(require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each ncut])
(import hyrule [assoc inc])
(import os)
(import cv2)
(import numpy :as np)


(defn is-it-image? [file-name]
  (if (not (os.path.isfile file-name))
    False
    (as-> file-name it (it.lower) (map it.endswith [".jpg" ".png" ".jpeg"]) (any it))))


(defn remove-green-halo-from-npimage [#^ cv2.typing.MatLike image 
                                    [steps 10]
                                    [effect-strenght-for-each-step 0.75]
                                    [mask-dilate 30]]

  "Removes green tint(halo) from image with alpha channel (isolated object with transparent background)."

  ;; -------------------------------------------------------------------------------------------------------------------
  ;; Parameters for optional tuning: 
  (setv erosion-step-factor 1)
  (setv green-low #(15 40 0))
  (setv green-high #(85 255 255))
  (setv inpaint-radius 5)
  (setv [mask-trashhold-min mask-trashhold-max] #(200 255))
  (setv kernel (cv2.getStructuringElement cv2.MORPH_ELLIPSE #(7 7)))
  ;; -------------------------------------------------------------------------------------------------------------------
  ;; If you want to understand what's going on here,
  ;; just upload the whole file to any LLM and ask for detailed comments! :)

  (for [step (range steps)]
    
    (setv [b g r alpha] (cv2.split image))
    (setv rgb (cv2.merge [b g r]))
    
    (setv solid-mask (-> alpha
                         (cv2.threshold mask-trashhold-min mask-trashhold-max cv2.THRESH_BINARY)
                         (get 1)
                         (cv2.GaussianBlur #(3 3) 0)))

    (let [dilated-mask (cv2.dilate solid-mask kernel :iterations mask-dilate)
          eroded-mask (cv2.erode solid-mask kernel :iterations (* step erosion-step-factor))]  ; one pixel larger each next step
          (setv edge-mask (cv2.subtract dilated-mask eroded-mask)))

    (setv hsv (cv2.cvtColor rgb cv2.COLOR_BGR2HSV))
    (setv [h s v] (cv2.split hsv))

    (setv final-edge-mask (as-> hsv it
                            (cv2.inRange it green-low green-high)
                            (cv2.bitwise_and edge-mask it)))

    (setv inpainted (cv2.inpaint rgb final-edge-mask inpaint-radius cv2.INPAINT_TELEA))  ; TODO: check effect

    (setv blend-mask (cv2.merge (* [final-edge-mask] 3)))

    (setv result (np.where (> blend-mask 0) inpainted rgb))

    (setv s (.astype s np.float32))
    ; python: s[final_edge_mask > 0] *= effect-strenght-for-each-step
    (let [mask-sat (get s (> final_edge_mask 0))]
      (assoc s (> final_edge_mask 0) (* mask-sat effect-strenght-for-each-step)))
    (setv s (-> s (np.clip 0 255) (.astype (np.uint8))))

    (let [corrected-hsv (cv2.merge [h s v])
          corrected-rgb (cv2.cvtColor corrected-hsv cv2.COLOR_HSV2BGR)]
       (setv final-result (np.where (> blend-mask 0) corrected-rgb result)))


    ; (setv output (as-> final-result it
    ;               (lfor i (range 3) (ncut it : : i))
    ;               (+ it [alpha])
    ;               (cv2.merge it)))
    ; more readable version of the above code               
    (setv image (cv2.merge [ (ncut final-result : : 0)
                             (ncut final-result : : 1)
                             (ncut final-result : : 2)
                             alpha]))
    
    ) ; END OF for [step (range steps)] 
  image)



; USAGE EXAMPLE:
; 
; (as-> "ditry-transparent.png" it
;     (cv2.imread it cv2.IMREAD_UNCHANGED)
;     (remove-green-halo-from-image it)
;     (cv2.imwrite "cleaned.png" it))
