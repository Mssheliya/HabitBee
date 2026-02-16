import 'package:flutter/material.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/data/models/app_settings.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentColors = themeProvider.currentThemeColors;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: currentColors.primary,
        foregroundColor: Colors.black,
        title: const Text('Theme Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Mode Section
          _buildSectionTitle(theme, 'Theme Mode'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Use System Theme'),
                  subtitle: const Text('Follow device theme settings'),
                  value: themeProvider.useSystemTheme,
                  onChanged: (value) => themeProvider.setUseSystemTheme(value),
                  secondary: const Icon(Icons.brightness_auto),
                  activeColor: currentColors.primary,
                ),
                if (!themeProvider.useSystemTheme) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark theme'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.setDarkMode(value),
                    secondary: const Icon(Icons.dark_mode),
                    activeColor: currentColors.primary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Color Theme Section
          _buildSectionTitle(theme, 'Color Theme'),
          _buildThemeGrid(themeProvider, currentColors),
          const SizedBox(height: 24),

          // Custom Theme Section
          if (themeProvider.themeType == AppThemeType.custom) ...[
            _buildSectionTitle(theme, 'Custom Colors'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: currentColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    title: const Text('Primary Color'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showColorPicker(context, themeProvider, true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: currentColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    title: const Text('Secondary Color'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showColorPicker(context, themeProvider, false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Font Scale Section
          _buildSectionTitle(theme, 'Text Size'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.text_decrease, size: 20),
                      Expanded(
                        child: Slider(
                          value: themeProvider.fontScale,
                          min: 0.8,
                          max: 1.4,
                          divisions: 6,
                          activeColor: currentColors.primary,
                          onChanged: (value) => themeProvider.setFontScale(value),
                        ),
                      ),
                      const Icon(Icons.text_increase, size: 24),
                    ],
                  ),
                  Center(
                    child: Text(
                      '${(themeProvider.fontScale * 100).toInt()}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Preview Text',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16 * themeProvider.fontScale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Preview Section
          _buildSectionTitle(theme, 'Preview'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary Button'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined Button'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Text Button'),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'Text Field Preview',
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildThemeGrid(ThemeProvider themeProvider, ThemeColors currentColors) {
    final themes = AppTheme.themeColors.entries.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final entry = themes[index];
            final isSelected = themeProvider.themeType == entry.key;
            final colors = entry.value;

            return InkWell(
              onTap: () => themeProvider.setThemeType(entry.key),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? currentColors.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      colors.name,
                      style: TextStyle(
                        fontSize: 12,
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
            );
          },
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider, bool isPrimary) {
    Color pickerColor = isPrimary
        ? Color(themeProvider.settings.customPrimaryColor ?? AppTheme.primaryYellow.value)
        : Color(themeProvider.settings.customSecondaryColor ?? AppTheme.darkYellow.value);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isPrimary ? 'Pick Primary Color' : 'Pick Secondary Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              pickerAreaBorderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2.0),
                topRight: Radius.circular(2.0),
              ),
              hexInputBar: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Select'),
              onPressed: () {
                if (isPrimary) {
                  themeProvider.setCustomColors(
                    pickerColor,
                    Color(themeProvider.settings.customSecondaryColor ?? AppTheme.darkYellow.value),
                  );
                } else {
                  themeProvider.setCustomColors(
                    Color(themeProvider.settings.customPrimaryColor ?? AppTheme.primaryYellow.value),
                    pickerColor,
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
