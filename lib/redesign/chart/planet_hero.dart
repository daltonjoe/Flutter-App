// Gezegen sahnesi (Faz 3): altın glow, yörünge halkaları ve gezegen görseli.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/planet_glyph_icon.dart';
import '../../services/reference_names_service.dart';
import '../assets_map.dart';
import '../data/planet_card_view_model.dart';
import 'orbit_stars.dart';

/// PlanetHero sahnesinin yüksekliği (dp). Karusel bindirmesi bu değeri
/// paylaşır; başka bir yerde tekrar edilmemelidir.
const double kPlanetHeroHeight = 280;

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

  /// Gezegen görseli; asset yüklenemezse gezegen glyph'ine düşer.
  Widget _planetImage(PlanetCardViewModel item, {Key? key}) {
    return Image.asset(
      RdAssets.planetImage(item.key),
      key: key,
      height: 220,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => PlanetGlyphIcon(
        name: item.key.toLowerCase(),
        size: 28,
        color: AppColors.mist,
        semanticLabel: item.name,
      ),
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
