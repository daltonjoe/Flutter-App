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

/// Haritadaki gezegenlerin element, kutupluluk (polarity) ve nitelik
/// (modality) dağılımını tek kartta üç halka hâlinde gösteren bölüm.
///
/// Üç dağılım da aynı gezegen kümesinden (Sun…Pluto; doğum saati
/// bilinmiyorsa Moon hariç) hesaplanır. Kartın altında element çıkarım
/// cümlesi yer alır.
class ChartBalanceSection extends StatelessWidget {
  const ChartBalanceSection({super.key, required this.chartData});

  final NatalChartResponse chartData;

  static const List<String> _planetOrder = <String>[
    'Sun',
    'Moon',
    'Mercury',
    'Venus',
    'Mars',
    'Jupiter',
    'Saturn',
    'Uranus',
    'Neptune',
    'Pluto',
  ];

  /// Bu genişliğin altında Element üstte tek satır, Polarity ve Modality
  /// altta iki sütun olur.
  static const double _narrowWidth = 340;

  @override
  Widget build(BuildContext context) {
    final planets = chartData.planets ?? const <String, PlanetData>{};
    final birthTimeKnown = chartData.input?.birthTimeKnown == true;

    final element = <int>[0, 0, 0, 0]; // [ateş, toprak, hava, su]
    final polarity = <int>[0, 0]; // [eril, dişil]
    final modality = <int>[0, 0, 0]; // [öncü, sabit, değişken]
    var count = 0;
    for (final key in _planetOrder) {
      if (!birthTimeKnown && key == 'Moon') continue;
      final data = planets[key];
      if (data == null) continue;
      count++;
      element[data.signIndex % 4] += 1;
      polarity[data.signIndex % 2 == 0 ? 0 : 1] += 1;
      modality[data.signIndex % 3] += 1;
    }
    if (count == 0) return const SizedBox.shrink();

    final elementPct = _toPercent(element);
    final polarityPct = _toPercent(polarity);
    final modalityPct = _toPercent(modality);
    final elementCounts = <String, int>{
      for (var i = 0; i < _kElementOrder.length; i++)
        _kElementOrder[i]: element[i],
    };

    final elementSegments = <_Segment>[
      for (var i = 0; i < _kElementOrder.length; i++)
        _Segment(
          'elements.${_kElementOrder[i]}',
          elementPct[i],
          AstroGlyphs.elementColors[_kElementOrder[i]]!,
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
                  _Segment('rd.chart.masculine', polarityPct[0], AppColors.gold),
                  _Segment(
                    'rd.chart.feminine',
                    polarityPct[1],
                    AppColors.elementWater,
                  ),
                ],
                ringSize: ringSize,
              );
              final modalityColumn = _BalanceColumn(
                titleKey: 'rd.chart.modality',
                segments: [
                  _Segment('rd.chart.cardinal', modalityPct[0], AppColors.gold),
                  _Segment('rd.chart.fixed', modalityPct[1], AppColors.mist),
                  _Segment(
                    'rd.chart.mutable',
                    modalityPct[2],
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

  /// En büyük kalan yöntemiyle yüzdeleri tam sayıya çevirir; toplam 100 olur.
  static List<int> _toPercent(List<int> counts) {
    final total = counts.fold<int>(0, (a, b) => a + b);
    if (total == 0) return List<int>.filled(counts.length, 0);
    final exact = <double>[for (final c in counts) c / total * 100];
    final out = <int>[for (final e in exact) e.floor()];
    var remainder = 100 - out.fold<int>(0, (a, b) => a + b);
    final order = List<int>.generate(counts.length, (i) => i)
      ..sort((a, b) {
        final diff = (exact[b] - out[b]).compareTo(exact[a] - out[a]);
        return diff != 0 ? diff : a - b;
      });
    var k = 0;
    while (remainder > 0) {
      out[order[k % order.length]] += 1;
      remainder--;
      k++;
    }
    return out;
  }
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
  const _Segment(this.labelKey, this.percent, this.color);

  final String labelKey;
  final int percent;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is _Segment &&
      other.labelKey == labelKey &&
      other.percent == percent &&
      other.color == color;

  @override
  int get hashCode => Object.hash(labelKey, percent, color);
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
