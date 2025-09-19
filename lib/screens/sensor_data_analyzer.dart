import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:flutter/services.dart';

class SensorDataAnalyzer extends StatefulWidget {
  const SensorDataAnalyzer({super.key});

  @override
  State<SensorDataAnalyzer> createState() => _SensorDataAnalyzerState();
}

class _SensorDataAnalyzerState extends State<SensorDataAnalyzer> {
  List<SensorReading> _sensorReadings = [];
  List<TapEvent> _detectedTaps = [];
  List<ProximityReading> _proximityReadings = [];
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<int>? _proximitySubscription;
  bool _isRecording = false;
  bool _isProximitySupported = false;
  double _detectionThreshold = 4.0; // Lowered threshold for better sensitivity
  DateTime? _recordingStartTime;
  Timer? _samplingTimer;
  UserAccelerometerEvent? _latestEvent;
  double _baselineMagnitude = 1.0; // Baseline for normalization
  int _sampleCount = 0;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _stopRecording();
    super.dispose();
  }

  void _startRecording() {
    if (_isRecording) return;
    
    setState(() {
      _isRecording = true;
      _sensorReadings.clear();
      _detectedTaps.clear();
      _proximityReadings.clear();
      _recordingStartTime = DateTime.now();
    });
    
    // Sample accelerometer at 2Hz (every 500ms) instead of as fast as possible
    _samplingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_latestEvent != null) {
        final event = _latestEvent!;
        final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        final reading = SensorReading(
          timestamp: DateTime.now(),
          x: event.x,
          y: event.y,
          z: event.z,
          magnitude: magnitude,
        );
        
        _processSensorReading(reading);
        _latestEvent = null; // Reset after processing
      }
    });
    
    // Listen to accelerometer events but just store the latest one
    _accelerometerSubscription = userAccelerometerEvents.listen((event) {
      _latestEvent = event; // Just store the latest event for sampling
    });
    
    // Listen to proximity events
    try {
      _proximitySubscription = ProximitySensor.events.listen((event) {
        final reading = ProximityReading(
          timestamp: DateTime.now(),
          distance: event > 0 ? 0.0 : 5.0, // When proximity is detected, distance is 0cm, otherwise 5cm
          isNear: event > 0, // In the proximity_sensor package, > 0 means near
        );
        
        setState(() {
          _proximityReadings.add(reading);
          // Keep only recent readings (last 50)
          if (_proximityReadings.length > 50) {
            _proximityReadings.removeAt(0);
          }
        });
      });
      setState(() {
        _isProximitySupported = true;
      });
    } catch (e) {
      // Proximity sensor not supported
      setState(() {
        _isProximitySupported = false;
      });
      print('Proximity sensor not supported: $e');
    }
  }
  
  void _processSensorReading(SensorReading reading) {
    setState(() {
      _sensorReadings.add(reading);
      
      // Keep only recent readings (last 100)
      if (_sensorReadings.length > 100) {
        _sensorReadings.removeAt(0);
      }
      
      // Update baseline magnitude calculation with a moving average
      _sampleCount++;
      if (_sampleCount <= 10) {
        // For the first 10 samples, calculate average to establish baseline
        _baselineMagnitude = ((_baselineMagnitude * (_sampleCount - 1)) + reading.magnitude) / _sampleCount;
      } else {
        // After 10 samples, use a weighted moving average to adjust baseline
        _baselineMagnitude = (_baselineMagnitude * 0.95) + (reading.magnitude * 0.05);
      }
      
      // Use adaptive threshold based on baseline
      final adaptiveThreshold = _baselineMagnitude * 2.5; // 2.5x the baseline as threshold
      
      // Improved tap detection algorithm
      if (reading.magnitude > adaptiveThreshold && reading.magnitude > _detectionThreshold) {
        // Check if this is a distinct tap
        bool isDistinctTap = true;
        if (_detectedTaps.isNotEmpty) {
          final lastTap = _detectedTaps.last;
          final timeDiff = DateTime.now().difference(lastTap.timestamp).inMilliseconds;
          
          // Prevent duplicate detections of the same tap (minimum 50ms between taps)
          if (timeDiff <= 50) {
            isDistinctTap = false;
          }
        }
        
        if (isDistinctTap) {
          _detectedTaps.add(TapEvent(
            timestamp: DateTime.now(),
            x: reading.x,
            y: reading.y,
            z: reading.z,
            magnitude: reading.magnitude,
          ));
          
          // Limit detected taps to last 20 to prevent memory issues
          if (_detectedTaps.length > 20) {
            _detectedTaps.removeAt(0);
          }
        }
      }
    });
  }

  void _stopRecording() {
    _isRecording = false;
    _accelerometerSubscription?.cancel();
    _proximitySubscription?.cancel();
    _samplingTimer?.cancel();
    setState(() {});
  }

  void _clearData() {
    setState(() {
      _sensorReadings.clear();
      _detectedTaps.clear();
      _proximityReadings.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Data Analyzer'),
        actions: [
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recording Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Status:'),
                        const SizedBox(width: 10),
                        Text(
                          _isRecording ? 'Recording...' : 'Stopped',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isRecording ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Threshold:'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Slider(
                            value: _detectionThreshold,
                            min: 1.0,
                            max: 20.0,
                            divisions: 19,
                            label: _detectionThreshold.round().toString(),
                            onChanged: (value) {
                              setState(() {
                                _detectionThreshold = value;
                              });
                            },
                          ),
                        ),
                        Text('${_detectionThreshold.round()}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Readings: ${_sensorReadings.length}, Taps: ${_detectedTaps.length}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Detected taps list
            if (_detectedTaps.isNotEmpty) ...[
              const Text(
                'Detected Taps',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  itemCount: _detectedTaps.length,
                  itemBuilder: (context, index) {
                    final tap = _detectedTaps[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: Colors.deepPurple.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tap #${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                Text(
                                  '${tap.timestamp.hour}:${tap.timestamp.minute}:${tap.timestamp.second}.${tap.timestamp.millisecond}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'X: '),
                                  TextSpan(
                                    text: '${tap.x.toStringAsFixed(2)}  ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(text: 'Y: '),
                                  TextSpan(
                                    text: '${tap.y.toStringAsFixed(2)}  ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(text: 'Z: '),
                                  TextSpan(
                                    text: '${tap.z.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Text('Magnitude: '),
                                Text(
                                  tap.magnitude.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Proximity sensor data
            if (_isProximitySupported && _proximityReadings.isNotEmpty) ...[
              const Text(
                'Proximity Sensor Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _proximityReadings.length,
                  itemBuilder: (context, index) {
                    final reading = _proximityReadings[index];
                    return Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: reading.isNear ? Colors.deepPurple : Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${reading.distance.toStringAsFixed(1)}cm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reading.isNear ? 'NEAR' : 'FAR',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Sensor data list
            const Text(
              'Sensor Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _sensorReadings.length,
                itemBuilder: (context, index) {
                  final reading = _sensorReadings[index];
                  final isTap = _detectedTaps.any((tap) => 
                      tap.timestamp.difference(reading.timestamp).inMilliseconds.abs() < 100);
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isTap ? Colors.red.withOpacity(0.2) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${reading.timestamp.hour}:${reading.timestamp.minute}:${reading.timestamp.second}.${reading.timestamp.millisecond}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (isTap)
                                const Icon(
                                  Icons.touch_app,
                                  color: Colors.red,
                                  size: 16,
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'X: '),
                                TextSpan(
                                  text: '${reading.x.toStringAsFixed(2)}  ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: 'Y: '),
                                TextSpan(
                                  text: '${reading.y.toStringAsFixed(2)}  ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: 'Z: '),
                                TextSpan(
                                  text: '${reading.z.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Text('Magnitude: '),
                              Text(
                                reading.magnitude.toStringAsFixed(2),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isTap ? Colors.red : null,
                                ),
                              ),
                              if (isTap) ...[
                                const SizedBox(width: 10),
                                const Text('(TAP)', style: TextStyle(color: Colors.red)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _clearData,
                  child: const Text('Clear Data'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Export data functionality
                    _exportData();
                  },
                  child: const Text('Export Data'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Copy data to clipboard
                    _copyDataToClipboard();
                  },
                  child: const Text('Copy Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _exportData() {
    // In a real app, you would export the data to a file or share it
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data exported successfully!'),
      ),
    );
  }
  
  void _copyDataToClipboard() {
    // Format sensor data as text
    final buffer = StringBuffer();
    buffer.writeln('PocketRecorder Sensor Data Export');
    buffer.writeln('Exported on: ${DateTime.now()}');
    buffer.writeln('');
    buffer.writeln('Accelerometer Data:');
    buffer.writeln('Timestamp,X,Y,Z,Magnitude');
    
    for (final reading in _sensorReadings) {
      buffer.writeln('${reading.timestamp},${reading.x.toStringAsFixed(4)},${reading.y.toStringAsFixed(4)},${reading.z.toStringAsFixed(4)},${reading.magnitude.toStringAsFixed(4)}');
    }
    
    if (_isProximitySupported && _proximityReadings.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Proximity Sensor Data:');
      buffer.writeln('Timestamp,Distance (cm),Status');
      
      for (final reading in _proximityReadings) {
        buffer.writeln('${reading.timestamp},${reading.distance.toStringAsFixed(2)},${reading.isNear ? "NEAR" : "FAR"}');
      }
    }
    
    if (_detectedTaps.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Detected Taps:');
      buffer.writeln('Timestamp,X,Y,Z,Magnitude');
      
      for (final tap in _detectedTaps) {
        buffer.writeln('${tap.timestamp},${tap.x.toStringAsFixed(4)},${tap.y.toStringAsFixed(4)},${tap.z.toStringAsFixed(4)},${tap.magnitude.toStringAsFixed(4)}');
      }
    }
    
    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data copied to clipboard!'),
      ),
    );
  }
}

class SensorReading {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double magnitude;

  SensorReading({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
  });
}

class TapEvent {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double magnitude;

  TapEvent({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
  });
}

class ProximityReading {
  final DateTime timestamp;
  final double distance; // in cm
  final bool isNear;

  ProximityReading({
    required this.timestamp,
    required this.distance,
    required this.isNear,
  });
}