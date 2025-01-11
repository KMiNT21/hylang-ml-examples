(require hyrule [-> ->> as-> ap-filter ap-map ap-each ap-reject])
(import hyrule [flatten])
(import os shutil)
(import paddleocr)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv text-to-find "CAM03")
(setv images-directory-path "C:/temp/cameras-images")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setv target-dir f"{images-directory-path}/{text-to-find}")
(os.makedirs  target-dir :exist_ok True)

(setv ocr-engine (paddleocr.PaddleOCR :lang "en"))

(defn found? [text-to-find file-path]
  (->> file-path
       (ocr-engine.ocr :cls True)
       flatten
       (in text-to-find)))

(setv found-files (->> images-directory-path
                       os.scandir
                       (ap-map it.path)
                       (ap-filter (it.endswith ".jpg"))                       
                       (ap-filter (found? text-to-find it))
                       list))

(ap-each found-files (shutil.copy it f"{target-dir}/{(os.path.basename it)}"))

(print f"Search string was found in {(len found-files)} files. All files was copied to subfolder /{text-to-find}.")
