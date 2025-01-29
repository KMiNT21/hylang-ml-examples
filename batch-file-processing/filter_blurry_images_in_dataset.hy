(require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each])
(import hyrule [assoc])
(import os shutil)
(import cv2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv images-directory-path "D:/data/new-to-process/VID_20250127_162218")
(setv subfolder-for-suspected-images "blurry")
(setv laplacian-threshold 250)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn is-it-image? [file-name]
  (any (ap-map (file-name.endswith it) [".jpg" ".png" ".jpeg"])))

(setv file-paths (->> images-directory-path
                      os.scandir
                      (ap-map it.path)
                      (filter is-it-image?)
                      list))

(print "Filtering blurry images...")

(defn is-blurry? [image-path]
  (-> image-path
      (cv2.imread cv2.IMREAD_GRAYSCALE)
      (cv2.Laplacian cv2.CV_64F)
      .var
      (< laplacian-threshold)))

(os.makedirs f"{images-directory-path}/{subfolder-for-suspected-images}" :exist_ok True)
(ap-each file-paths
         (when (is-blurry? it)
           (print f"Image {it} is blurry, moving to subfolder")
           (shutil.move it f"{images-directory-path}/{subfolder-for-suspected-images}/{(os.path.basename it)}")))

