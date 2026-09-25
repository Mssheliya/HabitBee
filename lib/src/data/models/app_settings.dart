import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'app_settings.g.dart';

/// Tolerantly parses a bool stored as bool, String ("true"/"false") or num (1/0).
bool _parseBool(dynamic value, bool fallback) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true' ? true : (value.toLowerCase() == 'false' ? false : fallback);
  if (value is num) return value != 0;
  return fallback;
}

/// Tolerantly parses a DateTime stored as DateTime or ISO String.
DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Tolerantly parses a num value stored as num or String.
double _parseDouble(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Tolerantly parses a color value stored as int (new) or hex String (legacy data).
int? _parseColorValue(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    var s = value.replaceAll('#', '').replaceAll(RegExp('0[xX]'), '');
    if (s.length == 6) s = 'FF$s';
    return int.tryParse(s, radix: 16);
  }
  return null;
}

// Predefined themes
@HiveType(typeId: 10)
enum AppThemeType {
  @HiveField(0)
  yellow,
  @HiveField(1)
  blue,
  @HiveField(2)
  green,
  @HiveField(3)
  purple,
  @HiveField(4)
  pink,
  @HiveField(5)
  orange,
  @HiveField(6)
  teal,
  @HiveField(7)
  red,
  @HiveField(8)
  indigo,
  @HiveField(9)
  custom,
}

/// Tolerantly parses theme type stored as AppThemeType, int index, or String name.
AppThemeType _parseThemeType(dynamic value) {
  if (value is AppThemeType) return value;
  if (value is int && value >= 0 && value < AppThemeType.values.length) {
    return AppThemeType.values[value];
  }
  if (value is String) {
    return AppThemeType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => AppThemeType.yellow,
    );
  }
  return AppThemeType.yellow;
}

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  bool notificationsEnabled;

  @HiveField(2)
  String? userName;

  @HiveField(3)
  DateTime? lastBackupDate;

  @HiveField(4)
  AppThemeType themeType;

  @HiveField(5)
  int? customPrimaryColor;

  @HiveField(6)
  int? customSecondaryColor;

  @HiveField(7)
  double fontScale;

  @HiveField(8)
  bool useSystemTheme;

  @HiveField(9)
  int dynamicSchemeVariantIndex;

  @HiveField(10)
  int? selectedColorSeed;

  @HiveField(11)
  bool hapticFeedbackEnabled;

  AppSettings({
    this.isDarkMode = false,
    this.notificationsEnabled = true,
    this.userName,
    this.lastBackupDate,
    this.themeType = AppThemeType.yellow,
    this.customPrimaryColor,
    this.customSecondaryColor,
    this.fontScale = 1.0,
    this.useSystemTheme = false,
    this.dynamicSchemeVariantIndex = 0,
    this.selectedColorSeed,
    this.hapticFeedbackEnabled = true,
  });

  factory AppSettings.defaultSettings() {
    return AppSettings(
      isDarkMode: false,
      notificationsEnabled: true,
      userName: null,
      lastBackupDate: null,
      themeType: AppThemeType.yellow,
      customPrimaryColor: null,
      customSecondaryColor: null,
      fontScale: 1.0,
      useSystemTheme: false,
      dynamicSchemeVariantIndex: 0,
      selectedColorSeed: const Color(0xFFFFB300).toARGB32(),
      hapticFeedbackEnabled: true,
    );
  }

  AppSettings copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    String? userName,
    DateTime? lastBackupDate,
    AppThemeType? themeType,
    int? customPrimaryColor,
    int? customSecondaryColor,
    double? fontScale,
    bool? useSystemTheme,
    int? dynamicSchemeVariantIndex,
    int? selectedColorSeed,
    bool? hapticFeedbackEnabled,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      userName: userName ?? this.userName,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      themeType: themeType ?? this.themeType,
      customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
      customSecondaryColor: customSecondaryColor ?? this.customSecondaryColor,
      fontScale: fontScale ?? this.fontScale,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      dynamicSchemeVariantIndex: dynamicSchemeVariantIndex ?? this.dynamicSchemeVariantIndex,
      selectedColorSeed: selectedColorSeed ?? this.selectedColorSeed,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'notificationsEnabled': notificationsEnabled,
      'userName': userName,
      'lastBackupDate': lastBackupDate?.toIso8601String(),
      'themeType': themeType.index,
      'customPrimaryColor': customPrimaryColor,
      'customSecondaryColor': customSecondaryColor,
      'fontScale': fontScale,
      'useSystemTheme': useSystemTheme,
      'dynamicSchemeVariantIndex': dynamicSchemeVariantIndex,
      'selectedColorSeed': selectedColorSeed,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: _parseBool(json['isDarkMode'], false),
      notificationsEnabled: _parseBool(json['notificationsEnabled'], true),
      userName: json['userName']?.toString(),
      lastBackupDate: _parseDateTime(json['lastBackupDate']),
      themeType: _parseThemeType(json['themeType']),
      customPrimaryColor: _parseColorValue(json['customPrimaryColor']),
      customSecondaryColor: _parseColorValue(json['customSecondaryColor']),
      fontScale: _parseDouble(json['fontScale'], 1.0),
      useSystemTheme: _parseBool(json['useSystemTheme'], false),
      dynamicSchemeVariantIndex: _parseColorValue(json['dynamicSchemeVariantIndex']) ?? 0,
      selectedColorSeed: _parseColorValue(json['selectedColorSeed']),
      hapticFeedbackEnabled: _parseBool(json['hapticFeedbackEnabled'], true),
    );
  }
}
