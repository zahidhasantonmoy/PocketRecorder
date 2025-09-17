import 'package:flutter/material.dart';
import 'package:pocket_recorder/services/gesture_detection_service.dart';

class GestureTrainingScreen extends StatefulWidget {
  const GestureTrainingScreen({super.key});

  @override
  State<GestureTrainingScreen> createState() => _GestureTrainingScreenState();
}

class _GestureTrainingScreenState extends State<GestureTrainingScreen> {
  final GestureDetectionService _gestureService = GestureDetectionService();
  
  // Training state
  bool _isTraining = false;
  String _trainingStatus = 'Tap the back of your phone to train the gesture recognition';
  IconData _statusIcon = Icons.touch_app;
  Color _statusColor = Colors.grey;
  
  // Gesture data
  int _tapCount = 0;
  DateTime? _firstTapTime;
  List<double> _tapIntervals = [];

  @override
  void initState() {
    super.initState();
  }

  void _startTraining() {
    setState(() {
      _isTraining = true;
      _trainingStatus = 'Tap the back of your phone 5 times to train the recognition';
      _statusIcon = Icons.touch_app;
      _statusColor = Colors.blue;
      _tapCount = 0;
      _firstTapTime = null;
      _tapIntervals.clear();
    });
    
    // Set up gesture callbacks for training
    _gestureService.onDoubleTap = _onTapDetected;
    _gestureService.onTripleTap = _onTapDetected;
    _gestureService.onLongSlap = _onTapDetected;
    
    // Start listening for gestures
    _gestureService.startListening();
  }

  void _stopTraining() {
    setState(() {
      _isTraining = false;
      _trainingStatus = 'Tap the back of your phone to train the gesture recognition';
      _statusIcon = Icons.touch_app;
      _statusColor = Colors.grey;
    });
    
    // Stop listening for gestures
    _gestureService.stopListening();
  }

  void _onTapDetected() {
    if (!_isTraining) return;
    
    setState(() {
      _tapCount++;
      
      if (_firstTapTime == null) {
        _firstTapTime = DateTime.now();
      } else {
        final now = DateTime.now();
        final interval = now.difference(_firstTapTime!).inMilliseconds;
        _tapIntervals.add(interval.toDouble());
        _firstTapTime = now;
      }
      
      _trainingStatus = 'Tap $_tapCount/5 - Keep tapping';
      _statusIcon = Icons.touch_app;
      _statusColor = Colors.green;
    });
    
    if (_tapCount >= 5) {
      _finishTraining();
    }
  }

  void _finishTraining() {
    _stopTraining();
    
    // Calculate average tap interval
    double averageInterval = 0;
    if (_tapIntervals.isNotEmpty) {
      double total = _tapIntervals.reduce((a, b) => a + b);
      averageInterval = total / _tapIntervals.length;
    }
    
    setState(() {
      _trainingStatus = 'Training complete! Average tap interval: ${averageInterval.toStringAsFixed(0)}ms';
      _statusIcon = Icons.check_circle;
      _statusColor = Colors.green;
    });
    
    // Show completion dialog
    Future.delayed(const Duration(seconds: 1), () {
      _showTrainingCompleteDialog(averageInterval);
    });
  }

  void _showTrainingCompleteDialog(double averageInterval) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Training Complete'),
          content: Text(
            'Gesture recognition has been trained based on your tapping pattern.\n\n'
            'Average tap interval: ${averageInterval.toStringAsFixed(0)}ms\n\n'
            'The app will now be more accurate at recognizing your specific tapping style.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _gestureService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gesture Training'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Gesture Training',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Train the app to recognize your specific tapping patterns',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Icon(
              _statusIcon,
              size: 100,
              color: _statusColor,
            ),
            const SizedBox(height: 32),
            Text(
              _trainingStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            if (!_isTraining)
              ElevatedButton(
                onPressed: _startTraining,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Start Training'),
              )
            else
              ElevatedButton(
                onPressed: _stopTraining,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Stop Training'),
              ),
            const SizedBox(height: 32),
            const Text(
              'Instructions:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Hold your phone naturally in your hand\n'
              '2. Tap the back of your phone 5 times\n'
              '3. Try to maintain a consistent rhythm\n'
              '4. The app will learn your specific tapping pattern\n'
              '5. This will improve gesture recognition accuracy',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}