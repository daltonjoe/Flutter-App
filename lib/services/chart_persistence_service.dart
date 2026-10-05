import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/reference_ids.dart';
import '../models/natal_chart_response.dart';
import '../models/onboarding_data.dart';
import 'astro_service.dart';

class ChartPersistenceService {
  static Future<String> saveChart({
    required OnboardingData data,
    required NatalChartResponse chart,
    required String locale,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('NO_SESSION');
    }

 if (!chart.isSuccess) {
      throw Exception(chart.message ?? 'unknown_error');
    }
    final planets = chart.planets;
    final houses = chart.houses;
    final sun = planets?['Sun'];
    final moon = planets?['Moon'];
    final firstHouse = houses?['house_1'];
    final mcLongitude = data.birthTimeKnown ? _mcLongitude(chart.angles) : null;
    if (data.name == null ||
        data.birthDate == null ||
        data.birthTime == null ||
        data.city == null ||
        sun == null ||
        moon == null ||
        (data.birthTimeKnown && firstHouse == null)) {
      throw Exception('MISSING_CHART_DATA');
    }

    final client = Supabase.instance.client;
    final profile = await client
        .from('user_profiles')
        .insert({
          'user_id': userId,
          'display_name': data.name,
          'gender': data.gender,
          'relationship_status': data.relationshipStatus,
          'birth_date': _formatDate(data.birthDate!),
          'birth_time': _formatTime(data.birthTime!),
          'birth_time_known': data.birthTimeKnown,
          'birth_city': data.city!.city,
          'latitude': data.city!.latitude,
          'longitude': data.city!.longitude,
          'timezone': data.city!.timezone,
          'locale': locale,
          'sun_sign_id': RefIds.signId(sun.signIndex),
          'moon_sign_id': RefIds.signId(moon.signIndex),
          'ascendant_sign_id': data.birthTimeKnown
              ? RefIds.signId(firstHouse!.signIndex)
              : null,
          'mc_degree': mcLongitude,
          'mc_sign_id': mcLongitude == null
              ? null
              : RefIds.signId((mcLongitude / 30).floor()),
        })
        .select('id')
        .single();

    final profileId = profile['id'] as String;
    try {
      final houseRows = _buildHouseRows(
        profileId,
        houses,
        birthTimeKnown: data.birthTimeKnown,
      );
      if (houseRows.isNotEmpty) {
        await client
            .from('user_chart_houses')
            .upsert(houseRows, onConflict: 'profile_id,house_id');
      }

      final placementRows = _buildPlacementRows(
        profileId,
        planets,
        birthTimeKnown: data.birthTimeKnown,
      );
      await client
          .from('user_chart_placements')
          .upsert(placementRows, onConflict: 'profile_id,planet_id');

      final aspectRows = _buildAspectRows(profileId, chart.aspects);
      if (aspectRows.isNotEmpty) {
        await client
            .from('user_chart_aspects')
            .upsert(
              aspectRows,
              onConflict: 'profile_id,planet_a_id,planet_b_id,aspect_type_id',
            );
      }
    } catch (_) {
      try {
        await client.from('user_profiles').delete().eq('id', profileId);
      } catch (cleanupError) {
        debugPrint(
          'Failed to delete profile after chart save error: $cleanupError',
        );
      }
      rethrow;
    }

    return profileId;
  }

  static Future<void> addBirthTime({
    required String profileId,
    required TimeOfDay time,
    required String locale,
  }) async {
    final client = Supabase.instance.client;
    final row = await client
        .from('user_profiles')
        .select(
          'birth_date, birth_city, latitude, longitude, timezone, birth_time_known',
        )
        .eq('id', profileId)
        .maybeSingle();
    if (row == null) {
      throw Exception('PROFILE_NOT_FOUND');
    }
    final alreadyKnown = row['birth_time_known'] == true;
    if (alreadyKnown) {
      return;
    }
    final birthDate = row['birth_date']?.toString() ?? '';
    final birthCity = row['birth_city']?.toString() ?? '';
    final latitude = (row['latitude'] as num?)?.toDouble() ?? 0.0;
    final longitude = (row['longitude'] as num?)?.toDouble() ?? 0.0;
    final timezone = row['timezone']?.toString() ?? '';
    final birthTimeStr = _formatTime(time);

    final chart = await AstroService.generateNatalChart(
      birthDate: birthDate,
      birthTime: birthTimeStr,
      city: birthCity,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      locale: locale,
    );
  if (!chart.isSuccess) {
      throw Exception(chart.message ?? 'unknown_error');
    }
    final planets = chart.planets;
    final houses = chart.houses;
    final aspects = chart.aspects;
    final moon = planets?['Moon'];
    final firstHouse = houses?['house_1'];
    final mcLongitude = _mcLongitude(chart.angles);
     if (planets == null ||
        moon == null ||
        firstHouse == null ||
        mcLongitude == null) {
      throw Exception('MISSING_RECALCULATED_CHART');
    }

    final houseRows = _buildHouseRows(profileId, houses, birthTimeKnown: true);
    final placementRows = _buildPlacementRows(
      profileId,
      planets,
      birthTimeKnown: true,
    );
    final aspectRows = _buildAspectRows(profileId, aspects);

    if (houseRows.isNotEmpty) {
      await client
          .from('user_chart_houses')
          .upsert(houseRows, onConflict: 'profile_id,house_id');
    }
    await client
        .from('user_chart_placements')
        .upsert(placementRows, onConflict: 'profile_id,planet_id');
    await client
        .from('user_chart_aspects')
        .delete()
        .eq('profile_id', profileId);
    if (aspectRows.isNotEmpty) {
      await client.from('user_chart_aspects').insert(aspectRows);
    }

    final updatePayload = <String, dynamic>{
      'birth_time': birthTimeStr,
      'birth_time_known': true,
      'ascendant_sign_id': RefIds.signId(firstHouse.signIndex),
      'moon_sign_id': RefIds.signId(moon.signIndex),
       'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
 final sun = planets['Sun'];
    if (sun != null) {
      updatePayload['sun_sign_id'] = RefIds.signId(sun.signIndex);
    }
    updatePayload['mc_degree'] = mcLongitude;
    updatePayload['mc_sign_id'] = RefIds.signId((mcLongitude / 30).floor());
    await client
        .from('user_profiles')
        .update(updatePayload)
        .eq('id', profileId);
  }

  static List<Map<String, dynamic>> _buildHouseRows(
    String profileId,
    Map<String, HouseData>? houses, {
    required bool birthTimeKnown,
  }) {
    if (!birthTimeKnown || houses == null) return const [];
    return houses.values
        .map(
          (house) => {
            'profile_id': profileId,
            'house_id': RefIds.houseId(house.houseNumber),
            'cusp_degree': house.longitude,
            'sign_id': RefIds.signId(house.signIndex),
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _buildPlacementRows(
    String profileId,
    Map<String, PlanetData>? planets, {
    required bool birthTimeKnown,
  }) {
    final rows = <Map<String, dynamic>>[];
    if (planets == null) return rows;
    for (final entry in planets.entries) {
      final planetId = RefIds.planets[entry.key];
      if (planetId == null) {
        debugPrint('Skipping unknown planet: ${entry.key}');
        continue;
      }
      final planet = entry.value;
      rows.add({
        'profile_id': profileId,
        'planet_id': planetId,
        'sign_id': RefIds.signId(planet.signIndex),
        'house_id': birthTimeKnown ? RefIds.houseId(planet.house) : null,
        'longitude_degree': planet.longitude,
        'latitude_degree': planet.latitude,
        'retrograde': planet.retrograde,
      });
    }
    return rows;
  }

  static List<Map<String, dynamic>> _buildAspectRows(
    String profileId,
    List<AspectData>? aspects,
  ) {
    final rows = <Map<String, dynamic>>[];
    for (final aspect in aspects ?? const <AspectData>[]) {
      final planetAId = RefIds.planets[aspect.planet1];
      final planetBId = RefIds.planets[aspect.planet2];
      final aspectTypeId = RefIds.aspectId(aspect.angle);
      if (planetAId == null || planetBId == null || aspectTypeId == null) {
        continue;
      }
      rows.add({
        'profile_id': profileId,
        'planet_a_id': planetAId,
        'planet_b_id': planetBId,
        'aspect_type_id': aspectTypeId,
        'exact_angle': aspect.actualAngle,
        'orb': aspect.orb,
        'applying': aspect.applying,
      });
    }
    return rows;
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  static double? _mcLongitude(ChartAngles? angles) {
    if (angles == null) return null;
    const signs = [
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
    final signIndex = signs.indexOf(angles.mcSign);
    if (signIndex < 0) return null;
    return signIndex * 30 + angles.mcDegree;
  }
}
