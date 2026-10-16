// Paylaşılan splash saati. Statik durum: oturum boyunca asla yeniden başlamaz.
// Hot restart saati sıfırlar.
class SplashClock {
  SplashClock._();

  // Earth animasyonunun süresi (ms).
  static const int durationMs = 2500;

  // Yalnızca overlay için fade-out süresi (ms).
  static const int fadeOutMs = 300;

  // Tembel başlar: ilk erişimde çalışmaya başlar.
  static final Stopwatch _sw = Stopwatch()..start();

  static int get elapsedMs => _sw.elapsedMilliseconds;

  static double get progress => (elapsedMs / durationMs).clamp(0.0, 1.0);
}
