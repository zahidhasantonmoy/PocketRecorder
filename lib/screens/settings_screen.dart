import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../recorder_provider.dart';
import '../services/app_settings_service.dart';
import '../models/app_settings.dart';
import '../services/background_pattern_service.dart';
import 'developer_info_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    _settings = await SettingsService().getAppSettings();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await SettingsService().saveAppSettings(_settings);
    // Update background service if settings changed
    await BackgroundPatternDetectionService().updateSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                    value: _settings.audioSampleRate,
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
                      if (value != null) {
                        setState(() {
                          _settings.audioSampleRate = value;
                        });
                      }
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Bit Rate'),
                  subtitle: const Text('128 kbps'),
                  trailing: DropdownButton<String>(
                    value: _settings.audioBitRate,
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
                      if (value != null) {
                        setState(() {
                          _settings.audioBitRate = value;
                        });
                      }
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
                  value: _settings.deleteAfterSharing,
                  onChanged: (value) {
                    setState(() {
                      _settings.deleteAfterSharing = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto-delete old recordings'),
                  subtitle: Text('Delete recordings older than ${_settings.autoDeleteDays} days'),
                  value: _settings.autoDeleteOldRecordings,
                  onChanged: (value) {
                    setState(() {
                      _settings.autoDeleteOldRecordings = value;
                    });
                  },
                ),
                ListTile(
                  title: const Text('Auto-delete days'),
                  trailing: DropdownButton<int>(
                    value: _settings.autoDeleteDays,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                      DropdownMenuItem(value: 14, child: Text('14 days')),
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                      DropdownMenuItem(value: 60, child: Text('60 days')),
                      DropdownMenuItem(value: 90, child: Text('90 days')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings.autoDeleteDays = value;
                        });
                      }
                    },
                  ),
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
                    value: _settings.themeMode,
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
                      if (value != null) {
                        setState(() {
                          _settings.themeMode = value;
                        });
                      }
                    },
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Camera',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text('Default Camera'),
                  trailing: DropdownButton<String>(
                    value: _settings.defaultCamera,
                    items: const [
                      DropdownMenuItem(
                        value: 'front',
                        child: Text('Front'),
                      ),
                      DropdownMenuItem(
                        value: 'back',
                        child: Text('Back'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings.defaultCamera = value;
                        });
                      }
                    },
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Background Service',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Enable background service'),
                  subtitle: const Text('Keep pattern detection active'),
                  value: _settings.backgroundServiceEnabled,
                  onChanged: (value) {
                    setState(() {
                      _settings.backgroundServiceEnabled = value;
                    });
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Privacy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Discreet mode'),
                  subtitle: const Text('Hide app icon and notifications'),
                  value: _settings.discreetMode,
                  onChanged: (value) {
                    setState(() {
                      _settings.discreetMode = value;
                    });
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text('Developer Info'),
                  subtitle: const Text('Zahid Hasan Tonmoy'),
                  leading: const Icon(Icons.info),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeveloperInfoScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}