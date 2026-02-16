import 'package:hive/hive.dart';

part 'habit_completion.g.dart';

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

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
    this.completed = false,
    this.completedAt,
    this.completionCount = 0,
  });

  factory HabitCompletion.create({
    required String habitId,
    required DateTime date,
    bool completed = false,
    int completionCount = 0,
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
    );
  }
}
