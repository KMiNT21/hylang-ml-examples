; (require hyrule [-> ->> as-> ap-filter ap-reject ap-map ap-each defmain doto])
; (import hyrule [assoc inc])
(import os)

(import google [genai])  ; pip install google-genai
(import google.genai [types])


; get your free key at https://aistudio.google.com/apikey and create ENV key
(setv client (genai.Client :api_key (os.getenv "GENAI-API")))
(setv model "gemini-2.0-flash")


(setv text-input "Write lyrics for a new `The Prodigy` track.")
(setv response (client.models.generate_content :model model :contents text-input))

(print response.text)