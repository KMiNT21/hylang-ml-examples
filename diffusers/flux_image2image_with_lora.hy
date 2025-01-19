(print "Importing modules...")
(require hyrule *)
(import torch [bfloat16 float16])
(import transformers [T5EncoderModel BitsAndBytesConfig :as TransformersBitsAndBytesConfig])
(import diffusers [BitsAndBytesConfig :as DiffusersBitsAndBytesConfig])
(import diffusers.pipelines.flux.pipeline_flux_img2img [FluxImg2ImgPipeline])
(import diffusers.models.transformers.transformer_flux [FluxTransformer2DModel])
(import diffusers.utils.loading_utils [load_image])
(import cv2)
(import time [time])

(setv dtype float16)
(setv repo_path "c:/FLUX.1-dev")

(print "Loading models")
(setv models-start-loading-time (time))

; Load transformer model first, so it loads to GPU only.
; And we can load LoRa adapter right after to GPU before unloading model layers to CPU.
; Otherwise, we have big chance to get CUDA errors (tensors on different devices) when loading LoRa adapter.
(print "Loading transformer...")
(setv transformer
  (FluxTransformer2DModel.from_pretrained
   repo_path
   :subfolder "quantized/transformer"
  ;  :quantization_config (DiffusersBitsAndBytesConfig :load_in_8bit True :bnb_4bit_compute_dtype dtype)
   :low_cpu_mem_usage True
   :torch_dtype dtype))  ; float16 to suppress warning: MatMul8bitLt: inputs will be cast from torch.bfloat16 to float16 during quantization

(print "Loading LoRa ...")
; (pipe.load_lora_weights (some-folder :weight_name ".safetensors")) after pipe init
(transformer.load_lora_adapter "C:\\FLUX.1-dev\\quantized\\lora\\adapter_model.safetensors")

(print "Loading text_encoder_2 ...")
(setv text_encoder_2
  (T5EncoderModel.from_pretrained
   repo_path
   :subfolder "quantized_4b/text_encoder_2"
   :low_cpu_mem_usage True
   :torch_dtype dtype))

(print "Loading pipe rest components...")
(setv pipe
  (FluxImg2ImgPipeline.from_pretrained
   repo_path
   :text_encoder_2 text_encoder_2
   :transformer transformer
   :torch_dtype dtype))

(doto pipe
  (.fuse_lora :lora_scale 0.95)
  (.text_encoder.to "cuda")  ; move all NN modules to the same device (quantized models are on GPU already)
  (.vae.to "cuda")
  (.vae.enable_slicing)
  (.vae.enable_tiling)
  )

(as-> (pipe
       :prompt "Some very strange prompt for image2image model, dark colors, cyberpunk, etc."
       :image (load_image "image-0001.png") 
       :width 960
       :height 540
       :strength 0.4
       :num_inference_steps 30
       :guidance_scale 3.5) it
  it.images
  (get it 0)
  (.save it f"flux-i2i-lora-{(time):.0f}.jpg"))

(print f"Elapsed time (with loading models from disk[cache]): {(- (time) models-start-loading-time):.2f} sec") 