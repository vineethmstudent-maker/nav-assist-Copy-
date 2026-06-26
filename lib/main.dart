import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'screens/home_screen.dart';
import 'screens/navigation_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/results_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Load saved API key from SharedPreferences into AppConfig
  final prefs = await SharedPreferences.getInstance();
  final savedKey = prefs.getString('gemini_api_key');
  if (savedKey != null && savedKey.isNotEmpty) {
    AppConfig.geminiApiKey = savedKey;
  }

  // Load saved thresholds
  AppConfig.criticalDistance = prefs.getDouble('critical_distance') ?? 40.0;
  AppConfig.dangerDistance   = prefs.getDouble('danger_distance')   ?? 80.0;
  AppConfig.frameIntervalMs  = prefs.getInt('frame_interval_ms')    ?? 500;

  runApp(const NavAssistApp());
}

class NavAssistApp extends StatelessWidget {
  const NavAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavAssist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        // Large text for accessibility
        textTheme: const TextTheme(
          bodyLarge:   TextStyle(fontSize: 18),
          bodyMedium:  TextStyle(fontSize: 16),
          titleLarge:  TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/':         (ctx) => const HomeScreen(),
        '/nav':      (ctx) => const NavigationScreen(),
        '/settings': (ctx) => const SettingsScreen(),
        '/results':  (ctx) => const ResultsScreen(),
      },
    );
  }
}

/// Request all required permissions at app start.
/// Called from HomeScreen on first launch.
Future<Map<Permission, PermissionStatus>> requestPermissions() async {
  final statuses = await [
    Permission.camera,
    Permission.storage,
    Permission.manageExternalStorage,
  ].request();
  return statuses;
}
