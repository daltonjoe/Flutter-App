// Gezegen karuseli (Faz 5). Ölçekleme PageController ile animasyonlanır.
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
import '../../services/reference_names_service.dart';
import '../assets_map.dart';
import '../data/planet_card_view_model.dart';
import '../detail/redesign_detail_page.dart';

class PlanetCarousel extends StatefulWidget {
  const PlanetCarousel({super.key, required this.chartData, this.onSettled});

  final NatalChartResponse chartData;

  final ValueChanged<int>? onSettled;

  @override
  State<PlanetCarousel> createState() => _PlanetCarouselState();
}

class _PlanetCarouselState extends State<PlanetCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: 0.85,
    initialPage: 0,
  );

  int _lastSettled = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = context.watch<ReferenceNamesService>();
    final items = PlanetCardViewModel.fromChart(widget.chartData, names);
    if (items.isEmpty) return const SizedBox.shrink();

    final double height = (MediaQuery.sizeOf(context).height * 0.42).clamp(
      300.0,
      440.0,
    );

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double h = constraints.maxHeight;

          return ScrollConfiguration(
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
                  final item = items[i];
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
                        return _PlanetCard(
                          item: item,
                          chartData: widget.chartData,
                          height: h,
                          scale: f,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanetCard extends StatelessWidget {
  const _PlanetCard({
    required this.item,
    required this.chartData,
    required this.height,
    required this.scale,
  });

  final PlanetCardViewModel item;
  final NatalChartResponse chartData;
  final double height;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double h = height;
    final double f = scale;

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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Arka kart yüzeyi.
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            height: h * 0.62 * f,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.8),
                borderRadius: AppRadius.lgBr,
                border: Border.all(color: AppColors.borderSubtle),
              ),
            ),
          ),
          // Gezegen görseli (yoksa emoji).
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            height: h * 0.55 * f,
            child: Image.asset(
              RdAssets.planetImage(item.key),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(item.emoji, style: AppTextStyles.displayLarge()),
              ),
            ),
          ),
          // Metin bloğu.
          PositionedDirectional(
            start: AppSpacing.md,
            end: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: AppTextStyles.h2(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.retrograde) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.roseAccent.withValues(alpha: 0.15),
                          borderRadius: AppRadius.smBr,
                        ),
                        child: Text(
                          '℞',
                          style: AppTextStyles.miniTag(
                            color: AppColors.roseAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.sign}  ·  ${item.degree.toStringAsFixed(2)}°',
                  style: AppTextStyles.bodyMd(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.houseName != null)
                  Text(
                    '${item.houseName} ${t(context, 'chart.house')}',
                    style: AppTextStyles.bodySm(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
