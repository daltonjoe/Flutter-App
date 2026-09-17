import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const List<Map<String, String>> supportedLanguages = [
    {"code": "tr", "label": "Türkçe", "flag": "🇹🇷"},
    {"code": "en", "label": "English", "flag": "🇬🇧"},
    {"code": "ar", "label": "العربية", "flag": "🇸🇦"},
    {"code": "de", "label": "Deutsch", "flag": "🇩🇪"},
    {"code": "es", "label": "Español", "flag": "🇪🇸"},
    {"code": "fr", "label": "Français", "flag": "🇫🇷"},
    {"code": "pt", "label": "Português", "flag": "🇧🇷"},
  ];

  Locale _locale = const Locale('tr');
  bool _isLoading = false;
  static const String _prefKey = 'selected_language';

  LanguageProvider();

  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  bool get isRtl => _locale.languageCode == 'ar';

  Future<void> loadSavedLocale() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_prefKey) ?? 'tr';
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
    _isLoading = false;
    notifyListeners();
  }
}
