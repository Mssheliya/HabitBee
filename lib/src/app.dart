import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/data/services/storage_service.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/features/splash/presentation/splash_screen.dart';

class HabitBeeApp extends StatelessWidget {
  const HabitBeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set custom error builder - uses default yellow since theme may not be available
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: const Color(0xFFFFC107),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exception.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ),
        ),
      );
    };

    return MultiProvider(
      providers: [
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        ProxyProvider<StorageService, HabitRepository>(
          update: (_, storageService, __) => HabitRepository(storageService),
        ),
        ChangeNotifierProxyProvider<StorageService, ThemeProvider>(
          create: (context) => ThemeProvider(
            Provider.of<StorageService>(context, listen: false),
          ),
          update: (_, storageService, previous) {
            // Return the existing instance, don't create a new one
            if (previous != null) {
              return previous;
            }
            return ThemeProvider(storageService);
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'HabitBee',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
