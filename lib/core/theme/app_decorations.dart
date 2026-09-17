// lib/core/theme/app_decorations.dart
// SoulBound Cosmic Sanctum — composite BoxDecoration presets
//
// All reusable card/container decorations live here.
// Screens import this instead of constructing BoxDecoration inline.

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_shadows.dart';
import 'app_dimensions.dart';

class AppDecorations {
  AppDecorations._();

  // ── Cosmic card (default) ────────────────────────────────────────────
  /// The primary reusable card surface: card gradient + subtle violet border
  /// + card shadow. Pass overrides to customise without breaking the baseline.
  static BoxDecoration cosmicCard({
    Color? borderColor,
    double? borderWidth,
    List<BoxShadow>? shadows,
    Gradient? gradient,
    double? radius,
  }) =>
      BoxDecoration(
        gradient: gradient ?? AppGradients.cosmicCard,
        borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
        border: Border.all(
          color: borderColor ?? AppColors.borderSubtle,
          width: borderWidth ?? 1.0,
        ),
        boxShadow: shadows ?? AppShadows.cardShadow,
      );

  // ── Glowing CTA card ─────────────────────────────────────────────────
  /// Card variant with a violet glow — used for the primary analysis card
  static BoxDecoration cosmicCardGlowing({Gradient? gradient}) =>
      cosmicCard(
        gradient: gradient,
        shadows: AppShadows.violetGlow,
        borderColor: AppColors.borderMedium,
      );

  // ── Input field container ────────────────────────────────────────────
  static BoxDecoration inputField({bool hasError = false}) => BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.mdBr,
        border: Border.all(
          color: hasError ? AppColors.borderError : AppColors.borderSubtle,
          width: 1.2,
        ),
      );

  // ── Mini tag (ASC / MC chips) ────────────────────────────────────────
  static BoxDecoration miniTag() => BoxDecoration(
        color: const Color(0x268B5CF6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderMedium),
      );

  // ── Hero zodiac orb ──────────────────────────────────────────────────
  static BoxDecoration heroOrb() => const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF3D2B7A), AppColors.violetPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppShadows.heroOrbGlow,
      );

  // ── Planet icon circle ───────────────────────────────────────────────
  static BoxDecoration planetIcon(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      );

  // ── Planet header card ───────────────────────────────────────────────
  static BoxDecoration planetHeader(Color color) => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgBr,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      );

  // ── Hero header background ───────────────────────────────────────────
  static const BoxDecoration heroHeader = BoxDecoration(
    gradient: AppGradients.heroHeader,
  );

  // ── Forecast selection user card ─────────────────────────────────────
  static BoxDecoration forecastUserCard() => BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1F6B), Color(0xFF1A1240)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgBr,
        border: Border.all(color: AppColors.borderMedium),
      );

  // ── Forecast period card ─────────────────────────────────────────────
  static BoxDecoration forecastPeriodCard(List<Color> gradientColors) =>
      BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.mdBr,
        border: Border.all(
          color: gradientColors[0].withValues(alpha: 0.25),
          width: 1,
        ),
      );

  // ── Forecast period icon box ─────────────────────────────────────────
  static BoxDecoration forecastIconBox(List<Color> gradientColors) =>
      BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      );

  // ── Retrograde chip ──────────────────────────────────────────────────
  static const BoxDecoration retrogradeChip = BoxDecoration(
    color: Color(0x14EC4899),
    borderRadius: BorderRadius.all(Radius.circular(20)),
    // Note: border must be set via BoxDecoration.border — see retrogradeChipBorder
  );

  static BoxDecoration retrogradeChipFull() => BoxDecoration(
        color: const Color(0x14EC4899),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4DEC4899)),
      );

  // ── Retrograde badge (inline ℞ chip inside planet card) ─────────────
  static BoxDecoration retrogradeBadge() => BoxDecoration(
        color: const Color(0x26EC4899),
        borderRadius: BorderRadius.circular(6),
      );

  // ── Trio badge (Sun / Moon / Ascendant cards) ────────────────────────
  /// Same as cosmicCard with default settings — named alias for clarity
  static BoxDecoration trioBadge() => cosmicCard();

  // ── Error banner ─────────────────────────────────────────────────────
  static BoxDecoration errorBanner() => BoxDecoration(
        color: const Color(0x14F87171),
        borderRadius: AppRadius.mdBr,
        border: Border.all(color: const Color(0x40F87171)),
      );

  // ── Person hero card (natal report) ─────────────────────────────────
  static BoxDecoration personHeroCard() => cosmicCard(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF130E29)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // ── Hero chip (Sun / Moon / ASC chips in natal report) ───────────────
  static BoxDecoration heroChip() => BoxDecoration(
        color: const Color(0x991A1535),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x338B5CF6)),
      );

  // ── Retry / outline action button ────────────────────────────────────
  static BoxDecoration outlineAction() => BoxDecoration(
        color: const Color(0x268B5CF6),
        borderRadius: AppRadius.mdBr,
        border: Border.all(color: AppColors.borderMedium),
      );

  // ── Primary CTA button ───────────────────────────────────────────────
  static BoxDecoration primaryCta({bool disabled = false}) => BoxDecoration(
        borderRadius: AppRadius.mdBr,
        gradient: disabled ? null : AppGradients.primaryCta,
        color: disabled ? AppColors.bgSurface : null,
        boxShadow: disabled ? null : AppShadows.violetGlow,
      );

  // ── Outline / secondary CTA button ──────────────────────────────────
  static BoxDecoration secondaryCta() => BoxDecoration(
        borderRadius: AppRadius.mdBr,
        color: AppColors.bgCard,
        border: Border.all(color: const Color(0x598B5CF6)),
      );

  // ── Person avatar circle (forecast header) ───────────────────────────
  static const BoxDecoration personAvatar = BoxDecoration(
    shape: BoxShape.circle,
    gradient: AppGradients.primaryCta,
  );

  // ── Language pill ────────────────────────────────────────────────────
  static BoxDecoration languagePill() => BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderSubtle),
      );

  // ── Section icon badge ───────────────────────────────────────────────
  static BoxDecoration sectionIconBadge() => const BoxDecoration(
        color: Color(0x268B5CF6),
        shape: BoxShape.circle,
      );

  // ── House number box ─────────────────────────────────────────────────
  static BoxDecoration houseBox(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smBr,
      );
}
