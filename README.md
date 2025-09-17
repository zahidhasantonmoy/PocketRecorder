# PocketRecorder

A background media capture app that lets users capture photos, videos, and audio recordings using customizable slap/tap patterns on the back of the phone.

## Core Idea

Unlike traditional capture apps, PocketRecorder uses motion detection sensors (accelerometer & gyroscope) instead of buttons to trigger media capture. This enables covert recording capabilities for security/ investigation purposes, journalists/activists, and general users who want fun gesture-based triggers.

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

## Development Status

This is a work-in-progress Flutter application. The core architecture is being implemented with the following components:

1. Gesture detection using device sensors
2. Background media capture services
3. Secure storage with encryption
4. Customizable gesture mapping
5. Security features (app lock, emergency delete)
6. Stealth mode capabilities

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Connect an Android device or start an emulator
4. Run `flutter run` to build and deploy the app

## Dependencies

- `sensors_plus`: For tap/slap detection
- `camera`: For background image capture
- `flutter_sound`: For audio recording
- `encrypt`: For file encryption
- `hive`: For local data storage
- `permission_handler`: For handling app permissions

## Architecture

The app follows a clean architecture pattern with the following layers:

- **UI Layer**: Screens and widgets for user interaction
- **Service Layer**: Business logic and integration with device features
- **Model Layer**: Data models and entities
- **Utility Layer**: Helper functions and utilities

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.