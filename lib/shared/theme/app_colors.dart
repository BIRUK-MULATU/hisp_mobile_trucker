import 'package:flutter/material.dart';

/// DHIS2 Official Brand Colors
/// Primary reference: https://dhis2.org/brand
class AppColors {
  AppColors._();

  // ── Primary Brand ──────────────────────────────────────────
  static const Color primary = Color(0xFF2C6EBA);
  static const Color primaryDark = Color(0xFF1A4F8A);
  static const Color primaryLight = Color(0xFF4A8FD4);
  static const Color primarySurface = Color(0xFFE8F1FB);

  // ── Secondary / Accent ─────────────────────────────────────
  static const Color secondary = Color(0xFF00B0FF);
  static const Color accent = Color(0xFF147CD7);

  // ── Backgrounds ────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  static const Color inputBackground = Color(0xFFEEEEEE);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ── Text ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // ── Border & Divider ───────────────────────────────────────
  static const Color border = Color(0xFFBDBDBD);
  static const Color borderFocused = Color(0xFF2C6EBA);
  static const Color divider = Color(0xFFE0E0E0);

  // ── Status Colors ──────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color info = Color(0xFF2C6EBA);
  static const Color infoLight = Color(0xFFE8F1FB);

  // ── Shadows ────────────────────────────────────────────────
  static const Color shadow = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);

  // ── Gradients ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, primary],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A8FD4), Color(0xFF1A4F8A)],
  );
}
