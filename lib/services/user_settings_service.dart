import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserSettings {
  final String? notificationTime;
  final bool notificationsEnabled;
  final String? currentTimezone;

  UserSettings({
    this.notificationTime,
    required this.notificationsEnabled,
    this.currentTimezone,
  });

  UserSettings copyWith({
    String? notificationTime,
    bool? notificationsEnabled,
    String? currentTimezone,
  }) {
    return UserSettings(
      notificationTime: notificationTime ?? this.notificationTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      currentTimezone: currentTimezone ?? this.currentTimezone,
    );
  }
}

class UserSettingsService {
  UserSettingsService._();

  static Future<UserSettings?> load() async {
    try {
      final auth = Supabase.instance.client.auth;
      final user = auth.currentUser;
      if (user == null) return null;

      final row = await Supabase.instance.client
          .from('user_settings')
          .select('notification_time, notifications_enabled, current_timezone')
          .eq('user_id', user.id)
          .maybeSingle();

      if (row == null) return null;

      String? rawTime = row['notification_time'] as String?;
      String? parsedTime;
      if (rawTime != null && rawTime.length >= 5) {
        parsedTime = rawTime.substring(0, 5);
      }

      return UserSettings(
        notificationTime: parsedTime,
        notificationsEnabled: row['notifications_enabled'] as bool? ?? false,
        currentTimezone: row['current_timezone'] as String?,
      );
    } catch (e) {
      debugPrint('UserSettingsService.load failed: $e');
      rethrow;
    }
  }

  static Future<void> save({
    String? notificationTime,
    bool? notificationsEnabled,
  }) async {
    try {
      final auth = Supabase.instance.client.auth;
      final user = auth.currentUser;
      if (user == null) return;

      final Map<String, dynamic> data = {
        'user_id': user.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (notificationTime != null) {
        data['notification_time'] = '${notificationTime.substring(0, 5)}:00';
      }
      if (notificationsEnabled != null) {
        data['notifications_enabled'] = notificationsEnabled;
      }

      await Supabase.instance.client
          .from('user_settings')
          .upsert(data, onConflict: 'user_id');
    } catch (e) {
      debugPrint('UserSettingsService.save failed: $e');
      rethrow;
    }
  }

  static Future<bool> isFlagEnabled(String key) async {
    try {
      final row = await Supabase.instance.client
          .from('feature_flags')
          .select('enabled')
          .eq('key', key)
          .maybeSingle();

      if (row == null) return false;
      return row['enabled'] as bool? ?? false;
    } catch (e) {
      debugPrint('UserSettingsService.isFlagEnabled($key) failed: $e');
      return false;
    }
  }
}
