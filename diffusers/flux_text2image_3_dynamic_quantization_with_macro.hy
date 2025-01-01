(print "Importing modules...")

(require hyrule *)
(import torch [bfloat16])
(import transformers [T5EncoderModel BitsAndBytesConfig :as TransformersBitsAndBytesConfig])
(import diffusers [BitsAndBytesConfig :as DiffusersBitsAndBytesConfig])
(import diffusers.pipelines.flux.pipeline_flux [FluxPipeline])
(import diffusers.models.transformers.transformer_flux [FluxTransformer2DModel])
(import time [time])

(setv dtype bfloat16)
(setv repo_path "c:/FLUX.1-dev")  ; or "black-forest-labs/FLUX.1-dev"

(defmacro pretrained [model-class subfolder-name quantization_config]  ; This code is implemented as a macro rather than a function for the purpose of demonstrating macro syntax.
  `((. ~model-class from_pretrained)
    repo_path
    :subfolder ~subfolder-name
    :quantization_config ~quantization_config
    :torch_dtype dtype
    ))

(defn print-info [model]
  (print  f"{(. (type model) __name__):<23} memory footprint: {(/ (model.get-memory-footprint) (* 1024 1024 1024)):6.3f} GB"))

(print "Loading models...")
(setv start-time (time))

(setv pipe
  (FluxPipeline.from_pretrained
   repo_path
   :text_encoder_2 (pretrained T5EncoderModel "text_encoder_2" (TransformersBitsAndBytesConfig :load_in_4bit True))
   :transformer (pretrained FluxTransformer2DModel "transformer" (DiffusersBitsAndBytesConfig :load_in_8bit True))  ; try load_in_4bit if CUDA errors
   :torch_dtype dtype))
(pipe.to "cuda") ; Make sure all NN modules are on the same device.
; (pipe.enable_sequential_cpu_offload) --> bitsandbytes\nn\modules.py bnb.functional.quantize_4bit() -> ValueError: Blockwise quantization only supports 16/32-bit floats, but got torch.uint8
(pipe.vae.enable_slicing)
(pipe.vae.enable_tiling)

(print-info pipe.transformer)
(print-info pipe.text_encoder_2)

(setv output
  (pipe
   :prompt "Cute AI robot wearing helmet with print 'LISP', parrot on his shoulder and fluffy rufous cat"
   :width 1024
   :height 1024
   :num_inference_steps 30 ; Approximately 1 second per step on a 4090 with default Sceduler
   :guidance_scale 1.5))

(-> (. output images)
    (get 0)
    (.save f"flux-t2i-quant-{(time):.0f}.jpg"))

(print f"Elapsed time (with loading models from disk[cache]): {(- (time) start-time):.2f} sec")