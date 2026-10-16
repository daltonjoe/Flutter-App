// Harita ekstraları (Faz 7b): element dağılımı, retrogezegenler,
// Yükselen/MC etiketleri ve Forecast/Analysis butonları.
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
import '../../screens/forecast_selection_page.dart';
import '../../screens/natal_report_page.dart';

class ChartExtras extends StatelessWidget {
  const ChartExtras({
    super.key,
    required this.chartData,
    required this.userName,
  });

  final NatalChartResponse chartData;
  final String userName;

  static const Map<String, Color> _elementColors = {
    'fire': AppColors.elementFire,
    'earth': AppColors.elementEarth,
    'air': AppColors.elementAir,
    'water': AppColors.elementWater,
  };

  static const Map<String, String> _elementKeys = {
    'fire': 'elements.fire',
    'earth': 'elements.earth',
    'air': 'elements.air',
    'water': 'elements.water',
  };

  static const Map<String, String> _planetKeys = {
    'Sun': 'chart.sun',
    'Moon': 'chart.moon',
    'Mercury': 'chart.mercury',
    'Venus': 'chart.venus',
    'Mars': 'chart.mars',
    'Jupiter': 'chart.jupiter',
    'Saturn': 'chart.saturn',
    'Uranus': 'chart.uranus',
    'Neptune': 'chart.neptune',
    'Pluto': 'chart.pluto',
  };

  static const Map<String, String> _planetEmojis = {
    'Sun': '☀️',
    'Moon': '🌙',
    'Mercury': '☿',
    'Venus': '♀',
    'Mars': '♂',
    'Jupiter': '♃',
    'Saturn': '♄',
    'Uranus': '♅',
    'Neptune': '♆',
    'Pluto': '♇',
  };

  @override
  Widget build(BuildContext context) {
    final summary = chartData.summary;
    final angles = chartData.angles;
    final birthTimeKnown = chartData.input?.birthTimeKnown == true;

    final elements = summary?.elementDistribution ?? const <String, int>{};
    final retrogrades = summary?.retrogradePlanets ?? const <String>[];

    final sections = <Widget>[
      if (elements.isNotEmpty) _elementSection(context, elements),
      if (retrogrades.isNotEmpty) _retroSection(context, retrogrades),
      if (birthTimeKnown && angles != null) _ascMcSection(context, angles),
      _buttons(context),
    ];

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.screenH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _spaced(sections),
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(const SizedBox(height: AppSpacing.lg));
      out.add(items[i]);
    }
    return out;
  }

  Widget _sectionTitle(BuildContext context, String key) => Text(
    t(context, key),
    style: AppTextStyles.h3(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.bgCard.withValues(alpha: 0.8),
      borderRadius: AppRadius.lgBr,
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: child,
  );

  // ── 1. Element dağılımı ────────────────────────────────────────────
  Widget _elementSection(BuildContext context, Map<String, int> elements) {
    final total = elements.values.fold(0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'chart.element_distribution'),
        const SizedBox(height: AppSpacing.sm),
        _card(
          child: Column(
            children: [
              for (final entry in elements.entries)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.sm,
                  ),
                  child: _elementRow(context, entry.key, entry.value, total),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _elementRow(BuildContext context, String code, int count, int total) {
    final double pct = total > 0 ? count / total : 0.0;
    final color = _elementColors[code] ?? AppColors.violetPrimary;
    final label = t(context, _elementKeys[code] ?? code);
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: AppTextStyles.bodyXs(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.smBr,
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$count',
          style: AppTextStyles.bodySm(
            color: color,
          ).copyWith(fontWeight: FontWeight.w700),
          maxLines: 1,
        ),
      ],
    );
  }

  // ── 2. Retrogezegenler ─────────────────────────────────────────────
  Widget _retroSection(BuildContext context, List<String> retrogrades) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'chart.retrograde_planets'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final key in retrogrades) _retroChip(context, key),
          ],
        ),
      ],
    );
  }

  Widget _retroChip(BuildContext context, String key) {
    final emoji = _planetEmojis[key] ?? '✦';
    final nameKey = _planetKeys[key];
    final name = nameKey == null ? key : t(context, nameKey);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.roseAccent.withValues(alpha: 0.08),
        borderRadius: AppRadius.smBr,
        border: Border.all(color: AppColors.roseAccent.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$emoji $name ℞',
        style: AppTextStyles.bodyXs(
          color: AppColors.roseAccent,
        ).copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── 3. Yükselen / MC ───────────────────────────────────────────────
  Widget _ascMcSection(BuildContext context, ChartAngles angles) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _miniTag(
          'ASC',
          '${angles.ascSign} ${angles.ascDegree.toStringAsFixed(0)}°',
        ),
        _miniTag(
          'MC',
          '${angles.mcSign} ${angles.mcDegree.toStringAsFixed(0)}°',
        ),
      ],
    );
  }

  Widget _miniTag(String label, String value) => Container(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.violetPrimary.withValues(alpha: 0.15),
      borderRadius: AppRadius.smBr,
      border: Border.all(color: AppColors.violetPrimary.withValues(alpha: 0.3)),
    ),
    child: Text(
      '$label · $value',
      style: AppTextStyles.miniTag(color: AppColors.violetPrimary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );

  // ── 4. CTA butonları ───────────────────────────────────────────────
  Widget _buttons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _forecastButton(context),
        const SizedBox(height: AppSpacing.sm),
        _analysisButton(context),
      ],
    );
  }

  Widget _forecastButton(BuildContext context) {
    return Material(
      color: AppColors.bgCard.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBr,
        side: BorderSide(
          color: AppColors.violetPrimary.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ForecastSelectionPage(chartData: chartData),
          ),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: AlignmentDirectional.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timeline_rounded,
                color: AppColors.violetPrimary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  t(context, 'chart.forecast_button'),
                  style: AppTextStyles.bodyLg(
                    color: AppColors.violetPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _analysisButton(BuildContext context) {
    return Material(
      color: AppColors.violetPrimary,
      borderRadius: AppRadius.mdBr,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                NatalReportPage(chartData: chartData, userName: userName),
          ),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          alignment: AlignmentDirectional.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  t(context, 'chart.analysis_button'),
                  style: AppTextStyles.ctaPrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
