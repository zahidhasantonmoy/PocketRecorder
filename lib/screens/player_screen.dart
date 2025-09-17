import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../recorder_provider.dart';
import '../recording.dart';

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
                  Icons.audiotrack,
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
              _formatDate(widget.recording.date),
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
                  Text(_formatDuration(recorderProvider.currentPlaybackPosition)),
                  Text(_formatDuration(widget.recording.duration)),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).toInt());
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '$hours:$minutes:$secs';
    } else {
      return '$minutes:$secs';
    }
  }
}