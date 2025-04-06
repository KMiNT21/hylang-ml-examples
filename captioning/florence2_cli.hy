(require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each defmain doto unless])
(import hyrule [assoc inc])
(import sys os argparse shutil time)
(import pathlib [Path])
(import cv2)
(import PIL [Image])
(import torch)
(import transformers [AutoProcessor AutoModelForCausalLM])
(import tqdm [tqdm])


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; (setv model_id "microsoft/Florence-2-large")
; (setv model_id "gokaygokay/Florence-2-Flux-large")
(setv model_id "C:/models/LLM/Florence-2-Flux-Large")
(setv prompts ["<CAPTION>" "<DETAILED_CAPTION>" "<MORE_DETAILED_CAPTION>"])
(setv torch_dtype torch.float16)
(setv device (if (torch.cuda.is_available) "cuda" "cpu"))
(setv trigger-word "") ;; <--------------------- MAKE YOUR OWN LOGIC in corresponding code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defn is-it-image-file? [file-name]
  (if (not (os.path.isfile file-name))
    False
    (as-> file-name it (it.lower) (map it.endswith [".jpg" ".png" ".jpeg"]) (any it))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defmain [] ;;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  (setv parser (argparse.ArgumentParser :description "Captioning with microsoft/Florence-2-large model to .txt files."))
  (setv args
    (-> (doto parser
          (.add_argument "--path"  :type str  :required True  :help "Captioning with microsoft/Florence-2-large model")
          (.add_argument "--lod"  :type int  :default 2  :help "Level of details: 0, 1 or 2 (2 for maximum details)")
          (.add_argument "--overwrite_existing_txt" :default False :action "store_true" :help "Ignore existing .txt files and re-run Florence to rewrite"))
        .parse_args))
  (print f"Captioning images in folder: {args.path}")
  (setv paths (if (os.path.isfile args.path)
                [args.path]
                (->> args.path
                         os.scandir
                         (ap-map it.path)
                         (filter is-it-image-file?)
                         list)))

  (unless args.overwrite-existing-txt
          (setv paths (list (ap-reject (os.path.isfile f"{(os.path.dirname it)}/{(. (Path it) stem)}.txt") paths))))
  
 
  (setv model (AutoModelForCausalLM.from_pretrained model_id :trust_remote_code True :torch_dtype "auto"))
  (doto model .eval .cuda)
  (setv processor (AutoProcessor.from_pretrained model_id :trust_remote_code True))

  (ap-each (tqdm paths)  ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
           
    (setv image (Image.open it))
    (when (= image.mode "RGBA")
      (setv image (image.convert "RGB")))           
    (setv inputs (processor :text (get prompts args.lod) :images image :return_tensors "pt"))
    (inputs.to device torch_dtype)

    (setv generated-ids (model.generate
                        :input_ids (get inputs "input_ids")
                        :pixel_values (get inputs "pixel_values")
                        :max_new_tokens 4096
                        :num_beams 3
                        :do_sample False))

    (setv text (-> generated-ids
                   (processor.batch_decode :skip_special_tokens False)
                   (get 0)
                   (processor.post_process_generation :task (get prompts args.lod) :image_size #(image.width image.height))
                   (get (get prompts args.lod))))
    
    (when trigger-word  ;; ....................... write your logic here if needed...................................
      (setv text (-> text
                    (.replace "man" f"{trigger-word} man")
                    (.replace "person" f"{trigger-word} person")))
      )
      
    (with [f (open f"{(os.path.dirname it)}/{(. (Path it) stem)}.txt" "w" :encoding "utf-8")]
      (.write f text))

    ) ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

  


  





  (import winsound)
  (doto winsound
    (.Beep 6000 50)
    (.Beep 6000 50)
    (.Beep 8000 100)))