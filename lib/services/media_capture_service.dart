import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pocket_recorder/services/encryption_service.dart';

class MediaCaptureService {
  static final MediaCaptureService _instance = MediaCaptureService._internal();
  factory MediaCaptureService() => _instance;
  MediaCaptureService._internal();

  // Encryption service
  final EncryptionService _encryptionService = EncryptionService();

  // Camera related variables
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  // Audio recording variables
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecordingAudio = false;

  // Initialize cameras
  Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  // Initialize audio recorder
  Future<void> initializeAudioRecorder() async {
    try {
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();
    } catch (e) {
      print('Error initializing audio recorder: $e');
    }
  }

  // Capture photo
  Future<String?> capturePhoto({CameraLensDirection lens = CameraLensDirection.back}) async {
    try {
      // Initialize camera if not already done
      if (_cameras == null) {
        await initializeCameras();
      }

      if (_cameras == null || _cameras!.isEmpty) {
        print('No cameras available');
        return null;
      }

      // Find the appropriate camera
      CameraDescription? camera;
      if (lens == CameraLensDirection.back) {
        camera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
      } else {
        camera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
      }

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Take the picture
      final XFile photo = await _cameraController!.takePicture();

      // Get the application documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String mediaDir = path.join(appDir.path, 'media');
      
      // Create media directory if it doesn't exist
      await Directory(mediaDir).create(recursive: true);
      
      // Generate a unique filename
      final String fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(mediaDir, fileName);
      
      // Move the file to our directory
      await File(photo.path).copy(filePath);
      
      // Encrypt the file
      final String? encryptedPath = await _encryptionService.encryptFile(filePath);
      
      // Dispose of the camera controller
      await _cameraController!.dispose();
      _cameraController = null;
      
      return encryptedPath ?? filePath;
    } catch (e) {
      print('Error capturing photo: $e');
      // Clean up camera controller if needed
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
      return null;
    }
  }

  // Start video recording
  Future<String?> startVideoRecording({CameraLensDirection lens = CameraLensDirection.back}) async {
    try {
      // Initialize camera if not already done
      if (_cameras == null) {
        await initializeCameras();
      }

      if (_cameras == null || _cameras!.isEmpty) {
        print('No cameras available');
        return null;
      }

      // Find the appropriate camera
      CameraDescription? camera;
      if (lens == CameraLensDirection.back) {
        camera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
      } else {
        camera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
      }

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      await _cameraController!.prepareForVideoRecording();

      // Get the application documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String mediaDir = path.join(appDir.path, 'media');
      
      // Create media directory if it doesn't exist
      await Directory(mediaDir).create(recursive: true);
      
      // Generate a unique filename
      final String fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String filePath = path.join(mediaDir, fileName);
      
      // Start recording
      await _cameraController!.startVideoRecording();
      
      return filePath;
    } catch (e) {
      print('Error starting video recording: $e');
      // Clean up camera controller if needed
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
      return null;
    }
  }

  // Stop video recording
  Future<String?> stopVideoRecording() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
        return null;
      }

      final XFile video = await _cameraController!.stopVideoRecording();
      
      // Get the application documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String mediaDir = path.join(appDir.path, 'media');
      
      // Create media directory if it doesn't exist
      await Directory(mediaDir).create(recursive: true);
      
      // Generate a unique filename
      final String fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String filePath = path.join(mediaDir, fileName);
      
      // Move the file to our directory
      await File(video.path).copy(filePath);
      
      // Encrypt the file
      final String? encryptedPath = await _encryptionService.encryptFile(filePath);
      
      // Dispose of the camera controller
      await _cameraController!.dispose();
      _cameraController = null;
      
      return encryptedPath ?? filePath;
    } catch (e) {
      print('Error stopping video recording: $e');
      // Clean up camera controller if needed
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
      return null;
    }
  }

  // Start audio recording
  Future<String?> startAudioRecording() async {
    try {
      if (_audioRecorder == null) {
        await initializeAudioRecorder();
      }

      if (_audioRecorder == null) {
        print('Audio recorder not available');
        return null;
      }

      // Get the application documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String mediaDir = path.join(appDir.path, 'media');
      
      // Create media directory if it doesn't exist
      await Directory(mediaDir).create(recursive: true);
      
      // Generate a unique filename
      final String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      final String filePath = path.join(mediaDir, fileName);
      
      // Start recording
      await _audioRecorder!.startRecorder(toFile: filePath);
      _isRecordingAudio = true;
      
      return filePath;
    } catch (e) {
      print('Error starting audio recording: $e');
      return null;
    }
  }

  // Stop audio recording
  Future<String?> stopAudioRecording() async {
    try {
      if (_audioRecorder == null || !_isRecordingAudio) {
        return null;
      }

      final String? result = await _audioRecorder!.stopRecorder();
      _isRecordingAudio = false;
      
      if (result != null) {
        // Encrypt the file
        final String? encryptedPath = await _encryptionService.encryptFile(result);
        return encryptedPath ?? result;
      }
      
      return result;
    } catch (e) {
      print('Error stopping audio recording: $e');
      return null;
    }
  }

  // Dispose of the service
  Future<void> dispose() async {
    // Dispose camera controller
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    // Close audio recorder
    if (_audioRecorder != null) {
      await _audioRecorder!.closeRecorder();
      _audioRecorder = null;
    }
  }
}