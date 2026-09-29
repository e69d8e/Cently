import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'category_manage/category_manage_screen.dart';
import 'home/home_screen.dart';
import 'record/add_record_screen.dart';
import 'settings/settings_screen.dart';
import 'stats/stats_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  /// Allows child widgets to programmatically navigate to a tab
  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
    if (state != null) {
      state._onTabSelected(index);
    }
  }

  /// Returns the re-select signal notifier of a tab. Incrementing it means the
  /// user tapped the already-active tab again (e.g. scroll current list to top).
  /// Returns null when the screen is displayed outside [MainNavigationScreen].
  static ValueNotifier<int>? tabReselectSignal(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
    if (state == null || index < 0 || index >= state._tabReselectSignals.length) {
      return null;
    }
    return state._tabReselectSignals[index];
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  /// Per-tab counters bumped when the user taps the already-active tab.
  final List<ValueNotifier<int>> _tabReselectSignals =
      List.generate(4, (_) => ValueNotifier(0));

  final List<Widget> _screens = const [
    HomeScreen(),
    StatsScreen(),
    CategoryManageScreen(),
    SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      // Re-tapping the active tab: notify listeners (e.g. scroll to top)
      _tabReselectSignals[index].value++;
      return;
    }
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    for (final signal in _tabReselectSignals) {
      signal.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_add_record_fab',
        onPressed: () {
          HapticFeedback.mediumImpact();
          AddRecordScreen.show(context);
        },
        backgroundColor: isDark ? const Color(0xFFF8FAFC) : AppColors.primary,
        foregroundColor: isDark ? AppColors.primary : Colors.white,
        elevation: isDark ? 4 : 3,
        shape: CircleBorder(
          side: BorderSide(
            color: isDark ? Colors.white70 : Colors.white24,
            width: 1.5,
          ),
        ),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.receipt_long_outlined, Icons.receipt_long_rounded, '明细', isDark),
                  _buildNavItem(1, Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, '统计', isDark),
                  const SizedBox(width: 48), // Space for centered notched FAB
                  _buildNavItem(2, Icons.category_outlined, Icons.category_rounded, '分类', isDark),
                  _buildNavItem(3, Icons.settings_outlined, Icons.settings_rounded, '设置', isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
    bool isDark,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? (isDark ? AppColors.textPrimaryDark : AppColors.primary)
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary);

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
