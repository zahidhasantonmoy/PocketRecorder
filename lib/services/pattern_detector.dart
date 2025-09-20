import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';

class PatternDetector {
  static const double _threshold = 1.2; // Lowered acceleration threshold for better tap detection
  static const int _maxTimeBetweenTaps = 1000; // Increased max time between taps in milliseconds
  static const int _patternTimeout = 3000; // Extended time to wait for pattern completion
  static const int _debounceTime = 200; // Time to ignore subsequent taps (debouncing)
  static const int _proximityGracePeriod = 500; // Time to allow taps after proximity returns to far

  final Function(int) onPatternDetected;
  final VoidCallback onPatternTimeout;
  
  late StreamSubscription<UserAccelerometerEvent> _accelerometerSubscription;
  List<DateTime> _tapTimestamps = [];
  Timer? _patternTimer;
  DateTime? _lastTapTime; // For debouncing
  bool _isNearProximity = false; // Track proximity sensor state
  DateTime? _proximityLastNear; // Track when proximity was last in near state

  PatternDetector({
    required this.onPatternDetected,
    required this.onPatternTimeout,
  }) {
    _startListening();
    _startProximityListening();
  }

  void _startListening() {
    _accelerometerSubscription = userAccelerometerEvents.listen((event) {
      // Calculate magnitude of acceleration
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Apply a smoothing filter to reduce noise
      if (_isSignificantTap(magnitude)) {
        _onTapDetected();
      }
    });
  }
  
  void _startProximityListening() {
    // Note: This would require integrating the proximity sensor package
    // For now, we'll simulate this or it would be set externally
    // In a complete implementation, you would listen to proximity events here
  }
  
  // Method to update proximity state (to be called from outside)
  void updateProximityState(bool isNear) {
    _isNearProximity = isNear;
    if (isNear) {
      _proximityLastNear = DateTime.now();
    }
  }
  
  // Check if we're in a valid state to detect taps (near proximity or within grace period)
  bool _isInValidDetectionState() {
    // If we're currently in near proximity, we can detect taps
    if (_isNearProximity) {
      return true;
    }
    
    // If we're not in near proximity, check if we're within the grace period
    if (_proximityLastNear != null) {
      final timeSinceNear = DateTime.now().difference(_proximityLastNear!).inMilliseconds;
      return timeSinceNear <= _proximityGracePeriod;
    }
    
    // Otherwise, we're not in a valid state for tap detection
    return false;
  }
  
  // Smoothing filter to reduce noise and detect transient tap events
  double _prevMagnitude = 0.0;
  double _prevDelta = 0.0;
  bool _isSignificantTap(double magnitude) {
    // First check if we're in a valid detection state
    if (!_isInValidDetectionState()) {
      return false;
    }
    
    // Apply exponential moving average filter
    final filteredMagnitude = 0.7 * magnitude + 0.3 * _prevMagnitude;
    _prevMagnitude = filteredMagnitude;
    
    // Check if the change is significant enough to be a tap
    final delta = (filteredMagnitude - 9.81).abs(); // Subtract gravity
    
    // Apply high-pass filtering to focus on transient events
    final deltaChange = delta - _prevDelta;
    _prevDelta = delta;
    
    // Check if we have a sharp transient (tap signature)
    final isTransient = deltaChange > 0.5 && delta > _threshold;
    
    return isTransient;
  }

  void _onTapDetected() {
    final now = DateTime.now();
    
    // Implement debouncing - ignore taps that are too close together
    if (_lastTapTime != null) {
      final timeSinceLastTap = now.difference(_lastTapTime!).inMilliseconds;
      if (timeSinceLastTap < _debounceTime) {
        return; // Ignore this tap, it's too soon after the last one
      }
    }
    
    // Update last tap time
    _lastTapTime = now;
    
    // Cancel any existing pattern timer
    _patternTimer?.cancel();
    
    // Add the tap timestamp
    _tapTimestamps.add(now);
    
    // Remove taps that are too old
    _tapTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp).inMilliseconds > _patternTimeout
    );
    
    // Check if we have a valid pattern based on tap count
    if (_tapTimestamps.length >= 1) { // Allow single tap patterns
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
          _lastTapTime = null; // Reset debouncing
        });
      }
    }
  }

  void stopListening() {
    _accelerometerSubscription.cancel();
    _patternTimer?.cancel();
    _lastTapTime = null; // Reset debouncing state
    _isNearProximity = false; // Reset proximity state
    _proximityLastNear = null; // Reset proximity timing
  }
  
  // Method to check if a pattern matches with ~60% tolerance
  bool isPatternMatch(List<int> detectedPattern, List<int> targetPattern, double tolerance) {
    if (detectedPattern.length != targetPattern.length) return false;
    
    int matchCount = 0;
    int totalCount = detectedPattern.length;
    
    // Compare elements with tolerance
    for (int i = 0; i < detectedPattern.length; i++) {
      if (detectedPattern[i] == targetPattern[i]) {
        matchCount++;
      }
    }
    
    double matchPercentage = matchCount / totalCount;
    return matchPercentage >= tolerance;
  }
  
  // Use Dart's built-in math functions for better precision
  double sqrt(double value) {
    return value <= 0 ? 0 : math.sqrt(value);
  }
}