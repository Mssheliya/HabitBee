import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Habit> _habits = [];
  Map<String, List<DateTime>> _habitCompletionDates = {};
  Map<String, Map<DateTime, double>> _habitCompletionProgress = {};
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  // Public method to refresh data from outside
  void refreshData() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repository = Provider.of<HabitRepository>(context, listen: false);
      final habits = await repository.getActiveHabits();
      
      // Load completion progress for each habit (including partial completions)
      final habitCompletionDates = <String, List<DateTime>>{};
      final habitCompletionProgress = <String, Map<DateTime, double>>{};
      
      for (final habit in habits) {
        final completions = await repository.getCompletionsForHabit(habit.id);
        final completedDates = <DateTime>[];
        final progressMap = <DateTime, double>{};
        
        for (final completion in completions) {
          final date = DateTime(completion.date.year, completion.date.month, completion.date.day);
          
          if (completion.completed) {
            completedDates.add(date);
            progressMap[date] = 1.0;
          } else if (completion.completionCount > 0) {
            // Include partial completions
            completedDates.add(date);
            progressMap[date] = completion.completionCount / habit.frequencyPerDay;
          }
        }
        
        habitCompletionDates[habit.id] = completedDates;
        habitCompletionProgress[habit.id] = progressMap;
      }

      if (mounted) {
        setState(() {
          _habits = habits;
          _habitCompletionDates = habitCompletionDates;
          _habitCompletionProgress = habitCompletionProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required when using AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: _isLoading
                  ? Center(
                  child: MaterialLoadingIndicator(
                    size: 56,
                    color: theme.colorScheme.primary,
                    style: LoadingStyle.wave,
                  ),
                    )
                  : _error != null
                      ? _buildErrorState(theme)
                      : _buildBody(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Progress',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error loading data', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendar(theme),
            const SizedBox(height: 24),
            _buildSelectedDaySummary(theme),
            const SizedBox(height: 24),
            _buildHabitProgressList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    // Calculate completion progress for each day (including partial completions)
    final Map<DateTime, double> completionProgress = {};
    for (final entry in _habitCompletionProgress.entries) {
      for (final dateProgress in entry.value.entries) {
        final normalizedDate = DateTime(dateProgress.key.year, dateProgress.key.month, dateProgress.key.day);
        completionProgress[normalizedDate] = (completionProgress[normalizedDate] ?? 0) + dateProgress.value;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(color: theme.colorScheme.onSurface),
            holidayTextStyle: TextStyle(color: theme.colorScheme.onSurface),
            defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: true,
            formatButtonDecoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: theme.textTheme.bodySmall!,
            titleTextStyle: theme.textTheme.titleMedium!,
            leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurface),
            rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: theme.textTheme.bodySmall!,
            weekendStyle: theme.textTheme.bodySmall!,
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final progress = completionProgress[normalizedDate] ?? 0;
              
              if (progress <= 0) return null;
              
              final maxHabits = _habits.length > 0 ? _habits.length : 1;
              final intensity = (progress / maxHabits).clamp(0.0, 1.0);
              
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      theme.colorScheme.primary.withOpacity(0.3),
                      theme.colorScheme.primary,
                      intensity,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
            defaultBuilder: (context, day, focusedDay) {
              final normalizedDate = DateTime(day.year, day.month, day.day);
              final progress = completionProgress[normalizedDate] ?? 0;
              
              if (progress <= 0 || _habits.isEmpty) return null;
              
              final maxHabits = _habits.length;
              final intensity = (progress / maxHabits).clamp(0.0, 1.0);
              
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: intensity > 0
                      ? theme.colorScheme.primary.withOpacity(intensity * 0.3)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDaySummary(ThemeData theme) {
    if (_selectedDay == null) return const SizedBox.shrink();

    final normalizedDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    // Calculate progress including partial completions
    double totalProgress = 0;
    int fullyCompletedCount = 0;
    int partialCount = 0;
    
    for (final entry in _habitCompletionProgress.entries) {
      final progress = entry.value[normalizedDate];
      if (progress != null && progress > 0) {
        totalProgress += progress;
        if (progress >= 1.0) {
          fullyCompletedCount++;
        } else {
          partialCount++;
        }
      }
    }

    final completionRate = _habits.isNotEmpty
        ? (totalProgress / _habits.length * 100).round()
        : 0;

    final isToday = DateTime.now().difference(normalizedDate).inDays == 0;
    final dateLabel = isToday
        ? 'Today'
        : DateFormat('EEEE, MMM d').format(_selectedDay!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  theme,
                  'Completed',
                  '$fullyCompletedCount${_habits.isNotEmpty ? "/${_habits.length}" : ""}',
                  Icons.check_circle,
                  theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  theme,
                  'Progress',
                  '$completionRate%',
                  Icons.trending_up,
                  const Color(0xFFB5EAD7),
                ),
              ),
            ],
          ),
          if (partialCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '+$partialCount partial',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHabitProgressList(ThemeData theme) {
    if (_habits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No habits yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Add habits to track your progress!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Habit Progress',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ..._habits.map((habit) => _buildHabitCard(theme, habit)),
      ],
    );
  }

  Widget _buildHabitCard(ThemeData theme, Habit habit) {
    final completionDates = _habitCompletionDates[habit.id] ?? [];
    final streak = _calculateStreak(completionDates);
    final bestStreak = _calculateBestStreak(completionDates);
    final totalCompleted = completionDates.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: habit.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  habit.icon,
                  color: habit.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${habit.category} • $totalCompleted days completed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  theme,
                  'Current Streak',
                  '$streak days',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  theme,
                  'Best Streak',
                  '$bestStreak days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mini calendar strip showing last 7 days
          _buildMiniCalendarStrip(theme, habit, completionDates),
        ],
      ),
    );
  }

  Widget _buildStatChip(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendarStrip(ThemeData theme, Habit habit, List<DateTime> completionDates) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final habitProgress = _habitCompletionProgress[habit.id] ?? {};
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final date = normalizedToday.subtract(Duration(days: 6 - index));
        final progress = habitProgress[date] ?? 0.0;
        final isCompleted = progress >= 1.0;
        final isPartial = progress > 0.0 && progress < 1.0;
        final isToday = date == normalizedToday;
        
        final dayLabel = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7];
        
        // Calculate color intensity based on progress
        Color cellColor;
        if (isCompleted) {
          cellColor = habit.color;
        } else if (isPartial) {
          // Use a lighter shade for partial completion
          cellColor = habit.color.withOpacity(0.3 + (progress * 0.4));
        } else {
          cellColor = theme.colorScheme.surfaceContainerHighest;
        }
        
        return Column(
          children: [
            Text(
              dayLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(6),
                border: isToday
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : isPartial
                        ? Border.all(
                            color: habit.color.withOpacity(0.5),
                            width: 1,
                          )
                        : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isCompleted || isPartial
                        ? AppTheme.black
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    
    final sortedDates = dates.map((d) => 
      DateTime(d.year, d.month, d.day)
    ).toList()
      ..sort((a, b) => b.compareTo(a));
    
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    // Check if completed today or yesterday
    final mostRecent = sortedDates.first;
    final daysSince = normalizedToday.difference(mostRecent).inDays;
    
    if (daysSince > 1) return 0;
    
    int streak = 1;
    DateTime expectedDate = mostRecent.subtract(const Duration(days: 1));
    
    for (int i = 1; i < sortedDates.length; i++) {
      if (sortedDates[i] == expectedDate) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (sortedDates[i].isBefore(expectedDate)) {
        break;
      }
    }
    
    return streak;
  }

  int _calculateBestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    
    final sortedDates = dates.map((d) => 
      DateTime(d.year, d.month, d.day)
    ).toList()
      ..sort();
    
    int bestStreak = 0;
    int currentStreak = 0;
    DateTime? previousDate;
    
    for (final date in sortedDates) {
      if (previousDate == null) {
        currentStreak = 1;
      } else {
        final difference = date.difference(previousDate).inDays;
        if (difference == 1) {
          currentStreak++;
        } else if (difference > 1) {
          if (currentStreak > bestStreak) {
            bestStreak = currentStreak;
          }
          currentStreak = 1;
        }
      }
      previousDate = date;
    }
    
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }
    
    return bestStreak;
  }
}
