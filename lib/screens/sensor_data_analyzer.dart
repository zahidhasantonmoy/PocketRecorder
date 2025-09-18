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
  bool _isRecording = false;
  double _tapThreshold = 6.0;
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
      _accelerometerReadings.clear();
      _gyroscopeReadings.clear();
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
      
      setState(() {
        _accelerometerReadings.add(reading);
        // Keep only the last 100 readings
        if (_accelerometerReadings.length > 100) {
          _accelerometerReadings.removeAt(0);
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
        _gyroscopeReadings.add(reading);
        // Keep only the last 100 readings
        if (_gyroscopeReadings.length > 100) {
          _gyroscopeReadings.removeAt(0);
        }
      });
    });
  }

  void _stopRecording() {
    _isRecording = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    setState(() {});
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
            icon: Icon(_isRecording ? Icons.pause : Icons.play_arrow),
            onPressed: _isRecording ? _stopRecording : _startRecording,
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
                            min: 1.0,
                            max: 20.0,
                            divisions: 19,
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
                      'Readings: ${_accelerometerReadings.length} accelerometer, ${_gyroscopeReadings.length} gyroscope',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    if (_recordingStartTime != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Recording time: ${DateTime.now().difference(_recordingStartTime!).inSeconds}s',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: (tapCount / 50 * 100).clamp(0, 100),
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
        child: Text('No accelerometer data yet. Tap on the back of your phone to generate readings.'),
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
                const SizedBox(height: 5),
                // Progress bar showing magnitude relative to max threshold
                LinearProgressIndicator(
                  value: (reading.magnitude / 20.0).clamp(0.0, 1.0),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Progress bar showing magnitude relative to max
                LinearProgressIndicator(
                  value: (reading.magnitude / 10.0).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
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

class _TopReadingsTab extends StatelessWidget {
  final List<SensorReading> readings;
  final double threshold;

  const _TopReadingsTab({
    required this.readings,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text('No readings yet. Move or tap your phone to generate data.'),
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
                      '#${index + 1} - ${reading.sensorType}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${reading.timestamp.hour}:${reading.timestamp.minute}:${reading.timestamp.second}',
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
                      const Text('(ABOVE THRESHOLD)', style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
                // Progress bar showing magnitude relative to max
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

class _CurrentReadingsTab extends StatelessWidget {
  final List<SensorReading> readings;
  final double threshold;

  const _CurrentReadingsTab({
    required this.readings,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text('No recent readings yet. Move or tap your phone to generate data.'),
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
                      '${reading.sensorType}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${reading.timestamp.hour}:${reading.timestamp.minute}:${reading.timestamp.second}.${reading.timestamp.millisecond.toString().substring(0, 2)}',
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
                      const Text('(ABOVE THRESHOLD)', style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
                // Progress bar showing magnitude relative to max
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

class _AllReadingsTab extends StatelessWidget {
  final List<SensorReading> readings;
  final double threshold;

  const _AllReadingsTab({
    required this.readings,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text('No readings yet. Move or tap your phone to generate data.'),
      );
    }

    // Show last 100 readings
    final displayReadings = readings.length > 100 ? readings.sublist(readings.length - 100) : readings;

    return ListView.builder(
      itemCount: displayReadings.length,
      itemBuilder: (context, index) {
        final reading = displayReadings[index];
        final isAboveThreshold = reading.magnitude > threshold;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${reading.timestamp.hour}:${reading.timestamp.minute}:${reading.timestamp.second}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  '${reading.sensorType.substring(0, 1)}: ',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  reading.magnitude.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isAboveThreshold ? Colors.red : null,
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

class SensorReading {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double magnitude;
  final String sensorType;

  SensorReading({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.sensorType,
  });
}