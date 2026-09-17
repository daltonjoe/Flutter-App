import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils/number_utils.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;
  bool isRtl = false;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString(
      'locales/${locale.languageCode}.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    isRtl = (locale.languageCode == "ar");

    return true;
  }

  String translate(String key, {Map<String, String>? args}) {
    String translation = _localizedStrings[key] ?? key;
    if (args != null) {
      args.forEach((key, value) {
        translation = translation.replaceAll('{$key}', value);
      });
    }

    // Localize numbers for Arabic
    return NumberUtils.localize(translation, locale.languageCode);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return [
      'tr',
      'en',
      'ar',
      'de',
      'es',
      'fr',
      'pt',
    ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Global helper function for easier access
String t(BuildContext context, String key, {Map<String, String>? args}) {
  return AppLocalizations.of(context)?.translate(key, args: args) ?? key;
}
