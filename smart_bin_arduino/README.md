# Smart Bin – Arduino & Edge Tools

This folder contains everything that runs on (or next to) the physical bin.

## Contents

| File | Description |
|------|-------------|
| `arduino.ino` | Arduino firmware (ultrasonic sensors + servo motors) |
| `vision_detector.py` | PC webcam classifier – detects trash type, tells bridge to open bin |
| `simulate_firebase.py` | Push fake bin levels to Firebase (test without hardware) |
| `test_arduino.py` | Verify serial communication with the Arduino |
| `requirements.txt` | Python dependencies for the edge tools |

## Arduino Hardware

| Component | Pin(s) |
|-----------|--------|
| Plastic ultrasonic (HC-SR04) trigger / echo | 2 / 4 |
| Paper ultrasonic (HC-SR04) trigger / echo | 7 / 9 |
| Metal ultrasonic (HC-SR04) trigger / echo | 8 / 10 |
| Plastic servo | 3 |
| Paper servo | 5 |
| Metal servo | 6 |

## Flashing the Arduino

1. Open `arduino.ino` in the Arduino IDE.
2. Select your board (e.g. Arduino Uno) and the correct COM port.
3. Click **Upload**.

## Running the Vision Detector

The detector captures webcam frames, runs the TFLite model, and sends
the open-bin command to `arduino_bridge.py` when it is confident enough.

```bash
pip install -r requirements.txt

python vision_detector.py \
  --model  ../smart_bin_flutter_backend/exports/model.tflite \
  --labels ../smart_bin_flutter_backend/exports/labels.txt \
  --bridge-url http://127.0.0.1:5000
```

Press **q** to quit.

## Simulating Without Hardware

```bash
python simulate_firebase.py \
  --firebase-url https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com
```

Updates `bin_status/` in Firebase every 3 seconds with random values
so you can test the Flutter app without a physical bin.

## Testing Serial Communication

```bash
python test_arduino.py
```

Sends `P` (plastic) and `S` (paper) commands and prints the response.
