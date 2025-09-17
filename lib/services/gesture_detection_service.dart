import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pocket_recorder/services/media_capture_service.dart';

class GestureDetectionService {
  static final GestureDetectionService _instance = GestureDetectionService._internal();
  factory GestureDetectionService() => _instance;
  GestureDetectionService._internal();

  // Media capture service
  final MediaCaptureService _mediaService = MediaCaptureService();

  // Streams for accelerometer and gyroscope data
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Gesture detection parameters
  static const double _tapThreshold = 15.0; // Threshold for detecting a tap
  static const int _doubleTapWindow = 500; // Time window for double tap in milliseconds
  static const int _tripleTapWindow = 1000; // Time window for triple tap in milliseconds

  // Variables for gesture detection
  DateTime? _lastTapTime;
  int _tapCount = 0;
  final List<double> _accelerationBuffer = [];
  final int _bufferSize = 10;

  // Callbacks for different gestures
  Function()? onDoubleTap;
  Function()? onTripleTap;
  Function()? onLongSlap;

  // Start listening to sensor events
  void startListening() {
    _accelerometerSubscription = SensorsPlatform.instance.userAccelerometerEvents.listen(_onAccelerometerEvent);
    _gyroscopeSubscription = SensorsPlatform.instance.gyroscopeEvents.listen(_onGyroscopeEvent);
  }

  // Stop listening to sensor events
  void stopListening() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
  }

  // Process accelerometer events
  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    // Calculate the magnitude of the acceleration vector
    double magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z
    );

    // Add to buffer
    _accelerationBuffer.add(magnitude);
    if (_accelerationBuffer.length > _bufferSize) {
      _accelerationBuffer.removeAt(0);
    }

    // Check for tap gesture
    if (magnitude > _tapThreshold) {
      _processTapEvent();
    }
  }

  // Process gyroscope events (for future use)
  void _onGyroscopeEvent(GyroscopeEvent event) {
    // We can use this for more complex gesture recognition in the future
  }

  // Process tap events
  void _processTapEvent() {
    DateTime now = DateTime.now();
    
    if (_lastTapTime == null) {
      // First tap
      _lastTapTime = now;
      _tapCount = 1;
    } else {
      // Check if this tap is within the double tap window
      int timeDiff = now.difference(_lastTapTime!).inMilliseconds;
      
      if (timeDiff <= _doubleTapWindow) {
        _tapCount++;
        
        // Check for double tap
        if (_tapCount == 2) {
          _handleDoubleTap();
          _resetTapDetection();
        }
        // Check for triple tap
        else if (_tapCount == 3) {
          _handleTripleTap();
          _resetTapDetection();
        }
      } else if (timeDiff <= _tripleTapWindow && _tapCount == 2) {
        // This is the third tap within the extended window
        _tapCount++;
        _handleTripleTap();
        _resetTapDetection();
      } else {
        // Reset for a new sequence
        _lastTapTime = now;
        _tapCount = 1;
      }
    }
  }

  // Handle double tap gesture
  void _handleDoubleTap() {
    // Capture photo by default
    _mediaService.capturePhoto();
    
    // Call custom callback if set
    onDoubleTap?.call();
  }

  // Handle triple tap gesture
  void _handleTripleTap() {
    // Start video recording by default
    _mediaService.startVideoRecording();
    
    // Call custom callback if set
    onTripleTap?.call();
  }

  // Handle long slap gesture
  void _handleLongSlap() {
    // Start audio recording by default
    _mediaService.startAudioRecording();
    
    // Call custom callback if set
    onLongSlap?.call();
  }

  // Reset tap detection variables
  void _resetTapDetection() {
    _lastTapTime = null;
    _tapCount = 0;
  }

  // Dispose of the service
  void dispose() {
    stopListening();
    _mediaService.dispose();
  }
}