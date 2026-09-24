import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'shirazi_colors.dart';
import 'shirazi_typography.dart';
import '../constants/shirazi_spacing.dart';

class ShiraziTheme {
  ShiraziTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ShiraziColors.background,
      primaryColor: ShiraziColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: ShiraziColors.primary,
        onPrimary: ShiraziColors.onPrimary,
        primaryContainer: ShiraziColors.primaryContainer,
        onPrimaryContainer: ShiraziColors.onPrimaryContainer,
        secondary: ShiraziColors.secondary,
        onSecondary: ShiraziColors.onSecondary,
        secondaryContainer: ShiraziColors.secondaryContainer,
        onSecondaryContainer: ShiraziColors.onSecondaryContainer,
        tertiary: ShiraziColors.tertiary,
        surface: ShiraziColors.surface,
        onSurface: ShiraziColors.onSurface,
        onSurfaceVariant: ShiraziColors.onSurfaceVariant,
        outline: ShiraziColors.outline,
        outlineVariant: ShiraziColors.outlineVariant,
        error: ShiraziColors.error,
        onError: ShiraziColors.onError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: ShiraziColors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ShiraziRadius.roundedLg,
          side: const BorderSide(color: ShiraziColors.outlineVariant, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShiraziColors.surfaceContainerLowest,
        hintStyle: ShiraziTypography.bodyMd(color: ShiraziColors.outline),
        border: OutlineInputBorder(
          borderRadius: ShiraziRadius.roundedXl,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ShiraziRadius.roundedXl,
          borderSide: const BorderSide(color: ShiraziColors.outlineVariant, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ShiraziRadius.roundedXl,
          borderSide: const BorderSide(color: ShiraziColors.primary, width: 1.0),
        ),
      ),
    );
  }
}
