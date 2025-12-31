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

  final List<Widget> _pages = const [
    AdminHome(),
    AdminCoursesScreen(),
    AdminUsersScreen(),
    AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.08),
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
                  color: cs.primary,
                );
              }
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              );
            }),
          ),
          child: NavigationBar(
            height: 70,
            backgroundColor: cs.surface,
            elevation: 0,
            selectedIndex: _currentIndex,
            indicatorColor: cs.primary.withOpacity(0.12),
            animationDuration: const Duration(milliseconds: 500),
            onDestinationSelected: _onTabSelected,
            destinations: [
              _buildNavDest(
                label: "Dashboard",
                icon: HugeIcons.strokeRoundedHome01,
                colorScheme: cs,
              ),
              _buildNavDest(
                label: "Courses",
                icon: HugeIcons.strokeRoundedBookOpen01,
                colorScheme: cs,
              ),
              _buildNavDest(
                label: "Users",
                icon: HugeIcons.strokeRoundedUserGroup,
                colorScheme: cs,
              ),
              _buildNavDest(
                label: "Profile",
                icon: HugeIcons.strokeRoundedUser,
                colorScheme: cs,
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

  NavigationDestination _buildNavDest({
    required String label,
    required dynamic icon,
    required ColorScheme colorScheme,
  }) {
    return NavigationDestination(
      icon: HugeIcon(icon: icon, size: 24, color: colorScheme.onSurfaceVariant),
      selectedIcon: HugeIcon(icon: icon, size: 24, color: colorScheme.primary),
      label: label,
    );
  }
}
