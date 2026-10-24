// Harita dengesi (Faz 7b): Element, Polarity ve Modality halkaları.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/astro_glyphs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/cosmic_card.dart';
import '../../presentation/widgets/components/glyph.dart';
import '../../presentation/widgets/components/overline_text.dart';

/// Element kodu sırası (0 ateş, 1 toprak, 2 hava, 3 su).
const List<String> _kElementOrder = <String>['fire', 'earth', 'air', 'water'];

/// Element dağılımı için çıkarım cümlesi.
///
/// [ChartExtras] içindeki eski `_inference` ile aynı mantığı ve aynı
/// `rd.chart.element_*` anahtarlarını kullanır; tek yerde tutulur.
String elementInferenceText(BuildContext context, Map<String, int> counts) {
  final vals = <int>[for (final code in _kElementOrder) counts[code] ?? 0];
  final allEqual = vals.every((v) => v == vals.first);
  if (allEqual) return t(context, 'rd.chart.element_balanced');

  var maxV = vals.first;
  for (final v in vals) {
    if (v > maxV) maxV = v;
  }

  final idx = <int>[0, 1, 2, 3]
    ..sort((a, b) {
      final diff = vals[b] - vals[a];
      return diff != 0 ? diff : a - b;
    });

  final a = t(context, 'elements.${_kElementOrder[idx[0]]}');
  if (vals[idx[1]] >= maxV - 1) {
    final b = t(context, 'elements.${_kElementOrder[idx[1]]}');
    return t(context, 'rd.chart.element_dominant_two', args: {'a': a, 'b': b});
  }
  return t(context, 'rd.chart.element_dominant_one', args: {'a': a});
}

/// Element, kutupluluk (aktif/pasif) ve nitelik dagilimini tek kartta
/// uc halka halinde gosteren bolum. Degerler sunucudan gelir
/// ([NatalChartResponse.distribution]); yoksa bolum gizlenir.
class ChartBalanceSection extends StatelessWidget {
  const ChartBalanceSection({super.key, required this.chartData});

  final NatalChartResponse chartData;

  /// Bu genişliğin altında Element üstte tek satır, Polarity ve Modality
  /// altta iki sütun olur.
  static const double _narrowWidth = 340;

  @override
  Widget build(BuildContext context) {
    final dist = chartData.distribution;
    if (dist == null) return const SizedBox.shrink();

    final elementCounts = <String, int>{
      for (final code in _kElementOrder) code: dist.elements[code]!.raw,
    };

    final elementSegments = <_Segment>[
      for (var i = 0; i < _kElementOrder.length; i++)
        _Segment(
          'elements.${_kElementOrder[i]}',
          dist.elements[_kElementOrder[i]]!.pct,
          AstroGlyphs.elementColors[_kElementOrder[i]]!,
          glyphKey: _kElementOrder[i],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CosmicCard(
          blur: false,
          child: LayoutBuilder(
            builder: (context, box) {
              final narrow = box.maxWidth < _narrowWidth;
              final columnWidth = narrow
                  ? (box.maxWidth - AppSpacing.md) / 2
                  : (box.maxWidth - AppSpacing.md * 2) / 3;
              final ringSize = _ringSize(columnWidth);

              final elementColumn = _BalanceColumn(
                titleKey: 'chart.elements',
                segments: elementSegments,
                ringSize: narrow ? _ringSize(box.maxWidth) : ringSize,
                horizontal: narrow,
              );
              final polarityColumn = _BalanceColumn(
                titleKey: 'rd.chart.polarity',
                segments: [
                  _Segment(
                    'rd.chart.active',
                    dist.polarity['active']!.pct,
                    AppColors.gold,
                  ),
                  _Segment(
                    'rd.chart.passive',
                    dist.polarity['passive']!.pct,
                    AppColors.elementWater,
                  ),
                ],
                ringSize: ringSize,
              );
              final modalityColumn = _BalanceColumn(
                titleKey: 'rd.chart.modality',
                segments: [
                  _Segment(
                    'rd.chart.cardinal',
                    dist.modalities['cardinal']!.pct,
                    AppColors.gold,
                  ),
                  _Segment(
                    'rd.chart.fixed',
                    dist.modalities['fixed']!.pct,
                    AppColors.mist,
                  ),
                  _Segment(
                    'rd.chart.mutable',
                    dist.modalities['mutable']!.pct,
                    AppColors.elementAir,
                  ),
                ],
                ringSize: ringSize,
              );

              if (!narrow) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: elementColumn),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: polarityColumn),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: modalityColumn),
                  ],
                );
              }

              // Dar ekran / büyük metin: Element üstte tek satır, diğerleri
              // altta iki sütun (RTL'de sıra doğal akar).
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  elementColumn,
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: polarityColumn),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: modalityColumn),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          elementInferenceText(context, elementCounts),
          style: AppTextStyles.bodyMd(),
        ),
      ],
    );
  }

  /// Sütun genişliğinden halka boyutu: (genişlik − 8) ve 76–104 dp arası.
  static double _ringSize(double columnWidth) =>
      (columnWidth - AppSpacing.sm).clamp(76.0, 104.0);
}

/// Tek dağılım sütunu: başlık, halka, lejant satırları.
///
/// [horizontal] true iken halka ve lejant tek satırda yan yana durur
/// (dar ekranda Element sütunu).
class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({
    required this.titleKey,
    required this.segments,
    required this.ringSize,
    this.horizontal = false,
  });

  final String titleKey;
  final List<_Segment> segments;
  final double ringSize;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final ring = _BalanceRing(
      titleKey: titleKey,
      segments: segments,
      size: ringSize,
    );
    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          _LegendRow(segment: segments[i]),
        ],
      ],
    );

    if (horizontal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OverlineText(t(context, titleKey)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              ring,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: legend),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        OverlineText(t(context, titleKey)),
        const SizedBox(height: AppSpacing.md),
        ring,
        const SizedBox(height: AppSpacing.md),
        legend,
      ],
    );
  }
}

/// Tek halka: giriş animasyonlu dilimler ve merkezde baskın yüzde.
class _BalanceRing extends StatelessWidget {
  const _BalanceRing({
    required this.titleKey,
    required this.segments,
    required this.size,
  });

  final String titleKey;
  final List<_Segment> segments;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    var dominant = 0;
    for (var i = 1; i < segments.length; i++) {
      if (segments[i].percent > segments[dominant].percent) dominant = i;
    }

    return Semantics(
      label: _semanticsLabel(context),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              painter: _RingPainter(
                segments: segments,
                progress: value,
                background: Colors.white.withValues(alpha: 0.08),
              ),
              child: Center(
                child: Text(
                  '%${segments[dominant].percent}',
                  style: AppTextStyles.h2(
                    color: AppColors.starlight,
                  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _semanticsLabel(BuildContext context) {
    final parts = <String>[
      for (final seg in segments) '${t(context, seg.labelKey)} %${seg.percent}',
    ];
    return '${t(context, titleKey)}: ${parts.join(', ')}';
  }
}

/// Halka lejantı: renk noktası + etiket + yüzde.
class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segment});

  final _Segment segment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (segment.glyphKey != null)
          Glyph(
            segment.glyphKey!,
            size: 12,
            color: segment.color,
            decorative: true,
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: segment.color,
            ),
          ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            t(context, segment.labelKey),
            style: AppTextStyles.bodyXs(color: AppColors.mist),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '%${segment.percent}',
          style: AppTextStyles.bodySm(
            color: AppColors.starlight,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          maxLines: 1,
        ),
      ],
    );
  }
}

/// Halka dilimi: etiket anahtarı, tam sayı yüzde ve renk.
class _Segment {
  const _Segment(this.labelKey, this.percent, this.color, {this.glyphKey});

  final String labelKey;
  final int percent;
  final Color color;

  /// Varsa, lejant noktasi yerine cizilen glyph anahtari (element kodu).
  final String? glyphKey;

  @override
  bool operator ==(Object other) =>
      other is _Segment &&
      other.labelKey == labelKey &&
      other.percent == percent &&
      other.color == color &&
      other.glyphKey == glyphKey;

  @override
  int get hashCode => Object.hash(labelKey, percent, color, glyphKey);
}

/// Segmentleri halka üzerine çizen ressam; animasyon `progress` ile sürülür.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.segments,
    required this.progress,
    required this.background,
  });

  final List<_Segment> segments;
  final double progress;
  final Color background;

  static const double _strokeWidth = 10;
  static const double _gap = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..color = background,
    );

    final visible = segments.where((s) => s.percent > 0).toList();
    final gap = visible.length > 1 ? _gap : 0.0;

    var start = -math.pi / 2;
    for (final seg in segments) {
      if (seg.percent <= 0) continue;
      final fraction = seg.percent / 100;
      final sweep = math.max(0.0, fraction * 2 * math.pi - gap);
      if (sweep > 0) {
        canvas.drawArc(
          rect,
          start,
          sweep * progress,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _strokeWidth
            ..color = seg.color,
        );
      }
      start += fraction * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.background != background ||
      !listEquals(old.segments, segments);
}
