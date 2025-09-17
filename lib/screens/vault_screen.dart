import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../recorder_provider.dart';
import '../models/recording.dart';
import '../widgets/recording_list_item.dart';
import '../utils/formatting_utils.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recorderProvider = Provider.of<RecorderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Vault'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Audio'),
            Tab(text: 'Video'),
            Tab(text: 'Images'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              // Lock vault
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Audio recordings
          _RecordingsList(
            recordings: recorderProvider.recordings
                .where((r) => _isAudioFile(r.path))
                .toList(),
          ),
          
          // Video recordings
          _RecordingsList(
            recordings: recorderProvider.recordings
                .where((r) => _isVideoFile(r.path))
                .toList(),
          ),
          
          // Images
          _RecordingsList(
            recordings: recorderProvider.recordings
                .where((r) => _isImageFile(r.path))
                .toList(),
          ),
        ],
      ),
    );
  }
  
  bool _isAudioFile(String path) {
    return path.toLowerCase().endsWith('.mp3') || 
           path.toLowerCase().endsWith('.m4a') || 
           path.toLowerCase().endsWith('.wav');
  }
  
  bool _isVideoFile(String path) {
    return path.toLowerCase().endsWith('.mp4') || 
           path.toLowerCase().endsWith('.mov') || 
           path.toLowerCase().endsWith('.avi');
  }
  
  bool _isImageFile(String path) {
    return path.toLowerCase().endsWith('.jpg') || 
           path.toLowerCase().endsWith('.jpeg') || 
           path.toLowerCase().endsWith('.png');
  }
}

class _RecordingsList extends StatelessWidget {
  final List<Recording> recordings;

  const _RecordingsList({required this.recordings});

  @override
  Widget build(BuildContext context) {
    if (recordings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No files in this category',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Files will appear here once added',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recordings.length,
      itemBuilder: (context, index) {
        return RecordingListItem(recording: recordings[index]);
      },
    );
  }
}