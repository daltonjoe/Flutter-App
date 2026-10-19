// Gezegen karuseli (Faz 5). Ölçekleme PageController ile animasyonlanır.
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/astro_glyphs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/cosmic_card.dart';
import '../../presentation/widgets/components/glyph.dart';
import '../../services/reference_names_service.dart';
import '../assets_map.dart';
import '../data/planet_card_view_model.dart';
import '../detail/redesign_detail_page.dart';

export 'planet_glyph_strip.dart';
export 'planet_hero.dart';

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

/// Burç indeksine göre element rengi. Element→renk eşlemesinin tek kaynağı
/// [AstroGlyphs]'tir; burada yalnız indeks→burç anahtarı çözülür.
Color _elementColor(int signIndex) {
  final key = _zodiacKeys[signIndex % _zodiacKeys.length];
  return AstroGlyphs.elementColorFor(key) ?? AppColors.elementWater;
}

String? _zodiacKeyFor(int signIndex) =>
    (signIndex >= 0 && signIndex < _zodiacKeys.length)
    ? _zodiacKeys[signIndex]
    : null;

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
