import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';

/// Shows every archived habit. From here the user can restore a habit
/// (it reappears on Home / Progress / stats with its data intact) or
/// permanently delete it (habit + all completions removed).
class ArchivedHabitsScreen extends StatefulWidget {
  const ArchivedHabitsScreen({super.key});

  @override
  State<ArchivedHabitsScreen> createState() => _ArchivedHabitsScreenState();
}

class _ArchivedHabitsScreenState extends State<ArchivedHabitsScreen> {
  List<Habit> _archivedHabits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedHabits();
  }

  Future<void> _loadArchivedHabits() async {
    try {
      final repository = Provider.of<HabitRepository>(context, listen: false);
      final habits = await repository.getArchivedHabits();
      if (mounted) {
        setState(() {
          _archivedHabits = habits;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ArchivedHabitsScreen: error loading archived habits: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreHabit(Habit habit) async {
    try {
      final repository = Provider.of<HabitRepository>(context, listen: false);
      await repository.unarchiveHabit(habit.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${habit.name} restored')));
      }
      _loadArchivedHabits();
    } catch (e) {
      debugPrint('ArchivedHabitsScreen: error restoring habit: $e');
    }
  }

  Future<void> _confirmDelete(Habit habit) async {
    // Capture the repository before the async gap (showDialog).
    final repository = Provider.of<HabitRepository>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        // The delete card adopts THIS habit's color scheme — same color
        // logic as the habit cards, habit-wise different tint.
        final habitScheme = habit.scheme(dialogTheme.brightness);
        return Theme(
          data: dialogTheme.copyWith(
            colorScheme: habitScheme,
            dialogTheme: dialogTheme.dialogTheme.copyWith(
              backgroundColor: habitScheme.surfaceContainerHigh,
            ),
          ),
          child: AlertDialog(
            title: const Text('Delete Permanently'),
            content: Text(
              'Are you sure you want to permanently delete "${habit.name}"?\n\n'
              'All of its data and history will be removed. '
              'This action cannot be undone.',
            ),
            actions: [
              // Cancel text uses the same color logic as the habit's own
              // icon (onPrimaryContainer of this habit's scheme).
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: habitScheme.onPrimaryContainer,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              // Delete uses the Material 3 Expressive soft danger tone:
              // errorContainer fill + onErrorContainer label.
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: habitScheme.errorContainer,
                  foregroundColor: habitScheme.onErrorContainer,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        await repository.deleteHabit(habit.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${habit.name} deleted permanently')),
          );
        }
        _loadArchivedHabits();
      } catch (e) {
        debugPrint('ArchivedHabitsScreen: error deleting habit: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Same background color logic as every other screen — straight from
      // the app theme.
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: MaterialLoadingIndicator(
                        size: 40,
                        color: theme.colorScheme.primary,
                        style: LoadingStyle.pulse,
                      ),
                    )
                  : _archivedHabits.isEmpty
                  ? _buildEmptyState(theme)
                  : RefreshIndicator(
                      onRefresh: _loadArchivedHabits,
                      color: theme.colorScheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _archivedHabits.length,
                        itemBuilder: (context, index) =>
                            _buildArchivedCard(theme, _archivedHabits[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Archived Habits',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Same card style as the home habit card, but only the logo and the
  /// category remain — no stats, arcs or completion controls. The 3-dot
  /// menu on the right offers Restore and Delete Permanently.
  Widget _buildArchivedCard(ThemeData theme, Habit habit) {
    // Material 3 scheme generated from THIS habit's own selected color —
    // same logic as the home card icon circle.
    final habitScheme = habit.scheme(theme.brightness);

    return Container(
      height: 84,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: habit.cardBackground(theme.brightness),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: habitScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              habit.icon,
              color: habitScheme.onPrimaryContainer,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: habitScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    habit.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: habitScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            // Menu card tinted by THIS habit's own color scheme — same
            // surface-container color logic, habit-wise different tint.
            color: habitScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'restore') {
                _restoreHabit(habit);
              } else if (value == 'delete') {
                _confirmDelete(habit);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(
                      Icons.unarchive_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 10),
                    const Text('Restore'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      size: 18,
                      // Material 3 soft danger tone (onErrorContainer).
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Delete Permanently',
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
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
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.archive_rounded,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No archived habits',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Habits you archive will appear here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
