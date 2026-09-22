import 'package:supabase_flutter/supabase_flutter.dart';

class AccountDeletionService {
  static Future<void> deleteAccount() async {
    final response = await Supabase.instance.client.functions.invoke(
      'delete-account',
    );

    if (response.status < 200 || response.status >= 300) {
      final error = response.data is Map
          ? (response.data as Map)['error']?.toString()
          : null;
      throw Exception(error ?? 'Account deletion failed');
    }

    await Supabase.instance.client.auth.signOut();
    await Supabase.instance.client.auth.signInAnonymously();
  }
}
