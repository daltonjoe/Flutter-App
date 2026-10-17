// lib/core/theme/app_typography.dart
// Ephemerai — typography system
//
// Font strategy (google_fonts):
//   • Display / headings → 'Cormorant Garamond' w600
//   • Body / UI / numbers → 'Inter'
//
// Sizes (size/line-height):
//   Display 34/40 · H1 28/34 · H2 22/28 · Body 15/24 · Caption 13/18
//   Overline 11/16 (w500, letterSpacing 1.2, uppercase — uppercase must be
//   applied by the caller, TextStyle has no text-transform).
//
// Offline note: google_fonts downloads the families on first use and caches
// them on device; when the download fails every style falls back to the
// platform font. See the task report for the asset-bundling recommendation.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// ── Font-family name constants ──────────────────────────────────────────
// Used for the global ThemeData.fontFamily fallback.
class AppFonts {
  AppFonts._();

  static const String heading = 'Cormorant Garamond';
  static const String body = 'Inter';
}

// ── Text styles ────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  // ── Display / Hero ──────────────────────────────────────────────────
  /// Display — Cormorant Garamond 34/40, w600.
  static TextStyle display({Color color = AppColors.textPrimary}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 34,
        height: 40 / 34,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: color,
      );

  /// Large hero heading — alias of [display].
  static TextStyle heroTitle({Color color = AppColors.textPrimary}) =>
      display(color: color);

  /// H1 — Cormorant Garamond 28/34, w600.
  static TextStyle displayLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
      );

  // ── Headings (Cormorant Garamond) ───────────────────────────────────
  /// H2 — 22/28, w600.
  static TextStyle h1({Color color = AppColors.textPrimary}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Heading — 18/24, w600.
  static TextStyle h2({Color color = AppColors.textPrimary}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Heading — 16/22, w600.
  static TextStyle h3({Color color = AppColors.textPrimary}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Planet / accent names ───────────────────────────────────────────
  /// Planet name in header card — 22/28, w600, accent coloured.
  static TextStyle planetName({Color color = AppColors.violetPrimary}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
      );

  // ── Body (Inter) ────────────────────────────────────────────────────
  /// Body — Inter 15/24.
  static TextStyle bodyLg({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 15,
        height: 24 / 15,
        color: color,
      );

  /// Body small — Inter 14/22.
  static TextStyle bodyMd({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        height: 22 / 14,
        color: color,
      );

  /// Caption — Inter 13/18.
  static TextStyle bodySm({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 13,
        height: 18 / 13,
        color: color,
      );

  /// Extra-small / hint — Inter 12/16.
  static TextStyle bodyXs({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        color: color,
      );

  // ── Labels & chips ──────────────────────────────────────────────────
  /// Overline — Inter 11/16, w500, tracked. Caller must uppercase the text.
  static TextStyle overline({Color color = AppColors.mist}) =>
      GoogleFonts.inter(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: color,
      );

  /// Input field label — Inter 11, w500, tracked.
  static TextStyle fieldLabel({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: color,
      );

  /// Small chip / pill label — Inter 12/16, w600.
  static TextStyle chip({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Mini tag (ASC / MC labels) — Inter 10, w600.
  static TextStyle miniTag({Color color = AppColors.violetPrimary}) =>
      GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Tiny label (house "ev" text) — Inter 8.
  static TextStyle tinyLabel({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 8,
        color: color,
      );

  // ── Buttons ─────────────────────────────────────────────────────────
  /// Primary CTA button label — Inter 16, w600. Text colour follows the
  /// gold CTA fill ([AppColors.onGold]).
  static TextStyle get ctaPrimary => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onGold,
        letterSpacing: 0.3,
      );

  /// Secondary / outline button label — Inter 15, w600.
  static TextStyle ctaSecondary({Color color = AppColors.violetPrimary}) =>
      GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Navigation / app bar ────────────────────────────────────────────
  /// App-bar title — Inter 15–17, w600.
  static TextStyle appBarTitle({
    double size = 15,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Branding ────────────────────────────────────────────────────────
  /// Footer brand line — Inter 10, w600, tracked (gold @ 50 %).
  static TextStyle get brandFooter => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: const Color(0x80D9B36A),
        letterSpacing: 1.2,
      );

  // ── Numeric / degree values ─────────────────────────────────────────
  /// Degree readout — Inter 11, bold, tabular figures.
  static TextStyle degreeLabel({Color color = AppColors.violetPrimary}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Large numeric (house number) — Inter 16, w700, tabular figures.
  static TextStyle houseNumber({Color color = AppColors.violetPrimary}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ── ThemeData TextTheme (used inside CosmicTheme) ───────────────────
  static TextTheme get materialTextTheme => TextTheme(
        displayLarge: display(),
        headlineMedium: h1(),
        titleLarge: h2(),
        bodyLarge: bodyLg(),
        bodyMedium: bodySm(),
        labelSmall: overline(color: AppColors.textMuted),
      );
}
