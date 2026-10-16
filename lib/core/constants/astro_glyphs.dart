// lib/core/constants/astro_glyphs.dart
// Astroloji glyph (sembol) altyapısı: burç, gezegen ve açılar için Unicode
// karakter eşleştirmeleri; element ve açı renk yardımcıları.

import 'dart:ui' show Color;

import '../theme/app_colors.dart';

/// Tek bir astroloji sembolünün çizim verisi.
class AstroGlyph {
  const AstroGlyph(this.character, {this.isTextLabel = false});

  /// Unicode sembol; [isTextLabel] true ise kısa metin etiketi (ASC/MC).
  final String character;

  /// true ise [character] sembol değil, kısa metin etiketi olarak çizilir.
  final bool isTextLabel;
}

/// Glyph anahtarı -> Unicode karakter / metin etiketi eşleştirmeleri.
///
/// Bilinmeyen anahtarlar için [glyphFor] null döndürür; fallback davranışı
/// çağıran widget'a ([Glyph]) aittir.
class AstroGlyphs {
  AstroGlyphs._();

  /// Tüm desteklenen anahtarlar.
  static const Map<String, AstroGlyph> glyphs = <String, AstroGlyph>{
    // ── Burçlar ─────────────────────────────────────────────────────────
    'aries': AstroGlyph('\u2648'),
    'taurus': AstroGlyph('\u2649'),
    'gemini': AstroGlyph('\u264A'),
    'cancer': AstroGlyph('\u264B'),
    'leo': AstroGlyph('\u264C'),
    'virgo': AstroGlyph('\u264D'),
    'libra': AstroGlyph('\u264E'),
    'scorpio': AstroGlyph('\u264F'),
    'sagittarius': AstroGlyph('\u2650'),
    'capricorn': AstroGlyph('\u2651'),
    'aquarius': AstroGlyph('\u2652'),
    'pisces': AstroGlyph('\u2653'),
    // ── Gezegenler ──────────────────────────────────────────────────────
    'sun': AstroGlyph('\u2609'),
    'moon': AstroGlyph('\u263D'),
    'mercury': AstroGlyph('\u263F'),
    'venus': AstroGlyph('\u2640'),
    'mars': AstroGlyph('\u2642'),
    'jupiter': AstroGlyph('\u2643'),
    'saturn': AstroGlyph('\u2644'),
    'uranus': AstroGlyph('\u2645'),
    'neptune': AstroGlyph('\u2646'),
    'pluto': AstroGlyph('\u2647'),
    // ── Açılar ──────────────────────────────────────────────────────────
    'conjunction': AstroGlyph('\u260C'),
    'sextile': AstroGlyph('\u26B9'),
    'square': AstroGlyph('\u25A1'),
    'trine': AstroGlyph('\u25B3'),
    'opposition': AstroGlyph('\u260D'),
    // ── Açılar / köşe noktaları (metin etiketi) ─────────────────────────
    'asc': AstroGlyph('ASC', isTextLabel: true),
    'mc': AstroGlyph('MC', isTextLabel: true),
  };

  /// Anahtara karşılık gelen glyph; bilinmeyen anahtar için null.
  static AstroGlyph? glyphFor(String name) => glyphs[name];

  /// Burç -> element (fire/earth/air/water). Bilinmeyen anahtar için null.
  static const Map<String, String> zodiacElements = <String, String>{
    'aries': 'fire',
    'leo': 'fire',
    'sagittarius': 'fire',
    'taurus': 'earth',
    'virgo': 'earth',
    'capricorn': 'earth',
    'gemini': 'air',
    'libra': 'air',
    'aquarius': 'air',
    'cancer': 'water',
    'scorpio': 'water',
    'pisces': 'water',
  };

  /// Element -> mevcut AppColors element token'ı.
  static const Map<String, Color> elementColors = <String, Color>{
    'fire': AppColors.elementFire,
    'earth': AppColors.elementEarth,
    'air': AppColors.elementAir,
    'water': AppColors.elementWater,
  };

  /// Açı -> mevcut AppColors durum token'ı.
  static const Map<String, Color> aspectColors = <String, Color>{
    'conjunction': AppColors.gold,
    'sextile': AppColors.statusSupportive,
    'trine': AppColors.statusSupportive,
    'square': AppColors.statusChallenging,
    'opposition': AppColors.statusChallenging,
  };

  /// Burç anahtarından element rengi; bilinmeyen anahtar için null.
  static Color? elementColorFor(String name) {
    final element = zodiacElements[name];
    return element == null ? null : elementColors[element];
  }

  /// Açı anahtarından durum rengi; bilinmeyen anahtar için null.
  static Color? aspectColorFor(String name) => aspectColors[name];
}
