// lib/services/analytics_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Onboarding/paywall hunisi olay adları. Sayfalar yalnız bunları kullanır.
class AnalyticsEvents {
  AnalyticsEvents._();

  /// props: step (welcome, name, birth_date, birth_time, city, relationship,
  /// chat, calculating, first_result, first_question)
  static const stepViewed = 'onboarding_step_viewed';
  static const stepCompleted = 'onboarding_step_completed';

  /// props: n (1-3), ok (bool)
  static const questionAsked = 'onboarding_question_asked';

  static const accountGateViewed = 'account_gate_viewed';

  /// props: method (apple, google, email)
  static const accountLinked = 'account_linked';
  static const accountGateSkipped = 'account_gate_skipped';

  /// props: source (onboarding, quota, preview, notification)
  static const paywallViewed = 'paywall_viewed';

  /// props: product (annual, monthly)
  static const trialStarted = 'trial_started';
  static const purchased = 'purchase_completed';
  static const paywallClosed = 'paywall_closed';
}

/// PostHog analitiği (AB bulutu, HTTP batch API; yerel eklenti yok).
///
/// Anahtar `--dart-define=POSTHOG_KEY=phc_...` ile verilir. Anahtar yoksa
/// olaylar gönderilmez, yalnız debug log'a yazılır. distinct_id = Supabase uid
/// (anonim dahil; linkIdentity uid'i değiştirmediği için huni kopmaz).
class AnalyticsService {
  AnalyticsService._();

  static const String _key = String.fromEnvironment('POSTHOG_KEY');
  static const String _host = 'https://eu.i.posthog.com';
  static const int _maxQueue = 20;

  static final List<Map<String, dynamic>> _queue = [];
  static Timer? _timer;
  static AppLifecycleListener? _lifecycle;

  static bool get enabled => _key.isNotEmpty;

  /// main()'de bir kez; arka plana geçişte kuyruğu boşaltır.
  static void init() {
    _lifecycle ??= AppLifecycleListener(onPause: () => flush().ignore());
  }

  static void track(String event, [Map<String, Object?> props = const {}]) {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'unknown';
    final e = buildEvent(event, uid, props, DateTime.now().toUtc());
    if (!enabled) {
      debugPrint('[analytics] $event ${jsonEncode(e['properties'])}');
      return;
    }
    _queue.add(e);
    if (_queue.length >= _maxQueue) {
      flush().ignore();
    } else {
      _timer ??= Timer(const Duration(seconds: 10), () => flush().ignore());
    }
  }

  static Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (!enabled || _queue.isEmpty) return;
    final batch = List<Map<String, dynamic>>.of(_queue);
    _queue.clear();
    try {
      final res = await http.post(
        Uri.parse('$_host/batch/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'api_key': _key, 'batch': batch}),
      );
      if (res.statusCode >= 300) {
        debugPrint('[analytics] flush ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('[analytics] flush failed: $e');
    }
  }

  @visibleForTesting
  static Map<String, dynamic> buildEvent(
    String event,
    String distinctId,
    Map<String, Object?> props,
    DateTime timestampUtc,
  ) => {
    'event': event,
    'distinct_id': distinctId,
    'timestamp': timestampUtc.toIso8601String(),
    'properties': {
      ...props,
      r'$lib': 'soulbound-flutter',
      'platform': defaultTargetPlatform.name,
    },
  };
}
