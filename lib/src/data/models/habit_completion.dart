import 'package:hive/hive.dart';

part 'habit_completion.g.dart';

// Tolerant parsers for legacy stored values (String/num instead of bool/int/DateTime)
bool _hcBool(dynamic v, bool fallback) {
  if (v is bool) return v;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
  }
  if (v is num) return v != 0;
  return fallback;
}

int _hcInt(dynamic v, int fallback) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

DateTime _hcDate(dynamic v, DateTime fallback) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v) ?? fallback;
  return fallback;
}

DateTime? _hcDateOrNull(dynamic v) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

@HiveType(typeId: 1)
class HabitCompletion extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String habitId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  bool completed;

  @HiveField(4)
  DateTime? completedAt;

  @HiveField(5)
  int completionCount;

  /// Optional user note for this habit on this date.
  @HiveField(6)
  String? note;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
    this.completed = false,
    this.completedAt,
    this.completionCount = 0,
    this.note,
  });

  factory HabitCompletion.create({
    required String habitId,
    required DateTime date,
    bool completed = false,
    int completionCount = 0,
    String? note,
  }) {
    // Normalize date to remove time component for consistent storage
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return HabitCompletion(
      id: '${habitId}_${normalizedDate.toIso8601String().split('T')[0]}',
      habitId: habitId,
      date: normalizedDate,
      completed: completed,
      completedAt: completed ? DateTime.now() : null,
      completionCount: completionCount,
      note: note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date.toIso8601String(),
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'completionCount': completionCount,
      'note': note,
    };
  }

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      id: json['id'],
      habitId: json['habitId'],
      date: DateTime.parse(json['date']),
      completed: json['completed'],
      completedAt:
          json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      completionCount: json['completionCount'] ?? 0,
      note: json['note'],
    );
  }
}
