# PocketRecorder

A modern Android application for background recording triggered by tap patterns.

## Features

- **Customizable Tap/Hit Pattern Detection**: Detects tap patterns to trigger recordings.
- **Location Tracking and Metadata**: Adds GPS location and timestamps to recordings.
- **Encryption and Security**: Encrypts files and uses biometric authentication.
- **Smart Notifications**: Provides notifications for recording status.
- **Automatic File Management**: Categorizes and cleans up old files.
- **Voice Command Integration**: Triggers recordings with voice commands.
- **Smart Sensor Integration**: Prevents accidental recordings.
- **Emergency Mode**: Sends location and files via SMS.
- **Battery Optimization**: Efficiently uses resources.
- **Tutorial Mode**: Guides users through the app's features.
- **Multilingual Support**: Supports English and Bengali.

## Setup

1. Open the project in Android Studio.
2. Sync Gradle dependencies.
3. Run the app on an Android device or emulator.

PocketRecorder Android App Development Plan

Overview

The PocketRecorder app is an Android application that runs in the background, enabling users to trigger audio, video, and image capture via tap patterns on their phone, even when in their pocket. Built with Kotlin and Jetpack Compose for a modern UI/UX, it prioritizes privacy, security, and customization. This plan uses a single Gemini CLI prompt to generate all features in one phase, with Git commits after each edit.

Features and Working Principles





Customizable Tap/Hit Pattern Detection:





Detects taps (3 for audio, 4 for video, 2 for image) using Sensor.TYPE_ACCELEROMETER in TapDetectionService.kt.



Customizable tap count (2–5), sensitivity, and 1-second threshold via SharedPreferences and settings UI.



Example: 3 taps in pocket → audio recording starts.



Location Tracking and Metadata:





Adds GPS location and timestamp to files using Fused Location Provider.



Stores metadata in Room Database (LocationDao.kt).



Caches location offline.



Example: Video file includes metadata (latitude: 23.8103, time: 2025-07-28 20:52:30).



Encryption and Security:





Encrypts files with Jetpack Security’s EncryptedFile.



Uses BiometricPrompt or PIN for access.



Hides files with .nomedia.



Example: Image accessible only after fingerprint authentication.



Smart Notifications:





Shows vibration/icon via NotificationCompat.Builder when recording starts/stops.



Customizable notification type and vibration patterns.



Example: 200ms vibration confirms recording start.



Automatic File Management:





Categorizes files in /audio, /video, /image.



WorkManager cleans files older than 30 days (FileCleanupWorker.kt).



Sets recording quality via settings.



Example: Old files deleted to save storage.



Voice Command Integration:





Triggers recording with SpeechRecognizer (e.g., “start recording”).



Custom passphrases and sensitivity settings.



Example: Voice command starts audio recording.



Smart Sensor Integration:





Uses Sensor.TYPE_PROXIMITY and Sensor.TYPE_ORIENTATION to restrict recording to pocket/upright phone.



Toggle via settings.



Example: Taps ignored if phone is on table.



Emergency Mode:





5 rapid taps send location/files via SMS (SmsManager).



Contacts stored in ContactDao.kt.



Example: SMS sent to contact with location data.



Battery Optimization:





Uses SENSOR_DELAY_NORMAL and WorkManager for efficiency.



Handles Doze Mode with Foreground Service.



Example: Low battery usage in background.



Tutorial Mode:





Jetpack Compose tutorial screen (TutorialScreen.kt) for onboarding.



Skip/repeat option.



Example: User practices tap patterns.



Multilingual Support:





Supports Bengali/English with res/values-bn/strings.xml.



Language selection in settings.



Example: UI shows “রেকর্ডিং শুরু” in Bengali.