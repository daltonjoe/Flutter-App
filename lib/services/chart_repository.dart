import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/reference_ids.dart';
import '../models/natal_chart_response.dart';

class ChartRepository {
  static const _signs = [
    'Koç',
    'Boğa',
    'İkizler',
    'Yengeç',
    'Aslan',
    'Başak',
    'Terazi',
    'Akrep',
    'Yay',
    'Oğlak',
    'Kova',
    'Balık',
  ];

  static const _aspectNames = {
    0: 'Kavuşum',
    60: 'Sekstil',
    90: 'Kare',
    120: 'Üçgen',
    180: 'Karşıt',
  };

  static Future<({NatalChartResponse chart, String name})> load(
    String profileId,
  ) async {
    final client = Supabase.instance.client;
    final planetNames = {
      for (final entry in RefIds.planets.entries) entry.value: entry.key,
    };
    final aspectAngles = {
      for (final entry in RefIds.aspectByAngle.entries) entry.value: entry.key,
    };

    final profileFuture = client
        .from('user_profiles')
        .select(
          'display_name, sun_sign_id, moon_sign_id, ascendant_sign_id, '
          'birth_date, birth_time, birth_city, latitude, longitude, timezone',
        )
        .eq('id', profileId)
        .single();
    final housesFuture = client
        .from('user_chart_houses')
        .select('house_id, cusp_degree, sign_id')
        .eq('profile_id', profileId);
    final placementsFuture = client
        .from('user_chart_placements')
        .select(
          'planet_id, sign_id, house_id, longitude_degree, '
          'latitude_degree, retrograde',
        )
        .eq('profile_id', profileId);
    final aspectsFuture = client
        .from('user_chart_aspects')
        .select(
          'planet_a_id, planet_b_id, aspect_type_id, exact_angle, orb, applying',
        )
        .eq('profile_id', profileId);

    final results = await Future.wait<dynamic>([
      profileFuture,
      housesFuture,
      placementsFuture,
      aspectsFuture,
    ]);
    final profile = Map<String, dynamic>.from(results[0] as Map);
    final houseRows = List<Map<String, dynamic>>.from(results[1] as List);
    final placementRows = List<Map<String, dynamic>>.from(results[2] as List);
    final aspectRows = List<Map<String, dynamic>>.from(results[3] as List);

    final houses = <String, HouseData>{};
    for (final row in houseRows) {
      final houseNumber = _int(row['house_id']);
      final longitude = _double(row['cusp_degree']);
      final signIndex = _signIndex(row['sign_id']);
      houses['house_$houseNumber'] = HouseData(
        sign: _signName(signIndex),
        cuspDegree: longitude,
        signIndex: signIndex,
        longitude: longitude,
        degreeInSign: longitude % 30,
        houseNumber: houseNumber,
      );
    }

    final planets = <String, PlanetData>{};
    for (final row in placementRows) {
      final planetName = planetNames[_int(row['planet_id'])];
      if (planetName == null) continue;
      final longitude = _double(row['longitude_degree']);
      final signIndex = _signIndex(row['sign_id']);
      final house = _int(row['house_id']);
      planets[planetName] = PlanetData(
        sign: _signName(signIndex),
        signIndex: signIndex,
        longitude: longitude,
        latitude: _double(row['latitude_degree']),
        degreeInSign: longitude % 30,
        house: house,
        houseNumber: house,
        retrograde: row['retrograde'] == true,
      );
    }

    final aspects = <AspectData>[];
    for (final row in aspectRows) {
      final planet1 = planetNames[_int(row['planet_a_id'])];
      final planet2 = planetNames[_int(row['planet_b_id'])];
      final angle = aspectAngles[_int(row['aspect_type_id'])];
      if (planet1 == null || planet2 == null || angle == null) continue;
      aspects.add(
        AspectData(
          planet1: planet1,
          aspect: _aspectNames[angle] ?? angle.toString(),
          planet2: planet2,
          angle: angle,
          actualAngle: _double(row['exact_angle']),
          orb: _double(row['orb']),
          applying: row['applying'] == true,
          isMajor: true,
        ),
      );
    }

    final elementDistribution = <String, int>{
      'Ateş': 0,
      'Toprak': 0,
      'Hava': 0,
      'Su': 0,
    };
    for (final planet in planets.values) {
      final element = _elementForSign(planet.signIndex);
      elementDistribution[element] = elementDistribution[element]! + 1;
    }

    final retrogradePlanets = planets.entries
        .where((entry) => entry.value.retrograde)
        .map((entry) => entry.key)
        .toList();
    final birthDate = profile['birth_date']?.toString() ?? '';
    final birthTime = profile['birth_time']?.toString() ?? '';
    final birthCity = profile['birth_city']?.toString() ?? '';
    final latitude = _double(profile['latitude']);
    final longitude = _double(profile['longitude']);
    final timezone = profile['timezone']?.toString() ?? '';
    final chart = NatalChartResponse(
      status: 'success',
      requestId: profileId,
      input: ChartInput(
        birthDate: birthDate,
        birthTimeLocal: birthTime,
        // The persisted profile stores local birth time only.
        birthTimeUtc: birthTime,
        julianDay: 0.0,
      ),
      location: ChartLocation(
        cityQuery: birthCity,
        cityResolved: birthCity,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
        utcOffset: '',
      ),
      summary: ChartSummary(
        sunSign: _signName(_signIndex(profile['sun_sign_id'])),
        moonSign: _signName(_signIndex(profile['moon_sign_id'])),
        ascendantSign: _signName(_signIndex(profile['ascendant_sign_id'])),
        elementDistribution: elementDistribution,
        retrogradePlanets: retrogradePlanets,
      ),
      planets: planets,
      aspects: aspects,
      houses: houses,
      angles: null,
    );
    return (chart: chart, name: profile['display_name']?.toString() ?? '');
  }

  static int _int(dynamic value) => (value as num?)?.toInt() ?? 0;

  static double _double(dynamic value) => (value as num?)?.toDouble() ?? 0;

  static int _signIndex(dynamic signId) {
    final index = _int(signId) - 1;
    return index >= 0 && index < _signs.length ? index : 0;
  }

  static String _signName(int signIndex) =>
      signIndex >= 0 && signIndex < _signs.length
      ? _signs[signIndex]
      : _signs[0];

  static String _elementForSign(int signIndex) {
    if ([0, 4, 8].contains(signIndex)) return 'Ateş';
    if ([1, 5, 9].contains(signIndex)) return 'Toprak';
    if ([2, 6, 10].contains(signIndex)) return 'Hava';
    return 'Su';
  }
}
