(require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each defmain doto])
(import hyrule [assoc inc])
(import sys os argparse shutil time)


(import nicegui [ui])
(import kokoro)  ; https://github.com/hexgrad/kokoro
(import soundfile :as sf)
(import slugify [slugify])  ; pip install python-slugify [unidecode]

(setv pipeline (kokoro.KPipeline :lang_code "a"))


; hardcode some settings or move it to UI if needed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setv target-directory-path "C:/downloads")
; (setv voices ["af_heart" "af_alloy" "am_liam" "am_michal" "another_voice"])  ; https://github.com/hexgrad/kokoro/tree/main/kokoro.js/voices
(setv voice "am_liam")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




; TODO: anync and some progress bar for the next example

(defn synth [text voice target-dir]
  (setv generator (pipeline text :voice voice))
  (for [[i [gsent ps audio]] (enumerate generator)]
    (setv target-file-name (-> gsent slugify (cut 40) (+ f"__{voice}__{(int (time.time))}.wav")))
    (try (sf.write f"{target-dir}/{target-file-name}" audio 24000)
        (except [e Exception]
                (print e))))
  (try (do (import winsound) (doto winsound (.Beep 6000 50) (.Beep 6000 50) (.Beep 8000 100))) (except [])) ; optional
  )





; TODO: macro to provide a more elegant syntax. I think now it's ugly!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(ui.markdown "## Simple Kokoro TTS Interface with NiceGUI")
(with  [_ (doto (ui.card) (.classes "mx-auto w-full sm:w-11/12 md:w-4/5 lg:w-4/5 max-w-[800px] mt-1"))]
  
  (with [_ (doto (ui.card_section) (.classes "w-full"))]
    (setv text-input (ui.textarea :placeholder "Greetings, commander!"))
    (doto text-input
      (.classes "w-full")
      (.props "outlined clearable rows=15")))
  
;   (with [_ (ui.card_section)]
;     (setv voice-select (ui.select :options voices :label "Select voice" :value (get voices 0)))
;     (doto voice-select (.classes "w-full") (.props "outlined dense options-dense"))
;     )
  
  (with [_ (doto (ui.card_actions) (.classes "flex flex-col w-full") (.props "align=right"))]
    (setv button (ui.button "SYNTHESIZE" :on_click (fn [] (synth text_input.value voice target-directory-path))))
    (doto button (.classes "w-full") (.props "color=primary icon=volume_up")))

 ) ; end of UI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




(defmain [] (ui.run :title "TTS Interface (NiceGUI)" :show False :reload False))  ;; live reload impossible for Hy

