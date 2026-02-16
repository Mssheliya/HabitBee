import 'dart:io';
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

  ThemeMode get themeMode {
    if (_settings.useSystemTheme) {
      return ThemeMode.system;
    }
    return _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

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

  Future<void> toggleTheme() async {
    try {
      _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (_settings.isDarkMode == value) return;
    try {
      _settings = _settings.copyWith(isDarkMode: value);
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme: $e');
    }
  }

  Future<void> setUseSystemTheme(bool value) async {
    if (_settings.useSystemTheme == value) return;
    try {
      _settings = _settings.copyWith(useSystemTheme: value);
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting system theme: $e');
    }
  }

  Future<void> setThemeType(AppThemeType type) async {
    if (_settings.themeType == type) return;
    try {
      _settings = _settings.copyWith(themeType: type);
      await _storageService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme type: $e');
    }
  }

  Future<void> setCustomColors(Color primary, [Color? secondary]) async {
    try {
      _settings = _settings.copyWith(
        themeType: AppThemeType.custom,
        customPrimaryColor: primary.value,
        customSecondaryColor: secondary?.value,
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
    return AppTheme.getThemeColors(
      _settings.themeType,
      customPrimary: _settings.customPrimaryColor,
      customSecondary: _settings.customSecondaryColor,
    );
  }

  void refresh() {
    notifyListeners();
  }
}
