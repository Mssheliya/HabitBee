import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';

enum DetailViewType { daily, weekly, monthly, overall }

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({
    super.key,
    required this.habit,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  DetailViewType _selectedView = DetailViewType.daily;
  bool _isLoading = true;
  String? _error;

  // Data
  List<DateTime> _completionDates = [];
  Map<DateTime, double> _completionProgress = {};
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalCompleted = 0;
  int _totalMissed = 0;
  double _completionRate = 0.0;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
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

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedView = DetailViewType.values[_tabController.index];
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repository = Provider.of<HabitRepository>(context, listen: false);
      final completions = await repository.getCompletionsForHabit(widget.habit.id);

      final completionDates = <DateTime>[];
      final progressMap = <DateTime, double>{};

      for (final completion in completions) {
        final date = DateTime(
          completion.date.year,
          completion.date.month,
          completion.date.day,
        );

        if (completion.completed) {
          completionDates.add(date);
          progressMap[date] = 1.0;
        } else if (completion.completionCount > 0) {
          progressMap[date] = completion.completionCount / widget.habit.frequencyPerDay;
        }
      }

      // Calculate stats based on selected view
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedView) {
        case DetailViewType.daily:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case DetailViewType.weekly:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case DetailViewType.monthly:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case DetailViewType.overall:
          startDate = widget.habit.createdAt;
          break;
      }

      // Filter dates based on view
      final filteredProgressEntries = progressMap.entries
          .where((entry) => entry.key.isAfter(startDate) || entry.key.isAtSameMomentAs(startDate))
          .toList();

      final totalDays = now.difference(startDate).inDays + 1;
      
      // For daily view, calculate percentage based on today's completion count
      double completionRate;
      if (_selectedView == DetailViewType.daily) {
        final today = DateTime(now.year, now.month, now.day);
        final todayProgress = progressMap[today] ?? 0.0;
        completionRate = todayProgress * 100;
      } else {
        // For other views, use the sum of progress divided by total days
        final totalProgress = filteredProgressEntries.fold<double>(
          0.0,
          (sum, entry) => sum + entry.value,
        );
        completionRate = totalDays > 0 ? (totalProgress / totalDays) * 100 : 0.0;
      }

      final completedDays = progressMap.entries
          .where((entry) => entry.value >= 1.0)
          .where((entry) => entry.key.isAfter(startDate) || entry.key.isAtSameMomentAs(startDate))
          .length;
      final missedDays = totalDays - completedDays;

      // For daily view, show today's completion count
      int totalCompleted;
      if (_selectedView == DetailViewType.daily) {
        final today = DateTime(now.year, now.month, now.day);
        final todayProgress = progressMap[today] ?? 0.0;
        totalCompleted = (todayProgress * widget.habit.frequencyPerDay).round();
      } else {
        totalCompleted = completedDays;
      }

      if (mounted) {
        setState(() {
          _completionDates = completionDates;
          _completionProgress = progressMap;
          _currentStreak = _calculateStreak(completionDates);
          _bestStreak = _calculateBestStreak(completionDates);
          _totalCompleted = totalCompleted;
          _totalMissed = missedDays > 0 ? missedDays : 0;
          _completionRate = completionRate;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading habit details: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final sortedDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

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

    final sortedDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitColor = widget.habit.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, habitColor),
            _buildTabBar(theme, habitColor),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: MaterialLoadingIndicator(
                        size: 56,
                        color: habitColor,
                        style: LoadingStyle.wave,
                      ),
                    )
                  : _error != null
                      ? _buildErrorState(theme)
                      : _buildBody(theme, habitColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color habitColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            habitColor.withOpacity(0.3),
            habitColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: habitColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.habit.icon,
                  color: habitColor,
                  size: 28,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.habit.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.habit.category,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, Color habitColor) {
    return Container(
      color: theme.cardTheme.color,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        indicatorColor: habitColor,
        indicatorWeight: 3,
        labelColor: habitColor,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Daily'),
          Tab(text: 'Weekly'),
          Tab(text: 'Monthly'),
          Tab(text: 'Overall'),
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

  Widget _buildBody(ThemeData theme, Color habitColor) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: habitColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainStats(theme, habitColor),
            const SizedBox(height: 24),
            _buildStatsGrid(theme, habitColor),
            const SizedBox(height: 24),
            _buildStatisticsSection(theme, habitColor),
            const SizedBox(height: 24),
            _buildCalendarSection(theme, habitColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStats(ThemeData theme, Color habitColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            habitColor.withOpacity(0.2),
            habitColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: habitColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completion Rate',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_completionRate.toStringAsFixed(1)}%',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: habitColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getViewLabel(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildCircularProgress(habitColor),
          ),
        ],
      ),
    );
  }

  String _getViewLabel() {
    switch (_selectedView) {
      case DetailViewType.daily:
        return 'Today';
      case DetailViewType.weekly:
        return 'Last 7 days';
      case DetailViewType.monthly:
        return 'This month';
      case DetailViewType.overall:
        return 'All time';
    }
  }

  Widget _buildCircularProgress(Color habitColor) {
    return Container(
      width: 100,
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: _completionRate / 100,
            strokeWidth: 10,
            backgroundColor: habitColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(habitColor),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.habit.icon,
                  color: habitColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, Color habitColor) {
    final isDailyView = _selectedView == DetailViewType.daily;
    final completedValue = isDailyView 
        ? '$_totalCompleted/${widget.habit.frequencyPerDay}'
        : '$_totalCompleted';
    final completedUnit = isDailyView ? 'today' : 'times';
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          theme,
          habitColor,
          'Current Streak',
          '$_currentStreak',
          'days',
          Icons.local_fire_department,
        ),
        _buildStatCard(
          theme,
          habitColor,
          'Best Streak',
          '$_bestStreak',
          'days',
          Icons.emoji_events,
        ),
        _buildStatCard(
          theme,
          habitColor,
          'Completed',
          completedValue,
          completedUnit,
          Icons.check_circle,
        ),
        _buildStatCard(
          theme,
          habitColor,
          'Missed',
          '$_totalMissed',
          'times',
          Icons.cancel,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    Color habitColor,
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: habitColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(ThemeData theme, Color habitColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              _buildStatRow(
                theme,
                'Completion Rate',
                '${_completionRate.toStringAsFixed(1)}%',
                habitColor,
              ),
              const Divider(height: 24),
              _buildStatRow(
                theme,
                'Total Completions',
                '$_totalCompleted',
                habitColor,
              ),
              const Divider(height: 24),
              _buildStatRow(
                theme,
                'Total Missed',
                '$_totalMissed',
                habitColor,
              ),
              const Divider(height: 24),
              _buildStatRow(
                theme,
                'Current Streak',
                '$_currentStreak days',
                habitColor,
              ),
              const Divider(height: 24),
              _buildStatRow(
                theme,
                'Best Streak',
                '$_bestStreak days',
                habitColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    ThemeData theme,
    String label,
    String value,
    Color accentColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection(ThemeData theme, Color habitColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Calendar',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                });
              },
              icon: Icon(
                Icons.today,
                color: habitColor,
              ),
              tooltip: 'Go to today',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
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
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return false;
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                holidayTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                todayDecoration: BoxDecoration(
                  color: habitColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                markerDecoration: BoxDecoration(
                  color: habitColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: theme.colorScheme.onSurface,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: theme.textTheme.bodySmall!,
                weekendStyle: theme.textTheme.bodySmall!,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final normalizedDate = DateTime(day.year, day.month, day.day);
                  final progress = _completionProgress[normalizedDate] ?? 0.0;

                  if (progress <= 0) return null;

                  final isCompleted = progress >= 1.0;

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? habitColor
                          : habitColor.withOpacity(progress * 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCompleted ? AppTheme.black : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(theme, habitColor, 'Completed'),
            const SizedBox(width: 24),
            _buildLegendItem(theme, habitColor.withOpacity(0.5), 'Partial'),
            const SizedBox(width: 24),
            _buildLegendItem(theme, theme.colorScheme.surfaceContainerHighest, 'Missed'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
