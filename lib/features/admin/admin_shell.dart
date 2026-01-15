import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'admin_home.dart';
import 'courses/admin_courses_screen.dart';
import 'users/admin_users_screen.dart';
import 'profile/admin_profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminHome(),
    AdminCoursesScreen(),
    AdminUsersScreen(),
    AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // ✅ Check if we are in Dark Mode
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ✅ 1. Allow content to scroll behind the navbar
      extendBody: true,

      body: Theme(
        data: theme.copyWith(
          appBarTheme: theme.appBarTheme.copyWith(
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),

      // ✅ 2. Floating Navbar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Material(
          elevation: 12,
          shadowColor: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(15),

          // 🛑 COLOR LOGIC:
          // Light Mode -> Black Bar (0xFF1E1E1E)
          // Dark Mode -> White/Light Bar (0xFFF5F5F5)
          color: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1E1E1E),

          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavBarItem(
                  asset: AppIcons.home,
                  label: "DASHBOARD",
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                _NavBarItem(
                  asset: AppIcons.book,
                  label: "COURSE",
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                _NavBarItem(
                  asset: AppIcons.user,
                  label: "USER",
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                _NavBarItem(
                  asset: AppIcons.avatar,
                  label: "PROFILE",
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Reusable "Chip Style" Nav Item
class _NavBarItem extends StatelessWidget {
  final String asset;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark; // ✅ Added to handle icon colors

  const _NavBarItem({
    required this.asset,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuad,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            AppSvgIcon(
              asset: asset,
              size: 24,
              // 🛑 ICON COLOR LOGIC:
              // Selected -> Primary
              // Unselected (Light Mode/Black Bar) -> Light Grey (0xFFB0B0B0)
              // Unselected (Dark Mode/White Bar) -> Dark Grey (0xFF1E1E1E)
              color: isSelected
                  ? colorScheme.primary
                  : (isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFB0B0B0)),
            ),

            // Label (Visible only when selected)
            if (isSelected) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
