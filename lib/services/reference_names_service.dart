import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/language_provider.dart';

class ReferenceNamesService extends ChangeNotifier {
  ReferenceNamesService(this._languageProvider) {
    _instance = this;
    _languageProvider.addListener(_onLanguageChanged);
    unawaited(_load(_languageProvider.locale.languageCode));
  }

  final LanguageProvider _languageProvider;
  static ReferenceNamesService? _instance;
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

  Future<void> loadLocale(String locale) => _load(locale);

  void _onLanguageChanged() {
    final locale = _languageProvider.locale.languageCode;
    if (locale != _loadedLocale && !_loading) {
      unawaited(_load(locale));
    }
  }

  Future<void> _load(String locale) async {
    _loading = true;
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _loadTable(client, 'celestial_body_translations', 'celestial_body_id', locale),
        _loadTable(client, 'aspect_type_translations', 'aspect_type_id', locale),
        _loadTable(client, 'astrological_house_translations', 'astrological_house_id', locale),
        _loadTable(client, 'zodiac_sign_translations', 'zodiac_sign_id', locale),
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
    String idColumn,
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
      'celestial_body_id',
      'aspect_type_id',
      'astrological_house_id',
      'zodiac_sign_id',
      'body_id',
      'house_id',
      'id',
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
