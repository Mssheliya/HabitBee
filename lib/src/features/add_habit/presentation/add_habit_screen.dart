import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/core/constants/app_constants.dart';
import 'package:habit_bee/src/core/services/notification_service.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/widgets/theme_color_circle.dart';
import 'package:habit_bee/src/core/utils/motivational_messages.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/features/add_habit/presentation/widgets/habit_icon_data.dart';
import 'package:habit_bee/src/features/add_habit/presentation/widgets/icon_frequency_ring.dart';
import 'package:habit_bee/src/features/add_habit/presentation/widgets/habit_picker_sheets.dart';
import 'package:habit_bee/src/features/add_habit/presentation/widgets/grouped_card.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit;

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedCategory = AppConstants.habitCategories.first;
  int _selectedColorIndex = 0;
  String _selectedIcon = AppConstants.habitIcons.first;
  bool _reminderEnabled = false;
  TimeOfDay? _reminderTime;
  List<bool> _repeatDays = List.filled(7, true);
  int _frequencyPerDay = 1;
  int _freqDirection = 1;
  bool _isSaving = false;
  String? _errorMessage;
  // Add mode: page keeps the app theme color until the user picks a habit
  // color. Edit mode: starts true so the page adopts the habit's color.
  bool _colorChosen = false;

  bool get _isEditing => widget.habit != null;

  void _haptic() {
    Provider.of<ThemeProvider>(context, listen: false).triggerHaptic();
  }

  @override
  void initState() {
    super.initState();
    debugPrint('AddHabitScreen: initState');
    if (_isEditing) {
      _nameController.text = widget.habit!.name;
      _selectedCategory = widget.habit!.category;
      _selectedColorIndex = widget.habit!.colorIndex;
      _colorChosen = true; // Edit mode: page adopts the habit's own color
      _selectedIcon = widget.habit!.iconName;
      _reminderEnabled = widget.habit!.reminderEnabled;
      _frequencyPerDay = widget.habit!.frequencyPerDay;
      if (widget.habit!.reminderTime != null) {
        _reminderTime = TimeOfDay.fromDateTime(widget.habit!.reminderTime!);
      }
      _repeatDays = List.from(widget.habit!.repeatDays);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildFreqStepButton({
    required IconData icon,
    required bool enabled,
    required bool isMinus,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isMinus ? 18 : 8),
      bottomLeft: Radius.circular(isMinus ? 18 : 8),
      topRight: Radius.circular(isMinus ? 8 : 18),
      bottomRight: Radius.circular(isMinus ? 8 : 18),
    );
    return Material(
      color: enabled
          ? colorScheme.primary
          : colorScheme.primary.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        borderRadius: radius,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 44,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? colorScheme.onPrimary
                : colorScheme.onPrimary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  // Pickers receive the page-themed context so sheets/dialogs also adopt
  // the habit color (background, pills, buttons) — same color logic.
  Future<void> _selectTime(BuildContext pickerContext) async {
    final TimeOfDay? picked = await showTimePicker(
      context: pickerContext,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveHabit() async {
    _haptic();
    debugPrint('=== SAVE HABIT STARTED ===');
    debugPrint('Form validation: ${_formKey.currentState?.validate()}');
    debugPrint('Name: ${_nameController.text}');

    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a habit name';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Getting repository...');
      final repository = Provider.of<HabitRepository>(context, listen: false);
      debugPrint('Repository obtained successfully');

      debugPrint('Creating/Updating habit...');

      DateTime? reminderDateTime;
      if (_reminderEnabled && _reminderTime != null) {
        final now = DateTime.now();
        var scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          _reminderTime!.hour,
          _reminderTime!.minute,
        );

        // If the time has already passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        reminderDateTime = scheduledDate;
      }

      Habit savedHabit;

      if (_isEditing) {
        debugPrint('Updating existing habit: ${widget.habit!.id}');
        final updatedHabit = widget.habit!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          colorIndex: _selectedColorIndex,
          iconName: _selectedIcon,
          reminderEnabled: _reminderEnabled,
          reminderTime: reminderDateTime,
          repeatDays: _repeatDays,
          frequencyPerDay: _frequencyPerDay,
        );
        await repository.updateHabit(updatedHabit);
        savedHabit = updatedHabit;
        debugPrint('Habit updated successfully');
      } else {
        debugPrint('Creating new habit...');
        final newHabit = Habit.create(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          colorIndex: _selectedColorIndex,
          iconName: _selectedIcon,
          reminderEnabled: _reminderEnabled,
          reminderTime: reminderDateTime,
          repeatDays: _repeatDays,
          frequencyPerDay: _frequencyPerDay,
        );
        debugPrint('Created habit object with ID: ${newHabit.id}');
        await repository.createHabit(newHabit);
        savedHabit = newHabit;
        debugPrint('Habit saved to repository successfully');
      }

      // Schedule notification
      if (_reminderEnabled && reminderDateTime != null) {
        try {
          debugPrint('AddHabitScreen: Scheduling notification...');
          final notificationService = NotificationService();

          // Try to cancel any existing notification (ignore errors)
          try {
            await notificationService.cancelNotification(
              savedHabit.notificationId,
            );
          } catch (e) {
            debugPrint(
              'AddHabitScreen: Cancel notification error (ignoring): $e',
            );
          }

          // Schedule new notification
          await notificationService.scheduleNotification(
            id: savedHabit.notificationId,
            title: MotivationalMessages.getTitle(savedHabit.category),
            body: MotivationalMessages.getMessage(
              savedHabit.category,
              savedHabit.name,
            ),
            scheduledDate: reminderDateTime,
            repeatDays: _repeatDays,
          );

          debugPrint('AddHabitScreen: Notification scheduled successfully');
        } catch (e) {
          debugPrint('AddHabitScreen: Notification scheduling failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Habit saved, but reminder could not be set'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      debugPrint('=== SAVE HABIT SUCCESS ===');

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '✓ Habit updated!' : '✓ Habit created!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('=== SAVE HABIT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _saveHabit,
            ),
          ),
        );
      }
    } finally {
      if (mounted && _errorMessage == null) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Edit mode → the page adopts the habit's own color. Add mode → app
    // theme color until the user picks a habit color, then the page
    // instantly re-colors. A FULL theme is built from the habit seed, so
    // every component — name field, category pill, dropdown sheets, color
    // picker sheet, reminder toggle, time picker, save button — re-colors
    // with the SAME color logic (only the seed changes).
    final pageTheme = !_colorChosen
        ? baseTheme
        : AppTheme.buildThemeFromSeed(
            seedColor:
                AppTheme.habitColorOptions[_selectedColorIndex %
                    AppTheme.habitColorOptions.length],
            brightness: baseTheme.brightness,
            variant: themeProvider.dynamicSchemeVariant,
            fontScale: themeProvider.settings.fontScale,
          );

    return Theme(
      data: pageTheme,
      child: Builder(
        builder: (themedContext) {
          final theme = Theme.of(themedContext);

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),

                    // 1) Habit Name + Icon (standalone card)
                    GroupedCard(
                      position: GroupedCardPosition.single,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Habit Name *',
                          hintText: 'e.g., Morning Exercise',
                          border: InputBorder.none,
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: IconFrequencyRing(
                              icon: habitIconData(_selectedIcon),
                              frequency: _frequencyPerDay,
                              onTap: () => _pickIcon(themedContext),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a habit name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: GroupedCard.groupGap),

                    // 2) Category + Color (one grouped stack, tiny inner gap)
                    GroupedCardsColumn(
                      children: [
                        GroupedCard(
                          position: GroupedCardPosition.top,
                          padding: EdgeInsets.zero,
                          onTap: () => _pickCategory(themedContext),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 2,
                            ),
                            title: const Text(
                              'Category',
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,

                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCategory,
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        GroupedCard(
                          position: GroupedCardPosition.bottom,
                          padding: EdgeInsets.zero,
                          onTap: () => _pickColor(themedContext),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 2,
                            ),
                            title: const Text(
                              'Color',
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ThemeColorCircle(
                                  seedColor: AppTheme
                                      .habitColorOptions[_selectedColorIndex],
                                  isSelected: false,
                                  onTap: () => _pickColor(themedContext),
                                  brightness: Theme.of(context).brightness,
                                  dynamicSchemeVariant: context
                                      .read<ThemeProvider>()
                                      .dynamicSchemeVariant,
                                  size: 30,
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GroupedCard.groupGap),

                    // 3) Frequency + Reminder (one grouped stack)
                    GroupedCardsColumn(
                      children: [
                        GroupedCard(
                          position: GroupedCardPosition.top,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.repeat_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Frequency'),
                                    Text(
                                      _frequencyPerDay == 1
                                          ? '1 time per day'
                                          : '$_frequencyPerDay times per day',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final colorScheme = theme.colorScheme;
                                  final isDark =
                                      theme.brightness == Brightness.dark;
                                  final cardBg =
                                      theme.cardTheme.color ??
                                      (isDark
                                          ? colorScheme.surfaceContainerLow
                                          : colorScheme.surfaceContainerHighest
                                                .withValues(alpha: 0.4));
                                  final minusEnabled = _frequencyPerDay > 1;
                                  final plusEnabled = _frequencyPerDay < 10;

                                  void decrement() {
                                    _haptic();
                                    setState(() {
                                      _freqDirection = -1;
                                      _frequencyPerDay--;
                                    });
                                  }

                                  void increment() {
                                    _haptic();
                                    setState(() {
                                      _freqDirection = 1;
                                      _frequencyPerDay++;
                                    });
                                  }

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildFreqStepButton(
                                        icon: Icons.remove_rounded,
                                        enabled: minusEnabled,
                                        isMinus: true,
                                        onTap: decrement,
                                        colorScheme: colorScheme,
                                      ),
                                      const SizedBox(width: 2),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 40,
                                          height: 36,
                                          color: cardBg,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            transitionBuilder:
                                                (child, animation) {
                                                  final isEntering =
                                                      child.key ==
                                                      ValueKey(
                                                        _frequencyPerDay,
                                                      );
                                                  final dy = isEntering
                                                      ? _freqDirection
                                                            .toDouble()
                                                      : -_freqDirection
                                                            .toDouble();
                                                  return SlideTransition(
                                                    position:
                                                        Tween<Offset>(
                                                          begin: Offset(
                                                            0,
                                                            0.9 * dy,
                                                          ),
                                                          end: Offset.zero,
                                                        ).animate(
                                                          CurvedAnimation(
                                                            parent: animation,
                                                            curve: Curves
                                                                .easeOutCubic,
                                                          ),
                                                        ),
                                                    child: child,
                                                  );
                                                },
                                            child: Text(
                                              '$_frequencyPerDay',
                                              key: ValueKey(_frequencyPerDay),
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      _buildFreqStepButton(
                                        icon: Icons.add_rounded,
                                        enabled: plusEnabled,
                                        isMinus: false,
                                        onTap: increment,
                                        colorScheme: colorScheme,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        GroupedCard(
                          position: GroupedCardPosition.bottom,
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: Text(
                                  'Enable Reminder',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Get notified to complete this habit',
                                ),
                                value: _reminderEnabled,
                                onChanged: (value) {
                                  _haptic();
                                  setState(() {
                                    _reminderEnabled = value;
                                  });
                                },
                              ),
                              if (_reminderEnabled) ...[
                                const SizedBox(height: 12),
                                ListTile(
                                  leading: const Icon(Icons.access_time),
                                  title: const Text('Reminder Time'),
                                  subtitle: Text(
                                    _reminderTime != null
                                        ? _reminderTime!.format(context)
                                        : 'Select time',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _selectTime(themedContext),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Repeat on',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                        final index = entry.key;
                                        final day = entry.value;
                                        return GestureDetector(
                                          onTap: () {
                                            _haptic();
                                            setState(() {
                                              _repeatDays[index] =
                                                  !_repeatDays[index];
                                            });
                                          },
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _repeatDays[index]
                                                  ? theme.colorScheme.primary
                                                  : theme
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                day,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: _repeatDays[index]
                                                      ? theme
                                                            .colorScheme
                                                            .onPrimary
                                                      : theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveHabit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update' : 'Save',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickIcon(BuildContext pickerContext) async {
    _haptic();
    final picked = await showHabitIconPickerSheet(
      context: pickerContext,
      selectedIcon: _selectedIcon,
    );
    if (picked != null) {
      setState(() => _selectedIcon = picked);
    }
  }

  Future<void> _pickCategory(BuildContext pickerContext) async {
    _haptic();
    final picked = await showCategoryPickerSheet(
      context: pickerContext,
      categories: AppConstants.habitCategories,
      selectedCategory: _selectedCategory,
    );
    if (picked != null) {
      setState(() => _selectedCategory = picked);
    }
  }

  Future<void> _pickColor(BuildContext pickerContext) async {
    _haptic();
    final picked = await showHabitColorPickerSheet(
      context: pickerContext,
      selectedIndex: _selectedColorIndex,
    );
    if (picked != null) {
      // The moment the user picks a color, the whole page instantly
      // re-colors to that habit color (same color logic, new seed).
      setState(() {
        _selectedColorIndex = picked;
        _colorChosen = true;
      });
    }
  }
}
