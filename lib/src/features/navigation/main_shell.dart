import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:habit_bee/src/core/theme/app_theme.dart';
import 'package:habit_bee/src/core/theme/theme_provider.dart';
import 'package:habit_bee/src/features/home/presentation/home_screen.dart';
import 'package:habit_bee/src/features/analytics/presentation/analytics_screen.dart';
import 'package:habit_bee/src/features/progress/presentation/progress_screen.dart';
import 'package:habit_bee/src/features/settings/presentation/settings_screen.dart';
import 'package:habit_bee/src/features/add_habit/presentation/add_habit_screen.dart';

// Export state classes for MainShell
export 'package:habit_bee/src/features/analytics/presentation/analytics_screen.dart' show AnalyticsScreenState;
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
  final GlobalKey<AnalyticsScreenState> _analyticsKey = GlobalKey<AnalyticsScreenState>();
  final GlobalKey<ProgressScreenState> _progressKey = GlobalKey<ProgressScreenState>();

  void _onItemTapped(int index) {
    if (index == 2) {
      _showAddHabitScreen();
    } else {
      setState(() {
        _currentIndex = index;
      });
      
      // Refresh the selected tab's data after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (index == 1) {
          _analyticsKey.currentState?.refreshData();
        } else if (index == 3) {
          _progressKey.currentState?.refreshData();
        }
      });
    }
  }

  Future<void> _showAddHabitScreen() async {
    debugPrint('MainShell: Opening AddHabitScreen');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddHabitScreen(),
      ),
    );
    
    debugPrint('MainShell: AddHabitScreen returned: $result');
    
    // If habit was saved (result == true), refresh the home screen
    if (result == true) {
      debugPrint('MainShell: Refreshing home screen');
      if (_homeKey.currentState != null) {
        _homeKey.currentState!.refreshHabits();
      }
    }
  }

  void _onPopInvoked(bool didPop) {
    if (didPop) return;

    // If not on home tab, go to home tab first
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return; // Don't exit app yet, user is redirected to home
    }

    // On home tab - close app immediately on single press
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    debugPrint('MainShell: building with index $_currentIndex, darkMode=$isDarkMode');
    
    return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
        backgroundColor: isDarkMode ? AppTheme.black : AppTheme.offWhite,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(key: _homeKey),
            AnalyticsScreen(key: _analyticsKey),
            const SizedBox.shrink(), // Placeholder for FAB
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
    final bgColor = isDarkMode ? AppTheme.darkGrey : AppTheme.white;
    final iconColor = isDarkMode ? AppTheme.lightGrey : AppTheme.mediumGrey;
    final selectedColor = theme.colorScheme.primary;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, 'Home', 0, iconColor, selectedColor),
            _buildNavItem(Icons.analytics_rounded, 'Analytics', 1, iconColor, selectedColor),
            _buildCenterButton(),
            _buildNavItem(Icons.trending_up_rounded, 'Progress', 3, iconColor, selectedColor),
            _buildNavItem(Icons.settings_rounded, 'Settings', 4, iconColor, selectedColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color defaultColor, Color selectedColor) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : defaultColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : defaultColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _showAddHabitScreen,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: AppTheme.black,
          size: 32,
        ),
      ),
    );
  }
}
