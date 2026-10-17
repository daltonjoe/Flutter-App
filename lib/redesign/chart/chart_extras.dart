// Harita ekstraları (Faz 7b): harita noktaları, element dağılımı,

// retrogezegenler ve Analysis/Forecast butonları.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../core/theme/app_dimensions.dart';

import '../../core/theme/app_typography.dart';

import '../../i18n/app_localizations.dart';

import '../../models/natal_chart_response.dart';

import '../../presentation/widgets/components/cosmic_card.dart';

import '../../presentation/widgets/components/cosmic_cta_button.dart';

import '../../presentation/widgets/components/cosmic_outline_button.dart';

import '../../presentation/widgets/components/planet_glyph_icon.dart';

import '../../screens/forecast_selection_page.dart';

import '../../screens/natal_report_page.dart';

import '../data/planet_card_view_model.dart';

import 'chart_balance_section.dart';

class ChartExtras extends StatelessWidget {
  const ChartExtras({
    super.key,

    required this.chartData,

    required this.userName,
  });

  final NatalChartResponse chartData;

  final String userName;

  static const Map<String, String> _planetKeys = <String, String>{
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

  @override
  Widget build(BuildContext context) {
    final summary = chartData.summary;

    final angles = chartData.angles;

    final birthTimeKnown = chartData.input?.birthTimeKnown == true;

    final retrogrades = summary?.retrogradePlanets ?? const <String>[];

    final sections = <Widget>[
      ?_pointsSection(context, angles, birthTimeKnown),
      ChartBalanceSection(chartData: chartData),
      _retroSection(context, retrogrades),
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

    style: AppTextStyles.h3(color: AppColors.starlight),

    maxLines: 1,

    overflow: TextOverflow.ellipsis,
  );

  // ── 1. Harita noktaları (ASC / MC) ─────────────────────────────────

  Widget? _pointsSection(
    BuildContext context,

    ChartAngles? angles,

    bool birthTimeKnown,
  ) {
    final Widget body;

    if (birthTimeKnown && angles != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _angleRow(context, 'ASC', angles.ascSign, angles.ascDegree),

          const SizedBox(height: AppSpacing.xs),

          _angleRow(context, 'MC', angles.mcSign, angles.mcDegree),
        ],
      );
    } else if (!birthTimeKnown) {
      body = Row(
        children: [
          const Icon(
            Icons.schedule_rounded,

            size: 16,

            color: AppColors.statusChallenging,
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Text(
              t(context, 'chart.time_unknown'),

              style: AppTextStyles.bodySm(color: AppColors.mist),

              maxLines: 1,

              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      // Doğum saati biliniyor ama açı verisi yok -> bölümü gizle.

      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _sectionTitle(context, 'rd.chart.points'),

        const SizedBox(height: AppSpacing.sm),

        CosmicCard(blur: false, compact: true, child: body),
      ],
    );
  }

  Widget _angleRow(
    BuildContext context,

    String label,

    String sign,

    double degree,
  ) => Text(
    '$label · $sign ${PlanetCardViewModel.formatDegree(degree)}',

    style: AppTextStyles.bodySm(color: AppColors.starlight),

    maxLines: 1,

    overflow: TextOverflow.ellipsis,
  );

  // ── 3. Retrogezegenler ─────────────────────────────────────────────

  Widget _retroSection(BuildContext context, List<String> retrogrades) {
    final title = t(context, 'chart.retrograde_planets');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle(context, 'chart.retrograde_planets')),

            Semantics(
              button: true,

              label: title,

              child: IconButton(
                onPressed: () => _showRxInfo(context),

                iconSize: 18,

                color: AppColors.mist,

                padding: EdgeInsets.zero,

                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),

                icon: const Icon(Icons.info_outline_rounded),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        if (retrogrades.isEmpty)
          Text(
            t(context, 'rd.chart.no_retrograde'),

            style: AppTextStyles.bodyMd(),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,

            runSpacing: AppSpacing.sm,

            children: [for (final key in retrogrades) _retroChip(context, key)],
          ),
      ],
    );
  }

  void _showRxInfo(BuildContext context) {
    final title = t(context, 'chart.retrograde_planets');

    final body = t(context, 'rd.chart.rx_info');

    showModalBottomSheet<void>(
      context: context,

      backgroundColor: AppColors.navyRaised,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),

      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(title, style: AppTextStyles.h3(color: AppColors.starlight)),

              const SizedBox(height: AppSpacing.sm),

              Text(body, style: AppTextStyles.bodyMd()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _retroChip(BuildContext context, String key) {
    final nameKey = _planetKeys[key];

    final name = nameKey == null ? key : t(context, nameKey);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,

        vertical: AppSpacing.xs,
      ),

      decoration: BoxDecoration(
        color: AppColors.navyRaised,

        borderRadius: AppRadius.pillBr,

        border: Border.all(
          color: AppColors.statusChallenging.withValues(alpha: 0.4),
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          PlanetGlyphIcon(
            name: key.toLowerCase(),
            size: 16,
            color: AppColors.gold,
            decorative: true,
          ),

          const SizedBox(width: AppSpacing.xs),

          Text(
            '$name Rx',

            style: AppTextStyles.miniTag(color: AppColors.statusChallenging),

            maxLines: 1,

            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── 4. CTA butonları ───────────────────────────────────────────────

  Widget _buttons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        CosmicCtaButton(
          label: t(context, 'chart.analysis_button'),

          icon: const Icon(
            Icons.auto_awesome_rounded,

            size: 18,

            color: AppColors.onGold,
          ),

          onTap: () => Navigator.push(
            context,

            MaterialPageRoute(
              builder: (_) =>
                  NatalReportPage(chartData: chartData, userName: userName),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        CosmicOutlineButton(
          label: t(context, 'chart.forecast_button'),

          icon: const Icon(
            Icons.timeline_rounded,

            size: 18,

            color: AppColors.gold,
          ),

          onTap: () => Navigator.push(
            context,

            MaterialPageRoute(
              builder: (_) => ForecastSelectionPage(chartData: chartData),
            ),
          ),
        ),
      ],
    );
  }
}
