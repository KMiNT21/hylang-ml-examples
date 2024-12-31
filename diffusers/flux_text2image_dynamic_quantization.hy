(import torch [bfloat16 float32])
(import transformers [T5EncoderModel BitsAndBytesConfig :as TransformersBitsAndBytesConfig])
(import diffusers [BitsAndBytesConfig :as DiffusersBitsAndBytesConfig])
(import diffusers.pipelines.flux.pipeline_flux [FluxPipeline])
(import diffusers.models.transformers.transformer_flux [FluxTransformer2DModel])

; (setv repo_path "black-forest-labs/FLUX.1-dev")
(setv repo_path "c:/FLUX.1-dev")

(setv text_encoder_t5
  (T5EncoderModel.from_pretrained
   repo_path
   :subfolder "text_encoder_2"
   :quantization_config (TransformersBitsAndBytesConfig :load_in_4bit True)
   :torch_dtype bfloat16))

(setv transformer
  (FluxTransformer2DModel.from_pretrained
   repo_path
   :subfolder "transformer"
   :quantization_config (DiffusersBitsAndBytesConfig :load_in_8bit True)
   :torch_dtype bfloat16))

(setv pipe
  (FluxPipeline.from_pretrained
   repo_path
   :text_encoder_2 text_encoder_t5
   :transformer transformer
   :device_map "balanced"
   :torch_dtype bfloat16))

; (print "pipe.text_encoder_t5: " (pipe.text_encoder_2.get_memory_footprint))
; (print "pipe.transformer:     " (pipe.transformer.get_memory_footprint))

(setv output
  (pipe
   :prompt "A cartoon penguin wearing a cowboy hat, its body segmented into small, colorful cubes to represent quantization. Some cubes are larger near the feet and smaller near the head, illustrating progressive size reduction. The text 'LISP' appears as blocky, digital-style lettering above the penguin, on a clean and modern background."
   :width 1024
   :height 1024
   :num_inference_steps 30
   :guidance_scale 7.5)) 

; Approximately 1 second per step on a 4090

(setv image (get output.images 0))
(image.save "flux-image-test-4090-vram-only-4bit-8bit.jpg")
