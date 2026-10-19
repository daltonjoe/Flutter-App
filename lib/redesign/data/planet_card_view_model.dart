// Gezegen kartı görünüm modeli (Faz 5).
import '../../core/reference_ids.dart';
import '../../models/natal_chart_response.dart';
import '../../services/reference_names_service.dart';

class PlanetCardViewModel {
  const PlanetCardViewModel({
    required this.key,
    required this.name,
    required this.sign,
    required this.signIndex,
    required this.houseName,
    required this.houseNumber,
    required this.degree,
    required this.retrograde,
  });

  final String key;
  final String name;
  final String sign;

  /// Burç indeksi (0 tabanlı): 0 = Koç … 11 = Balık.
  final int signIndex;

  final String? houseName;
  final int? houseNumber;
  final double degree;
  final bool retrograde;

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
          signIndex: data.signIndex,
          houseName: houseName,
          houseNumber: (birthTimeKnown && data.house > 0) ? data.house : null,
          degree: data.degreeInSign,
          retrograde: data.retrograde,
        ),
      );
    }
    return items;
  }

  /// Dereceyi "12°36′" biçiminde döndürür (derece + dakika).
  ///
  /// Dakika sade tamsayı olarak yazılır (0 ile doldurulmaz). 59.5′ ve üstü
  /// yuvarlamada bir üst dereceye taşınır; sonuç 30°'yi geçmez.
  static String formatDegree(double d) {
    var deg = d.floor();
    var min = ((d - deg) * 60).round();
    if (min >= 60) {
      min -= 60;
      deg += 1;
    }
    if (deg >= 30) {
      deg = 30;
      min = 0;
    }
    return '$deg°$min′';
  }
}
