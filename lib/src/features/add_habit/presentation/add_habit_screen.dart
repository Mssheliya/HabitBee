import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/data/models/habit.dart';
import 'package:habit_bee/src/data/repositories/habit_repository.dart';
import 'package:habit_bee/src/core/constants/app_constants.dart';
import 'package:habit_bee/src/core/services/notification_service.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';

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
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    debugPrint('AddHabitScreen: initState');
    if (_isEditing) {
      _nameController.text = widget.habit!.name;
      _selectedCategory = widget.habit!.category;
      _selectedColorIndex = widget.habit!.colorIndex;
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveHabit() async {
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
          
          // Cancel any existing notification first
          await notificationService.cancelNotification(savedHabit.notificationId);
          
          // Schedule new notification
          await notificationService.scheduleNotification(
            id: savedHabit.notificationId,
            title: 'Habit Reminder',
            body: 'Time to complete: ${savedHabit.name}',
            scheduledDate: reminderDateTime,
            repeatDays: _repeatDays,
          );
          
          debugPrint('AddHabitScreen: Notification scheduled successfully');
          
          // Verify it was scheduled
          final pendingNotifications = await notificationService.getPendingNotifications();
          debugPrint('AddHabitScreen: Pending notifications: ${pendingNotifications.length}');
          for (final notification in pendingNotifications) {
            debugPrint('AddHabitScreen: - ID: ${notification.id}, Title: ${notification.title}');
          }
        } catch (e) {
          debugPrint('AddHabitScreen: Notification scheduling failed: $e');
          // Show warning but don't fail the habit creation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Habit saved, but reminder could not be set: $e'),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: MaterialLoadingIndicator(
                size: 24,
                color: AppTheme.black,
                style: LoadingStyle.pulse,
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _saveHabit,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text(
                  'SAVE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
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

              // Name Input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit Name *',
                  hintText: 'e.g., Morning Exercise',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category Selection
              Text(
                'Category',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.habitCategories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? theme.colorScheme.onPrimary : null,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Frequency Selection
              Text(
                'Frequency Times Per Day',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: _frequencyPerDay > 1
                        ? () => setState(() => _frequencyPerDay--)
                        : null,
                    icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.primary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.primary),
                    ),
                    child: Text(
                      '$_frequencyPerDay',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _frequencyPerDay < 10
                        ? () => setState(() => _frequencyPerDay++)
                        : null,
                    icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _frequencyPerDay == 1 ? 'time per day' : 'times per day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Color Selection
              Text(
                'Color',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(AppTheme.habitColors.length, (index) {
                  final isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorIndex = index;
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.habitColors[index],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: AppTheme.black, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Icon Selection
              Text(
                'Icon',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppConstants.habitIcons.map((iconName) {
                  final isSelected = _selectedIcon == iconName;
                  IconData iconData = _getIconData(iconName);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconName;
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppTheme.black, width: 2)
                            : null,
                      ),
                      child: Icon(iconData),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Reminder Section
              SwitchListTile(
                title: Text(
                  'Enable Reminder',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Get notified to complete this habit'),
                value: _reminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _reminderEnabled = value;
                  });
                },
                activeColor: theme.colorScheme.primary,
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
                  onTap: _selectTime,
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _repeatDays[index] = !_repeatDays[index];
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _repeatDays[index]
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _repeatDays[index]
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.black,
                        ),
                      ),
                    )
                  : Text(
                      _isEditing ? 'UPDATE HABIT' : 'CREATE HABIT',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'fitness_center': Icons.fitness_center,
      'directions_run': Icons.directions_run,
      'self_improvement': Icons.self_improvement,
      'menu_book': Icons.menu_book,
      'water_drop': Icons.water_drop,
      'bedtime': Icons.bedtime,
      'restaurant': Icons.restaurant,
      'savings': Icons.savings,
      'work': Icons.work,
      'palette': Icons.palette,
      'music_note': Icons.music_note,
      'code': Icons.code,
      'nature': Icons.nature,
      'chat': Icons.chat,
      'local_florist': Icons.local_florist,
      'wb_sunny': Icons.wb_sunny,
      'nights_stay': Icons.nights_stay,
      'favorite': Icons.favorite,
      'star': Icons.star,
      'emoji_events': Icons.emoji_events,
    };
    return iconMap[iconName] ?? Icons.star;
  }
}
