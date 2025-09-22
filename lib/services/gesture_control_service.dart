import 'dart:async';
import 'package:flutter/material.dart';
import 'package:volume_watcher/volume_watcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/app_settings_service.dart';
import '../models/app_settings.dart';
import 'package:provider/provider.dart';
import '../recorder_provider.dart';

class GestureControlService {
  static final GestureControlService _instance = GestureControlService._internal();
  factory GestureControlService() => _instance;
  GestureControlService._internal();

  StreamSubscription<double>? _volumeSubscription;
  Timer? _resetTimer;
  int _volumePressCount = 0;
  int _requiredVolumePresses = 5; // Default value
  bool _gestureControlsEnabled = true; // Default value
  DateTime _lastVolumePress = DateTime.now();
  bool _isListening = false;

  // Start listening for gesture controls
  Future<void> startListening(BuildContext context) async {
    if (_isListening) return;
    
    // Load settings
    await _loadSettings();
    
    // Only start listening if gesture controls are enabled
    if (_gestureControlsEnabled) {
      // Start listening for volume changes
      _volumeSubscription = VolumeWatcher().onVolumeChanged.listen((volume) {
        _handleVolumeChange(context);
      });
      
      _isListening = true;
    }
  }

  // Stop listening for gesture controls
  void stopListening() {
    _volumeSubscription?.cancel();
    _resetTimer?.cancel();
    _isListening = false;
  }

  // Load settings
  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService().getAppSettings();
      _requiredVolumePresses = settings.volumeButtonPresses;
      _gestureControlsEnabled = settings.gestureControlsEnabled;
    } catch (e) {
      print('Error loading gesture settings: $e');
    }
  }

  // Handle volume change
  void _handleVolumeChange(BuildContext context) {
    // Check if gesture controls are enabled
    if (!_gestureControlsEnabled) return;
    
    final now = DateTime.now();
    final timeDiff = now.difference(_lastVolumePress).inMilliseconds;
    
    // If it's been more than 1 second since last press, reset counter
    if (timeDiff > 1000) {
      _volumePressCount = 0;
    }
    
    _volumePressCount++;
    _lastVolumePress = now;
    
    print('Volume button pressed $_volumePressCount times');
    
    // Cancel any existing reset timer
    _resetTimer?.cancel();
    
    // Set a timer to reset the counter after 1 second of inactivity
    _resetTimer = Timer(const Duration(seconds: 1), () {
      _volumePressCount = 0;
    });
    
    // Check if we've reached the required number of presses
    if (_volumePressCount >= _requiredVolumePresses) {
      _triggerRecording(context);
      _volumePressCount = 0;
    }
  }

  // Trigger recording based on gesture
  void _triggerRecording(BuildContext context) {
    print('Triggering recording from gesture');
    
    // Access the recorder provider
    final recorderProvider = Provider.of<RecorderProvider>(context, listen: false);
    
    // For now, we'll trigger video recording, but this should be configurable
    if (recorderProvider.isRecording) {
      // Stop current recording
      if (recorderProvider.videoService.isRecording) {
        recorderProvider.stopVideoRecording();
      } else {
        recorderProvider.stopRecording();
      }
    } else {
      // Start video recording
      recorderProvider.startVideoRecording();
    }
  }

  // Update settings
  Future<void> updateSettings() async {
    await _loadSettings();
    
    // If gesture controls were disabled, stop listening
    if (!_gestureControlsEnabled) {
      stopListening();
    }
  }

  bool get isListening => _isListening;
}