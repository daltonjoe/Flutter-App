import 'planet_glyph_icon.dart';
// lib/presentation/widgets/components/glyph.dart
// Astroloji sembolü çizen bileşen: SVG (varsa) -> Unicode -> metin etiketi.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/astro_glyphs.dart';
import '../../../core/theme/app_colors.dart';

/// `assets/glyphs/` altında SVG varlığı bulunan glyph anahtarları.
///
/// Listelenen anahtarlar için [Glyph], `assets/glyphs/<anahtar>.svg`
/// varlığını çizer; listede olmayanlar Unicode/metin yedeğine düşer.
const Set<String> kSvgGlyphs = <String>{
  // ── Burçlar ──
  'aries',
  'taurus',
  'gemini',
  'cancer',
  'leo',
  'virgo',
  'libra',
  'scorpio',
  'sagittarius',
  'capricorn',
  'aquarius',
  'pisces',
  // ── Açılar ──
  'conjunction',
  'sextile',
  'square',
  'trine',
  'opposition',
  // ── Elementler ──
  'fire',
  'earth',
  'air',
  'water',
};

/// Astroloji sembolü gösteren widget.
///
/// Çizim sırası: (a) [kSvgGlyphs] içindeyse SVG, (b) Unicode fallback,
/// (c) ASC/MC gibi metin etiketleri. Bilinmeyen anahtar boş kutu döndürür ve
/// hiçbir exception fırlatmaz.
class Glyph extends StatelessWidget {
  const Glyph(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
    this.decorative = false,
    this.semanticLabel,
  });

  /// [AstroGlyphs.glyphs] içindeki anahtar.
  final String name;

  /// Sembolün kare boyutu (dp).
  final double size;

  /// Sembol rengi; verilmezse [AppColors.mist].
  final Color? color;

  /// true ise semantics ağacından tamamen dışlanır (süsleme).
  final bool decorative;

  /// Erişilebilirlik etiketi; verilmezse [name] kullanılır.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (PlanetGlyphIcon.supports(name)) {
      return PlanetGlyphIcon(
        name: name,
        size: size,
        color: color,
        decorative: decorative,
        semanticLabel: semanticLabel,
      );
    }
    final resolved = color ?? AppColors.mist;
    final glyph = AstroGlyphs.glyphFor(name);

    final Widget child;
    if (kSvgGlyphs.contains(name)) {
      child = SvgPicture.asset(
        'assets/glyphs/$name.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
      );
    } else if (glyph == null) {
      child = SizedBox(width: size, height: size);
    } else if (glyph.isTextLabel) {
      child = Text(
        glyph.character,
        textScaler: TextScaler.noScaling,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: size * 0.55,
          fontWeight: FontWeight.w700,
          color: resolved,
        ),
      );
    } else {
      // U+FE0E (variation selector-15): metin sunumunu zorlar, emoji render'ı engeller.
      // Paketlenmiş NotoSansSymbols2 kullanılır; ağ indirmesi olmadığından ilk
      // karede emoji fallback'ine düşülmez.
      child = SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            '${glyph.character}\uFE0E',
            textScaler: TextScaler.noScaling,
            textAlign: TextAlign.center,
            softWrap: false,
            overflow: TextOverflow.visible,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            strutStyle: const StrutStyle(
              forceStrutHeight: true,
              height: 1.0,
              leading: 0,
              fontFamily: 'NotoSansSymbols2',
            ),
            style: TextStyle(
              fontFamily: 'NotoSansSymbols2',
              fontSize: size,
              height: 1.0,
              color: resolved,
            ),
          ),
        ),
      );
    }

    if (decorative) {
      return ExcludeSemantics(child: child);
    }
    return Semantics(
      label: semanticLabel ?? name,
      image: true,
      child: child,
    );
  }
}
