(require hyrule [-> ->> as-> ap-filter ap-reject ap-map unless ncut])
(import os cv2 mediapipe)
(import numpy :as np) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv source-directory-path "C:/temp/png")
(setv subfolder-boxes "bounding-boxes") ; we will save cropped images in this example
(setv overwrite-existing-result-images False)
(setv min-detection-confidence 0.8)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(os.makedirs f"{source-directory-path}/{subfolder-boxes}" :exist_ok True)
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
                  (get it 0)
                  it.location_data.relative_bounding_box))

  (setv #(img-height img-width channels) cv2image.shape)

  (setv #(x width) (->> [box.xmin box.width]
                      (ap-map (* img-width it))
                      (map int)))
  (setv #(y height) (->> [box.ymin box.height]
                      (ap-map (* img-height it))
                      (map int)))

  (->> (ncut cv2image (: y (+ y height)) (: x (+ x width)))
       np.array
       (cv2.imwrite f"{source-directory-path}/{subfolder-boxes}/{fname}")))