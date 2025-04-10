(require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each ncut doto])
(import hyrule [assoc inc])
(import sys os shutil time)
(import kokoro)  ;; https://github.com/hexgrad/kokoro
(import soundfile :as sf)
(import slugify [slugify])  ;; pip install python-slugify [unidecode]

(setv pipeline (kokoro.KPipeline :lang_code "a"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv text "My brain's firing off like Wall Street on the day Trump slapped new tariffs on imports—chaotic, hysterical, high on fear. Knock-knock. Something's tapping from inside my skull—polite, insistent.")
(setv voice "am_michael")
(setv target-dir "c:/downloads")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setv generator (pipeline text :voice voice))
(for [[i [gsent ps audio]] (enumerate generator)]
  (setv target-file-name (-> gsent slugify (cut 40) (+ f"__{voice}__{(int (time.time))}.wav")))
  (try (sf.write f"{target-dir}/{target-file-name}" audio 24000)
    (except [e Exception]
            (print e))))





