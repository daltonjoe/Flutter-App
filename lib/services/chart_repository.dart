import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/reference_ids.dart';
import '../models/natal_chart_response.dart';
import 'reference_names_service.dart';

class ChartRepository {
  static Future<({NatalChartResponse chart, String name})> load(
    String profileId,
  ) async {
    final names = await ReferenceNamesService.waitForInstance();
    await names.ensureLoaded();
    final client = Supabase.instance.client;
    final aspectAngles = {
      for (final entry in RefIds.aspectByAngle.entries) entry.value: entry.key,
    };

    final profileFuture = client
        .from('user_profiles')
        .select(
          'display_name, sun_sign_id, moon_sign_id, ascendant_sign_id, '
          'birth_date, birth_time, birth_time_known, mc_degree, mc_sign_id, '
          'birth_city, latitude, longitude, timezone, locale',
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
        sign: names.sign(RefIds.signId(signIndex)),
        cuspDegree: longitude,
        signIndex: signIndex,
        longitude: longitude,
        degreeInSign: longitude % 30,
        houseNumber: houseNumber,
      );
    }

    final planets = <String, PlanetData>{};
    for (final row in placementRows) {
      final planetId = _int(row['planet_id']);
      final planetName = _planetKey(planetId);
      if (planetName == null) continue;
      final longitude = _double(row['longitude_degree']);
      final signIndex = _signIndex(row['sign_id']);
      final house = _int(row['house_id']);
      planets[planetName] = PlanetData(
        sign: names.sign(RefIds.signId(signIndex)),
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
      final planet1 = _planetKey(_int(row['planet_a_id']));
      final planet2 = _planetKey(_int(row['planet_b_id']));
      final angle = aspectAngles[_int(row['aspect_type_id'])];
      if (planet1 == null || planet2 == null || angle == null) continue;
      aspects.add(
        AspectData(
          planet1: planet1,
          aspect: names.aspect(RefIds.aspectId(angle) ?? _int(row['aspect_type_id'])),
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
      'fire': 0,
      'earth': 0,
      'air': 0,
      'water': 0,
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
    final birthTimeKnown = profile['birth_time_known'] != false;
    final firstHouse = houses['house_1'];
    final mcDegree = profile['mc_degree'] == null
        ? null
        : _double(profile['mc_degree']);
    final angles = mcDegree == null ||
            profile['mc_sign_id'] == null ||
            firstHouse == null
        ? null
        : ChartAngles(
            ascSign: firstHouse.sign,
            ascDegree: firstHouse.degreeInSign,
            mcSign: names.sign(RefIds.signId(_signIndex(profile['mc_sign_id']))),
            mcDegree: mcDegree % 30,
          );
    final chart = NatalChartResponse(
      status: 'success',
      requestId: profileId,
      input: ChartInput(
        birthDate: birthDate,
        birthTimeLocal: birthTimeKnown ? birthTime : '',
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
        sunSign: names.sign(RefIds.signId(_signIndex(profile['sun_sign_id']))),
        moonSign: names.sign(RefIds.signId(_signIndex(profile['moon_sign_id']))),
        ascendantSign: names.sign(
          RefIds.signId(
          _signIndex(profile['ascendant_sign_id']),
          ),
        ),
        elementDistribution: elementDistribution,
        retrogradePlanets: retrogradePlanets,
      ),
      planets: planets,
      aspects: aspects,
      houses: houses,
      angles: angles,
    );
    return (chart: chart, name: profile['display_name']?.toString() ?? '');
  }

  static int _int(dynamic value) => (value as num?)?.toInt() ?? 0;

  static double _double(dynamic value) => (value as num?)?.toDouble() ?? 0;

  static int _signIndex(dynamic signId) {
    return _int(signId) - 1;
  }

  static String? _planetKey(int id) {
    for (final entry in RefIds.planets.entries) {
      if (entry.value == id) return entry.key;
    }
    return null;
  }

  static String _elementForSign(int signIndex) {
    if ([0, 4, 8].contains(signIndex)) return 'fire';
    if ([1, 5, 9].contains(signIndex)) return 'earth';
    if ([2, 6, 10].contains(signIndex)) return 'air';
    return 'water';
  }
}
