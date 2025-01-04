(require hyrule *)
(import toolz [first last])
(import ultralytics [YOLO])
(import cv2)

(setv model-path "your-model-cls.pt")
(setv video-source "protocol://netwrork-camera-ip-address:port")  ; (setv video-source "or-local-video-for-testing.mp4")
(setv person-class-index 1)
(setv person-confidence-threshold 0.77)

(setv model (YOLO model-path))

(defn read-device-and-process-frame [cap]
  (let [#(success? frame) (cap.read)]
    (when success?
      (process frame))))

(defn process [frame]
  (let [first-result (-> (model.predict frame :verbose False)
                         first
                         .cpu)
        top1-class-index first-result.probs.top1
        top1conf (first-result.probs.top1conf.item)
        person-class? (= top1-class-index person-class-index)
        confidence-threshold-passed? (> top1conf person-confidence-threshold)
        person-detected? (and person-class? confidence-threshold-passed?)]
    (if person-detected?
      (cv2.imshow "Person detected!" frame)
      (cv2.imshow "No events..." frame))
    (cv2.waitKey 1)))

(while True
  (let [capture-device (cv2.VideoCapture video-source)]
    (while (read-device-and-process-frame capture-device)
      (continue))
    (print "End of stream or file. Reopening/reconnecting")))
