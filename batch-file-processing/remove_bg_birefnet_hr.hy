(require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each ncut doto])
(import hyrule [assoc inc])
(import sys os shutil time)
(import cv2)
(import PIL [Image])
(import tqdm [tqdm])
(import numpy :as np)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; (setv images-directory-path "D:/data/km-images-pipeline/raw2")
(setv images-directory-path "D:/data/temp")
; (setv target-directory-path "D:/data/km-images-pipeline/person-isolated-transparent")
(setv target-directory-path "D:/data/temp/processed")
(setv skip-existing-files True)
(setv [model-name model-resolution] ["ZhengPeng7/BiRefNet_HR" 2048])
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(print "Initializing torch and loading model...")
(import torch)
(torch.set_float32_matmul_precision "high")
(import transformers [AutoModelForImageSegmentation])
(import torchvision [transforms])
(setv transform-image (transforms.Compose [(transforms.Resize #(model-resolution model-resolution))
                                           (transforms.ToTensor)
                                           (transforms.Normalize [0.485, 0.456, 0.406] [0.229, 0.224, 0.225])]))
(setv birefnet (doto (AutoModelForImageSegmentation.from_pretrained model-name :trust_remote_code True)
                 (.to "cuda")
                 .eval
                 .half))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(print f"Processing images from {images-directory-path} to {target-directory-path}")
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
  (setv image (Image.open image-path))
  (with [_ (torch.no_grad)]
    (setv new-alpha (-> image
                   transform-image
                   (.unsqueeze 0)
                   (.to "cuda")
                   .half
                   birefnet
                   (get -1)
                   .sigmoid
                   .cpu
                   (get 0)
                   .squeeze
                    ((transforms.ToPILImage))
                    (.resize image.size))))
    (doto (image-utils.refine-foreground image new-alpha)
      (.putalpha new-alpha)
      (.save f"{target-directory-path}/{(os.path.basename image-path)}"))
  ) ;; end for




(import winsound)
(doto winsound
  (.Beep 6000 50)
  (.Beep 6000 50)
  (.Beep 8000 100))
