import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorDataAnalyzer extends StatefulWidget {
  const SensorDataAnalyzer({super.key});

  @override
  State<SensorDataAnalyzer> createState() => _SensorDataAnalyzerState();
}

class _SensorDataAnalyzerState extends State<SensorDataAnalyzer> {
  List<SensorReading> _sensorReadings = [];
  List<TapEvent> _detectedTaps = [];
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  bool _isRecording = false;
  double _detectionThreshold = 6.0;
  DateTime? _recordingStartTime;

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
      _recordingStartTime = DateTime.now();
    });
    
    // Listen to accelerometer events
    _accelerometerSubscription = userAccelerometerEvents.listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final reading = SensorReading(
        timestamp: DateTime.now(),
        x: event.x,
        y: event.y,
        z: event.z,
        magnitude: magnitude,
      );
      
      _processSensorReading(reading);
    });
  }
  
  void _processSensorReading(SensorReading reading) {
    setState(() {
      _sensorReadings.add(reading);
      
      // Keep only recent readings (last 100)
      if (_sensorReadings.length > 100) {
        _sensorReadings.removeAt(0);
      }
      
      // Check for tap detection
      if (reading.magnitude > _detectionThreshold) {
        // Check if this is a distinct tap
        if (_detectedTaps.isEmpty || 
            DateTime.now().difference(_detectedTaps.last.timestamp).inMilliseconds > 200) {
          
          _detectedTaps.add(TapEvent(
            timestamp: DateTime.now(),
            x: reading.x,
            y: reading.y,
            z: reading.z,
            magnitude: reading.magnitude,
          ));
        }
      }
    });
  }

  void _stopRecording() {
    _isRecording = false;
    _accelerometerSubscription?.cancel();
    setState(() {});
  }

  void _clearData() {
    setState(() {
      _sensorReadings.clear();
      _detectedTaps.clear();
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
            
            // Detected taps visualization
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
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _detectedTaps.length,
                  itemBuilder: (context, index) {
                    final tap = _detectedTaps[index];
                    return Container(
                      margin: const EdgeInsets.all(10),
                      width: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
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