# Smart Bin Recognition System

This project detects recyclable waste using a mobile camera and TensorFlow Lite.

## Detects

Plastic
Paper
Metal

## Run Backend

cd smart_bin_backend
pip install -r requirements.txt
python train_model.py
dataset => metal, paper, plastic

## Run Mobile App

cd smart_bin_recognition
flutter pub get
flutter run


datasets=> assets-> labels.txt and model.tflite