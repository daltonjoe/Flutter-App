import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveProfileProvider extends ChangeNotifier {
  String? activeProfileId;
  static const String _prefKey = 'active_profile_id';

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
}
