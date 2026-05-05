import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'services/notification_service.dart';
import 'database/database.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Wrap everything in try-catch to see errors
  try {
    WidgetsFlutterBinding.ensureInitialized();

    print('[MAIN] Starting app initialization...');

    // Load file .env
    try {
      await dotenv.load(fileName: ".env");
      print('[MAIN] .env file loaded successfully');
    } catch (e) {
      print('[MAIN] Warning: Could not load .env file: $e');
      // Continue anyway, .env might not be critical for web
    }

    // Initialize database with timeout
    try {
      print('[MAIN] Initializing database...');
      await DatabaseHelper.instance.database.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Database initialization timeout after 10 seconds');
        },
      );
      print('[MAIN] Database initialized successfully');
    } catch (e) {
      print('[MAIN] ERROR: Database initialization failed: $e');
      print('[MAIN] Continuing without database...');
      // Don't throw, let app continue to show error screen
    }

    // Inisialisasi notifikasi lokal (skip di web karena tidak support)
    if (!kIsWeb) {
      try {
        await NotificationService.instance.init();
        await NotificationService.instance.requestPermission();
        print('[MAIN] Notification service initialized');
      } catch (e) {
        print('[MAIN] Warning: Notification service failed: $e');
      }
    } else {
      print('[MAIN] Running on web platform - skipping notification service');
    }

    print('[MAIN] App initialization complete, starting app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('[MAIN] FATAL ERROR during initialization:');
    print(e);
    print(stackTrace);
    
    // Show error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Error Starting App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
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