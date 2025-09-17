import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../recorder_provider.dart';
import '../recording.dart';
import '../screens/player_screen.dart';
import '../utils/formatting_utils.dart';

class RecordingListItem extends StatelessWidget {
  final Recording recording;

  const RecordingListItem({super.key, required this.recording});

  @override
  Widget build(BuildContext context) {
    final recorderProvider = Provider.of<RecorderProvider>(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          recording.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(FormattingUtils.formatDate(recording.date)),
            const SizedBox(height: 4),
            Text(FormattingUtils.formatDuration(recording.duration)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'play':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(recording: recording),
                  ),
                );
                break;
              case 'rename':
                _showRenameDialog(context, recorderProvider, recording);
                break;
              case 'share':
                _shareRecording(context, recording);
                break;
              case 'delete':
                _showDeleteConfirmation(context, recorderProvider, recording);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: ListTile(
                leading: Icon(Icons.play_arrow),
                title: Text('Play'),
              ),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Rename'),
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(recording: recording),
            ),
          );
        },
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, RecorderProvider provider, Recording recording) {
    final controller = TextEditingController(text: recording.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Recording'),
          content: TextField(
            controller: controller,
            autofocus: true,
            onSubmitted: (_) {
              Navigator.pop(context);
              provider.renameRecording(recording.id, controller.text);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                provider.renameRecording(recording.id, controller.text);
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _shareRecording(BuildContext context, Recording recording) {
    Share.shareXFiles([XFile(recording.path)]);
  }

  void _showDeleteConfirmation(
      BuildContext context, RecorderProvider provider, Recording recording) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Recording'),
          content: Text(
              'Are you sure you want to delete "${recording.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                provider.deleteRecording(recording.id);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}