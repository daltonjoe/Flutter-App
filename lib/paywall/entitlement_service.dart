import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EntitlementState {
  const EntitlementState({this.status, this.expiresAt});
  final String? status;
  final DateTime? expiresAt;

  static const EntitlementState none = EntitlementState();

  bool get hasRecord => status != null;
  bool get trialActive =>
      status == 'trial' && expiresAt != null && expiresAt!.isAfter(DateTime.now());
  bool get trialEnded => status == 'trial' && !trialActive;
}

class EntitlementService {
  static Future<EntitlementState> load() async {
    final c = Supabase.instance.client;
    final uid = c.auth.currentUser?.id;
    if (uid == null) return EntitlementState.none;
    try {
      final rows = await c
          .from('entitlements')
          .select('status, expires_at')
          .eq('user_id', uid)
          .eq('sku', 'trial')
          .limit(1);
      if (rows.isEmpty) return EntitlementState.none;
      final r = rows.first;
      final e = r['expires_at'];
      return EntitlementState(
        status: r['status'] as String?,
        expiresAt: e == null ? null : DateTime.parse(e as String).toLocal(),
      );
    } catch (e) {
      debugPrint('entitlements load error: $e');
      rethrow;
    }
  }

  static Future<DateTime> startTrial() async {
    try {
      final res = await Supabase.instance.client.rpc('start_trial');
      return DateTime.parse(res.toString()).toLocal();
    } catch (e) {
      debugPrint('start_trial error: $e');
      rethrow;
    }
  }
}