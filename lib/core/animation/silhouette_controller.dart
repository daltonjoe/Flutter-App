import 'package:flutter/foundation.dart';

/// Onboarding animasyonunu dışarıdan yöneten controller.
/// progress: 0-100, reveal(): final sekansı, pulseOnce(): gök cisimleri tek atım.
class SilhouetteController extends ChangeNotifier {
  double _progress = 0;
  int _revealTick = 0;
  int _pulseTick = 0;

  double get progress => _progress;
  int get revealTick => _revealTick;
  int get pulseTick => _pulseTick;

  set progress(double v) {
    final c = v < 0 ? 0.0 : (v > 100 ? 100.0 : v);
    if (c == _progress) return;
    _progress = c;
    notifyListeners();
  }

  void reveal() {
    _revealTick++;
    notifyListeners();
  }

  void pulseOnce() {
    _pulseTick++;
    notifyListeners();
  }
}

/// Tüm onboarding boyunca tek örnek kullanılır (sayfalar değişse de state kaybolmaz).
final SilhouetteController silhouette = SilhouetteController();
