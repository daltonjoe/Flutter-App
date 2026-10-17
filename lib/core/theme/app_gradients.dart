// lib/core/theme/app_gradients.dart
// Ephemerai — gradient presets
// Concept: "night sky + golden thread". Blue gradients are atmosphere only;
// every call-to-action gradient is gold.

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  // ── Forecast period gradients ────────────────────────────────────────
  /// Daily — warm ember (today / fire).
  static const LinearGradient forecastDaily = LinearGradient(
    colors: [AppColors.elementFire, AppColors.statusChallenging],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Weekly — primary gold (value emphasis).
  static const LinearGradient forecastWeekly = LinearGradient(
    colors: [AppColors.goldSoft, AppColors.gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Monthly — info blue (secondary interaction / atmosphere).
  static const LinearGradient forecastMonthly = LinearGradient(
    colors: [AppColors.info, AppColors.elementAir],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Yearly — deep gold (long-range value).
  static const LinearGradient forecastYearly = LinearGradient(
    colors: [AppColors.goldDeep, AppColors.gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Card / surface gradients ─────────────────────────────────────────
  /// Cosmic card: raised navy top → deep navy base.
  static const LinearGradient cosmicCard = LinearGradient(
    colors: [AppColors.bgCardTop, AppColors.bgCard],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Primary CTA gradient ─────────────────────────────────────────────
  /// Gold-on-gold, 135° (top-left → bottom-right). No blue CTA fills.
  static const LinearGradient primaryCta = LinearGradient(
    colors: [AppColors.goldSoft, AppColors.gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Cosmic radial glow ───────────────────────────────────────────────
  /// Use as a background RadialGradient — fades a golden glow into the void.
  static const RadialGradient cosmicRadialGlow = RadialGradient(
    colors: [Color(0x3DD9B36A), AppColors.bgVoid],
    radius: 0.8,
  );

  // ── Ambient background glow (used in bg orbs) ────────────────────────
  /// Night-sky ambience — info blue, decorative only.
  static const RadialGradient ambientViolet = RadialGradient(
    colors: [Color(0x1E4C8DFF), Colors.transparent],
  );

  static const RadialGradient ambientIndigo = RadialGradient(
    colors: [Color(0x144C8DFF), Colors.transparent],
  );

  // ── Hero header gradient ─────────────────────────────────────────────
  static const LinearGradient heroHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.navyRaised, AppColors.bgVoid],
  );

  // ── Convenience aliases (keep old names working) ─────────────────────
  static const LinearGradient violetGradient = primaryCta;
  static const LinearGradient cardGradient = cosmicCard;
  static const RadialGradient glowGradient = RadialGradient(
    colors: [AppColors.goldGlow, AppColors.goldGlowClear],
    radius: 0.8,
  );
}
