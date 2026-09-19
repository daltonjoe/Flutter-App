import 'package:supabase_flutter/supabase_flutter.dart';

class PlacementContent {
  final String placementType;
  final String themeCode;
  final int themeOrder;
  final String title;
  final String? shortDescription;
  final String? content;
  final List<String> keywords;
  final List<String> strengths;
  final List<String> challenges;

  PlacementContent({
    required this.placementType,
    required this.themeCode,
    required this.themeOrder,
    required this.title,
    this.shortDescription,
    this.content,
    required this.keywords,
    required this.strengths,
    required this.challenges,
  });

  static List<String> _list(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : [];

  factory PlacementContent.fromJson(Map<String, dynamic> j) {
    final theme = j['content_themes'] as Map<String, dynamic>?;
    return PlacementContent(
      placementType: j['placement_type'] ?? '',
      themeCode: theme?['code'] ?? '',
      themeOrder: (theme?['sort_order'] as num?)?.toInt() ?? 0,
      title: j['title'] ?? '',
      shortDescription: j['short_description'],
      content: j['content'],
      keywords: _list(j['keywords']),
      strengths: _list(j['strengths']),
      challenges: _list(j['challenges']),
    );
  }
}

class PlacementContentService {
  static final _db = Supabase.instance.client;

  static const _locales = {'tr', 'en', 'de', 'es', 'fr'};

  static const _signCodes = {
  'Koç': 'aries', 'Boğa': 'taurus', 'İkizler': 'gemini', 'Yengeç': 'cancer',
  'Aslan': 'leo', 'Başak': 'virgo', 'Terazi': 'libra', 'Akrep': 'scorpio',
  'Yay': 'sagittarius', 'Oğlak': 'capricorn', 'Kova': 'aquarius', 'Balık': 'pisces',
    };

  /// placements: {'sun': sunSign, 'moon': moonSign, 'ascendant': ascSign}
  static Future<Map<String, List<PlacementContent>>> fetch({
    required Map<String, String> placements,
    required String locale,
  }) async {
    final result = <String, List<PlacementContent>>{};
    for (final e in placements.entries) {
      final rows = await _db
          .from('placement_sign_theme_content')
          .select(
              'placement_type,title,short_description,content,keywords,strengths,challenges,'
              'content_themes(code,sort_order),zodiac_signs!inner(code)')
          .eq('placement_type', e.key)
          .eq('locale', _locales.contains(locale) ? locale : 'en')
          .eq('is_active', true)
          .eq('zodiac_signs.code', _signCodes[e.value] ?? e.value.toLowerCase());
      result[e.key] = rows
          .map<PlacementContent>((r) => PlacementContent.fromJson(r))
          .toList()
        ..sort((a, b) => a.themeOrder.compareTo(b.themeOrder));
    }
    return result;
  }
}