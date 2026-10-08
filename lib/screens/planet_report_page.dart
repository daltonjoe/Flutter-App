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
import '../presentation/widgets/components/analysis_section_card.dart';
import '../widgets/analysis/floating_analysis_icon.dart';
import '../widgets/animations/zodiac_orbital_animation.dart';
import '../core/content_theme_colors.dart';
import '../core/reference_ids.dart';
import '../services/reference_names_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/ask_context_provider.dart';
import '../widgets/ask_add.dart';


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
  String? _loc;

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

  // signIndex (0-11) -> zodiac_signs.code. Sıra DB'de doğrulandı (1-12).
  static const List<String> _signCodes = [
    'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
    'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces',
  ];

  static String _signCodeOf(PlanetData? pd) {
    final i = pd?.signIndex;
    if (i == null || i < 0 || i >= _signCodes.length) return '';
    return _signCodes[i];
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = context.watch<LanguageProvider>().locale.languageCode;
    if (_loc != null && _loc != loc) _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; _isFallback = false; });

    final locale = Provider.of<LanguageProvider>(context, listen: false)
        .locale.languageCode;
    _loc = locale;
    final pd = widget.chartData.planets?[widget.planetName];
    final birthTimeKnown = widget.chartData.input?.birthTimeKnown == true;
    final house = pd?.house ?? 0;

    if (widget.planetName == 'Moon' && !birthTimeKnown) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final signCode = _signCodeOf(pd);
      var query = Supabase.instance.client
          .from('placement_content')
          .select('title, content, strengths, challenges, '
              'celestial_bodies!inner(code), zodiac_signs!inner(code), '
              'astrological_houses!inner(house_number), '
              'content_themes(code, sort_order)')
          .eq('celestial_bodies.code', widget.planetName)
          .eq('zodiac_signs.code', signCode);
      if (birthTimeKnown && house > 0) {
        query = query.eq('astrological_houses.house_number', house);
      }
      final rows = await query
          .eq('locale', locale)
          .eq('is_active', true);
        if (!mounted) return;
        if (rows.isEmpty) {
        // Fallback: Supabase'de içerik yoksa eski AI akışına düş
        final r = await AstroService.generatePlanetReport(
          planetName: widget.planetName,
          chartData: widget.chartData.toChartPayload(),
          locale: locale,
        );
          if (!mounted) return;
          setState(() { _report = r; _isFallback = true; _isLoading = false; });
      } else {
        setState(() {
          _sections = List<Map<String, dynamic>>.from(rows);
          _isLoading = false;
        });
      }
 } on AstroServiceException catch (e) {
        if (!mounted) return;
        setState(() { _error = e.message; _isLoading = false; });
    } catch (e) {
        debugPrint('planet_report fetch error: $e');
        if (!mounted) return;
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
    final names = context.watch<ReferenceNamesService>();
    final pid = RefIds.planets[widget.planetName];
    final planetLabel =
        pid != null ? names.planet(pid) : widget.planetNameTR;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          t(
            context,
            'planet_report.title',
              args: {'name': planetLabel},
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
    final names = context.watch<ReferenceNamesService>();
    final pid = RefIds.planets[widget.planetName];
    final planetLabel =
        pid != null ? names.planet(pid) : widget.planetNameTR;
    // ── FIX: Translate sign name from backend (always Turkish) ───────
   final translatedSign =
        pd != null ? names.sign(RefIds.signId(pd.signIndex)) : '';

    final known = widget.chartData.input?.birthTimeKnown == true;
    final askQ = (pd == null || pid == null)
        ? null
        : t(context, known && pd.house > 0
                ? 'ask.about.placement'
                : 'ask.about.nohouse',
            args: {
              'planet': planetLabel,
              'sign': translatedSign,
              'house': known && pd.house > 0 ? names.house(pd.house) : '',
            });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (askQ != null)
            ValueListenableBuilder<bool>(
              valueListenable: askEnabled,
              builder: (_, on, _) => !on
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FilledButton.icon(
                        onPressed: () => askAbout(askQ),
                        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                        label: Text(t(context, 'ask.about.button')),
                      ),
                    ),
            ),
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
                       planetLabel,
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
                          '$translatedSign'
                          '${pd.house > 0 ? '  ·  ${t(context, 'planet_report.house', args: {'number': pd.house.toString()})}' : ''}'
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
  if (pd != null && pd.house <= 0)
            Text(
              t(context, 'planet_report.time_unknown'),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            )
          else if (_isFallback)
            ..._renderModernReportText(_report!, color)
          else
            ..._renderModernReport(color),
        ],
      ),
    );
  }

  // Supabase'den gelen structured içerik — her tema kendi rengiyle
  List<Widget> _renderModernReport(Color accent) {
    final sorted = List<Map<String, dynamic>>.from(_sections)
      ..sort((a, b) {
        final ao = (a['content_themes']?['sort_order'] as num?) ?? 0;
        final bo = (b['content_themes']?['sort_order'] as num?) ?? 0;
        return ao.compareTo(bo);
      });
    return sorted.map((row) {
      final s = List<String>.from(row['strengths'] ?? []);
      final c = List<String>.from(row['challenges'] ?? []);
      final themeCode = row['content_themes']?['code'] as String? ?? '';
      final color = themeCode.isNotEmpty ? themeColorFor(themeCode) : accent;
      return AnalysisSectionCard(
        title: row['title'] ?? '',
        content: row['content'] ?? '',
        strengths: s,
        challenges: c,
        strengthsLabel: t(context, 'placement.strengths'),
        challengesLabel: t(context, 'placement.challenges'),
        color: color,
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
