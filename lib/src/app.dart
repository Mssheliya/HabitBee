import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/data/services/storage_service.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/features/splash/presentation/splash_screen.dart';

class HabitBeeApp extends StatelessWidget {
  const HabitBeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        ProxyProvider<StorageService, HabitRepository>(
          update: (_, storageService, _) => HabitRepository(storageService),
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
