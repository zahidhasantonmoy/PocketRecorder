import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pattern_recording_service.dart';
import '../services/pattern_storage_service.dart';
import '../models/pattern_signature.dart';

class PatternRecordingScreen extends StatefulWidget {
  const PatternRecordingScreen({super.key});

  @override
  State<PatternRecordingScreen> createState() => _PatternRecordingScreenState();
}

class _PatternRecordingScreenState extends State<PatternRecordingScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedFunction = 'custom';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patternService = Provider.of<PatternRecordingService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Pattern'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!patternService.isRecording) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pattern Name',
                  hintText: 'Enter a name for your pattern',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Assign to function:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedFunction,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'audio',
                    child: Text('Audio Recording'),
                  ),
                  DropdownMenuItem(
                    value: 'video',
                    child: Text('Video Recording'),
                  ),
                  DropdownMenuItem(
                    value: 'image',
                    child: Text('Image Capture'),
                  ),
                  DropdownMenuItem(
                    value: 'sos',
                    child: Text('SOS Alert'),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text('Custom (No assigned function)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFunction = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 30),
            ],
            
            Center(
              child: Column(
                children: [
                  // Recording indicator
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: patternService.isRecording 
                          ? Colors.red.withOpacity(0.2) 
                          : Colors.grey.withOpacity(0.2),
                      border: Border.all(
                        color: patternService.isRecording 
                            ? Colors.red 
                            : Colors.grey,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        patternService.isRecording 
                            ? Icons.stop 
                            : Icons.fiber_manual_record,
                        size: 60,
                        color: patternService.isRecording 
                            ? Colors.red 
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Status text
                  Text(
                    patternService.isRecording 
                        ? 'Recording... Tap on the back of your phone' 
                        : 'Ready to record pattern',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  
                  // Tap visualization
                  if (patternService.isRecording) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${patternService.tapTimestamps.length} taps recorded',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Visualize taps as circles
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: patternService.tapTimestamps.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.deepPurple,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  
                  // Action button
                  ElevatedButton(
                    onPressed: patternService.isRecording
                        ? () async {
                            // Stop recording
                            final pattern = patternService.stopRecording(
                              name: _nameController.text.isEmpty 
                                  ? 'Custom Pattern' 
                                  : _nameController.text,
                              function: _selectedFunction,
                            );
                            
                            if (pattern != null) {
                              // Save pattern
                              setState(() {
                                _isSaving = true;
                              });
                              
                              await PatternStorageService().savePattern(pattern);
                              
                              setState(() {
                                _isSaving = false;
                              });
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pattern saved successfully!'),
                                  ),
                                );
                                
                                // Navigate back
                                Navigator.of(context).pop();
                              }
                            }
                          }
                        : () {
                            // Start recording
                            patternService.startRecording();
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            patternService.isRecording 
                                ? 'Stop & Save Pattern' 
                                : 'Start Recording Pattern',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  
                  if (patternService.isRecording) ...[
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () {
                        // Cancel recording
                        patternService.cancelRecording();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Pattern training tips
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pattern Training Tips:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text('• Tap firmly but not too hard on the back of your phone'),
                    Text('• Keep consistent timing between taps'),
                    Text('• Practice your pattern a few times before recording'),
                    Text('• 2-5 taps work best for reliable detection'),
                    Text('• The app detects ~60% pattern similarity for activation'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to record a pattern:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text('1. Enter a name for your pattern'),
                    Text('2. Select a function to assign (optional)'),
                    Text('3. Tap "Start Recording Pattern"'),
                    Text('4. Tap on the back of your phone in your desired pattern'),
                    Text('5. Tap "Stop & Save Pattern" when done'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}