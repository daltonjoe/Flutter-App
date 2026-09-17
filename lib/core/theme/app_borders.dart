// lib/core/theme/app_borders.dart
// SoulBound Cosmic Sanctum — border presets

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class AppBorders {
  AppBorders._();

  // ── Base border values ───────────────────────────────────────────────
  static const double _width      = 1.0;
  static const double _widthMd    = 1.2;
  static const double _widthFocus = 1.5;

  // ── Solid sides ──────────────────────────────────────────────────────
  /// Default card border — subtle violet
  static const Border cardSubtle = Border.fromBorderSide(
    BorderSide(color: AppColors.borderSubtle, width: _width),
  );

  /// Medium emphasis border — 25 % violet
  static const Border cardMedium = Border.fromBorderSide(
    BorderSide(color: AppColors.borderMedium, width: _width),
  );

  /// Strong emphasis border — 40 % violet
  static const Border cardStrong = Border.fromBorderSide(
    BorderSide(color: AppColors.borderStrong, width: _width),
  );

  /// Error / validation border — 50 % error red
  static const Border errorBorder = Border.fromBorderSide(
    BorderSide(color: AppColors.borderError, width: _widthMd),
  );

  // ── InputDecoration borders ──────────────────────────────────────────
  /// Default unfocused input border (radius = md)
  static OutlineInputBorder inputDefault({bool hasError = false}) =>
      OutlineInputBorder(
        borderRadius: AppRadius.mdBr,
        borderSide: BorderSide(
          color: hasError ? AppColors.borderError : AppColors.borderSubtle,
          width: _widthMd,
        ),
      );

  /// Focused input border
  static OutlineInputBorder inputFocused() => OutlineInputBorder(
        borderRadius: AppRadius.mdBr,
        borderSide: const BorderSide(
          color: AppColors.violetPrimary,
          width: _widthFocus,
        ),
      );

  /// Error state input border
  static OutlineInputBorder inputError() => OutlineInputBorder(
        borderRadius: AppRadius.mdBr,
        borderSide:
            const BorderSide(color: AppColors.borderError, width: _widthMd),
      );

  // ── Convenient side factories (for BoxDecoration.border) ────────────

  /// Returns a [Border] with a single tinted side derived from [color].
  static Border tinted(Color color, {double alpha = 0.25, double width = 1}) =>
      Border.fromBorderSide(
        BorderSide(color: color.withValues(alpha: alpha), width: width),
      );

  /// Returns a violet border at a given opacity (default = borderSubtle).
  static Border violet({double opacity = 0.18, double width = 1}) =>
      Border.fromBorderSide(
        BorderSide(
          color: AppColors.violetPrimary.withValues(alpha: opacity),
          width: width,
        ),
      );
}
