import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/data/models/app_settings.dart';
import 'package:habit_bee/src/data/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  AppSettings _settings = AppSettings.defaultSettings();
  bool _isLoaded = false;

  ThemeProvider(this._storageService) {
    _loadTheme();
  }

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;
  bool get isDarkMode => _settings.isDarkMode;
  AppThemeType get themeType => _settings.themeType;
  double get fontScale => _settings.fontScale;
  bool get useSystemTheme => _settings.useSystemTheme;
  bool get hapticFeedbackEnabled => _settings.hapticFeedbackEnabled;

  ThemeMode get themeMode {
    if (_settings.useSystemTheme) {
      return ThemeMode.system;
    }
    return _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  DynamicSchemeVariant get dynamicSchemeVariant =>
      AppTheme.getDynamicSchemeVariant(_settings);

  Color get selectedSeedColor => AppTheme.getSeedColor(_settings);

  ThemeData get theme => AppTheme.getLightTheme(_settings);
  ThemeData get darkTheme => AppTheme.getDarkTheme(_settings);

  ThemeData getCurrentTheme(Brightness platformBrightness) {
    if (_settings.useSystemTheme) {
      return platformBrightness == Brightness.dark
          ? AppTheme.getDarkTheme(_settings)
          : AppTheme.getLightTheme(_settings);
    }
    return _settings.isDarkMode
        ? AppTheme.getDarkTheme(_settings)
        : AppTheme.getLightTheme(_settings);
  }

  Future<void> _loadTheme() async {
    try {
      _settings = await _storageService.getSettings();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Trigger subtle haptic feedback if enabled in settings
  void triggerHaptic() {
    if (_settings.hapticFeedbackEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Trigger slightly stronger haptic feedback (for habit completion or major actions)
  void triggerMediumHaptic() {
    if (_settings.hapticFeedbackEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    triggerHaptic();
    try {
      switch (mode) {
        case ThemeMode.system:
          _settings = _settings.copyWith(useSystemTheme: true);
          break;
        case ThemeMode.dark:
          _settings = _settings.copyWith(useSystemTheme: false, isDarkMode: true);
          break;
        case ThemeMode.light:
          _settings = _settings.copyWith(useSystemTheme: false, isDarkMode: false);
          break;
      }
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme mode: $e');
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (_settings.isDarkMode == value && !_settings.useSystemTheme) return;
    triggerHaptic();
    try {
      _settings = _settings.copyWith(isDarkMode: value, useSystemTheme: false);
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting dark mode: $e');
    }
  }

  Future<void> setUseSystemTheme(bool value) async {
    if (_settings.useSystemTheme == value) return;
    triggerHaptic();
    try {
      _settings = _settings.copyWith(useSystemTheme: value);
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting system theme: $e');
    }
  }

  Future<void> setSelectedSeedColor(Color color, {AppThemeType? legacyType}) async {
    triggerHaptic();
    try {
      _settings = _settings.copyWith(
        selectedColorSeed: color.toARGB32(),
        themeType: legacyType ?? _settings.themeType,
        customPrimaryColor: color.toARGB32(),
      );
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting seed color: $e');
    }
  }

  Future<void> setDynamicSchemeVariant(DynamicSchemeVariant variant) async {
    if (_settings.dynamicSchemeVariantIndex == variant.index) return;
    triggerHaptic();
    try {
      _settings = _settings.copyWith(
        dynamicSchemeVariantIndex: variant.index,
      );
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting scheme variant: $e');
    }
  }

  Future<void> setHapticFeedbackEnabled(bool value) async {
    if (_settings.hapticFeedbackEnabled == value) return;
    if (value) {
      HapticFeedback.lightImpact();
    }
    try {
      _settings = _settings.copyWith(hapticFeedbackEnabled: value);
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting haptic feedback: $e');
    }
  }

  Future<void> toggleTheme() async {
    triggerHaptic();
    try {
      _settings = _settings.copyWith(
        isDarkMode: !_settings.isDarkMode,
        useSystemTheme: false,
      );
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }

  Future<void> setThemeType(AppThemeType type) async {
    triggerHaptic();
    try {
      final seedOpt = AppTheme.seedOptions.firstWhere(
        (o) => o.legacyType == type,
        orElse: () => AppTheme.seedOptions.first,
      );
      _settings = _settings.copyWith(
        themeType: type,
        selectedColorSeed: seedOpt.seedColor.toARGB32(),
      );
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme type: $e');
    }
  }

  Future<void> setCustomColors(Color primary, [Color? secondary]) async {
    triggerHaptic();
    try {
      _settings = _settings.copyWith(
        themeType: AppThemeType.custom,
        selectedColorSeed: primary.toARGB32(),
        customPrimaryColor: primary.toARGB32(),
        customSecondaryColor: secondary?.toARGB32(),
      );
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting custom colors: $e');
    }
  }

  Future<void> setFontScale(double scale) async {
    if (_settings.fontScale == scale) return;
    try {
      _settings = _settings.copyWith(fontScale: scale);
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting font scale: $e');
    }
  }

  ThemeColors get currentThemeColors {
    final seed = selectedSeedColor;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      dynamicSchemeVariant: dynamicSchemeVariant,
    );
    return ThemeColors(
      primary: colorScheme.primary,
      secondary: colorScheme.secondary,
      light: colorScheme.primaryContainer,
      name: _settings.themeType.name,
    );
  }

  void refresh() {
    notifyListeners();
  }
}
