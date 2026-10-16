// Redesign Harita sayfası iskeleti (Faz 4).
import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/cosmic_background.dart';
import '../../screens/placement_content_page.dart';
import 'chart_category_bar.dart';
import 'planet_carousel.dart';

class RedesignChartPage extends StatelessWidget {
  const RedesignChartPage({
    super.key,
    required this.chartData,
    required this.userName,
  });

  final NatalChartResponse chartData;

  final String userName;

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.screenH,
                  end: AppSpacing.screenH,
                  top: AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTextStyles.h1(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        t(context, 'rd.chart.planet_positions'),
                        style: AppTextStyles.bodyMd(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: ChartCategoryBar(
                  birthTimeKnown: chartData.input?.birthTimeKnown == true,
                  onOpenPlacement: (k) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlacementContentPage(
                        chartData: chartData,
                        initialKey: k,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(child: PlanetCarousel(chartData: chartData)),
              SliverToBoxAdapter(
                child: SizedBox(height: AppSizes.bottomNavInset(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
