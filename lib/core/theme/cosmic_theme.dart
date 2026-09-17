// lib/core/theme/cosmic_theme.dart
// SoulBound Cosmic Sanctum — core theme barrel and ThemeData factory

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

// ── Export all foundations ──────────────────────────────────────────────
export 'app_colors.dart';
export 'app_gradients.dart';
export 'app_shadows.dart';
export 'app_typography.dart';
export 'app_dimensions.dart';
export 'app_borders.dart';
export 'app_decorations.dart';

class CosmicTheme {
  CosmicTheme._();

  // ── Main App Theme ──────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDeep,

        // Base color scheme mapping
        colorScheme: const ColorScheme.dark(
          primary: AppColors.violetPrimary,
          secondary: AppColors.roseAccent,
          surface: AppColors.bgCard,
          error: AppColors.errorRed,
        ),

        // App bar
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bgDeep,
          elevation: 0,
          titleTextStyle: AppTextStyles.appBarTitle(),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),

        // Text theme uses our GoogleFonts-ready text styles
        textTheme: AppTextStyles.materialTextTheme,
      );
}
