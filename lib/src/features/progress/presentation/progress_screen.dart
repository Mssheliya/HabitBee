import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';
import 'package:habit_bee/src/features/habit_detail/presentation/habit_detail_screen.dart';

enum ProgressPeriod {
  thisWeek,
  thisMonth,
  thisYear,
  allTime,
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  ProgressPeriod _selectedPeriod = ProgressPeriod.thisWeek;

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

      final habitCompletionDates = <String, List<DateTime>>{};
      final habitCompletionProgress = <String, Map<DateTime, double>>{};

      for (final habit in habits) {
        final completions = await repository.getCompletionsForHabit(habit.id);
        final completedDates = <DateTime>[];
        final progressMap = <DateTime, double>{};

        for (final completion in completions) {
          final date = DateTime(
            completion.date.year,
            completion.date.month,
            completion.date.day,
          );

          if (completion.completed) {
            completedDates.add(date);
            progressMap[date] = 1.0;
          } else if (completion.completionCount > 0) {
            final freq = habit.frequencyPerDay > 0 ? habit.frequencyPerDay : 1;
            progressMap[date] = completion.completionCount / freq;
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
    super.build(context);
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Calendar
            _buildCalendar(theme),
            const SizedBox(height: 16),

            // 2. Calendar ke niche wala "Today" Progress Card
            _buildTodayProgressCard(theme),
            const SizedBox(height: 20),

            // 3. 4 Buttons (This Week, This Month, This Year, All Time)
            _buildPeriodSelectorButtons(theme),
            const SizedBox(height: 24),

            // 4. Overview Section
            _buildOverviewSection(theme),
            const SizedBox(height: 24),

            // 5. Top Streak Card
            _buildTopStreakCard(theme),
            const SizedBox(height: 20),

            // 6. Consistency Trend
            _buildConsistencyTrendCard(theme),
            const SizedBox(height: 24),

            // 7. Habits Overview
            _buildHabitsOverview(theme),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Top Calendar
  // ---------------------------------------------------------------------------
  Widget _buildCalendar(ThemeData theme) {
    final Map<DateTime, double> completionProgress = {};
    for (final entry in _habitCompletionProgress.entries) {
      for (final dateProgress in entry.value.entries) {
        final normalizedDate = DateTime(
          dateProgress.key.year,
          dateProgress.key.month,
          dateProgress.key.day,
        );
        completionProgress[normalizedDate] =
            (completionProgress[normalizedDate] ?? 0) + dateProgress.value;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          availableCalendarFormats: const {
            CalendarFormat.week: 'Week',
            CalendarFormat.twoWeeks: '2 weeks',
            CalendarFormat.month: 'Month',
          },
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            titleTextStyle: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
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

              final maxHabits = _habits.isNotEmpty ? _habits.length : 1;
              final intensity = (progress / maxHabits).clamp(0.0, 1.0);

              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      theme.colorScheme.primary.withValues(alpha: 0.3),
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
                      ? theme.colorScheme.primary.withValues(alpha: intensity * 0.3)
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

  // ---------------------------------------------------------------------------
  // 2. Calendar ke niche wala "Today" Progress Card (Tertiary Tinted)
  // ---------------------------------------------------------------------------
  Widget _buildTodayProgressCard(ThemeData theme) {
    final activeDay = _selectedDay ?? DateTime.now();
    final normalizedDate = DateTime(
      activeDay.year,
      activeDay.month,
      activeDay.day,
    );

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

    final isToday = DateTime.now().difference(normalizedDate).inDays == 0 &&
        DateTime.now().day == normalizedDate.day;
    final dateLabel = isToday
        ? 'Today'
        : DateFormat('EEEE, MMM d').format(activeDay);

    final tertiary = theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: tertiary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: tertiary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$fullyCompletedCount${_habits.isNotEmpty ? "/${_habits.length}" : ""}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tertiary,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Completed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tertiary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: tertiary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completionRate%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tertiary,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Progress',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tertiary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (partialCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '+$partialCount partial',
              style: theme.textTheme.bodySmall?.copyWith(
                color: tertiary.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. 4 Buttons (This Week, This Month, This Year, All Time)
  // ---------------------------------------------------------------------------
  Widget _buildPeriodSelectorButtons(ThemeData theme) {
    final buttons = [
      (ProgressPeriod.thisWeek, 'This Week'),
      (ProgressPeriod.thisMonth, 'This Month'),
      (ProgressPeriod.thisYear, 'This Year'),
      (ProgressPeriod.allTime, 'All Time'),
    ];

    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: buttons.map((item) {
        final period = item.$1;
        final label = item.$2;
        final isSelected = _selectedPeriod == period;

        final Color buttonBg;
        final Color textColor;

        if (isDark) {
          if (isSelected) {
            buttonBg = theme.colorScheme.onTertiaryContainer;
            textColor = theme.colorScheme.tertiaryContainer;
          } else {
            buttonBg = theme.colorScheme.tertiaryContainer;
            textColor = theme.colorScheme.onTertiaryContainer;
          }
        } else {
          if (isSelected) {
            buttonBg = theme.colorScheme.tertiary;
            textColor = theme.colorScheme.onTertiary;
          } else {
            buttonBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
            textColor = theme.colorScheme.onSurfaceVariant;
          }
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Provider.of<ThemeProvider>(context, listen: false).triggerHaptic();
                  setState(() {
                    _selectedPeriod = period;
                  });
                },
                borderRadius: BorderRadius.circular(isSelected ? 24 : 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: buttonBg,
                    borderRadius: BorderRadius.circular(isSelected ? 24 : 10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Overview Section (Theme Colors only, NO tertiary)
  // ---------------------------------------------------------------------------
  Widget _buildOverviewSection(ThemeData theme) {
    final periodStats = _calculatePeriodStats(_selectedPeriod);
    final periodTitle = switch (_selectedPeriod) {
      ProgressPeriod.thisWeek => 'This Week Overview',
      ProgressPeriod.thisMonth => 'This Month Overview',
      ProgressPeriod.thisYear => 'This Year Overview',
      ProgressPeriod.allTime => 'All Time Overview',
    };

    final healthPercent = periodStats.healthPercentage;
    final doneCount = periodStats.totalDone;
    final targetCount = periodStats.totalTarget;
    final habitsCount = _habits.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          periodTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),

        // Big Circle: Percentage + Habit Health
        Center(
          child: SizedBox(
            width: 210,
            height: 210,
            child: CustomPaint(
              painter: _HabitHealthPainter(
                percentage: healthPercent / 100.0,
                trackColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                progressColor: theme.colorScheme.primary,
                strokeWidth: 14,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$healthPercent%',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 38,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Habit Health',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 3 side-by-side metric cards: Done (highlighted), Target, Habits
        Row(
          children: [
            // Done Card (Highlighted)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$doneCount',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'done',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Target Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$targetCount',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Habits Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$habitsCount',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Habits',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Top Streak Card (Theme Colors only, NO tertiary)
  // ---------------------------------------------------------------------------
  Widget _buildTopStreakCard(ThemeData theme) {
    final periodStats = _calculatePeriodStats(_selectedPeriod);
    final topStreak = periodStats.topStreak;
    final topHabit = periodStats.topStreakHabit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$topStreak Day',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Top streak',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (topHabit != null)
            GestureDetector(
              onTap: () {
                Provider.of<ThemeProvider>(context, listen: false).triggerHaptic();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HabitDetailScreen(habit: topHabit),
                  ),
                ).then((_) => _loadData());
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: topHabit.scheme(theme.brightness).primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  topHabit.icon,
                  color: topHabit.scheme(theme.brightness).onPrimaryContainer,
                  size: 20,
                ),
              ),
            )
          else
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Consistency Trend (Tertiary Line Color)
  // ---------------------------------------------------------------------------
  Widget _buildConsistencyTrendCard(ThemeData theme) {
    final trendData = _calculateTrendData(_selectedPeriod);
    final spots = trendData.spots;
    final labels = trendData.labels;
    final tertiary = theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consistency Trend',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'No consistency data',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      const axisSpace = 34.0 + 12.0;
                      final extraSlot = trendData.pointSpacing > 0 &&
                              spots.length > 1
                          ? trendData.pointSpacing
                          : 0.0;
                      final naturalWidth = trendData.pointSpacing > 0 &&
                              spots.length > 1
                          ? axisSpace +
                              (spots.length - 1) * trendData.pointSpacing +
                              extraSlot
                          : constraints.maxWidth;
                      final chartWidth =
                          math.max(naturalWidth, constraints.maxWidth);

                      final chart = SizedBox(
                        width: chartWidth,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: trendData.pointSpacing > 0 && spots.length > 1
                                ? spots.length.toDouble()
                                : math.max(1, spots.length - 1).toDouble(),
                            minY: 0,
                            maxY: 110,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 25,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.25),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 34,
                                  interval: 25,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0 ||
                                        value == 25 ||
                                        value == 50 ||
                                        value == 75 ||
                                        value == 100) {
                                      return Text(
                                        '${value.toInt()}',
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.round();
                                    if (index >= 0 &&
                                        index < labels.length &&
                                        labels[index].isNotEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          labels[index],
                                          style: TextStyle(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                            fontSize: spots.length > 12
                                                ? 9
                                                : 10.5,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (touchedSpot) =>
                                    theme.colorScheme.surfaceContainerHighest,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      '${spot.y.toInt()}%',
                                      TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.5,
                                color: tertiary,
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                    radius: spots.length > 40 ? 0 : 4,
                                    color: tertiary,
                                    strokeWidth: 2,
                                    strokeColor: theme.cardTheme.color ??
                                        theme.colorScheme.surface,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: tertiary.withValues(alpha: 0.08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (chartWidth <= constraints.maxWidth) return chart;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: chart,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Habits Overview (Settings Style Grouped Corner Radii & Habit Colors)
  // ---------------------------------------------------------------------------
  Widget _buildHabitsOverview(ThemeData theme) {
    if (_habits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.fitness_center,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No habits yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Add habits to see your overview!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = _habits.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Habits Overview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(height: 3), // Settings inner gap
          _buildHabitOverviewCard(theme, _habits[i], i, total),
        ],
      ],
    );
  }

  Widget _buildHabitOverviewCard(
    ThemeData theme,
    Habit habit,
    int index,
    int total,
  ) {
    final completionDates = _habitCompletionDates[habit.id] ?? [];
    final bestStreak = _calculateBestStreak(completionDates);
    final allTimeDates = _allTimeDatesFor(habit);
    final allTimeStats = _calculateHabitStatsForDates(habit, allTimeDates);
    final rate = allTimeStats.target > 0
        ? (allTimeStats.done / allTimeStats.target * 100)
            .round()
            .clamp(0, 100)
        : 0;

    final borderRadius = _getGroupedBorderRadius(index, total);
    final cardBg = habit.cardBackground(theme.brightness);
    final habitScheme = habit.scheme(theme.brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Provider.of<ThemeProvider>(context, listen: false).triggerHaptic();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HabitDetailScreen(habit: habit),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              // Habit Icon in circular badge with mini progress ring
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (rate / 100.0).clamp(0.0, 1.0),
                      strokeWidth: 2.5,
                      backgroundColor:
                          habitScheme.onPrimaryContainer.withValues(alpha: 0.18),
                      color: habitScheme.onPrimaryContainer,
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: habit.scheme(theme.brightness).primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        habit.icon,
                        color: habit.scheme(theme.brightness).onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Middle: Habit Name and Top Flame Streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${allTimeStats.done}/',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: habitScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${allTimeStats.target} Target',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        // Bold divider dot (same as home habit card subtitle)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Text(
                          'Top ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const Text('🔥 ', style: TextStyle(fontSize: 12)),
                        Text(
                          '$bestStreak',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Completion percentage
              Text(
                '$rate%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Corner Radius Logic (Android Settings Grouped Style)
  // ---------------------------------------------------------------------------
  BorderRadius _getGroupedBorderRadius(int index, int total) {
    const outer = Radius.circular(20.0);
    const inner = Radius.circular(6.0);

    if (total <= 1) {
      return const BorderRadius.all(outer);
    }
    if (index == 0) {
      return const BorderRadius.only(
        topLeft: outer,
        topRight: outer,
        bottomLeft: inner,
        bottomRight: inner,
      );
    }
    if (index == total - 1) {
      return const BorderRadius.only(
        topLeft: inner,
        topRight: inner,
        bottomLeft: outer,
        bottomRight: outer,
      );
    }
    return const BorderRadius.all(inner);
  }

  // ---------------------------------------------------------------------------
  // Calculation Helpers for Periods
  // ---------------------------------------------------------------------------
  _PeriodStats _calculatePeriodStats(ProgressPeriod period) {
    final dates = _getDatesForPeriod(period);
    int totalDone = 0;
    int totalTarget = 0;

    for (final habit in _habits) {
      final habitStats = _calculateHabitStatsForDates(habit, dates);
      totalDone += habitStats.done;
      totalTarget += habitStats.target;
    }

    final healthPercentage = totalTarget > 0
        ? (totalDone / totalTarget * 100).round().clamp(0, 100)
        : 0;

    // Calculate Top Streak Habit
    Habit? topStreakHabit;
    int topStreak = 0;

    for (final habit in _habits) {
      final datesCompleted = _habitCompletionDates[habit.id] ?? [];
      final streak = _calculateBestStreak(datesCompleted);
      if (streak > topStreak) {
        topStreak = streak;
        topStreakHabit = habit;
      }
    }

    // If all streaks are 0 but habits exist, default top habit to first habit
    if (topStreakHabit == null && _habits.isNotEmpty) {
      topStreakHabit = _habits.first;
    }

    return _PeriodStats(
      totalDone: totalDone,
      totalTarget: totalTarget,
      healthPercentage: healthPercentage,
      topStreak: topStreak,
      topStreakHabit: topStreakHabit,
    );
  }

  _HabitPeriodStats _calculateHabitStatsForDates(Habit habit, List<DateTime> dates) {
    int done = 0;
    int target = 0;
    final progressMap = _habitCompletionProgress[habit.id] ?? {};

    for (final date in dates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final weekdayIndex = (normalizedDate.weekday - 1) % 7;
      final isScheduled = weekdayIndex < habit.repeatDays.length &&
          habit.repeatDays[weekdayIndex];

      if (isScheduled) {
        final freq = habit.frequencyPerDay > 0 ? habit.frequencyPerDay : 1;
        target += freq;
        final prog = progressMap[normalizedDate] ?? 0.0;
        done += (prog * freq).round();
      }
    }

    final rate = target > 0 ? (done / target * 100).round().clamp(0, 100) : 0;
    return _HabitPeriodStats(done: done, target: target, rate: rate);
  }

  List<DateTime> _allTimeDatesFor(Habit habit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final totalDays = today.difference(start).inDays + 1;
    return List.generate(
      totalDays > 0 ? totalDays : 1,
      (i) => start.add(Duration(days: i)),
    );
  }

  List<DateTime> _getDatesForPeriod(ProgressPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case ProgressPeriod.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

      case ProgressPeriod.thisMonth:
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        return List.generate(
          lastDay,
          (i) => DateTime(now.year, now.month, i + 1),
        );

      case ProgressPeriod.thisYear:
        final isLeap = (now.year % 4 == 0 && now.year % 100 != 0) || (now.year % 400 == 0);
        final totalDays = isLeap ? 366 : 365;
        final startOfYear = DateTime(now.year, 1, 1);
        return List.generate(
          totalDays,
          (i) => startOfYear.add(Duration(days: i)),
        );

      case ProgressPeriod.allTime:
        // Past 180 days (approx 6 months) for comprehensive all-time baseline
        return List.generate(
          180,
          (i) => today.subtract(Duration(days: 179 - i)),
        );
    }
  }

  _TrendData _calculateTrendData(ProgressPeriod period) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final labels = <String>[];
    var spacing = 0.0;

    switch (period) {
      case ProgressPeriod.thisWeek:
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));

        for (int i = 0; i < 7; i++) {
          final date = startOfWeek.add(Duration(days: i));
          labels.add(dayNames[i]);
          final stats = _calculateStatsForSingleDate(date);
          spots.add(FlSpot(i.toDouble(), stats.healthPercentage.toDouble()));
        }
        break;

      case ProgressPeriod.thisMonth:
        // Day-wise data for the entire month (1, 2, 3 ... on x-axis)
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        for (int d = 1; d <= lastDay; d++) {
          final date = DateTime(now.year, now.month, d);
          labels.add('$d');
          final stats = _calculateStatsForSingleDate(date);
          spots.add(FlSpot((d - 1).toDouble(), stats.healthPercentage.toDouble()));
        }
        spacing = 34;
        break;

      case ProgressPeriod.thisYear:
        final monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];

        for (int m = 1; m <= 12; m++) {
          labels.add(monthNames[m - 1]);
          final lastDay = DateTime(now.year, m + 1, 0).day;
          final dates = List.generate(
            lastDay,
            (d) => DateTime(now.year, m, d + 1),
          );

          int totalDone = 0;
          int totalTarget = 0;
          for (final habit in _habits) {
            final s = _calculateHabitStatsForDates(habit, dates);
            totalDone += s.done;
            totalTarget += s.target;
          }

          final rate = totalTarget > 0
              ? (totalDone / totalTarget * 100).round().clamp(0, 100)
              : 0;
          spots.add(FlSpot((m - 1).toDouble(), rate.toDouble()));
        }
        spacing = 52;
        break;

      case ProgressPeriod.allTime:
        // Day-wise data from the earliest habit's start till today.
        // x-axis marks each month (Jan, Feb, ...) at the 1st day of month.
        DateTime? earliest;
        for (final habit in _habits) {
          if (earliest == null || habit.createdAt.isBefore(earliest)) {
            earliest = habit.createdAt;
          }
        }
        final today = DateTime(now.year, now.month, now.day);
        final start = earliest != null
            ? DateTime(earliest.year, earliest.month, earliest.day)
            : today.subtract(const Duration(days: 29));

        final totalDays = today.difference(start).inDays + 1;
        var prevMonthKey = '';
        for (int i = 0; i < totalDays; i++) {
          final date = start.add(Duration(days: i));
          final monthKey = '${date.year}-${date.month}';
          var label = '';
          if (monthKey != prevMonthKey) {
            // First data point of a new calendar month gets the month label
            label = DateFormat('MMM').format(date);
            prevMonthKey = monthKey;
          }
          if (i == totalDays - 1) {
            label = DateFormat('d MMM').format(date);
          }
          labels.add(label);
          final stats = _calculateStatsForSingleDate(date);
          spots.add(FlSpot(i.toDouble(), stats.healthPercentage.toDouble()));
        }
        spacing = 16;
        break;
    }

    return _TrendData(spots: spots, labels: labels, pointSpacing: spacing);
  }

  _PeriodStats _calculateStatsForSingleDate(DateTime date) {
    int totalDone = 0;
    int totalTarget = 0;

    for (final habit in _habits) {
      final s = _calculateHabitStatsForDates(habit, [date]);
      totalDone += s.done;
      totalTarget += s.target;
    }

    final health = totalTarget > 0
        ? (totalDone / totalTarget * 100).round().clamp(0, 100)
        : 0;

    return _PeriodStats(
      totalDone: totalDone,
      totalTarget: totalTarget,
      healthPercentage: health,
      topStreak: 0,
      topStreakHabit: null,
    );
  }

  int _calculateBestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final sortedDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
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

// -----------------------------------------------------------------------------
// Custom Painter for Habit Health Circular Progress Arc
// -----------------------------------------------------------------------------
class _HabitHealthPainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _HabitHealthPainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 14.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * percentage.clamp(0.0, 1.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HabitHealthPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// -----------------------------------------------------------------------------
// Data Classes
// -----------------------------------------------------------------------------
class _PeriodStats {
  final int totalDone;
  final int totalTarget;
  final int healthPercentage;
  final int topStreak;
  final Habit? topStreakHabit;

  _PeriodStats({
    required this.totalDone,
    required this.totalTarget,
    required this.healthPercentage,
    required this.topStreak,
    required this.topStreakHabit,
  });
}

class _HabitPeriodStats {
  final int done;
  final int target;
  final int rate;

  _HabitPeriodStats({
    required this.done,
    required this.target,
    required this.rate,
  });
}

class _TrendData {
  final List<FlSpot> spots;
  final List<String> labels;
  final double pointSpacing;

  _TrendData({
    required this.spots,
    required this.labels,
    this.pointSpacing = 0,
  });
}
