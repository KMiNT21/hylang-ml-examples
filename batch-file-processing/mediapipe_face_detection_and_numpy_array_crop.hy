(require hyrule [-> ->> as-> ncut unless ap-filter ap-reject unless])
(import toolz [first last])
(import numpy :as np) 
(import os cv2 mediapipe)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv source-directory-path "C:/temp/png")
(setv subfolder-boxes "bounding-boxes") ; we will save cropped images in this example
(setv overwrite-existing-result-images False)
(setv min-detection-confidence 0.8)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setv detector (mediapipe.solutions.face_detection.FaceDetection 
                :model_selection 1 
                :min_detection_confidence min-detection-confidence))

(setv filenames-to-process (->> source-directory-path
                                os.listdir
                                (ap-filter (it.endswith ".png"))
                                (ap-reject (unless overwrite-existing-result-images
                                                   (os.path.isfile f"{source-directory-path}/{subfolder-boxes}/{it}")))))

(for [fname filenames-to-process]
  (setv image-path f"{source-directory-path}/{fname}")
  (print "Processing: " image-path)
  (setv cv2image (cv2.imread image-path))
  
  (setv detection-result (detector.process cv2image))
  (unless (and detection-result detection-result.detections) 
    (do (print "No faces detected!")
        (continue)))

  (setv box (as-> detection-result.detections it
                  (first it)
                  it.location_data.relative_bounding_box))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ; V1 
;   (setv #(img-height img-width channels) cv2image.shape)
;   (setv x1 (int (* box.xmin img-width)))
;   (setv x2 (+ x1 (int (* box.width img-width))))
;   (setv y1 (int (* box.ymin img-height)))
;   (setv y2 (+ y1 (int (* box.height img-height))))
;   (setv cropped-image (np.array (ncut cv2image (: y1 y2) (: x1 x2)))) 


; V2  
  (setv #(img-height img-width channels) cv2image.shape)
  (setv #(x y width height) (lfor [b i]
                                  (zip [box.xmin box.ymin box.width box.height]
                                       [img-width img-height img-width img-height])
                                  (int (* b i))))
  (setv cropped-image (np.array (ncut cv2image (: y (+ y height)) (: x (+ x width))))) 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  

  

  (setv target-path  f"{source-directory-path}/{subfolder-boxes}/{fname}")
  (cv2.imwrite target-path cropped-image))





















; Instead of block
; 
;   (unless (and detection-result detection-result.detections) 
;     (continue))
;      
;   you can do it this way if you don't mind the extra nesting:
;   
;   (if (or (is None detection-result) (is None detection-result.detections))
;     (do
;       (print "Failed! Skipping."))
;     (do 
;       (setv box
;       ..
;  
