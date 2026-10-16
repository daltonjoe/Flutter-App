// Gezegen kartı görünüm modeli (Faz 5).
import '../../core/reference_ids.dart';
import '../../models/natal_chart_response.dart';
import '../../services/reference_names_service.dart';

class PlanetCardViewModel {
  const PlanetCardViewModel({
    required this.key,
    required this.name,
    required this.sign,
    required this.houseName,
    required this.houseNumber,
    required this.degree,
    required this.retrograde,
    required this.emoji,
  });

  final String key;
  final String name;
  final String sign;
  final String? houseName;
  final int? houseNumber;
  final double degree;
  final bool retrograde;
  final String emoji;

  static const List<String> _order = [
    'Sun',
    'Moon',
    'Mercury',
    'Venus',
    'Mars',
    'Jupiter',
    'Saturn',
    'Uranus',
    'Neptune',
    'Pluto',
  ];

  static const Map<String, String> _emojis = {
    'Sun': '☀️',
    'Moon': '🌙',
    'Mercury': '☿',
    'Venus': '♀',
    'Mars': '♂',
    'Jupiter': '♃',
    'Saturn': '♄',
    'Uranus': '♅',
    'Neptune': '♆',
    'Pluto': '♇',
  };

  static List<PlanetCardViewModel> fromChart(
    NatalChartResponse chart,
    ReferenceNamesService names,
  ) {
    final birthTimeKnown = chart.input?.birthTimeKnown == true;
    final planets = chart.planets ?? const <String, PlanetData>{};
    final items = <PlanetCardViewModel>[];
    for (final key in _order) {
      if (!birthTimeKnown && key == 'Moon') continue;
      final data = planets[key];
      if (data == null) continue;
      final houseName = (birthTimeKnown && data.house > 0)
          ? names.house(data.house)
          : null;
      items.add(
        PlanetCardViewModel(
          key: key,
          name: names.planet(RefIds.planets[key] ?? 0),
          sign: names.sign(data.signIndex + 1),
          houseName: houseName,
          houseNumber: (birthTimeKnown && data.house > 0) ? data.house : null,
          degree: data.degreeInSign,
          retrograde: data.retrograde,
          emoji: _emojis[key] ?? '✦',
        ),
      );
    }
    return items;
  }
}
