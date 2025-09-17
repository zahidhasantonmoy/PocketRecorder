import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocket_recorder/models/pattern_setting.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _patternSettingsKey = 'pattern_settings';

  // Default patterns
  final List<PatternSetting> _defaultPatterns = [
    PatternSetting(tapCount: 2, functionName: 'Audio Recording', functionType: 'audio'),
    PatternSetting(tapCount: 3, functionName: 'Video Recording', functionType: 'video'),
    PatternSetting(tapCount: 4, functionName: 'Image Capture', functionType: 'image'),
    PatternSetting(tapCount: 5, functionName: 'SOS Alert', functionType: 'sos'),
  ];

  Future<List<PatternSetting>> getPatternSettings() async {
    try {
      final String? jsonString = await _storage.read(key: _patternSettingsKey);
      
      if (jsonString == null) {
        // Return default patterns if none are saved
        return _defaultPatterns;
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => PatternSetting.fromMap(item)).toList();
    } catch (e) {
      // Return default patterns if there's an error
      return _defaultPatterns;
    }
  }

  Future<void> savePatternSettings(List<PatternSetting> patterns) async {
    try {
      final String jsonString = json.encode(
        patterns.map((pattern) => pattern.toMap()).toList(),
      );
      await _storage.write(key: _patternSettingsKey, value: jsonString);
    } catch (e) {
      // Handle error silently
      print('Error saving pattern settings: $e');
    }
  }

  Future<void> resetToDefaults() async {
    await savePatternSettings(_defaultPatterns);
  }
}