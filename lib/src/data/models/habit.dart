import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'habit.g.dart';

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
      notificationId: DateTime.now().millisecondsSinceEpoch % 2147483647,
      frequencyPerDay: frequencyPerDay,
    );
  }

  Color get color {
    final colors = [
      const Color(0xFFFFB7B2), // Soft Red
      const Color(0xFFFFDAC1), // Peach
      const Color(0xFFE2F0CB), // Soft Green
      const Color(0xFFB5EAD7), // Mint
      const Color(0xFFC7CEEA), // Soft Purple
      const Color(0xFFF8B195), // Coral
      const Color(0xFFF67280), // Pink
      const Color(0xFFC06C84), // Mauve
      const Color(0xFF6C5B7B), // Deep Purple
      const Color(0xFF355C7D), // Navy Blue
    ];
    return colors[colorIndex % colors.length];
  }

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
