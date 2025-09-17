import 'package:flutter/material.dart';
import 'package:pocket_recorder/screens/home_screen.dart';

void main() {
  runApp(const PocketRecorderApp());
}

class PocketRecorderApp extends StatelessWidget {
  const PocketRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketRecorder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
