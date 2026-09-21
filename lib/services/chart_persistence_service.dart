import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/reference_ids.dart';
import '../models/natal_chart_response.dart';
import '../models/onboarding_data.dart';

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

    final planets = chart.planets;
    final houses = chart.houses;
    final sun = planets?['Sun'];
    final moon = planets?['Moon'];
    final firstHouse = houses?['house_1'];
    if (data.name == null ||
        data.birthDate == null ||
        data.birthTime == null ||
        data.city == null ||
        sun == null ||
        moon == null ||
        firstHouse == null) {
      throw Exception('MISSING_CHART_DATA');
    }

    final client = Supabase.instance.client;
    final profile = await client.from('user_profiles').insert({
      'user_id': userId,
      'display_name': data.name,
      'gender': data.gender,
      'relationship_status': data.relationshipStatus,
      'birth_date': _formatDate(data.birthDate!),
      'birth_time': _formatTime(data.birthTime!),
      'birth_city': data.city!.city,
      'latitude': data.city!.latitude,
      'longitude': data.city!.longitude,
      'timezone': data.city!.timezone,
      'locale': locale,
      'sun_sign_id': RefIds.signId(sun.signIndex),
      'moon_sign_id': RefIds.signId(moon.signIndex),
      'ascendant_sign_id': RefIds.signId(firstHouse.signIndex),
    }).select('id').single();

    final profileId = profile['id'] as String;
    try {
      final houseRows = houses!.values
          .map(
            (house) => {
              'profile_id': profileId,
              'house_id': RefIds.houseId(house.houseNumber),
              'cusp_degree': house.longitude,
              'sign_id': RefIds.signId(house.signIndex),
            },
          )
          .toList();
      await client
          .from('user_chart_houses')
          .upsert(houseRows, onConflict: 'profile_id,house_id');

      final placementRows = <Map<String, dynamic>>[];
      for (final entry in planets!.entries) {
        final planetId = RefIds.planets[entry.key];
        if (planetId == null) {
          debugPrint('Skipping unknown planet: ${entry.key}');
          continue;
        }
        final planet = entry.value;
        placementRows.add({
          'profile_id': profileId,
          'planet_id': planetId,
          'sign_id': RefIds.signId(planet.signIndex),
          'house_id': RefIds.houseId(planet.house),
          'longitude_degree': planet.longitude,
          'latitude_degree': planet.latitude,
          'retrograde': planet.retrograde,
        });
      }
      await client
          .from('user_chart_placements')
          .upsert(placementRows, onConflict: 'profile_id,planet_id');

      final aspectRows = <Map<String, dynamic>>[];
      for (final aspect in chart.aspects ?? const <AspectData>[]) {
        final planetAId = RefIds.planets[aspect.planet1];
        final planetBId = RefIds.planets[aspect.planet2];
        final aspectTypeId = RefIds.aspectId(aspect.angle);
        if (planetAId == null || planetBId == null || aspectTypeId == null) {
          debugPrint(
            'Skipping aspect: ${aspect.planet1}/${aspect.planet2}, '
            'angle=${aspect.angle}',
          );
          continue;
        }
        aspectRows.add({
          'profile_id': profileId,
          'planet_a_id': planetAId,
          'planet_b_id': planetBId,
          'aspect_type_id': aspectTypeId,
          'exact_angle': aspect.actualAngle,
          'orb': aspect.orb,
          'applying': aspect.applying,
        });
      }
      if (aspectRows.isNotEmpty) {
        await client.from('user_chart_aspects').upsert(
              aspectRows,
              onConflict: 'profile_id,planet_a_id,planet_b_id,aspect_type_id',
            );
      }
    } catch (_) {
      try {
        await client.from('user_profiles').delete().eq('id', profileId);
      } catch (cleanupError) {
        debugPrint('Failed to delete profile after chart save error: $cleanupError');
      }
      rethrow;
    }

    return profileId;
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
