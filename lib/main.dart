import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'recorder_provider.dart';
import 'screens/home_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/pattern_settings_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sensor_data_analyzer.dart';
import 'screens/pattern_training_screen.dart';
import 'services/background_pattern_service.dart';
import 'services/sos_service.dart';
import 'services/pattern_recording_service.dart';
import 'services/app_settings_service.dart';
import 'models/app_settings.dart';
import 'services/gesture_control_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start background pattern detection service
  await BackgroundPatternDetectionService().startBackgroundService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => RecorderProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => SOSService(),
        ),
        ChangeNotifierProvider(
          create: (context) => PatternRecordingService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketRecorder',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      routes: {
        '/pattern-training': (context) => const PatternTrainingScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GestureControlService _gestureService = GestureControlService();
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const VaultScreen(),
    const PatternSettingsScreen(),
    SettingsScreen(gestureService: GestureControlService()), // Pass gesture service
  ];

  @override
  void initState() {
    super.initState();
    // Start gesture control service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gestureService.startListening(context);
    });
  }

  @override
  void dispose() {
    _gestureService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock),
            label: 'Vault',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gesture),
            label: 'Patterns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      // Add debug menu button in top right corner for sensor analysis
      floatingActionButton: _currentIndex == 3 // Only show on settings screen
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SensorDataAnalyzer(),
                  ),
                );
              },
              child: const Icon(Icons.science),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}
