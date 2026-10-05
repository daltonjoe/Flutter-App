import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart' show appOnGenerateRoute;
import 'active_chart_page.dart';
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
  final _keys = List.generate(4, (_) => GlobalKey<NavigatorState>());
  bool _matchTabEnabled = false;
  bool _matchTabLoaded = false;

  @override
  void initState() {
    super.initState();
    _index = 1;
    shellTab.addListener(_onTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shellTab.value != 1) shellTab.value = 1;
    });
    mapPopToRoot.addListener(_onPopMap);
    unawaited(_loadMatchFlag());
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

  @override
  void dispose() {
    shellTab.removeListener(_onTab);
    mapPopToRoot.removeListener(_onPopMap);
    _fade.dispose();
    super.dispose();
  }

  void _onTab() {
    if (!mounted || _index == shellTab.value) return;
    final target = shellTab.value;
    final max = _matchTabEnabled ? 3 : 2;
    final clamped = target > max ? max : target;
    setState(() => _index = clamped);
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
      default:
        return const MatchPage();
    }
  }

  Route<dynamic>? _onRoute(int i, RouteSettings s) {
    if (s.name == '/') {
      return MaterialPageRoute(builder: (_) => _root(i), settings: s);
    }
    return appOnGenerateRoute(s);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final showMatch = _matchTabLoaded && _matchTabEnabled;
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.wb_sunny_outlined),
        label: l?.translate('nav.today') ?? 'nav.today',
      ),
      NavigationDestination(
        icon: const Icon(Icons.public),
        label: l?.translate('nav.chart') ?? 'nav.chart',
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        label: l?.translate('nav.profile') ?? 'nav.profile',
      ),
      if (showMatch)
        NavigationDestination(
          icon: const Icon(Icons.favorite_border),
          label: l?.translate('nav.match') ?? 'nav.match',
        ),
    ];
    final stackChildren = List.generate(4, (i) {
      return Navigator(key: _keys[i], onGenerateRoute: (s) => _onRoute(i, s));
    });
    final maxIdx = showMatch ? 3 : 2;
    var idx = _index;
    if (idx > maxIdx) idx = maxIdx;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _keys[idx].currentState!;
        if (nav.canPop()) nav.pop();
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _fade,
          child: IndexedStack(index: idx, children: stackChildren),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) {
            final clamped = i > maxIdx ? maxIdx : i;
            shellTab.value = clamped;
          },
          destinations: destinations,
        ),
      ),
    );
  }
}
