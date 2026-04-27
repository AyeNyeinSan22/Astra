# Astra – Smart Bin Recycling System

Astra is an IoT + mobile app system that helps people recycle correctly.
A physical smart bin detects trash type, opens the right lid automatically,
and reports fill levels to the Flutter app through Firebase Realtime Database.

---

## Repository Layout

```
Astra/
├── smart_bin_flutter/          # 📱 Flutter mobile app (iOS & Android)
├── smart_bin_arduino/          # 🔌 Arduino firmware + PC edge tools
│   ├── arduino.ino             #    Arduino sketch (sensors + servos)
│   ├── vision_detector.py      #    PC webcam trash detector
│   ├── simulate_firebase.py    #    Simulate bin data without hardware
│   ├── test_arduino.py         #    Test serial communication
│   └── requirements.txt        #    Python deps for edge tools
├── smart_bin_flutter_backend/  # 🤖 ML training pipeline (MobileNetV2)
│   ├── train_model.py          #    Fine-tune model on dataset/
│   ├── convert_to_tflite.py    #    Export .h5 → model.tflite
│   ├── dataset/                #    Training images (metal/paper/plastic)
│   ├── models/                 #    Saved Keras model (.h5)
│   └── exports/                #    model.tflite + labels.txt for Flutter
└── arduino_bridge.py           # 🌉 USB → Wi-Fi + Firebase bridge (run on PC)
```

---

## How the System Works

```
┌─────────────────────┐    USB serial     ┌─────────────────────────┐
│  Arduino            │ ────────────────► │  arduino_bridge.py (PC)  │
│  Ultrasonic sensors │                   │  - Reads DATA|P|S|M      │
│  Servo motors       │ ◄──────────────── │  - Pushes to Firebase    │
└─────────────────────┘   P / S / M cmd   │  - REST API on :5000     │
                                          └──────────┬──────────────┘
                                                     │ HTTPS (Firebase REST)
                                          ┌──────────▼──────────────┐
                                          │  Firebase Realtime DB    │
                                          │  bin_status/             │
                                          │    plastic: 45           │
                                          │    paper:   72           │
                                          │    metal:   10           │
                                          └──────────┬──────────────┘
                                                     │ real-time stream
                                          ┌──────────▼──────────────┐
                                          │  Flutter App (Astra)     │
                                          │  • Live bin fill levels  │
                                          │  • AI trash scanner      │
                                          │  • Points / eco shop     │
                                          └─────────────────────────┘
```

---

## Quick Start

### 1 – Set up Firebase

1. Go to <https://console.firebase.google.com/> and create a new project.
2. Enable **Realtime Database** (Build → Realtime Database → Create database).
3. Set rules to allow read/write while testing:
   ```json
   { "rules": { ".read": true, ".write": true } }
   ```
4. Note your database URL, e.g. `https://my-project-default-rtdb.firebaseio.com`.

### 2 – Configure the Flutter app

```bash
cd smart_bin_flutter

# Option A – automatic (recommended)
dart pub global activate flutterfire_cli
firebase login
flutterfire configure          # rewrites lib/firebase_options.dart automatically

# Option B – manual
# Edit lib/firebase_options.dart and replace every YOUR_* placeholder
# with real values from Firebase Console → Project Settings → Your Apps.
```

For **Android** you also need `google-services.json`:
- Firebase Console → Your Android app → Download `google-services.json`
- Place it at `smart_bin_flutter/android/app/google-services.json`

For **iOS** you also need `GoogleService-Info.plist`:
- Firebase Console → Your iOS app → Download `GoogleService-Info.plist`
- Place it at `smart_bin_flutter/ios/Runner/GoogleService-Info.plist`

### 3 – Run the Flutter app

```bash
cd smart_bin_flutter
flutter pub get
flutter run
```

### 4 – Run the Arduino bridge (PC)

```bash
pip install flask pyserial requests

# With Firebase push enabled:
python arduino_bridge.py \
  --firebase-url https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com

# Without Firebase (local REST only):
python arduino_bridge.py
```

### 5 – Test without hardware

Use the simulator to push fake bin levels to Firebase:

```bash
cd smart_bin_arduino
pip install requests
python simulate_firebase.py \
  --firebase-url https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com
```

### 6 – Train / update the AI model (optional)

```bash
cd smart_bin_flutter_backend
pip install tensorflow
python train_model.py          # trains on dataset/  → saves models/trash_classifier.h5
python convert_to_tflite.py    # converts → exports/model.tflite

# Copy exported files to the Flutter app assets
cp exports/model.tflite  ../smart_bin_flutter/assets/model.tflite
cp exports/labels.txt    ../smart_bin_flutter/assets/labels.txt
```

---

## Firebase Database Structure

The Arduino bridge writes to `bin_status/` every ~3 seconds:

| Field          | Type   | Description                            |
|----------------|--------|----------------------------------------|
| `plastic`      | int    | Plastic bin fill level (0–100 %)       |
| `paper`        | int    | Paper bin fill level (0–100 %)         |
| `metal`        | int    | Metal bin fill level (0–100 %)         |
| `last_updated` | string | ISO-8601 timestamp of the last write   |

---

## Arduino Serial Protocol

The Arduino (`arduino.ino`) communicates with the bridge over USB at 9600 baud.

**Output** (every 3 s):
```
DATA|<plastic%>|<paper%>|<metal%>
```
Example: `DATA|45|72|10`

**Input** (single ASCII byte):
| Command | Effect |
|---------|--------|
| `P` | Open plastic bin lid for 4 s |
| `S` | Open paper (stationery) bin lid for 4 s |
| `M` | Open metal bin lid for 4 s |
