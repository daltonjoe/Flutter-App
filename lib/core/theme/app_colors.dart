// lib/core/theme/app_colors.dart
// SoulBound Cosmic Sanctum — colour tokens
// Single source of truth: every raw hex value lives here and nowhere else.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ─────────────────────────────────────────────────────
  static const Color bgDeep = Color(0xFF030813); // deepest screen bg
  static const Color bgCard = Color(0xFF0A1431); // card surface
  static const Color bgCardTop = Color(0xFF122350); // card top highlight
  static const Color bgSurface = Color(0xFF0E1C40); // inputs / surfaces
  static const Color bgSurfaceLow = Color(0xFF081127); // depressed surface
  static const Color bgSurfaceBright = Color(0xFF2B3A5E); // elevated surface

  // ── Violet / Primary ────────────────────────────────────────────────
  static const Color violetPrimary = Color(0xFF2D7DF0);
  static const Color violetSoft = Color(0xFF1E5BC6);
  static const Color violetDark = Color(0xFF0B2A6B);
  static const Color violetGlow = Color(0x662D7DF0); // 40 % alpha

  // ── Accents ─────────────────────────────────────────────────────────
  static const Color indigoAccent = Color(0xFF3B5FD9);
  static const Color roseAccent = Color(0xFFC9A24A);
  static const Color roseSoft = Color(0xFFE8D5A3);

  // ── Elements ────────────────────────────────────────────────────────
  static const Color elementFire = Color(0xFFFF6B6B);
  static const Color elementEarth = Color(0xFF98C379);
  static const Color elementAir = Color(0xFF61AFEF);
  static const Color elementWater = Color(0xFF56B6C2);

  // ── Semantic ────────────────────────────────────────────────────────
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color amberTransit = Color(0xFFF59E0B);
  static const Color tealSuccess = Color(0xFF14B8A6);
  static const Color errorRed = Color(0xFFF87171);
  static const Color successGreen = Color(0xFF34D399);

  // ── Text ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF2F6FF);
  static const Color textSecondary = Color(0xFF93A6C9);
  static const Color textMuted = Color(0xFF566A8E);
  static const Color textDisabled = Color(0xFF34455F);

  // ── Borders (pre-alpha-encoded) ─────────────────────────────────────
  /// 18 % violet — subtle dividers, default card border
  static const Color borderSubtle = Color(0x2E2D7DF0);

  /// 25 % violet — medium emphasis borders
  static const Color borderMedium = Color(0x402D7DF0);

  /// 40 % violet — strong / focused borders
  static const Color borderStrong = Color(0x662D7DF0);

  /// 50 % error red — validation error borders
  static const Color borderError = Color(0x80F87171);

  // ── Convenience aliases (keep existing code compiling unchanged) ─────
  static const Color violet = violetPrimary;
  static const Color indigo = indigoAccent;
  static const Color rose = roseAccent;
  static const Color amber = amberTransit;
  static const Color gold = goldAccent;
  static const Color teal = tealSuccess;
  static const Color error = errorRed;
  static const Color success = successGreen;
  static const Color warning = goldAccent;
}
