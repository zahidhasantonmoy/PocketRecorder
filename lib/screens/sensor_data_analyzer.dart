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
  List<SensorDataPoint> _accelerometerReadings = [];
  List<SensorDataPoint> _gyroscopeReadings = [];
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
      final reading = SensorDataPoint(
        timestamp: DateTime.now(),
        x: event.x,
        y: event.y,
        z: event.z,
        magnitude: magnitude,
        sensorType: 'Accelerometer',
      );
      
      setState(() {
        _accelerometerReadings.add(reading);
        // Keep only recent data (last 100 readings)
        _maintainDataWindowSize();
        
        // Detect taps
        _detectTaps();
      });
    });
    
    // Listen to gyroscope events
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final reading = SensorDataPoint(
        timestamp: DateTime.now(),
        x: event.x,
        y: event.y,
        z: event.z,
        magnitude: magnitude,
        sensorType: 'Gyroscope',
      );
      
      setState(() {
        _gyroscopeReadings.add(reading);
        // Keep only recent data
        _maintainDataWindowSize();
      });
    });
  }
  
  void _maintainDataWindowSize() {
    final cutoffTime = DateTime.now().subtract(Duration(seconds: 10));
    
    _accelerometerReadings.removeWhere((point) => point.timestamp.isBefore(cutoffTime));
    _gyroscopeReadings.removeWhere((point) => point.timestamp.isBefore(cutoffTime));
  }
  
  void _detectTaps() {
    if (_accelerometerReadings.length < 3) return;
    
    // Look for peaks in the recent data
    final recentData = _accelerometerReadings.length > 10 
        ? _accelerometerReadings.sublist(_accelerometerReadings.length - 10)
        : _accelerometerReadings;
    
    // Simple peak detection
    for (int i = 1; i < recentData.length - 1; i++) {
      final current = recentData[i];
      final prev = recentData[i - 1];
      final next = recentData[i + 1];
      
      // Check if this is a peak
      if (current.magnitude > _tapThreshold && 
          current.magnitude > prev.magnitude && 
          current.magnitude > next.magnitude) {
        
        // Check if this is a new tap (not part of previous tap)
        if (_detectedTaps.isEmpty || 
            current.timestamp.difference(_detectedTaps.last.timestamp).inMilliseconds > 200) {
          
          // Analyze the tap characteristics
          final tapAnalysis = _analyzeTapCharacteristics(current, i, recentData);
          
          setState(() {
            _detectedTaps.add(TapEvent(
              timestamp: current.timestamp,
              magnitude: current.magnitude,
              x: current.x,
              y: current.y,
              z: current.z,
              analysis: tapAnalysis,
            ));
          });
        }
      }
    }
  }
  
  TapAnalysis _analyzeTapCharacteristics(
      SensorDataPoint peakPoint, int peakIndex, List<SensorDataPoint> dataWindow) {
    
    // Calculate rise time (time to reach peak)
    double riseTime = 0;
    if (peakIndex > 0) {
      final startTime = dataWindow[peakIndex - 1].timestamp;
      riseTime = peakPoint.timestamp.difference(startTime).inMilliseconds.toDouble();
    }
    
    // Calculate decay characteristics
    double decayRate = 0;
    if (peakIndex < dataWindow.length - 1) {
      final nextPoint = dataWindow[peakIndex + 1];
      final decayTime = nextPoint.timestamp.difference(peakPoint.timestamp).inMilliseconds;
      decayRate = (peakPoint.magnitude - nextPoint.magnitude) / decayTime;
    }
    
    // Calculate energy (area under curve around peak)
    double energy = 0;
    final windowStart = (peakIndex - 2).clamp(0, dataWindow.length - 1);
    final windowEnd = (peakIndex + 2).clamp(0, dataWindow.length - 1);
    
    for (int i = windowStart; i <= windowEnd; i++) {
      energy += dataWindow[i].magnitude;
    }
    
    return TapAnalysis(
      riseTime: riseTime,
      decayRate: decayRate,
      energy: energy,
      peakSharpness: _calculatePeakSharpness(peakIndex, dataWindow),
      frequencyContent: _calculateFrequencyContent(peakIndex, dataWindow),
    );
  }
  
  double _calculatePeakSharpness(int peakIndex, List<SensorDataPoint> data) {
    if (peakIndex < 2 || peakIndex > data.length - 3) return 0;
    
    final peakValue = data[peakIndex].magnitude;
    final prevAvg = (data[peakIndex - 1].magnitude + data[peakIndex - 2].magnitude) / 2;
    final nextAvg = (data[peakIndex + 1].magnitude + data[peakIndex + 2].magnitude) / 2;
    
    final riseSharpness = peakValue - prevAvg;
    final fallSharpness = peakValue - nextAvg;
    
    return (riseSharpness + fallSharpness) / 2;
  }
  
  double _calculateFrequencyContent(int peakIndex, List<SensorDataPoint> data) {
    // Simplified frequency analysis - look at variation in nearby points
    if (peakIndex < 1 || peakIndex > data.length - 2) return 0;
    
    final variations = [
      (data[peakIndex].magnitude - data[peakIndex - 1].magnitude).abs(),
      (data[peakIndex + 1].magnitude - data[peakIndex].magnitude).abs(),
    ];
    
    return variations.reduce((a, b) => a + b) / variations.length;
  }

  void _stopRecording() {
    _isRecording = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    setState(() {});
  }

  void _clearData() {
    setState(() {
      _accelerometerReadings.clear();
      _gyroscopeReadings.clear();
      _detectedTaps.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Data Analyzer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analysis Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Collection controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isRecording) ...[
                          ElevatedButton.icon(
                            onPressed: _stopRecording,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Collection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: _startRecording,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Collection'),
                          ),
                        ],
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _clearData,
                          child: const Text('Clear Data'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Threshold slider
                    Row(
                      children: [
                        const Text('Detection Threshold:'),
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
                    
                    // Stats
                    Text('Collected Data: ${_accelerometerReadings.length} accel, ${_gyroscopeReadings.length} gyro points'),
                    Text('Detected Taps: ${_detectedTaps.length}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Visualization tabs
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Accelerometer'),
                        Tab(text: 'Gyroscope'),
                        Tab(text: 'Analysis'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _AccelerometerTab(
                            data: _accelerometerReadings,
                            detectedTaps: _detectedTaps,
                          ),
                          _GyroscopeTab(
                            data: _gyroscopeReadings,
                          ),
                          _AnalysisTab(
                            detectedTaps: _detectedTaps,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccelerometerTab extends StatelessWidget {
  final List<SensorDataPoint> data;
  final List<TapEvent> detectedTaps;

  const _AccelerometerTab({
    required this.data,
    required this.detectedTaps,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No accelerometer data collected yet'),
      );
    }

    return Column(
      children: [
        // Line chart for accelerometer data
        Expanded(
          flex: 2,
          child: _buildAccelerometerChart(data, detectedTaps),
        ),
        
        const SizedBox(height: 20),
        
        // Raw data table
        Expanded(
          flex: 1,
          child: _buildRawDataTable(data),
        ),
      ],
    );
  }
  
  Widget _buildAccelerometerChart(List<SensorDataPoint> data, List<TapEvent> taps) {
    // Prepare chart data
    final chartData = data.map((point) => ChartData(
      timestamp: point.timestamp.millisecondsSinceEpoch,
      value: point.magnitude,
    )).toList();
    
    // TODO: Implement chart visualization
    return const Center(
      child: Text('Accelerometer Chart Visualization'),
    );
  }
  
  Widget _buildRawDataTable(List<SensorDataPoint> data) {
    final displayData = data.length > 20 ? data.sublist(data.length - 20) : data;
    
    return ListView(
      children: [
        const Text(
          'Recent Raw Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        DataTable(
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('X')),
            DataColumn(label: Text('Y')),
            DataColumn(label: Text('Z')),
            DataColumn(label: Text('Mag')),
          ],
          rows: displayData.map((point) {
            return DataRow(
              cells: [
                DataCell(Text('${point.timestamp.second}.${point.timestamp.millisecond}')),
                DataCell(Text(point.x.toStringAsFixed(2))),
                DataCell(Text(point.y.toStringAsFixed(2))),
                DataCell(Text(point.z.toStringAsFixed(2))),
                DataCell(Text(point.magnitude.toStringAsFixed(2))),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _GyroscopeTab extends StatelessWidget {
  final List<SensorDataPoint> data;

  const _GyroscopeTab({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No gyroscope data collected yet'),
      );
    }

    return Column(
      children: [
        // Line chart for gyroscope data
        Expanded(
          flex: 2,
          child: _buildGyroscopeChart(data),
        ),
        
        const SizedBox(height: 20),
        
        // Raw data table
        Expanded(
          flex: 1,
          child: _buildRawDataTable(data),
        ),
      ],
    );
  }
  
  Widget _buildGyroscopeChart(List<SensorDataPoint> data) {
    // TODO: Implement chart visualization
    return const Center(
      child: Text('Gyroscope Chart Visualization'),
    );
  }
  
  Widget _buildRawDataTable(List<SensorDataPoint> data) {
    final displayData = data.length > 20 ? data.sublist(data.length - 20) : data;
    
    return ListView(
      children: [
        const Text(
          'Recent Raw Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        DataTable(
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('X')),
            DataColumn(label: Text('Y')),
            DataColumn(label: Text('Z')),
            DataColumn(label: Text('Mag')),
          ],
          rows: displayData.map((point) {
            return DataRow(
              cells: [
                DataCell(Text('${point.timestamp.second}.${point.timestamp.millisecond}')),
                DataCell(Text(point.x.toStringAsFixed(2))),
                DataCell(Text(point.y.toStringAsFixed(2))),
                DataCell(Text(point.z.toStringAsFixed(2))),
                DataCell(Text(point.magnitude.toStringAsFixed(2))),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  final List<TapEvent> detectedTaps;

  const _AnalysisTab({required this.detectedTaps});

  @override
  Widget build(BuildContext context) {
    if (detectedTaps.isEmpty) {
      return const Center(
        child: Text('No taps detected yet. Start collecting data to see analysis.'),
      );
    }

    return ListView(
      children: [
        // Tap sequence visualization
        const Text(
          'Tap Sequence',
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
            itemCount: detectedTaps.length,
            itemBuilder: (context, index) {
              final tap = detectedTaps[index];
              return Container(
                margin: const EdgeInsets.all(10),
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: Center,
                    children: [
                      Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        tap.magnitude.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Detailed analysis
        const Text(
          'Detailed Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        
        // Tap timing analysis
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Timing Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                
                if (detectedTaps.length > 1) ...[
                  for (int i = 1; i < detectedTaps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Tap ${i} → Tap ${i + 1}: ${detectedTaps[i].timestamp.difference(detectedTaps[i - 1].timestamp).inMilliseconds}ms',
                      ),
                    ),
                ] else
                  const Text('Need at least 2 taps for timing analysis'),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Individual tap analysis
        const Text(
          'Individual Tap Characteristics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        
        ...detectedTaps.asMap().entries.map((entry) {
          final index = entry.key;
          final tap = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap #${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Timestamp: ${tap.timestamp.hour}:${tap.timestamp.minute}:${tap.timestamp.second}.${tap.timestamp.millisecond}'),
                  const SizedBox(height: 5),
                  Text('Magnitude: ${tap.magnitude.toStringAsFixed(2)}'),
                  const SizedBox(height: 5),
                  Text('Vector: (${tap.x.toStringAsFixed(2)}, ${tap.y.toStringAsFixed(2)}, ${tap.z.toStringAsFixed(2)})'),
                  
                  if (tap.analysis != null) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Advanced Analysis:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text('Rise Time: ${tap.analysis!.riseTime.toStringAsFixed(2)}ms'),
                    Text('Decay Rate: ${tap.analysis!.decayRate.toStringAsFixed(4)}'),
                    Text('Energy: ${tap.analysis!.energy.toStringAsFixed(2)}'),
                    Text('Sharpness: ${tap.analysis!.peakSharpness.toStringAsFixed(2)}'),
                    Text('Frequency Content: ${tap.analysis!.frequencyContent.toStringAsFixed(2)}'),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

// Data Models
class SensorDataPoint {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double magnitude;
  final String sensorType;

  SensorDataPoint({
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
  final TapAnalysis? analysis;

  TapEvent({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    this.analysis,
  });
}

class TapAnalysis {
  final double riseTime;
  final double decayRate;
  final double energy;
  final double peakSharpness;
  final double frequencyContent;

  TapAnalysis({
    required this.riseTime,
    required this.decayRate,
    required this.energy,
    required this.peakSharpness,
    required this.frequencyContent,
  });
}

class ChartData {
  final int timestamp;
  final double value;

  ChartData({
    required this.timestamp,
    required this.value,
  });
}