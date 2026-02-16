import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/core/constants/app_constants.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';
import 'package:habit_bee/src/features/home/presentation/widgets/habit_tile.dart';
import 'package:habit_bee/src/features/add_habit/presentation/add_habit_screen.dart';

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

  List<Habit> get _filteredHabits {
    if (_selectedCategory == null) return _habits;
    return _habits.where((habit) => habit.category == _selectedCategory).toList();
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
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHabits();
    });
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

  void _editHabit(Habit habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddHabitScreen(habit: habit),
      ),
    ).then((_) => _loadHabits());
  }

  void _addNewHabit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddHabitScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadHabits();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('HomeScreen: building, isLoading=$_isLoading, habits=${_habits.length}');
    final theme = Theme.of(context);
    final isToday = DateTime.now().difference(_selectedDate).inDays == 0;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, isToday, themeProvider),
            const SizedBox(height: 16),
            if (_availableCategories.length > 1) _buildCategoryFilter(theme),
            const SizedBox(height: 16),
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
            Text(
              'Error loading habits',
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
              onPressed: _loadHabits,
              child: const Text('Retry'),
            ),
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

  Widget _buildHeader(ThemeData theme, bool isToday, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? 'Today' : DateFormat('EEEE').format(_selectedDate),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(_selectedDate),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // All categories chip
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _selectedCategory == null,
                showCheckmark: false,
                avatar: _selectedCategory == null
                    ? Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.onPrimary,
                        size: 18,
                      )
                    : Icon(
                        Icons.apps_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                label: const Text('All'),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _selectedCategory == null
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                selectedColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: _selectedCategory == null ? 2 : 0,
                onSelected: (_) => setState(() => _selectedCategory = null),
              ),
            );
          }

          final category = _availableCategories[index - 1];
          final isSelected = _selectedCategory == category;
          final categoryColor = _getCategoryColor(category, theme);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                selected: isSelected,
                showCheckmark: false,
                avatar: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : categoryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                label: Text(category),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                ),
                backgroundColor: categoryColor.withOpacity(0.15),
                selectedColor: categoryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: isSelected ? 3 : 0,
                shadowColor: isSelected ? categoryColor.withOpacity(0.5) : null,
                side: BorderSide(
                  color: isSelected
                      ? categoryColor
                      : categoryColor.withOpacity(0.3),
                  width: isSelected ? 0 : 1.5,
                ),
                onSelected: (_) => setState(() => _selectedCategory = category),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category.toLowerCase()) {
      case 'health':
        return const Color(0xFF4CAF50);
      case 'fitness':
        return const Color(0xFFFF5722);
      case 'productivity':
        return const Color(0xFF2196F3);
      case 'learning':
        return const Color(0xFF9C27B0);
      case 'mindfulness':
        return const Color(0xFF00BCD4);
      case 'social':
        return const Color(0xFFFF9800);
      case 'creativity':
        return const Color(0xFFE91E63);
      case 'finance':
        return const Color(0xFF795548);
      case 'reading':
        return const Color(0xFF673AB7);  // Deep Purple
      case 'writing':
        return const Color(0xFF607D8B);  // Blue Grey
      default:
        return theme.colorScheme.primary;
    }
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
            onEdit: () => _editHabit(habit),
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
