import 'package:flutter/material.dart';
import 'package:pocket_recorder/models/gesture_pattern.dart';
import 'package:pocket_recorder/screens/security_screen.dart';
import 'package:pocket_recorder/screens/gesture_training_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Default gesture mappings
  GestureType _doubleTapAction = GestureType.DoubleTap;
  GestureType _tripleTapAction = GestureType.TripleTap;
  GestureType _longSlapAction = GestureType.LongSlap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gesture Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildGestureSetting(
              context,
              'Double Tap',
              _doubleTapAction,
              _onDoubleTapChanged,
            ),
            const SizedBox(height: 16),
            _buildGestureSetting(
              context,
              'Triple Tap',
              _tripleTapAction,
              _onTripleTapChanged,
            ),
            const SizedBox(height: 16),
            _buildGestureSetting(
              context,
              'Long Slap',
              _longSlapAction,
              _onLongSlapChanged,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Gesture Training'),
              subtitle: const Text('Train the app to recognize your tapping style'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GestureTrainingScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Security Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('App Lock & Security'),
              subtitle: const Text('PIN, fingerprint, encryption, emergency delete'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecurityScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Stealth Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Stealth Mode'),
              subtitle: const Text('Hide app icon and notifications'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
              onTap: () {
                // Navigate to stealth mode settings
              },
            ),
            ListTile(
              title: const Text('Fake Notifications'),
              subtitle: const Text('Show system-like notifications'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
              onTap: () {
                // Navigate to fake notifications settings
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureSetting(
    BuildContext context,
    String title,
    GestureType currentValue,
    Function(GestureType?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButton<GestureType>(
          value: currentValue,
          isExpanded: true,
          onChanged: onChanged,
          items: const [
            DropdownMenuItem(
              value: GestureType.DoubleTap,
              child: Text('Capture Photo'),
            ),
            DropdownMenuItem(
              value: GestureType.TripleTap,
              child: Text('Record Video'),
            ),
            DropdownMenuItem(
              value: GestureType.LongSlap,
              child: Text('Record Audio'),
            ),
          ],
        ),
      ],
    );
  }

  void _onDoubleTapChanged(GestureType? value) {
    if (value != null) {
      setState(() {
        _doubleTapAction = value;
      });
    }
  }

  void _onTripleTapChanged(GestureType? value) {
    if (value != null) {
      setState(() {
        _tripleTapAction = value;
      });
    }
  }

  void _onLongSlapChanged(GestureType? value) {
    if (value != null) {
      setState(() {
        _longSlapAction = value;
      });
    }
  }
}