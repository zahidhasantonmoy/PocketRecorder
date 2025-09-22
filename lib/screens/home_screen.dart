import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../recorder_provider.dart';
import '../utils/formatting_utils.dart';
import 'recordings_screen.dart';
import 'settings_screen.dart';
import 'pattern_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recorderProvider = Provider.of<RecorderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketRecorder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.gesture),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatternSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecordingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo
          const Icon(
            Icons.security,
            size: 60,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 10),
          const Text(
            'PocketRecorder',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 30),
          
          // Main recording button
          Center(
            child: GestureDetector(
              onTapDown: (_) {
                _animationController.forward();
                // Toggle recording when pressed
                if (recorderProvider.isRecording) {
                  recorderProvider.stopRecording();
                } else {
                  recorderProvider.startRecording();
                }
              },
              onTapUp: (_) {
                _animationController.reverse();
              },
              onTapCancel: () {
                _animationController.reverse();
              },
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: recorderProvider.isRecording
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      recorderProvider.isRecording
                          ? Icons.stop
                          : Icons.mic_none,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            recorderProvider.isRecording
                ? 'Recording...'
                : 'Tap to start/stop recording',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            recorderProvider.isRecording
                ? FormattingUtils.formatDuration(recorderProvider.recordedDuration)
                : 'Ready to record',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          const SizedBox(height: 40),
          
          // Quick action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickActionButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  isRecording: recorderProvider.isRecording && 
                               recorderProvider.videoService.isRecording,
                  onTap: () {
                    // Toggle video recording
                    if (recorderProvider.isRecording) {
                      recorderProvider.stopVideoRecording();
                    } else {
                      recorderProvider.startVideoRecording();
                    }
                  },
                ),
                _QuickActionButton(
                  icon: Icons.camera_alt,
                  label: 'Photo',
                  isRecording: false, // Photos are instant
                  onTap: () {
                    // Capture photo
                    recorderProvider.captureImage();
                  },
                ),
                _QuickActionButton(
                  icon: Icons.emergency,
                  label: 'SOS',
                  isRecording: false,
                  onTap: () {
                    // Send SOS alert
                    _sendSOSAlert();
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('Pattern detection active'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _sendSOSAlert() {
    // Show a simple alert dialog for SOS
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SOS Alert'),
          content: const Text('Emergency alert sent to trusted contacts.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isRecording;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isRecording,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            IconButton(
              icon: Icon(icon, size: 30),
              onPressed: onTap,
              style: IconButton.styleFrom(
                backgroundColor: isRecording ? Colors.red : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            if (isRecording)
              const Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.circle,
                  color: Colors.red,
                  size: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}