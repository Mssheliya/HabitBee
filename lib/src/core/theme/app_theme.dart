import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_bee/src/data/models/app_settings.dart';

/// Predefined seed color option for Material 3 dynamic themes
class AppThemeSeedOption {
  final String id;
  final String name;
  final Color seedColor;
  final AppThemeType? legacyType;

  const AppThemeSeedOption({
    required this.id,
    required this.name,
    required this.seedColor,
    this.legacyType,
  });
}

/// Metadata for DynamicSchemeVariant options
class ThemeVariantOption {
  final DynamicSchemeVariant variant;
  final String name;
  final String description;

  const ThemeVariantOption({
    required this.variant,
    required this.name,
    required this.description,
  });
}

class AppTheme {
  // 16 Curated Material 3 Seed Colors
  static const List<AppThemeSeedOption> seedOptions = [
    AppThemeSeedOption(
      id: 'amber',
      name: 'Honey Amber',
      seedColor: Color(0xFFFFB300),
      legacyType: AppThemeType.yellow,
    ),
    AppThemeSeedOption(
      id: 'blue',
      name: 'Ocean Blue',
      seedColor: Color(0xFF1E88E5),
      legacyType: AppThemeType.blue,
    ),
    AppThemeSeedOption(
      id: 'green',
      name: 'Forest Green',
      seedColor: Color(0xFF43A047),
      legacyType: AppThemeType.green,
    ),
    AppThemeSeedOption(
      id: 'purple',
      name: 'Royal Purple',
      seedColor: Color(0xFF8E24AA),
      legacyType: AppThemeType.purple,
    ),
    AppThemeSeedOption(
      id: 'pink',
      name: 'Rose Pink',
      seedColor: Color(0xFFD81B60),
      legacyType: AppThemeType.pink,
    ),
    AppThemeSeedOption(
      id: 'orange',
      name: 'Sunset Orange',
      seedColor: Color(0xFFFB8C00),
      legacyType: AppThemeType.orange,
    ),
    AppThemeSeedOption(
      id: 'teal',
      name: 'Teal Wave',
      seedColor: Color(0xFF00897B),
      legacyType: AppThemeType.teal,
    ),
    AppThemeSeedOption(
      id: 'red',
      name: 'Cherry Red',
      seedColor: Color(0xFFE53935),
      legacyType: AppThemeType.red,
    ),
    AppThemeSeedOption(
      id: 'indigo',
      name: 'Indigo Night',
      seedColor: Color(0xFF3949AB),
      legacyType: AppThemeType.indigo,
    ),
    AppThemeSeedOption(
      id: 'cyan',
      name: 'Sky Cyan',
      seedColor: Color(0xFF00ACC1),
    ),
    AppThemeSeedOption(
      id: 'deep_purple',
      name: 'Deep Lavender',
      seedColor: Color(0xFF5E35B1),
    ),
    AppThemeSeedOption(
      id: 'lime',
      name: 'Citrus Lime',
      seedColor: Color(0xFF7CB342),
    ),
    AppThemeSeedOption(
      id: 'coral',
      name: 'Coral Warm',
      seedColor: Color(0xFFF4511E),
    ),
    AppThemeSeedOption(
      id: 'brown',
      name: 'Mocha Brown',
      seedColor: Color(0xFF6D4C41),
    ),
    AppThemeSeedOption(
      id: 'blue_grey',
      name: 'Slate Grey',
      seedColor: Color(0xFF546E7A),
    ),
    AppThemeSeedOption(
      id: 'mint',
      name: 'Mint Breeze',
      seedColor: Color(0xFF008975),
    ),
  ];

  // 9 DynamicSchemeVariant Options
  static const List<ThemeVariantOption> variantOptions = [
    ThemeVariantOption(
      variant: DynamicSchemeVariant.tonalSpot,
      name: 'Tonal Spot',
      description: 'Default calm Material 3 pastel palette',
    ),
    ThemeVariantOption(
      variant: DynamicSchemeVariant.fidelity,
      name: 'Fidelity',
      description: 'Matches exact seed color faithfully',
    ),
    ThemeVariantOption(
      variant: DynamicSchemeVariant.monochrome,
      name: 'Monochrome',
      description: 'Minimalist grayscale tones',
    ),
    ThemeVariantOption(
      variant: DynamicSchemeVariant.neutral,
      name: 'Neutral',
      description: 'Subtle low-saturation palette',
    ),
    ThemeVariantOption(
      variant: DynamicSchemeVariant.vibrant,
      name: 'Vibrant',
      description: 'High energy saturated colors',
    ),
    ThemeVariantOption(
      variant: DynamicSchemeVariant.expressive,
      name: 'Expressive',
      description: 'Bold expressive tertiary accents',
    ),
    ThemeVariantOption(
      variant: DynamicSchemeVariant.content,
      name: 'Content',
      description: 'Matches color of focused media',
    ),
    ThemeVariantOption(
      variant: DynamicSchemeVariant.rainbow,
      name: 'Rainbow',
      description: 'Playful wide spectrum colors',
    ),
    ThemeVariantOption(
      variant: DynamicSchemeVariant.fruitSalad,
      name: 'Fruit Salad',
      description: 'Warm fruity harmonious tones',
    ),
  ];

  // Map for backward compatibility
  static final Map<AppThemeType, ThemeColors> themeColors = {
    for (final opt in seedOptions.where((o) => o.legacyType != null))
      opt.legacyType!: ThemeColors(
        primary: opt.seedColor,
        secondary: _darkenColor(opt.seedColor, 0.15),
        light: _lightenColor(opt.seedColor, 0.3),
        name: opt.name,
      ),
    AppThemeType.custom: ThemeColors(
      primary: const Color(0xFFFFB300),
      secondary: const Color(0xFFFFA000),
      light: const Color(0xFFFFECB3),
      name: 'Custom Theme',
    ),
  };

  // Default Colors for backward compatibility
  static const Color primaryYellow = Color(0xFFFFB300);
  static const Color darkYellow = Color(0xFFFFA000);
  static const Color lightYellow = Color(0xFFFFECB3);
  static const Color black = Color(0xFF141414);
  static const Color darkGrey = Color(0xFF222222);
  static const Color mediumGrey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F9FA);

  /// Color palette available for individual habits.
  /// Same colors as the app theme seed options, but the habit color is
  /// chosen independently per habit (not tied to the selected app theme).
  static List<Color> get habitColorOptions =>
      seedOptions.map((o) => o.seedColor).toList();

  /// Get seed color from settings
  static Color getSeedColor(AppSettings settings) {
    if (settings.selectedColorSeed != null) {
      return Color(settings.selectedColorSeed!);
    }
    if (settings.themeType == AppThemeType.custom &&
        settings.customPrimaryColor != null) {
      return Color(settings.customPrimaryColor!);
    }
    final option = seedOptions.firstWhere(
      (opt) => opt.legacyType == settings.themeType,
      orElse: () => seedOptions.first,
    );
    return option.seedColor;
  }

  /// Get DynamicSchemeVariant from settings index
  static DynamicSchemeVariant getDynamicSchemeVariant(AppSettings settings) {
    final idx = settings.dynamicSchemeVariantIndex;
    if (idx >= 0 && idx < DynamicSchemeVariant.values.length) {
      return DynamicSchemeVariant.values[idx];
    }
    return DynamicSchemeVariant.tonalSpot;
  }

  /// Generate ColorScheme from seed, brightness, and variant
  static ColorScheme generateColorScheme({
    required Color seedColor,
    required Brightness brightness,
    required DynamicSchemeVariant variant,
  }) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: variant,
    );
  }

  /// Create full ThemeData
  static ThemeData buildTheme({
    required AppSettings settings,
    required Brightness brightness,
  }) {
    return buildThemeFromSeed(
      seedColor: getSeedColor(settings),
      brightness: brightness,
      variant: getDynamicSchemeVariant(settings),
      fontScale: settings.fontScale,
    );
  }

  /// Create full ThemeData from an explicit seed color.
  ///
  /// Identical color logic to [buildTheme] — every sub-theme (switch,
  /// input decoration, text selection, dialogs, bottom sheets, …) derives
  /// from the generated scheme. Lets a screen adopt a habit's own color
  /// as its theme without changing any color logic.
  static ThemeData buildThemeFromSeed({
    required Color seedColor,
    required Brightness brightness,
    required DynamicSchemeVariant variant,
    double fontScale = 1.0,
  }) {
    final colorScheme = generateColorScheme(
      seedColor: seedColor,
      brightness: brightness,
      variant: variant,
    );
    final isDark = brightness == Brightness.dark;

    final textTheme = _getTextTheme(fontScale, brightness, colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? colorScheme.surface
          : colorScheme.surfaceContainerLowest,
      canvasColor: colorScheme.surface,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18 * fontScale,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // SegmentedButton
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14 * fontScale,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12 * fontScale,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12 * fontScale,
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outlineVariant;
        }),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _getTextTheme(
    double fontScale,
    Brightness brightness,
    ColorScheme colorScheme,
  ) {
    final primaryColor = colorScheme.onSurface;
    final secondaryColor = colorScheme.onSurfaceVariant;

    return GoogleFonts.poppinsTextTheme(
      brightness == Brightness.light
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32 * fontScale,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 24 * fontScale,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 20 * fontScale,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 18 * fontScale,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14 * fontScale,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 13 * fontScale,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.normal,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14 * fontScale,
        fontWeight: FontWeight.normal,
        color: primaryColor,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12 * fontScale,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14 * fontScale,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12 * fontScale,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
    );
  }

  // Helper to darken a color
  static Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  // Helper to lighten a color
  static Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  // Backward compatibility getters & methods
  static ThemeData getLightTheme(AppSettings settings) {
    return buildTheme(settings: settings, brightness: Brightness.light);
  }

  static ThemeData getDarkTheme(AppSettings settings) {
    return buildTheme(settings: settings, brightness: Brightness.dark);
  }

  static ThemeData get lightTheme =>
      getLightTheme(AppSettings.defaultSettings());
  static ThemeData get darkTheme => getDarkTheme(AppSettings.defaultSettings());

  static ThemeColors getThemeColors(
    AppThemeType type, {
    int? customPrimary,
    int? customSecondary,
  }) {
    if (type == AppThemeType.custom && customPrimary != null) {
      final primary = Color(customPrimary);
      final secondary = customSecondary != null
          ? Color(customSecondary)
          : _darkenColor(primary, 0.2);
      return ThemeColors(
        primary: primary,
        secondary: secondary,
        light: _lightenColor(primary, 0.3),
        name: 'Custom Theme',
      );
    }
    return themeColors[type] ?? themeColors[AppThemeType.yellow]!;
  }
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
