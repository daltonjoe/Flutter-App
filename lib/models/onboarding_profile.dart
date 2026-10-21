// lib/models/onboarding_profile.dart
// S10c sohbetinin sonunda yazılan tek profil kaydı (K22).

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Sohbet tamamlanmadan hiçbir şey yazılmaz; [save] yalnız "close.continue"
/// adımında çağrılır ve [prefKey] altına tek bir JSON nesnesi koyar.
class OnboardingProfile {
  const OnboardingProfile({
    required this.goal,
    required this.area,
    required this.reaction,
    required this.tone,
    required this.alert,
    required this.notif,
  });

  /// shared_preferences anahtarı.
  static const String prefKey = 'onboarding_profile_v1';

  /// Şema sürümü.
  static const int schemaVersion = 1;

  /// c1 — ilk bakmak istediği alan (self, intentions, …).
  final String goal;

  /// c2 — hayatta en önemli alan (love, career, …).
  final String area;

  /// c3 — karar verirken eğilim (act, wait, consult, withdraw).
  final String reaction;

  /// c7 — konuşma tonu (soft | direct).
  final String tone;

  /// c5 — hazır olmak istenen anlar (hard_days, regret, right_time, all).
  final String alert;

  /// Sistem bildirimi izni sonucu (granted | denied | skipped).
  /// `skipped`: izin hiç sorulmadı (web veya desteklenmeyen platform).
  final String notif;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': schemaVersion,
    'migrated': false,
    'goal': goal,
    'area': area,
    'reaction': reaction,
    'tone': tone,
    'alert': alert,
    'notif': notif,
  };

  static OnboardingProfile fromJson(Map<String, dynamic> json) {
    String str(String key) => json[key] is String ? json[key] as String : '';
    return OnboardingProfile(
      goal: str('goal'),
      area: str('area'),
      reaction: str('reaction'),
      tone: str('tone'),
      alert: str('alert'),
      notif: str('notif'),
    );
  }

  String encode() => jsonEncode(toJson());

  /// Tamamlanan sohbeti [prefKey] altına yazar.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, encode());
  }
}
