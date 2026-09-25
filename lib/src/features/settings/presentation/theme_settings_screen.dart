import 'package:flutter/material.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/core/widgets/theme_color_circle.dart';
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
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    final currentBrightness = themeProvider.themeMode == ThemeMode.dark
        ? Brightness.dark
        : (themeProvider.themeMode == ThemeMode.light
            ? Brightness.light
            : MediaQuery.platformBrightnessOf(context));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Theme & Appearance'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Theme Mode Section
          _buildSectionTitle(theme, 'Theme Mode'),
          _buildCard(
            theme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_rounded, size: 18),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_rounded, size: 18),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_rounded, size: 18),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (newSelection) {
                      themeProvider.setThemeMode(newSelection.first);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Palette / Color Selection Grid
          _buildSectionTitle(theme, 'Theme Color Palette'),
          _buildCard(
            theme,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Seed Color',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showCustomColorPicker(context, themeProvider),
                      icon: const Icon(Icons.colorize_rounded, size: 16),
                      label: const Text('Custom'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: AppTheme.seedOptions.length,
                  itemBuilder: (context, index) {
                    final option = AppTheme.seedOptions[index];
                    final isSelected = themeProvider.selectedSeedColor.toARGB32() ==
                        option.seedColor.toARGB32();

                    return ThemeColorCircle(
                      seedColor: option.seedColor,
                      name: option.name,
                      isSelected: isSelected,
                      brightness: currentBrightness,
                      dynamicSchemeVariant: themeProvider.dynamicSchemeVariant,
                      size: 48,
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
          const SizedBox(height: 20),

          // Dynamic Scheme Variant Section
          _buildSectionTitle(theme, 'Material 3 Dynamic Scheme Variant'),
          _buildCard(
            theme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuning Algorithm',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Defines how tones and saturation are harmonized from your seed color.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppTheme.variantOptions.map((opt) {
                        final isSelected =
                            themeProvider.dynamicSchemeVariant == opt.variant;
                        return ChoiceChip(
                          label: Text(
                            opt.name,
                            style: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: colorScheme.primaryContainer,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          side: BorderSide.none,
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) {
                              themeProvider.setDynamicSchemeVariant(opt.variant);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Font Scale Section
          _buildSectionTitle(theme, 'Text Scale'),
          _buildCard(
            theme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.text_decrease_rounded, size: 20),
                        Expanded(
                          child: Slider(
                            value: themeProvider.fontScale,
                            min: 0.8,
                            max: 1.3,
                            divisions: 5,
                            onChanged: (value) => themeProvider.setFontScale(value),
                          ),
                        ),
                        const Icon(Icons.text_increase_rounded, size: 24),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Size: ${(themeProvider.fontScale * 100).toInt()}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'HabitBee preview text',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Live Component Preview Section
          _buildSectionTitle(theme, 'Live Theme Preview'),
          _buildCard(
            theme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => themeProvider.triggerHaptic(),
                            child: const Text('Filled Button'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => themeProvider.triggerHaptic(),
                            child: const Text('Tonal Button'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => themeProvider.triggerHaptic(),
                            child: const Text('Outlined'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: () => themeProvider.triggerHaptic(),
                            child: const Text('Text Button'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const TextField(
                      decoration: InputDecoration(
                        hintText: 'Material 3 input field',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('Chip'),
                        ),
                        FloatingActionButton.small(
                          heroTag: 'preview_fab',
                          onPressed: () => themeProvider.triggerHaptic(),
                          child: const Icon(Icons.add_rounded),
                        ),
                        Switch(
                          value: true,
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  void _showCustomColorPicker(BuildContext context, ThemeProvider themeProvider) {
    Color pickerColor = themeProvider.selectedSeedColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick Custom Seed Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(16)),
              hexInputBar: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Select Color'),
              onPressed: () {
                themeProvider.setSelectedSeedColor(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
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

  Widget _buildCard(ThemeData theme, {required List<Widget> children}) {
    // Same card background color logic as the settings page GroupedCards
    final cardColor = theme.cardTheme.color ??
        (theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4));
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
