import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Igreja Manager Typography
///
/// Display: DM Serif Display — a refined serif with editorial character,
/// perfect for headers, titles, and impactful text. Feels authoritative
/// without being stuffy.
///
/// Body: Source Sans 3 — clean, highly readable sans-serif with generous
/// x-height. Professional enough for data-dense screens, warm enough for
/// pastoral communications.
///
/// Mono: JetBrains Mono — for numerical data, codes, and financial figures.
class AppTypography {
  AppTypography._();

  // ── Display (DM Serif Display) ──
  static TextStyle get displayLarge => GoogleFonts.dmSerifDisplay(
        fontSize: 40,
        fontWeight: FontWeight.w400,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.dmSerifDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle get displaySmall => GoogleFonts.dmSerifDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w400,
        height: 1.25,
      );

  // ── Heading (Source Sans 3) ──
  static TextStyle get headingLarge => GoogleFonts.sourceSans3(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
      );

  static TextStyle get headingMedium => GoogleFonts.sourceSans3(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
      );

  static TextStyle get headingSmall => GoogleFonts.sourceSans3(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ── Body (Source Sans 3) ──
  static TextStyle get bodyLarge => GoogleFonts.sourceSans3(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.sourceSans3(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.sourceSans3(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ── Labels ──
  static TextStyle get labelLarge => GoogleFonts.sourceSans3(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.4,
      );

  static TextStyle get labelMedium => GoogleFonts.sourceSans3(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => GoogleFonts.sourceSans3(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0.6,
      );

  // ── Mono (JetBrains Mono) — for numbers, codes, financial data ──
  static TextStyle get monoLarge => GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get monoMedium => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ── Button Text ──
  static TextStyle get buttonLarge => GoogleFonts.sourceSans3(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.3,
      );

  static TextStyle get buttonMedium => GoogleFonts.sourceSans3(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.3,
      );
}
