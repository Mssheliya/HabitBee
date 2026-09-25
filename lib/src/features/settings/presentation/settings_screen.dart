import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/data/services/storage_service.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/core/services/notification_service.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';
import 'package:habit_bee/src/core/widgets/theme_color_circle.dart';
import 'package:habit_bee/src/features/settings/presentation/theme_settings_screen.dart';
import 'package:habit_bee/src/features/settings/presentation/archived_habits_screen.dart';
import 'package:habit_bee/src/features/add_habit/presentation/widgets/grouped_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final settings = await storageService.getSettings();
    if (mounted) {
      setState(() {
        _notificationsEnabled = settings.notificationsEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final settings = await storageService.getSettings();
    await storageService.saveSettings(
      settings.copyWith(notificationsEnabled: value),
    );
    setState(() {
      _notificationsEnabled = value;
    });
  }

  // Export data to JSON file
  Future<void> _exportToJson() async {
    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      final data = await storageService.exportData();
      final jsonData = jsonEncode(data);

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'habitbee_backup_$timestamp.json';

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(jsonData);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'HabitBee Backup - $timestamp',
        subject: 'HabitBee Data Backup',
      );

      if (await file.exists()) {
        await file.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  // Export data to CSV file
  Future<void> _exportToCsv() async {
    try {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      final csvData = await storageService.exportToCsv();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'habitbee_export_$timestamp.csv';

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'HabitBee CSV Export - $timestamp',
        subject: 'HabitBee Data Export',
      );

      if (await file.exists()) {
        await file.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported to CSV successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
      }
    }
  }

  // Import data from JSON file
  Future<void> _importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        throw Exception('Invalid file path');
      }

      final fileContent = await File(file.path!).readAsString();
      final data = jsonDecode(fileContent) as Map<String, dynamic>;

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: const Text(
            'This will replace all your current habits and data. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (!mounted) return;
        final storageService = Provider.of<StorageService>(
          context,
          listen: false,
        );
        await storageService.importData(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data imported successfully!')),
          );
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  // Import data from CSV file
  Future<void> _importFromCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        throw Exception('Invalid file path');
      }

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import CSV Data'),
          content: const Text(
            'This will add imported habits to your current data. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (!mounted) return;
        final storageService = Provider.of<StorageService>(
          context,
          listen: false,
        );
        final fileContent = await File(file.path!).readAsString();
        final importedCount = await storageService.importFromCsv(fileContent);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$importedCount habits imported successfully!'),
            ),
          );
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV import failed: $e')));
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all your habits and data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      await storageService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All data cleared')));
      }
    }
  }

  void _showAboutDialog(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.emoji_nature_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'HabitBee',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your personal habit tracker',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'HabitBee helps you build positive habits and track your daily progress with Google Material 3 Design.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Created by Mustafa Sheliya',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.code_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Version 1.0.0', style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    Share.share(
      'Check out HabitBee - Your personal habit tracker! Download now and start building positive habits. https://play.google.com/store/apps/details?id=com.habitbee.app',
      subject: 'HabitBee - Habit Tracker App',
    );
  }

  Future<void> _rateApp() async {
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.habitbee.app',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open store')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: MaterialLoadingIndicator(
            size: 48,
            color: colorScheme.primary,
            style: LoadingStyle.bouncing,
          ),
        ),
      );
    }

    // Determine current effective brightness for circle preview calculations
    final currentBrightness = themeProvider.themeMode == ThemeMode.dark
        ? Brightness.dark
        : (themeProvider.themeMode == ThemeMode.light
              ? Brightness.light
              : MediaQuery.platformBrightnessOf(context));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Settings',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Appearance & Theme Card
                  _buildSectionTitle(theme, 'Theme'),
                  _buildSettingsCard(
                    theme,
                    children: [
                      // Theme Mode Selection
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<ThemeMode>(
                                segments: const [
                                  ButtonSegment<ThemeMode>(
                                    value: ThemeMode.system,
                                    label: Text('System'),
                                    icon: Icon(
                                      Icons.brightness_auto_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  ButtonSegment<ThemeMode>(
                                    value: ThemeMode.light,
                                    label: Text('Light'),
                                    icon: Icon(
                                      Icons.light_mode_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  ButtonSegment<ThemeMode>(
                                    value: ThemeMode.dark,
                                    label: Text('Dark'),
                                    icon: Icon(
                                      Icons.dark_mode_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ],
                                selected: {themeProvider.themeMode},
                                onSelectionChanged: (newSelection) {
                                  themeProvider.setThemeMode(
                                    newSelection.first,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Theme Color Circles (3-Color Split Preview)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Theme Color',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ThemeSettingsScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.tune_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('More Options'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 86,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: AppTheme.seedOptions.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, index) {
                                  final option = AppTheme.seedOptions[index];
                                  final isSelected =
                                      themeProvider.selectedSeedColor
                                          .toARGB32() ==
                                      option.seedColor.toARGB32();

                                  return ThemeColorCircle(
                                    seedColor: option.seedColor,
                                    name: option.name,
                                    isSelected: isSelected,
                                    brightness: currentBrightness,
                                    dynamicSchemeVariant:
                                        themeProvider.dynamicSchemeVariant,
                                    onTap: () {
                                      themeProvider.setSelectedSeedColor(
                                        option.seedColor,
                                        legacyType: option.legacyType,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Theme Variant Dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Theme Variant',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            _buildVariantMenuButton(
                              context,
                              themeProvider,
                              colorScheme,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Haptic Feedback Toggle
                      SwitchListTile(
                        title: const Text('Haptic Feedback'),
                        subtitle: const Text(
                          'Tactile response on taps and interactions',
                        ),
                        value: themeProvider.hapticFeedbackEnabled,
                        onChanged: (value) =>
                            themeProvider.setHapticFeedbackEnabled(value),
                        secondary: const Icon(Icons.vibration_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notifications Section
                  _buildSectionTitle(theme, 'Notifications'),
                  _buildSettingsCard(
                    theme,
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Notifications'),
                        subtitle: const Text('Receive daily habit reminders'),
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        secondary: const Icon(Icons.notifications_rounded),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_rounded),
                        title: const Text('Test Notification'),
                        subtitle: const Text(
                          'Send a test reminder notification now',
                        ),
                        trailing: const Icon(Icons.send_rounded, size: 20),
                        onTap: () async {
                          themeProvider.triggerHaptic();
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await NotificationService().showTestNotification();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Test notification sent! Check notification tray.',
                                ),
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to send notification: $e',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Data Management Section
                  _buildSectionTitle(theme, 'Data Management'),
                  _buildSettingsCard(
                    theme,
                    children: [
                      // Archived Habits
                      ListTile(
                        leading: const Icon(Icons.archive_rounded),
                        title: const Text('Archived Habits'),
                        subtitle: const Text(
                          'Restore or permanently delete archived habits',
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: () {
                          Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          ).triggerHaptic();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ArchivedHabitsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Export Options
                      ExpansionTile(
                        leading: const Icon(Icons.upload_file_rounded),
                        title: const Text('Export Data'),
                        subtitle: const Text(
                          'Backup habits to JSON or CSV spreadsheet',
                        ),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.code_rounded),
                            title: const Text('Export as JSON'),
                            subtitle: const Text(
                              'Full backup with all completions and settings',
                            ),
                            onTap: _exportToJson,
                          ),
                          ListTile(
                            leading: const Icon(Icons.table_chart_rounded),
                            title: const Text('Export as CSV'),
                            subtitle: const Text(
                              'Spreadsheet format for Excel/Sheets',
                            ),
                            onTap: _exportToCsv,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Import Options
                      ExpansionTile(
                        leading: const Icon(Icons.download_rounded),
                        title: const Text('Import Data'),
                        subtitle: const Text(
                          'Restore habits from JSON or CSV backup',
                        ),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.code_rounded),
                            title: const Text('Import from JSON'),
                            subtitle: const Text('Restore full backup file'),
                            onTap: _importFromJson,
                          ),
                          ListTile(
                            leading: const Icon(Icons.table_chart_rounded),
                            title: const Text('Import from CSV'),
                            subtitle: const Text('Import habits from CSV file'),
                            onTap: _importFromCsv,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: Icon(
                          Icons.delete_forever_rounded,
                          color: colorScheme.error,
                        ),
                        title: Text(
                          'Clear All Data',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Delete all habits and history permanently',
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.error,
                        ),
                        onTap: _clearAllData,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // About Section
                  _buildSectionTitle(theme, 'About'),
                  _buildSettingsCard(
                    theme,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: const Text('App Version'),
                        trailing: Text(
                          '1.0.0',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.star_rounded),
                        title: const Text('Rate HabitBee'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _rateApp,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.emoji_nature_rounded),
                        title: const Text('About HabitBee'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showAboutDialog(theme),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.share_rounded),
                        title: const Text('Share HabitBee'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _shareApp,
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantMenuButton(
    BuildContext context,
    ThemeProvider themeProvider,
    ColorScheme colorScheme,
  ) {
    final currentVariant = themeProvider.dynamicSchemeVariant;
    final currentOption = AppTheme.variantOptions.firstWhere(
      (opt) => opt.variant == currentVariant,
      orElse: () => AppTheme.variantOptions.first,
    );

    return PopupMenuButton<DynamicSchemeVariant>(
      initialValue: currentVariant,
      tooltip: 'Select Variant',
      onSelected: (variant) {
        themeProvider.setDynamicSchemeVariant(variant);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) {
        return AppTheme.variantOptions.map((opt) {
          final isSelected = opt.variant == currentVariant;
          return PopupMenuItem<DynamicSchemeVariant>(
            value: opt.variant,
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        opt.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        opt.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentOption.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8, top: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Renders each child as a card in one Android-style grouped stack:
  /// larger radius on the outer corners of the first/last items, smaller
  /// radius in-between, with a tiny gap so the background peeks through.
  Widget _buildSettingsCard(ThemeData theme, {required List<Widget> children}) {
    final items = children.where((w) => w is! SizedBox).toList();

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: GroupedCard.innerGap),
          GroupedCard(
            position: groupedPosition(i, items.length),
            padding: EdgeInsets.zero,
            child: items[i],
          ),
        ],
      ],
    );
  }
}
