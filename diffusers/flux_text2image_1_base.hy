(import torch [bfloat16])
(import diffusers.pipelines.flux.pipeline_flux [FluxPipeline])

(setv pipe (FluxPipeline.from_pretrained "c:/FLUX.1-dev" :torch_dtype bfloat16))
(pipe.enable_sequential_cpu_offload)
(pipe.vae.enable_slicing)
(pipe.vae.enable_tiling)

(setv output
  (pipe
   :prompt "A very simplified cartoon-style penguin with the word 'BASE'"
   :width 1024
   :height 1024
   :num_inference_steps 30
   :guidance_scale 6.5))

(setv image (get output.images 0))
(image.save "flux-image-test-base.jpg")
