import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'pattern_detector.dart';
import '../services/settings_service.dart' as pattern_settings_service;
import 'pattern_storage_service.dart';
import '../models/pattern_setting.dart';
import '../models/pattern_signature.dart';
import 'app_settings_service.dart' as app_settings_service;
import '../models/app_settings.dart';

class BackgroundPatternDetectionService {
  static final BackgroundPatternDetectionService _instance = 
      BackgroundPatternDetectionService._internal();
  
  factory BackgroundPatternDetectionService() => _instance;
  
  BackgroundPatternDetectionService._internal();

  PatternDetector? _patternDetector;
  List<PatternSetting> _patternSettings = [];
  List<PatternSignature> _customPatterns = [];
  bool _isServiceRunning = false;
  bool _isDiscreetMode = false;
  StreamSubscription<int>? _proximitySubscription; // For proximity sensor events

  Future<void> startBackgroundService() async {
    if (_isServiceRunning) return;
    
    // Load settings to check if discreet mode is enabled
    final settings = await app_settings_service.SettingsService().getAppSettings();
    _isDiscreetMode = settings.discreetMode;
    
    // Load pattern settings
    _patternSettings = await pattern_settings_service.SettingsService().getPatternSettings();
    _customPatterns = await PatternStorageService().getPatterns();
    
    // Initialize pattern detector
    _patternDetector = PatternDetector(
      onPatternDetected: _handlePatternDetected,
      onPatternTimeout: () {},
    );
    
    // Start listening to proximity sensor
    _startProximityListening();
    
    _isServiceRunning = true;
    
    // Start foreground service to keep running in background
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'pattern_detection_channel',
        channelName: _isDiscreetMode ? 'Background Service' : 'Pattern Detection Service',
        channelDescription: _isDiscreetMode 
            ? 'Keeping app running in background' 
            : 'Detects tap patterns on the back of the device',
        channelImportance: _isDiscreetMode 
            ? NotificationChannelImportance.NONE 
            : NotificationChannelImportance.LOW,
        priority: _isDiscreetMode 
            ? NotificationPriority.MIN 
            : NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    
    FlutterForegroundTask.startService(
      notificationTitle: _isDiscreetMode ? '' : 'PocketRecorder',
      notificationText: _isDiscreetMode 
          ? '' 
          : 'Listening for tap patterns...',
    );
  }

  void _handlePatternDetected(int tapCount) {
    // Create a pattern signature from the detected taps
    List<double> timestamps = [];
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    // Create timestamps with 200ms intervals (arbitrary for demo)
    for (int i = 0; i < tapCount; i++) {
      timestamps.add(now - (tapCount - i - 1) * 200);
    }
    
    final detectedPattern = PatternSignature(
      id: 'detected_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Detected Pattern',
      timestamps: timestamps,
      createdAt: DateTime.now(),
    );
    
    // First check custom patterns with 60% tolerance
    for (final pattern in _customPatterns) {
      if (pattern.matches(detectedPattern, tolerance: 0.6)) {
        _executePatternFunction(pattern.assignedFunction);
        return;
      }
    }
    
    // If no custom pattern matches, check default patterns
    final matchingPattern = _patternSettings.firstWhere(
      (pattern) => pattern.tapCount == tapCount,
      orElse: () => PatternSetting(
        tapCount: tapCount,
        functionName: 'Unknown',
        functionType: 'unknown',
      ),
    );
    
    // Handle the detected pattern
    _executePatternFunction(matchingPattern.functionType);
  }

  void _executePatternFunction(String functionType) {
    switch (functionType) {
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
    _stopProximityListening();
    FlutterForegroundTask.stopService();
    _isServiceRunning = false;
  }

  bool get isServiceRunning => _isServiceRunning;
  
  // Method to update service when settings change
  Future<void> updateSettings() async {
    final settings = await app_settings_service.SettingsService().getAppSettings();
    final newDiscreetMode = settings.discreetMode;
    
    if (_isDiscreetMode != newDiscreetMode) {
      _isDiscreetMode = newDiscreetMode;
      
      // Restart service with new settings
      stopBackgroundService();
      await startBackgroundService();
    }
  }
  
  // Start listening to proximity sensor events
  void _startProximityListening() {
    try {
      _proximitySubscription = ProximitySensor.events.listen((event) {
        // Update the pattern detector with the proximity state
        // In the proximity_sensor package, > 0 means near
        _patternDetector?.updateProximityState(event > 0);
      });
    } catch (e) {
      print('Proximity sensor not supported: $e');
    }
  }
  
  // Stop listening to proximity sensor events
  void _stopProximityListening() {
    _proximitySubscription?.cancel();
  }
}