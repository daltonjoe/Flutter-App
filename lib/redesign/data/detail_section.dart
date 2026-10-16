// Detay bölümü modeli (Faz 7a). İki eski sayfanın satır tiplerini tek tipe çevirir.
import '../../services/placement_content_service.dart';

class DetailSection {
  const DetailSection({
    required this.themeCode,
    required this.themeOrder,
    required this.title,
    required this.shortDescription,
    required this.content,
    required this.keywords,
    required this.strengths,
    required this.challenges,
  });

  final String themeCode;
  final int themeOrder;
  final String title;
  final String? shortDescription;
  final String? content;
  final List<String> keywords;
  final List<String> strengths;
  final List<String> challenges;

  factory DetailSection.fromPlacement(PlacementContent c) => DetailSection(
    themeCode: c.themeCode,
    themeOrder: c.themeOrder,
    title: c.title,
    shortDescription: c.shortDescription,
    content: c.content,
    keywords: c.keywords,
    strengths: c.strengths,
    challenges: c.challenges,
  );

  /// placement_content satırı: title, content, strengths, challenges,
  /// content_themes{code, sort_order}. Eksik anahtarlar boş/null olur.
  factory DetailSection.fromPlanetRow(Map<String, dynamic> row) {
    final theme = row['content_themes'] as Map<String, dynamic>?;
    return DetailSection(
      themeCode: theme?['code'] as String? ?? '',
      themeOrder: (theme?['sort_order'] as num?)?.toInt() ?? 0,
      title: row['title'] as String? ?? '',
      shortDescription: row['short_description'] as String?,
      content: row['content'] as String?,
      keywords: _list(row['keywords']),
      strengths: _list(row['strengths']),
      challenges: _list(row['challenges']),
    );
  }

  static List<String> _list(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : const <String>[];
}
