import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocket_recorder/models/app_settings.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _settingsKey = 'app_settings';

  // Default settings
  final AppSettings _defaultSettings = AppSettings();

  Future<AppSettings> getAppSettings() async {
    try {
      final String? jsonString = await _storage.read(key: _settingsKey);
      
      if (jsonString == null) {
        // Return default settings if none are saved
        return _defaultSettings;
      }
      
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return AppSettings.fromMap(jsonMap);
    } catch (e) {
      // Return default settings if there's an error
      return _defaultSettings;
    }
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    try {
      final String jsonString = json.encode(settings.toMap());
      await _storage.write(key: _settingsKey, value: jsonString);
    } catch (e) {
      // Handle error silently
      print('Error saving app settings: $e');
    }
  }

  Future<void> resetToDefaults() async {
    await saveAppSettings(_defaultSettings);
  }
}