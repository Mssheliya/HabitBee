import 'package:flutter/material.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/data/models/habit_completion.dart';
import 'package:habit_bee/src/data/services/storage_service.dart';
import 'package:habit_bee/src/core/services/notification_service.dart';
import 'package:habit_bee/src/core/utils/motivational_messages.dart';

class HabitRepository {
  final StorageService _storageService;

  HabitRepository(this._storageService);

  Future<List<Habit>> getAllHabits() async {
    return await _storageService.getAllHabits();
  }

  Future<List<Habit>> getActiveHabits() async {
    return await _storageService.getActiveHabits();
  }

  Future<List<Habit>> getArchivedHabits() async {
    return await _storageService.getArchivedHabits();
  }

  Future<Habit?> getHabit(String id) async {
    return await _storageService.getHabit(id);
  }

  Future<void> createHabit(Habit habit) async {
    await _storageService.saveHabit(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    final oldHabit = await getHabit(habit.id);
    await _storageService.saveHabit(habit);

    // When the frequency changed, re-evaluate the stored completions so the
    // home card, arcs and stats instantly reflect the new target.
    if (oldHabit != null && oldHabit.frequencyPerDay != habit.frequencyPerDay) {
      await _syncCompletionsWithFrequency(habit);
    }
  }

  /// Re-marks each stored completion against the habit's current frequency:
  /// a day counts as completed when its count meets the frequency.
  Future<void> _syncCompletionsWithFrequency(Habit habit) async {
    final frequency = habit.frequencyPerDay > 0 ? habit.frequencyPerDay : 1;
    final completions = await _storageService.getCompletionsForHabit(habit.id);
    for (final completion in completions) {
      final shouldComplete = completion.completionCount >= frequency;
      if (completion.completed != shouldComplete) {
        completion.completed = shouldComplete;
        completion.completedAt = shouldComplete
            ? (completion.completedAt ?? DateTime.now())
            : null;
        await _storageService.saveCompletion(completion);
      }
    }
  }

  Future<void> deleteHabit(String id) async {
    final habit = await getHabit(id);
    // Cancel any scheduled reminder notifications before removing the habit
    // from storage, otherwise the OS keeps firing daily notifications for
    // a habit that no longer exists.
    if (habit != null && habit.reminderEnabled && habit.reminderTime != null) {
      try {
        await NotificationService().cancelNotification(habit.notificationId);
        debugPrint('Repository: Cancelled notifications for deleted habit $id');
      } catch (e) {
        debugPrint(
          'Repository: Error cancelling notification for deleted habit $id: $e',
        );
      }
    }
    await _storageService.deleteHabit(id);
  }

  Future<void> archiveHabit(String id) async {
    final habit = await getHabit(id);
    if (habit != null) {
      // Cancel scheduled reminders so an archived habit never fires
      // notifications while it is hidden from the app.
      if (habit.reminderEnabled && habit.reminderTime != null) {
        try {
          await NotificationService().cancelNotification(habit.notificationId);
          debugPrint(
            'Repository: Cancelled notifications for archived habit $id',
          );
        } catch (e) {
          debugPrint(
            'Repository: Error cancelling notification for archived habit $id: $e',
          );
        }
      }
      await _storageService.saveHabit(habit.copyWith(isArchived: true));
    }
  }

  Future<void> unarchiveHabit(String id) async {
    final habit = await getHabit(id);
    if (habit != null) {
      await _storageService.saveHabit(habit.copyWith(isArchived: false));

      // Re-schedule reminders immediately so the restored habit keeps
      // notifying without waiting for the next full app reschedule.
      if (habit.reminderEnabled && habit.reminderTime != null) {
        try {
          final now = DateTime.now();
          var scheduledDate = DateTime(
            now.year,
            now.month,
            now.day,
            habit.reminderTime!.hour,
            habit.reminderTime!.minute,
          );
          if (scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }
          await NotificationService().scheduleNotification(
            id: habit.notificationId,
            title: MotivationalMessages.getTitle(habit.category),
            body: MotivationalMessages.getMessage(habit.category, habit.name),
            scheduledDate: scheduledDate,
            repeatDays: habit.repeatDays,
          );
          debugPrint(
            'Repository: Rescheduled notifications for restored habit $id',
          );
        } catch (e) {
          debugPrint(
            'Repository: Error rescheduling notification for restored habit $id: $e',
          );
        }
      }
    }
  }

  // Completion operations
  Future<HabitCompletion?> getCompletionForDate(
    String habitId,
    DateTime date,
  ) async {
    return await _storageService.getCompletionForDate(habitId, date);
  }

  // Note operations -----------------------------------------------------------

  /// Returns the note saved for this habit on this date, or null.
  Future<String?> getNoteForDate(String habitId, DateTime date) async {
    final completion = await _storageService.getCompletionForDate(
      habitId,
      date,
    );
    final note = completion?.note;
    return (note != null && note.trim().isNotEmpty) ? note : null;
  }

  /// Saves (or clears, when empty) the note for this habit on this date.
  /// Creates a lightweight completion record when none exists yet so the
  /// note survives even on days the habit was never tapped.
  Future<void> saveNoteForDate(
    String habitId,
    DateTime date,
    String note,
  ) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final trimmed = note.trim();
    final completion = await _storageService.getCompletionForDate(
      habitId,
      normalizedDate,
    );

    if (completion == null) {
      if (trimmed.isEmpty) return; // Nothing to store
      final newCompletion = HabitCompletion.create(
        habitId: habitId,
        date: normalizedDate,
        note: trimmed,
      );
      await _storageService.saveCompletion(newCompletion);
      return;
    }

    completion.note = trimmed.isEmpty ? null : trimmed;
    await _storageService.saveCompletion(completion);
  }

  /// All saved notes for a habit, keyed by normalized date — used by the
  /// habit-detail calendar to mark days that have a note.
  Future<Map<DateTime, String>> getNotesForHabit(String habitId) async {
    final completions = await _storageService.getCompletionsForHabit(habitId);
    final notes = <DateTime, String>{};
    for (final completion in completions) {
      final note = completion.note;
      if (note != null && note.trim().isNotEmpty) {
        notes[DateTime(
              completion.date.year,
              completion.date.month,
              completion.date.day,
            )] =
            note;
      }
    }
    return notes;
  }

  Future<List<HabitCompletion>> getCompletionsForHabit(String habitId) async {
    return await _storageService.getCompletionsForHabit(habitId);
  }

  Future<List<HabitCompletion>> getCompletionsForDate(DateTime date) async {
    return await _storageService.getCompletionsForDate(date);
  }

  Future<void> toggleHabitCompletion(String habitId, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    debugPrint('Repository: Toggling habit $habitId for date $normalizedDate');

    // Always get fresh data from storage to avoid stale state
    final completion = await _storageService.getCompletionForDate(
      habitId,
      normalizedDate,
    );
    final habit = await getHabit(habitId);
    final frequency = habit?.frequencyPerDay ?? 1;
    bool becameCompletedToday = false;

    debugPrint(
      'Repository: Current completion: ${completion != null ? 'count=${completion.completionCount}, completed=${completion.completed}' : 'null'}, frequency=$frequency',
    );

    if (completion == null) {
      // First click - create with count = 1
      final newCompletion = HabitCompletion.create(
        habitId: habitId,
        date: normalizedDate,
        completed:
            frequency == 1, // If frequency is 1, mark as completed immediately
        completionCount: 1,
      );
      await _storageService.saveCompletion(newCompletion);
      debugPrint(
        'Repository: Created new completion with count=1, completed=${frequency == 1}',
      );
      if (frequency == 1) {
        becameCompletedToday = true;
      }
    } else {
      // Completion exists
      if (completion.completed) {
        // Already fully completed - DO NOT allow uncompleting on same day
        debugPrint(
          'Repository: Habit already fully completed - no action taken',
        );
        return;
      } else {
        // Not yet completed - increment count
        final newCount = completion.completionCount + 1;
        final isNowCompleted = newCount >= frequency;

        completion.completionCount = newCount;
        if (isNowCompleted) {
          completion.completed = true;
          completion.completedAt = DateTime.now();
          becameCompletedToday = true;
        }

        await _storageService.saveCompletion(completion);
        debugPrint(
          'Repository: Updated completion count to ${completion.completionCount}, completed=${completion.completed}',
        );
      }
    }

    // If today's habit has just become fully completed, cancel its pending reminder
    if (becameCompletedToday &&
        habit != null &&
        habit.reminderEnabled &&
        habit.reminderTime != null) {
      try {
        final notificationService = NotificationService();
        await notificationService.cancelNotification(habit.notificationId);
        debugPrint(
          'Repository: Cancelled notification for completed habit $habitId',
        );
      } catch (e) {
        debugPrint(
          'Repository: Error cancelling notification for completed habit $habitId: $e',
        );
      }
    }
  }

  Future<bool> isHabitCompleted(String habitId, DateTime date) async {
    final completion = await getCompletionForDate(habitId, date);
    return completion?.completed ?? false;
  }

  Future<int> getCompletionCount(String habitId, DateTime date) async {
    final completion = await getCompletionForDate(habitId, date);
    return completion?.completionCount ?? 0;
  }

  Future<Map<String, dynamic>> getHabitCompletionStatus(
    String habitId,
    DateTime date,
  ) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    debugPrint(
      'Repository: Getting status for habit $habitId on $normalizedDate',
    );

    final habit = await getHabit(habitId);
    final completion = await getCompletionForDate(habitId, normalizedDate);
    final frequency = habit?.frequencyPerDay ?? 1;
    final count = completion?.completionCount ?? 0;
    // The current frequency is the source of truth: a day is complete when
    // its count meets the frequency (keeps the card in sync right after a
    // frequency change).
    final isCompleted = frequency > 0 && count >= frequency;

    debugPrint(
      'Repository: Status -> count=$count, frequency=$frequency, isCompleted=$isCompleted',
    );

    return {
      'isCompleted': isCompleted,
      'completionCount': count,
      'frequency': frequency,
      'progress': frequency > 0 ? count / frequency : 0.0,
    };
  }

  Future<Map<String, dynamic>> getHabitStats(String habitId) async {
    final completions = await getCompletionsForHabit(habitId);
    final habit = await getHabit(habitId);
    final frequency = habit?.frequencyPerDay ?? 1;

    // Calculate completion rate considering partial progress
    double totalProgress = 0;
    int fullyCompletedDays = 0;
    int partialDays = 0;

    for (final completion in completions) {
      if (completion.completed) {
        fullyCompletedDays++;
        totalProgress += 1.0;
      } else if (completion.completionCount > 0) {
        partialDays++;
        totalProgress += completion.completionCount / frequency;
      }
    }

    final totalDays = completions.length;

    return {
      'completedDays': fullyCompletedDays,
      'partialDays': partialDays,
      'totalDays': totalDays,
      'completionRate': totalDays > 0
          ? (totalProgress / totalDays * 100).round()
          : 0,
      'totalProgress': totalProgress,
    };
  }

  Future<Map<String, dynamic>> getDailyStats(DateTime date) async {
    final habits = await getActiveHabits();
    final completions = await getCompletionsForDate(date);
    final totalHabits = habits.length;

    // Calculate partial progress for multi-frequency habits
    double totalProgress = 0;
    int fullyCompletedCount = 0;

    for (final habit in habits) {
      final completion = completions.firstWhere(
        (c) => c.habitId == habit.id,
        orElse: () => HabitCompletion.create(
          habitId: habit.id,
          date: date,
          completionCount: 0,
        ),
      );

      if (completion.completed) {
        fullyCompletedCount++;
        totalProgress += 1.0;
      } else if (completion.completionCount > 0) {
        // Partial completion - calculate progress percentage
        final progress = completion.completionCount / habit.frequencyPerDay;
        totalProgress += progress;
      }
    }

    return {
      'completedCount': fullyCompletedCount,
      'partialCount': completions
          .where((c) => !c.completed && c.completionCount > 0)
          .length,
      'totalHabits': totalHabits,
      'completionRate': totalHabits > 0
          ? (totalProgress / totalHabits * 100).round()
          : 0,
      'totalProgress': totalProgress,
    };
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats(DateTime startDate) async {
    final List<Map<String, dynamic>> weeklyStats = [];

    for (int i = 0; i < 7; i++) {
      final date = startDate.subtract(Duration(days: i));
      final stats = await getDailyStats(date);
      weeklyStats.add({'date': date, ...stats});
    }

    return weeklyStats.reversed.toList();
  }

  Future<Map<String, dynamic>> getOverallStats() async {
    final habits = await getActiveHabits();
    final allCompletions = await _storageService.getAllCompletions();

    // Calculate completion rate considering partial progress
    double totalProgress = 0;
    int fullyCompletedDays = 0;
    int partialDays = 0;

    for (final completion in allCompletions) {
      final habit = habits.firstWhere(
        (h) => h.id == completion.habitId,
        orElse: () => Habit(
          id: '',
          name: '',
          category: '',
          colorIndex: 0,
          iconName: 'check',
          repeatDays: List.filled(7, true),
          createdAt: DateTime.now(),
          frequencyPerDay: 1,
        ),
      );

      if (completion.completed) {
        fullyCompletedDays++;
        totalProgress += 1.0;
      } else if (completion.completionCount > 0) {
        partialDays++;
        final frequency = habit.frequencyPerDay > 0 ? habit.frequencyPerDay : 1;
        totalProgress += completion.completionCount / frequency;
      }
    }

    final totalCompletions = allCompletions.length;

    // Calculate current and best streaks
    int currentStreak = 0;
    int bestStreak = 0;

    if (habits.isNotEmpty) {
      for (final habit in habits) {
        final habitStreaks = await getHabitStreaks(habit.id);
        currentStreak += habitStreaks['currentStreak'] as int;
        if (habitStreaks['bestStreak'] as int > bestStreak) {
          bestStreak = habitStreaks['bestStreak'] as int;
        }
      }
    }

    return {
      'totalHabits': habits.length,
      'completedCompletions': fullyCompletedDays,
      'partialCompletions': partialDays,
      'totalCompletions': totalCompletions,
      'overallCompletionRate': totalCompletions > 0
          ? (totalProgress / totalCompletions * 100).round()
          : 0,
      'totalProgress': totalProgress,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
    };
  }

  Future<Map<String, dynamic>> getHabitStreaks(String habitId) async {
    final completions = await getCompletionsForHabit(habitId);
    final completedDates = completions
        .where((c) => c.completed)
        .map((c) => c.date)
        .toList();

    if (completedDates.isEmpty) {
      return {'currentStreak': 0, 'bestStreak': 0};
    }

    // Sort dates in descending order
    completedDates.sort((a, b) => b.compareTo(a));

    // Calculate current streak
    int currentStreak = 0;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Check if completed today or yesterday
    final mostRecentDate = DateTime(
      completedDates.first.year,
      completedDates.first.month,
      completedDates.first.day,
    );

    final daysSinceLastCompletion = normalizedToday
        .difference(mostRecentDate)
        .inDays;

    if (daysSinceLastCompletion <= 1) {
      // Streak is active
      currentStreak = 1;
      DateTime expectedDate = mostRecentDate.subtract(const Duration(days: 1));

      for (int i = 1; i < completedDates.length; i++) {
        final date = DateTime(
          completedDates[i].year,
          completedDates[i].month,
          completedDates[i].day,
        );

        if (date == expectedDate) {
          currentStreak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else if (date.isBefore(expectedDate)) {
          break;
        }
      }
    }

    // Calculate best streak
    int bestStreak = 0;
    int tempStreak = 0;
    DateTime? previousDate;

    // Sort in ascending order for best streak calculation
    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => a.compareTo(b));

    for (final date in sortedDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);

      if (previousDate == null) {
        tempStreak = 1;
      } else {
        final difference = normalizedDate.difference(previousDate).inDays;
        if (difference == 1) {
          tempStreak++;
        } else if (difference > 1) {
          if (tempStreak > bestStreak) {
            bestStreak = tempStreak;
          }
          tempStreak = 1;
        }
      }
      previousDate = normalizedDate;
    }

    if (tempStreak > bestStreak) {
      bestStreak = tempStreak;
    }

    return {'currentStreak': currentStreak, 'bestStreak': bestStreak};
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats(DateTime startDate) async {
    final List<Map<String, dynamic>> monthlyStats = [];
    final habits = await getActiveHabits();

    for (int i = 29; i >= 0; i--) {
      final date = startDate.subtract(Duration(days: i));
      final completions = await getCompletionsForDate(date);
      final completedCount = completions.where((c) => c.completed).length;
      final totalHabits = habits.length;

      monthlyStats.add({
        'date': date,
        'completionRate': totalHabits > 0
            ? (completedCount / totalHabits * 100).round()
            : 0,
        'completedCount': completedCount,
        'totalHabits': totalHabits,
      });
    }

    return monthlyStats;
  }

  Future<List<Map<String, dynamic>>> getAllTimeStats() async {
    final habits = await getActiveHabits();
    if (habits.isEmpty) return [];

    // Find the earliest creation date
    DateTime? earliestDate;
    for (final habit in habits) {
      if (earliestDate == null || habit.createdAt.isBefore(earliestDate)) {
        earliestDate = habit.createdAt;
      }
    }

    if (earliestDate == null) return [];

    final today = DateTime.now();
    final daysDifference = today.difference(earliestDate).inDays;
    final daysToShow = daysDifference > 365 ? 365 : daysDifference + 1;

    final List<Map<String, dynamic>> allTimeStats = [];

    for (int i = daysToShow - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final completions = await getCompletionsForDate(date);
      final completedCount = completions.where((c) => c.completed).length;
      final totalHabits = habits.length;

      allTimeStats.add({
        'date': date,
        'completionRate': totalHabits > 0
            ? (completedCount / totalHabits * 100).round()
            : 0,
        'completedCount': completedCount,
        'totalHabits': totalHabits,
      });
    }

    return allTimeStats;
  }

  // Reschedule all habit notifications (call this on app startup)
  Future<void> rescheduleAllNotifications() async {
    final habits = await getActiveHabits();
    final notificationService = NotificationService();

    // STEP 0: Migrate habits that still carry the legacy timestamp-based
    // notification ID (very large values close to 2^31) to small sequential
    // IDs. Old IDs could overflow 32-bit space when adding the +0..6
    // day offsets, making Android silently refuse some day notifications.
    const legacyThreshold = 1000000; // sequential IDs start at ~1010
    for (final habit in habits) {
      if (habit.reminderEnabled &&
          habit.reminderTime != null &&
          habit.notificationId >= legacyThreshold) {
        try {
          final oldId = habit.notificationId;
          await notificationService.cancelNotification(oldId);
          final newId = await _storageService.getNextNotificationBaseId();
          await _storageService.saveHabit(
            habit.copyWith(notificationId: newId),
          );
          habit.notificationId = newId;
          debugPrint(
            'Repository: Migrated notificationId for ${habit.name}: $oldId -> $newId',
          );
        } catch (e) {
          debugPrint('Repository: ID migration failed for ${habit.name}: $e');
        }
      }
    }

    // STEP 1: Schedule fresh notifications FIRST (keeps old ones as a safety
    // net until the new ones are confirmed by the OS).
    int scheduledCount = 0;
    int failedCount = 0;
    for (final habit in habits) {
      if (habit.reminderEnabled && habit.reminderTime != null) {
        try {
          // Calculate next reminder time
          final now = DateTime.now();
          var scheduledDate = DateTime(
            now.year,
            now.month,
            now.day,
            habit.reminderTime!.hour,
            habit.reminderTime!.minute,
          );

          // If time has passed, schedule for tomorrow
          if (scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }

          // Schedule new notification
          await notificationService.scheduleNotification(
            id: habit.notificationId,
            title: MotivationalMessages.getTitle(habit.category),
            body: MotivationalMessages.getMessage(habit.category, habit.name),
            scheduledDate: scheduledDate,
            repeatDays: habit.repeatDays,
          );

          scheduledCount++;
          debugPrint(
            'Rescheduled notification for habit: ${habit.name} at $scheduledDate',
          );
        } catch (e) {
          failedCount++;
          debugPrint('FAILED to reschedule notification for ${habit.name}: $e');
        }
      }
    }

    // Purge any pending notifications left behind by habits that were
    // deleted before delete-time cancellation existed (old-version orphans).
    final validIds = <int>{};
    for (final habit in habits) {
      for (var i = 0; i < 7; i++) {
        validIds.add(habit.notificationId + i);
      }
    }
    try {
      await notificationService.cancelOrphanedNotifications(validIds);
      debugPrint('Repository: Orphaned notification cleanup done');
    } catch (e) {
      debugPrint('Repository: Error during orphaned notification cleanup: $e');
    }

    // STEP 2: Verify — count pending notifications in the OS vs expected.
    try {
      final pending = await notificationService.getPendingNotifications();
      debugPrint(
        'Repository: OS pending notifications = ${pending.length} '
        '(habits scheduled: $scheduledCount, failed: $failedCount)',
      );
    } catch (e) {
      debugPrint('Repository: Pending notification verification failed: $e');
    }

    if (failedCount > 0) {
      debugPrint(
        'Repository: WARNING — $failedCount habit(s) failed to reschedule notifications',
      );
    }
    debugPrint('Rescheduled $scheduledCount notifications');
  }
}
