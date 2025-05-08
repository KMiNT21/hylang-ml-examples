(require hyrule [-> ->> as-> doto])
(import PIL [Image])
(import tqdm [tqdm])
(import numpy :as np)


(setv [model-name model-resolution] ["ZhengPeng7/BiRefNet_HR" 2048])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

(defn get-alpha [cv-frame]
  ;; returns in PIL format
  (setv pil-image (Image.fromarray cv-frame))
  (with [_ (torch.no_grad)]
        (-> pil-image
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
            (.resize pil-image.size)
            )))

  