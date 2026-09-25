import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/features/home/presentation/widgets/completion_arc_button.dart';

class HabitTile extends StatefulWidget {
  final Habit habit;
  final DateTime date;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const HabitTile({
    super.key,
    required this.habit,
    required this.date,
    required this.onToggle,
    required this.onTap,
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
  String? _note;

  @override
  void initState() {
    super.initState();
    _frequency = widget.habit.frequencyPerDay;
    _loadCompletionStatus();
  }

  @override
  void didUpdateWidget(HabitTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when the date or the habit itself changed (including a
    // frequency change from the edit screen), unless we're toggling.
    if (!_isToggling &&
        (!_isSameDay(oldWidget.date, widget.date) ||
            oldWidget.habit.id != widget.habit.id ||
            oldWidget.habit.frequencyPerDay != widget.habit.frequencyPerDay)) {
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
      final status = await repository.getHabitCompletionStatus(
        widget.habit.id,
        widget.date,
      );
      final note = await repository.getNoteForDate(
        widget.habit.id,
        widget.date,
      );
      if (mounted && !_isToggling) {
        setState(() {
          _isCompleted = status['isCompleted'] as bool;
          _completionCount = status['completionCount'] as int;
          _frequency = status['frequency'] as int;
          _note = note;
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
    if (_isToggling || _isCompleted) {
      return; // Prevent multiple clicks and uncompleting
    }
    // Not scheduled on this date (reminder days skipped) → completion disabled.
    if (!widget.habit.isScheduledOn(widget.date)) return;

    // Stronger haptic on habit completion (respects Settings toggle)
    Provider.of<ThemeProvider>(context, listen: false).triggerMediumHaptic();

    setState(() {
      _isToggling = true;
    });

    try {
      final repository = Provider.of<HabitRepository>(context, listen: false);

      // Toggle completion
      await repository.toggleHabitCompletion(widget.habit.id, widget.date);

      // Check new state
      final status = await repository.getHabitCompletionStatus(
        widget.habit.id,
        widget.date,
      );

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
            message =
                '✓ ${widget.habit.name} completed! ($_completionCount/$_frequency)';
          } else {
            message = '${widget.habit.name} ($_completionCount/$_frequency)';
          }
        } else {
          // Single completion habit
          message = _isCompleted
              ? '✓ ${widget.habit.name} completed!'
              : '○ ${widget.habit.name}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: _isCompleted
                ? Colors.green
                : theme.colorScheme.primary,
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  ThemeData get theme => Theme.of(context);

  /// Opens the note editor popup for THIS tile's date. Only the note badge
  /// triggers this — every other part of the card keeps its old behavior.
  /// Closing the popup (X button or outside tap) saves the note.
  Future<void> _openNoteEditor() async {
    Provider.of<ThemeProvider>(context, listen: false).triggerHaptic();
    final baseTheme = theme;
    final habitScheme = widget.habit.scheme(baseTheme.brightness);
    final controller = TextEditingController(text: _note ?? '');
    // Captured before the async dialog so no context is used across the gap.
    final repository = Provider.of<HabitRepository>(context, listen: false);

    await showDialog<void>(
      context: context,
      barrierDismissible: true, // tapping outside also saves & closes
      builder: (dialogContext) {
        return Theme(
          // Same color logic as the habit card: everything derives from the
          // habit's own color scheme.
          data: baseTheme.copyWith(colorScheme: habitScheme),
          child: AlertDialog(
            backgroundColor: habitScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Enter note',
                    style: baseTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: habitScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: habitScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Close',
                ),
              ],
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              style: baseTheme.textTheme.bodyMedium?.copyWith(
                color: habitScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Write a note for this day...',
                hintStyle: baseTheme.textTheme.bodyMedium?.copyWith(
                  color: habitScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: habitScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: habitScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: habitScheme.primary,
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Dialog closed — save whatever the user typed for this date.
    final text = controller.text;
    controller.dispose();
    try {
      await repository.saveNoteForDate(widget.habit.id, widget.date, text);
      if (mounted) {
        final trimmed = text.trim();
        setState(() {
          _note = trimmed.isEmpty ? null : trimmed;
        });
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
    }
  }

  /// The small divider dot used between subtitle items.
  Widget _buildDot(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Subtitle: [Category badge] • [Note badge] • [reminder icon]
  /// Category badge uses the habit scheme's tertiary roles; the note badge
  /// uses the same color logic as the habit icon badge (primaryContainer /
  /// onPrimaryContainer). Percentage / frequency text is intentionally gone.
  Widget _buildSubtitle(
    ThemeData theme,
    ColorScheme habitScheme,
    bool isScheduled,
    Color skipBadgeBg,
    Color skipBadgeFg,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category badge
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isScheduled ? habitScheme.tertiaryContainer : skipBadgeBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              widget.habit.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isScheduled
                    ? habitScheme.onTertiaryContainer
                    : skipBadgeFg,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ),
        _buildDot(theme),
        // Note badge — tapping ONLY here opens the note editor popup.
        GestureDetector(
          onTap: _openNoteEditor,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isScheduled ? habitScheme.primaryContainer : skipBadgeBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Note',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isScheduled
                        ? habitScheme.onPrimaryContainer
                        : skipBadgeFg,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.edit_note_rounded,
                  size: 13,
                  color: isScheduled
                      ? habitScheme.onPrimaryContainer
                      : skipBadgeFg,
                ),
              ],
            ),
          ),
        ),
        if (widget.habit.reminderEnabled) ...[
          _buildDot(theme),
          Icon(
            Icons.notifications_active_outlined,
            size: 13,
            color: isScheduled ? widget.habit.color : skipBadgeFg,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reminder on + some days skipped → false on those days: card shows
    // fully greyed out and completion is disabled, but tapping still opens
    // details.
    final isScheduled = widget.habit.isScheduledOn(widget.date);
    // Material 3 scheme generated from THIS habit's own selected color —
    // every card element (background, icon circle, completion arc) derives
    // from it, never from the system theme.
    final habitScheme = widget.habit.scheme(theme.brightness);

    // Skip-day "disabled" palette (reference: user-provided dark mock) —
    // near-black card, slightly lifted dark containers, muted grey
    // foregrounds in dark mode; soft neutral greys in light mode.
    final skipIsDark = theme.brightness == Brightness.dark;
    final skipCardBg = skipIsDark
        ? const Color(0xFF161616)
        : Colors.grey.shade200;
    final skipContainerBg = skipIsDark
        ? const Color(0xFF262626)
        : Colors.grey.shade300;
    final skipFg = skipIsDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final skipFgMuted = skipIsDark
        ? Colors.grey.shade600
        : Colors.grey.shade500;

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

    return GestureDetector(
      onTap: () {
        Provider.of<ThemeProvider>(context, listen: false).triggerHaptic();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 84,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          // Calendar-style card background, tinted by THIS habit's color
          // (same logic as the progress-page calendar card). Skip days get
          // the muted disabled background (image reference) instead.
          color: isScheduled
              ? widget.habit.cardBackground(theme.brightness)
              : skipCardBg,
          borderRadius: BorderRadius.circular(16),
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
                    // Add-habit-button-style background: primaryContainer
                    // of this habit's own color scheme. Skip days: muted
                    // disabled container (image reference).
                    color: isScheduled
                        ? habitScheme.primaryContainer
                        : skipContainerBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.habit.icon,
                    // Add-habit-button plus icon logic: onPrimaryContainer
                    color: isScheduled
                        ? habitScheme.onPrimaryContainer
                        : skipFgMuted,
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
                        widget.habit.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isScheduled ? null : skipFg,
                          decoration: _isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildSubtitle(
                        theme,
                        habitScheme,
                        isScheduled,
                        skipContainerBg,
                        skipFgMuted,
                      ),
                    ],
                  ),
                ),
                // Completion button with frequency arcs
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CompletionArcButton(
                    // Plus-icon / add-button colors from THIS habit's
                    // scheme; skip days use the muted disabled greys.
                    color: isScheduled
                        ? habitScheme.onPrimaryContainer
                        : skipFgMuted,
                    mutedColor: isScheduled
                        ? habitScheme.primaryContainer
                        : skipContainerBg,
                    completionCount: _completionCount,
                    frequency: _frequency,
                    isCompleted: _isCompleted,
                    isBusy: _isToggling,
                    onTap: _isToggling || _isCompleted || !isScheduled
                        ? null
                        : _handleToggle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
