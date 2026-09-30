import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveProfileProvider extends ChangeNotifier {
  String? activeProfileId;
  static const String _prefKey = 'active_profile_id';

  /// Yeni oluşturulan profil için chart üretim+kayıt işlemini taşır.
  /// ActiveChartPage, activeProfileId null iken bunu bulursa çalıştırır.
  Future<void> Function()? pendingProfileSetup;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    activeProfileId = prefs.getString(_prefKey);
    notifyListeners();
  }

  Future<void> setActive(String id) async {
    activeProfileId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id);
    notifyListeners();
  }

  Future<void> clearActive() async {
    activeProfileId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    notifyListeners();
  }
}
