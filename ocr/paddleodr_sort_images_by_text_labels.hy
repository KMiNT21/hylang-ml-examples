(require hyrule [-> ->> as-> ap-filter ap-map ap-each ap-first ap-reject do-n doto])
(import hyrule [pp pprint flatten])
(import os shutil logging)
(import paddleocr)
(import paddleocr.ppocr.utils.logging [get_logger])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv image-labels ["CAM01" "CAM02" "CAM03" "CAM04"])
(setv images-directory-path "C:/temp/cameras-images/person")
(setv number-of-attempts 3)  ; will it work wiothout image transformation?
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(doto (get_logger) (.setLevel logging.ERROR))  ; paddleocr print toooooo much debug info by default
(ap-each image-labels (os.makedirs f"{images-directory-path}/{it}" :exist_ok True))
(setv ocr-engine (paddleocr.PaddleOCR :use_angle_cls False :lang "en"))

(defn is-it-image? [file-name]
  (any (ap-map (file-name.endswith it) [".jpg" ".png" ".jpeg"])))

(defn find-any-label [image-labels found-strings]  ; return first found label from image-labels collection or None
  (ap-first (in it found-strings) image-labels))

(do-n number-of-attempts
      (print "\nNew attempt. Rescan folder for leftovers and run OCR for each.......................................")
      (setv file-paths (->> images-directory-path
                        os.scandir
                        (ap-map it.path)
                        (filter is-it-image?)))
      (for [image-path file-paths]
        (print "Processing " image-path)
        (setv ocr-data (ocr-engine.ocr image-path :cls False))
        (setv found-text-strings (->> ocr-data
                                      flatten
                                      (ap-filter (isinstance it str))
                                      list))
        (setv found-label (->> found-text-strings
                              (ap-map (it.replace "O" "0"))  ; my custom case to skip using Fuzzy String Matching, because it recognize CAM01 as CAMO1.
                               (find-any-label image-labels)))
        (if found-label
          (do 
            (print "\tFound label" found-label " Moving file to subfolder...")
            (shutil.move image-path f"{images-directory-path}/{found-label}/{(os.path.basename image-path)}")
            )
          (do 
            (print "\tNothing found. All recognized text: " :end "")
            (pprint found-text-strings)))))
