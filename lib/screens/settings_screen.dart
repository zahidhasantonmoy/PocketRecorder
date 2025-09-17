import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../recorder_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Audio Quality',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('Sample Rate'),
            subtitle: const Text('44.1 kHz'),
            trailing: DropdownButton<String>(
              value: '44100',
              items: const [
                DropdownMenuItem(
                  value: '22050',
                  child: Text('22.05 kHz'),
                ),
                DropdownMenuItem(
                  value: '44100',
                  child: Text('44.1 kHz'),
                ),
                DropdownMenuItem(
                  value: '48000',
                  child: Text('48 kHz'),
                ),
              ],
              onChanged: (value) {
                // Handle sample rate change
              },
            ),
          ),
          ListTile(
            title: const Text('Bit Rate'),
            subtitle: const Text('128 kbps'),
            trailing: DropdownButton<String>(
              value: '128000',
              items: const [
                DropdownMenuItem(
                  value: '64000',
                  child: Text('64 kbps'),
                ),
                DropdownMenuItem(
                  value: '128000',
                  child: Text('128 kbps'),
                ),
                DropdownMenuItem(
                  value: '192000',
                  child: Text('192 kbps'),
                ),
                DropdownMenuItem(
                  value: '256000',
                  child: Text('256 kbps'),
                ),
                DropdownMenuItem(
                  value: '320000',
                  child: Text('320 kbps'),
                ),
              ],
              onChanged: (value) {
                // Handle bit rate change
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Storage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Delete recordings after sharing'),
            value: false,
            onChanged: (value) {
              // Handle toggle
            },
          ),
          SwitchListTile(
            title: const Text('Auto-delete old recordings'),
            subtitle: const Text('Delete recordings older than 30 days'),
            value: false,
            onChanged: (value) {
              // Handle toggle
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('System default'),
            trailing: DropdownButton<String>(
              value: 'system',
              items: const [
                DropdownMenuItem(
                  value: 'light',
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: 'dark',
                  child: Text('Dark'),
                ),
                DropdownMenuItem(
                  value: 'system',
                  child: Text('System default'),
                ),
              ],
              onChanged: (value) {
                // Handle theme change
              },
            ),
          ),
        ],
      ),
    );
  }
}