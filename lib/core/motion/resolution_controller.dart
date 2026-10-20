import 'package:flutter/foundation.dart';

/// Onboarding çözünürlüğü (0.0 bulanık → 1.0 net). Tek doğruluk kaynağı.
/// Akıcı geçiş ekran tarafında TweenAnimationBuilder ile yapılır.
class ResolutionController extends ChangeNotifier {
  double _value = 0.0;
  double get value => _value;

  void setTarget(double v) {
    final next = v.clamp(0.0, 1.0).toDouble();
    if (next == _value) return;
    _value = next;
    notifyListeners();
  }
}