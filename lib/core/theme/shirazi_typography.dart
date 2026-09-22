import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shirazi_colors.dart';

/// Bidirectional Typography System honoring Classical Arabic, Urdu Nastaliq & English Academic prose
class ShiraziTypography {
  ShiraziTypography._();

  // Arabic Classical Font (Amiri)
  static TextStyle amiri({
    double fontSize = 18.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = ShiraziColors.onSurface,
    double height = 1.8,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // Scheherazade Quranic / Classical Scholarly Font
  static TextStyle scheherazade({
    double fontSize = 20.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = ShiraziColors.onSurface,
    double height = 1.8,
  }) {
    return GoogleFonts.scheherazadeNew(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // Urdu Nastaliq Font
  static TextStyle urdu({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = ShiraziColors.onSurfaceVariant,
    double height = 2.2,
  }) {
    return GoogleFonts.notoNastaliqUrdu(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // Classical Headings (Noto Serif)
  static TextStyle displayHero({Color color = ShiraziColors.onSurface}) {
    return GoogleFonts.notoSerif(
      fontSize: 34.0,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.01,
      height: 1.3,
      color: color,
    );
  }

  static TextStyle headlineLg({
    Color color = ShiraziColors.onSurface,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.notoSerif(
      fontSize: 26.0,
      fontWeight: fontWeight,
      height: 1.3,
      color: color,
    );
  }

  static TextStyle headlineMd({
    Color color = ShiraziColors.onSurface,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.notoSerif(
      fontSize: 22.0,
      fontWeight: fontWeight,
      height: 1.35,
      color: color,
    );
  }

  static TextStyle headlineSm({
    Color color = ShiraziColors.onSurface,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.notoSerif(
      fontSize: 18.0,
      fontWeight: fontWeight,
      height: 1.4,
      color: color,
    );
  }

  // Modern UI Text (Inter)
  static TextStyle bodyLg({
    Color color = ShiraziColors.onSurface,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.inter(
      fontSize: 18.0,
      fontWeight: fontWeight,
      height: 1.5,
      color: color,
    );
  }

  static TextStyle bodyMd({
    Color color = ShiraziColors.onSurfaceVariant,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.inter(
      fontSize: 14.0,
      fontWeight: fontWeight,
      height: 1.5,
      color: color,
    );
  }

  static TextStyle bodySm({
    Color color = ShiraziColors.onSurfaceVariant,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.inter(
      fontSize: 12.0,
      fontWeight: fontWeight,
      height: 1.4,
      color: color,
    );
  }

  static TextStyle labelMd({
    Color color = ShiraziColors.onSurface,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.inter(
      fontSize: 12.0,
      fontWeight: fontWeight,
      letterSpacing: 0.5,
      color: color,
    );
  }

  static TextStyle labelSm({
    Color color = ShiraziColors.outline,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.inter(
      fontSize: 11.0,
      fontWeight: fontWeight,
      letterSpacing: 0.4,
      color: color,
    );
  }

  // --- Dynamic Language-Aware Typography ---
  static TextStyle dynamicHeadline(
    String lang, {
    double fontSize = 20.0,
    FontWeight fontWeight = FontWeight.bold,
    Color color = ShiraziColors.onSurface,
    double? height,
  }) {
    if (lang == 'ur') {
      return GoogleFonts.notoNastaliqUrdu(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 2.0,
      );
    } else if (lang == 'ar') {
      return GoogleFonts.amiri(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.5,
      );
    } else {
      return GoogleFonts.notoSerif(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.35,
      );
    }
  }

  static TextStyle dynamicBody(
    String lang, {
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = ShiraziColors.onSurfaceVariant,
    double? height,
  }) {
    if (lang == 'ur') {
      return GoogleFonts.notoNastaliqUrdu(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 2.1,
      );
    } else if (lang == 'ar') {
      return GoogleFonts.amiri(
        fontSize: fontSize + 1.5,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.7,
      );
    } else {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.5,
      );
    }
  }

  static TextStyle dynamicLabel(
    String lang, {
    double fontSize = 12.0,
    FontWeight fontWeight = FontWeight.w600,
    Color color = ShiraziColors.onSurface,
    double? letterSpacing,
  }) {
    if (lang == 'ur') {
      return GoogleFonts.notoNastaliqUrdu(
        fontSize: fontSize + 0.5,
        fontWeight: fontWeight,
        color: color,
        height: 1.8,
      );
    } else if (lang == 'ar') {
      return GoogleFonts.amiri(
        fontSize: fontSize + 1.5,
        fontWeight: fontWeight,
        color: color,
        height: 1.4,
      );
    } else {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing ?? 0.5,
        color: color,
      );
    }
  }
}
