(import torch [float16])
(import diffusers.models.transformers.transformer_flux [FluxTransformer2DModel])
(setv dtype float16)

(setv repo_path "c:/FLUX.1-dev")  ; or "black-forest-labs/FLUX.1-dev"


; FluxTransformer2DModel (transformer) quantization example

(import diffusers [BitsAndBytesConfig :as DiffusersBitsAndBytesConfig]) 
(setv save_to_path "C:/FLUX.1-dev/8bit/transformer")

(setv transformer-quantization-config
  (DiffusersBitsAndBytesConfig :load_in_8bit True))

(setv transformer
  (FluxTransformer2DModel.from_pretrained
   repo_path
   :subfolder "transformer"
   :quantization_config transformer-quantization-config))

(transformer.save_pretrained save_to_path :max_shard_size "4GB")


; T5EncoderModel (text_encoder_2) quantization - the same way:
; 
; (import transformers [T5EncoderModel BitsAndBytesConfig :as TransformersBitsAndBytesConfig])
; (setv save_to_path "C:/FLUX.1-dev/4bit/text_encoder_2")
; ...
; ...
; ... :subfolder "text_encoder_2"
; ... :quantization_config (TransformersBitsAndBytesConfig :load_in_4bit True) 
; ...