# PocketRecorder

A background media capture app that lets users capture photos, videos, and audio recordings using customizable slap/tap patterns on the back of the phone.

## Core Idea

Unlike traditional capture apps, PocketRecorder uses motion detection sensors (accelerometer & gyroscope) instead of buttons to trigger media capture. This enables covert recording capabilities for security/investigation purposes, journalists/activists, and general users who want fun gesture-based triggers.

## Features

### Core Features
- **Tap/Slap Gesture Detection**: Uses accelerometer + gyroscope data to identify specific tap/slap patterns
- **Background Image Capture**: Triggers camera service in background using Android CameraX API
- **Background Video Recording**: Starts video recording via foreground service
- **Background Audio Recording**: Uses MediaRecorder for background audio capture
- **Custom Trigger Mapping**: Assign tap/slap gestures to specific actions

### Security & Privacy
- **App Lock**: PIN, Password, Fingerprint authentication
- **Encrypted Media Storage**: Files encrypted with AES before saving
- **Emergency Delete**: Shake phone or enter secret PIN to instantly delete all media

### Stealth Features
- **Stealth Mode**: No UI, no preview; capture works even when screen is off
- **Hidden App Icon**: Access app via secret dial code or settings menu
- **Fake Notifications**: Shows "System Update" or "Battery Optimization" message instead of real purpose

## Platform Support

- **Android**: Full support (background camera + sensors)
- **iOS**: Limited support (Apple restricts background camera/audio)

## Getting Started

### Prerequisites
- Flutter 3.32.8 or higher
- Android SDK 24 or higher
- Android device or emulator for testing

### Installation
1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```
   cd PocketRecorder
   ```
3. Install dependencies:
   ```
   flutter pub get
   ```

### Building the App
1. Connect an Android device or start an Android emulator
2. Build the APK:
   ```
   flutter build apk
   ```
3. The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`

### Running the App
1. Connect an Android device or start an Android emulator
2. Run the app in debug mode:
   ```
   flutter run
   ```
3. To run in release mode:
   ```
   flutter run --release
   ```

### Testing Gesture Detection
1. Open the app on your Android device
2. Grant all requested permissions
3. Try double-tapping the back of your phone to capture a photo
4. Try triple-tapping to start/stop video recording
5. Try a long slap to start/stop audio recording

## Project Structure
```
lib/
├── main.dart                   # App entry point
├── screens/                    # UI screens
│   ├── home_screen.dart        # Main screen with gesture feedback
│   ├── settings_screen.dart    # App settings and gesture mapping
│   ├── media_gallery_screen.dart # View captured media
│   ├── gesture_training_screen.dart # Train gesture recognition
│   └── security_screen.dart    # Security settings
├── services/                   # Business logic
│   ├── gesture_detection_service.dart # Gesture recognition
│   ├── media_capture_service.dart # Media capture functionality
│   └── encryption_service.dart # File encryption
├── models/                     # Data models
│   └── gesture_pattern.dart    # Gesture and action models
└── utils/                      # Utility functions
    └── permission_utils.dart   # Permission handling
```

## Dependencies

- `sensors_plus`: For tap/slap detection using accelerometer and gyroscope
- `camera`: For background image and video capture
- `flutter_sound`: For audio recording
- `encrypt`: For AES file encryption
- `hive`: For local data storage
- `permission_handler`: For handling app permissions
- `workmanager`: For background task scheduling

## Architecture

The app follows a clean architecture pattern with the following layers:

- **UI Layer**: Screens and widgets for user interaction
- **Service Layer**: Business logic and integration with device features
- **Model Layer**: Data models and entities
- **Utility Layer**: Helper functions and utilities

## Development Summary

This project has successfully implemented all core features including:
- Gesture detection using device sensors
- Background media capture services
- Secure storage with encryption
- Customizable gesture mapping
- Security features (app lock, emergency delete)
- Stealth mode capabilities

For a complete development summary, see [DEVELOPMENT_SUMMARY.md](DEVELOPMENT_SUMMARY.md).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.