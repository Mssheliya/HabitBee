import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/data/services/storage_service.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/core/services/notification_service.dart';
import 'package:habit_bee/src/core/widgets/material_loading_indicator.dart';
import 'package:habit_bee/src/features/settings/presentation/theme_settings_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:habit_bee/src/data/models/app_settings.dart';
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
    setState(() {
      _notificationsEnabled = settings.notificationsEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setDarkMode(value);
  }

  Future<void> _toggleNotifications(bool value) async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final settings = await storageService.getSettings();
    await storageService.saveSettings(settings.copyWith(notificationsEnabled: value));
    setState(() {
      _notificationsEnabled = value;
    });
  }

  // Export data to JSON file
  Future<void> _exportToJson() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final data = await storageService.exportData();
      final jsonData = jsonEncode(data);
      
      // Create file with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'habitbee_backup_$timestamp.json';
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonData);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'HabitBee Backup - $timestamp',
        subject: 'HabitBee Data Backup',
      );
      
      // Clean up temp file after sharing
      if (await file.exists()) {
        await file.delete();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup exported successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  // Export data to CSV file
  Future<void> _exportToCsv() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final csvData = await storageService.exportToCsv();
      
      // Create file with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'habitbee_export_$timestamp.csv';
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsString(csvData);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'HabitBee CSV Export - $timestamp',
        subject: 'HabitBee Data Export',
      );
      
      // Clean up temp file after sharing
      if (await file.exists()) {
        await file.delete();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported to CSV successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV export failed: $e')),
      );
    }
  }

  // Import data from JSON file
  Future<void> _importFromJson() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }
      
      final file = result.files.first;
      if (file.path == null) {
        throw Exception('Invalid file path');
      }
      
      // Read file
      final fileContent = await File(file.path!).readAsString();
      final data = jsonDecode(fileContent) as Map<String, dynamic>;
      
      // Confirm import
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryYellow),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        final storageService = Provider.of<StorageService>(context, listen: false);
        await storageService.importData(data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully!')),
        );
        
        // Refresh UI
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  // Import data from CSV file
  Future<void> _importFromCsv() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }
      
      final file = result.files.first;
      if (file.path == null) {
        throw Exception('Invalid file path');
      }
      
      // Confirm import
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryYellow),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        final storageService = Provider.of<StorageService>(context, listen: false);
        final fileContent = await File(file.path!).readAsString();
        final importedCount = await storageService.importFromCsv(fileContent);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$importedCount habits imported successfully!')),
        );
        
        // Refresh UI
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV import failed: $e')),
      );
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.clearAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared')),
      );
    }
  }

  void _showAboutDialog(ThemeData theme, ThemeColors currentColors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: currentColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_nature, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 12),
            const Text('HabitBee'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your personal habit tracker',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'HabitBee helps you build positive habits and track your daily progress. Stay motivated and achieve your goals!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 18, color: currentColors.primary),
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
                Icon(Icons.code, size: 18, color: currentColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: currentColors.primary)),
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
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.habitbee.app');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open store')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentColors = themeProvider.currentThemeColors;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: MaterialLoadingIndicator(
            size: 48,
            color: Theme.of(context).colorScheme.primary,
            style: LoadingStyle.bouncing,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Settings',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Appearance Section
                  _buildSectionTitle(theme, 'Appearance'),
                  _buildSettingsCard(
                    theme,
                    children: [
                      // Quick Theme Selection
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Select Theme',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ThemeSettingsScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.tune, size: 18),
                                  label: const Text('More Options'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildThemeSelector(context, theme, themeProvider, currentColors),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Enable dark theme'),
                        value: themeProvider.isDarkMode,
                        onChanged: _toggleDarkMode,
                        secondary: const Icon(Icons.dark_mode),
                        activeColor: currentColors.primary,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Use System Theme'),
                        subtitle: const Text('Follow device theme settings'),
                        value: themeProvider.useSystemTheme,
                        onChanged: (value) => themeProvider.setUseSystemTheme(value),
                        secondary: const Icon(Icons.brightness_auto),
                        activeColor: currentColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Notifications Section
                  _buildSectionTitle(theme, 'Notifications'),
                  _buildSettingsCard(
                    theme,
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Notifications'),
                        subtitle: const Text('Receive habit reminders'),
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        secondary: const Icon(Icons.notifications),
                        activeColor: currentColors.primary,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.notifications_active, color: currentColors.primary),
                        title: const Text('Test Notification'),
                        subtitle: const Text('Send a test notification now'),
                        trailing: const Icon(Icons.send),
                        onTap: () async {
                          try {
                            await NotificationService().showTestNotification();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Test notification sent! Check your notification tray.')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to send notification: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Data Management Section
                  _buildSectionTitle(theme, 'Data Management'),
                  _buildSettingsCard(
                    theme,
                    children: [
                      // Export Options
                      ExpansionTile(
                        leading: Icon(Icons.upload, color: currentColors.primary),
                        title: const Text('Export Data'),
                        subtitle: const Text('Backup your habits to file (JSON or CSV)'),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.code),
                            title: const Text('Export as JSON'),
                            subtitle: const Text('Full backup with all data'),
                            onTap: _exportToJson,
                          ),
                          ListTile(
                            leading: const Icon(Icons.table_chart),
                            title: const Text('Export as CSV'),
                            subtitle: const Text('Spreadsheet format'),
                            onTap: _exportToCsv,
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      // Import Options
                      ExpansionTile(
                        leading: Icon(Icons.download, color: currentColors.primary),
                        title: const Text('Import Data'),
                        subtitle: const Text('Restore from file (JSON or CSV)'),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.code),
                            title: const Text('Import from JSON'),
                            subtitle: const Text('Restore full backup'),
                            onTap: _importFromJson,
                          ),
                          ListTile(
                            leading: const Icon(Icons.table_chart),
                            title: const Text('Import from CSV'),
                            subtitle: const Text('Import habits from CSV'),
                            onTap: _importFromCsv,
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text(
                          'Clear All Data',
                          style: TextStyle(color: Colors.red),
                        ),
                        subtitle: const Text('Delete all habits and progress'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.red),
                        onTap: _clearAllData,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  _buildSectionTitle(theme, 'About'),
                  _buildSettingsCard(
                    theme,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('App Version'),
                        trailing: Text(
                          '1.0.0',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.star),
                        title: const Text('Rate HabitBee'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _rateApp,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('About HabitBee'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showAboutDialog(theme, currentColors),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text('Share HabitBee'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _shareApp,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeData theme, ThemeProvider themeProvider, ThemeColors currentColors) {
    final themes = AppTheme.themeColors.entries.toList();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final entry = themes[index];
          final isSelected = themeProvider.themeType == entry.key;
          final colors = entry.value;
          final isCustom = entry.key == AppThemeType.custom;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => themeProvider.setThemeType(entry.key),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? currentColors.primary : Colors.transparent,
                    width: 2,
                  ),
                  color: isSelected 
                    ? currentColors.primary.withOpacity(0.1) 
                    : theme.cardTheme.color,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isCustom
                          ? const Icon(
                              Icons.colorize,
                              color: Colors.white,
                              size: 20,
                            )
                          : (isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      colors.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? currentColors.primary : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme, {required List<Widget> children}) {
    return Container(
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
        children: children,
      ),
    );
  }
}
