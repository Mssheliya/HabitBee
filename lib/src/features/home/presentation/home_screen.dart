import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';
import 'package:habit_bee/src/features/home/presentation/widgets/habit_tile.dart';
import 'package:habit_bee/src/features/add_habit/presentation/add_habit_screen.dart';
import 'package:habit_bee/src/features/habit_detail/presentation/habit_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Habit> _habits = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Habit> get _filteredHabits {
    var list = _habits;
    if (_selectedCategory != null) {
      list = list
          .where((habit) => habit.category == _selectedCategory)
          .toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list
          .where(
            (h) =>
                h.name.toLowerCase().contains(q) ||
                h.category.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  List<String> get _availableCategories {
    final categories = _habits.map((h) => h.category).toSet().toList();
    categories.sort();
    return categories;
  }

  @override
  void initState() {
    super.initState();
    // Normalize the initial date to remove time component
    _selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHabits();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Public method to refresh habits from outside
  void refreshHabits() {
    debugPrint('HomeScreen: refreshHabits called');
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repository = Provider.of<HabitRepository>(context, listen: false);
      final habits = await repository.getActiveHabits();

      if (mounted) {
        setState(() {
          _habits = habits;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading habits: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onDateSelected(DateTime date) {
    // Normalize the date to remove time component for consistent comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_selectedDate != normalizedDate) {
      setState(() {
        _selectedDate = normalizedDate;
      });
    }
  }

  Future<void> _toggleHabit(Habit habit) async {
    // Note: The actual toggle logic is handled in HabitTile._handleToggle()
    // This method is only called as a callback to refresh the UI
    try {
      await _loadHabits();
    } catch (e) {
      debugPrint('Error refreshing habits: $e');
    }
  }

  void _openHabitDetail(Habit habit) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)),
        )
        .then((_) => _loadHabits());
  }

  void _addNewHabit() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddHabitScreen()))
        .then((result) {
          if (result == true) {
            _loadHabits();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'HomeScreen: building, isLoading=$_isLoading, habits=${_habits.length}',
    );
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSearchBar(theme),
            const SizedBox(height: 16),
            if (_availableCategories.length > 1) _buildCategoryFilter(theme),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(theme)),
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
          style: LoadingStyle.pulse,
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
            Text('Error loading habits', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadHabits, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_habits.isEmpty) {
      return _buildEmptyState(theme);
    }

    if (_filteredHabits.isEmpty) {
      return _buildEmptyFilterState(theme);
    }

    return _buildHabitList();
  }

  Widget _buildEmptyFilterState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.filter_list_off,
              size: 50,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No habits in "$_selectedCategory"',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a different category or add new habits',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _selectedCategory = null),
            icon: const Icon(Icons.filter_list),
            label: const Text('View All'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final dayStr = DateFormat('d').format(now);
    final monthStr = DateFormat('MMM').format(now).toUpperCase();

    // Date number keeps the DARK theme's tertiary tone in BOTH themes —
    // the light theme does not switch it to the darker light-mode tone.
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final dateNumberColor = AppTheme.generateColorScheme(
      seedColor: AppTheme.getSeedColor(themeProvider.settings),
      brightness: Brightness.dark,
      variant: themeProvider.dynamicSchemeVariant,
    ).tertiary;

    // Progress page calendar background logic:
    final searchBarBg =
        theme.cardTheme.color ??
        (isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Search bar container
          Expanded(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: searchBarBg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  // Left side square date badge (pitch black)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.primaryContainer,
                        width: 4,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayStr,
                          style: TextStyle(
                            color: dateNumberColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorScheme.primaryContainer,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            monthStr,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 8,
                              letterSpacing: 0.5,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Search text input
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        hintText: 'Search habits',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right side Add Habit Button (tertiary color logic)
          GestureDetector(
            onTap: () {
              Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).triggerHaptic();
              _addNewHabit();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.add_rounded,
                color: colorScheme.onTertiaryContainer,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colorScheme = theme.colorScheme;

    Widget buildPill({
      required String label,
      required bool isSelected,
      IconData? icon,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              themeProvider.triggerHaptic();
              onTap();
            },
            borderRadius: BorderRadius.circular(28),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 17,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _availableCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return buildPill(
              label: 'All',
              icon: _selectedCategory == null
                  ? Icons.check_rounded
                  : Icons.apps_rounded,
              isSelected: _selectedCategory == null,
              onTap: () => setState(() => _selectedCategory = null),
            );
          }

          final category = _availableCategories[index - 1];
          final isSelected = _selectedCategory == category;
          return buildPill(
            label: category,
            icon: isSelected ? Icons.check_rounded : null,
            isSelected: isSelected,
            onTap: () => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildHabitList() {
    return RefreshIndicator(
      onRefresh: _loadHabits,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filteredHabits.length,
        itemBuilder: (context, index) {
          final habit = _filteredHabits[index];
          return HabitTile(
            key: ValueKey('${habit.id}_${_selectedDate.toIso8601String()}'),
            habit: habit,
            date: _selectedDate,
            onToggle: () => _toggleHabit(habit),
            onTap: () => _openHabitDetail(habit),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_task_rounded,
              size: 60,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Habits Yet',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first habit',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewHabit,
            icon: const Icon(Icons.add),
            label: const Text('Add Habit'),
          ),
        ],
      ),
    );
  }
}
