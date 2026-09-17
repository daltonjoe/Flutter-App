// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/create_profile_page.dart';
import 'screens/chart_page.dart';
import 'models/natal_chart_response.dart';
import 'providers/language_provider.dart';
import 'i18n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final languageProvider = LanguageProvider();
  await languageProvider.loadSavedLocale();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgDeep,
    ),
  );

  runApp(
    ChangeNotifierProvider.value(
      value: languageProvider,
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
        return Directionality(
          textDirection: languageProvider.isRtl
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },
      home: const CreateProfilePage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/chart') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ChartPage(
              chartData: args['chartData'] as NatalChartResponse,
              userName: args['userName'] as String,
            ),
          );
        }
        return null;
      },
    );
  }
}
