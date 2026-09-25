// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      isDarkMode: _parseBool(fields[0], false),
      notificationsEnabled: _parseBool(fields[1], true),
      userName: fields[2]?.toString(),
      lastBackupDate: _parseDateTime(fields[3]),
      themeType: _parseThemeType(fields[4]),
      customPrimaryColor: _parseColorValue(fields[5]),
      customSecondaryColor: _parseColorValue(fields[6]),
      fontScale: _parseDouble(fields[7], 1.0),
      useSystemTheme: _parseBool(fields[8], false),
      dynamicSchemeVariantIndex: _parseColorValue(fields[9]) ?? 0,
      selectedColorSeed: _parseColorValue(fields[10]),
      hapticFeedbackEnabled: _parseBool(fields[11], true),
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.lastBackupDate)
      ..writeByte(4)
      ..write(obj.themeType)
      ..writeByte(5)
      ..write(obj.customPrimaryColor)
      ..writeByte(6)
      ..write(obj.customSecondaryColor)
      ..writeByte(7)
      ..write(obj.fontScale)
      ..writeByte(8)
      ..write(obj.useSystemTheme)
      ..writeByte(9)
      ..write(obj.dynamicSchemeVariantIndex)
      ..writeByte(10)
      ..write(obj.selectedColorSeed)
      ..writeByte(11)
      ..write(obj.hapticFeedbackEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppThemeTypeAdapter extends TypeAdapter<AppThemeType> {
  @override
  final int typeId = 10;

  @override
  AppThemeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppThemeType.yellow;
      case 1:
        return AppThemeType.blue;
      case 2:
        return AppThemeType.green;
      case 3:
        return AppThemeType.purple;
      case 4:
        return AppThemeType.pink;
      case 5:
        return AppThemeType.orange;
      case 6:
        return AppThemeType.teal;
      case 7:
        return AppThemeType.red;
      case 8:
        return AppThemeType.indigo;
      case 9:
        return AppThemeType.custom;
      default:
        return AppThemeType.yellow;
    }
  }

  @override
  void write(BinaryWriter writer, AppThemeType obj) {
    switch (obj) {
      case AppThemeType.yellow:
        writer.writeByte(0);
        break;
      case AppThemeType.blue:
        writer.writeByte(1);
        break;
      case AppThemeType.green:
        writer.writeByte(2);
        break;
      case AppThemeType.purple:
        writer.writeByte(3);
        break;
      case AppThemeType.pink:
        writer.writeByte(4);
        break;
      case AppThemeType.orange:
        writer.writeByte(5);
        break;
      case AppThemeType.teal:
        writer.writeByte(6);
        break;
      case AppThemeType.red:
        writer.writeByte(7);
        break;
      case AppThemeType.indigo:
        writer.writeByte(8);
        break;
      case AppThemeType.custom:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
