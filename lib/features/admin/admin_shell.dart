import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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

  // Pages are immutable → mark as final & const where possible
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

    return Scaffold(
      // ✅ Use theme background (keeps same visual, but centralized)
      backgroundColor: theme.scaffoldBackgroundColor,

      // Keeps state of each tab alive (already correct)
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
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
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            selectedIndex: _currentIndex,
            indicatorColor: colorScheme.primary.withOpacity(0.1),
            animationDuration: const Duration(milliseconds: 500),
            onDestinationSelected: _onTabSelected,
            destinations: [
              _buildNavDest(
                label: "Dashboard",
                icon: HugeIcons.strokeRoundedHome01,
                colorScheme: colorScheme,
              ),
              _buildNavDest(
                label: "Courses",
                icon: HugeIcons.strokeRoundedBookOpen01,
                colorScheme: colorScheme,
              ),
              _buildNavDest(
                label: "Users",
                icon: HugeIcons.strokeRoundedUserGroup,
                colorScheme: colorScheme,
              ),
              _buildNavDest(
                label: "Profile",
                icon: HugeIcons.strokeRoundedUser,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  // Helper method (UI unchanged)
  NavigationDestination _buildNavDest({
    required String label,
    required dynamic icon,
    required ColorScheme colorScheme,
  }) {
    return NavigationDestination(
      icon: HugeIcon(icon: icon, size: 24, color: Colors.grey.shade500),
      selectedIcon: HugeIcon(icon: icon, size: 24, color: colorScheme.primary),
      label: label,
    );
  }
}
