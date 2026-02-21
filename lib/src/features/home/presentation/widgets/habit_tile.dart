import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';

class HabitTile extends StatefulWidget {
  final Habit habit;
  final DateTime date;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const HabitTile({
    super.key,
    required this.habit,
    required this.date,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile> {
  bool _isCompleted = false;
  int _completionCount = 0;
  int _frequency = 1;
  bool _isLoading = true;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _frequency = widget.habit.frequencyPerDay;
    _loadCompletionStatus();
  }

  @override
  void didUpdateWidget(HabitTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if the date or habit changed, and we're not currently toggling
    if (!_isToggling && (
        !_isSameDay(oldWidget.date, widget.date) ||
        oldWidget.habit.id != widget.habit.id)) {
      _frequency = widget.habit.frequencyPerDay;
      _loadCompletionStatus();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadCompletionStatus() async {
    if (_isToggling) return; // Don't reload while toggling
    
    try {
      final repository = Provider.of<HabitRepository>(context, listen: false);
      final status = await repository.getHabitCompletionStatus(widget.habit.id, widget.date);
      if (mounted && !_isToggling) {
        setState(() {
          _isCompleted = status['isCompleted'] as bool;
          _completionCount = status['completionCount'] as int;
          _frequency = status['frequency'] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking completion: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleToggle() async {
    if (_isToggling || _isCompleted) return; // Prevent multiple clicks and uncompleting

    setState(() {
      _isToggling = true;
    });

    try {
      final repository = Provider.of<HabitRepository>(context, listen: false);

      // Toggle completion
      await repository.toggleHabitCompletion(widget.habit.id, widget.date);

      // Check new state
      final status = await repository.getHabitCompletionStatus(widget.habit.id, widget.date);

      if (mounted) {
        setState(() {
          _isCompleted = status['isCompleted'] as bool;
          _completionCount = status['completionCount'] as int;
          _isToggling = false;
        });

        // Notify parent
        widget.onToggle();

        // Show feedback
        final String message;
        if (_frequency > 1) {
          // Multi-completion habit
          if (_isCompleted) {
            message = '✓ ${widget.habit.name} completed! ($_completionCount/$_frequency)';
          } else {
            message = '${widget.habit.name} ($_completionCount/$_frequency)';
          }
        } else {
          // Single completion habit
          message = _isCompleted ? '✓ ${widget.habit.name} completed!' : '○ ${widget.habit.name}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: _isCompleted ? Colors.green : theme.colorScheme.primary,
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling habit: $e');
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ThemeData get theme => Theme.of(context);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: MaterialLoadingIndicator(
            size: 32,
            color: Theme.of(context).colorScheme.primary,
            style: LoadingStyle.pulse,
          ),
        ),
      );
    }

    return Dismissible(
      key: Key('${widget.habit.id}_${widget.date.year}-${widget.date.month}-${widget.date.day}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Habit'),
            content: Text('Are you sure you want to delete "${widget.habit.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          final repository = Provider.of<HabitRepository>(context, listen: false);
          await repository.deleteHabit(widget.habit.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.habit.name} deleted')),
            );
          }
        } catch (e) {
          debugPrint('Error deleting habit: $e');
        }
      },
      child: GestureDetector(
        onTap: _isCompleted ? null : widget.onEdit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 84,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _isCompleted
                ? widget.habit.color.withValues(alpha: 0.3)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: _isCompleted
                ? Border.all(color: widget.habit.color, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.habit.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.habit.icon,
                      color: widget.habit.color.withValues(alpha: 0.8),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.habit.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: _isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _frequency > 1
                              ? _isCompleted
                                  ? '${widget.habit.category} • ${((_completionCount / _frequency) * 100).round()}% ✓ Done'
                                  : '${widget.habit.category} • ${((_completionCount / _frequency) * 100).round()}% ($_completionCount/$_frequency)'
                              : '${widget.habit.category}${_isCompleted ? " ✓ Done" : ""}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _isCompleted ? Colors.green : theme.colorScheme.onSurfaceVariant,
                            fontWeight: _isCompleted ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Complete Button
                  GestureDetector(
                    onTap: _isToggling || _isCompleted ? null : _handleToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: _isCompleted
                            ? widget.habit.color
                            : (_completionCount > 0
                                ? widget.habit.color.withValues(alpha: 0.3)
                                : theme.colorScheme.surfaceContainerHighest),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isToggling
                              ? Colors.grey
                              : (_isCompleted
                                  ? widget.habit.color
                                  : (_completionCount > 0
                                      ? widget.habit.color
                                      : theme.colorScheme.outline)),
                          width: 2,
                        ),
                      ),
                      child: _isToggling
                          ? Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.9)),
                                ),
                              ),
                            )
                          : (_isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 28,
                                )
                              : (_completionCount > 0
                                  ? Center(
                                      child: Text(
                                        '$_completionCount',
                                        style: TextStyle(
                                          color: widget.habit.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : null)),
                    ),
                  ),
                ],
              ),
              // Frequency Progress Indicator
              if (_frequency > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 4,
                  child: Center(
                    child: SizedBox(
                      width: 0.8,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(
                          begin: 0.0,
                          end: _frequency > 0 ? (_completionCount / _frequency).clamp(0.0, 1.0) : 0.0,
                        ),
                        builder: (context, progress, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: widget.habit.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: progress * constraints.maxWidth,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          widget.habit.color.withValues(alpha: 0.9),
                                          widget.habit.color,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
