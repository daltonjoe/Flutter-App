import 'dart:async';

import 'package:flutter/material.dart';
import 'loading_video.dart';
import 'splash_clock.dart';

// MainShell üstünde splash: kalıcı video katmanına "splash metinli" talep
// bildirir (video + metinleri katman çizer). Splash saati bitince talep kalkar.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> {
  Timer? _timer;
  late bool _active;

  @override
  void initState() {
    super.initState();
    // Saat çoktan bittiyse talep hiç bildirilmez.
    final remaining = SplashClock.durationMs - SplashClock.elapsedMs;
    _active = remaining > 0;
    if (_active) {
      _timer = Timer(Duration(milliseconds: remaining), () {
        if (mounted) setState(() => _active = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _active
        ? const LoadingVideo(showTexts: true)
        : const SizedBox.shrink();
  }
}
