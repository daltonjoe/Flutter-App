// lib/core/theme/app_dimensions.dart
// SoulBound Cosmic Sanctum — spacing, radii, component sizes

import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ── Named page gutters ───────────────────────────────────────────────
  /// Standard horizontal screen padding
  static const double screenH = 20.0;

  /// Standard top padding for content below a SliverAppBar
  static const double contentTop = 8.0;

  /// Standard bottom padding to clear the nav bar
  static const double contentBottom = 60.0;

  // ── Input / form ─────────────────────────────────────────────────────
  static const double inputLabelGap = 8.0;
  static const double fieldBottomGap = 22.0;
  static const double inputPaddingH = 16.0;
  static const double inputPaddingV = 16.0;
}

// ── Private helper ───────────────────────────────────────────────────────
BorderRadius _br(double r) => BorderRadius.circular(r);

class AppRadius {
  AppRadius._();

  static const double sm = 10.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double pill = 999.0;

  // ── Convenience BorderRadius ─────────────────────────────────────────
  // ignore: non_constant_identifier_names
  static final BorderRadius smBr = _br(sm);
  // ignore: non_constant_identifier_names
  static final BorderRadius mdBr = _br(md);
  // ignore: non_constant_identifier_names
  static final BorderRadius lgBr = _br(lg);
  // ignore: non_constant_identifier_names
  static final BorderRadius xlBr = _br(xl);
  // ignore: non_constant_identifier_names
  static final BorderRadius pillBr = _br(pill);
}

class AppSizes {
  AppSizes._();

  // ── Component heights ────────────────────────────────────────────────
  static const double ctaHeight = 58.0;
  static const double inputHeight = 56.0;
  static const double languagePillHeight = 36.0;

  // ── Bottom navigation ────────────────────────────────────────────────
  /// Seçili olmayan sekme dairesinin çapı.
  static const double navItemSize = 48.0;

  /// Seçili sekme dairesinin çapı.
  static const double navItemSelectedSize = 64.0;

  /// Seçili olmayan sekme ikon boyutu.
  static const double navIconSize = 22.0;

  /// Seçili sekme ikon boyutu.
  static const double navIconSelectedSize = 28.0;

  /// Zikzak (dalga) diziliminin genliği. Bir sekmenin gerçek dikey ofseti =
  /// slot çarpanı ([NavWavePattern]) * bu değer.
  static const double navWaveAmplitude = 20.0;

  /// Zikzaklı dizilimde etiket için ayrılan temel dikey alan.
  static const double navLabelHeight = 28.0;

  /// Çubuk içeriğinin dikey nefes payı.
  static const double navVerticalPadding = 8.0;

  /// Yüzen alt navigasyon çubuğunun toplam iç yüksekliği; sabit sayı yerine
  /// bileşenlerden türetilir: seçili daire + etiket + zikzak salınımı + nefes.
  /// Safe-area hariçtir.
  static const double bottomNavHeight =
      navItemSelectedSize +
      navLabelHeight +
      NavWavePattern.maxSwing * navWaveAmplitude +
      navVerticalPadding;

  /// Yüzen navigasyon çubuğunun altında kalan içerik için gereken boşluk:
  /// çubuk yüksekliği + cihazın alt güvenli alanı (home indicator).
  static double bottomNavInset(BuildContext context) =>
      bottomNavHeight + MediaQuery.of(context).viewPadding.bottom;

  // ── Icon containers ──────────────────────────────────────────────────
  static const double planetIconContainer = 44.0;
  static const double heroZodiacOrb = 72.0;
  static const double forecastIconBox = 52.0;

  // ── Misc ─────────────────────────────────────────────────────────────
  static const double sectionIconBadge = 40.0;
  static const double personHeroAvatar = 48.0;
}

/// Zikzaklı (dalgalı) alt menü dizilimi için slot çarpanları.
///
/// Pozitif değer aşağı, negatif değer yukarı öteler; gerçek dikey ofset
/// `çarpan * AppSizes.navWaveAmplitude`. Ofset slot sırasına bağlıdır,
/// seçime bağlı değildir.
class NavWavePattern {
  NavWavePattern._();

  /// 3 görünür sekme.
  static const List<double> three = [0.6, -0.4, 0.6];

  /// 4 görünür sekme.
  static const List<double> four = [0.2, 1.0, -0.4, 0.8];

  /// 5 görünür sekme.
  static const List<double> five = [0.0, 1.0, -0.6, 0.9, 0.3];

  /// Tüm desenlerdeki en büyük dikey salınım farkı |max − min|.
  /// En geniş desen 5 sekmeliktir: 1.0 − (−0.6) = 1.6.
  static const double maxSwing = 1.6;

  /// Sekme sayısına karşılık gelen desen. Tanımsız sayıda düz (boş) döner;
  /// bu durumda tüm ofsetler 0 alınır.
  static List<double> forCount(int count) {
    switch (count) {
      case 3:
        return three;
      case 4:
        return four;
      case 5:
        return five;
      default:
        return const <double>[];
    }
  }
}
