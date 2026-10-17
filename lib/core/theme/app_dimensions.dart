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

  /// Standard inner padding of a card / panel surface
  static const double cardPadding = 20.0;

  /// Vertical gap between two sections
  static const double sectionGap = 32.0;

  /// Vertical gap between two cards of the same section
  static const double cardGap = 12.0;

  /// Standard top padding for content below a SliverAppBar
  static const double contentTop = 8.0;

  /// Standard bottom padding to clear the floating nav bar.
  /// Device safe-area is added on top of this by [AppSizes.scrollBottomPadding].
  static const double contentBottom = 100.0;

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

  // ── Semantic names ───────────────────────────────────────────────────
  /// Card / panel corner radius (24).
  static const double card = lg;

  /// Inner element corner radius (16).
  static const double inner = md;

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
  // ignore: non_constant_identifier_names
  static final BorderRadius cardBr = _br(card);
  // ignore: non_constant_identifier_names
  static final BorderRadius innerBr = _br(inner);
}

class AppSizes {
  AppSizes._();

  // ── Component heights ────────────────────────────────────────────────
  static const double ctaHeight = 52.0;
  static const double inputHeight = 56.0;
  static const double languagePillHeight = 36.0;
  static const double chipHeight = 32.0;
  static const double segmentHeight = 40.0;

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

  // ── Yüzen "hap" navigasyon çubuğu (yeni tasarım) ─────────────────────
  /// Hap çubuğun iç yüksekliği (safe-area ve alt boşluk hariç).
  static const double navBarHeight = 64.0;

  /// Hap çubuğun ekranın altından yüzdüğü boşluk (safe-area eklenir).
  static const double navBarBottomGap = 12.0;

  /// Nav bar ikon boyutu (aktif/pasif aynı).
  static const double navBarIconSize = 24.0;

  /// Aktif etiket için ayrılan dikey alan.
  static const double navBarLabelHeight = 12.0;

  /// Aktif gösterge noktasının çapı.
  static const double navDotSize = 4.0;

  /// Aktif gösterge noktasının çubuk tabanından uzaklığı.
  static const double navDotInset = 8.0;

  /// Cam (glass) efekti için BackdropFilter bulanıklık kuvveti.
  static const double navBarBlurSigma = 20.0;

  /// Ask sekmesinin "nefes" glow daire çapı.
  static const double navGlowSize = 32.0;

  /// Ask sekmesinin "nefes" glow bulanıklığı.
  static const double navGlowBlur = 20.0;

  /// Okunabilirlik perdesinin çubuk üstüne eklediği yumuşak geçiş payı.
  static const double navScrimExtra = 40.0;

  /// Yüzen alt navigasyon çubuğunun toplam iç yüksekliği:
  /// hap yüksekliği + alt boşluk. Safe-area hariçtir.
  static const double bottomNavHeight = navBarHeight + navBarBottomGap;

  /// Yüzen navigasyon çubuğunun altında kalan içerik için gereken boşluk:
  /// çubuk yüksekliği + cihazın alt güvenli alanı (home indicator).
  static double bottomNavInset(BuildContext context) =>
      bottomNavHeight + MediaQuery.of(context).viewPadding.bottom;

  /// Kaydırılabilir (scroll) içerik için alt boşluk:
  /// çubuk bölgesi + cihazın alt güvenli alanı + nefes payı.
  static double scrollBottomPadding(BuildContext context) =>
      bottomNavHeight +
      MediaQuery.of(context).viewPadding.bottom +
      AppSpacing.lg;

  // ── Yükleme (video) ekranları ────────────────────────────────────────
  /// Video ekranlarındaki "yükleniyor" mesaj bloğunun dikey çapası.
  ///
  /// [Alignment] y = 0.30 → bloğun merkezi, güvenli alan içinde ekran
  /// yüksekliğinin ~%65'ine denk gelir. Altında kalan boşluk (ekranın
  /// ~%35'i) yüzen alt menünün ve home indicator'ın çok üstündedir.
  static const Alignment loadingMessageAlignment = Alignment(0.0, 0.30);

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
