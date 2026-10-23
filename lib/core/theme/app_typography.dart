// lib/core/theme/app_typography.dart
// Ephemerai — typography system
//
// Font strategy (google_fonts): single global family; Arabic text falls back to 'Noto Sans Arabic'.
//   • Display / headings → 'Inter' w600
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

  static const String heading = 'Inter';
  static const String body = 'Inter';
}

// ── Text styles ────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  /// Global family ('Inter') has no Arabic glyphs, so 'ar' text falls back to
  /// an Arabic-capable Google Font family (no extra package).
  static final List<String> _fallbackFamilies = <String>[
    AppFonts.body,
    GoogleFonts.notoSansArabic().fontFamily ?? 'NotoSansArabic_regular',
  ];

  /// Single entry point for every text style: the global font family and its
  /// fallbacks are defined here only once.
  static TextStyle _font({
    required double fontSize,
    double? height,
    FontWeight? fontWeight,
    double? letterSpacing,
    Color? color,
    List<FontFeature>? fontFeatures,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        height: height,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color,
        fontFeatures: fontFeatures,
      ).copyWith(fontFamilyFallback: _fallbackFamilies);

  // ── Display / Hero ──────────────────────────────────────────────────
  /// Display — Inter 34/40, w600.
  static TextStyle display({Color color = AppColors.starlight}) =>
      _font(
        fontSize: 34,
        height: 40 / 34,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: color,
      );

  /// Large hero heading — alias of [display].
  static TextStyle heroTitle({Color color = AppColors.starlight}) =>
      display(color: color);

  /// H1 — Inter 28/34, w600.
  static TextStyle displayLarge({Color color = AppColors.starlight}) =>
      _font(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
      );

  // ── Headings (Inter) ───────────────────────────────────
  /// H2 — 22/28, w600.
  static TextStyle h1({Color color = AppColors.starlight}) =>
      _font(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Heading — 18/24, w600.
  static TextStyle h2({Color color = AppColors.starlight}) =>
      _font(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Heading — 16/22, w600.
  static TextStyle h3({Color color = AppColors.starlight}) =>
      _font(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Planet / accent names ───────────────────────────────────────────
  /// Planet name in header card — 22/28, w600, accent coloured.
  static TextStyle planetName({Color color = AppColors.gold}) =>
      _font(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
      );

  // ── Body (Inter) ────────────────────────────────────────────────────
  /// Body — Inter 15/24.
  static TextStyle bodyLg({Color color = AppColors.starlight}) =>
      _font(
        fontSize: 15,
        height: 24 / 15,
        color: color,
      );

  /// Body small — Inter 14/22.
  static TextStyle bodyMd({Color color = AppColors.mist}) =>
      _font(
        fontSize: 14,
        height: 22 / 14,
        color: color,
      );

  /// Caption — Inter 13/18.
  static TextStyle bodySm({Color color = AppColors.mist}) =>
      _font(
        fontSize: 13,
        height: 18 / 13,
        color: color,
      );

  /// Extra-small / hint — Inter 12/16.
  static TextStyle bodyXs({Color color = AppColors.mist}) =>
      _font(
        fontSize: 12,
        height: 16 / 12,
        color: color,
      );

  // ── Labels & chips ──────────────────────────────────────────────────
  /// Overline — Inter 11/16, w500, tracked. Caller must uppercase the text.
  static TextStyle overline({Color color = AppColors.mist}) =>
      _font(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: color,
      );

  /// Input field label — Inter 11, w500, tracked.
  static TextStyle fieldLabel({Color color = AppColors.mist}) =>
      _font(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: color,
      );

  /// Small chip / pill label — Inter 12/16, w600.
  static TextStyle chip({Color color = AppColors.starlight}) =>
      _font(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Mini tag (ASC / MC labels) — Inter 10, w600.
  static TextStyle miniTag({Color color = AppColors.gold}) =>
      _font(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Tiny label (house "ev" text) — Inter 8.
  static TextStyle tinyLabel({Color color = AppColors.mist}) =>
      _font(
        fontSize: 8,
        color: color,
      );

  // ── Buttons ─────────────────────────────────────────────────────────
  /// Primary CTA button label — Inter 16, w600. Text colour follows the
  /// gold CTA fill ([AppColors.onGold]).
  static TextStyle get ctaPrimary => _font(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onGold,
        letterSpacing: 0.3,
      );

  /// Secondary / outline button label — Inter 15, w600.
  static TextStyle ctaSecondary({Color color = AppColors.gold}) =>
      _font(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Navigation / app bar ────────────────────────────────────────────
  /// App-bar title — Inter 15–17, w600.
  static TextStyle appBarTitle({
    double size = 15,
    Color color = AppColors.starlight,
  }) =>
      _font(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Branding ────────────────────────────────────────────────────────
  /// Footer brand line — Inter 10, w600, tracked (gold @ 50 %).
  static TextStyle get brandFooter => _font(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: const Color(0x80D9B36A),
        letterSpacing: 1.2,
      );

  // ── Numeric / degree values ─────────────────────────────────────────
  /// Degree readout — Inter 11, bold, tabular figures.
  static TextStyle degreeLabel({Color color = AppColors.gold}) =>
      _font(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Large numeric (house number) — Inter 16, w700, tabular figures.
  static TextStyle houseNumber({Color color = AppColors.gold}) =>
      _font(
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
        labelSmall: overline(color: AppColors.mist),
      );
}
