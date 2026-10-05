import 'package:flutter/material.dart';
import '../main.dart' show appOnGenerateRoute;
import 'active_chart_page.dart';
import 'profile_switcher_page.dart';
import 'today_page.dart';
import '../i18n/app_localizations.dart';

final ValueNotifier<int> shellTab = ValueNotifier<int>(1);
/// Artınca Harita sekmesi köke döner (profil değişiminde).
final ValueNotifier<int> mapPopToRoot = ValueNotifier<int>(0);

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 1; // Today hazır olana kadar varsayılan: Harita
  final _keys = List.generate(3, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
 _index = 1; // yeni MainShell her zaman Harita'da açılır
    shellTab.addListener(_onTab);
    // Global değeri build dışında sıfırla (build sırasında yazmak setState hatası verir).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shellTab.value != 1) shellTab.value = 1;
    });
    mapPopToRoot.addListener(_onPopMap);
  }

  @override
  void dispose() {
    shellTab.removeListener(_onTab);
    mapPopToRoot.removeListener(_onPopMap);
    super.dispose();
  }

  void _onTab() {
    if (!mounted || _index == shellTab.value) return;
    setState(() => _index = shellTab.value);
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
      default:
        return const ProfileSwitcherPage();
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _keys[_index].currentState!;
        if (nav.canPop()) nav.pop();
      },
      child: Scaffold(
  body: Stack(
          children: List.generate(3, (i) {
            final active = i == _index;
            final reduce = MediaQuery.of(context).disableAnimations;
            return Positioned.fill(
              child: IgnorePointer(
                ignoring: !active,
                child: ExcludeFocus(
                  excluding: !active,
                  child: TickerMode(
                    enabled: active,
                    child: AnimatedOpacity(
                      opacity: active ? 1 : 0,
                      duration: reduce
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      child: Navigator(
                        key: _keys[i],
                        onGenerateRoute: (s) => _onRoute(i, s),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => shellTab.value = i,
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.wb_sunny_outlined),
                label: l?.translate('nav.today') ?? 'nav.today'),
            NavigationDestination(
                icon: const Icon(Icons.public),
                label: l?.translate('nav.chart') ?? 'nav.chart'),
            NavigationDestination(
                icon: const Icon(Icons.person_outline),
                label: l?.translate('nav.profile') ?? 'nav.profile'),
          ],
        ),
      ),
    );
  }
}