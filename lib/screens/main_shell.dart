import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart' show appOnGenerateRoute;
import '../providers/ask_context_provider.dart';
import 'active_chart_page.dart';
import 'ask_page.dart';
import 'match_page.dart';
import 'profile_switcher_page.dart';
import 'today_page.dart';
import '../i18n/app_localizations.dart';
import '../services/user_settings_service.dart';

final ValueNotifier<int> shellTab = ValueNotifier<int>(1);

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
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  int _index = 1; // Today hazır olana kadar varsayılan: Harita
  final _keys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  bool _matchTabEnabled = false;
  bool _matchTabLoaded = false;

  bool get _askOn => askEnabled.value;
  bool get _matchOn => _matchTabLoaded && _matchTabEnabled;

  /// Görünen sekmelerin shellTab indeksleri (alt çubuk sırası).
  List<int> get _visible => [0, 1, if (_askOn) kAskTab, if (_matchOn) 3, 2];

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
    unawaited(_loadMatchFlag());
    unawaited(_loadAskFlag());
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

  NavigationDestination _dest(int tab, BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (tab) {
      case 0:
        return NavigationDestination(
          icon: const Icon(Icons.wb_sunny_outlined),
          label: l?.translate('nav.today') ?? 'nav.today',
        );
      case 1:
        return NavigationDestination(
          icon: const Icon(Icons.public),
          label: l?.translate('nav.chart') ?? 'nav.chart',
        );
      case 2:
        return NavigationDestination(
          icon: const Icon(Icons.person_outline),
          label: l?.translate('nav.profile') ?? 'nav.profile',
        );
      case 3:
        return NavigationDestination(
          icon: const Icon(Icons.favorite_border),
          label: l?.translate('nav.match') ?? 'nav.match',
        );
      default:
        return NavigationDestination(
          icon: const Icon(Icons.auto_awesome_outlined),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _keys[idx].currentState;
        if (nav != null && nav.canPop()) nav.pop();
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _fade,
          child: IndexedStack(index: idx, children: stackChildren),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: visible.indexOf(idx),
          onDestinationSelected: (i) {
            shellTab.value = visible[i];
          },
          destinations: [for (final v in visible) _dest(v, context)],
        ),
      ),
    );
  }
}