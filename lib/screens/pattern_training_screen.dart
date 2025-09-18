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
  List<SensorReading> _sensorReadings = [];
  List<TapEvent> _detectedTaps = [];
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  bool _isRecording = false;
  String _patternName = '';
  double _detectionThreshold = 6.0;
  DateTime? _recordingStartTime;
  DateTime? _recordingEndTime;
  Timer? _autoStopTimer;
  String _selectedFunction = 'custom';

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
    _startSensorCollection();
    
    // Set auto-stop timer (10 seconds max)
    _autoStopTimer = Timer(const Duration(seconds: 10), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }
  
  void _startSensorCollection() {
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
      
      _processSensorReading(reading);
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
      
      _processSensorReading(reading);
    });
  }
  
  void _processSensorReading(SensorReading reading) {
    setState(() {
      _sensorReadings.add(reading);
      
      // Check for tap detection
      if (reading.magnitude > _detectionThreshold && reading.sensorType == 'Accelerometer') {
        // Check if this is a new tap (not part of previous tap)
        if (_detectedTaps.isEmpty || 
            DateTime.now().difference(_detectedTaps.last.timestamp).inMilliseconds > 200) {
          _detectedTaps.add(TapEvent(
            timestamp: DateTime.now(),
            magnitude: reading.magnitude,
            x: reading.x,
            y: reading.y,
            z: reading.z,
          ));
        }
      }
    });
  }

  void _stopRecording() {
    if (!_isRecording) return;
    
    _autoStopTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    
    setState(() {
      _isRecording = false;
      _recordingEndTime = DateTime.now();
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
      assignedFunction: _selectedFunction,
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
              
              // Function assignment
              const Text(
                'Assign to function:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedFunction,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'audio',
                    child: Text('Audio Recording'),
                  ),
                  DropdownMenuItem(
                    value: 'video',
                    child: Text('Video Recording'),
                  ),
                  DropdownMenuItem(
                    value: 'image',
                    child: Text('Image Capture'),
                  ),
                  DropdownMenuItem(
                    value: 'sos',
                    child: Text('SOS Alert'),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text('Custom (No assigned function)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFunction = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
            
            // Recording controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRecording) ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.2),
                      border: Border.all(color: Colors.red, width: 3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.stop,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      border: Border.all(color: Theme.of(context).primaryColor, width: 3),
                    ),
                    child: Center(
                      child: Icon(
                        _detectedTaps.isEmpty 
                            ? Icons.fiber_manual_record
                            : Icons.replay,
                        color: Theme.of(context).primaryColor,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ],
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
            ],
            
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
                      Text('Recording duration: ${_getRecordingDuration()}'),
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
            ],
            
            // Detailed tap data
            if (_detectedTaps.isNotEmpty) ...[
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
  
  String _getRecordingDuration() {
    if (_recordingStartTime == null) return '0s';
    final endTime = _recordingEndTime ?? DateTime.now();
    final duration = endTime.difference(_recordingStartTime!);
    return '${duration.inSeconds}.${(duration.inMilliseconds % 1000) ~/ 100}s';
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