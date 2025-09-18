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
  List<SensorReading> _accelerometerReadings = [];
  List<SensorReading> _gyroscopeReadings = [];
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  bool _isListening = false;
  int _maxRecords = 50;
  double _tapThreshold = 15.0;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  void _startListening() {
    if (_isListening) return;
    
    _isListening = true;
    
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
      
      setState(() {
        _accelerometerReadings.insert(0, reading);
        if (_accelerometerReadings.length > _maxRecords) {
          _accelerometerReadings.removeLast();
        }
      });
    });
    
    // Listen to gyroscope events
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final reading = SensorReading(
        timestamp: DateTime.now(),
        x: event.x,
        y: event.y,
        z: event.z,
        magnitude: magnitude,
      );
      
      setState(() {
        _gyroscopeReadings.insert(0, reading);
        if (_gyroscopeReadings.length > _maxRecords) {
          _gyroscopeReadings.removeLast();
        }
      });
    });
  }

  void _stopListening() {
    _isListening = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
  }

  void _clearReadings() {
    setState(() {
      _accelerometerReadings.clear();
      _gyroscopeReadings.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Data Analyzer'),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.pause : Icons.play_arrow),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Threshold selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detection Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Tap Threshold:'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Slider(
                            value: _tapThreshold,
                            min: 5.0,
                            max: 50.0,
                            divisions: 45,
                            label: _tapThreshold.round().toString(),
                            onChanged: (value) {
                              setState(() {
                                _tapThreshold = value;
                              });
                            },
                          ),
                        ),
                        Text('${_tapThreshold.round()}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Current readings: ${_accelerometerReadings.length} accelerometer, ${_gyroscopeReadings.length} gyroscope',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Detected taps indicator
            Card(
              color: Colors.deepPurple.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Taps',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTapIndicators(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tabs for accelerometer and gyroscope data
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Accelerometer'),
                        Tab(text: 'Gyroscope'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _AccelerometerTab(
                            readings: _accelerometerReadings,
                            threshold: _tapThreshold,
                          ),
                          _GyroscopeTab(
                            readings: _gyroscopeReadings,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _clearReadings,
                  child: const Text('Clear Data'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save data to file or share
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
  
  Widget _buildTapIndicators() {
    // Count readings above threshold
    int tapCount = _accelerometerReadings
        .where((reading) => reading.magnitude > _tapThreshold)
        .length;
    
    // Get highest magnitude reading
    double maxMagnitude = 0.0;
    if (_accelerometerReadings.isNotEmpty) {
      maxMagnitude = _accelerometerReadings
          .map((r) => r.magnitude)
          .reduce((a, b) => a > b ? a : b);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Readings above threshold: $tapCount'),
        Text('Highest magnitude detected: ${maxMagnitude.toStringAsFixed(2)}'),
        const SizedBox(height: 10),
        if (tapCount > 0)
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: (tapCount / _maxRecords * 100).clamp(0, 100),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
      ],
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

class _AccelerometerTab extends StatelessWidget {
  final List<SensorReading> readings;
  final double threshold;

  const _AccelerometerTab({
    required this.readings,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text('No accelerometer data yet. Tap the back of your phone to generate readings.'),
      );
    }

    return ListView.builder(
      itemCount: readings.length,
      itemBuilder: (context, index) {
        final reading = readings[index];
        final isAboveThreshold = reading.magnitude > threshold;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isAboveThreshold ? Colors.red.withOpacity(0.2) : null,
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
                    if (isAboveThreshold)
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
                        color: isAboveThreshold ? Colors.red : null,
                      ),
                    ),
                    if (isAboveThreshold) ...[
                      const SizedBox(width: 10),
                      const Text('(TAP DETECTED)', style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
                // Progress bar showing magnitude relative to threshold
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: (reading.magnitude / 50.0).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAboveThreshold ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GyroscopeTab extends StatelessWidget {
  final List<SensorReading> readings;

  const _GyroscopeTab({required this.readings});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text('No gyroscope data yet. Rotate your phone to generate readings.'),
      );
    }

    return ListView.builder(
      itemCount: readings.length,
      itemBuilder: (context, index) {
        final reading = readings[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reading.timestamp.hour}:${reading.timestamp.minute}:${reading.timestamp.second}.${reading.timestamp.millisecond}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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