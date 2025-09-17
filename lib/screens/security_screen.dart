import 'package:flutter/material.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isAppLockEnabled = false;
  bool _isEncryptionEnabled = true;
  bool _isEmergencyDeleteEnabled = false;
  String _selectedLockMethod = 'PIN';
  String _emergencyDeletePin = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Protection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('App Lock'),
              subtitle: const Text('Require authentication to open the app'),
              trailing: Switch(
                value: _isAppLockEnabled,
                onChanged: (value) {
                  setState(() {
                    _isAppLockEnabled = value;
                  });
                },
              ),
              onTap: () {
                if (_isAppLockEnabled) {
                  _showLockMethodSelector();
                } else {
                  setState(() {
                    _isAppLockEnabled = true;
                  });
                  _showLockSetupDialog();
                }
              },
            ),
            if (_isAppLockEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Lock Method: $_selectedLockMethod',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Encryption'),
              subtitle: const Text('Encrypt all captured media files'),
              trailing: Switch(
                value: _isEncryptionEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEncryptionEnabled = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Emergency Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Emergency Delete'),
              subtitle: const Text('Delete all media with shake or secret PIN'),
              trailing: Switch(
                value: _isEmergencyDeleteEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEmergencyDeleteEnabled = value;
                  });
                },
              ),
              onTap: () {
                if (_isEmergencyDeleteEnabled) {
                  _showEmergencyDeleteSetup();
                } else {
                  setState(() {
                    _isEmergencyDeleteEnabled = true;
                  });
                  _showEmergencyDeleteSetup();
                }
              },
            ),
            if (_isEmergencyDeleteEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Shake to delete: Enabled\nSecret PIN: ${_emergencyDeletePin.isEmpty ? 'Not set' : '****'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 32),
            const Text(
              'Privacy Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Stealth Mode'),
              subtitle: const Text('Hide app icon and use fake notifications'),
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
              subtitle: const Text('Show system-like notifications during capture'),
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

  void _showLockMethodSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lock Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('PIN'),
                value: 'PIN',
                groupValue: _selectedLockMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedLockMethod = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Password'),
                value: 'Password',
                groupValue: _selectedLockMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedLockMethod = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Fingerprint'),
                value: 'Fingerprint',
                groupValue: _selectedLockMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedLockMethod = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLockSetupDialog() {
    TextEditingController pinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set $_selectedLockMethod'),
          content: TextField(
            controller: pinController,
            decoration: InputDecoration(
              hintText: _selectedLockMethod == 'PIN' ? 'Enter 4-digit PIN' : 'Enter password',
            ),
            obscureText: _selectedLockMethod != 'Fingerprint',
            keyboardType: _selectedLockMethod == 'PIN' ? TextInputType.number : TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Save the PIN/password
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('App lock has been set up'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencyDeleteSetup() {
    TextEditingController pinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Emergency Delete Setup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set a secret PIN for emergency media deletion'),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  hintText: 'Enter 4-digit secret PIN',
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _emergencyDeletePin = pinController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Emergency delete has been set up'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}