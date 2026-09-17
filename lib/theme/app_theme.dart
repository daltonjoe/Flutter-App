// lib/theme/app_theme.dart
// SoulBound Cosmic Sanctum — compatibility shim
//
// All canonical definitions live in:
//   lib/core/theme/
//
// This file re-exports everything from lib/core/theme/ and provides
// the legacy AppTheme class so existing code continues to compile
// unchanged while we migrate individual screens to the new design system.

import 'package:flutter/material.dart';

// Re-export everything from the centralized core theme (single export does it all)
export '../core/theme/cosmic_theme.dart';

// Direct imports needed for AppTheme class body references
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/cosmic_theme.dart';

class AppTheme {
  AppTheme._();

  // ── Backgrounds ─────────────────────────────────────────────────────
  static const Color bgDeep          = AppColors.bgDeep;
  static const Color bgCard          = AppColors.bgCard;
  static const Color bgCardTop       = AppColors.bgCardTop;
  static const Color bgSurface       = AppColors.bgSurface;
  static const Color bgSurfaceLow    = AppColors.bgSurfaceLow;
  static const Color bgSurfaceBright = AppColors.bgSurfaceBright;

  // ── Violet / Primary ────────────────────────────────────────────────
  static const Color violet          = AppColors.violetPrimary;
  static const Color violetPrimary   = AppColors.violetPrimary;
  static const Color violetSoft      = AppColors.violetSoft;
  static const Color violetDark      = AppColors.violetDark;
  static const Color violetGlowColor = AppColors.violetGlow;

  // ── Accents ─────────────────────────────────────────────────────────
  static const Color indigo          = AppColors.indigoAccent;
  static const Color indigoAccent    = AppColors.indigoAccent;
  static const Color rose            = AppColors.roseAccent;
  static const Color roseAccent      = AppColors.roseAccent;
  static const Color roseSoft        = AppColors.roseSoft;

  // ── Elements ────────────────────────────────────────────────────────
  static const Color elementFire     = AppColors.elementFire;
  static const Color elementEarth    = AppColors.elementEarth;
  static const Color elementAir      = AppColors.elementAir;
  static const Color elementWater    = AppColors.elementWater;

  // ── Semantic ────────────────────────────────────────────────────────
  static const Color amber           = AppColors.amberTransit;
  static const Color amberTransit    = AppColors.amberTransit;
  static const Color gold            = AppColors.goldAccent;
  static const Color goldAccent      = AppColors.goldAccent;
  static const Color teal            = AppColors.tealSuccess;
  static const Color tealSuccess     = AppColors.tealSuccess;
  static const Color error           = AppColors.errorRed;
  static const Color errorRed        = AppColors.errorRed;
  static const Color success         = AppColors.successGreen;
  static const Color successGreen    = AppColors.successGreen;
  static const Color warning         = AppColors.goldAccent;

  // ── Text ────────────────────────────────────────────────────────────
  static const Color textPrimary     = AppColors.textPrimary;
  static const Color textSecondary   = AppColors.textSecondary;
  static const Color textMuted       = AppColors.textMuted;
  static const Color textDisabled    = AppColors.textDisabled;

  // ── Borders ─────────────────────────────────────────────────────────
  static const Color borderSubtle    = AppColors.borderSubtle;
  static const Color borderMedium    = AppColors.borderMedium;
  static const Color borderStrong    = AppColors.borderStrong;
  static const Color borderError     = AppColors.borderError;

  // ── Gradients ───────────────────────────────────────────────────────
  static const LinearGradient violetGradient = AppGradients.primaryCta;
  static const LinearGradient cosmicGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient   = AppGradients.cosmicCard;
  static const RadialGradient glowGradient   = RadialGradient(
    colors: [Color(0x408B5CF6), Color(0x008B5CF6)],
    radius: 0.8,
  );

  // ── Shadows ─────────────────────────────────────────────────────────
  static const List<BoxShadow> violetGlow  = AppShadows.violetGlow;
  static const List<BoxShadow> cardShadow  = AppShadows.cardShadow;

  // ── Radii ───────────────────────────────────────────────────────────
  static const double radiusSm  = AppRadius.sm;
  static const double radiusMd  = AppRadius.md;
  static const double radiusLg  = AppRadius.lg;
  static const double radiusXl  = AppRadius.xl;
  static const double radiusPill= AppRadius.pill;

  // ── Spacing ─────────────────────────────────────────────────────────
  static const double spaceSm   = AppSpacing.sm;
  static const double spaceMd   = AppSpacing.md;
  static const double spaceLg   = AppSpacing.lg;
  static const double spaceXl   = AppSpacing.xl;
  static const double spaceXxl  = AppSpacing.xxl;

  // ── ThemeData ───────────────────────────────────────────────────────
  static ThemeData get dark => CosmicTheme.darkTheme;
}

// ── Reusable card decoration helper (legacy function signature) ────────
BoxDecoration cosmicCard({
  Color? border,
  List<BoxShadow>? shadows,
  Gradient? gradient,
}) =>
    AppDecorations.cosmicCard(
      borderColor: border,
      shadows: shadows,
      gradient: gradient,
    );
