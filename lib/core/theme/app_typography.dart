// lib/core/theme/app_typography.dart
// SoulBound Cosmic Sanctum — typography system
//
// Font strategy:
//   • Headings  → 'Playfair Display' (google_fonts package)
//   • Body / UI → 'Inter' (google_fonts package)
//
// If google_fonts is unavailable at runtime (offline / stripped build),
// each TextStyle falls back gracefully to the platform serif / sans-serif.
//
// IMPORTANT: import google_fonts via pubspec.yaml before using this file:
//   dependencies:
//     google_fonts: ^6.2.1

import 'package:flutter/material.dart';
import 'app_colors.dart';

// ── Font-family name constants ──────────────────────────────────────────
// We reference these strings so all usages stay in sync even if we later
// swap providers (e.g. bundled assets) without touching every TextStyle.
class AppFonts {
  AppFonts._();

  static const String heading = 'Playfair Display';
  static const String body    = 'Inter';
}

// ── Text styles ────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  // ── Display / Hero ──────────────────────────────────────────────────
  /// Large hero heading — Playfair Display, 34 px, ExtraBold
  static TextStyle heroTitle({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.15,
        letterSpacing: -0.8,
      );

  /// Section display heading — Playfair Display, 26 px, Bold
  static TextStyle displayLarge({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      );

  // ── Headings (Playfair Display) ─────────────────────────────────────
  /// H1 — 22 px, Bold
  static TextStyle h1({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
      );

  /// H2 — 18 px, SemiBold
  static TextStyle h2({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// H3 — 16 px, SemiBold
  static TextStyle h3({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Planet / accent names ───────────────────────────────────────────
  /// Planet name in header card — 22 px, Black, accent colored
  static TextStyle planetName({Color color = AppColors.violetPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -0.5,
      );

  // ── Body (Inter) ────────────────────────────────────────────────────
  /// Standard body copy — 15 px
  static TextStyle bodyLg({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 15,
        color: color,
        height: 1.6,
      );

  /// Secondary body copy — 14 px
  static TextStyle bodyMd({Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 14,
        color: color,
        height: 1.55,
      );

  /// Small body / caption — 13 px
  static TextStyle bodySm({Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 13,
        color: color,
        height: 1.5,
      );

  /// Extra-small / hint — 12 px
  static TextStyle bodyXs({Color color = AppColors.textMuted}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 12,
        color: color,
        height: 1.4,
      );

  // ── Labels & chips ──────────────────────────────────────────────────
  /// Input field label — 11 px, Bold, tracked
  static TextStyle fieldLabel({Color color = AppColors.textMuted}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.2,
      );

  /// Small chip / pill label — 12 px, SemiBold
  static TextStyle chip({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Mini tag (ASC / MC labels) — 10 px, SemiBold
  static TextStyle miniTag({Color color = AppColors.violetPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Tiny label (house "ev" text) — 8 px
  static TextStyle tinyLabel({Color color = AppColors.textMuted}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 8,
        color: color,
      );

  // ── Buttons ─────────────────────────────────────────────────────────
  /// Primary CTA button label — 16 px, Bold
  static const TextStyle ctaPrimary = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  /// Secondary / outline button label — 15 px, SemiBold
  static TextStyle ctaSecondary({Color color = AppColors.violetPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Navigation / app bar ────────────────────────────────────────────
  /// App-bar title — 15–17 px, SemiBold
  static TextStyle appBarTitle({
    double size = 15,
    Color color = AppColors.textPrimary,
  }) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Branding ────────────────────────────────────────────────────────
  /// Footer brand line — 10 px, SemiBold, tracked
  static const TextStyle brandFooter = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Color(0x808B5CF6),
    letterSpacing: 1.2,
  );

  // ── Numeric / degree values ─────────────────────────────────────────
  /// Degree readout — 11 px, Bold
  static TextStyle degreeLabel({Color color = AppColors.violetPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color,
      );

  /// Large numeric (house number) — 16 px, ExtraBold
  static TextStyle houseNumber({Color color = AppColors.violetPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: color,
      );

  // ── ThemeData TextTheme (used inside CosmicTheme) ───────────────────
  static TextTheme get materialTextTheme => const TextTheme(
    displayLarge: TextStyle(
      fontFamily: AppFonts.heading,
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: AppFonts.heading,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 15,
      color: AppColors.textPrimary,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 13,
      color: AppColors.textSecondary,
      height: 1.5,
    ),
    labelSmall: TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 11,
      color: AppColors.textMuted,
      letterSpacing: 0.5,
    ),
  );
}
