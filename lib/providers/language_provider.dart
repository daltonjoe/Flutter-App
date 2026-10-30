import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Picks the app locale: saved choice if supported, else device language
/// (language part only) if supported, else 'en'.
String pickLocaleCode(
  String? saved,
  String deviceCode,
  Iterable<String> supported,
) {
  if (saved != null && supported.contains(saved)) return saved;
  final device = deviceCode.toLowerCase().split(RegExp(r'[_-]')).first;
  if (supported.contains(device)) return device;
  return 'en';
}

class LanguageProvider extends ChangeNotifier {
  static const List<Map<String, String>> supportedLanguages = [
    {"code": "tr", "label": "Türkçe", "flag": "🇹🇷"},
    {"code": "en", "label": "English", "flag": "🇬🇧"},
    {"code": "ar", "label": "العربية", "flag": "🇸🇦"},
    {"code": "de", "label": "Deutsch", "flag": "🇩🇪"},
    {"code": "es", "label": "Español", "flag": "🇪🇸"},
    {"code": "fr", "label": "Français", "flag": "🇫🇷"},
    {"code": "pt", "label": "Português", "flag": "🇧🇷"},
    {"code": "it", "label": "Italiano", "flag": "🇮🇹"},
  ];

  Locale _locale = const Locale('tr');
  bool _chosen = false;
  bool _isLoading = false;
  static const String _prefKey = 'selected_language';

  LanguageProvider();

  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  bool get isRtl => _locale.languageCode == 'ar';
  bool get chosen => _chosen;

  Future<void> loadSavedLocale() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    _chosen = saved != null;
    final langCode = pickLocaleCode(
      saved,
      PlatformDispatcher.instance.locale.languageCode,
      supportedLanguages.map((l) => l['code']!),
    );
    _locale = Locale(langCode);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLocale(String langCode) async {
    _isLoading = true;
    notifyListeners();
    _locale = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, langCode);
    _chosen = true;
    _isLoading = false;
    notifyListeners();
  }
}
