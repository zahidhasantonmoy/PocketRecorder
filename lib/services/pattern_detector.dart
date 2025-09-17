import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';

class PatternDetector {
  static const double _threshold = 15.0; // Acceleration threshold for tap detection
  static const int _maxTimeBetweenTaps = 500; // Max time between taps in milliseconds
  static const int _patternTimeout = 2000; // Time to wait for pattern completion

  final Function(int) onPatternDetected;
  final Function onPatternTimeout;
  
  late StreamSubscription<UserAccelerometerEvent> _accelerometerSubscription;
  List<DateTime> _tapTimestamps = [];
  Timer? _patternTimer;

  PatternDetector({
    required this.onPatternDetected,
    required this.onPatternTimeout,
  }) {
    _startListening();
  }

  void _startListening() {
    _accelerometerSubscription = userAccelerometerEvents.listen((event) {
      // Check if the acceleration exceeds the threshold
      final magnitude = event.x * event.x + event.y * event.y + event.z * event.z;
      if (magnitude > _threshold * _threshold) {
        _onTapDetected();
      }
    });
  }

  void _onTapDetected() {
    final now = DateTime.now();
    
    // Cancel any existing pattern timer
    _patternTimer?.cancel();
    
    // Add the tap timestamp
    _tapTimestamps.add(now);
    
    // Remove taps that are too old
    _tapTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp).inMilliseconds > _patternTimeout
    );
    
    // Check if we have a valid pattern based on tap count
    if (_tapTimestamps.length >= 2) {
      // Check time gaps between consecutive taps
      bool isValidPattern = true;
      for (int i = 1; i < _tapTimestamps.length; i++) {
        final gap = _tapTimestamps[i].difference(_tapTimestamps[i-1]).inMilliseconds;
        if (gap > _maxTimeBetweenTaps) {
          isValidPattern = false;
          break;
        }
      }
      
      // If we have a valid pattern, notify
      if (isValidPattern) {
        // Start a timer to wait for more taps or finalize the pattern
        _patternTimer = Timer(Duration(milliseconds: _patternTimeout), () {
          // Pattern is complete, notify with tap count
          onPatternDetected(_tapTimestamps.length);
          _tapTimestamps.clear();
        });
      }
    }
  }

  void stopListening() {
    _accelerometerSubscription.cancel();
    _patternTimer?.cancel();
  }
  
  // Method to check if a pattern matches with ~60% tolerance
  bool isPatternMatch(List<int> detectedPattern, List<int> targetPattern, double tolerance) {
    if (detectedPattern.length != targetPattern.length) return false;
    
    int matchCount = 0;
    for (int i = 0; i < detectedPattern.length; i++) {
      if (detectedPattern[i] == targetPattern[i]) {
        matchCount++;
      }
    }
    
    double matchPercentage = matchCount / detectedPattern.length;
    return matchPercentage >= tolerance;
  }
}