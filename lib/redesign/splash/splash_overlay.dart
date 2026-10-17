import 'package:flutter/material.dart';
import 'loading_video.dart';
import 'splash_clock.dart';

// MainShell üstünde gösterilen tam ekran splash katmanı.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  static const int total = SplashClock.durationMs + SplashClock.fadeOutMs;

  // Saat çoktan bittiyse değer 1'den başlar, overlay hemen boş döner.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: total),
    value: (SplashClock.elapsedMs / total).clamp(0.0, 1.0),
  );

  late final Animation<double> _opacity = _c.drive(
    Tween<double>(begin: 1, end: 0).chain(
      CurveTween(
        curve: Interval(
          SplashClock.durationMs / total,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    if (!_c.isCompleted) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: const LoadingVideo(showTexts: true),
      builder: (context, child) {
        if (_c.isCompleted) return const SizedBox.shrink();
        return AbsorbPointer(
          child: FadeTransition(opacity: _opacity, child: child),
        );
      },
    );
  }
}
