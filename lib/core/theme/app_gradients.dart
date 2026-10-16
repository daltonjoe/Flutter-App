// lib/core/theme/app_gradients.dart
// SoulBound Cosmic Sanctum — gradient presets

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  // ── Forecast period gradients ────────────────────────────────────────
  static const LinearGradient forecastDaily = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient forecastWeekly = LinearGradient(
    colors: [AppColors.violetSoft, AppColors.violetPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient forecastMonthly = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient forecastYearly = LinearGradient(
    colors: [Color(0xFFB8860B), Color(0xFFE3C777)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Card / surface gradients ─────────────────────────────────────────
  /// Cosmic card: top highlight → deep card base
  static const LinearGradient cosmicCard = LinearGradient(
    colors: [AppColors.bgCardTop, AppColors.bgCard],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Primary CTA gradient ─────────────────────────────────────────────
  static const LinearGradient primaryCta = LinearGradient(
    colors: [AppColors.violetSoft, AppColors.violetPrimary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Cosmic radial glow ───────────────────────────────────────────────
  /// Use as a background RadialGradient — fades violet glow into deep bg
  static const RadialGradient cosmicRadialGlow = RadialGradient(
    colors: [Color(0x3D2D7DF0), AppColors.bgDeep],
    radius: 0.8,
  );

  // ── Ambient background glow (used in bg orbs) ────────────────────────
  static const RadialGradient ambientViolet = RadialGradient(
    colors: [Color(0x1E2D7DF0), Colors.transparent],
  );

  static const RadialGradient ambientIndigo = RadialGradient(
    colors: [Color(0x143B5FD9), Colors.transparent],
  );

  // ── Hero header gradient ─────────────────────────────────────────────
  static const LinearGradient heroHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1A40), AppColors.bgDeep],
  );

  // ── Convenience aliases (keep old names working) ─────────────────────
  static const LinearGradient violetGradient = primaryCta;
  static const LinearGradient cardGradient = cosmicCard;
  static const RadialGradient glowGradient = RadialGradient(
    colors: [Color(0x402D7DF0), Color(0x002D7DF0)],
    radius: 0.8,
  );
}
