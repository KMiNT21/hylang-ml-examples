(require hyrule [-> ->> as-> ap-filter ap-map ap-each ap-first ap-reject do-n doto])
(require hyrule [defmain])
(import os shutil random)
(import ultralytics)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv dataset-path "D:/data/camera/images_928x576-CAM01")  ; root folder with "train" folder inside
(setv model (ultralytics.YOLO "C:/OneDrive/SRC/hylang-ml-examples/yolo/my-yolov8n-cls.yaml"))
(setv shuffle-data False)  ; Move val to train, shuffle and split trans/val sets again
(setv new-val-train-split 0.2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; on my machine it has problems with spawning new processes if started by hy.exe, so
; it can be compiled to .pyc and run with python:
; hyc ./yolo/train_cls.hy
; python ./yolo/__pycache__/train_cls.cpython-311.pyc
; (chech hyc output for your platform)
(defmain []
  
(when shuffle-data
  (print "Dataset shuffling enabled:")
  (setv train-path f"{dataset-path}/train")
  (setv val-path f"{dataset-path}/val")
  (os.makedirs val-path :exist-ok True)
  (setv classes (os.listdir train-path))
  (ap-each classes (os.makedirs f"{val-path}/{it}" :exist-ok True))
  (for [cls classes]
           (setv images-to-move-back (os.listdir f"{val-path}/{cls}"))
    (when images-to-move-back
      (print f"\t- {cls}: Moving all validation images back to train folder...")
      (ap-each images-to-move-back (shutil.move f"{val-path}/{cls}/{it}" f"{train-path}/{cls}/{it}"))))
  (print "Shuffling, splitting and moving images to validation folder...")
  (for [cls classes]
    (setv all-class-images (os.listdir f"{train-path}/{cls}"))
    (setv val-count (int (* (len all-class-images) new-val-train-split)))
    (ap-each
     (random.sample all-class-images val-count)
     (shutil.move f"{train-path}/{cls}/{it}" f"{val-path}/{cls}/{it}"))
    (print f"\t- {cls}: Moved {val-count} from {(len all-class-images)} images to validation folder."))
  (print "Dataset shuffling completed."))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(model.train
 :resume False
 :data dataset-path
 :epochs 100
 :batch -1
;  :batch 8
 :workers 4
 :optimizer "AdamW"
 :imgsz 224
 :single_cls True
 :cache False
 :pretrained False
 :scale 0.0   ; Scales the image by a gain factor, simulating objects at different distances from the camera.
 :fliplr 0.0  ; Flips the image upside down with the specified probability, increasing the data variability without affecting the object's characteristics.
 :mosaic 0.0  ; Combines four training images into one, simulating different scene compositions and object interactions. Highly effective for complex scene understanding.
 :project "C:/temp/yolo-logs"
 )

(print "Metrics: " model.val)


)