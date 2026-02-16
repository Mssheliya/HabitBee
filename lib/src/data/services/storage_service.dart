import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_bee/src/core/constants/app_constants.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/data/models/habit_completion.dart';
import 'package:habit_bee/src/data/models/app_settings.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Box<Habit>? _habitsBox;
  Box<HabitCompletion>? _completionsBox;
  Box<AppSettings>? _settingsBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitCompletionAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(AppThemeTypeAdapter());

    _habitsBox = await Hive.openBox<Habit>(AppConstants.habitsBox);
    _completionsBox = await Hive.openBox<HabitCompletion>(AppConstants.completionsBox);
    _settingsBox = await Hive.openBox<AppSettings>(AppConstants.settingsBox);

    if (_settingsBox!.isEmpty) {
      await _settingsBox!.put('settings', AppSettings.defaultSettings());
    }
  }

  // Habits
  Future<List<Habit>> getAllHabits() async {
    return _habitsBox?.values.toList() ?? [];
  }

  Future<List<Habit>> getActiveHabits() async {
    return _habitsBox?.values.where((h) => !h.isArchived).toList() ?? [];
  }

  Future<Habit?> getHabit(String id) async {
    return _habitsBox?.get(id);
  }

  Future<void> saveHabit(Habit habit) async {
    await _habitsBox?.put(habit.id, habit);
  }

  Future<void> deleteHabit(String id) async {
    await _habitsBox?.delete(id);
    // Also delete all completions for this habit
    final completions = await getCompletionsForHabit(id);
    for (var completion in completions) {
      await _completionsBox?.delete(completion.id);
    }
  }

  // Completions
  Future<List<HabitCompletion>> getAllCompletions() async {
    return _completionsBox?.values.toList() ?? [];
  }

  Future<List<HabitCompletion>> getCompletionsForHabit(String habitId) async {
    return _completionsBox?.values
        .where((c) => c.habitId == habitId)
        .toList() ?? [];
  }

  Future<HabitCompletion?> getCompletionForDate(String habitId, DateTime date) async {
    // Normalize date to ensure consistent comparison (remove time component)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final id = '${habitId}_${normalizedDate.toIso8601String().split('T')[0]}';
    final completion = _completionsBox?.get(id);
    debugPrint('StorageService: Getting completion for $id -> ${completion != null ? 'Found (count: ${completion.completionCount}, completed: ${completion.completed})' : 'Not found'}');
    return completion;
  }

  Future<List<HabitCompletion>> getCompletionsForDate(DateTime date) async {
    // Normalize date to ensure consistent comparison (remove time component)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateStr = normalizedDate.toIso8601String().split('T')[0];
    return _completionsBox?.values
        .where((c) {
          final completionDate = DateTime(c.date.year, c.date.month, c.date.day);
          return completionDate.toIso8601String().split('T')[0] == dateStr;
        })
        .toList() ?? [];
  }

  Future<void> saveCompletion(HabitCompletion completion) async {
    debugPrint('StorageService: Saving completion ${completion.id} (count: ${completion.completionCount}, completed: ${completion.completed})');
    await _completionsBox?.put(completion.id, completion);
    debugPrint('StorageService: Completion saved successfully');
  }

  Future<void> deleteCompletion(String id) async {
    await _completionsBox?.delete(id);
  }

  // Settings
  Future<AppSettings> getSettings() async {
    return _settingsBox?.get('settings') ?? AppSettings.defaultSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox?.put('settings', settings);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _habitsBox?.clear();
    await _completionsBox?.clear();
  }

  // Export data to JSON
  Future<Map<String, dynamic>> exportData() async {
    final habits = await getAllHabits();
    final completions = await getAllCompletions();
    final settings = await getSettings();

    return {
      'habits': habits.map((h) => h.toJson()).toList(),
      'completions': completions.map((c) => c.toJson()).toList(),
      'settings': settings.toJson(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Import data from JSON
  Future<void> importData(Map<String, dynamic> data) async {
    await clearAllData();

    if (data['habits'] != null) {
      for (var habitJson in data['habits']) {
        final habit = Habit.fromJson(habitJson);
        await saveHabit(habit);
      }
    }

    if (data['completions'] != null) {
      for (var completionJson in data['completions']) {
        final completion = HabitCompletion.fromJson(completionJson);
        await saveCompletion(completion);
      }
    }

    if (data['settings'] != null) {
      final settings = AppSettings.fromJson(data['settings']);
      await saveSettings(settings);
    }
  }

  // Export data to CSV
  Future<String> exportToCsv() async {
    final habits = await getAllHabits();
    final completions = await getAllCompletions();
    
    final buffer = StringBuffer();
    
    // Write header
    buffer.writeln('Habit ID,Name,Category,Color Index,Icon Name,Reminder Enabled,Frequency Per Day,Created At,Is Archived,Completion Date,Completed,Completion Count');
    
    // Write data
    for (var habit in habits) {
      final habitCompletions = completions.where((c) => c.habitId == habit.id).toList();
      
      if (habitCompletions.isEmpty) {
        // Write habit row without completions
        buffer.writeln('${habit.id},${_escapeCsv(habit.name)},${_escapeCsv(habit.category)},${habit.colorIndex},${habit.iconName},${habit.reminderEnabled},${habit.frequencyPerDay},${habit.createdAt.toIso8601String()},${habit.isArchived},,,0');
      } else {
        // Write habit row for each completion
        for (var completion in habitCompletions) {
          buffer.writeln('${habit.id},${_escapeCsv(habit.name)},${_escapeCsv(habit.category)},${habit.colorIndex},${habit.iconName},${habit.reminderEnabled},${habit.frequencyPerDay},${habit.createdAt.toIso8601String()},${habit.isArchived},${completion.date.toIso8601String()},${completion.completed},${completion.completionCount}');
        }
      }
    }
    
    return buffer.toString();
  }

  // Helper to escape CSV values
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // Import data from CSV
  Future<int> importFromCsv(String csvData) async {
    final lines = LineSplitter.split(csvData).toList();
    if (lines.isEmpty) return 0;
    
    // Skip header line
    final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
    
    int importedHabits = 0;
    final Map<String, Habit> habitMap = {};
    
    for (var line in dataLines) {
      try {
        final parts = _parseCsvLine(line);
        if (parts.length < 8) continue;
        
        final habitId = parts[0];
        final habitName = parts[1];
        final category = parts[2];
        final colorIndex = int.tryParse(parts[3]) ?? 0;
        final iconName = parts[4];
        final reminderEnabled = parts[5].toLowerCase() == 'true';
        final frequencyPerDay = int.tryParse(parts[6]) ?? 1;
        
        // Create or get existing habit
        if (!habitMap.containsKey(habitId)) {
          final habit = Habit.create(
            name: habitName,
            category: category,
            colorIndex: colorIndex,
            iconName: iconName,
            reminderEnabled: reminderEnabled,
            frequencyPerDay: frequencyPerDay,
          );
          habitMap[habitId] = habit;
          await saveHabit(habit);
          importedHabits++;
        }
        
        // Import completion if present
        if (parts.length >= 11 && parts[9].isNotEmpty) {
          try {
            final completionDate = DateTime.parse(parts[9]);
            final completed = parts[10].toLowerCase() == 'true';
            final completionCount = int.tryParse(parts[11]) ?? (completed ? 1 : 0);
            
            final habit = habitMap[habitId]!;
            final completion = HabitCompletion(
              id: '${habit.id}_${completionDate.toIso8601String().split('T')[0]}',
              habitId: habit.id,
              date: completionDate,
              completed: completed,
              completionCount: completionCount,
            );
            await saveCompletion(completion);
          } catch (e) {
            debugPrint('Error parsing completion: $e');
          }
        }
      } catch (e) {
        debugPrint('Error parsing CSV line: $e');
      }
    }
    
    return importedHabits;
  }

  // Helper to parse CSV line (handles quoted values)
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          current.write('"');
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    
    result.add(current.toString());
    return result;
  }
}
