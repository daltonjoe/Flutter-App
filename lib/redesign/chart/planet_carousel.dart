// Gezegen karuseli (Faz 5). Ölçekleme PageController ile animasyonlanır.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/cosmic_card.dart';
import '../../presentation/widgets/components/glyph.dart';
import '../../presentation/widgets/components/planet_glyph_icon.dart';
import '../../services/reference_names_service.dart';
import '../assets_map.dart';
import '../data/planet_card_view_model.dart';
import '../detail/redesign_detail_page.dart';
import 'orbit_stars.dart';

/// Burç anahtarları ([AstroGlyphs.glyphs] içinde tanımlı), 0 tabanlı burç
/// indeksine göre sıralı: 0 = Koç … 11 = Balık.
const List<String> _zodiacKeys = <String>[
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
];

/// Burç indeksine göre element rengi (0 fire, 1 earth, 2 air, 3 water).
Color _elementColor(int signIndex) {
  switch (signIndex % 4) {
    case 0:
      return AppColors.elementFire;
    case 1:
      return AppColors.elementEarth;
    case 2:
      return AppColors.elementAir;
    default:
      return AppColors.elementWater;
  }
}

String? _zodiacKeyFor(int signIndex) =>
    (signIndex >= 0 && signIndex < _zodiacKeys.length)
    ? _zodiacKeys[signIndex]
    : null;

/// PlanetHero sahnesinin yüksekliği (dp). Karusel bindirmesi bu değeri
/// paylaşır; başka bir yerde tekrar edilmemelidir.
const double kPlanetHeroHeight = 280;

class PlanetCarousel extends StatefulWidget {
  const PlanetCarousel({
    super.key,
    required this.chartData,
    this.onSettled,
    this.selected,
    this.pagePosition,
  });

  final NatalChartResponse chartData;

  final ValueChanged<int>? onSettled;

  /// Verilirse karusel bu notifier'ı izler ve dışarıdan seçilen sayfaya kayar.
  final ValueNotifier<int>? selected;

  /// Verilirse kaydırma sırasında sayfa konumu (0.0–n) buraya yazılır.
  final ValueNotifier<double>? pagePosition;

  @override
  State<PlanetCarousel> createState() => _PlanetCarouselState();
}

class _PlanetCarouselState extends State<PlanetCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: 0.80,
    initialPage: 0,
  );

  int _lastSettled = 0;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    widget.selected?.addListener(_onSelectedChanged);
    _controller.addListener(_onPageScroll);
  }

  @override
  void didUpdateWidget(covariant PlanetCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      oldWidget.selected?.removeListener(_onSelectedChanged);
      widget.selected?.addListener(_onSelectedChanged);
    }
  }

  @override
  void dispose() {
    widget.selected?.removeListener(_onSelectedChanged);
    _controller.removeListener(_onPageScroll);
    _controller.dispose();
    super.dispose();
  }

  /// Dış notifier değişince: hedef sayfa mevcut sayfadan farklıysa kay.
  /// Değer zaten eşitse hiçbir şey yapılmaz (sonsuz döngü yok).
  void _onSelectedChanged() {
    final target = widget.selected?.value;
    if (target == null || !mounted) return;
    if (!_controller.hasClients || _count == 0) return;
    final current = (_controller.page ?? 0).round();
    if (target == current) return;
    final page = target.clamp(0, _count - 1);
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutExpo,
      );
    }
  }

  /// Kaydırma sırasında sayfa konumunu dış notifiere yazar.
  void _onPageScroll() {
    final notifier = widget.pagePosition;
    if (notifier == null) return;
    if (!_controller.hasClients || !_controller.position.haveDimensions) return;
    final page = _controller.page;
    if (page == null) return;
    if (notifier.value != page) notifier.value = page;
  }

  @override
  Widget build(BuildContext context) {
    final names = context.watch<ReferenceNamesService>();
    final items = PlanetCardViewModel.fromChart(widget.chartData, names);
    _count = items.length;
    if (items.isEmpty) return const SizedBox.shrink();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 168,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (n) {
                if (n.metrics.axis == Axis.horizontal &&
                    _controller.hasClients) {
                  final i = (_controller.page ?? 0).round();
                  if (i != _lastSettled) {
                    _lastSettled = i;
                    widget.onSettled?.call(i);
                  }
                }
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: items.length,
                clipBehavior: Clip.none,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final double page =
                            (_controller.hasClients &&
                                _controller.position.haveDimensions)
                            ? (_controller.page ?? 0.0)
                            : 0.0;
                        final double f = math.max(0.85, 1 - (page - i).abs());
                        return Transform.scale(
                          scale: f,
                          alignment: Alignment.bottomCenter,
                          child: child,
                        );
                      },
                      child: _PlanetCard(
                        item: items[i],
                        chartData: widget.chartData,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PageDots(
          controller: _controller,
          count: items.length,
          reduceMotion: reduceMotion,
        ),
      ],
    );
  }
}

/// Karusel altı nokta göstergesi: aktif nokta altın hap olur.
class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.controller,
    required this.count,
    required this.reduceMotion,
  });

  final PageController controller;
  final int count;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final double page =
            (controller.hasClients && controller.position.haveDimensions)
            ? (controller.page ?? 0.0)
            : 0.0;
        final int active = page.round();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: i == active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == active
                      ? AppColors.gold
                      : AppColors.mist.withValues(alpha: 0.35),
                  borderRadius: AppRadius.pillBr,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PlanetCard extends StatelessWidget {
  const _PlanetCard({required this.item, required this.chartData});

  final PlanetCardViewModel item;
  final NatalChartResponse chartData;

  @override
  Widget build(BuildContext context) {
    final zodiacKey = _zodiacKeyFor(item.signIndex);
    final degree = PlanetCardViewModel.formatDegree(item.degree);
    final house = item.houseNumber;
    final degreeLine = house == null
        ? degree
        : '$degree · '
              "${t(context, 'planet_report.house', args: {'number': '$house'})}";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RedesignDetailPage.planet(
              chartData: chartData,
              planetKey: item.key,
            ),
          ),
        );
      },
      child: Semantics(
        button: true,
        label: '${item.name}, ${item.sign}, $degree',
        child: CosmicCard(
          blur: false,
          radius: AppRadius.card,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Arka planda dev, dekoratif burç görseli (renkli illüstrasyon).
              if (zodiacKey != null)
                PositionedDirectional(
                  end: -48,
                  bottom: -48,
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: 0.60,
                      child: Image.asset(
                        RdAssets.signIcon(item.signIndex),
                        width: 170,
                        height: 170,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Glyph(
                          zodiacKey,
                          size: 170,
                          color: Colors.white.withValues(alpha: 0.06),
                          decorative: true,
                        ),
                      ),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (zodiacKey != null) ...[
                        Image.asset(
                          RdAssets.signIcon(item.signIndex),
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Glyph(
                            zodiacKey,
                            size: 32,
                            color: _elementColor(item.signIndex),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.h2(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.sign,
                              style: AppTextStyles.bodyMd(
                                color: AppColors.mist,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (item.retrograde) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const _RetroChip(),
                      ],
                    ],
                  ),
                  Text(
                    degreeLine,
                    style: AppTextStyles.h1(color: AppColors.gold).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Retrograde işareti ("Rx") mini chip'i.
class _RetroChip extends StatelessWidget {
  const _RetroChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.statusChallenging.withValues(alpha: 0.15),
        borderRadius: AppRadius.smBr,
      ),
      child: Text(
        'Rx',
        style: AppTextStyles.miniTag(color: AppColors.statusChallenging),
      ),
    );
  }
}

/// Gezegen glyph'lerinden oluşan yatay seçim şeridi.
///
/// Seçili öğe altın çerçeve/dolgu ile vurgulanır ve şeritte görünür tutulur.
class PlanetGlyphStrip extends StatefulWidget {
  const PlanetGlyphStrip({
    super.key,
    required this.chartData,
    required this.selected,
  });

  final NatalChartResponse chartData;

  final ValueNotifier<int> selected;

  @override
  State<PlanetGlyphStrip> createState() => _PlanetGlyphStripState();
}

class _PlanetGlyphStripState extends State<PlanetGlyphStrip> {
  static const double _dotSize = 36.0;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.selected.addListener(_keepSelectedVisible);
  }

  @override
  void didUpdateWidget(covariant PlanetGlyphStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      oldWidget.selected.removeListener(_keepSelectedVisible);
      widget.selected.addListener(_keepSelectedVisible);
    }
  }

  @override
  void dispose() {
    widget.selected.removeListener(_keepSelectedVisible);
    _scroll.dispose();
    super.dispose();
  }

  /// Seçili öğeyi şeridin ortasına getirir (dış sayfayı kaydırmaz).
  void _keepSelectedVisible() {
    if (!mounted || !_scroll.hasClients) return;
    final i = widget.selected.value;
    final viewport = _scroll.position.viewportDimension;
    final itemStart = AppSpacing.screenH + i * (_dotSize + AppSpacing.sm);
    final target = (itemStart - (viewport - _dotSize) / 2).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = context.watch<ReferenceNamesService>();
    final items = PlanetCardViewModel.fromChart(widget.chartData, names);
    if (items.isEmpty) return const SizedBox.shrink();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return ValueListenableBuilder<int>(
      valueListenable: widget.selected,
      builder: (context, active, _) {
        return SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.screenH,
          ),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                _GlyphDot(
                  item: items[i],
                  selected: i == active,
                  reduceMotion: reduceMotion,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.selected.value = i;
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Şeritteki tek gezegen glyph dairesi.
class _GlyphDot extends StatelessWidget {
  const _GlyphDot({
    required this.item,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  final PlanetCardViewModel item;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.navyRaised : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.hairline,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: PlanetGlyphIcon(
              name: item.key.toLowerCase(),
              size: 20,
              color: selected ? AppColors.gold : AppColors.mist,
              decorative: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// Seçili gezegenin sahnesi: glow, yörünge halkaları ve gezegen görseli.
///
/// Ekrandaki tek ambient hareket arkadaki altın glow'dur; halkalar statiktir.
class PlanetHero extends StatefulWidget {
  const PlanetHero({
    super.key,
    required this.chartData,
    required this.selected,
    this.pagePosition,
  });

  final NatalChartResponse chartData;

  final ValueListenable<int> selected;

  /// Verilirse gezegen görselleri kaydırma konumuna göre kayar.
  final ValueListenable<double>? pagePosition;

  @override
  State<PlanetHero> createState() => _PlanetHeroState();
}

class _PlanetHeroState extends State<PlanetHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TickerProviderStateMixin sayesinde TickerMode kapalıyken ticker askıya
    // alınır; burada yalnızca "hareketi azalt" tercihi yönetilir.
    if (MediaQuery.disableAnimationsOf(context)) {
      _glow.stop();
    } else if (!_glow.isAnimating) {
      _glow.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final names = context.watch<ReferenceNamesService>();
    final items = PlanetCardViewModel.fromChart(widget.chartData, names);
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: kPlanetHeroHeight,
      child: ValueListenableBuilder<int>(
        valueListenable: widget.selected,
        builder: (context, index, _) {
          final item = items[index.clamp(0, items.length - 1)];
          // Tek RepaintBoundary: sahne birlikte boyanır. Stack sırası
          // halkalar → yıldızlar → gezegen'dir.
          return RepaintBoundary(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Center(
                    child: _HeroGlow(
                      controller: _glow,
                      reduceMotion: reduceMotion,
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: CustomPaint(painter: _OrbitRingsPainter()),
                ),
                Positioned.fill(
                  child: OrbitStars(
                    trigger: item.key,
                    reduceMotion: reduceMotion,
                  ),
                ),
                Positioned.fill(
                  child: _visualLayer(items, index, reduceMotion),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Gezegen görselleri katmanı.
  ///
  /// [PlanetHero.pagePosition] verilmişse görseller kaydırma konumuna göre
  /// yatayda kayar; verilmemişse (veya hareket azaltma açıksa) seçili görsel
  /// çapraz geçişle gösterilir.
  Widget _visualLayer(
    List<PlanetCardViewModel> items,
    int index,
    bool reduceMotion,
  ) {
    final position = widget.pagePosition;
    if (position == null || reduceMotion) {
      final item = items[index.clamp(0, items.length - 1)];
      final duration = reduceMotion
          ? const Duration(milliseconds: 150)
          : const Duration(milliseconds: 450);
      return AnimatedSwitcher(
        duration: duration,
        switchInCurve: reduceMotion ? Curves.linear : Curves.easeOutExpo,
        transitionBuilder: (child, animation) {
          if (reduceMotion) {
            return FadeTransition(opacity: animation, child: child);
          }
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
              child: child,
            ),
          );
        },
        child: _planetImage(item, key: ValueKey<String>(item.key)),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: position,
      builder: (context, page, _) {
        return ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double sceneWidth = constraints.maxWidth;
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 0; i < items.length; i++)
                    if ((i - page).abs() < 1.5)
                      _slidingImage(context, items[i], i - page, sceneWidth),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Tek gezegen görselini kaydırma konumuna göre kaydırır, ölçekler ve
  /// soldurur.
  Widget _slidingImage(
    BuildContext context,
    PlanetCardViewModel item,
    double d,
    double sceneWidth,
  ) {
    // t: kenara yaklastikca 0 -> 1 (easeOut).
    final double t = Curves.easeOut.transform(d.abs().clamp(0.0, 1.0));
    final double scale = 1.0 - 0.45 * t; // lerp(1.0, 0.55, t)
    final double opacity = 1 - 0.7 * t;
    // RTL'de kayma yonu ters cevrilir.
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.translate(
      offset: Offset(d * sceneWidth * 0.55 * (rtl ? -1 : 1), 0),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(scale: scale, child: _planetImage(item)),
      ),
    );
  }

  /// Gezegen görseli; asset yüklenemezse emoji'ye düşer.
  Widget _planetImage(PlanetCardViewModel item, {Key? key}) {
    return Image.asset(
      RdAssets.planetImage(item.key),
      key: key,
      height: 220,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Text(item.emoji, style: AppTextStyles.displayLarge()),
    );
  }
}

/// Arkadaki tek altın glow: 5 sn'lik nefes (opaklık 0.25 ↔ 0.38).
class _HeroGlow extends StatelessWidget {
  const _HeroGlow({required this.controller, required this.reduceMotion});

  final AnimationController controller;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final double alpha = reduceMotion
            ? 0.30
            : 0.25 + 0.13 * Curves.easeInOutSine.transform(controller.value);
        return Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.gold.withValues(alpha: alpha),
                AppColors.gold.withValues(alpha: alpha * 0.4),
                AppColors.gold.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: alpha * 0.5),
                blurRadius: 32,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Statik eş merkezli altın yörünge halkaları. Çaplar [kRingDiameters] ile
/// OrbitStars ile paylaşılır (yarıçaplar 100 / 125 / 150 dp).
class _OrbitRingsPainter extends CustomPainter {
  const _OrbitRingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gold.withValues(alpha: 0.15);
    for (final d in kRingDiameters) {
      canvas.drawCircle(center, d / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingsPainter oldDelegate) => false;
}
