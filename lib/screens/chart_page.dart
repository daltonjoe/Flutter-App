// lib/screens/chart_page.dart
// Moonly-inspired redesign

import 'package:flutter_application/models/zodiac_sign.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/natal_chart_response.dart';
import '../widgets/animations/zodiac_orbital_animation.dart';
import '../theme/app_theme.dart';
import '../i18n/app_localizations.dart';
import 'natal_report_page.dart';
import 'planet_report_page.dart';
import 'forecast_selection_page.dart';
import 'placement_content_page.dart';

class ChartPage extends StatefulWidget {
  final NatalChartResponse chartData;
  final String userName;

  const ChartPage({super.key, required this.chartData, required this.userName});

  @override
  State<ChartPage> createState() => _ChartPageState();
}


class _ChartPageState extends State<ChartPage> with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _orbitCtrl;
  late List<Animation<double>> _cardAnims;

  static const Map<String, Map<String, dynamic>> _planetMeta = {
    'Sun': {'emoji': '☀️', 'key': 'chart.sun', 'color': Color(0xFFFFB347)},
    'Moon': {'emoji': '🌙', 'key': 'chart.moon', 'color': Color(0xFFADD8E6)},
    'Mercury': {
      'emoji': '☿',
      'key': 'chart.mercury',
      'color': Color(0xFF98FF98),
    },
    'Venus': {'emoji': '♀', 'key': 'chart.venus', 'color': Color(0xFFFF9EBC)},
    'Mars': {'emoji': '♂', 'key': 'chart.mars', 'color': Color(0xFFFF6B6B)},
    'Jupiter': {
      'emoji': '♃',
      'key': 'chart.jupiter',
      'color': Color(0xFFFFD700),
    },
    'Saturn': {'emoji': '♄', 'key': 'chart.saturn', 'color': Color(0xFFE8C49A)},
    'Uranus': {'emoji': '♅', 'key': 'chart.uranus', 'color': Color(0xFF7FFFD4)},
    'Neptune': {
      'emoji': '♆',
      'key': 'chart.neptune',
      'color': Color(0xFF87CEEB),
    },
    'Pluto': {'emoji': '♇', 'key': 'chart.pluto', 'color': Color(0xFFDDA0DD)},
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

  static const Map<String, String> _signSymbols = {
    'Koç': '♈',
    'Boğa': '♉',
    'İkizler': '♊',
    'Yengeç': '♋',
    'Aslan': '♌',
    'Başak': '♍',
    'Terazi': '♎',
    'Akrep': '♏',
    'Yay': '♐',
    'Oğlak': '♑',
    'Kova': '♒',
    'Balık': '♓',
  };

  static const Map<String, String> _elementKeys = {
    'Ateş': 'elements.fire',
    'Toprak': 'elements.earth',
    'Hava': 'elements.air',
    'Su': 'elements.water',
  };

  static const Map<String, Color> _elementColors = {
    'Ateş': Color(0xFFFF6B6B),
    'Toprak': Color(0xFF98C379),
    'Hava': Color(0xFF61AFEF),
    'Su': Color(0xFF56B6C2),
  };

  @override
  void initState() {
    super.initState();
    final count = (widget.chartData.planets?.length ?? 0).clamp(1, 20);

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + count * 50),
    )..forward();

    _cardAnims = List.generate(count, (i) {
      final start = (i * 0.06).clamp(0.0, 0.9);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.chartData.summary;
    final planets = widget.chartData.planets ?? {};
    final angles = widget.chartData.angles;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          _buildBgOrbs(),
          CustomScrollView(
            slivers: [
              // ── Hero header ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppTheme.bgDeep,
                iconTheme: const IconThemeData(color: AppTheme.textPrimary),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHero(summary, angles),
                ),
                title: Text(
                  t(context, 'chart.title', args: {'name': widget.userName}),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Üçlü rozet ─────────────────────────
                    _buildTrioBadges(summary),
                    const SizedBox(height: 28),

                    // ── Gezegen başlığı ────────────────────
                    _sectionHeader(
                      t(context, 'chart.planet_positions'),
                      t(
                        context,
                        'chart.planets_count',
                        args: {'count': planets.length.toString()},
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Gezegen kartları ───────────────────
                    ...planets.entries.toList().asMap().entries.map((e) {
                      final i = e.key;
                      final key = e.value.key;
                      final data = e.value.value;
                      final anim = i < _cardAnims.length
                          ? _cardAnims[i]
                          : const AlwaysStoppedAnimation(1.0);
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(anim),
                          child: _buildPlanetCard(key, data),
                        ),
                      );
                    }),

                    // ── Element dağılımı ───────────────────
                    if (summary?.elementDistribution.isNotEmpty ?? false) ...[
                      const SizedBox(height: 24),
                      _sectionHeader(
                        t(context, 'chart.element_distribution'),
                        '',
                      ),
                      const SizedBox(height: 12),
                      _buildElementChart(summary!.elementDistribution),
                    ],

                    // ── Retrograde ─────────────────────────
                    if (summary?.retrogradePlanets.isNotEmpty ?? false) ...[
                      const SizedBox(height: 24),
                      _sectionHeader(
                        t(context, 'chart.retrograde_planets'),
                        '',
                      ),
                      const SizedBox(height: 10),
                      _buildRetrogrades(summary!.retrogradePlanets),
                    ],

                    const SizedBox(height: 32),

                    // ── CTA butonlar ───────────────────────
                    _outlineBtn(
                      label: t(context, 'placement.button'),
                      icon: Icons.stars_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlacementContentPage(chartData: widget.chartData),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildForecastBtn(),
                    const SizedBox(height: 12),
                    _buildAnalysisBtn(),
                    const SizedBox(height: 48),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Background orbs ───────────────────────────────────────────────
  Widget _buildBgOrbs() {
    return AnimatedBuilder(
      animation: _orbitCtrl,
      builder: (_, _) {
        final t = _orbitCtrl.value;
        return Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.violet.withOpacity(
                        0.08 + 0.04 * math.sin(t * 2 * math.pi),
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.indigo.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────
  Widget _buildHero(ChartSummary? summary, ChartAngles? angles) {
    final ascSymbol = _signSymbols[summary?.ascendantSign] ?? '✦';
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1240), AppTheme.bgDeep],
        ),
      ),
      child: Stack(
        children: [
          // ── Background Orbital Animation ──────────────────────────
          Positioned(
            top: -20,
            right: -60,
            child: Opacity(
              opacity: 0.4,
              child: ZodiacOrbitalAnimation(size: screenWidth * 0.6),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 88, 24, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Büyük burç sembolü
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3D2B7A), AppTheme.violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x808B5CF6), blurRadius: 20),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      SoulBoundAssets.getZodiac(summary?.ascendantSign ?? ''),
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${t(context, _signKeys[summary?.sunSign] ?? (summary?.sunSign ?? ''))} '
                        '${t(context, 'chart.sun_label')} · '
                        '${t(context, _signKeys[summary?.ascendantSign] ?? (summary?.ascendantSign ?? ''))} '
                        '${t(context, 'chart.rising_label')}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (angles != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _miniTag(
                              'ASC',
                              '${angles.ascSign} ${angles.ascDegree.toStringAsFixed(0)}°',
                            ),
                            const SizedBox(width: 8),
                            _miniTag(
                              'MC',
                              '${angles.mcSign} ${angles.mcDegree.toStringAsFixed(0)}°',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Color(0x268B5CF6),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Color(0x4D8B5CF6)),
    ),
    child: Text(
      '$label · $value',
      style: const TextStyle(
        color: AppTheme.violet,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ── Üçlü rozet ────────────────────────────────────────────────────
  Widget _buildTrioBadges(ChartSummary? summary) {
    return Row(
      children: [
        _trioItem(t(context, 'chart.sun'), summary?.sunSign, '☀️'),
        const SizedBox(width: 8),
        _trioItem(t(context, 'chart.moon'), summary?.moonSign, '🌙'),
        const SizedBox(width: 8),
        _trioItem(t(context, 'chart.ascendant'), summary?.ascendantSign, '⬆️'),
      ],
    );
  }

  Widget _trioItem(String label, String? sign, String icon) {
    final signKey = _signKeys[sign] ?? sign ?? '';
    final translatedSign = sign != null ? t(context, signKey) : '-';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: cosmicCard(),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              translatedSign,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Planet card ───────────────────────────────────────────────────
  Widget _buildPlanetCard(String key, PlanetData data) {
    final meta = _planetMeta[key];
    final color = (meta?['color'] as Color?) ?? AppTheme.violet;
    final emoji = meta?['emoji'] as String? ?? '✦';
    final planetName = meta != null ? t(context, meta['key']) : key;
    final signKey = _signKeys[data.sign] ?? data.sign;
    final translatedSign = t(context, signKey);
    final symbol = _signSymbols[data.sign] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlanetReportPage(
                planetName: key,
                planetNameTR: planetName,
                chartData: widget.chartData,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: cosmicCard(border: color.withOpacity(0.22)),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + sign
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            planetName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (data.retrograde) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x26EC4899),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '℞',
                                style: TextStyle(
                                  color: AppTheme.rose,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$symbol $translatedSign  ·  ${data.degreeInSign.toStringAsFixed(2)}°',
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Zodiac icon (house'un solunda, aynı boyutta)
                Image.asset(
                  SoulBoundAssets.getZodiac(data.sign),
                  width: 42,
                  height: 42,
                ),
                const SizedBox(width: 8),

                // House badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${data.house}',
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'ev',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final isRtl =
                        Directionality.of(context) == TextDirection.rtl;
                    return Icon(
                      isRtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: AppTheme.textMuted,
                      size: 16,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Element chart ─────────────────────────────────────────────────
  Widget _buildElementChart(Map<String, int> elements) {
    final total = elements.values.fold(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cosmicCard(),
      child: Column(
        children: elements.entries.map((e) {
          final pct = total > 0 ? e.value / total : 0.0;
          final color = _elementColors[e.key] ?? AppTheme.violet;
          final elementKey = _elementKeys[e.key] ?? e.key;
          final translatedElement = t(context, elementKey);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    translatedElement,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${e.value}',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Retrograde ────────────────────────────────────────────────────
  Widget _buildRetrogrades(List<String> list) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: list.map((p) {
        final meta = _planetMeta[p];
        final emoji = meta?['emoji'] as String? ?? '✦';
        final planetName = meta != null ? t(context, meta['key']) : p;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x14EC4899),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x4DEC4899)),
          ),
          child: Text(
            '$emoji $planetName ℞',
            style: const TextStyle(
              color: AppTheme.rose,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── CTA butonlar ──────────────────────────────────────────────────
  Widget _buildForecastBtn() {
    return _outlineBtn(
      label: t(context, 'chart.forecast_button'),
      icon: Icons.timeline_rounded,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ForecastSelectionPage(chartData: widget.chartData),
        ),
      ),
    );
  }

  Widget _buildAnalysisBtn() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NatalReportPage(
            chartData: widget.chartData,
            userName: widget.userName,
          ),
        ),
      ),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          gradient: AppTheme.violetGradient,
          boxShadow: AppTheme.violetGlow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              t(context, 'chart.analysis_button'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          color: AppTheme.bgCard,
          border: Border.all(color: Color(0x598B5CF6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.violet, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.violet,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
      ],
    );
  }
}
