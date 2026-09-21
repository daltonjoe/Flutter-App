// lib/screens/planet_report_page.dart
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
import '../widgets/analysis/floating_analysis_icon.dart';
import '../widgets/animations/zodiac_orbital_animation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlanetReportPage extends StatefulWidget {
  final String planetName;
  final String planetNameTR;
  final NatalChartResponse chartData;

  const PlanetReportPage({
    super.key,
    required this.planetName,
    required this.planetNameTR,
    required this.chartData,
  });

  @override
  State<PlanetReportPage> createState() => _PlanetReportPageState();
}

class _PlanetReportPageState extends State<PlanetReportPage> {
 List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;
  bool _isFallback = false;
  String? _report;
  String? _error;

  static const Map<String, Map<String, dynamic>> _meta = {
    'Sun': {'emoji': '☀️', 'color': Color(0xFFFFB347)},
    'Moon': {'emoji': '🌙', 'color': Color(0xFFADD8E6)},
    'Mercury': {'emoji': '☿', 'color': Color(0xFF98FF98)},
    'Venus': {'emoji': '♀', 'color': Color(0xFFFF9EBC)},
    'Mars': {'emoji': '♂', 'color': Color(0xFFFF6B6B)},
    'Jupiter': {'emoji': '♃', 'color': Color(0xFFFFD700)},
    'Saturn': {'emoji': '♄', 'color': Color(0xFFE8C49A)},
    'Uranus': {'emoji': '♅', 'color': Color(0xFF7FFFD4)},
    'Neptune': {'emoji': '♆', 'color': Color(0xFF87CEEB)},
    'Pluto': {'emoji': '♇', 'color': Color(0xFFDDA0DD)},
  };

  static const Map<String, String> _signKeys = {
    'Koç': 'signs.aries',
    'Boğa': 'signs.taurus',
    'İkizler': 'signs.gemini',
    'Yengeç': 'signs.cancer',
    'Aslan': 'signs.leo',
    'Başak': 'signs.virgo',
    'Terazi': 'signs.libra',
    'Akrep': 'signs.scorpio',
    'Yay': 'signs.sagittarius',
    'Oğlak': 'signs.capricorn',
    'Kova': 'signs.aquarius',
    'Balık': 'signs.pisces',
  };

  @override
  void initState() {
    super.initState();
    List<Map<String, dynamic>> _sections = [];

    Future<void> _fetch() async {
      setState(() { _isLoading = true; _error = null; });

      final locale = Provider.of<LanguageProvider>(context, listen: false)
          .locale.languageCode;
      final pd = widget.chartData.planets?[widget.planetName];
      if (pd == null) { setState(() => _isLoading = false); return; }

      final signCode = _signKeys[pd.sign]?.split('.').last ?? '';

      try {
        final rows = await Supabase.instance.client
            .from('placement_content')
            .select('title, content, keywords, strengths, challenges, '
                'content_themes!inner(code), celestial_bodies!inner(code), '
                'zodiac_signs!inner(code), astrological_houses!inner(house_number)')
            .eq('celestial_bodies.code', widget.planetName.toLowerCase())
            .eq('zodiac_signs.code', signCode)
            .eq('astrological_houses.house_number', pd.house)
            .eq('locale', locale)
            .eq('is_active', true);

        setState(() {
          _sections = List<Map<String, dynamic>>.from(rows);
          _isLoading = false;
        });
      } catch (_) {
        setState(() {
          _error = t(context, 'planet_report.unexpected_error');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; _isFallback = false; });

    final locale = Provider.of<LanguageProvider>(context, listen: false)
        .locale.languageCode;
    final pd = widget.chartData.planets?[widget.planetName];

    try {
      final signCode = _signKeys[pd?.sign]?.split('.').last ?? '';
      final rows = await Supabase.instance.client
          .from('placement_content')
          .select('title, content, strengths, challenges, '
              'celestial_bodies!inner(code), zodiac_signs!inner(code), '
              'astrological_houses!inner(house_number)')
          .eq('celestial_bodies.code', widget.planetName.toLowerCase())
          .eq('zodiac_signs.code', signCode)
          .eq('astrological_houses.house_number', pd?.house ?? -1)
          .eq('locale', locale)
          .eq('is_active', true);

      if (rows.isEmpty) {
        // Fallback: Supabase'de içerik yoksa eski AI akışına düş
        final r = await AstroService.generatePlanetReport(
          planetName: widget.planetName,
          chartData: widget.chartData.toChartPayload(),
          locale: locale,
        );
        setState(() { _report = r; _isFallback = true; _isLoading = false; });
      } else {
        setState(() {
          _sections = List<Map<String, dynamic>>.from(rows);
          _isLoading = false;
        });
      }
    } on AstroServiceException catch (e) {
      setState(() { _error = e.message; _isLoading = false; });
    } catch (_) {
      setState(() {
        _error = t(context, 'planet_report.unexpected_error');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta[widget.planetName];
    final color = (m?['color'] as Color?) ?? AppTheme.violet;
    final emoji = m?['emoji'] as String? ?? '✦';
    final pd = widget.chartData.planets?[widget.planetName];

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          t(
            context,
            'planet_report.title',
            args: {'name': widget.planetNameTR},
          ),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          if (!_isLoading && _error == null)
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
      body: _isLoading
          ? CosmicLoader(message: t(context, 'planet_report.loading'))
          : _error != null
          ? _buildError()
          : _buildContent(color, emoji, pd),
    );
  }

  Widget _buildContent(Color color, String emoji, PlanetData? pd) {
    // ── FIX: Translate sign name from backend (always Turkish) ───────
    final translatedSign = pd != null ? _translateSign(pd.sign) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Background Animation ──────────────────────────────
          Center(
            child: Opacity(
              opacity: 0.3,
              child: ZodiacOrbitalAnimation(
                size: MediaQuery.of(context).size.width * 0.5,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Planet header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                FloatingAnalysisIcon(icon: emoji, size: 64, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.planetNameTR,
                        style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (pd != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          // ── FIX: use translatedSign ───────────────
                          '$translatedSign  ·  ${t(context, 'planet_report.house', args: {'number': pd.house.toString()})}'
                          '${pd.retrograde ? '  ·  ${t(context, 'planet_report.retrograde')}' : ''}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${pd.degreeInSign.toStringAsFixed(2)}° $translatedSign',
                          style: TextStyle(
                            color: color.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Report
                    // Report
          if (_isFallback)
            ..._renderModernReportText(_report!, color)
          else
            ..._renderModernReport(color),
        ],
      ),
    );
  }

  // Supabase'den gelen structured içerik
  List<Widget> _renderModernReport(Color accent) {
    return _sections.map((row) {
      final s = List<String>.from(row['strengths'] ?? []);
      final c = List<String>.from(row['challenges'] ?? []);
      return AnalysisSectionCard(
        title: row['title'] ?? '',
        content: row['content'] ?? '',
        bulletPoints: [...s, ...c],
        color: accent,
        icon: _getIconForTitle(row['title'] ?? ''),
      );
    }).toList();
  }

  // AI fallback (eski davranış)
  List<Widget> _renderModernReportText(String report, Color accent) {
    final sections = TextParser.parse(report);
    if (sections.isEmpty) return [];
    return sections.map((section) {
      return AnalysisSectionCard(
        title: section.title,
        content: section.content,
        bulletPoints: section.bulletPoints,
        color: accent,
        icon: _getIconForTitle(section.title),
      );
    }).toList();
  }

  /// Translates a backend sign name (always Turkish) to active locale.
  String _translateSign(String sign) {
    final key = _signKeys[sign];
    if (key == null) return sign;
    return t(context, key);
  }

  String? _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('ev') || t.contains('house')) return '🏠';
    if (t.contains('burç') || t.contains('sign')) return '✨';
    if (t.contains('açı') || t.contains('aspect')) return '📐';
    return '✦';
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 44,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.error, fontSize: 14),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _fetch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                gradient: AppTheme.violetGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.violetGlow,
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
