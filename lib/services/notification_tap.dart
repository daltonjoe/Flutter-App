import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_localizations.dart';
import '../providers/ask_context_provider.dart';
import '../providers/ask_draft.dart';
import '../screens/main_shell.dart' show shellTab;
import 'notification_repository.dart';
import 'notification_transit_service.dart';
import '../providers/active_profile_provider.dart';
import '../providers/language_provider.dart';
import 'notification_tap_logic.dart';

final Map<String, DateTime> _recentTaps = <String, DateTime>{};

/// Tap on an OS notification or an inbox row (N6): record the tap, mark read,
/// open the target tab, put the question in the Sor box as a draft (not sent),
/// show a credit snack if credits were awarded.
Future<void> handleNotificationTap(
  BuildContext context,
  String day,
  String slot, {
  InboxItem? item,
  bool popToRoot = false,
}) async {
  final key = '$day|$slot';
  final now = DateTime.now();
  final last = _recentTaps[key];
  if (!popToRoot &&
      last != null &&
      now.difference(last).inSeconds < 5) {
    return; // launch details + callback can both report the same tap
  }
  _recentTaps[key] = now;

  DateTime d;
  try {
    d = DateTime.parse(day);
  } catch (_) {
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  final nav = Navigator.maybeOf(context);
  final tpl = t(context, 'notif.tap.awarded');
  var n7Loc = 'en';
  String? n7Pid;
  try {
    n7Loc = context.read<LanguageProvider>().locale.languageCode;
    n7Pid = context.read<ActiveProfileProvider>().activeProfileId;
  } catch (e) {
    debugPrint('tap provider read failed: $e');
  }

  TapResult? res;
  try {
    res = await NotificationRepository.tap(d, slot);
  } catch (e) {
    debugPrint('notification_tap failed: $e');
  }
  try {
    await NotificationRepository.markRead(day: d, slot: slot);
  } catch (e) {
    debugPrint('markRead failed: $e');
  }

  var it = item;
  if (it == null) {
    try {
      final rows = await NotificationRepository.inbox(days: 30);
      for (final r in rows) {
        if (r.day == day && r.slot == slot) {
          it = r;
          break;
        }
      }
    } catch (e) {
      debugPrint('inbox lookup failed: $e');
    }
  }
  final target = it?.target ?? 'today';
  final q = it?.question;

  if (popToRoot) nav?.popUntil((r) => r.isFirst);
  shellTab.value = tabForTarget(target);

  if (q != null && q.trim().isNotEmpty && target != 'today' && askEnabled.value) {
    var n7Q = q;
    try {
      var n7Ev = '';
      final n7Rows = await NotificationRepository.content(d, d, n7Loc);
      for (final r in n7Rows) {
        if (r.slot == slot) {
          n7Ev = r.eventType ?? '';
          break;
        }
      }
      final n7Topic = await NotificationRepository.topic();
      final n7P = await NotificationTransitService.question(
        seed: q,
        eventType: n7Ev,
        topic: n7Topic,
        locale: n7Loc,
        profileId: n7Pid,
      ).timeout(const Duration(seconds: 6));
      if (n7P != null && n7P.trim().isNotEmpty) n7Q = n7P;
    } catch (e) {
      debugPrint('personal question failed: $e');
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    askDraft.value = n7Q;
  }
  if (res != null && res.awarded > 0) {
    messenger?.showSnackBar(
      SnackBar(content: Text(tpl.replaceAll('{n}', '${res.awarded}'))),
    );
  }
}
