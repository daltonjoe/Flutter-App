import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart' show appOnGenerateRoute;
import '../providers/ask_context_provider.dart';
import 'active_chart_page.dart';
import 'ask_page.dart';
import 'match_page.dart';
import 'profile_switcher_page.dart';
import 'today_page.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../i18n/app_localizations.dart';
import '../services/ad_service.dart';
import '../services/user_settings_service.dart';
import '../widgets/navigation/cosmic_bottom_nav.dart';
import '../widgets/navigation/nav_tour_overlay.dart';
import '../redesign/splash/splash_overlay.dart';

final ValueNotifier<int> shellTab = ValueNotifier<int>(1);

/// Profil sekmesinin shellTab indeksi.
const int kProfileTab = 2;

/// Artınca Harita sekmesi köke döner (profil değişiminde).
final ValueNotifier<int> mapPopToRoot = ValueNotifier<int>(0);

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  late final Animation<double> _fadeOpacity = CurvedAnimation(
    parent: _fade,
    curve: Curves.easeOutCubic,
  );

  /// Hafif yukarı kayma (~8 px): çocuk yüksekliğinin küçük bir kesri
  /// (tipik ekranda ~8 px) kadar aşağıdan yukarı gelir.
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.02),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic));
  late final Animation<double> _scale = Tween<double>(
    begin: 0.98,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic));
  int _index = 1; // Today hazır olana kadar varsayılan: Harita
  final _keys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _navKey = GlobalKey();
  bool _matchTabEnabled = false;
  bool _matchTabLoaded = false;

  /// İlk açılış navigasyon turu (K34).
  bool _tourOn = false;
  List<int> _tourTabs = const [];

  bool get _askOn => askEnabled.value;
  bool get _matchOn => _matchTabLoaded && _matchTabEnabled;

  /// Görünen sekmelerin shellTab indeksleri (alt çubuk sırası).
  List<int> get _visible => [
    0,
    1,
    if (_askOn) kAskTab,
    if (_matchOn) 3,
    kProfileTab,
  ];

  @override
  void initState() {
    super.initState();
    _index = 1;
    shellTab.addListener(_onTab);
    askEnabled.addListener(_onAskFlag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shellTab.value != 1) shellTab.value = 1;
    });
    mapPopToRoot.addListener(_onPopMap);
    unawaited(_maybeStartTour());
  }

  /// İki sekme bayrağı da yüklendikten sonra, tur henüz gösterilmediyse
  /// başlatır. Bayraklar henüz yüklenmemişken başlatmak, kapalı sekmeleri
  /// yanlışlıkla gösterebilir.
  Future<void> _maybeStartTour() async {
    await Future.wait([_loadMatchFlag(), _loadAskFlag()]);
    if (!mounted) return;
    if (await navTourSeen()) {
      unawaited(_initAds()); // tur yok: yedek başlatma hemen
      return;
    }
    if (!mounted) return;
    setState(() {
      _tourTabs = List<int>.of(_visible);
      _tourOn = true;
    });
  }

  /// Yedek reklam başlatma (K5): onboarding'i bu sürümden önce bitirmiş
  /// kullanıcılar için. AdService.init() idempotent olduğundan sohbet
  /// çağrısıyla çakışmaz; hata sohbeti/kabuğu durdurmaz.
  Future<void> _initAds() async {
    try {
      await AdService.init();
    } catch (e) {
      debugPrint('MainShell AdService.init failed: $e');
    }
  }

  /// Alt çubuk pilinin global (ekran) koordinatındaki dikdörtgeni.
  Rect _pillRect() {
    final box = _navKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Rect.zero;
    final o = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      o.dx + AppSpacing.screenH,
      o.dy,
      box.size.width - 2 * AppSpacing.screenH,
      AppSizes.navBarHeight,
    );
  }

  /// Tur adımının açıklama metni (sekme indeksine göre).
  String _tourBody(int tab) {
    switch (tab) {
      case 0:
        return t(context, 'tour.today');
      case 1:
        return t(context, 'tour.chart');
      case 3:
        return t(context, 'tour.match');
      case kProfileTab:
        return t(context, 'tour.profile');
      default:
        return t(context, 'tour.ask');
    }
  }

  Future<void> _loadMatchFlag() async {
    try {
      final v = await UserSettingsService.isFlagEnabled('tab_match');
      if (!mounted) return;
      setState(() {
        _matchTabEnabled = v;
        _matchTabLoaded = true;
      });
    } catch (e) {
      debugPrint('match flag load failed: $e');
      if (mounted) {
        setState(() {
          _matchTabEnabled = false;
          _matchTabLoaded = true;
        });
      }
    }
  }

  Future<void> _loadAskFlag() async {
    try {
      askEnabled.value = await UserSettingsService.isFlagEnabled('tab_ai');
    } catch (e) {
      debugPrint('ask flag load failed: $e');
      askEnabled.value = false;
    }
  }

  void _onAskFlag() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    shellTab.removeListener(_onTab);
    askEnabled.removeListener(_onAskFlag);
    mapPopToRoot.removeListener(_onPopMap);
    _fade.dispose();
    super.dispose();
  }

  void _onTab() {
    if (!mounted || _index == shellTab.value) return;
    final target = shellTab.value;
    if (!_visible.contains(target)) return;
    setState(() => _index = target);
    if (MediaQuery.of(context).disableAnimations) {
      _fade.value = 1;
    } else {
      _fade.forward(from: 0);
    }
  }

  void _onPopMap() {
    _keys[1].currentState?.popUntil((r) => r.isFirst);
  }

  Widget _root(int i) {
    switch (i) {
      case 0:
        return const TodayPage();
      case 1:
        return const ActiveChartPage();
      case 2:
        return const ProfileSwitcherPage();
      case 3:
        return const MatchPage();
      default:
        return const AskPage();
    }
  }

  Route<dynamic>? _onRoute(int i, RouteSettings s) {
    if (s.name == '/') {
      return MaterialPageRoute(builder: (_) => _root(i), settings: s);
    }
    return appOnGenerateRoute(s);
  }

  CosmicNavItem _navItem(int tab, BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (tab) {
      case 0:
        return CosmicNavItem(
          index: 0,
          icon: Icons.wb_sunny_outlined,
          activeIcon: Icons.wb_sunny,
          label: l?.translate('nav.today') ?? 'nav.today',
        );
      case 1:
        return CosmicNavItem(
          index: 1,
          icon: Icons.public_outlined,
          activeIcon: Icons.public,
          label: l?.translate('nav.chart') ?? 'nav.chart',
        );
      case 2:
        return CosmicNavItem(
          index: 2,
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: l?.translate('nav.profile') ?? 'nav.profile',
        );
      case 3:
        return CosmicNavItem(
          index: 3,
          icon: Icons.favorite_border,
          activeIcon: Icons.favorite,
          label: l?.translate('nav.match') ?? 'nav.match',
        );
      default:
        return CosmicNavItem(
          index: kAskTab,
          icon: Icons.auto_awesome_outlined,
          activeIcon: Icons.auto_awesome,
          label: l?.translate('nav.ask') ?? 'nav.ask',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final idx = visible.contains(_index) ? _index : 1;
    final stackChildren = List.generate(5, (i) {
      if (!visible.contains(i)) return const SizedBox.shrink();
      return Navigator(key: _keys[i], onGenerateRoute: (s) => _onRoute(i, s));
    });
    final items = [for (final v in visible) _navItem(v, context)];
    final selected = visible.indexOf(idx);
    // Klavye açıkken çubuk aşağı kayıp solarak gizlenir; ağaçtan çıkarılmaz.
    // Böylece (özellikle AskPage girişi) klavyenin üstünde kalır.
    final navHidden = MediaQuery.viewInsetsOf(context).bottom > 0;
    final navDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_tourOn) return;
        final nav = _keys[idx].currentState;
        if (nav != null && nav.canPop()) nav.pop();
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            // Sayfa içeriği: fade + hafif yukarı kayma + çok hafif ölçek.
            FadeTransition(
              opacity: _fadeOpacity,
              child: SlideTransition(
                position: _slide,
                child: ScaleTransition(
                  scale: _scale,
                  child: IndexedStack(index: idx, children: stackChildren),
                ),
              ),
            ),
            // Okunabilirlik perdesi: sayfa arka planı görünür kalır.
            // Çubuk bölgesi + üstünde yumuşak geçiş; dokunuşları engellemez.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: navDuration,
                  curve: Curves.easeInOutCubic,
                  opacity: navHidden ? 0.0 : 1.0,
                  child: SizedBox(
                    height:
                        AppSizes.bottomNavInset(context) +
                        AppSizes.navScrimExtra,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.bgVoid.withValues(alpha: 0),
                            AppColors.bgVoid.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Yüzen "hap" gezinme çubuğu: klavye açıkken aşağı kayar ve
            // solarak gizlenir; ağaçtan çıkarılmaz.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: navHidden,
                child: AnimatedSlide(
                  duration: navDuration,
                  curve: Curves.easeInOutCubic,
                  offset: navHidden ? const Offset(0, 1) : Offset.zero,
                  child: AnimatedOpacity(
                    duration: navDuration,
                    curve: Curves.easeInOutCubic,
                    opacity: navHidden ? 0.0 : 1.0,
                    child: CosmicBottomNav(
                      key: _navKey,
                      items: items,
                      selectedIndex: selected,
                      onTap: (tab) {
                        shellTab.value = tab;
                      },
                    ),
                  ),
                ),
              ),
            ),
            // İlk açılış navigasyon turu (K34): alt çubuğu tanıtır.
            if (_tourOn)
              Positioned.fill(
                child: NavTourOverlay(
                  steps: [
                    for (var i = 0; i < _tourTabs.length; i++)
                      NavTourStep(
                        slot: i,
                        title: _navItem(_tourTabs[i], context).label,
                        body: _tourBody(_tourTabs[i]),
                      ),
                  ],
                  pillRect: _pillRect,
                  onStep: (i) => shellTab.value = _tourTabs[i],
                  onDone: () {
                    unawaited(navTourMarkSeen());
                    setState(() => _tourOn = false);
                    shellTab.value = 1;
                    unawaited(_initAds()); // tur bitti: yedek başlatma
                  },
                ),
              ),
            const Positioned.fill(child: SplashOverlay()),
          ],
        ),
      ),
    );
  }
}
