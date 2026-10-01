import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/language_provider.dart';

class ReferenceNamesService extends ChangeNotifier {
  ReferenceNamesService(this._languageProvider) {
    _instance = this;
    _languageProvider.addListener(_onLanguageChanged);
    _loadFuture = _load(_languageProvider.locale.languageCode);
  }

  final LanguageProvider _languageProvider;
  static ReferenceNamesService? _instance;
  Future<void>? _loadFuture;
  final Map<int, String> _planets = {};
  final Map<int, String> _aspects = {};
  final Map<int, String> _houses = {};
  final Map<int, String> _signs = {};
  String? _loadedLocale;
  bool _loading = false;

  String planet(int id) => _planets[id] ?? id.toString();

  String aspect(int id) => _aspects[id] ?? id.toString();

  String house(int id) => _houses[id] ?? id.toString();

  String sign(int id) => _signs[id] ?? id.toString();

  String get localeCode => _languageProvider.locale.languageCode;

  static ReferenceNamesService get instance {
    final value = _instance;
    if (value == null) {
      throw StateError('ReferenceNamesService is not initialized');
    }
    return value;
  }

  /// Servis henüz oluşmadıysa (lazy provider) kısa süre bekler.
  static Future<ReferenceNamesService> waitForInstance() async {
    for (var i = 0; i < 50; i++) {
      final value = _instance;
      if (value != null) return value;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return instance; // 5 sn sonra hâlâ yoksa net hata fırlatır
  }

  Future<void> loadLocale(String locale) => _loadFuture = _load(locale);

  /// Cache hazır olana kadar bekler. _load hataları yutuyor, throw etmez.
  Future<void> ensureLoaded() async {
    final f = _loadFuture;
    if (f != null) await f;
  }

  void _onLanguageChanged() {
    final locale = _languageProvider.locale.languageCode;
    if (locale != _loadedLocale && !_loading) {
      _loadFuture = _load(locale);
    }
  }

  Future<void> _load(String locale) async {
    _loading = true;
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _loadTable(client, 'celestial_body_translations', locale),
        _loadTable(client, 'aspect_type_translations', locale),
        _loadTable(client, 'astrological_house_translations', locale),
        _loadTable(client, 'zodiac_sign_translations', locale),
      ]);

      _replace(_planets, results[0]);
      _replace(_aspects, results[1]);
      _replace(_houses, results[2]);
      _replace(_signs, results[3]);
      _loadedLocale = locale;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Reference name translations failed for $locale: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _loading = false;
    }
  }

  Future<List<Map<String, dynamic>>> _loadTable(
    SupabaseClient client,
    String table,
    String locale,
  ) async {
    final localized = await client
        .from(table)
        .select('*')
        .eq('locale', locale);
    if (localized.isNotEmpty || locale == 'en') {
      return List<Map<String, dynamic>>.from(localized);
    }
    final fallback = await client
        .from(table)
        .select('*')
        .eq('locale', 'en');
    return List<Map<String, dynamic>>.from(fallback);
  }

  void _replace(Map<int, String> target, List<Map<String, dynamic>> rows) {
    target
      ..clear()
      ..addEntries(
        rows
            .map((row) {
              final id = _id(row);
              final name = _name(row);
              return id == null || name == null
                  ? null
                  : MapEntry(id, name);
            })
            .whereType<MapEntry<int, String>>(),
      );
  }

  int? _id(Map<String, dynamic> row) {
    for (final key in [
      'body_id',
      'aspect_type_id',
      'house_id',
      'sign_id',
    ]) {
      final value = row[key];
      if (value is num) return value.toInt();
    }
    return null;
  }

  String? _name(Map<String, dynamic> row) {
    for (final key in ['name', 'label', 'translation', 'display_name']) {
      final value = row[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  @override
  void dispose() {
    _languageProvider.removeListener(_onLanguageChanged);
    super.dispose();
  }
}