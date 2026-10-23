import 'package:flutter/animation.dart';

/// Onboarding hareket tokenları (plan Bölüm 5.2).
class AppMotion {
  AppMotion._();

  static const enter = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 60);
  static const resolution = Duration(milliseconds: 900);
  static const pageOut = Duration(milliseconds: 500);
  static const hero = Duration(milliseconds: 700);
  static const chipFill = Duration(milliseconds: 260);

  /// Eya (AskPage) typewriter step: this many chars every typewriterTick.
  static const typewriterTick = Duration(milliseconds: 30);
  static const typewriterCharsPerTick = 2;

  /// Eya (AskPage) gap between sequential bubbles.
  static const bubbleGap = Duration(milliseconds: 450);

  static const enterCurve = Curves.easeOutCubic;
  static const resolutionCurve = Curves.easeInOutCubic;
}