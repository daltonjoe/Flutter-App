// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/cosmic_theme.dart';
import 'providers/language_provider.dart';
import 'providers/active_profile_provider.dart';
import 'services/reference_names_service.dart';
import 'i18n/app_localizations.dart';
import 'screens/onboarding/onboarding_flow_page.dart';
import 'screens/profile_switcher_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'screens/onboarding/onboarding_link_account_page.dart';
import 'screens/onboarding/onboarding_register_page.dart';
import 'screens/onboarding/onboarding_sign_in_page.dart';
import 'screens/onboarding/onboarding_calculating_page.dart';
import 'screens/onboarding/onboarding_first_result_page.dart';
import 'screens/main_shell.dart';
import 'screens/settings_page.dart';
import 'screens/streak_page.dart';
import 'screens/notifications_page.dart';
import 'services/account_deletion_service.dart';
import 'services/account_linking_service.dart';
import 'services/analytics_service.dart';
import "package:flutter_application/paywall/paywall_service.dart";
import "package:shared_preferences/shared_preferences.dart";
import "session/resolve_entry.dart";
import "session/session_controller.dart";
import "session/supabase_session_source.dart";
import "presentation/widgets/components/cosmic_loader.dart";
import "presentation/widgets/components/cosmic_alert_dialog.dart";
import "presentation/widgets/components/cosmic_error_state.dart";
import "redesign/splash/loading_video_host.dart";
import "redesign/splash/loading_video.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final languageProvider = LanguageProvider();
  await languageProvider.loadSavedLocale();
  final activeProfileProvider = ActiveProfileProvider();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDeep,
    ),
  );

  _readWebError67();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // Bayat (sunucuda silinmiş) oturumu temizle; initialize'dan SONRA olmalı.
  try {
    await AccountDeletionService.ensureValidSession();
  } catch (e) {
    debugPrint('ensureValidSession failed: $e');
  }

  if (Supabase.instance.client.auth.currentSession == null) {
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous Supabase sign-in failed: $e');
    }
  }
  AnalyticsService.init();
  _netFail80 =
      Supabase.instance.client.auth.currentSession == null ||
      !await _reachable80();

  await activeProfileProvider.load();
  final sessionController = SessionController(
    source: SupabaseSessionSource(),
    profiles: activeProfileProvider,
    language: languageProvider,
  );
  _ctl80 = sessionController;
  try {
    await sessionController.refresh();
  } catch (e) {
    debugPrint("session refresh failed: $e");
  }
  var lastUid80 = sessionController.uid;
  Supabase.instance.client.auth.onAuthStateChange.listen((s) {
    final id80 = s.session?.user.id;
    if (id80 == lastUid80) return;
    lastUid80 = id80;
    sessionController.refresh().ignore();
  });
  if (Supabase.instance.client.auth.currentUser?.isAnonymous == false) {
    try {
      await PaywallService.init();
    } catch (e) {
      debugPrint("paywall init failed: $e");
    }
  }
  if (kDebugMode) {
    debugPrint(
      'TOKEN=${Supabase.instance.client.auth.currentSession?.accessToken == null ? "null" : "present"}',
    );
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: activeProfileProvider),
        ChangeNotifierProvider.value(value: sessionController),
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) => ReferenceNamesService(ctx.read<LanguageProvider>()),
        ),
      ],
      child: const SoulBoundApp(),
    ),
  );

  // Paylasilan yukleme videosunu ilk frame'den sonra arka planda hazirla.
  // await yok; acilis gecikmez, hata host icinde loglanip yutulur.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    LoadingVideoHost.instance.warmUp();
  });
}

class SoulBoundApp extends StatelessWidget {
  const SoulBoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'Ephemerai',
      debugShowCheckedModeBanner: false,
      theme: CosmicTheme.darkTheme,
      locale: languageProvider.locale,
      supportedLocales: LanguageProvider.supportedLanguages
          .map((l) => Locale(l['code']!))
          .toList(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return ColoredBox(
          color: AppColors.bgVoid,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Directionality(
                textDirection: languageProvider.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Stack(
                  fit: StackFit.expand,
                  children: [child!, const LoadingVideoLayer()],
                ),
              ),
            ),
          ),
        );
      },
      home: const _WebErr67(child: _Gate80()),
      onGenerateRoute: appOnGenerateRoute,
    );
  }
}

Route<dynamic>? appOnGenerateRoute(RouteSettings settings) {
  if (settings.name == '/onboarding') {
    final args = settings.arguments as Map<String, dynamic>?;
    final isFirstProfile = args?['isFirstProfile'] as bool? ?? true;
    return MaterialPageRoute(
      builder: (_) => OnboardingFlowPage(isFirstProfile: isFirstProfile),
    );
  }
  if (settings.name == '/profiles') {
    return MaterialPageRoute(builder: (_) => const ProfileSwitcherPage());
  }
  if (settings.name == '/onboarding/calculating') {
    final a = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => OnboardingCalculatingPage(
        setupFactory: a['setupFactory'] as Future<void> Function(),
        isFirstProfile: a['isFirstProfile'] as bool,
      ),
    );
  }
  if (settings.name == '/onboarding/first-result') {
    return MaterialPageRoute(
      builder: (_) => OnboardingFirstResultPage(
        isFirstProfile: settings.arguments as bool? ?? false,
      ),
    );
  }
  if (settings.name == '/onboarding/link-account') {
    return MaterialPageRoute(builder: (_) => const OnboardingRegisterPage());
  }
  if (settings.name == '/onboarding/email') {
    return MaterialPageRoute(builder: (_) => const OnboardingLinkAccountPage());
  }
  if (settings.name == '/signin') {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const OnboardingSignInPage(),
    );
  }
  if (settings.name == '/home') {
    return MaterialPageRoute(builder: (_) => const MainShell());
  }
  if (settings.name == '/settings') {
    return MaterialPageRoute(
      builder: (_) => const SettingsPage(),
      settings: settings,
    );
  }
  if (settings.name == '/notifications') {
    return MaterialPageRoute(
      builder: (_) => const NotificationsPage(),
      settings: settings,
    );
  }
  if (settings.name == '/streak') {
    return MaterialPageRoute(
      builder: (_) => StreakPage(profileId: settings.arguments as String),
      settings: settings,
    );
  }
  return null;
}

bool _webExists67 = false;
bool _netFail80 = false;
bool _netOpen80 = false;
bool _nfOpen80 = false;
SessionController? _ctl80;

void _readWebError67() {
  if (!kIsWeb) return;
  try {
    final q = Uri.base.queryParameters;
    if (q["error_code"] == "identity_already_exists") _webExists67 = true;
  } catch (e) {
    debugPrint("web error parse failed: $e");
  }
}

class _WebErr67 extends StatefulWidget {
  const _WebErr67({required this.child});
  final Widget child;
  @override
  State<_WebErr67> createState() => _WebErr67State();
}

class _WebErr67State extends State<_WebErr67> {
  @override
  void initState() {
    super.initState();
    if (!_webExists67) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_webExists67) return;
      _webExists67 = false;
      if (!mounted) return;
      // 90: nav70 kalkti
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(context, "onboarding.register.exists")),
          action: SnackBarAction(
            label: t(context, "onboarding.register.signin"),
            onPressed: () {
              startOAuthSignin90(
                OAuthProvider.google,
              ).catchError((Object e) {});
            },
          ),
        ),
      );
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse("/"),
        replace: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> showNotFound70(BuildContext context) async {
  if (_nfOpen80) return;
  _nfOpen80 = true;
  try {
    await _showNotFound80(context);
  } finally {
    _nfOpen80 = false;
  }
}

Future<void> _showNotFound80(BuildContext context) async {
  final yes = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(t(ctx, "auth.signin.notfound.title")),
      content: Text(t(ctx, "auth.signin.notfound.body")),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(t(ctx, "auth.signin.notfound.no")),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(t(ctx, "auth.signin.notfound.yes")),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  final nav = Navigator.of(context, rootNavigator: true);
  if (yes == true) {
    if (await _yesLink89(nav)) return;
    await _ctl80?.resolveNotFound();
    nav.popUntil((r) => r.isFirst);
    return;
  }
  final prov = context.read<ActiveProfileProvider>();
  try {
    final c = Supabase.instance.client;
    await c.auth.signOut(scope: SignOutScope.local);
    final sp84 = await SharedPreferences.getInstance();
    final tok84 = sp84.getString("guest_refresh");
    await sp84.remove("guest_refresh");
    var back84 = false;
    if (tok84 != null) {
      try {
        await c.auth.setSession(tok84);
        back84 = true;
      } catch (e) {
        debugPrint("guest restore failed: $e");
      }
    }
    if (!back84) {
      await c.auth.signInAnonymously();
      await prov.clearActive();
    }
  } catch (e) {
    debugPrint("notfound no failed: $e");
  }
  await _ctl80?.resolveNotFound();
  nav.popUntil((r) => r.isFirst);
}

Future<bool> _reachable80() async {
  try {
    await http
        .get(
          Uri.parse('${SupabaseConfig.url}/auth/v1/health'),
          headers: {'apikey': SupabaseConfig.anonKey},
        )
        .timeout(const Duration(seconds: 4));
    return true;
  } catch (e) {
    debugPrint('net check failed: $e');
    return false;
  }
}

Future<void> showNetError80(BuildContext context) async {
  if (_netOpen80) return;
  _netOpen80 = true;
  try {
    await showCosmicAlert(
      context,
      title: t(context, 'net.title'),
      message: t(context, 'net.body'),
      actions: [
        CosmicAlertAction(
          label: t(context, 'net.retry'),
          onTap: _netRetry80,
        ),
        CosmicAlertAction(
          label: t(context, 'net.logout'),
          primary: false,
          onTap: _netLogout80,
        ),
      ],
    );
  } finally {
    _netOpen80 = false;
  }
}

Future<void> _netRetry80() async {
  final c = Supabase.instance.client;
  if (c.auth.currentSession == null) {
    try {
      await c.auth.signInAnonymously();
    } catch (e) {
      debugPrint('net retry sign-in failed: $e');
    }
  }
  _netFail80 = c.auth.currentSession == null || !await _reachable80();
  try {
    await _ctl80?.refresh();
  } catch (e) {
    debugPrint('net retry refresh failed: $e');
  }
}

Future<void> _netLogout80() async {
  try {
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    await _ctl80?.profiles.clearActive();
  } catch (e) {
    debugPrint('net logout failed: $e');
  }
  await _netRetry80();
}

class _Gate80 extends StatefulWidget {
  const _Gate80();
  @override
  State<_Gate80> createState() => _Gate80State();
}

class _Gate80State extends State<_Gate80> {
  @override
  Widget build(BuildContext context) {
    final ctl = context.watch<SessionController>();
    final r = ctl.route;
    if (r == EntryRoute.notFound && !_nfOpen80) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showNotFound70(context);
      });
    }
    if ((r == EntryRoute.retry || (r == EntryRoute.loading && _netFail80)) &&
        !_netOpen80) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showNetError80(context);
      });
    }
    return switch (r) {
      EntryRoute.home => const MainShell(),
      EntryRoute.onboarding => const OnboardingFlowPage(isFirstProfile: true),
      EntryRoute.signin => const OnboardingSignInPage(),
      EntryRoute.retry => Scaffold(
        body: Center(
          child: CosmicErrorState(
            message: t(context, "settings.error.load"),
            retryLabel: t(context, "settings.retry"),
            onRetry: () => ctl.refresh(),
          ),
        ),
      ),
      EntryRoute.loading => const CosmicLoadingScreen(),
      EntryRoute.notFound => const Scaffold(backgroundColor: AppColors.bgVoid),
    };
  }
}

Future<bool> _yesLink89(NavigatorState nav) async {
  final c = Supabase.instance.client;
  final sp = await SharedPreferences.getInstance();
  final tok = sp.getString("guest_refresh");
  if (tok == null) {
    return false;
  }
  try {
    await AccountDeletionService.deleteRemoteOnly();
  } catch (e) {
    return false;
  }
  try {
    await c.auth.signOut(scope: SignOutScope.local);
    await c.auth.setSession(tok);
    await sp.remove("guest_refresh");
  } catch (e) {
    try {
      if (c.auth.currentUser == null) await c.auth.signInAnonymously();
      await _ctl80?.profiles.clearActive();
    } catch (_) {}
    return false;
  }
  await _ctl80?.resolveNotFound();
  try {
    await AccountLinkingService.linkGoogle();
  } catch (e) {
    // Hata bilerek yutuluyor.
  }
  nav.popUntil((r) => r.isFirst);
  return true;
}
