// lib/main.dart
import 'package:flutter/material.dart';
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
import 'core/config/supabase_config.dart';
import 'screens/onboarding/onboarding_link_account_page.dart';
import 'screens/onboarding/onboarding_calculating_page.dart';
import 'screens/onboarding/onboarding_first_result_page.dart';
import 'screens/main_shell.dart';
import 'screens/settings_page.dart';
import 'services/account_deletion_service.dart';


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
      title: 'SoulBound',
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
          home: context.watch<ActiveProfileProvider>().activeProfileId != null
          ? const MainShell()
          : const OnboardingFlowPage(isFirstProfile: true),
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
    return MaterialPageRoute(builder: (_) => const OnboardingLinkAccountPage());
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
  return null;
}