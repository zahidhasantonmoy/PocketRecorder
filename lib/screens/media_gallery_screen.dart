import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  List<FileSystemEntity> _mediaFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMediaFiles();
  }

  Future<void> _loadMediaFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String mediaDir = path.join(appDir.path, 'media');
      
      final Directory dir = Directory(mediaDir);
      if (await dir.exists()) {
        final List<FileSystemEntity> files = await dir.list().toList();
        // Filter for image and video files
        final List<FileSystemEntity> mediaFiles = files.where((file) {
          final String extension = path.extension(file.path).toLowerCase();
          return extension == '.jpg' || extension == '.jpeg' || 
                 extension == '.png' || extension == '.mp4' || 
                 extension == '.mov' || extension == '.aac' || 
                 extension == '.mp3' || extension == '.wav';
        }).toList();
        
        // Sort by modification time (newest first)
        mediaFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        
        setState(() {
          _mediaFiles = mediaFiles;
          _isLoading = false;
        });
      } else {
        setState(() {
          _mediaFiles = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading media files: $e');
      setState(() {
        _mediaFiles = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Gallery'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMediaFiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mediaFiles.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No media files found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Capture media using gestures to see them here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _mediaFiles.length,
                  itemBuilder: (context, index) {
                    final FileSystemEntity file = _mediaFiles[index];
                    final String extension = path.extension(file.path).toLowerCase();
                    
                    return GestureDetector(
                      onTap: () => _viewMediaFile(file.path),
                      child: Card(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _isImage(extension)
                              ? _buildImageThumbnail(file.path)
                              : _buildVideoThumbnail(file.path),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  bool _isImage(String extension) {
    return extension == '.jpg' || extension == '.jpeg' || extension == '.png';
  }

  bool _isVideo(String extension) {
    return extension == '.mp4' || extension == '.mov';
  }

  bool _isAudio(String extension) {
    return extension == '.aac' || extension == '.mp3' || extension == '.wav';
  }

  Widget _buildImageThumbnail(String filePath) {
    return Image.file(
      File(filePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildVideoThumbnail(String filePath) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          color: Colors.black12,
          child: const Icon(
            Icons.video_library,
            size: 40,
            color: Colors.grey,
          ),
        ),
        const Icon(
          Icons.play_circle_fill,
          size: 30,
          color: Colors.white70,
        ),
      ],
    );
  }

  void _viewMediaFile(String filePath) {
    final String extension = path.extension(filePath).toLowerCase();
    
    if (_isImage(extension)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerScreen(imagePath: filePath),
        ),
      );
    } else if (_isVideo(extension)) {
      // For now, just show a dialog
      _showMediaInfoDialog(filePath, 'Video');
    } else if (_isAudio(extension)) {
      // For now, just show a dialog
      _showMediaInfoDialog(filePath, 'Audio');
    }
  }

  void _showMediaInfoDialog(String filePath, String type) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$type File'),
          content: Text('File: ${path.basename(filePath)}\n\nLocation: $filePath'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String imagePath;

  const ImageViewerScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(path.basename(imagePath)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(imagePath),
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 80,
                  color: Colors.white70,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}