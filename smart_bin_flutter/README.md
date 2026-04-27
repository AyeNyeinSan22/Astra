# Astra Mobile App

Flutter app for the Astra Smart Bin system (iOS & Android).

## Features

| Screen | What it does |
|--------|-------------|
| Home | Shows live bin fill levels from Firebase + points, eco-forest, activity feed |
| AI Scanner | On-device camera + TFLite model to identify plastic/paper/metal |
| Eco Shop | Redeem recycling points for rewards |
| Daily Habits | Earn bonus points for eco-friendly behaviour |
| CO₂ Dashboard | Track your environmental impact |
| Account / Settings | Profile management |

## Firebase Setup (required)

The bin fill levels are read from **Firebase Realtime Database** in real time.
You must connect the app to your own Firebase project before running.

### Option A – FlutterFire CLI (recommended)

```bash
# 1. Install the CLI
dart pub global activate flutterfire_cli

# 2. Log in
firebase login

# 3. Run inside smart_bin_flutter/
flutterfire configure
# → choose your project, it rewrites lib/firebase_options.dart automatically
```

### Option B – Manual

1. Open [Firebase Console](https://console.firebase.google.com/) → Project Settings → Your Apps.
2. Edit `lib/firebase_options.dart` and replace every `YOUR_*` placeholder with your real values.
3. Download `google-services.json` (Android) and place it at `android/app/google-services.json`.
4. Download `GoogleService-Info.plist` (iOS) and place it at `ios/Runner/GoogleService-Info.plist`.

### Firebase Database Rules (for testing)

```json
{
  "rules": {
    ".read":  true,
    ".write": true
  }
}
```

> ⚠️ Restrict these rules before going to production.

## Running the App

```bash
flutter pub get
flutter run
```

## Architecture

```
lib/
├── main.dart                    # Firebase.initializeApp() + MaterialApp
├── firebase_options.dart        # Your project credentials (git-ignored)
├── backend/
│   ├── bin_level_service.dart   # Firebase stream → BinLevels
│   └── local_auth_backend.dart  # In-memory user state (points, activities)
├── screens/
│   ├── home_screen.dart         # Live bin levels + gamification dashboard
│   ├── camera_scanner_screen.dart  # TFLite on-device inference
│   ├── eco_shop_screen.dart
│   ├── habit_checklist_screen.dart
│   ├── co2_dashboard_screen.dart
│   └── ...                      # Auth screens
├── widgets/
│   ├── astra_logo.dart
│   └── shared_widgets.dart
└── wifi_bin_monitor.dart        # Manual Wi-Fi monitor (debug/local use)
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase SDK initialisation |
| `firebase_database` | Realtime Database stream for bin levels |
| `tflite_flutter` | On-device AI trash scanner |
| `camera` | Live camera preview for scanner |
| `geolocator` / `geocoding` | Show current location on home screen |
| `google_fonts` | Poppins typeface |
