import 'package:flutter/material.dart';

/// Igreja Manager Color Palette
///
/// Aesthetic direction: "Sacred Geometry meets Modern Editorial"
/// Deep navy and warm gold as anchors, with clean whites and
/// soft stone grays. The palette evokes authority, trust, and warmth —
/// fitting for a church management tool that handles both
/// administrative rigor and pastoral care.
class AppColors {
  AppColors._();

  // ── Primary: Deep Navy ──
  static const Color primary = Color(0xFF0D1B2A);
  static const Color primaryLight = Color(0xFF1B2D45);
  static const Color primaryDark = Color(0xFF060F18);

  // ── Accent: Warm Gold ──
  static const Color accent = Color(0xFFD4A843);
  static const Color accentLight = Color(0xFFE8C96A);
  static const Color accentDark = Color(0xFFB08A2E);

  // ── Surface / Backgrounds ──
  static const Color background = Color(0xFFF7F5F0); // warm parchment
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0EDE6);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ── Text ──
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF5A6577);
  static const Color textMuted = Color(0xFF94A0B4);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF0D1B2A);

  // ── Border / Divider ──
  static const Color border = Color(0xFFE0DDD5);
  static const Color divider = Color(0xFFE8E5DC);

  // ── Status ──
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFD4A843);
  static const Color error = Color(0xFFC44536);
  static const Color info = Color(0xFF3A7CA5);

  // ── Semantic ──
  static const Color active = Color(0xFF2E7D5B);
  static const Color inactive = Color(0xFF94A0B4);
  static const Color transferred = Color(0xFF3A7CA5);
  static const Color dismissed = Color(0xFFC44536);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B2A), Color(0xFF1B2D45)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A843), Color(0xFFE8C96A)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1B2A), Color(0xFF162436), Color(0xFF1B2D45)],
  );
}
