(require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each defmain doto])
(import hyrule [assoc inc ])
(import sys os argparse shutil time)
(import cv2)


(-> __file__ os.path.abspath os.path.dirname os.path.dirname (+ "/libs") sys.path.append)
(import image-utils)


(defn is-blurry? [image-path laplacian-threshold]
  (-> image-path
      (cv2.imread cv2.IMREAD_GRAYSCALE)
      (cv2.Laplacian cv2.CV_64F)
      .var
      (< laplacian-threshold)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defmain []
  
  (setv parser (argparse.ArgumentParser :description "Filter blurry images"))
  (setv args
    (-> (doto parser
          (.add_argument "--path"  :type str  :required True  :help "Images Full Folder Path")
          (.add_argument "--subfolder"  :type str  :default "blurry"  :help "Subfolder name to create")
          (.add_argument "--threshold"  :type int  :default 50  :help "Laplacian Threshold Value. (Light=<50, Danger=>100)"))
        .parse_args))
  (print args.path "\t\t\tThreshold:" args.threshold)
  (setv image-paths (->> args.path
                         os.scandir
                         (ap-map it.path)
                         (filter image-utils.is-it-image?)
                         list))
  
  (os.makedirs f"{args.path}/{args.subfolder}" :exist_ok True)
  
  (setv [images-moved images-total] [0 (len image-paths)])
  (setv start_time (time.time))
  (for [[i image-path] (enumerate image-paths)]

    ; progress bar
    (let [elapsed (- (time.time) start_time)
          percent (/ (inc i) (len image-paths))
          bar_width 30
          filled (int (round (* percent bar_width)))
          bar f"{(* "█" filled)}{(* "-" (- bar_width filled))}"]
      (sys.stdout.write f"\rFiltering blurry images: |{bar}| {percent :.0%} {elapsed :.0f}s. Images moved/left: {images-moved}/{(- i images-moved)} of {images-total} total.")
      sys.stdout.flush)

    (when (is-blurry? image-path args.threshold)
      (setv images-moved (inc images-moved))
      (try (shutil.move image-path f"{args.path}/{args.subfolder}/{(os.path.basename image-path)}")
            (except [e [FileNotFoundError PermissionError OSError]]
              ;;(print e) - if you don't mind breaking the progress bar
            ))))
    
    (import winsound)
    (doto winsound
      (.Beep 6000 50)
      (.Beep 6000 50)
      (.Beep 8000 100)))