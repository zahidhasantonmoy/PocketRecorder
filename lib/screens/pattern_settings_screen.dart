import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../models/pattern_setting.dart';
import '../services/pattern_storage_service.dart';
import '../models/pattern_signature.dart';
import 'sos_settings_screen.dart';
import 'pattern_training_screen.dart';

class PatternSettingsScreen extends StatefulWidget {
  const PatternSettingsScreen({super.key});

  @override
  State<PatternSettingsScreen> createState() => _PatternSettingsScreenState();
}

class _PatternSettingsScreenState extends State<PatternSettingsScreen> {
  late List<PatternSetting> _patternSettings;
  List<PatternSignature> _customPatterns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatternSettings();
    _loadCustomPatterns();
  }

  Future<void> _loadPatternSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    _patternSettings = await SettingsService().getPatternSettings();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCustomPatterns() async {
    _customPatterns = await PatternStorageService().getPatterns();
    setState(() {});
  }

  Future<void> _savePatternSettings() async {
    await SettingsService().savePatternSettings(_patternSettings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pattern settings saved')),
      );
    }
  }

  void _addNewPattern() {
    setState(() {
      _patternSettings.add(
        PatternSetting(
          tapCount: 1,
          functionName: 'New Function',
          functionType: 'audio',
        ),
      );
    });
  }

  void _updatePattern(int index, PatternSetting updatedPattern) {
    setState(() {
      _patternSettings[index] = updatedPattern;
    });
  }

  void _removePattern(int index) {
    setState(() {
      _patternSettings.removeAt(index);
    });
  }

  void _deleteCustomPattern(String id) async {
    await PatternStorageService().deletePattern(id);
    _loadCustomPatterns(); // Reload patterns
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePatternSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Default Patterns',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(_patternSettings.length, (index) {
                        final pattern = _patternSettings[index];
                        return _PatternSettingItem(
                          pattern: pattern,
                          onUpdate: (updatedPattern) {
                            _updatePattern(index, updatedPattern);
                          },
                          onRemove: () {
                            _removePattern(index);
                          },
                        );
                      }),
                      
                      const SizedBox(height: 30),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Custom Patterns',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PatternTrainingScreen(),
                                ),
                              ).then((_) => _loadCustomPatterns());
                            },
                            child: const Text('Train New'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_customPatterns.isEmpty)
                        const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.pattern,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No custom patterns recorded yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Tap "Train New" to record your first pattern',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._customPatterns.map((pattern) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(pattern.name),
                              subtitle: Text(
                                '${pattern.timestamps.length} taps • ${pattern.assignedFunction.capitalize()}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteCustomPattern(pattern.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SOSSettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.emergency),
                    label: const Text('SOS Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPattern,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PatternSettingItem extends StatefulWidget {
  final PatternSetting pattern;
  final Function(PatternSetting) onUpdate;
  final VoidCallback onRemove;

  const _PatternSettingItem({
    required this.pattern,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_PatternSettingItem> createState() => _PatternSettingItemState();
}

class _PatternSettingItemState extends State<_PatternSettingItem> {
  late TextEditingController _nameController;
  late int _tapCount;
  late String _functionType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pattern.functionName);
    _tapCount = widget.pattern.tapCount;
    _functionType = widget.pattern.functionType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updatePattern() {
    final updatedPattern = PatternSetting(
      tapCount: _tapCount,
      functionName: _nameController.text,
      functionType: _functionType,
    );
    widget.onUpdate(updatedPattern);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Function Name',
                    ),
                    onChanged: (_) => _updatePattern(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Taps:'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (_tapCount > 1) _tapCount--;
                    });
                    _updatePattern();
                  },
                ),
                Text('$_tapCount'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _tapCount++;
                    });
                    _updatePattern();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _functionType,
              decoration: const InputDecoration(
                labelText: 'Function Type',
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
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _functionType = value;
                  });
                  _updatePattern();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}