import 'package:artgrade/features/student/profile/student_profile_screen.dart';
import 'package:artgrade/features/student/progress/student_progress_screen.dart';
import 'package:artgrade/features/student/student_course_navigator.dart';
import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';

import 'student_home.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const StudentHome(),
    const StudentCoursesNavigator(),
    const StudentProgressScreen(),
    const StudentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ✅ 1. Extend body so content scrolls behind the navbar
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

      // ✅ 2. Floating Navbar (M3 Material Widget)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Material(
          // ✅ High Elevation: Adds Shadow (Light) & Surface Tint (Dark)
          elevation: 12,

          // ✅ Standard Shadow Color
          shadowColor: Colors.black.withOpacity(0.4),

          // ✅ Round Corners
          borderRadius: BorderRadius.circular(15),

          // ✅ Use Card Theme Color: Lighter than Scaffold in Dark Mode
          color: theme.cardTheme.color,

          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavBarItem(
                  asset: AppIcons.home,
                  label: "HOME",
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                  colorScheme: colorScheme,
                ),
                _NavBarItem(
                  asset: AppIcons.book,
                  label: "COURSE",
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                  colorScheme: colorScheme,
                ),
                _NavBarItem(
                  asset: AppIcons.progress,
                  label: "PROGRESS",
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                  colorScheme: colorScheme,
                ),
                _NavBarItem(
                  asset: AppIcons.user,
                  label: "PROFILE",
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Custom Item Widget (Chip Style)
class _NavBarItem extends StatelessWidget {
  final String asset;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavBarItem({
    required this.asset,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
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
            AppSvgIcon(
              asset: asset,
              size: 24,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
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
