import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  // =========================
  // 🌞 LIGHT THEME (Smoother Shadows)
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
      // ☁️ SMOOTHER: Reduced opacity from 0.4 to 0.15 for a soft, natural drop shadow
      shadowColor: Colors.black.withOpacity(0.15),
      elevation: 6, // Slight bump in elevation helps blur the softer shadow
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 2,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withOpacity(0.15),
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
          color: AppColors.onSurface,
        );
      }),
    ),
  );

  // =========================
  // 🌙 DARK THEME (Subtle Glow)
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

    // ✅ FIXED CARD THEME
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      surfaceTintColor: AppColors.primary, // Keeps the slight surface tint
      // ☁️ SMOOTHER: Reduced from 0.4 to 0.25.
      // This keeps the colored "glow" but removes the harsh neon edge.
      shadowColor: AppColors.primary.withOpacity(0.25),

      elevation: 6, // Higher elevation = more blur radius = smoother look
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

    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 8,
      // ☁️ SMOOTHER: Reduced black shadow opacity to blend better with dark background
      shadowColor: Colors.black.withOpacity(0.3),
      backgroundColor: const Color(0xFF1E1E1E),
      indicatorColor: AppColors.primary,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.black);
        }
        return const IconThemeData(color: Color(0xFFE0E0E0));
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
          color: Color(0xFFE0E0E0),
        );
      }),
    ),
  );
}
