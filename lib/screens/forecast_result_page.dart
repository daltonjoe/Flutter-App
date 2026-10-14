// lib/screens/forecast_result_page.dart
// Moonly-inspired redesign

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/natal_chart_response.dart';
import '../providers/language_provider.dart';
import '../services/astro_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cosmic_loader.dart';
import '../i18n/app_localizations.dart';
import '../core/utils/text_parser.dart';
import '../widgets/analysis/analysis_section_card.dart';
import '../widgets/animations/zodiac_orbital_animation.dart';

class ForecastResultPage extends StatefulWidget {
  final String analysisType;
  final String periodLabel;
  final NatalChartResponse chartData;

  const ForecastResultPage({
    super.key,
    required this.analysisType,
    required this.periodLabel,
    required this.chartData,
  });

  @override
  State<ForecastResultPage> createState() => _ForecastResultPageState();
}

class _ForecastResultPageState extends State<ForecastResultPage> {
  String? _report;
  bool _isLoading = true;
  String? _error;

  static const Map<String, String> _emojis = {
    'daily': '🌅',
    'weekly': '🗓️',
    'monthly': '🌙',
    'yearly': '✨',
  };

  static const Map<String, List<Color>> _colors = {
    'daily': [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    'weekly': [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    'monthly': [Color(0xFF0284C7), Color(0xFF38BDF8)],
    'yearly': [Color(0xFFD97706), Color(0xFFFBBF24)],
  };

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // ── FIX: Read locale from LanguageProvider and pass to API ────
      final locale = Provider.of<LanguageProvider>(
        context,
        listen: false,
      ).locale.languageCode;

      final result = await AstroService.generateForecast(
        analysisType: widget.analysisType,
        chartData: widget.chartData.toChartPayload(),
        locale: locale, // ← FIX: was missing, defaulted to 'tr'
      );
      setState(() {
        _report = result['report'];
        _isLoading = false;
      });
    } on AstroServiceException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = t(context, 'forecast.unexpected_error');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _emojis[widget.analysisType] ?? '✦';
    final colors =
        _colors[widget.analysisType] ?? [AppTheme.violetSoft, AppTheme.violet];

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          '$emoji ${t(context, 'forecast.result_title', args: {'period': widget.periodLabel})}',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              onPressed: _fetch,
            ),
        ],
      ),
      body: _buildBody(emoji, colors),
    );
  }

  Widget _buildBody(String emoji, List<Color> colors) {
    if (_isLoading) {
      return CosmicLoader(message: t(context, 'forecast.loading'));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1AF87171),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.error,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.error, fontSize: 14),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _fetch,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    t(context, 'natal_report.retry'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dynamic Background Animation ──────────────────────────
          Center(
            child: ZodiacOrbitalAnimation(
              size: MediaQuery.of(context).size.width * 0.6,
            ),
          ),

          const SizedBox(height: 12),

          // Başlık kartı
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors[0].withOpacity(0.2),
                  colors[1].withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: colors[0].withOpacity(0.3)),
            ),
            child: Row(
              children: [
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
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // ── FIX: localized header label ──────────────
                        t(
                          context,
                          'forecast.analysis_header',
                          args: {'period': widget.periodLabel},
                        ),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.chartData.location?.cityResolved ?? '',
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

          const SizedBox(height: 24),

          // Rapor içeriği
          ..._renderModernReport(_report!, colors[0]),
        ],
      ),
    );
  }

  List<Widget> _renderModernReport(String report, Color accentColor) {
    final sections = TextParser.parse(report);
    if (sections.isEmpty) return [];

    return sections.map((section) {
      return AnalysisSectionCard(
        title: section.title,
        content: section.content,
        bulletPoints: section.bulletPoints,
        color: accentColor,
        icon: _getIconForTitle(section.title),
      );
    }).toList();
  }

  String? _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('aşk') || t.contains('love')) return '❤️';
    if (t.contains('kariyer') || t.contains('career')) return '💼';
    if (t.contains('para') || t.contains('money')) return '💰';
    if (t.contains('sağlık') || t.contains('health')) return '🏥';
    return '✨';
  }
}
