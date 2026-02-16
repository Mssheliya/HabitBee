import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'app_settings.g.dart';

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
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: json['isDarkMode'] ?? false,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      userName: json['userName'],
      lastBackupDate: json['lastBackupDate'] != null
          ? DateTime.parse(json['lastBackupDate'])
          : null,
      themeType: AppThemeType.values[json['themeType'] ?? 0],
      customPrimaryColor: json['customPrimaryColor'],
      customSecondaryColor: json['customSecondaryColor'],
      fontScale: json['fontScale']?.toDouble() ?? 1.0,
      useSystemTheme: json['useSystemTheme'] ?? false,
    );
  }
}
