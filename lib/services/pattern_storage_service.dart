import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/pattern_signature.dart';

class PatternStorageService {
  static final PatternStorageService _instance = PatternStorageService._internal();
  factory PatternStorageService() => _instance;
  PatternStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _patternsKey = 'saved_patterns';

  // Save a pattern
  Future<void> savePattern(PatternSignature pattern) async {
    try {
      final List<PatternSignature> patterns = await getPatterns();
      patterns.add(pattern);
      await _savePatterns(patterns);
    } catch (e) {
      print('Error saving pattern: $e');
    }
  }

  // Get all patterns
  Future<List<PatternSignature>> getPatterns() async {
    try {
      final String? jsonString = await _storage.read(key: _patternsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => PatternSignature.fromMap(item)).toList();
    } catch (e) {
      print('Error loading patterns: $e');
      return [];
    }
  }

  // Delete a pattern
  Future<void> deletePattern(String id) async {
    try {
      final List<PatternSignature> patterns = await getPatterns();
      patterns.removeWhere((pattern) => pattern.id == id);
      await _savePatterns(patterns);
    } catch (e) {
      print('Error deleting pattern: $e');
    }
  }

  // Update a pattern
  Future<void> updatePattern(PatternSignature updatedPattern) async {
    try {
      final List<PatternSignature> patterns = await getPatterns();
      patterns.removeWhere((pattern) => pattern.id == updatedPattern.id);
      patterns.add(updatedPattern);
      await _savePatterns(patterns);
    } catch (e) {
      print('Error updating pattern: $e');
    }
  }

  // Find matching pattern with 60% tolerance
  Future<PatternSignature?> findMatchingPattern(PatternSignature inputPattern) async {
    final List<PatternSignature> patterns = await getPatterns();
    
    for (final pattern in patterns) {
      if (pattern.matches(inputPattern, tolerance: 0.6)) {
        return pattern;
      }
    }
    
    return null;
  }

  // Save all patterns
  Future<void> _savePatterns(List<PatternSignature> patterns) async {
    try {
      final String jsonString = json.encode(
        patterns.map((pattern) => pattern.toMap()).toList(),
      );
      await _storage.write(key: _patternsKey, value: jsonString);
    } catch (e) {
      print('Error saving patterns: $e');
    }
  }

  // Clear all patterns
  Future<void> clearAllPatterns() async {
    try {
      await _storage.delete(key: _patternsKey);
    } catch (e) {
      print('Error clearing patterns: $e');
    }
  }
}