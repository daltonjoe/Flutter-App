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

class NatalReportPage extends StatefulWidget {
  final NatalChartResponse chartData;
  final String userName;

  const NatalReportPage({
    super.key,
    required this.chartData,
    required this.userName,
  });

  @override
  State<NatalReportPage> createState() => _NatalReportPageState();
}

class _NatalReportPageState extends State<NatalReportPage> {
  String? _report;
  bool _isLoading = true;
  String? _errorMsg;

  // ── Sign translation map (backend returns Turkish sign names) ──────
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

  // ── Keyword to Icon mapping ──────────────────────────────────────
  static const Map<String, String> _keywordIcons = {
    'Güneş': '☀️',
    'Sun': '☀️',
    'Ay': '🌙',
    'Moon': '🌙',
    'Merkür': '☿',
    'Mercury': '☿',
    'Venüs': '♀',
    'Venus': '☿',
    'Mars': '♂',
    'Jüpiter': '♃',
    'Jupiter': '♃',
    'Satürn': '♄',
    'Saturn': '♄',
    'Uranüs': '♅',
    'Uranus': '♅',
    'Neptün': '♆',
    'Neptune': '♆',
    'Plüton': '♇',
    'Pluto': '♇',
    'Yükselen': '⬆️',
    'Rising': '⬆️',
    'Ascendant': '⬆️',
    'Aşk': '❤️',
    'Love': '❤️',
    'Kariyer': '💼',
    'Career': '💼',
    'Para': '💰',
    'Money': '💰',
    'Sağlık': '🏥',
    'Health': '🏥',
    'Ruhsal': '🧘',
    'Spiritual': '🧘',
  };

  String? _getIconForTitle(String title) {
    for (var entry in _keywordIcons.entries) {
      if (title.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return '✨'; // Default
  }

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final location = widget.chartData.location;
      final input = widget.chartData.input;
      if (location == null || input == null) {
        setState(() {
          _errorMsg = t(context, 'natal_report.unexpected_error');
          _isLoading = false;
        });
        return;
      }

      // ── FIX: Read locale from LanguageProvider and pass to API ────
      final locale = Provider.of<LanguageProvider>(
        context,
        listen: false,
      ).locale.languageCode;

      final report = await AstroService.generateAstroReport(
        birthDate: input.birthDate,
        birthTime: input.birthTimeLocal,
        city: location.cityResolved,
        latitude: location.latitude,
        longitude: location.longitude,
        timezone: location.timezone,
        locale: locale, // ← FIX: was missing, defaulted to 'tr'
      );
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } on AstroServiceException catch (e) {
      setState(() {
        _errorMsg = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMsg = t(context, 'natal_report.unexpected_error');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CosmicLoadingScreen(
        message: t(context, 'natal_report.loading'),
        useLottie: true,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.bgDeep,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            title: Text(
              t(context, 'natal_report.title', args: {'name': widget.userName}),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.textSecondary,
                ),
                onPressed: _fetchReport,
                tooltip: t(context, 'natal_report.refresh'),
              ),
            ],
          ),

          // ── Body ───────────────────────────────────────────────
          if (_errorMsg != null)
            SliverFillRemaining(
              child: _ErrorView(message: _errorMsg!, onRetry: _fetchReport),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPersonHero(),
                  const SizedBox(height: 32),
                  ..._renderModernReport(_report ?? ''),
                  const SizedBox(height: 40),
                  _buildFooter(),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ── Person Hero ───────────────────────────────────────────────────
  Widget _buildPersonHero() {
    final summary = widget.chartData.summary;
    final location = widget.chartData.location;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: cosmicCard(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF130E29)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0x268B5CF6),
                  shape: BoxShape.circle,
                ),
                child: const Text('✨', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(
                        context,
                        'chart.title',
                        args: {'name': widget.userName},
                      ),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (location != null)
                      Text(
                        '📍 ${location.cityResolved}',
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
          if (summary != null) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // ── FIX: Translate sign names from backend (always TR) ─
                _heroChip('☀️', _translateSign(summary.sunSign)),
                _heroChip('🌙', _translateSign(summary.moonSign)),
                _heroChip('⬆️', _translateSign(summary.ascendantSign)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Translates a backend sign name (always Turkish) to the active locale.
  String _translateSign(String sign) {
    final key = _signKeys[sign];
    if (key == null) return sign;
    return t(context, key);
  }

  Widget _heroChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x991A1535),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x338B5CF6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Report Rendering ──────────────────────────────────────────────
  List<Widget> _renderModernReport(String report) {
    final sections = TextParser.parse(report);
    if (sections.isEmpty) return [];

    return sections.map((section) {
      return AnalysisSectionCard(
        title: section.title,
        content: section.content,
        icon: _getIconForTitle(section.title),
        bulletPoints: section.bulletPoints,
        color: _getColorForTitle(section.title),
      );
    }).toList();
  }

  Color? _getColorForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('güneş') || t.contains('sun')) return Colors.orange;
    if (t.contains('ay') || t.contains('moon')) return Colors.blueGrey;
    if (t.contains('aşk') || t.contains('love')) return Colors.pink;
    if (t.contains('kariyer') || t.contains('career')) return Colors.blue;
    return AppTheme.violet;
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: AppTheme.bgSurface, height: 60),
        // ── FIX: Footer text localized ──────────────────────────────
        Text(
          t(context, 'natal_report.footer_tagline'),
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'SoulBound · AI Astrology',
          style: TextStyle(
            color: Color(0x808B5CF6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error, fontSize: 14),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x268B5CF6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x4D8B5CF6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.violet,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t(context, 'natal_report.retry'),
                      style: const TextStyle(
                        color: AppTheme.violet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
