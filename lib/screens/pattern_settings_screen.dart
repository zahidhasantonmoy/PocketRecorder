import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../models/pattern_setting.dart';

class PatternSettingsScreen extends StatefulWidget {
  const PatternSettingsScreen({super.key});

  @override
  State<PatternSettingsScreen> createState() => _PatternSettingsScreenState();
}

class _PatternSettingsScreenState extends State<PatternSettingsScreen> {
  late List<PatternSetting> _patternSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatternSettings();
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _patternSettings.length,
              itemBuilder: (context, index) {
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
              },
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