import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'pattern_detector.dart';
import 'settings_service.dart';
import '../models/pattern_setting.dart';

class BackgroundPatternDetectionService {
  static final BackgroundPatternDetectionService _instance = 
      BackgroundPatternDetectionService._internal();
  
  factory BackgroundPatternDetectionService() => _instance;
  
  BackgroundPatternDetectionService._internal();

  PatternDetector? _patternDetector;
  List<PatternSetting> _patternSettings = [];
  bool _isServiceRunning = false;

  Future<void> startBackgroundService() async {
    if (_isServiceRunning) return;
    
    // Load pattern settings
    _patternSettings = await SettingsService().getPatternSettings();
    
    // Initialize pattern detector
    _patternDetector = PatternDetector(
      onPatternDetected: _handlePatternDetected,
      onPatternTimeout: () {},
    );
    
    _isServiceRunning = true;
    
    // Start foreground service to keep running in background
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'pattern_detection_channel',
        channelName: 'Pattern Detection Service',
        channelDescription: 'Detects tap patterns on the back of the device',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    
    FlutterForegroundTask.startService(
      notificationTitle: 'PocketRecorder',
      notificationText: 'Listening for tap patterns...',
    );
  }

  void _handlePatternDetected(int tapCount) {
    // Find matching pattern setting
    final matchingPattern = _patternSettings.firstWhere(
      (pattern) => pattern.tapCount == tapCount,
      orElse: () => PatternSetting(
        tapCount: tapCount,
        functionName: 'Unknown',
        functionType: 'unknown',
      ),
    );
    
    // Handle the detected pattern
    _executePatternFunction(matchingPattern);
  }

  void _executePatternFunction(PatternSetting pattern) {
    switch (pattern.functionType) {
      case 'audio':
        // Start audio recording
        _startAudioRecording();
        break;
      case 'video':
        // Start video recording
        _startVideoRecording();
        break;
      case 'image':
        // Capture image
        _captureImage();
        break;
      case 'sos':
        // Send SOS alert
        _sendSOSAlert();
        break;
      default:
        // Unknown pattern, do nothing
        break;
    }
  }

  void _startAudioRecording() {
    // Implementation for starting audio recording
    print('Starting audio recording...');
    // This would interact with the RecorderProvider to start recording
  }

  void _startVideoRecording() {
    // Implementation for starting video recording
    print('Starting video recording...');
    // This would start the camera and begin recording
  }

  void _captureImage() {
    // Implementation for capturing image
    print('Capturing image...');
    // This would take a photo with the camera
  }

  void _sendSOSAlert() {
    // Implementation for sending SOS alert
    print('Sending SOS alert...');
    // This would send location and alert to trusted contacts
  }

  void stopBackgroundService() {
    _patternDetector?.stopListening();
    FlutterForegroundTask.stopService();
    _isServiceRunning = false;
  }

  bool get isServiceRunning => _isServiceRunning;
}