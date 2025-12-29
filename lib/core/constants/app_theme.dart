import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: AppColors.surface,

    // FIX: Explicitly set thicker weights for everything
    textTheme: const TextTheme(
      // HEADLINES: Use Bold (w700) or ExtraBold (w800)
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800, // Thicker than before
        color: AppColors.onSurface,
        letterSpacing: -0.5,
      ),

      // BODY TEXT: Default to Medium (w500) or SemiBold (w600)
      // instead of Normal (w400) which looks thin in Nunito.
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600, // Much easier to read
        color: Color(0xFF001E45), // Darker than standard black for contrast
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600, // Thicker for subtitles/links
        color: Color(0xFF001E45),
      ),
    ),

    // INPUT FIELDS: Make text inside inputs thicker
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      prefixIconColor: Colors.grey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      // Labels and Hint text need to be readable too
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
      hintStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.black38,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),

    // BUTTONS: Make text bold
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w800, // Extra Bold for buttons
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}
