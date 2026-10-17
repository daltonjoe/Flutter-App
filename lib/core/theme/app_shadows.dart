// lib/core/theme/app_shadows.dart
// Ephemerai — shadow & glow presets
//
// One neutral shadow for the whole system; any coloured light comes from the
// runtime [glow] helper (blur 24–40, opacity 25–35 %).

import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  // ── Single neutral shadow ────────────────────────────────────────────
  /// 0 12 40 rgba(0,0,0,.45) — the only static shadow in the system.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x73000000), // 45 % black
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ];

  // ── Legacy alias ─────────────────────────────────────────────────────
  /// Kept so existing widgets keep compiling. Tinted shadow presets were
  /// removed; use [glow] for a coloured light.
  static const List<BoxShadow> violetGlow = cardShadow;

  // ── Glow helper ──────────────────────────────────────────────────────
  /// Returns a single coloured glow tinted with [color].
  /// [blur] is clamped to 24–40 and [alpha] to 25–35 %.
  static List<BoxShadow> glow(
    Color color, {
    double blur = 32,
    double alpha = 0.30,
  }) => [
    BoxShadow(
      color: color.withValues(alpha: alpha.clamp(0.25, 0.35)),
      blurRadius: blur.clamp(24.0, 40.0),
    ),
  ];
}
