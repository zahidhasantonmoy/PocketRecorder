import 'package:flutter/material.dart';
import 'package:pocket_recorder/services/gesture_detection_service.dart';
import 'package:pocket_recorder/utils/permission_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GestureDetectionService _gestureService = GestureDetectionService();
  String _statusText = 'Initializing...';
  IconData _statusIcon = Icons.hourglass_bottom;
  Color _statusColor = Colors.grey;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    // Request necessary permissions
    final permissions = await PermissionUtils.requestAllPermissions();
    
    final allGranted = permissions.values.every((granted) => granted);
    
    setState(() {
      _permissionsGranted = allGranted;
      if (allGranted) {
        _statusText = 'Listening for gestures...';
        _statusIcon = Icons.touch_app;
        _statusColor = Colors.grey;
        _initializeGestureDetection();
      } else {
        _statusText = 'Permissions required for app to function';
        _statusIcon = Icons.error;
        _statusColor = Colors.red;
      }
    });
  }

  void _initializeGestureDetection() {
    // Set up gesture callbacks
    _gestureService.onDoubleTap = _onDoubleTap;
    _gestureService.onTripleTap = _onTripleTap;
    _gestureService.onLongSlap = _onLongSlap;
    
    // Start listening for gestures
    _gestureService.startListening();
  }

  void _onDoubleTap() {
    setState(() {
      _statusText = 'Double tap detected! Capturing photo...';
      _statusIcon = Icons.camera_alt;
      _statusColor = Colors.green;
    });

    // Reset status after delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _statusText = 'Listening for gestures...';
        _statusIcon = Icons.touch_app;
        _statusColor = Colors.grey;
      });
    });
  }

  void _onTripleTap() {
    setState(() {
      _statusText = 'Triple tap detected! Starting video recording...';
      _statusIcon = Icons.videocam;
      _statusColor = Colors.blue;
    });

    // Reset status after delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _statusText = 'Listening for gestures...';
        _statusIcon = Icons.touch_app;
        _statusColor = Colors.grey;
      });
    });
  }

  void _onLongSlap() {
    setState(() {
      _statusText = 'Long slap detected! Starting audio recording...';
      _statusIcon = Icons.mic;
      _statusColor = Colors.orange;
    });

    // Reset status after delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _statusText = 'Listening for gestures...';
        _statusIcon = Icons.touch_app;
        _statusColor = Colors.grey;
      });
    });
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
        title: const Text('PocketRecorder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PocketRecorder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap/Slap patterns for background media capture',
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
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            if (!_permissionsGranted)
              ElevatedButton(
                onPressed: _initializeApp,
                child: const Text('Request Permissions'),
              )
            else
              const Text(
                'Try double-tapping the back of your phone',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}