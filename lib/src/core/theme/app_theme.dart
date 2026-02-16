import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_bee/src/data/models/app_settings.dart';

class AppTheme {
  // Predefined Theme Colors
  static final Map<AppThemeType, ThemeColors> themeColors = {
    AppThemeType.yellow: ThemeColors(
      primary: const Color(0xFFFFC107),
      secondary: const Color(0xFFFFA000),
      light: const Color(0xFFFFECB3),
      name: 'Honey Bee',
    ),
    AppThemeType.blue: ThemeColors(
      primary: const Color(0xFF2196F3),
      secondary: const Color(0xFF1976D2),
      light: const Color(0xFFBBDEFB),
      name: 'Ocean Blue',
    ),
    AppThemeType.green: ThemeColors(
      primary: const Color(0xFF4CAF50),
      secondary: const Color(0xFF388E3C),
      light: const Color(0xFFC8E6C9),
      name: 'Forest Green',
    ),
    AppThemeType.purple: ThemeColors(
      primary: const Color(0xFF9C27B0),
      secondary: const Color(0xFF7B1FA2),
      light: const Color(0xFFE1BEE7),
      name: 'Royal Purple',
    ),
    AppThemeType.pink: ThemeColors(
      primary: const Color(0xFFE91E63),
      secondary: const Color(0xFFC2185B),
      light: const Color(0xFFF8BBD0),
      name: 'Rose Pink',
    ),
    AppThemeType.orange: ThemeColors(
      primary: const Color(0xFFFF9800),
      secondary: const Color(0xFFF57C00),
      light: const Color(0xFFFFE0B2),
      name: 'Sunset Orange',
    ),
    AppThemeType.teal: ThemeColors(
      primary: const Color(0xFF009688),
      secondary: const Color(0xFF00796B),
      light: const Color(0xFFB2DFDB),
      name: 'Teal Wave',
    ),
    AppThemeType.red: ThemeColors(
      primary: const Color(0xFFF44336),
      secondary: const Color(0xFFD32F2F),
      light: const Color(0xFFFFCDD2),
      name: 'Cherry Red',
    ),
    AppThemeType.indigo: ThemeColors(
      primary: const Color(0xFF3F51B5),
      secondary: const Color(0xFF303F9F),
      light: const Color(0xFFC5CAE9),
      name: 'Indigo Night',
    ),
    AppThemeType.custom: ThemeColors(
      primary: const Color(0xFFFFC107),
      secondary: const Color(0xFFFFA000),
      light: const Color(0xFFFFECB3),
      name: 'Custom Theme',
    ),
  };

  // Default colors for backward compatibility
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color darkYellow = Color(0xFFFFA000);
  static const Color lightYellow = Color(0xFFFFECB3);
  static const Color black = Color(0xFF1A1A1A);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color mediumGrey = Color(0xFF6B6B6B);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F5F5);

  // Soft Pastel Colors for Habits
  static const List<Color> habitColors = [
    Color(0xFFFFB7B2), // Soft Red
    Color(0xFFFFDAC1), // Peach
    Color(0xFFE2F0CB), // Soft Green
    Color(0xFFB5EAD7), // Mint
    Color(0xFFC7CEEA), // Soft Purple
    Color(0xFFF8B195), // Coral
    Color(0xFFF67280), // Pink
    Color(0xFFC06C84), // Mauve
    Color(0xFF6C5B7B), // Deep Purple
    Color(0xFF355C7D), // Navy Blue
  ];

  // Get theme colors based on settings
  static ThemeColors getThemeColors(AppThemeType type, {int? customPrimary, int? customSecondary}) {
    if (type == AppThemeType.custom && customPrimary != null) {
      final primary = Color(customPrimary);
      final secondary = customSecondary != null ? Color(customSecondary) : _darkenColor(primary, 0.2);
      return ThemeColors(
        primary: primary,
        secondary: secondary,
        light: _lightenColor(primary, 0.3),
        name: 'Custom Theme',
      );
    }
    return themeColors[type] ?? themeColors[AppThemeType.yellow]!;
  }

  // Helper to darken a color
  static Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  // Helper to lighten a color
  static Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static ThemeData getLightTheme(AppSettings settings) {
    final colors = getThemeColors(
      settings.themeType,
      customPrimary: settings.customPrimaryColor,
      customSecondary: settings.customSecondaryColor,
    );
    final fontScale = settings.fontScale;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: Brightness.light,
        primary: colors.primary,
        onPrimary: black,
        secondary: colors.secondary,
        onSecondary: white,
        surface: white,
        onSurface: black,
        surfaceContainerHighest: offWhite,
        onSurfaceVariant: mediumGrey,
        outline: lightGrey,
        shadow: black.withOpacity(0.1),
      ),
      scaffoldBackgroundColor: offWhite,
      textTheme: _getTextTheme(fontScale, Brightness.light),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colors.primary,
        foregroundColor: black,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20 * fontScale,
          fontWeight: FontWeight.w600,
          color: black,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: colors.primary,
          foregroundColor: black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: black,
          side: BorderSide(color: colors.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.secondary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14 * fontScale,
          color: mediumGrey,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: black,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: colors.primary,
        unselectedItemColor: mediumGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: lightGrey,
        thickness: 1,
      ),
    );
  }

  static ThemeData getDarkTheme(AppSettings settings) {
    final colors = getThemeColors(
      settings.themeType,
      customPrimary: settings.customPrimaryColor,
      customSecondary: settings.customSecondaryColor,
    );
    final fontScale = settings.fontScale;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: Brightness.dark,
        primary: colors.primary,
        onPrimary: black,
        secondary: colors.secondary,
        onSecondary: white,
        surface: darkGrey,
        onSurface: white,
        surfaceContainerHighest: black,
        onSurfaceVariant: lightGrey,
        outline: mediumGrey,
        shadow: black.withOpacity(0.3),
      ),
      scaffoldBackgroundColor: black,
      textTheme: _getTextTheme(fontScale, Brightness.dark),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkGrey,
        foregroundColor: white,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20 * fontScale,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: darkGrey,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: colors.primary,
          foregroundColor: black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: white,
          side: BorderSide(color: colors.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14 * fontScale,
          color: lightGrey,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: black,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkGrey,
        selectedItemColor: colors.primary,
        unselectedItemColor: lightGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: mediumGrey,
        thickness: 1,
      ),
    );
  }

  static TextTheme _getTextTheme(double fontScale, Brightness brightness) {
    final color = brightness == Brightness.light ? black : white;
    final secondaryColor = brightness == Brightness.light ? mediumGrey : lightGrey;

    return GoogleFonts.poppinsTextTheme(
      brightness == Brightness.light ? ThemeData.light().textTheme : ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32 * fontScale,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 24 * fontScale,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 20 * fontScale,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 18 * fontScale,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14 * fontScale,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.normal,
        color: color,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14 * fontScale,
        fontWeight: FontWeight.normal,
        color: color,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12 * fontScale,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14 * fontScale,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12 * fontScale,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  // Legacy getters for backward compatibility
  static ThemeData get lightTheme => getLightTheme(AppSettings.defaultSettings());
  static ThemeData get darkTheme => getDarkTheme(AppSettings.defaultSettings());
}

class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color light;
  final String name;

  ThemeColors({
    required this.primary,
    required this.secondary,
    required this.light,
    required this.name,
  });
}
