import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/pattern_signature.dart';

class PatternRecordingService with ChangeNotifier {
  static final PatternRecordingService _instance = PatternRecordingService._internal();
  factory PatternRecordingService() => _instance;
  PatternRecordingService._internal();

  bool _isRecording = false;
  List<double> _tapTimestamps = [];
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  
  // Constants for tap detection
  static const double _tapThreshold = 15.0; // Acceleration threshold for tap detection
  static const int _maxTimeBetweenTaps = 1000; // Max time between taps in milliseconds

  // Getters
  bool get isRecording => _isRecording;
  List<double> get tapTimestamps => _tapTimestamps;

  // Start recording a new pattern
  void startRecording() {
    if (_isRecording) return;
    
    _isRecording = true;
    _tapTimestamps.clear();
    
    // Start listening to accelerometer events
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = userAccelerometerEvents.listen((event) {
      _processAccelerometerEvent(event);
    });
    
    notifyListeners();
  }

  // Stop recording and return the pattern
  PatternSignature? stopRecording({String name = 'Custom Pattern', String function = 'custom'}) {
    if (!_isRecording) return null;
    
    _isRecording = false;
    _accelerometerSubscription?.cancel();
    
    if (_tapTimestamps.isEmpty) {
      notifyListeners();
      return null;
    }
    
    final pattern = PatternSignature(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      timestamps: List.from(_tapTimestamps),
      createdAt: DateTime.now(),
      assignedFunction: function,
    );
    
    _tapTimestamps.clear();
    notifyListeners();
    
    return pattern;
  }

  // Cancel recording
  void cancelRecording() {
    if (!_isRecording) return;
    
    _isRecording = false;
    _accelerometerSubscription?.cancel();
    _tapTimestamps.clear();
    notifyListeners();
  }

  // Process accelerometer events to detect taps
  void _processAccelerometerEvent(UserAccelerometerEvent event) {
    if (!_isRecording) return;
    
    // Calculate the magnitude of acceleration
    final magnitude = event.x * event.x + event.y * event.y + event.z * event.z;
    
    // Check if the acceleration exceeds the threshold
    if (magnitude > _tapThreshold * _tapThreshold) {
      _onTapDetected();
    }
  }

  // Handle tap detection
  void _onTapDetected() {
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    
    // Add timestamp if it's the first tap or if enough time has passed since the last tap
    if (_tapTimestamps.isEmpty || 
        (now - _tapTimestamps.last) > _maxTimeBetweenTaps) {
      _tapTimestamps.add(now);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}