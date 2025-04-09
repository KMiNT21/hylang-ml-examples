(require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each ncut doto])
(import hyrule [assoc inc])
(import sys os shutil time)
(import cv2 random)
(import PIL [Image])
(import tqdm [tqdm])
(import numpy :as np)


; Random color background + PNG with isolated person

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv images-directory-path "D:/data/km-images-pipeline/person-isolated-transparent-vertical")
(setv target-directory-path "D:/data/km-images-pipeline/2lora-random-color-bg-vertical")
(setv skip-existing-files True)
(setv target-image-size-wh #(1280 720))
; (setv target-image-size-wh #(720 1280))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(setv colors [
    #(255 255 255) ; white
    #(0 0 0)       ; black
    #(255 0 0)     ; red
    #(0 128 0)     ; green
    #(0 0 255)     ; blue
    #(255 255 0)   ; yellow
    #(0 255 255)   ; cyan
    #(255 0 255)   ; magenta
    #(255 165 0)   ; orange
    #(128 0 128)   ; purple
    #(255 192 203) ; pink
    #(128 128 128) ; gray
    #(165 42 42)   ; brown
    #(0 255 0)     ; lime
    #(128 0 0)     ; maroon
    #(128 128 0)   ; olive
    #(0 128 128)   ; teal
    #(0 0 128)     ; navy
])





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(print f"Processing images from {images-directory-path} to {target-directory-path}")
(os.makedirs target-directory-path :exist_ok True)
(-> __file__ os.path.abspath os.path.dirname os.path.dirname (+ "/libs") sys.path.append)
(import image-utils)
(setv image-paths (->> images-directory-path
                       os.scandir
                       (ap-map it.path)
                       (filter image-utils.is-it-image?)
                       (ap-reject (and skip-existing-files
                                       (os.path.isfile f"{target-directory-path}/{(os.path.basename it)}")))
                       list))

(for [image-path (tqdm image-paths)]
    (setv result-image (Image.new "RGBA" target-image-size-wh (random.choice colors)))
    (setv person-image (as-> image-path it
                        (Image.open it)
                        (it.resize target-image-size-wh Image.Resampling.LANCZOS)
                        (doto result-image (.alpha_composite it))
                        (it.save f"{target-directory-path}/{(os.path.basename image-path)}")))
) ;; end for




(import winsound)
(doto winsound
  (.Beep 6000 50)
  (.Beep 6000 50)
  (.Beep 8000 100))
