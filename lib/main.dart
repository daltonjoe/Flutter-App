// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/chart_page.dart';
import 'models/natal_chart_response.dart';
import 'providers/language_provider.dart';
import 'providers/active_profile_provider.dart';
import 'services/reference_names_service.dart';
import 'i18n/app_localizations.dart';
import 'screens/onboarding/onboarding_flow_page.dart';
import 'screens/profile_switcher_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import "package:flutter_application/paywall/paywall_service.dart";

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
  await _restoreAccount67(activeProfileProvider);
if (kDebugMode) {
  debugPrint('TOKEN=${Supabase.instance.client.auth.currentSession?.accessToken}');
}
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: activeProfileProvider),
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) => ReferenceNamesService(ctx.read<LanguageProvider>()),
        ),
      ],
      child: const SoulBoundApp(),
    ),
  );
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
          color: Colors.black,
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
      home: _WebErr67(child: _startConsent67
          ? const OnboardingConsentPage()
          : context.watch<ActiveProfileProvider>().activeProfileId != null
          ? const MainShell()
          : const OnboardingFlowPage(isFirstProfile: true)),
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
      return MaterialPageRoute(builder: (_) => const OnboardingSignInPage());
  }
  if (settings.name == '/home') {
    return MaterialPageRoute(builder: (_) => const MainShell());
  }
  if (settings.name == '/chart') {
    final args = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => ChartPage(
        chartData: args['chartData'] as NatalChartResponse,
        userName: args['userName'] as String,
      ),
    );
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

bool _startConsent67 = false;

bool _webExists67 = false;

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, "onboarding.register.exists"))),
      );
      SystemNavigator.routeInformationUpdated(uri: Uri.parse("/"), replace: true);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> _restoreAccount67(ActiveProfileProvider prov) async {
  try {
    final c = Supabase.instance.client;
    final u = c.auth.currentUser;
    if (u == null || u.isAnonymous) return;
    final rows = await c.from("user_profiles").select("id").order("created_at");
    final ids = rows.map((r) => r["id"] as String).toList();
    if (ids.isEmpty) {
      await prov.clearActive();
      return;
    }
    if (prov.activeProfileId == null || !ids.contains(prov.activeProfileId)) {
      await prov.setActive(ids.first);
    }
    try {
      await PaywallService.init();
    } catch (e) {
      debugPrint("paywall init failed: $e");
    }
    final cons = await c
        .from("user_consents")
        .select("kind")
        .inFilter("kind", ["privacy", "terms", "ai"]);
    final k = cons.map((r) => r["kind"]).toSet();
    _startConsent67 = !(k.contains("privacy") && k.contains("terms") && k.contains("ai"));
    final sp67 = await SharedPreferences.getInstance();
    if (sp67.getBool("force_consent") == true) _startConsent67 = true;
  } catch (e) {
    debugPrint("restore account failed: $e");
  }
}
