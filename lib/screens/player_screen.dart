import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../recorder_provider.dart';
import '../models/recording.dart';
import '../utils/formatting_utils.dart';

class PlayerScreen extends StatefulWidget {
  final Recording recording;

  const PlayerScreen({super.key, required this.recording});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final recorderProvider = Provider.of<RecorderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recording.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareRecording(context, widget.recording),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album art placeholder
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  _getFileIcon(widget.recording.path),
                  size: 100,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Recording name
            Text(
              widget.recording.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Recording date
            Text(
              FormattingUtils.formatDateTime(widget.recording.date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 30),
            // Progress slider
            Slider(
              value: recorderProvider.currentPlaybackPosition,
              min: 0.0,
              max: widget.recording.duration,
              onChanged: (value) {
                recorderProvider.seekPlayback(value);
              },
            ),
            // Time indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(FormattingUtils.formatDuration(recorderProvider.currentPlaybackPosition)),
                  Text(FormattingUtils.formatDuration(widget.recording.duration)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Play/Pause button
                FloatingActionButton(
                  onPressed: () {
                    if (recorderProvider.isPlaying && 
                        recorderProvider.currentPlayingPath == widget.recording.path) {
                      recorderProvider.pausePlayback();
                    } else {
                      recorderProvider.startPlayback(widget.recording.path);
                    }
                  },
                  child: Icon(
                    recorderProvider.isPlaying && 
                            recorderProvider.currentPlayingPath == widget.recording.path
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),
                // Stop button
                FloatingActionButton(
                  onPressed: () {
                    recorderProvider.stopPlayback();
                  },
                  child: const Icon(
                    Icons.stop,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getFileIcon(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp3':
      case 'm4a':
      case 'wav':
        return Icons.audiotrack;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.photo;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  void _shareRecording(BuildContext context, Recording recording) async {
    try {
      final file = XFile(recording.path);
      await Share.shareXFiles(
        [file],
        subject: 'Recording from PocketRecorder',
        text: 'Check out this recording I captured with PocketRecorder!',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}