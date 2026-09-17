// lib/core/theme/app_colors.dart
// SoulBound Cosmic Sanctum — colour tokens
// Single source of truth: every raw hex value lives here and nowhere else.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ─────────────────────────────────────────────────────
  static const Color bgDeep         = Color(0xFF080612); // deepest screen bg
  static const Color bgCard         = Color(0xFF110E22); // card surface
  static const Color bgCardTop      = Color(0xFF1E1840); // card top highlight
  static const Color bgSurface      = Color(0xFF1A1535); // inputs / surfaces
  static const Color bgSurfaceLow   = Color(0xFF14121F); // depressed surface
  static const Color bgSurfaceBright= Color(0xFF3A3746); // elevated surface

  // ── Violet / Primary ────────────────────────────────────────────────
  static const Color violetPrimary  = Color(0xFF8B5CF6);
  static const Color violetSoft     = Color(0xFF6D28D9);
  static const Color violetDark     = Color(0xFF4C1D95);
  static const Color violetGlow     = Color(0x668B5CF6); // 40 % alpha

  // ── Accents ─────────────────────────────────────────────────────────
  static const Color indigoAccent   = Color(0xFF4F46E5);
  static const Color roseAccent     = Color(0xFFEC4899);
  static const Color roseSoft       = Color(0xFFF472B6);

  // ── Elements ────────────────────────────────────────────────────────
  static const Color elementFire    = Color(0xFFFF6B6B);
  static const Color elementEarth   = Color(0xFF98C379);
  static const Color elementAir     = Color(0xFF61AFEF);
  static const Color elementWater   = Color(0xFF56B6C2);

  // ── Semantic ────────────────────────────────────────────────────────
  static const Color goldAccent     = Color(0xFFFFD700);
  static const Color amberTransit   = Color(0xFFF59E0B);
  static const Color tealSuccess    = Color(0xFF14B8A6);
  static const Color errorRed       = Color(0xFFF87171);
  static const Color successGreen   = Color(0xFF34D399);

  // ── Text ────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF5F0FF);
  static const Color textSecondary  = Color(0xFF9E8DC0);
  static const Color textMuted      = Color(0xFF5C5175);
  static const Color textDisabled   = Color(0xFF3E3652);

  // ── Borders (pre-alpha-encoded) ─────────────────────────────────────
  /// 18 % violet — subtle dividers, default card border
  static const Color borderSubtle   = Color(0x2E8B5CF6);
  /// 25 % violet — medium emphasis borders
  static const Color borderMedium   = Color(0x408B5CF6);
  /// 40 % violet — strong / focused borders
  static const Color borderStrong   = Color(0x668B5CF6);
  /// 50 % error red — validation error borders
  static const Color borderError    = Color(0x80F87171);

  // ── Convenience aliases (keep existing code compiling unchanged) ─────
  static const Color violet    = violetPrimary;
  static const Color indigo    = indigoAccent;
  static const Color rose      = roseAccent;
  static const Color amber     = amberTransit;
  static const Color gold      = goldAccent;
  static const Color teal      = tealSuccess;
  static const Color error     = errorRed;
  static const Color success   = successGreen;
  static const Color warning   = goldAccent;
}
