import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_bee/src/app.dart';
import 'package:habit_bee/src/data/services/storage_service.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/core/services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait for better performance
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI for smoother experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runZonedGuarded(() async {
    try {
      debugPrint('Starting app initialization...');
      
      // Initialize storage first (required)
      debugPrint('Initializing StorageService...');
      await StorageService().initialize();
      debugPrint('StorageService initialized successfully');
      
      // Run app immediately for faster startup
      debugPrint('Running app...');
      runApp(const HabitBeeApp());
      
      // Initialize notifications in background (non-blocking)
      _initializeNotificationsInBackground();
      
    } catch (e, stackTrace) {
      debugPrint('Fatal error during initialization: $e');
      debugPrint('StackTrace: $stackTrace');
      runApp(ErrorApp(error: e.toString()));
    }
  }, (error, stackTrace) {
    debugPrint('Uncaught error: $error');
    debugPrint('StackTrace: $stackTrace');
  });
}

// Initialize notifications in background for faster app startup
void _initializeNotificationsInBackground() async {
  try {
    debugPrint('Initializing NotificationService in background...');
    await NotificationService().initialize();
    debugPrint('NotificationService initialized successfully');
    
    // Request notification permissions
    debugPrint('Requesting notification permissions...');
    await NotificationService().requestPermissions();
    
    // Reschedule all habit notifications
    debugPrint('Rescheduling habit notifications...');
    final storageService = StorageService();
    await storageService.initialize();
    final habitRepository = HabitRepository(storageService);
    await habitRepository.rescheduleAllNotifications();
    debugPrint('Habit notifications rescheduled successfully');
  } catch (e) {
    debugPrint('NotificationService initialization failed (non-critical): $e');
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC107),
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFFFC107),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
