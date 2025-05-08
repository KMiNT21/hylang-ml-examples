(require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each ncut doto unless])
(import os)
(import cv2)
(import PIL [Image])
(import tqdm [tqdm])
(import numpy :as np)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv video-source "d:/renders/sh2.mov")
(setv video-target f"{video-source}.matte.mp4")
; (setv skip-existing-files True) TODO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(unless (os.path.isfile video-source)
        (print f"Error opening {video-source}")
        (exit))

(print "Reading video file info...") ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv cap (cv2.VideoCapture video-source))
(setv num-of-frames (-> cap (.get cv2.CAP_PROP_FRAME_COUNT) int))
(let [frame-width (int (cap.get cv2.CAP_PROP_FRAME_WIDTH))
      frame-height (int (cap.get cv2.CAP_PROP_FRAME_HEIGHT))
      frame-size #(frame-width frame-height)
      fps (cap.get cv2.CAP_PROP_FPS)
      fourcc (cv2.VideoWriter_fourcc #* "mp4v")]
  (print video-target fps frame-size )
  (setv writer (cv2.VideoWriter video-target fourcc fps frame-size)))

(import mattinglib)

(print "Processing frames...")  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(for [i (-> num-of-frames range tqdm)]
  (setv #(success? frame) (cap.read))
  (unless success?
          (print "Error reading video file!")
          (break))
  (-> frame
      mattinglib.get-alpha
      np.array
      (cv2.cvtColor cv2.COLOR_BGR2RGB)
      writer.write)
  ) ; end of for

(writer.release)
(cap.release)




(import winsound)
(doto winsound
  (.Beep 6000 50)
  (.Beep 6000 50)
  (.Beep 8000 100))
