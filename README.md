# Hylang ML Examples

> "Code is Data, Data is Code" — The Lisp Way

A collection (**in its early stages**) of examples showcasing Hy (a Lisp dialect embedded in Python) for machine learning tasks.

## About

My goal is to demonstrate how Hy's Lisp syntax leads to **highly readable and concise code** for machine learning tasks, even if it might seem unfamiliar at first glance.

This repository demonstrates the power and elegance of Hy, a **Lisp dialect** embedded in **Python**, applied to **machine learning** problems. Hy combines the best of both worlds: the expressiveness and metaprogramming capabilities of Lisp with Python's rich machine learning ecosystem.

## Why Lisp for Machine Learning?

The Lisp family of languages offers unique advantages for developing **ML systems**:

- **Homoiconicity**: Code and data share the same representation, making metaprogramming natural and powerful
- **Macros**: Enable creation of specialized DSLs for ML tasks
- **Functional Approach**: Simplifies data manipulation and pipeline construction
- **Interactive Development**: REPL-driven development is perfect for exploratory data analysis
- **Expression-Oriented**: Everything is an expression, leading to more concise and composable code

## Why Hy?

- Full compatibility with Python's ecosystem (numpy, pandas, scikit-learn, pytorch, etc.)
- All the power of Lisp without losing access to Python's vast library collection
- Seamless integration with Jupyter notebooks
- Easy embedding into existing Python projects
- Zero-cost abstractions when compiled to Python bytecode

<!--
## Project Structure

```
hylang-ml-examples/
├── diffusers/
├── yolo/
``` -->

## Examples

### Data Pipeline with Threading Macro

```hy
;; threading macro -> (first parameter)
(defn preprocess-data [data]
  (-> data
      (normalize-features)
      (select-features ["age" "income" "category"])
      (handle-missing)
      (encode-categorical)))
```

```hy
;; threading macro as-> ("it" as iterator)
(as-> (pipe
       :prompt "Ukrainian girl with parrot on her shoulder and fluffy rufous cat"
       :width 1024
       :height 1024
       :num_inference_steps 30
       :guidance_scale 3.5) it
  it.images
  (get it 0)
  (.save it f"flux-text-to-image-{(time):.0f}.jpg"))
```

```hy
;; threading macro -> (first parameter)
;; Image background removing by BiRefNet_HR model
(setv image (Image.open image-path))
(with [_ (torch.no_grad)]
  (setv new-alpha (-> image
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
                  (.resize image.size))))
(doto image
  (.putalpha new-alpha)
  (.save "result.png"))
```

```hy
;; threading macro ->> (second parameter)
(setv image-paths (->> args.path
                       os.scandir
                       (ap-map it.path)
                       (filter is-it-image?)
                       list))
```


### Network stream processing: person detection with YOLO classification model

```hy
(defn read-device-and-process-frame [cap]
  (let [#(success? frame) (cap.read)]
    (when success?
      (process frame))))

(defn process [frame]
  (let [first-result (-> (model.predict frame :verbose False)
                         first
                         .cpu)
        top1-class-index first-result.probs.top1
        top1conf (first-result.probs.top1conf.item)
        person-class? (= top1-class-index person-class-index)
        confidence-threshold-passed? (> top1conf person-confidence-threshold)
        person-detected? (and person-class? confidence-threshold-passed?)]
    (if person-detected?
      (cv2.imshow "Person detected!" frame)
      (cv2.imshow "No events..." frame))
    (cv2.waitKey 1)))

(while True
  (let [capture-device (cv2.VideoCapture video-source)]
    (while (read-device-and-process-frame capture-device)
      (continue))
    (print "End of stream or file. Reopening/reconnecting")))
```

### Other macros examples

```hy
(doto pipe
  (.fuse_lora :lora_scale 0.95)
  (.text_encoder.to "cuda")
  (.vae.to "cuda")
  (.vae.enable_slicing)
  (.vae.enable_tiling))
```

```hy
(setv found-files (->> images-directory-path
                       os.scandir
                       (ap-map it.path)
                       (ap-filter (it.endswith ".jpg"))
                       (ap-filter (found? text-to-find it))
                       list))
```

## Getting Started

1. Create virtual environment. For example with Conda:

```bash
conda create --name <my-env>
```

2. Install main dependencies:

```bash
pip install hy hyrule
```

Install other dependencies what you want:

```bash
pip diffusers ultralytics cv2 ...
```

3. Install Pytorch by instructions at https://pytorch.org/ For example:

```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
```

4. Clone the repository:

```bash
git clone https://github.com/KMiNT21/hylang-ml-examples.git
cd hylang-ml-examples
```

## Contributing

I welcome your contributions!

 ![LISP](hy-hylang-python-lisp.jpg)
---

*"In Lisp, you don't just write your program; your program writes your program"*

**Note**: This project is meant for both educational purposes and practical applications. It demonstrates how functional programming patterns and Lisp's unique features can bring clarity and power to machine learning code.