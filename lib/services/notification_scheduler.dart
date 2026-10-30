import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'chart_cusps_service.dart';
import 'checkin_service.dart';
import 'house_lookup.dart';
import 'notification_planner.dart';
import 'notification_repository.dart';
import 'user_settings_service.dart';

/// OS scheduling + server sync (N4). Planning itself is pure
/// (notification_planner.dart); this class only wires services and plugin.
class NotificationScheduler {
  NotificationScheduler._();

  static const String flagKey = 'settings_notifications';
  static const String _kMorning = 'notif_morning';
  static const String _kEvening = 'notif_evening';
  static const String defaultMorning = '09:00';
  static const String defaultEvening = '20:00';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;
  static bool _busy = false;
  static bool _again = false;
  static tz.Location? _loc;

  /// Slot times as 'HH:mm' (local, device-only).
  static Future<({String morning, String evening})> slotTimes() async {
    final p = await SharedPreferences.getInstance();
    return (
      morning: _okTime(p.getString(_kMorning)) ?? defaultMorning,
      evening: _okTime(p.getString(_kEvening)) ?? defaultEvening,
    );
  }

  static Future<void> setSlotTimes({String? morning, String? evening}) async {
    final p = await SharedPreferences.getInstance();
    if (_okTime(morning) != null) await p.setString(_kMorning, morning!);
    if (_okTime(evening) != null) await p.setString(_kEvening, evening!);
  }

  static String? _okTime(String? v) {
    if (v == null) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(v.trim());
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final mi = int.parse(m.group(2)!);
    if (h > 23 || mi > 59) return null;
    return '${h.toString().padLeft(2, '0')}:${m.group(2)}';
  }

  static int _hh(String t) => int.parse(t.split(':')[0]);
  static int _mm(String t) => int.parse(t.split(':')[1]);

  static Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    try {
      final name = (await FlutterTimezone.getLocalTimezone()).identifier;
      _loc = tz.getLocation(name);
    } catch (e) {
      debugPrint('NotificationScheduler tz: $e');
      _loc = tz.UTC;
    }
    tz.setLocalLocation(_loc!);
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
    _inited = true;
  }

  /// Cancel + rebuild the OS schedule and sync the same list to the server.
  /// Returns the number of planned items (-1 if another run is in progress).
  static Future<int> reschedule({
    required String? profileId,
    required String? displayName,
    required String locale,
  }) async {
    if (_busy) {
      _again = true;
      return -1;
    }
    _busy = true;
    var n = 0;
    try {
      do {
        _again = false;
        n = await _run(profileId, displayName, locale);
      } while (_again);
    } catch (e) {
      debugPrint('NotificationScheduler.reschedule failed: $e');
    } finally {
      _busy = false;
    }
    return n;
  }

  static Future<int> _run(
      String? profileId, String? displayName, String locale) async {
    await init();
    final loc = _loc ?? tz.UTC;

    final flag = await UserSettingsService.isFlagEnabled(flagKey);
    if (!flag) return 0; // feature off: leave everything as is

    UserSettings? us;
    try {
      us = await UserSettingsService.load();
    } catch (_) {}
    final enabled = us?.notificationsEnabled ?? false;
    if (!enabled || profileId == null) {
      await _plugin.cancelAll();
      try {
        await NotificationRepository.schedule(const []);
      } catch (e) {
        debugPrint('NotificationScheduler clear failed: $e');
      }
      return 0;
    }

    final nowTz = tz.TZDateTime.now(loc);
    final today = DateTime(nowTz.year, nowTz.month, nowTz.day);
    final to = DateTime(today.year, today.month, today.day + 29);

    final content = await NotificationRepository.content(today, to, locale);
    final contentLocale = content.isNotEmpty ? content.first.locale : locale;
    final lines = content.isEmpty
        ? <HouseLine>[]
        : await NotificationRepository.houseLines(contentLocale);
    final topic = await NotificationRepository.topic();

    var lowMood = false;
    try {
      final cs = await CheckinService.loadRecent(profileId, days: 7);
      lowMood = NotificationPlanner.isLowMood(cs.map((c) => c.mood).toList());
    } catch (e) {
      debugPrint('NotificationScheduler mood: $e');
    }

    List<double>? cusps;
    if (content.any((r) => r.eventLon != null)) {
      cusps = await ChartCuspsService.loadCusps(profileId, locale: locale);
    }

    final times = await slotTimes();
    final name = (displayName ?? '').trim();
    final first = name.isEmpty ? null : name.split(RegExp(r'\s+')).first;

    final items = NotificationPlanner.plan(
      content: content,
      houseLines: lines,
      locale: contentLocale,
      now: nowTz,
      today: today,
      morningHour: _hh(times.morning),
      morningMinute: _mm(times.morning),
      eveningHour: _hh(times.evening),
      eveningMinute: _mm(times.evening),
      at: (d, h, m) => tz.TZDateTime(loc, d.year, d.month, d.day, h, m),
      firstName: first,
      topic: topic,
      lowMood: lowMood,
      houseOf: cusps == null ? null : (lon) => HouseLookup.houseOf(lon, cusps),
      toLocal: (utc) => tz.TZDateTime.from(utc, loc),
    );

    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'cosmic_daily',
        'Daily cosmic notes',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (final it in items) {
      try {
        await _plugin.zonedSchedule(
          id: it.osId,
          scheduledDate: tz.TZDateTime.from(it.scheduledAt, loc),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: it.title,
          body: it.body,
          payload: it.payload,
        );
      } catch (e) {
        debugPrint('NotificationScheduler zonedSchedule ${it.payload}: $e');
      }
    }

    try {
      await NotificationRepository.schedule(
          items.map((e) => e.toScheduleJson()).toList());
    } catch (e) {
      debugPrint('NotificationScheduler server sync failed: $e');
    }
    return items.length;
  }
}
