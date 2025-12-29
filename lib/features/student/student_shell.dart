import 'package:artgrade/features/student/profile/student_profile_screen.dart';
import 'package:artgrade/features/student/progress/student_progress_screen.dart';
import 'package:artgrade/features/student/student_course_navigator.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

// Import your actual Home Screen
import 'student_home.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  // Define your pages here
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
      backgroundColor: const Color(0xFFF8F9FC),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                );
              }
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              );
            }),
          ),
          child: NavigationBar(
            height: 70,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedIndex: _currentIndex,
            indicatorColor: colorScheme.primary.withOpacity(0.1),
            animationDuration: const Duration(milliseconds: 600),
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: [
              _buildNavDest(
                label: "Home",
                icon: HugeIcons.strokeRoundedHome01,
                selectedIcon: HugeIcons
                    .strokeRoundedHome01, // Use filled version if available
                isActive: _currentIndex == 0,
                colorScheme: colorScheme,
              ),
              _buildNavDest(
                label: "Courses",
                icon: HugeIcons.strokeRoundedBookOpen01,
                selectedIcon: HugeIcons.strokeRoundedBookOpen01,
                isActive: _currentIndex == 1,
                colorScheme: colorScheme,
              ),
              _buildNavDest(
                label: "Progress",
                icon: HugeIcons.strokeRoundedChart01,
                selectedIcon: HugeIcons.strokeRoundedChart01,
                isActive: _currentIndex == 2,
                colorScheme: colorScheme,
              ),
              _buildNavDest(
                label: "Profile",
                icon: HugeIcons.strokeRoundedUser,
                selectedIcon: HugeIcons.strokeRoundedUser,
                isActive: _currentIndex == 3,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build consistent navigation destinations
  NavigationDestination _buildNavDest({
    required String label,
    required dynamic icon,
    required dynamic selectedIcon,
    required bool isActive,
    required ColorScheme colorScheme,
  }) {
    return NavigationDestination(
      icon: HugeIcon(icon: icon, size: 24, color: Colors.grey.shade500),
      selectedIcon: HugeIcon(
        icon: selectedIcon,
        size: 24,
        color: colorScheme.primary,
      ),
      label: label,
    );
  }
}
