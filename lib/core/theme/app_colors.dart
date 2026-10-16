// lib/core/theme/app_colors.dart
// Ephemerai — colour tokens
// Concept: "night sky + golden thread".
//   • Blue  = ground / surface only (secondary interaction via [info]).
//   • Gold  = value & emphasis.
// Single source of truth: every raw hex value lives here and nowhere else.
//
// NOTE: legacy token names (violetPrimary, roseAccent, …) are kept so the
// existing screens keep compiling; their VALUES now follow the new system.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds / surfaces ──────────────────────────────────────────
  /// Deepest screen background.
  static const Color bgVoid = Color(0xFF05070F);

  /// Card surface.
  static const Color navyDeep = Color(0xFF0B1330);

  /// Raised surface (inputs, elevated cards, card top highlight).
  static const Color navyRaised = Color(0xFF111C42);

  static const Color bgDeep = bgVoid;
  static const Color bgCard = navyDeep;
  static const Color bgCardTop = navyRaised;
  static const Color bgSurface = navyRaised;
  static const Color bgSurfaceLow = Color(0xFF070B18); // depressed surface
  static const Color bgSurfaceBright = Color(0xFF1B2856); // elevated surface

  // ── Hairlines (white alpha) ─────────────────────────────────────────
  /// white @ 8 % — subtle dividers, default card border.
  static const Color hairline = Color(0x14FFFFFF);

  /// white @ 14 % — card top highlight / raised hairline.
  static const Color hairlineTop = Color(0x24FFFFFF);

  // ── Gold / primary ──────────────────────────────────────────────────
  static const Color gold = Color(0xFFD9B36A);
  static const Color goldSoft = Color(0xFFF2DDAE);
  static const Color goldDeep = Color(0xFF8A6A2F);
  static const Color onGold = Color(0xFF1A1305); // text/icon on gold fills

  /// gold @ 30 % — primary glow.
  static const Color goldGlow = Color(0x4DD9B36A);

  /// gold @ 25 % — soft glow / medium border.
  static const Color goldGlowSm = Color(0x40D9B36A);

  /// gold @ 0 % — transparent end stop for glow gradients.
  static const Color goldGlowClear = Color(0x00D9B36A);

  // Legacy "violet / primary" names → gold.
  static const Color violetPrimary = gold;
  static const Color violetSoft = goldSoft;
  static const Color violetDark = goldDeep;
  static const Color violetGlow = goldGlow;

  // ── Accents / info ──────────────────────────────────────────────────
  /// Secondary interaction only (links, info states).
  static const Color info = Color(0xFF4C8DFF);

  static const Color indigoAccent = info;

  /// WARNING: misleading legacy name — value is GOLD, not rose.
  static const Color roseAccent = gold;

  /// WARNING: misleading legacy name — value is GOLD, not rose.
  static const Color roseSoft = goldSoft;

  // ── Elements ────────────────────────────────────────────────────────
  static const Color elementFire = Color(0xFFFF7A59);
  static const Color elementEarth = Color(0xFFB7C27A);
  static const Color elementAir = Color(0xFF8FC7FF);
  static const Color elementWater = Color(0xFF6F8CFF);

  // ── Status ──────────────────────────────────────────────────────────
  static const Color statusSupportive = Color(0xFF5FD3B0);
  static const Color statusNeutral = Color(0xFF9AA6C7);
  static const Color statusChallenging = Color(0xFFFF8F6B);
  static const Color statusDanger = Color(0xFFFF6B7A);

  // ── Content themes (dashboard categories) ───────────────────────────
  /// love — soft rose / coral.
  static const Color themeLove = Color(0xFFE8A0A8);

  /// career — soft sky blue.
  static const Color themeCareer = Color(0xFF8FC7FF);

  /// identity — lavender.
  static const Color themeIdentity = Color(0xFFB9A7E8);

  /// health — sage.
  static const Color themeHealth = Color(0xFFA9C39A);

  // ── Semantic (legacy names remapped) ────────────────────────────────
  static const Color goldAccent = gold;
  static const Color amberTransit = Color(0xFFE8B45C);
  static const Color tealSuccess = statusSupportive;
  static const Color errorRed = statusDanger;
  static const Color successGreen = statusSupportive;

  // ── Text ────────────────────────────────────────────────────────────
  /// Primary text — contrast ≈ 16.2:1 on [navyDeep].
  static const Color starlight = Color(0xFFEEF1FA);

  /// Secondary text — contrast ≈ 6.8:1 on [navyRaised] / 8.3:1 on [bgVoid].
  static const Color mist = Color(0xFF9AA6C7);

  /// DECORATIVE / DISABLED ONLY — contrast ≈ 3.4:1 on [navyDeep]
  /// (3.8:1 on [bgVoid]); do not use for body copy.
  static const Color dim = Color(0xFF5E6A8F);

  static const Color textPrimary = starlight;
  static const Color textSecondary = mist;
  static const Color textMuted = dim;
  static const Color textDisabled = Color(0xFF39415E);

  // ── Borders (pre-alpha-encoded) ─────────────────────────────────────
  /// white @ 8 % — subtle hairlines, default card border.
  static const Color borderSubtle = hairline;

  /// gold @ 25 % — medium emphasis borders.
  static const Color borderMedium = goldGlowSm;

  /// gold @ 40 % — strong / focused borders.
  static const Color borderStrong = Color(0x66D9B36A);

  /// danger @ 50 % — validation error borders.
  static const Color borderError = Color(0x80FF6B7A);

  // ── Convenience aliases (keep existing code compiling unchanged) ─────
  static const Color violet = violetPrimary;
  static const Color indigo = indigoAccent;
  static const Color rose = roseAccent;
  static const Color amber = amberTransit;
  static const Color teal = tealSuccess;
  static const Color error = errorRed;
  static const Color success = successGreen;
  static const Color warning = goldAccent;
}
