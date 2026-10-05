import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Checkin {
  final String day;
  final int mood;

  const Checkin({required this.day, required this.mood});
}

class CheckinService {
  CheckinService._();

  static String dayKey(DateTime d) {
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime _strip(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  static Future<List<Checkin>> loadRecent(
    String profileId, {
    int days = 60,
  }) async {
    try {
      final today = _strip(DateTime.now());
      final start = today.subtract(Duration(days: days - 1));
      final startDay = dayKey(start);
      final rows = await Supabase.instance.client
          .from('user_checkins')
          .select('day,mood')
          .eq('profile_id', profileId)
          .gte('day', startDay)
          .order('day', ascending: false);
 final out = <Checkin>[];
      for (final r in rows) {
        final d = r['day']?.toString();
        final m = r['mood'] as num?;
        if (d != null && m != null) {
          out.add(Checkin(day: d, mood: m.toInt().clamp(1, 5)));
        }
      }
      return out;
    } catch (e) {
      debugPrint('CheckinService.loadRecent failed: $e');
      rethrow;
    }
  }

  static Future<void> setMood({
    required String profileId,
    required String day,
    required int mood,
  }) async {
    try {
      final payload = {
        'profile_id': profileId,
        'day': day,
        'mood': mood.clamp(1, 5),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await Supabase.instance.client
          .from('user_checkins')
          .upsert(payload, onConflict: 'profile_id,day');
    } catch (e) {
      debugPrint('CheckinService.setMood failed: $e');
      rethrow;
    }
  }

  static int currentStreak(Set<String> days, DateTime today) {
    final t = _strip(today);
    int streak = 0;
    var cursor = t;
    if (days.contains(dayKey(cursor))) {
      while (days.contains(dayKey(cursor))) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return streak;
    }
    cursor = t.subtract(const Duration(days: 1));
    while (days.contains(dayKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int bestStreak(Set<String> days) {
    if (days.isEmpty) return 0;
    final list = days.toList()..sort();
    int best = 1;
    int run = 1;
    for (var i = 1; i < list.length; i++) {
      final prev = DateTime.parse(list[i - 1]);
      final cur = DateTime.parse(list[i]);
      if (cur.difference(prev).inDays == 1) {
        run += 1;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }
}
