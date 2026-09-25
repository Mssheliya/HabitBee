import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/core/widgets/donut_progress_icon.dart';
import 'package:habit_bee/src/features/home/presentation/home_screen.dart';
import 'package:habit_bee/src/features/progress/presentation/progress_screen.dart';
import 'package:habit_bee/src/features/settings/presentation/settings_screen.dart';
import 'package:habit_bee/src/core/services/update_service.dart';

// Export state classes for MainShell
export 'package:habit_bee/src/features/progress/presentation/progress_screen.dart' show ProgressScreenState;

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  // Keys for screens to refresh when tabs are switched
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ProgressScreenState> _progressKey = GlobalKey<ProgressScreenState>();

  @override
  void initState() {
    super.initState();
    _checkForUpdateInBackground();
  }

  Future<void> _checkForUpdateInBackground() async {
    final updateInfo = await UpdateService.checkForUpdate();
    if (updateInfo != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          UpdateService.showUpdateDialog(context, updateInfo);
        }
      });
    }
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });

    // Refresh the selected tab's data after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index == 0) {
        _homeKey.currentState?.refreshHabits();
      } else if (index == 1) {
        _progressKey.currentState?.refreshData();
      }
    });
  }

  void _onPopInvoked(bool didPop, dynamic result) {
    if (didPop) return;

    // If not on habits tab, go to habits tab first
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return; // Don't exit app yet, user is redirected to home
    }

    // On habits tab - close app immediately on single press
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    debugPrint('MainShell: building with index $_currentIndex, darkMode=$isDarkMode');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        backgroundColor: isDarkMode ? AppTheme.black : AppTheme.offWhite,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(key: _homeKey),
            ProgressScreen(key: _progressKey),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(isDarkMode),
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDarkMode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardBg = theme.cardTheme.color ??
        (isDarkMode
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4));
    final iconColor = colorScheme.onSurfaceVariant;
    final selectedColor = colorScheme.primary;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: cardBg,
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              iconBuilder: (color) => Icon(Icons.home_rounded, color: color, size: 22),
              label: 'Habits',
              index: 0,
              defaultColor: iconColor,
              selectedColor: selectedColor,
            ),
            _buildNavItem(
              iconBuilder: (color) => SegmentedDonutIcon(color: color, size: 22),
              label: 'Progress',
              index: 1,
              defaultColor: iconColor,
              selectedColor: selectedColor,
            ),
            _buildNavItem(
              iconBuilder: (color) => Icon(Icons.settings_rounded, color: color, size: 22),
              label: 'Settings',
              index: 2,
              defaultColor: iconColor,
              selectedColor: selectedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Widget Function(Color color) iconBuilder,
    required String label,
    required int index,
    required Color defaultColor,
    required Color selectedColor,
  }) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Provider.of<ThemeProvider>(context, listen: false).triggerHaptic();
        _onItemTapped(index);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          scale: isSelected ? 1.0 : 0.92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pill indicator only on the icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                width: 58,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.secondaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: iconBuilder(
                    isSelected ? colorScheme.onSecondaryContainer : defaultColor,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Text label outside the pill
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 10.5,
                  letterSpacing: 0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
