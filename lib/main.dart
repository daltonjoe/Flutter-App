// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
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
import 'screens/onboarding/onboarding_consent_page.dart';
import 'screens/onboarding/onboarding_sign_in_page.dart';
import 'screens/onboarding/onboarding_calculating_page.dart';
import 'screens/onboarding/onboarding_first_result_page.dart';
import 'screens/main_shell.dart';
import 'screens/settings_page.dart';
import 'screens/streak_page.dart';
import 'services/account_deletion_service.dart';
import 'services/account_linking_service.dart';
import "package:flutter_application/paywall/paywall_service.dart";
import "package:flutter_application/diag68.dart";
import "package:shared_preferences/shared_preferences.dart";
import "session/resolve_entry.dart";
import "session/session_controller.dart";
import "session/supabase_session_source.dart";
import "presentation/widgets/components/cosmic_loader.dart";
import "presentation/widgets/components/cosmic_error_state.dart";
import "redesign/splash/loading_video_host.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final languageProvider = LanguageProvider();
  await languageProvider.loadSavedLocale();
  final activeProfileProvider = ActiveProfileProvider();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgDeep,
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
  debugPrint('TOKEN=${Supabase.instance.client.auth.currentSession?.accessToken}');
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
      theme: AppTheme.dark,
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
                child: child!,
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
    if (settings.name == '/onboarding/consent') {
      return MaterialPageRoute(builder: (_) => const OnboardingConsentPage());
    }
    if (settings.name == '/signin') {
      return MaterialPageRoute(settings: settings, builder: (_) => const OnboardingSignInPage());
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
  if (settings.name == '/streak') {
    return MaterialPageRoute(
      builder: (_) => StreakPage(profileId: settings.arguments as String),
      settings: settings,
    );
  }
  return null;
}

bool _webExists67 = false;
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
      diag68("web exists snackbar", "shown");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(context, "onboarding.register.exists")),
          action: SnackBarAction(
            label: t(context, "onboarding.register.signin"),
            onPressed: () {
              diag68("web exists signin direct");
              startOAuthSignin90(OAuthProvider.google).catchError((Object e) {
                diag68("web exists signin ERR", "${e.runtimeType}");
              });
            },
          ),
        ),
      );
      SystemNavigator.routeInformationUpdated(uri: Uri.parse("/"), replace: true);
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
  diag68("notfound shown");
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
    diag68("notfound yes");
    if (await _yesLink89(nav)) return;
    await _ctl80?.resolveNotFound();
    nav.popUntil((r) => r.isFirst);
    return;
  }
  diag68("notfound no");
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
    diag68("notfound guest", "restored=$back84");
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
    return switch (r) {
      EntryRoute.home => const MainShell(),
      EntryRoute.consent => const OnboardingConsentPage(),
      EntryRoute.language => const OnboardingFlowPage(isFirstProfile: true),
      EntryRoute.name => const OnboardingFlowPage(
        isFirstProfile: true,
        skipLanguage: true,
      ),
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
      EntryRoute.notFound => const Scaffold(backgroundColor: Colors.black),
    };
  }
}

Future<bool> _yesLink89(NavigatorState nav) async {
  diag68("notfound yes link start");
  final c = Supabase.instance.client;
  final sp = await SharedPreferences.getInstance();
  final tok = sp.getString("guest_refresh");
  if (tok == null) {
    diag68("link ERR step=notoken");
    return false;
  }
  try {
    await AccountDeletionService.deleteRemoteOnly();
    diag68("link del ok");
  } catch (e) {
    diag68("link ERR step=delete", "${e.runtimeType}");
    return false;
  }
  try {
    await c.auth.signOut(scope: SignOutScope.local);
    await c.auth.setSession(tok);
    await sp.remove("guest_refresh");
    diag68("link restored=true");
  } catch (e) {
    diag68("link ERR step=restore", "${e.runtimeType}");
    try {
      if (c.auth.currentUser == null) await c.auth.signInAnonymously();
      await _ctl80?.profiles.clearActive();
    } catch (_) {}
    return false;
  }
  await _ctl80?.resolveNotFound();
  try {
    diag68("link google start");
    await AccountLinkingService.linkGoogle();
  } catch (e) {
    diag68("link ERR step=link", "${e.runtimeType}");
  }
  nav.popUntil((r) => r.isFirst);
  return true;
}
