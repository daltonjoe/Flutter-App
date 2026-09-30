import 'package:flutter/material.dart';

/// content_themes.code -> renk. Her tema kartlarda kendi rengiyle gösterilir.
const Map<String, Color> contentThemeColors = {
  'love': Color(0xFFE85D75),     // pembe/rose
  'career': Color(0xFF4A90D9),   // mavi
  'identity': Color(0xFF9B59B6), // mor
  'health': Color(0xFF4CAF50),   // yeşil
};

Color themeColorFor(String code) =>
    contentThemeColors[code] ?? const Color(0xFF8B5CF6); // fallback: violet