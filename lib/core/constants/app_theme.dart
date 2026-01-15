import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  // =========================
  // 🌞 LIGHT THEME (White Body + Black Navbar)
  // =========================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    brightness: Brightness.light,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),

    scaffoldBackgroundColor: AppColors.surface,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.onSurface),
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.15),
      elevation: 6,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // ✅ LIGHT MODE NAVBAR: Black Background
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 0,
      backgroundColor: const Color(0xFF1E1E1E), // 🖤 Dark Grey/Black
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primary,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.white);
        }
        return const IconThemeData(color: Color(0xFFB0B0B0)); // Light Grey
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB0B0B0),
        );
      }),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFFB0B0B0),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // =========================
  // 🌙 DARK THEME (Dark Body + White/Light Navbar)
  // =========================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    brightness: Brightness.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF141414),
      onSurface: const Color(0xFFE0E0E0),
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),

    scaffoldBackgroundColor: const Color(0xFF141414),

    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      surfaceTintColor: AppColors.primary,
      shadowColor: AppColors.primary.withOpacity(0.25),
      elevation: 6,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFE0E0E0)),
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE0E0E0),
      ),
    ),

    // ✅ DARK MODE NAVBAR: White/Light Background
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 8,
      shadowColor: Colors.white.withOpacity(0.1),

      // ☁️ BACKGROUND: Light Grey / White
      backgroundColor: const Color(0xFFF5F5F5),
      surfaceTintColor: Colors.transparent,

      indicatorColor: AppColors.primary.withOpacity(0.2), // Softer tint

      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          // Selected: Primary Color (Darker for contrast on white)
          return const IconThemeData(color: AppColors.primary);
        }
        // Unselected: Dark Grey (visible on white bg)
        return const IconThemeData(color: Color(0xFF1E1E1E));
      }),

      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E1E1E), // Dark text
        );
      }),
    ),

    // ✅ Fallback for BottomNavigationBar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFF5F5F5), // ☁️ White/Light
      elevation: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFF1E1E1E), // Dark Grey Icons
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
