# PocketRecorder

A tactile-triggered personal security application built with Flutter. By tapping on the back of the phone in specific patterns, users can instantly start recording audio, video, or capture images — without unlocking or opening the app.

## 🌟 Features

### Tactile Pattern Detection
- **2 taps** → Start audio recording
- **3 taps** → Start video recording
- **4 taps** → Capture image
- **5 taps** → SOS alert
- Customizable pattern mapping
- Smart matching (works with ~60% pattern accuracy for emergency reliability)

### Recording & Capture Controls
- Audio recording with multiple quality options
- Video recording with front/back camera selection
- Silent image capture for discreet use
- Auto-stop settings (30s, 1 min, 5 min, etc.)

### File Management & Security
- Secure vault with password protection
- PIN, pattern, or biometric unlock options
- Separate tabs for Audio, Video, and Images
- Direct actions: View, share, delete files

### Customization Options
- Remap gesture patterns to functions
- Select default camera (front/back)
- Choose storage location (app vault, phone storage, cloud)
- Select file formats (MP3/WAV, MP4/AVI, JPG/PNG)
- Quality settings (Low/Medium/High)

### Home Dashboard
- Quick buttons for Audio, Video, Image
- Status indicators for ongoing recordings
- Emergency Stop All Recordings button
- Recent activity preview

### Background Operation
- Always running in background
- Works even when screen is off or app is closed
- Discreet hidden notification

### Security & Privacy
- App lock with password/biometric
- Vault content protection
- Discreet mode (hidden app icon/notifications)

### Additional Smart Features
- SOS Mode with location sharing
- Battery-safe mode
- Cloud backup (Google Drive/Dropbox)
- Auto-cleanup options

## 🎨 UI/UX Design

Modern minimal interface with:
- Intuitive bottom navigation
- Animated transitions
- Dark/light mode support
- Responsive design for all screen sizes

## 🛠️ Developer Info

**Zahid Hasan Tonmoy**
- Senior Flutter Developer & UI/UX Master
- [Portfolio](https://zahidhasantonmoy.vercel.app)
- [Facebook](https://www.facebook.com/zahidhasantonmoybd)
- [LinkedIn](https://www.linkedin.com/in/zahidhasantonmoy/)
- [GitHub](https://github.com/zahidhasantonmoy)

## 🚀 Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Connect your device
4. Run `flutter run`

## 📱 Permissions Required

- Camera
- Microphone
- Storage
- Background service

## 📦 Dependencies

- flutter_sound: Audio recording/playback
- sensors_plus: Tactile pattern detection
- camera: Video recording/image capture
- flutter_secure_storage: Secure data storage
- provider: State management
- permission_handler: Permission management
- path_provider: File storage
- intl: Date/time formatting
- share_plus: File sharing
- flutter_foreground_task: Background service
- url_launcher: External link handling

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.