import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/auth_redirect.dart';

class AccountLinkingService {
  static Future<void> linkEmail({
    required String email,
    required String password,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('NO_SESSION');

    await supabase.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
      ),
    );
  }

  static Future<void> linkGoogle() async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) throw Exception('NO_SESSION');
    await supabase.auth.linkIdentity(
      OAuthProvider.google,
      redirectTo: kAuthRedirectUrl,
    );
  }

  static Future<void> linkApple() async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) throw Exception('NO_SESSION');
    await supabase.auth.linkIdentity(
      OAuthProvider.apple,
      redirectTo: kAuthRedirectUrl,
    );
  }
}
