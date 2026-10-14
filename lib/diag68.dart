import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:supabase_flutter/supabase_flutter.dart";

String s68(String? s) => s == null ? "null" : (s.length > 8 ? s.substring(0, 8) : s);

void diag68(String nokta, [String ek = ""]) {
  if (!kDebugMode) return;
  final u = Supabase.instance.client.auth.currentUser;
  final t = DateTime.now().toIso8601String().substring(11, 19);
  _diag68(t, nokta, s68(u?.id), u?.isAnonymous, ek).ignore();
}

Future<void> _diag68(String t, String nokta, String uid, bool? anon, String ek) async {
  var sp = "err";
  try {
    final p = await SharedPreferences.getInstance();
    sp = s68(p.getString("active_profile_id"));
  } catch (e) {
    debugPrint("DIAG68 sp read failed: $e");
  }
  debugPrint("DIAG68 $t $nokta uid=$uid anon=$anon sp=$sp $ek");
}
