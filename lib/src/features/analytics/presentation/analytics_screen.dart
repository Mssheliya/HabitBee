import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => AnalyticsScreenState();
}

class AnalyticsScreenState extends State<AnalyticsScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  String _selectedPeriod = 'Weekly';
  final List<String> _periods = ['Daily', 'Weekly', 'Monthly', 'Overall'];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> _habitPerformance = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStats();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  // Public method to refresh data from outside
  void refreshData() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final repository = Provider.of<HabitRepository>(context, listen: false);
      
      // Load overall stats
      final stats = await repository.getOverallStats();
      
      // Load chart data based on selected period
      List<Map<String, dynamic>> chartData = [];
      switch (_selectedPeriod) {
        case 'Daily':
          // For daily view, show hourly breakdown (mock data since we don't track hours)
          chartData = await repository.getDailyStatsDetailed(DateTime.now());
          break;
        case 'Weekly':
          chartData = await repository.getWeeklyStats(DateTime.now());
          break;
        case 'Monthly':
          chartData = await repository.getMonthlyStats(DateTime.now());
          break;
        case 'Overall':
          chartData = await repository.getAllTimeStats();
          break;
        default:
          chartData = await repository.getWeeklyStats(DateTime.now());
      }
      
      // Load habit performance stats
      final habits = await repository.getActiveHabits();
      final habitPerformance = <Map<String, dynamic>>[];
      
      for (final habit in habits) {
        final habitStats = await repository.getHabitStats(habit.id);
        final habitStreaks = await repository.getHabitStreaks(habit.id);
        habitPerformance.add({
          'habit': habit,
          'completionRate': habitStats['completionRate'],
          'completedDays': habitStats['completedDays'],
          'totalDays': habitStats['totalDays'],
          'currentStreak': habitStreaks['currentStreak'],
          'bestStreak': habitStreaks['bestStreak'],
        });
      }
      
      // Sort by completion rate (highest first)
      habitPerformance.sort((a, b) => (b['completionRate'] as int).compareTo(a['completionRate'] as int));
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _chartData = chartData;
          _habitPerformance = habitPerformance;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analytics',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        items: _periods.map((period) {
                          return DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null && value != _selectedPeriod) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                            _loadStats();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: MaterialLoadingIndicator(
          size: 56,
          color: theme.colorScheme.primary,
          style: LoadingStyle.rotatingDots,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading analytics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadStats, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildOverviewCards(theme),
            const SizedBox(height: 24),
            _buildCompletionChart(theme),
            const SizedBox(height: 24),
            _buildHabitStatsList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(ThemeData theme) {
    final partialCompletions = _stats['partialCompletions'] ?? 0;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Total Habits',
                '${_stats['totalHabits'] ?? 0}',
                Icons.list_alt,
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                theme,
                'Completion Rate',
                '${_stats['overallCompletionRate'] ?? 0}%',
                Icons.trending_up,
                const Color(0xFFB5EAD7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Current Streak',
                '${_stats['currentStreak'] ?? 0}',
                Icons.local_fire_department,
                const Color(0xFFFFB7B2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                theme,
                'Best Streak',
                '${_stats['bestStreak'] ?? 0}',
                Icons.emoji_events,
                const Color(0xFFFFDAC1),
              ),
            ),
          ],
        ),
        if (partialCompletions > 0) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Partial Progress',
                  '$partialCompletions days',
                  Icons.timelapse,
                  const Color(0xFFFFE082),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(), // Empty placeholder for alignment
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionChart(ThemeData theme) {
    if (_chartData.isEmpty) {
      return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getChartTitle(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 60),
            Center(
              child: Text(
                'No data available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      );
    }

    // Get labels based on period
    final labels = _getChartLabels();
    
    // Calculate how many data points to show based on period
    final displayData = _chartData;
    
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getChartTitle(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => theme.colorScheme.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}%',
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          // Show fewer labels for monthly/overall view
                          if (_selectedPeriod == 'Monthly' && index % 5 != 0) {
                            return const SizedBox.shrink();
                          }
                          if (_selectedPeriod == 'Overall' && index % 30 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.surfaceContainerHighest,
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: List.generate(displayData.length, (index) {
                  final completionRate = (displayData[index]['completionRate'] as int).toDouble();
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: completionRate,
                        color: _getBarColor(index, theme),
                        width: _getBarWidth(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (_selectedPeriod) {
      case 'Daily':
        return 'Today\'s Progress';
      case 'Weekly':
        return 'Weekly Progress';
      case 'Monthly':
        return 'Monthly Progress (Last 30 Days)';
      case 'Overall':
        return 'All Time Progress';
      default:
        return 'Progress';
    }
  }

  List<String> _getChartLabels() {
    return _chartData.map((stat) {
      final date = stat['date'] as DateTime;
      switch (_selectedPeriod) {
        case 'Daily':
          return '${date.hour}:00';
        case 'Weekly':
          return ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7];
        case 'Monthly':
        case 'Overall':
          return DateFormat('MMM d').format(date);
        default:
          return '';
      }
    }).toList();
  }

  Color _getBarColor(int index, ThemeData theme) {
    final baseColor = theme.colorScheme.primary;
    switch (_selectedPeriod) {
      case 'Daily':
        return baseColor.withOpacity(0.7 + (index * 0.05));
      case 'Weekly':
        return baseColor.withOpacity(0.7 + (index * 0.05));
      case 'Monthly':
      case 'Overall':
        // Use gradient-like effect
        return Color.lerp(
          baseColor.withOpacity(0.5),
          baseColor,
          index / _chartData.length,
        )!;
      default:
        return baseColor;
    }
  }

  double _getBarWidth() {
    switch (_selectedPeriod) {
      case 'Daily':
        return 30;
      case 'Weekly':
        return 20;
      case 'Monthly':
        return 6;
      case 'Overall':
        return 3;
      default:
        return 20;
    }
  }

  Widget _buildHabitStatsList(ThemeData theme) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habit Performance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (_habitPerformance.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No habits yet. Add some habits to see performance!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ..._habitPerformance.map((performance) {
              final habit = performance['habit'] as dynamic;
              final completionRate = performance['completionRate'] as int;
              final currentStreak = performance['currentStreak'] as int;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPerformanceItem(
                  theme,
                  habit.name,
                  completionRate,
                  currentStreak,
                  habit.color,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(
    ThemeData theme,
    String name,
    int percentage,
    int streak,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                if (streak > 0) ...[
                  Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: const Color(0xFFFF6B35),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  '$percentage%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// Extension methods for repository
extension HabitRepositoryExtension on HabitRepository {
  Future<List<Map<String, dynamic>>> getDailyStatsDetailed(DateTime date) async {
    // For daily view, we show the completion status for each habit
    final habits = await getActiveHabits();
    final completions = await getCompletionsForDate(date);
    
    final List<Map<String, dynamic>> hourlyStats = [];
    
    // Create 6 time blocks for the day
    for (int i = 0; i < 6; i++) {
      final completedCount = completions.where((c) => c.completed).length;
      final totalHabits = habits.length;
      
      hourlyStats.add({
        'date': DateTime(date.year, date.month, date.day, i * 4),
        'completionRate': totalHabits > 0 ? (completedCount / totalHabits * 100).round() : 0,
        'completedCount': completedCount,
        'totalHabits': totalHabits,
      });
    }
    
    return hourlyStats;
  }
}
