import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';
import 'package:habit_bee/src/features/add_habit/presentation/add_habit_screen.dart';

enum HabitDetailPeriod { weekly, monthly, yearly, allTime }

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen>
    with WidgetsBindingObserver {
  late Habit _habit;
  HabitDetailPeriod _selectedPeriod = HabitDetailPeriod.weekly;
  bool _isLoading = true;
  String? _error;

  // Data
  List<DateTime> _completionDates = [];
  Map<DateTime, double> _completionProgress = {};
  Map<DateTime, String> _notes = {};
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    WidgetsBinding.instance.addObserver(this);
    _loadData();
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

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repository = Provider.of<HabitRepository>(context, listen: false);

      // Fetch fresh habit info in case it was edited
      final freshHabit = await repository.getHabit(_habit.id);
      if (freshHabit != null) {
        _habit = freshHabit;
      }

      final completions = await repository.getCompletionsForHabit(_habit.id);
      final completionDates = <DateTime>[];
      final progressMap = <DateTime, double>{};
      final notesMap = <DateTime, String>{};

      for (final completion in completions) {
        final date = DateTime(
          completion.date.year,
          completion.date.month,
          completion.date.day,
        );

        final note = completion.note;
        if (note != null && note.trim().isNotEmpty) {
          notesMap[date] = note;
        }

        if (completion.completed) {
          completionDates.add(date);
          progressMap[date] = 1.0;
        } else if (completion.completionCount > 0) {
          final freq = _habit.frequencyPerDay > 0 ? _habit.frequencyPerDay : 1;
          progressMap[date] = completion.completionCount / freq;
        }
      }

      if (mounted) {
        setState(() {
          _completionDates = completionDates;
          _completionProgress = progressMap;
          _notes = notesMap;
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

  Future<void> _openEditScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddHabitScreen(habit: _habit)),
    );
    if (result == true || mounted) {
      _loadData();
    }
  }

  void _shareHabit() {
    final periodStats = _calculatePeriodStats(_selectedPeriod);
    final text =
        'I am tracking "${_habit.name}" on HabitBee! '
        'My current streak is ${periodStats.currentStreak} days with '
        '${periodStats.completionRate.round()}% completion.';
    Share.share(text, subject: 'HabitBee Progress');
  }

  Future<void> _archiveHabit() async {
    try {
      final repository = Provider.of<HabitRepository>(context, listen: false);
      await repository.archiveHabit(_habit.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${_habit.name} archived')));
        // Pop back — the home screen refreshes itself on return, so the
        // archived habit disappears from the list immediately.
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error archiving habit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final habitScheme = _habit.scheme(theme.brightness);

    // Scaffold background: subtle tint in dark mode, standard background in light mode
    final scaffoldBg = isDark
        ? Color.alphaBlend(
            habitScheme.primary.withValues(alpha: 0.05),
            const Color(0xFF0D0D0D),
          )
        : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: MaterialLoadingIndicator(
                  size: 56,
                  color: habitScheme.primary,
                  style: LoadingStyle.wave,
                ),
              )
            : _error != null
            ? _buildErrorState(theme, habitScheme.primary)
            : RefreshIndicator(
                onRefresh: _loadData,
                color: habitScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Section (Back, Share, Edit icon, Circular Logo, Name, Category)
                      _buildTopSection(theme, habitScheme),
                      const SizedBox(height: 24),

                      // 2. Navigation Tabs (Weekly, Monthly, Yearly, All Time)
                      _buildNavigationTabs(theme, habitScheme),
                      const SizedBox(height: 28),

                      // 3. Middle Progress Section (Streaks left, Circle center, Times/Missed right)
                      _buildMiddleProgressSection(theme, habitScheme),
                      const SizedBox(height: 28),

                      // Summary Cards (Total Finished, Total Missed, Total Times)
                      _buildSummaryCards(theme, habitScheme),
                      const SizedBox(height: 32),

                      // 4. Statistics Section (Bar Chart)
                      _buildStatisticsSection(theme, habitScheme),
                      const SizedBox(height: 28),

                      // 5. Calendar Section (Themed TableCalendar)
                      _buildCalendarSection(theme, habitScheme),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Top Section
  // ---------------------------------------------------------------------------
  Widget _buildTopSection(ThemeData theme, ColorScheme habitScheme) {
    return Column(
      children: [
        // App bar icons row: Back on left; Archive, Share, Edit (pill) right
        Row(
          children: [
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back_rounded,
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              tooltip: 'Back',
            ),
            const Spacer(),
            // 1) Archive — plain icon.
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _archiveHabit();
              },
              icon: Icon(
                Icons.archive_outlined,
                color: theme.colorScheme.onSurface,
                size: 22,
              ),
              tooltip: 'Archive',
            ),
            // 2) Share — plain icon.
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _shareHabit();
              },
              icon: Icon(
                Icons.ios_share_rounded,
                color: theme.colorScheme.onSurface,
                size: 22,
              ),
              tooltip: 'Share',
            ),
            const SizedBox(width: 4),
            // 3) Edit — pill background, same color logic as the habit
            // logo: primaryContainer fill from THIS habit's own scheme.
            Tooltip(
              message: 'Edit Habit',
              child: Material(
                color: habitScheme.primaryContainer,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _openEditScreen();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: habitScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Round habit logo: Home card color logic (primaryContainer background, onPrimaryContainer icon, no shadow)
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: habitScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _habit.icon,
                color: habitScheme.onPrimaryContainer,
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Habit Name
        Text(
          _habit.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),

        // Category + Days pill pair, centered under the habit name.
        // Category pill keeps its fully-rounded LEFT corners; its right
        // corners are smoothed to 6px. The days pill mirrors this (6px on
        // the left, fully rounded on the right) with a 2px gap between them.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: habitScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Text(
                  _habit.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: habitScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            _buildDaysPill(theme, habitScheme),
          ],
        ),
      ],
    );
  }

  /// Days pill: "Everyday" when the reminder is off or every day is
  /// selected; otherwise the selected days separated by small dots.
  /// Uses the habit scheme's tertiary roles (same logic as the category
  /// pill, but tertiary instead of primary).
  Widget _buildDaysPill(ThemeData theme, ColorScheme habitScheme) {
    final textColor = habitScheme.onTertiaryContainer;
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w600,
    );
    final showEveryday =
        !_habit.reminderEnabled ||
        (_habit.repeatDays.length == 7 &&
            _habit.repeatDays.every((day) => day));

    Widget content;
    if (showEveryday) {
      content = Text('Everyday', style: textStyle);
    } else {
      const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final parts = <Widget>[];
      for (var i = 0; i < 7 && i < _habit.repeatDays.length; i++) {
        if (!_habit.repeatDays[i]) continue;
        if (parts.isNotEmpty) {
          // Same divider dot as the habit card, just smaller.
          parts.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }
        parts.add(Text(dayLabels[i], style: textStyle));
      }
      content = Row(mainAxisSize: MainAxisSize.min, children: parts);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: habitScheme.tertiaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          bottomLeft: Radius.circular(6),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: content,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Navigation Tabs (Weekly, Monthly, Yearly, All Time)
  // ---------------------------------------------------------------------------
  Widget _buildNavigationTabs(ThemeData theme, ColorScheme habitScheme) {
    final tabs = [
      (HabitDetailPeriod.weekly, 'Weekly'),
      (HabitDetailPeriod.monthly, 'Monthly'),
      (HabitDetailPeriod.yearly, 'Yearly'),
      (HabitDetailPeriod.allTime, 'All Time'),
    ];

    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: tabs.map((item) {
        final period = item.$1;
        final label = item.$2;
        final isSelected = _selectedPeriod == period;

        // Dark mode:
        // Active: background light (onPrimaryContainer), text dark (primaryContainer)
        // Inactive: background dark (primaryContainer), text light (onPrimaryContainer)
        // Light mode:
        // Active: background primary, text onPrimary
        // Inactive: background surfaceContainerHighest (0.5), text onSurfaceVariant
        final Color buttonBg;
        final Color textColor;

        if (isDark) {
          if (isSelected) {
            buttonBg = habitScheme.onTertiaryContainer;
            textColor = habitScheme.tertiaryContainer;
          } else {
            buttonBg = habitScheme.tertiaryContainer;
            textColor = habitScheme.onTertiaryContainer;
          }
        } else {
          if (isSelected) {
            buttonBg = habitScheme.tertiary;
            textColor = habitScheme.onTertiary;
          } else {
            buttonBg = habitScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            );
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
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).triggerHaptic();
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: textColor,
                      fontSize: 12,
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
  // 3. Middle Progress Section (Left: Streaks, Center: Circle, Right: Times)
  // ---------------------------------------------------------------------------
  Widget _buildMiddleProgressSection(ThemeData theme, ColorScheme habitScheme) {
    final periodStats = _calculatePeriodStats(_selectedPeriod);
    final completionRate = periodStats.completionRate;
    final currentStreak = periodStats.currentStreak;
    final bestStreak = periodStats.bestStreak;
    final completed = periodStats.completed;
    final missed = periodStats.missed;

    final periodPrefix = switch (_selectedPeriod) {
      HabitDetailPeriod.weekly => 'Weekly',
      HabitDetailPeriod.monthly => 'Monthly',
      HabitDetailPeriod.yearly => 'Yearly',
      HabitDetailPeriod.allTime => 'All Time',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Column: Current Streaks & Best Streaks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current\nStreaks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥 ', style: TextStyle(fontSize: 18)),
                    Text(
                      '$currentStreak',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Best\nStreaks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥 ', style: TextStyle(fontSize: 18)),
                    Text(
                      '$bestStreak',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Center: Large Circular Progress Bar - Progress page overview circle color logic
          SizedBox(
            width: 170,
            height: 170,
            child: CustomPaint(
              painter: _CircularGaugePainter(
                percentage: (completionRate / 100.0).clamp(0.0, 1.0),
                trackColor: habitScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                progressColor: habitScheme.primary,
                strokeWidth: 14,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${completionRate.round()}%',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 34,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total\nCompletion',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Column: Dynamic Completed & Missed
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$periodPrefix\nCompleted',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completed',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '$periodPrefix\nMissed',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$missed',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary Cards (Total Finished, Total Missed, Total Times)
  // ---------------------------------------------------------------------------
  Widget _buildSummaryCards(ThemeData theme, ColorScheme habitScheme) {
    final isDark = theme.brightness == Brightness.dark;
    final allTimeStats = _calculatePeriodStats(HabitDetailPeriod.allTime);

    // Card 1: Statistics background logic with tertiary color
    final tertiaryScheme = ColorScheme.fromSeed(
      seedColor: habitScheme.tertiary,
      brightness: theme.brightness,
    );
    final card1Bg = isDark
        ? tertiaryScheme.surfaceContainerLow
        : tertiaryScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    // Card 2 & 3: Statistics card background logic
    final card2And3Bg = _habit.cardBackground(theme.brightness);

    // Card 2: Material expressive soft danger color
    final softDangerColor = isDark
        ? const Color(0xFFFFB4AB)
        : const Color(0xFFBA1A1A);

    return Row(
      children: [
        // 1. Total Finished Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
            decoration: BoxDecoration(
              color: card1Bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark
                            ? habitScheme.tertiaryContainer
                            : habitScheme.tertiary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.sports_score_rounded,
                          size: 19,
                          color: isDark
                              ? habitScheme.onTertiaryContainer
                              : habitScheme.tertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${allTimeStats.completed}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: habitScheme.tertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Finished',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),

        // 2. Total Missed Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
            decoration: BoxDecoration(
              color: card2And3Bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B0000),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.event_busy_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${allTimeStats.missed}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: softDangerColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Missed',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),

        // 3. Total Times Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
            decoration: BoxDecoration(
              color: card2And3Bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark
                            ? habitScheme.primaryContainer
                            : habitScheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.repeat_rounded,
                          size: 19,
                          color: isDark
                              ? habitScheme.onPrimaryContainer
                              : habitScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${allTimeStats.target}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: habitScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Times',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Statistics Section (Bar Chart)
  // ---------------------------------------------------------------------------
  Widget _buildStatisticsSection(ThemeData theme, ColorScheme habitScheme) {
    final barData = _calculateBarChartData(_selectedPeriod, habitScheme);
    final periodTitle = switch (_selectedPeriod) {
      HabitDetailPeriod.weekly => 'Weekly Progress',
      HabitDetailPeriod.monthly => 'Monthly Progress',
      HabitDetailPeriod.yearly => 'Yearly Progress',
      HabitDetailPeriod.allTime => 'All Time Progress',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),

        // Bar Chart Card: Progress page calendar background logic & borderless
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _habit.cardBackground(theme.brightness),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                periodTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  const axisSpace = 38.0 + 16.0;
                  final naturalWidth =
                      barData.slotWidth > 0 && barData.labels.length > 7
                      ? axisSpace + barData.labels.length * barData.slotWidth
                      : constraints.maxWidth;
                  final chartWidth = math.max(
                    naturalWidth,
                    constraints.maxWidth,
                  );

                  final chart = SizedBox(
                    width: chartWidth,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 110,
                        minY: 0,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: habitScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            strokeWidth: 1,
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
                              reservedSize: 38,
                              interval: 25,
                              getTitlesWidget: (value, meta) {
                                if (value == 0 ||
                                    value == 25 ||
                                    value == 50 ||
                                    value == 75 ||
                                    value == 100) {
                                  return Text(
                                    '${value.toInt()}%',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
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
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < barData.labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      barData.labels[index],
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
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
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) =>
                                habitScheme.surfaceContainerHighest,
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
                        barGroups: barData.bars,
                      ),
                    ),
                  );

                  return SizedBox(
                    height: 210,
                    child: chartWidth > constraints.maxWidth
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: chart,
                          )
                        : chart,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Calendar Section (Themed TableCalendar)
  // ---------------------------------------------------------------------------
  Widget _buildCalendarSection(ThemeData theme, ColorScheme habitScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Calendar',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                });
              },
              icon: Icon(Icons.today_rounded, color: habitScheme.primary),
              tooltip: 'Today',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: _habit.cardBackground(theme.brightness),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => false,
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
                  color: habitScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                markerDecoration: BoxDecoration(
                  color: habitScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                weekendStyle: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildDefaultDayCell(context, theme, habitScheme, day);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildTodayDayCell(context, theme, habitScheme, day);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(theme, habitScheme.primaryContainer, 'Completed'),
            const SizedBox(width: 24),
            _buildLegendItem(
              theme,
              habitScheme.primaryContainer.withValues(alpha: 0.45),
              'Partial',
            ),
            const SizedBox(width: 24),
            _buildLegendItem(
              theme,
              theme.colorScheme.surfaceContainerHighest,
              'Missed',
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Calendar day cells (note-aware)
  // ---------------------------------------------------------------------------

  /// Wraps a day cell with the tiny top-right note icon (only when a note
  /// exists for that date) and the tap handler that opens the anchored
  /// note popup. Days without a note behave exactly like before.
  Widget _wrapWithNoteIndicator(
    BuildContext cellContext,
    ColorScheme habitScheme,
    DateTime day,
    Widget child,
  ) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    final note = _notes[normalizedDate];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: note == null
          ? null
          : () =>
                _showNotePopup(cellContext, habitScheme, normalizedDate, note),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          if (note != null)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(
                Icons.sticky_note_2_outlined,
                size: 10,
                color: habitScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultDayCell(
    BuildContext cellContext,
    ThemeData theme,
    ColorScheme habitScheme,
    DateTime day,
  ) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    final progress = _completionProgress[normalizedDate] ?? 0.0;

    // No progress: replicate the calendar's default look (plain day number)
    // so note icons can still show on untouched days.
    if (progress <= 0) {
      return _wrapWithNoteIndicator(
        cellContext,
        habitScheme,
        day,
        Center(
          child: Text(
            '${day.day}',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
      );
    }

    final isCompleted = progress >= 1.0;

    return _wrapWithNoteIndicator(
      cellContext,
      habitScheme,
      day,
      Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isCompleted
              ? habitScheme.primaryContainer
              : habitScheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: habitScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayDayCell(
    BuildContext cellContext,
    ThemeData theme,
    ColorScheme habitScheme,
    DateTime day,
  ) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    final progress = _completionProgress[normalizedDate] ?? 0.0;
    final isCompleted = progress >= 1.0;

    if (isCompleted) {
      return _wrapWithNoteIndicator(
        cellContext,
        habitScheme,
        day,
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: habitScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: habitScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return _wrapWithNoteIndicator(
      cellContext,
      habitScheme,
      day,
      Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: progress > 0
              ? habitScheme.primaryContainer.withValues(alpha: 0.45)
              : habitScheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: habitScheme.primary, width: 1.5),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: habitScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the saved note in a Material popup anchored next to the tapped
  /// calendar date (not centered). Tapping anywhere outside — or the X
  /// button — closes it. Colors follow this habit's color scheme.
  void _showNotePopup(
    BuildContext cellContext,
    ColorScheme habitScheme,
    DateTime date,
    String note,
  ) {
    final renderBox = cellContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final cellOffset = renderBox.localToGlobal(Offset.zero);
    final cellSize = renderBox.size;
    final baseTheme = Theme.of(context);

    Provider.of<ThemeProvider>(context, listen: false).triggerHaptic();

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true, // touching anywhere outside closes it
      barrierLabel: 'Note',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final screenSize = MediaQuery.of(dialogContext).size;
        const popupWidth = 260.0;
        const popupMaxHeight = 200.0;

        // Horizontally center the popup on the date cell, clamped on screen.
        final left = (cellOffset.dx + cellSize.width / 2 - popupWidth / 2)
            .clamp(12.0, screenSize.width - popupWidth - 12);

        // Prefer below the cell; flip above when there isn't enough room.
        final below = cellOffset.dy + cellSize.height + 8;
        final fitsBelow = below + popupMaxHeight <= screenSize.height - 12;
        final top = fitsBelow
            ? below
            : (cellOffset.dy - 8 - popupMaxHeight).clamp(
                12.0,
                screenSize.height,
              );

        return Stack(
          children: [
            Positioned(
              left: left.toDouble(),
              top: top.toDouble(),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: popupWidth,
                  constraints: const BoxConstraints(maxHeight: popupMaxHeight),
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 14),
                  decoration: BoxDecoration(
                    color: habitScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: habitScheme.primary.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 16,
                            color: habitScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              DateFormat('d MMM yyyy').format(date),
                              style: baseTheme.textTheme.bodySmall?.copyWith(
                                color: habitScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: habitScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Text(
                            note,
                            style: baseTheme.textTheme.bodyMedium?.copyWith(
                              color: habitScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading habit details',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text('Retry', style: TextStyle(color: _habit.onColor)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Calculations for Period Stats & Bar Chart
  // ---------------------------------------------------------------------------
  _HabitCalculatedStats _calculatePeriodStats(HabitDetailPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final habitCreated = DateTime(
      _habit.createdAt.year,
      _habit.createdAt.month,
      _habit.createdAt.day,
    );
    final daysSinceCreation = today.difference(habitCreated).inDays;

    DateTime startDate;

    switch (period) {
      case HabitDetailPeriod.weekly:
        startDate = today.subtract(Duration(days: today.weekday - 1));
        break;
      case HabitDetailPeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case HabitDetailPeriod.yearly:
        if (daysSinceCreation >= 365) {
          startDate = DateTime(now.year, 1, 1);
        } else {
          startDate = habitCreated;
        }
        break;
      case HabitDetailPeriod.allTime:
        startDate = habitCreated;
        break;
    }

    if (startDate.isBefore(habitCreated)) {
      startDate = habitCreated;
    }

    final totalDays = today.difference(startDate).inDays + 1;
    final dates = List.generate(
      totalDays > 0 ? totalDays : 1,
      (i) => startDate.add(Duration(days: i)),
    );

    int completed = 0;
    int target = 0;

    for (final date in dates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final weekdayIndex = (normalizedDate.weekday - 1) % 7;
      final isScheduled =
          weekdayIndex < _habit.repeatDays.length &&
          _habit.repeatDays[weekdayIndex];

      if (isScheduled) {
        final freq = _habit.frequencyPerDay > 0 ? _habit.frequencyPerDay : 1;
        target += freq;
        final prog = _completionProgress[normalizedDate] ?? 0.0;
        completed += (prog * freq).round();
      }
    }

    final missed = (target - completed).clamp(0, 999999);
    final rate = target > 0
        ? (completed / target * 100.0).clamp(0.0, 100.0)
        : 0.0;

    final currentStreak = _calculateStreak(_completionDates);
    final bestStreak = _calculateBestStreak(_completionDates);

    return _HabitCalculatedStats(
      completed: completed,
      target: target,
      missed: missed,
      completionRate: rate,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }

  // Completion % for a date range, clamped to the habit's lifetime.
  double _bucketPct(DateTime start, DateTime end) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final created = DateTime(
      _habit.createdAt.year,
      _habit.createdAt.month,
      _habit.createdAt.day,
    );

    var from = DateTime(start.year, start.month, start.day);
    var to = DateTime(end.year, end.month, end.day);
    if (from.isBefore(created)) from = created;
    if (to.isAfter(today)) to = today;
    if (from.isAfter(to)) return 0;

    final freq = _habit.frequencyPerDay > 0 ? _habit.frequencyPerDay : 1;
    double comp = 0;
    int tgt = 0;
    for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
      final weekdayIdx = (d.weekday - 1) % 7;
      if (weekdayIdx < _habit.repeatDays.length &&
          _habit.repeatDays[weekdayIdx]) {
        tgt += freq;
        comp += (_completionProgress[d] ?? 0.0) * freq;
      }
    }
    return tgt > 0 ? (comp / tgt * 100).clamp(0.0, 100.0) : 0;
  }

  BarChartGroupData _makeBar(int x, double pct, double width, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: pct,
          color: pct > 0 ? color : Colors.transparent,
          width: width,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  _HabitBarData _calculateBarChartData(
    HabitDetailPeriod period,
    ColorScheme habitScheme,
  ) {
    final now = DateTime.now();
    final bars = <BarChartGroupData>[];
    final labels = <String>[];
    // Single bar color, same logic as the middle progress circle fill.
    final barColor = habitScheme.primary;
    var slotWidth = 0.0;

    switch (period) {
      case HabitDetailPeriod.weekly:
        final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));

        for (int i = 0; i < 7; i++) {
          final date = startOfWeek.add(Duration(days: i));
          labels.add(dayLetters[i]);

          final normalizedDate = DateTime(date.year, date.month, date.day);
          final progress = _completionProgress[normalizedDate] ?? 0.0;
          final pct = (progress * 100).clamp(0.0, 100.0);
          bars.add(_makeBar(i, pct, 22, barColor));
        }
        break;

      case HabitDetailPeriod.monthly:
        // One bar per month of the current year (Jan..current month)
        slotWidth = 44;
        for (int m = 1; m <= now.month; m++) {
          labels.add(DateFormat('MMM').format(DateTime(now.year, m)));
          final pct = _bucketPct(
            DateTime(now.year, m, 1),
            DateTime(now.year, m + 1, 0),
          );
          bars.add(_makeBar(m - 1, pct, 26, barColor));
        }
        break;

      case HabitDetailPeriod.yearly:
        // One bar per year (2024, 2025, 2026 ...) since the habit started
        slotWidth = 72;
        final firstYear = _habit.createdAt.year;
        var index = 0;
        for (int y = firstYear; y <= now.year; y++) {
          labels.add('$y');
          final pct = _bucketPct(DateTime(y, 1, 1), DateTime(y, 12, 31));
          bars.add(_makeBar(index, pct, 36, barColor));
          index++;
        }
        break;

      case HabitDetailPeriod.allTime:
        // Habit younger than a year -> month-wise bars, older -> year-wise
        final created = _habit.createdAt;
        final monthsCount =
            (now.year - created.year) * 12 + (now.month - created.month) + 1;

        if (monthsCount <= 14) {
          slotWidth = 44;
          var index = 0;
          var cursor = DateTime(created.year, created.month, 1);
          final lastBucket = DateTime(now.year, now.month, 1);
          while (!cursor.isAfter(lastBucket)) {
            labels.add(DateFormat('MMM').format(cursor));
            final pct = _bucketPct(
              cursor,
              DateTime(cursor.year, cursor.month + 1, 0),
            );
            bars.add(_makeBar(index, pct, 26, barColor));
            index++;
            cursor = DateTime(cursor.year, cursor.month + 1, 1);
          }
        } else {
          slotWidth = 72;
          var index = 0;
          for (int y = created.year; y <= now.year; y++) {
            labels.add('$y');
            final pct = _bucketPct(DateTime(y, 1, 1), DateTime(y, 12, 31));
            bars.add(_makeBar(index, pct, 36, barColor));
            index++;
          }
        }
        break;
    }

    return _HabitBarData(bars: bars, labels: labels, slotWidth: slotWidth);
  }

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final sortedDates =
        dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
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

    final sortedDates =
        dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
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
// Custom Circular Progress Gauge
// -----------------------------------------------------------------------------
class _CircularGaugePainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularGaugePainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

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
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// -----------------------------------------------------------------------------
// Helper Classes
// -----------------------------------------------------------------------------
class _HabitCalculatedStats {
  final int completed;
  final int target;
  final int missed;
  final double completionRate;
  final int currentStreak;
  final int bestStreak;

  _HabitCalculatedStats({
    required this.completed,
    required this.target,
    required this.missed,
    required this.completionRate,
    required this.currentStreak,
    required this.bestStreak,
  });
}

class _HabitBarData {
  final List<BarChartGroupData> bars;
  final List<String> labels;
  final double slotWidth;

  _HabitBarData({required this.bars, required this.labels, this.slotWidth = 0});
}
