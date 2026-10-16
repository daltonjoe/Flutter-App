import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

/// content_themes.code -> renk. Her tema kartlarda kendi rengiyle gösterilir.
const Map<String, Color> contentThemeColors = {
  'love': AppColors.themeLove, // yumuşak gül / mercan
  'career': AppColors.themeCareer, // yumuşak gökmavisi
  'identity': AppColors.themeIdentity, // lavanta
  'health': AppColors.themeHealth, // sage
};

Color themeColorFor(String code) =>
    contentThemeColors[code] ?? AppColors.gold; // fallback: gold
