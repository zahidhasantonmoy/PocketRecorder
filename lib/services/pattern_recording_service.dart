import 'dart:async';
import 'dart:math' as math;
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
  int? _lastTapTime; // For debouncing
  
  // Improved constants for tap detection
  static const double _tapThreshold = 1.2; // Lowered acceleration threshold for better tap detection
  static const int _maxTimeBetweenTaps = 1000; // Max time between taps in milliseconds
  static const int _debounceTime = 200; // Time to ignore subsequent taps (debouncing)

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
    _lastTapTime = null; // Reset debouncing state
    notifyListeners();
    
    return pattern;
  }

  // Cancel recording
  void cancelRecording() {
    if (!_isRecording) return;
    
    _isRecording = false;
    _accelerometerSubscription?.cancel();
    _tapTimestamps.clear();
    _lastTapTime = null; // Reset debouncing state
    notifyListeners();
  }

  // Process accelerometer events to detect taps
  double _prevMagnitude = 0.0;
  double _prevDelta = 0.0;
  void _processAccelerometerEvent(UserAccelerometerEvent event) {
    if (!_isRecording) return;
    
    // Calculate the magnitude of acceleration
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    
    // Apply exponential moving average filter
    final filteredMagnitude = 0.7 * magnitude + 0.3 * _prevMagnitude;
    _prevMagnitude = filteredMagnitude;
    
    // Check if the change is significant enough to be a tap
    final delta = (filteredMagnitude - 9.81).abs(); // Subtract gravity
    
    // Apply high-pass filtering to focus on transient events
    final deltaChange = delta - _prevDelta;
    _prevDelta = delta;
    
    // Check if we have a sharp transient (tap signature)
    final isTransient = deltaChange > 0.5 && delta > _tapThreshold;
    
    // Check if the acceleration exceeds the threshold
    if (isTransient) {
      _onTapDetected();
    }
  }
  
  // Helper function for square root
  double sqrt(double value) {
    return value <= 0 ? 0 : math.sqrt(value);
  }

  // Handle tap detection with debouncing
  void _onTapDetected() {
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    
    // Implement debouncing - ignore taps that are too close together
    if (_lastTapTime != null) {
      final timeSinceLastTap = (now - _lastTapTime!).toInt();
      if (timeSinceLastTap < _debounceTime) {
        return; // Ignore this tap, it's too soon after the last one
      }
    }
    
    // Update last tap time
    _lastTapTime = now.toInt();
    
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
    _lastTapTime = null; // Reset debouncing state
    super.dispose();
  }
}