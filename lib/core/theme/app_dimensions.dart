// lib/core/theme/app_dimensions.dart
// SoulBound Cosmic Sanctum — spacing, radii, component sizes

import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs   =  4.0;
  static const double sm   =  8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;

  // ── Named page gutters ───────────────────────────────────────────────
  /// Standard horizontal screen padding
  static const double screenH = 20.0;
  /// Standard top padding for content below a SliverAppBar
  static const double contentTop = 8.0;
  /// Standard bottom padding to clear the nav bar
  static const double contentBottom = 60.0;

  // ── Input / form ─────────────────────────────────────────────────────
  static const double inputLabelGap  =  8.0;
  static const double fieldBottomGap = 22.0;
  static const double inputPaddingH  = 16.0;
  static const double inputPaddingV  = 16.0;
}

// ── Private helper ───────────────────────────────────────────────────────
BorderRadius _br(double r) => BorderRadius.circular(r);

class AppRadius {
  AppRadius._();

  static const double sm   = 10.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double pill = 999.0;

  // ── Convenience BorderRadius ─────────────────────────────────────────
  // ignore: non_constant_identifier_names
  static final BorderRadius smBr   = _br(sm);
  // ignore: non_constant_identifier_names
  static final BorderRadius mdBr   = _br(md);
  // ignore: non_constant_identifier_names
  static final BorderRadius lgBr   = _br(lg);
  // ignore: non_constant_identifier_names
  static final BorderRadius xlBr   = _br(xl);
  // ignore: non_constant_identifier_names
  static final BorderRadius pillBr = _br(pill);
}

class AppSizes {
  AppSizes._();

  // ── Component heights ────────────────────────────────────────────────
  static const double ctaHeight           = 58.0;
  static const double inputHeight         = 56.0;
  static const double languagePillHeight  = 36.0;
  static const double bottomNavHeight     = 68.0;

  // ── Icon containers ──────────────────────────────────────────────────
  static const double planetIconContainer = 44.0;
  static const double heroZodiacOrb       = 72.0;
  static const double forecastIconBox     = 52.0;

  // ── Misc ─────────────────────────────────────────────────────────────
  static const double sectionIconBadge    = 40.0;
  static const double personHeroAvatar    = 48.0;
}
