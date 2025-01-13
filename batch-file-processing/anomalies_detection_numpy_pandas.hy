(require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each])
(import hyrule [assoc])
(import os shutil)
(import multiprocessing.dummy)
(import numpy :as np)
(import pandas :as pd)
(import scipy [stats])
(import PIL [Image])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv images-directory-path "C:/temp/cameras-images/person/CAM03")
(setv subfolder-for-suspected-images "anomalies")
(setv z-threshold 3.0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn is-it-image? [file-name]
  (any (ap-map (file-name.endswith it) [".jpg" ".png" ".jpeg"])))

(defn calculate-brightness [image-path]
  (with [img (Image.open image-path)]
    (-> (img.convert "L")
        np.array
        np.mean)))

(setv file-paths (->> images-directory-path
                      os.scandir
                      (ap-map it.path)
                      (filter is-it-image?)
                      list))
(setv pool (multiprocessing.dummy.Pool 8))
(setv brightness-values (list (pool.map calculate-brightness file-paths)))

;; Example of using Pandas DataFrame
(setv df (pd.DataFrame))
(assoc df "brightness" brightness-values)
(assoc df "z_score" (stats.zscore df))
(assoc df "is_anomaly" (> (abs (get df "z_score")) z_threshold))
(assoc df "file-path" file-paths)

(print "Filtering anomalies...")
(setv anomalies_df (pd.DataFrame (get df (get df "is_anomaly"))))
(os.makedirs f"{images-directory-path}/{subfolder-for-suspected-images}" :exist_ok True)
(ap-each (get anomalies_df "file-path")
         (print "Moving " it " to subfolder")
         (shutil.move it f"{images-directory-path}/{subfolder-for-suspected-images}/{(os.path.basename it)}"))

 
