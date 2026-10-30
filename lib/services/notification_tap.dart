import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../i18n/app_localizations.dart';
import '../providers/ask_context_provider.dart';
import '../providers/ask_draft.dart';
import '../screens/main_shell.dart' show shellTab;
import 'notification_repository.dart';
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
    await Future<void>.delayed(const Duration(milliseconds: 350));
    askDraft.value = q;
  }
  if (res != null && res.awarded > 0) {
    messenger?.showSnackBar(
      SnackBar(content: Text(tpl.replaceAll('{n}', '${res.awarded}'))),
    );
  }
}
