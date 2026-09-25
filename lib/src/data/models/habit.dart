import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';

part 'habit.g.dart';

// Tolerant parsers for legacy stored values (String/num instead of bool/int/DateTime)
bool _hbBool(dynamic v, bool fallback) {
  if (v is bool) return v;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
  }
  if (v is num) return v != 0;
  return fallback;
}

int _hbInt(dynamic v, int fallback) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

DateTime _hbDate(dynamic v, DateTime fallback) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v) ?? fallback;
  return fallback;
}

DateTime? _hbDateOrNull(dynamic v) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  int colorIndex;

  @HiveField(4)
  String iconName;

  @HiveField(5)
  bool reminderEnabled;

  @HiveField(6)
  DateTime? reminderTime;

  @HiveField(7)
  List<bool> repeatDays;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  bool isArchived;

  @HiveField(10)
  int notificationId;

  @HiveField(11)
  int frequencyPerDay;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.colorIndex,
    required this.iconName,
    this.reminderEnabled = false,
    this.reminderTime,
    required this.repeatDays,
    required this.createdAt,
    this.isArchived = false,
    this.notificationId = 0,
    this.frequencyPerDay = 1,
  });

  factory Habit.create({
    required String name,
    required String category,
    required int colorIndex,
    required String iconName,
    bool reminderEnabled = false,
    DateTime? reminderTime,
    List<bool>? repeatDays,
    int frequencyPerDay = 1,
  }) {
    return Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      colorIndex: colorIndex,
      iconName: iconName,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
      repeatDays: repeatDays ?? List.filled(7, true),
      createdAt: DateTime.now(),
      isArchived: false,
      // Keep well below 2^31-1 so per-day reminder IDs (base + 0..6)
      // never overflow the 32-bit notification ID space on Android.
      notificationId: DateTime.now().millisecondsSinceEpoch % 2000000000,
      frequencyPerDay: frequencyPerDay,
    );
  }

  Color get color {
    final colors = AppTheme.habitColorOptions;
    return colors[colorIndex % colors.length];
  }

  /// Readable color for content drawn on top of [color].
  Color get onColor =>
      color.computeLuminance() > 0.45 ? const Color(0xFF1B1B1F) : Colors.white;

  /// Deeper, muted variant of [color] (towards black) — used for icon circles
  /// and completion circle fills so the vibrant accent stays on the icon/text.
  Color get mutedColor => Color.lerp(color, Colors.black, 0.45)!;

  // Cached Material 3 schemes generated from this habit's own selected color.
  ColorScheme? _schemeLight;
  ColorScheme? _schemeDark;

  /// Material 3 color scheme generated from THIS habit's selected color.
  /// The habit card derives every color from this scheme (calendar-style
  /// card surface, add-button-style container and its on-color).
  ColorScheme scheme(Brightness brightness) => brightness == Brightness.dark
      ? (_schemeDark ??= ColorScheme.fromSeed(
          seedColor: color, brightness: Brightness.dark))
      : (_schemeLight ??= ColorScheme.fromSeed(
          seedColor: color, brightness: Brightness.light));

  /// Habit-tinted card background, same logic as the theme's card color
  /// (used by the progress-page calendar / settings cards).
  Color cardBackground(Brightness brightness) =>
      brightness == Brightness.dark
          ? scheme(brightness).surfaceContainerLow
          : scheme(brightness).surfaceContainerHighest.withValues(alpha: 0.4);

  IconData get icon {
    final iconMap = {
      'fitness_center': Icons.fitness_center,
      'directions_run': Icons.directions_run,
      'self_improvement': Icons.self_improvement,
      'menu_book': Icons.menu_book,
      'water_drop': Icons.water_drop,
      'bedtime': Icons.bedtime,
      'restaurant': Icons.restaurant,
      'savings': Icons.savings,
      'work': Icons.work,
      'palette': Icons.palette,
      'music_note': Icons.music_note,
      'code': Icons.code,
      'nature': Icons.nature,
      'chat': Icons.chat,
      'local_florist': Icons.local_florist,
      'wb_sunny': Icons.wb_sunny,
      'nights_stay': Icons.nights_stay,
      'favorite': Icons.favorite,
      'star': Icons.star,
      'emoji_events': Icons.emoji_events,
    };
    return iconMap[iconName] ?? Icons.star;
  }

  /// Whether this habit is scheduled for the given date.
  /// Reminder off → scheduled every day. Otherwise checks repeatDays
  /// (index 0 = Monday, same indexing as repository stats logic).
  bool isScheduledOn(DateTime date) {
    if (!reminderEnabled) return true;
    if (repeatDays.length != 7) return true;
    return repeatDays[(date.weekday - 1) % 7];
  }

  Habit copyWith({
    String? id,
    String? name,
    String? category,
    int? colorIndex,
    String? iconName,
    bool? reminderEnabled,
    DateTime? reminderTime,
    List<bool>? repeatDays,
    DateTime? createdAt,
    bool? isArchived,
    int? notificationId,
    int? frequencyPerDay,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      colorIndex: colorIndex ?? this.colorIndex,
      iconName: iconName ?? this.iconName,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      repeatDays: repeatDays ?? this.repeatDays,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      notificationId: notificationId ?? this.notificationId,
      frequencyPerDay: frequencyPerDay ?? this.frequencyPerDay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'colorIndex': colorIndex,
      'iconName': iconName,
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime?.toIso8601String(),
      'repeatDays': repeatDays,
      'createdAt': createdAt.toIso8601String(),
      'isArchived': isArchived,
      'notificationId': notificationId,
      'frequencyPerDay': frequencyPerDay,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      colorIndex: json['colorIndex'],
      iconName: json['iconName'],
      reminderEnabled: json['reminderEnabled'],
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'])
          : null,
      repeatDays: List<bool>.from(json['repeatDays']),
      createdAt: DateTime.parse(json['createdAt']),
      isArchived: json['isArchived'],
      notificationId: json['notificationId'],
      frequencyPerDay: json['frequencyPerDay'] ?? 1,
    );
  }
}
