// lib/core/theme/app_shadows.dart
// SoulBound Cosmic Sanctum — shadow & glow presets

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  // ── Violet glow ──────────────────────────────────────────────────────
  /// Primary CTA / hero element glow
  static const List<BoxShadow> violetGlow = [
    BoxShadow(
      color: AppColors.violetGlow, // 0x668B5CF6
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Subtle violet glow for smaller interactive elements
  static const List<BoxShadow> violetGlowSm = [
    BoxShadow(
      color: Color(0x408B5CF6),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ── Hero orb glow ────────────────────────────────────────────────────
  static const List<BoxShadow> heroOrbGlow = [
    BoxShadow(
      color: Color(0x808B5CF6), // 50 % violet
      blurRadius: 20,
    ),
  ];

  // ── Generic card shadow ──────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x66000000), // 40 % black
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // ── Error / rose glow ────────────────────────────────────────────────
  static const List<BoxShadow> errorGlow = [
    BoxShadow(
      color: Color(0x40F87171),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ── Element-tinted glow (built at runtime with a given color) ────────
  /// Returns a single-shadow glow list tinted with [color].
  static List<BoxShadow> coloredGlow(Color color, {double blur = 16}) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: blur,
      offset: const Offset(0, 4),
    ),
  ];
}
