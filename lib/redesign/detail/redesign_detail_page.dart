// Detay sayfası (Faz 7a). Eski PlanetReportPage / PlacementContentPage veri
// akışını korur; görsel düzen yeniden kurulmuştur.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/content_theme_colors.dart';
import '../../core/reference_ids.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/text_parser.dart';
import '../../i18n/app_localizations.dart';
import '../../models/ask_context.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/analysis_section_card.dart';
import '../../presentation/widgets/components/cosmic_background.dart';
import '../../presentation/widgets/components/cosmic_error_state.dart';
import '../../presentation/widgets/components/cosmic_loader.dart';
import '../../presentation/widgets/components/planet_glyph_icon.dart';
import '../../providers/active_profile_provider.dart';
import '../../providers/ask_context_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/astro_service.dart';
import '../../services/placement_content_service.dart';
import '../../services/reference_names_service.dart';
import '../../widgets/ask_add.dart';
import '../assets_map.dart';
import '../data/detail_section.dart';
import 'detail_tab_bar.dart';

class RedesignDetailPage extends StatefulWidget {
  const RedesignDetailPage.planet({
    super.key,
    required this.chartData,
    required String planetKey,
  }) : modeKey = planetKey,
       isPlanet = true;

  const RedesignDetailPage.placement({
    super.key,
    required this.chartData,
    required String placementKey,
  }) : modeKey = placementKey,
       isPlanet = false;

  final NatalChartResponse chartData;

  /// Gezegen modunda 'Sun'..'Pluto', yerleşim modunda 'sun'|'moon'|'ascendant'.
  final String modeKey;

  final bool isPlanet;

  @override
  State<RedesignDetailPage> createState() => _RedesignDetailPageState();
}

class _RedesignDetailPageState extends State<RedesignDetailPage> {
  late final bool _birthTimeKnown =
      widget.chartData.input?.birthTimeKnown == true;

  int _token = 0;
  String? _loc;
  bool _loading = true;
  String? _errorMessage;
  bool _isFallback = false;
  String? _report;
  List<DetailSection> _sections = const <DetailSection>[];
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = context.watch<LanguageProvider>().locale.languageCode;
    if (_loc != null && _loc != loc) _reload();
  }

  void _reload() {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _isFallback = false;
      _report = null;
    });
    _load();
  }

  Future<void> _load() async {
    final locale = context.read<LanguageProvider>().locale.languageCode;
    _loc = locale;
    final myToken = ++_token;
    if (widget.isPlanet) {
      await _loadPlanet(locale, myToken);
    } else {
      await _loadPlacement(locale, myToken);
    }
  }

  /// PlanetReportPage._fetch() ile aynı sorgu ve aynı AI yedeği.
  Future<void> _loadPlanet(String locale, int myToken) async {
    final pd = widget.chartData.planets?[widget.modeKey];
    final house = pd?.house ?? 0;

    if (widget.modeKey == 'Moon' && !_birthTimeKnown) {
      if (!mounted || myToken != _token) return;
      setState(() {
        _sections = const <DetailSection>[];
        _loading = false;
      });
      return;
    }

    try {
      final signCode = RefIds.signCode(pd?.signIndex ?? -1) ?? '';
      var query = Supabase.instance.client
          .from('placement_content')
          .select(
            'title, content, strengths, challenges, '
            'celestial_bodies!inner(code), zodiac_signs!inner(code), '
            'astrological_houses!inner(house_number), '
            'content_themes(code, sort_order)',
          )
          .eq('celestial_bodies.code', widget.modeKey)
          .eq('zodiac_signs.code', signCode);
      if (_birthTimeKnown && house > 0) {
        query = query.eq('astrological_houses.house_number', house);
      }
      final rows = await query.eq('locale', locale).eq('is_active', true);
      if (!mounted || myToken != _token) return;
      if (rows.isEmpty) {
        // Yedek: Supabase'de içerik yoksa eski AI akışına düş.
        final report = await AstroService.generatePlanetReport(
          planetName: widget.modeKey,
          chartData: widget.chartData.toChartPayload(),
          locale: locale,
        );
        if (!mounted || myToken != _token) return;
        setState(() {
          _report = report;
          _isFallback = true;
          _sections = const <DetailSection>[];
          _loading = false;
        });
      } else {
        setState(() {
          _sections = [
            for (final row in rows) DetailSection.fromPlanetRow(row),
          ];
          _isFallback = false;
          _loading = false;
        });
      }
    } on AstroServiceException catch (e) {
      if (!mounted || myToken != _token) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (e) {
      debugPrint('redesign detail planet fetch error: $e');
      if (!mounted || myToken != _token) return;
      setState(() {
        _errorMessage = t(context, 'planet_report.unexpected_error');
        _loading = false;
      });
    }
  }

  /// PlacementContentPage._load() ile aynı servis çağrısı ve burç kodu türetimi.
  Future<void> _loadPlacement(String locale, int myToken) async {
    final key = widget.modeKey;
    if (key == 'moon' && !_birthTimeKnown) {
      if (!mounted || myToken != _token) return;
      setState(() {
        _sections = const <DetailSection>[];
        _loading = false;
      });
      return;
    }

    try {
      final int? signIndex = placementSignIndex(widget.chartData, key);
      final result = await PlacementContentService.fetch(
        placements: <String, String>{
          key: signIndex == null ? '' : (RefIds.signCode(signIndex) ?? ''),
        },
        locale: locale,
      );
      if (!mounted || myToken != _token) return;
      final rows = result[key] ?? const <PlacementContent>[];
      setState(() {
        _sections = [for (final row in rows) DetailSection.fromPlacement(row)];
        _loading = false;
      });
    } catch (e) {
      debugPrint('redesign detail placement fetch error: $e');
      if (!mounted || myToken != _token) return;
      setState(() {
        _errorMessage = t(context, 'placement.error');
        _loading = false;
      });
    }
  }

  // ── Türetilmiş veriler ────────────────────────────────────────────────
  PlanetData? get _planetData {
    final planets = widget.chartData.planets;
    if (widget.isPlanet) return planets?[widget.modeKey];
    if (widget.modeKey == 'sun') return planets?['Sun'];
    if (widget.modeKey == 'moon') return planets?['Moon'];
    return null;
  }

  int? get _signIndex {
    final pd = _planetData;
    if (pd != null) return pd.signIndex;
    if (widget.modeKey == 'ascendant') {
      return widget.chartData.houses?['house_1']?.signIndex;
    }
    return null;
  }

  /// Görsel için gezegen anahtarı; yükselen burçta görsel yok.
  String? get _assetKey {
    if (widget.isPlanet) return widget.modeKey;
    if (widget.modeKey == 'sun') return 'Sun';
    if (widget.modeKey == 'moon') return 'Moon';
    return null;
  }

  bool get _timeUnknown => widget.isPlanet && (_planetData?.house ?? 1) <= 0;

  void _onThemeSelected(int index) {
    final codes = _themeCodes(_sortedSections(_sections));
    if (index < 0 || index >= codes.length) return;
    setState(() {
      _selectedCode = codes[index];
    });
  }

  String _displayName(ReferenceNamesService names) {
    if (!widget.isPlanet) return t(context, 'chart.${widget.modeKey}');
    final id = RefIds.planets[widget.modeKey];
    return id == null ? widget.modeKey : names.planet(id);
  }

  @override
  Widget build(BuildContext context) {
    final names = context.watch<ReferenceNamesService>();
    final sections = _sortedSections(_sections);
    final codes = _themeCodes(sections);
    final showTabs =
        !_loading &&
        _errorMessage == null &&
        !_isFallback &&
        !_timeUnknown &&
        codes.isNotEmpty;
    final selectedIndex = _indexForCode(codes, _selectedCode);
    final selectedCode = codes.isEmpty ? null : codes[selectedIndex];

    final slivers = <Widget>[
      SliverPadding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.sm,
          end: AppSpacing.screenH,
          top: AppSpacing.sm,
        ),
        sliver: SliverToBoxAdapter(child: _topRow(context)),
      ),
    ];

    if (_loading) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: widget.isPlanet
              ? CosmicLoader(message: t(context, 'planet_report.loading'))
              : const CosmicLoader(),
        ),
      );
    } else if (_errorMessage != null) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: CosmicErrorState(
            message: _errorMessage!,
            onRetry: _reload,
            retryLabel: t(
              context,
              widget.isPlanet ? 'natal_report.retry' : 'placement.retry',
            ),
          ),
        ),
      );
    } else {
      if (showTabs) {
        slivers.add(
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        );
        slivers.add(
          SliverToBoxAdapter(
            child: DetailTabBar(
              themeCodes: codes,
              selectedIndex: selectedIndex,
              onSelected: _onThemeSelected,
            ),
          ),
        );
        slivers.add(
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        );
      }
      slivers.add(
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.screenH,
          ),
          sliver: SliverToBoxAdapter(child: _header(context, names)),
        ),
      );
      slivers.add(
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.screenH,
          ),
          sliver: SliverToBoxAdapter(
            child: _contentArea(sections, selectedCode),
          ),
        ),
      );
      slivers.add(
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      );
      slivers.add(
        SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.scrollBottomPadding(context)),
        ),
      );
    }

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(slivers: slivers),
        ),
      ),
    );
  }

  Widget _topRow(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final bool canRefresh =
        widget.isPlanet && !_loading && _errorMessage == null;
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(
            rtl
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
            color: AppColors.starlight,
            size: 20,
          ),
        ),
        const Spacer(),
        if (canRefresh)
          IconButton(
            onPressed: _reload,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.mist,
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _header(BuildContext context, ReferenceNamesService names) {
    final pd = _planetData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _image(names),
        const SizedBox(height: AppSpacing.md),
        Text(
          _displayName(names),
          style: AppTextStyles.h1(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        _metaLine(
          context,
          names: names,
          signIndex: _signIndex,
          planetData: _planetData,
          birthTimeKnown: _birthTimeKnown,
        ),
        if (widget.isPlanet && pd != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${pd.degreeInSign.toStringAsFixed(2)}°',
            style: AppTextStyles.bodySm(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _askSection(names),
      ],
    );
  }

  Widget _image(ReferenceNamesService names) {
    final assetKey = _assetKey;
    final double height = MediaQuery.sizeOf(context).height * 0.28;
    if (assetKey == null) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '✦',
            style: AppTextStyles.displayLarge(color: AppColors.gold),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: Image.asset(
          RdAssets.planetImage(assetKey),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Center(
            child: PlanetGlyphIcon(
              name: assetKey.toLowerCase(),
              size: 28,
              color: AppColors.mist,
              semanticLabel: _displayName(names),
            ),
          ),
        ),
      ),
    );
  }

  Widget _askSection(ReferenceNamesService names) {
    if (!widget.isPlanet) {
      return _placementAskButton(
        context,
        chartData: widget.chartData,
        placementKey: widget.modeKey,
        birthTimeKnown: _birthTimeKnown,
        names: names,
      );
    }

    final pd = _planetData;
    final pid = RefIds.planets[widget.modeKey];
    if (pd == null || pid == null) return const SizedBox.shrink();
    final planetLabel = names.planet(pid);
    final hasHouse = _birthTimeKnown && pd.house > 0;
    final question = t(
      context,
      hasHouse ? 'ask.about.placement' : 'ask.about.nohouse',
      args: {
        'planet': planetLabel,
        'sign': names.sign(RefIds.signId(pd.signIndex)),
        'house': hasHouse ? names.house(pd.house) : '',
      },
    );
    return ValueListenableBuilder<bool>(
      valueListenable: askEnabled,
      builder: (_, on, _) => !on
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: () => askAbout(question),
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: Text(t(context, 'ask.about.button')),
                ),
                TextButton.icon(
                  onPressed: () {
                    final profileId = context
                        .read<ActiveProfileProvider>()
                        .activeProfileId;
                    if (profileId == null) return;
                    addToAsk(
                      context,
                      AskContext.natalPlacement(
                        profileId: profileId,
                        planetId: pid,
                        label: planetLabel,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t(context, 'ask.add')),
                ),
              ],
            ),
    );
  }

  Widget _contentArea(List<DetailSection> sections, String? selectedCode) {
    if (_timeUnknown) {
      return Text(
        t(context, 'planet_report.time_unknown'),
        style: AppTextStyles.bodyMd(),
      );
    }

    if (_isFallback) {
      final text = _report;
      if (text == null || text.isEmpty) return const SizedBox.shrink();
      final cards = TextParser.parse(text);
      if (cards.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in cards)
            AnalysisSectionCard(
              title: section.title,
              content: section.content,
              bulletPoints: section.bulletPoints,
              color: AppColors.gold,
            ),
        ],
      );
    }

    return _sectionsColumn(context, sections, selectedCode);
  }
}

// ── Paylaşılan yerleşim yardımcıları ────────────────────────────────────
// Detay sayfası ve harita sayfasındaki satır içi görünüm aynı parçaları
// kullanır; böylece kopyala-yapıştır çoğaltma olmaz.

List<DetailSection> _sortedSections(List<DetailSection> sections) {
  final list = <DetailSection>[...sections];
  list.sort((a, b) => a.themeOrder.compareTo(b.themeOrder));
  return list;
}

List<String> _themeCodes(List<DetailSection> sections) {
  final codes = <String>[];
  for (final section in sections) {
    if (section.themeCode.isEmpty || codes.contains(section.themeCode)) {
      continue;
    }
    codes.add(section.themeCode);
  }
  return codes;
}

int _indexForCode(List<String> codes, String? code) {
  if (code == null) return 0;
  final index = codes.indexOf(code);
  return index < 0 ? 0 : index;
}

/// 'sun' | 'moon' | 'ascendant' yerleşimi için burç indeksi.
int? placementSignIndex(NatalChartResponse chartData, String key) {
  if (key == 'ascendant') return chartData.houses?['house_1']?.signIndex;
  return chartData.planets?[key == 'sun' ? 'Sun' : 'Moon']?.signIndex;
}

/// 'sun' | 'moon' yerleşimi için gezegen verisi (yükselende yoktur).
PlanetData? _placementPlanetData(NatalChartResponse chartData, String key) {
  if (key == 'sun') return chartData.planets?['Sun'];
  if (key == 'moon') return chartData.planets?['Moon'];
  return null;
}

Widget _sectionsColumn(
  BuildContext context,
  List<DetailSection> sections,
  String? selectedCode,
) {
  final visible = selectedCode == null
      ? sections
      : sections.where((s) => s.themeCode == selectedCode).toList();
  if (visible.isEmpty) {
    return Text(t(context, 'placement.empty'), style: AppTextStyles.bodyMd());
  }

  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    transitionBuilder: (child, animation) =>
        FadeTransition(opacity: animation, child: child),
    layoutBuilder: (currentChild, previousChildren) => Stack(
      alignment: AlignmentDirectional.topStart,
      children: [...previousChildren, ?currentChild],
    ),
    child: Column(
      key: ValueKey<String>(selectedCode ?? 'all'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in visible) ...[
          _PlacementCard(section),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    ),
  );
}

Widget _metaLine(
  BuildContext context, {
  required ReferenceNamesService names,
  required int? signIndex,
  required PlanetData? planetData,
  required bool birthTimeKnown,
}) {
  final parts = <String>[];
  if (signIndex != null) {
    parts.add(names.sign(RefIds.signId(signIndex)));
  }
  if (planetData != null && birthTimeKnown && planetData.house > 0) {
    parts.add(
      t(
        context,
        'planet_report.house',
        args: {'number': planetData.house.toString()},
      ),
    );
  }
  if (planetData != null && planetData.retrograde) {
    parts.add(t(context, 'planet_report.retrograde'));
  }
  if (parts.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
    child: Text(
      parts.join('  ·  '),
      style: AppTextStyles.bodyMd(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

/// Yerleşim modu için Ask butonu (detay sayfası ve satır içi görünüm ortak).
Widget _placementAskButton(
  BuildContext context, {
  required NatalChartResponse chartData,
  required String placementKey,
  required bool birthTimeKnown,
  required ReferenceNamesService names,
}) {
  final key = placementKey;
  final String question;
  if (key == 'ascendant') {
    final signIndex = chartData.houses?['house_1']?.signIndex;
    if (signIndex == null) return const SizedBox.shrink();
    question = t(
      context,
      'ask.about.asc',
      args: {'sign': names.sign(RefIds.signId(signIndex))},
    );
  } else {
    final pd = _placementPlanetData(chartData, key);
    if (pd == null) return const SizedBox.shrink();
    final id = RefIds.planets[key == 'sun' ? 'Sun' : 'Moon'] ?? 0;
    question = t(
      context,
      birthTimeKnown ? 'ask.about.placement' : 'ask.about.nohouse',
      args: {
        'planet': names.planet(id),
        'sign': names.sign(RefIds.signId(pd.signIndex)),
        'house': names.house(pd.house),
      },
    );
  }
  return ValueListenableBuilder<bool>(
    valueListenable: askEnabled,
    builder: (_, on, _) => !on
        ? const SizedBox.shrink()
        : Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: () => askAbout(question),
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(t(context, 'ask.about.button')),
            ),
          ),
  );
}

/// Yerleşim içeriği kartı (başlık, kısa açıklama, gövde, anahtar kelimeler,
/// güçlü yönler/zorluklar). Detay sayfası ve satır içi görünüm ortak kullanır.
class _PlacementCard extends StatelessWidget {
  const _PlacementCard(this.section);

  final DetailSection section;

  @override
  Widget build(BuildContext context) {
    final color = themeColorFor(section.themeCode);
    final short = section.shortDescription;
    final body = section.content;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navyDeep.withValues(alpha: 0.8),
        borderRadius: AppRadius.lgBr,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (short != null && short.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              short,
              style: AppTextStyles.bodySm().copyWith(
                fontStyle: FontStyle.italic,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: AppTextStyles.bodyMd()),
          ],
          _bullets(context, 'placement.strengths', section.strengths, color),
          _bullets(context, 'placement.challenges', section.challenges, color),
        ],
      ),
    );
  }

  Widget _bullets(
    BuildContext context,
    String labelKey,
    List<String> items,
    Color color,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(context, labelKey), style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.xs,
                    ),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.bodySm())),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Harita sayfasındaki Ascendant sekmesi için satır içi yerleşim
/// içeriği. Veri yükleme sayfa durumunda (RedesignChartPage) yapılır; bu widget
/// yalnızca önceden yüklenmiş bölümleri gösterir. Böylece sekme geçişinde
/// yeniden fetch/loader oluşmaz.
class PlacementInlineContent extends StatelessWidget {
  const PlacementInlineContent({
    super.key,
    required this.chartData,
    required this.placementKey,
    required this.sections,
  });

  final NatalChartResponse chartData;

  /// 'ascendant'
  final String placementKey;

  /// Onceden yuklenmis bolumler; yalniz love temasi gosterilir (bos olabilir).
  final List<DetailSection> sections;

  bool get _birthTimeKnown => chartData.input?.birthTimeKnown == true;

  @override
  Widget build(BuildContext context) {
    final names = context.watch<ReferenceNamesService>();
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.screenH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(context, 'chart.$placementKey'),
            style: AppTextStyles.h1(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _metaLine(
            context,
            names: names,
            signIndex: placementSignIndex(chartData, placementKey),
            planetData: _placementPlanetData(chartData, placementKey),
            birthTimeKnown: _birthTimeKnown,
          ),
          const SizedBox(height: AppSpacing.md),
          _placementAskButton(
            context,
            chartData: chartData,
            placementKey: placementKey,
            birthTimeKnown: _birthTimeKnown,
            names: names,
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionsColumn(context, _sortedSections(sections), 'love'),
        ],
      ),
    );
  }
}
