// lib/screens/forecast_selection_page.dart
// Moonly-inspired redesign

import 'package:flutter/material.dart';
import '../models/natal_chart_response.dart';
import '../theme/app_theme.dart';
import 'forecast_result_page.dart';
import '../i18n/app_localizations.dart';

class ForecastSelectionPage extends StatelessWidget {
  final NatalChartResponse chartData;

  const ForecastSelectionPage({super.key, required this.chartData});

  static const List<Map<String, dynamic>> _options = [
    {
      'type': 'daily',
      'key': 'forecast.daily',
      'subtitle_key': 'forecast.daily_subtitle',
      'emoji': '🌅',
      'colors': [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    },
    {
      'type': 'weekly',
      'key': 'forecast.weekly',
      'subtitle_key': 'forecast.weekly_subtitle',
      'emoji': '🗓️',
      'colors': [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    },
    {
      'type': 'monthly',
      'key': 'forecast.monthly',
      'subtitle_key': 'forecast.monthly_subtitle',
      'emoji': '🌙',
      'colors': [Color(0xFF0284C7), Color(0xFF38BDF8)],
    },
    {
      'type': 'yearly',
      'key': 'forecast.yearly',
      'subtitle_key': 'forecast.yearly_subtitle',
      'emoji': '✨',
      'colors': [Color(0xFFD97706), Color(0xFFFBBF24)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          t(context, 'forecast.title'),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kart — kullanıcı özeti
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E1F6B), Color(0xFF1A1240)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: Color(0x4D8B5CF6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.violetGradient,
                    ),
                    child: const Center(
                      child: Text('☽', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(context, 'forecast.custom_forecast'),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t(context, 'forecast.select_period'),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              t(context, 'forecast.which_period'),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t(context, 'forecast.personalized_notice'),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _buildCard(ctx, _options[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> opt) {
    final colors = (opt['colors'] as List).cast<Color>();
    final label = t(context, opt['key']);
    final subtitle = t(context, opt['subtitle_key']);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ForecastResultPage(
            analysisType: opt['type'],
            periodLabel: label,
            chartData: chartData,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: colors[0].withOpacity(0.25), width: 1),
        ),
        child: Row(
          children: [
            // Gradient icon box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(opt['emoji'], style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Builder(
              builder: (context) {
                final isRtl = Directionality.of(context) == TextDirection.rtl;
                return Icon(
                  isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                  size: 24,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
