# ML Training Pipeline

Trains and exports the MobileNetV2 trash-classification model used by the
Flutter app (on-device inference) and the PC vision detector.

## Folder Structure

```
smart_bin_flutter_backend/
├── train_model.py          # Fine-tune MobileNetV2 on dataset/
├── convert_to_tflite.py    # Export .h5 → model.tflite (quantised)
├── dataset/                # Training images  ← git-ignored (large)
│   ├── metal/
│   ├── paper/
│   └── plastic/
├── models/                 # Saved Keras model  ← git-ignored
│   └── trash_classifier.h5
└── exports/                # Ready-to-use artefacts
    ├── model.tflite        # Quantised TFLite model
    ├── labels.txt          # One class per line (metal / paper / plastic)
    └── class_indices.json  # {"metal":0, "paper":1, "plastic":2}
```

## Requirements

```bash
pip install tensorflow
```

## Steps

### 1 – Prepare the dataset

Populate `dataset/` with images, one sub-folder per class:
```
dataset/metal/   ← photos of metal items
dataset/paper/   ← photos of paper items
dataset/plastic/ ← photos of plastic items
```
Aim for at least 200 images per class.

### 2 – Train

```bash
python train_model.py
```
Trains for 5 epochs (edit `epochs=5` in the script to change).
Saves the model to `models/trash_classifier.h5`.

### 3 – Export to TFLite

```bash
python convert_to_tflite.py
```
Applies DEFAULT quantisation and writes `exports/model.tflite`.

### 4 – Copy to the Flutter app

```bash
cp exports/model.tflite  ../smart_bin_flutter/assets/model.tflite
cp exports/labels.txt    ../smart_bin_flutter/assets/labels.txt
```

Then rebuild the Flutter app (`flutter run`).

## Model Details

| Property | Value |
|----------|-------|
| Base model | MobileNetV2 (ImageNet weights) |
| Input size | 224 × 224 × 3 |
| Output classes | metal, paper, plastic |
| Optimisation | Default quantisation |
