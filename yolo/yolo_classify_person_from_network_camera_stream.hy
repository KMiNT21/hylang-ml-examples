(require hyrule *)
(import toolz [first last])
(import ultralytics [YOLO])
(import cv2)

(setv model-path "your-model-cls.pt") 
(setv video-source "protocol://netwrork-camera-ip-address:port")  ; (setv video-source "or-local-video-for-testing.mp4")
(setv person-class-index 1)
(setv person-confidence-threshold 0.77)

(setv model (YOLO model-path))

(defn process [frame]
  (setv first-result (-> (.predict model frame :verbose False) first .cpu))
  (setv top1 first-result.probs.top1)  
  (setv top1conf (first-result.probs.top1conf.item))
  (setv person-detected (and (= top1 person-class-index) (> top1conf person-confidence-threshold)))
  (if person-detected
    (cv2.imshow "Person detected!" frame)
    (cv2.imshow "No events..." frame))
  (cv2.waitKey 1))

(while True
  (setv cap (cv2.VideoCapture video-source))
  (while True
    (setv ret-and-frame-tuple (cap.read))
    (if (first ret-and-frame-tuple)
      (do ; if cap.read() returns (True, Image)
        (process (last ret-and-frame-tuple)))
      (do ; if cap.read() returns (False, EmptyImage)
       (print "End of stream or file. Reopening/reconnecting")
       (break)))))



; simplified version of the above code
; (while True
;   (setv cap (cv2.VideoCapture video-source))
;   (while True
;     (setv ret-and-frame-tuple (cap.read))
;     (if (first ret-and-frame-tuple)
;         (process (last ret-and-frame-tuple))
;         (break))))

; could be also written something like this
; with macro do-while and modified process function (args and return):
; (while True
;   (setv cap (cv2.VideoCapture video-source))
;   (do-while (process (cap.read))))


; use this if you don't use infinite loop:
; (cap.release)
; (cv2.destroyAllWindows)