import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/notification_service.dart';
import 'database/database.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env
  await dotenv.load(fileName: ".env");

  // Initialize database
  await DatabaseHelper.instance.database;
  print('[DEBUG] Database initialized');

  // Inisialisasi notifikasi lokal
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lapang.in',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(), // Start with splash screen for auto-login check
    );
  }
}