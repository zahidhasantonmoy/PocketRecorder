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
  List<SensorReading> _allReadings = []; // Store all readings
  List<SensorReading> _topReadings = []; // Top 50 readings
  List<SensorReading> _currentReadings = []; // Last 50 readings for display
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  bool _isListening = false;
  int _maxStoredReadings = 1000; // Store up to 1000 readings in memory
  int _displayReadings = 50; // Display top 50
  double _tapThreshold = 15.0;
  double _highestMagnitude = 0.0;

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
        sensorType: 'Accelerometer',
      );
      
      _addReading(reading);
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
        sensorType: 'Gyroscope',
      );
      
      _addReading(reading);
    });
  }
  
  void _addReading(SensorReading reading) {
    setState(() {
      // Add to all readings
      _allReadings.add(reading);
      
      // Update highest magnitude
      if (reading.magnitude > _highestMagnitude) {
        _highestMagnitude = reading.magnitude;
      }
      
      // Keep only the latest readings within our storage limit
      if (_allReadings.length > _maxStoredReadings) {
        _allReadings.removeAt(0);
      }
      
      // Update current readings for display (last 50)
      _currentReadings.insert(0, reading);
      if (_currentReadings.length > _displayReadings) {
        _currentReadings.removeLast();
      }
      
      // Update top readings
      _updateTopReadings();
    });
  }
  
  void _updateTopReadings() {
    // Sort all readings by magnitude (descending) and take top 50
    final sortedReadings = List<SensorReading>.from(_allReadings)
      ..sort((a, b) => b.magnitude.compareTo(a.magnitude));
    
    _topReadings = sortedReadings.take(_displayReadings).toList();
  }

  void _stopListening() {
    _isListening = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
  }

  void _clearReadings() {
    setState(() {
      _allReadings.clear();
      _topReadings.clear();
      _currentReadings.clear();
      _highestMagnitude = 0.0;
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
            // Statistics panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Total readings: ${_allReadings.length}'),
                    Text('Highest magnitude: ${_highestMagnitude.toStringAsFixed(2)}'),
                    Text('Current threshold: ${_tapThreshold.toStringAsFixed(2)}'),
                    Text('Readings above threshold: ${_allReadings.where((r) => r.magnitude > _tapThreshold).length}'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Tap Threshold:'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Slider(
                            value: _tapThreshold,
                            min: 1.0,
                            max: 50.0,
                            divisions: 49,
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
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tabs for different views
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Top 50 Readings'),
                        Tab(text: 'Recent Readings'),
                        Tab(text: 'All Readings'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _TopReadingsTab(
                            readings: _topReadings,
                            threshold: _tapThreshold,
                          ),
                          _CurrentReadingsTab(
                            readings: _currentReadings,
                            threshold: _tapThreshold,
                          ),
                          _AllReadingsTab(
                            readings: _allReadings,
                            threshold: _tapThreshold,
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
                  onPressed: _exportData,
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