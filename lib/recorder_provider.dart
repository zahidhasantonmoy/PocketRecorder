import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'models/recording.dart';
import 'services/video_recording_service.dart';

class RecorderProvider with ChangeNotifier {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final VideoRecordingService _videoService = VideoRecordingService();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String _currentRecordingPath = '';
  String _currentPlayingPath = '';
  double _recordedDuration = 0.0;
  double _currentPlaybackPosition = 0.0;
  double _currentPlaybackDuration = 0.0;
  List<Recording> _recordings = [];
  StreamSubscription? _playerSubscription;
  StreamSubscription? _recorderSubscription;
  Timer? _durationTimer;
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String get currentRecordingPath => _currentRecordingPath;
  String get currentPlayingPath => _currentPlayingPath;
  double get recordedDuration => _recordedDuration;
  double get currentPlaybackPosition => _currentPlaybackPosition;
  double get currentPlaybackDuration => _currentPlaybackDuration;
  List<Recording> get recordings => _recordings;
  VideoRecordingService get videoService => _videoService;
  
  RecorderProvider() {
    _init();
  }
  
  Future<void> _init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    await _requestPermissions();
    await loadRecordings();
    await _videoService.initializeCamera();
  }
  
  // Check and request permissions as needed
  Future<bool> checkAndRequestPermissions(String functionType) async {
    List<Permission> permissions = [];
    
    switch (functionType) {
      case 'audio':
        permissions = [Permission.microphone, Permission.storage];
        break;
      case 'video':
        permissions = [Permission.camera, Permission.microphone, Permission.storage];
        break;
      case 'image':
        permissions = [Permission.camera, Permission.storage];
        break;
      default:
        permissions = [Permission.microphone, Permission.camera, Permission.storage];
    }
    
    // Check current permissions
    bool allGranted = true;
    for (var permission in permissions) {
      var status = await permission.status;
      if (status != PermissionStatus.granted) {
        allGranted = false;
        break;
      }
    }
    
    // If not all permissions are granted, request them
    if (!allGranted) {
      final statuses = await permissions.request();
      for (var permission in permissions) {
        if (statuses[permission] != PermissionStatus.granted) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  Future<void> startRecording() async {
    if (_isRecording) return;
    
    // Check permissions
    final hasPermissions = await checkAndRequestPermissions('audio');
    if (!hasPermissions) {
      print('Audio recording permissions not granted');
      return;
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = '${directory.path}/$fileName';
      
      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4,
      );
      
      _isRecording = true;
      _recordedDuration = 0.0;
      
      // Update duration periodically using a timer
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!_isRecording) {
          timer.cancel();
          return;
        }
        _recordedDuration += 0.1;
        notifyListeners();
      });
      
      notifyListeners();
    } catch (e) {
      print('Error starting recording: $e');
    }
  }
  
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      await _recorder.stopRecorder();
      _durationTimer?.cancel();
      _isRecording = false;
      
      // Verify the file was created and has content
      final file = File(_currentRecordingPath);
      if (await file.exists()) {
        final length = await file.length();
        if (length > 0) {
          // Add the new recording to our list
          final newRecording = Recording(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            path: _currentRecordingPath,
            name: 'Recording ${DateFormat('hh:mm a').format(DateTime.now())}',
            duration: _recordedDuration,
            date: DateTime.now(),
          );
          
          _recordings.insert(0, newRecording);
          await _saveRecordings();
          notifyListeners();
        } else {
          // Delete empty file
          await file.delete();
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }
  
  Future<void> startVideoRecording() async {
    if (_isRecording) return;
    
    // Check permissions
    final hasPermissions = await checkAndRequestPermissions('video');
    if (!hasPermissions) {
      print('Video recording permissions not granted');
      return;
    }
    
    try {
      await _videoService.startRecording();
      _isRecording = _videoService.isRecording;
      
      // Listen to video service updates
      _videoService.addListener(_onVideoServiceUpdate);
      
      notifyListeners();
    } catch (e) {
      print('Error starting video recording: $e');
    }
  }
  
  void _onVideoServiceUpdate() {
    // Update our recording state based on video service
    if (_isRecording != _videoService.isRecording) {
      _isRecording = _videoService.isRecording;
      notifyListeners();
    }
  }
  
  Future<void> stopVideoRecording() async {
    if (!_isRecording) return;
    
    try {
      final videoPath = await _videoService.stopRecording();
      _videoService.removeListener(_onVideoServiceUpdate);
      _isRecording = _videoService.isRecording;
      
      if (videoPath != null) {
        // Verify the file was created and has content
        final file = File(videoPath);
        if (await file.exists()) {
          final length = await file.length();
          if (length > 0) {
            // Add the new video recording to our list
            final newRecording = Recording(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              path: videoPath,
              name: 'Video ${DateFormat('hh:mm a').format(DateTime.now())}',
              duration: 0.0, // We'll need to calculate this
              date: DateTime.now(),
            );
            
            _recordings.insert(0, newRecording);
            await _saveRecordings();
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error stopping video recording: $e');
    }
  }
  
  Future<void> captureImage() async {
    if (_isRecording) return;
    
    // Check permissions
    final hasPermissions = await checkAndRequestPermissions('image');
    if (!hasPermissions) {
      print('Image capture permissions not granted');
      return;
    }
    
    try {
      final imagePath = await _videoService.takePicture();
      
      if (imagePath != null) {
        // Verify the file was created and has content
        final file = File(imagePath);
        if (await file.exists()) {
          final length = await file.length();
          if (length > 0) {
            // Add the new image to our list
            final newRecording = Recording(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              path: imagePath,
              name: 'Photo ${DateFormat('hh:mm a').format(DateTime.now())}',
              duration: 0.0,
              date: DateTime.now(),
            );
            
            _recordings.insert(0, newRecording);
            await _saveRecordings();
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error capturing image: $e');
    }
  }
  
  Future<void> startPlayback(String path) async {
    if (_isPlaying && _currentPlayingPath == path) {
      await _player.resumePlayer();
      return;
    }
    
    try {
      // Stop any current playback
      if (_isPlaying) {
        await _player.stopPlayer();
        _playerSubscription?.cancel();
      }
      
      _currentPlayingPath = path;
      _isPlaying = true;
      
      // For now, we'll set a default duration or calculate it another way
      _currentPlaybackDuration = 0.0; // We'll update this as playback progresses
      
      await _player.startPlayer(
        fromURI: path,
        codec: Codec.aacMP4,
      );
      
      // Listen to player position updates
      _playerSubscription = _player.onProgress?.listen((position) {
        _currentPlaybackPosition = position.position.inMilliseconds.toDouble() / 1000;
        // Update duration as we play
        if (_currentPlaybackPosition > _currentPlaybackDuration) {
          _currentPlaybackDuration = _currentPlaybackPosition;
        }
        notifyListeners();
      });
      
      notifyListeners();
    } catch (e) {
      print('Error starting playback: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }
  
  Future<void> pausePlayback() async {
    if (!_isPlaying) return;
    
    try {
      await _player.pausePlayer();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      print('Error pausing playback: $e');
    }
  }
  
  Future<void> stopPlayback() async {
    try {
      await _player.stopPlayer();
      _playerSubscription?.cancel();
      _isPlaying = false;
      _currentPlaybackPosition = 0.0;
      _currentPlayingPath = '';
      notifyListeners();
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }
  
  Future<void> seekPlayback(double seconds) async {
    try {
      await _player.seekToPlayer(Duration(milliseconds: (seconds * 1000).toInt()));
      _currentPlaybackPosition = seconds;
      notifyListeners();
    } catch (e) {
      print('Error seeking playback: $e');
    }
  }
  
  Future<void> deleteRecording(String id) async {
    final index = _recordings.indexWhere((r) => r.id == id);
    if (index != -1) {
      try {
        final recording = _recordings[index];
        final file = File(recording.path);
        if (await file.exists()) {
          await file.delete();
        }
        
        _recordings.removeAt(index);
        await _saveRecordings();
        notifyListeners();
      } catch (e) {
        print('Error deleting recording: $e');
      }
    }
  }
  
  Future<void> renameRecording(String id, String newName) async {
    final index = _recordings.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recordings[index] = Recording(
        id: _recordings[index].id,
        path: _recordings[index].path,
        name: newName,
        duration: _recordings[index].duration,
        date: _recordings[index].date,
      );
      await _saveRecordings();
      notifyListeners();
    }
  }
  
  Future<void> loadRecordings() async {
    // In a real app, you would load recordings from a database or file
    // For now, we'll just initialize with an empty list
    _recordings = [];
    notifyListeners();
  }
  
  Future<void> _saveRecordings() async {
    // In a real app, you would save recordings to a database or file
    // For now, we'll just keep them in memory
  }
  
  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _playerSubscription?.cancel();
    _recorderSubscription?.cancel();
    _durationTimer?.cancel();
    _videoService.removeListener(_onVideoServiceUpdate);
    _videoService.dispose();
    super.dispose();
  }
}