// Redesign Harita sayfası iskeleti (Faz 4).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/reference_ids.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/cosmic_background.dart';
import '../../presentation/widgets/components/cosmic_error_state.dart';
import '../../presentation/widgets/components/cosmic_loader.dart';
import '../../presentation/widgets/components/profile_avatar_button.dart';
import '../../providers/language_provider.dart';
import '../../services/placement_content_service.dart';
import '../data/detail_section.dart';
import '../detail/redesign_detail_page.dart';
import 'chart_category_bar.dart';
import 'chart_extras.dart';
import 'house_meaning_panel.dart';
import 'planet_carousel.dart';

/// Sekme içeriği geçişi (fade + hafif yukarı kayma) süresi.
const Duration _kTabSwitchDuration = Duration(milliseconds: 250);

/// Karusel bloğunun hero sahnesinin altına bindiği miktar (dp).
const double _kCarouselOverlap = 32;

class RedesignChartPage extends StatefulWidget {
  const RedesignChartPage({
    super.key,
    required this.chartData,
    required this.userName,
  });

  final NatalChartResponse chartData;

  final String userName;

  @override
  State<RedesignChartPage> createState() => _RedesignChartPageState();
}

class _RedesignChartPageState extends State<RedesignChartPage> {
  final ValueNotifier<int> _selected = ValueNotifier<int>(0);

  /// Karusel kaydırma konumu; hero görsellerinin kaymasını sürer.
  final ValueNotifier<double> _pagePosition = ValueNotifier<double>(0);

  /// Seçili sekme: 'all' | 'sun' | 'moon' | 'ascendant'.
  String _tab = 'all';

  /// locale → (placementKey → bölümler). Sayfa açılışında üç yerleşim tek
  /// çağrıda yüklenir; sekme değişiminde yeni fetch yapılmaz.
  final Map<String, Map<String, List<DetailSection>>> _cache =
      <String, Map<String, List<DetailSection>>>{};

  /// Hedef locale ve verisi ekranda olan locale. Locale değişince eski veri
  /// ekranda kalır, yeni veri arka planda yüklenir (stale-while-revalidate).
  String? _targetLocale;
  String? _shownLocale;

  bool _loading = false;
  String? _error;
  int _token = 0;

  bool get _birthTimeKnown => widget.chartData.input?.birthTimeKnown == true;

  bool get _isPlacementTab =>
      _tab == 'sun' || _tab == 'moon' || _tab == 'ascendant';

  List<DetailSection>? _sectionsFor(String key) => _cache[_shownLocale]?[key];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = context.watch<LanguageProvider>().locale.languageCode;
    if (_targetLocale == loc) return;
    _targetLocale = loc;
    final cached = _cache[loc];
    if (cached != null) {
      setState(() {
        _shownLocale = loc;
        _loading = false;
        _error = null;
      });
      return;
    }
    _fetchPlacements(loc);
  }

  Future<void> _fetchPlacements(String loc) async {
    final myToken = ++_token;
    setState(() {
      _loading = true;
      _error = null;
    });
    final placements = <String, String>{
      'sun': _signCode('sun'),
      if (_birthTimeKnown) 'moon': _signCode('moon'),
      if (_birthTimeKnown) 'ascendant': _signCode('ascendant'),
    };
    try {
      final result = await PlacementContentService.fetch(
        placements: placements,
        locale: loc,
      );
      if (!mounted || myToken != _token) return;
      final map = <String, List<DetailSection>>{
        for (final key in placements.keys) key: const <DetailSection>[],
      };
      result.forEach((key, rows) {
        map[key] = [for (final row in rows) DetailSection.fromPlacement(row)];
      });
      _cache[loc] = map;
      setState(() {
        _shownLocale = loc;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('redesign chart placements fetch error: $e');
      if (!mounted || myToken != _token) return;
      setState(() {
        _loading = false;
        _error = t(context, 'placement.error');
      });
    }
  }

  String _signCode(String key) {
    final index = placementSignIndex(widget.chartData, key);
    if (index == null) return '';
    return RefIds.signCode(index) ?? '';
  }

  void _retry() {
    final loc = _targetLocale;
    if (loc == null) return;
    _cache.remove(loc);
    _fetchPlacements(loc);
  }

  @override
  void dispose() {
    _selected.dispose();
    _pagePosition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final switchDuration = reduceMotion
        ? const Duration(milliseconds: 150)
        : _kTabSwitchDuration;
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.userName,
                          style: AppTextStyles.h1(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const ProfileAvatarButton(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: ChartCategoryBar(
                  birthTimeKnown:
                      widget.chartData.input?.birthTimeKnown == true,
                  selectedKey: _tab,
                  onSelect: (k) => setState(() {
                    if (k == 'all') _selected.value = 0;
                    _tab = k;
                  }),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: switchDuration,
                  curve: Curves.easeOutCubic,
                  alignment: AlignmentDirectional.topStart,
                  child: AnimatedSwitcher(
                    duration: switchDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      if (reduceMotion) {
                        return FadeTransition(opacity: animation, child: child);
                      }
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: AlignmentDirectional.topStart,
                      children: [...previousChildren, ?currentChild],
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<String>(_tabContentKey),
                      child: _tabContent(context),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: SizedBox(height: AppSizes.scrollBottomPadding(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AnimatedSwitcher anahtarı: sekme + veri hazır mı (loader → içerik geçişi
  /// de yumuşak olsun).
  String get _tabContentKey {
    final ready = _isPlacementTab && _sectionsFor(_tab) != null;
    return '$_tab#${ready ? 1 : 0}';
  }

  Widget _tabContent(BuildContext context) {
    if (_tab == 'all') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlanetGlyphStrip(chartData: widget.chartData, selected: _selected),
          const SizedBox(height: AppSpacing.md),
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Hero sahnesi; alt kısmı aşağıdaki karusel bloğunun arkasında
              // kalır (glow ve halkalar kartın arkasından taşar).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: kPlanetHeroHeight,
                child: PlanetHero(
                  chartData: widget.chartData,
                  selected: _selected,
                  pagePosition: _pagePosition,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: kPlanetHeroHeight - _kCarouselOverlap,
                  ),
                  child: PlanetCarousel(
                    chartData: widget.chartData,
                    selected: _selected,
                    pagePosition: _pagePosition,
                    onSettled: (i) => _selected.value = i,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          HouseMeaningPanel(chartData: widget.chartData, selected: _selected),
          const SizedBox(height: AppSpacing.lg),
          ChartExtras(chartData: widget.chartData, userName: widget.userName),
        ],
      );
    }

    final sections = _sectionsFor(_tab);
    if (sections != null) {
      return PlacementInlineContent(
        chartData: widget.chartData,
        placementKey: _tab,
        sections: sections,
      );
    }
    if (!_loading && _error != null) {
      return CosmicErrorState(
        message: _error!,
        onRetry: _retry,
        retryLabel: t(context, 'placement.retry'),
      );
    }
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: const CosmicLoader(),
    );
  }
}
