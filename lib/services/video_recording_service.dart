import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:cross_file/cross_file.dart';
import '../services/app_settings_service.dart';
import '../models/app_settings.dart';

class VideoRecordingService with ChangeNotifier {
  CameraController? _cameraController;
  bool _isRecording = false;
  String _currentVideoPath = '';
  XFile? _videoFile;
  
  // Getters
  bool get isRecording => _isRecording;
  String get currentVideoPath => _currentVideoPath;
  CameraController? get cameraController => _cameraController;
  
  // Initialize camera
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      // Get user's preferred camera setting
      final settings = await SettingsService().getAppSettings();
      CameraDescription camera;
      
      if (settings.defaultCamera == 'front' && cameras.length > 1) {
        // Try to find front camera
        camera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      } else {
        // Use back camera (default)
        camera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _cameraController!.initialize();
      notifyListeners();
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }
  
  // Start video recording
  Future<void> startRecording() async {
    if (_isRecording || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      // Create dedicated folder for recordings
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/PocketRecorder/Video');
      if (!(await recordingsDir.exists())) {
        await recordingsDir.create(recursive: true);
      }
      
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final fileName = 'video_${formatter.format(DateTime.now())}.mp4';
      _currentVideoPath = '${recordingsDir.path}/$fileName';
      
      // Start recording
      await _cameraController!.startVideoRecording();
      _videoFile = XFile(_currentVideoPath); // Create XFile from path
      _isRecording = true;
      notifyListeners();
    } catch (e) {
      print('Error starting video recording: $e');
    }
  }
  
  // Stop video recording
  Future<String?> stopRecording() async {
    if (!_isRecording || _cameraController == null) {
      return null;
    }
    
    try {
      // Stop recording
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      _isRecording = false;
      
      // The video file is already saved to _currentVideoPath by the camera controller
      notifyListeners();
      return _currentVideoPath;
    } catch (e) {
      print('Error stopping video recording: $e');
    }
    
    return null;
  }
  
  // Switch camera
  Future<void> switchCamera() async {
    if (_cameraController == null) return;
    
    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) return;
      
      // Dispose current controller
      await _cameraController!.dispose();
      
      // Get the other camera
      final currentCamera = _cameraController!.description;
      final newCamera = cameras.firstWhere(
        (camera) => camera.lensDirection != currentCamera.lensDirection,
        orElse: () => cameras.first,
      );
      
      // Initialize new controller
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _cameraController!.initialize();
      notifyListeners();
    } catch (e) {
      print('Error switching camera: $e');
    }
  }
  
  // Take a picture
  Future<String?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    
    try {
      // Take picture
      final XFile pictureFile = await _cameraController!.takePicture();
      
      // Create dedicated folder for recordings
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/PocketRecorder/Images');
      if (!(await recordingsDir.exists())) {
        await recordingsDir.create(recursive: true);
      }
      
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final fileName = 'image_${formatter.format(DateTime.now())}.jpg';
      final imagePath = '${recordingsDir.path}/$fileName';
      
      await pictureFile.saveTo(imagePath);
      return imagePath;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }
  
  // Dispose resources
  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }
}