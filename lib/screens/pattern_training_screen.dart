import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/pattern_storage_service.dart';
import '../models/pattern_signature.dart';

class PatternTrainingScreen extends StatefulWidget {
  const PatternTrainingScreen({super.key});

  @override
  State<PatternTrainingScreen> createState() => _PatternTrainingScreenState();
}

class _PatternTrainingScreenState extends State<PatternTrainingScreen> {
  List<_SensorReading> _sensorReadings = [];
  List<_TapEvent> _detectedTaps = [];
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  bool _isRecording = false;
  String _patternName = '';
  double _detectionThreshold = 6.0;
  DateTime? _recordingStartTime;

  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _stopRecording();
    _nameController.dispose();
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
    
    // Start collecting sensor data
    _accelerometerSubscription = userAccelerometerEvents.listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final reading = _SensorReading(
        timestamp: DateTime.now(),
        x: event.x,
        y: event.y,
        z: event.z,
        magnitude: magnitude,
      );
      
      setState(() {
        _sensorReadings.add(reading);
        
        // Check for tap detection
        if (magnitude > _detectionThreshold) {
          // Check if this is a new tap (not part of previous tap)
          if (_detectedTaps.isEmpty || 
              DateTime.now().difference(_detectedTaps.last.timestamp).inMilliseconds > 200) {
            _detectedTaps.add(_TapEvent(
              timestamp: DateTime.now(),
              magnitude: magnitude,
              x: event.x,
              y: event.y,
              z: event.z,
            ));
          }
        }
      });
    });
  }

  void _stopRecording() {
    if (!_isRecording) return;
    
    _accelerometerSubscription?.cancel();
    
    setState(() {
      _isRecording = false;
    });
  }

  void _clearData() {
    setState(() {
      _sensorReadings.clear();
      _detectedTaps.clear();
      _patternName = '';
      _nameController.clear();
    });
  }

  Future<void> _savePattern() async {
    if (_detectedTaps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No taps detected. Try again with stronger taps.')),
      );
      return;
    }
    
    if (_patternName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your pattern')),
      );
      return;
    }
    
    // Create pattern signature
    final timestamps = _detectedTaps.map((tap) => tap.timestamp.millisecondsSinceEpoch.toDouble()).toList();
    
    final pattern = PatternSignature(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _patternName,
      timestamps: timestamps,
      createdAt: DateTime.now(),
      assignedFunction: 'custom',
    );
    
    // Save to storage
    await PatternStorageService().savePattern(pattern);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pattern saved successfully!')),
      );
      
      // Clear for next recording
      _clearData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Training'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pattern name input
            if (!_isRecording && _detectedTaps.isEmpty) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pattern Name',
                  hintText: 'e.g., Emergency Tap, Quick Record, etc.',
                ),
                onChanged: (value) {
                  setState(() {
                    _patternName = value;
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
            
            // Recording indicator
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  border: Border.all(
                    color: _isRecording ? Colors.red : Colors.grey,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    size: 50,
                    color: _isRecording ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Status text
            Text(
              _isRecording 
                  ? 'Recording... Perform your tap pattern now' 
                  : _detectedTaps.isEmpty 
                      ? 'Ready to record your pattern' 
                      : 'Pattern recorded. Review below.',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 10),
            
            // Recording time
            if (_isRecording && _recordingStartTime != null) ...[
              Text(
                'Recording time: ${DateTime.now().difference(_recordingStartTime!).inSeconds}s',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
            ],
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRecording) ...[
                  ElevatedButton(
                    onPressed: _stopRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Stop Recording'),
                  ),
                ] else ...[
                  if (_detectedTaps.isEmpty) ...[
                    ElevatedButton(
                      onPressed: _startRecording,
                      child: const Text('Start Recording'),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _startRecording,
                      child: const Text('Record Again'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _savePattern,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Pattern'),
                    ),
                  ],
                ],
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _clearData,
                  child: const Text('Clear'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Statistics
            if (_sensorReadings.isNotEmpty) ...[
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
                      Text('Total readings: ${_sensorReadings.length}'),
                      Text('Detected taps: ${_detectedTaps.length}'),
                      Text('Highest magnitude: ${_getHighestMagnitude().toStringAsFixed(2)}'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Detection Threshold:'),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
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
                height: 100,
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
              
              // Detailed tap data
              const Text(
                'Tap Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _detectedTaps.length,
                  itemBuilder: (context, index) {
                    final tap = _detectedTaps[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
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
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${tap.timestamp.hour}:${tap.timestamp.minute}:${tap.timestamp.second}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
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
                            if (index > 0) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Text('Time since last tap: '),
                                  Text(
                                    '${tap.timestamp.difference(_detectedTaps[index - 1].timestamp).inMilliseconds}ms',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  double _getHighestMagnitude() {
    if (_sensorReadings.isEmpty) return 0.0;
    return _sensorReadings
        .map((r) => r.magnitude)
        .reduce((a, b) => a > b ? a : b);
  }
}

class _SensorReading {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double magnitude;

  _SensorReading({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
  });
}

class _TapEvent {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double magnitude;

  _TapEvent({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
  });
}