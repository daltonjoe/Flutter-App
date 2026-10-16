// lib/presentation/widgets/components/cosmic_background.dart
// SoulBound Cosmic Sanctum — ortak yıldızlı arka plan sarmalayıcı

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Yıldızlı arka plan görselinin varsayılan opaklığı (tek kaynak).
///
/// Görsel mavi baskın (ortalama RGB ≈ 17/19/31); yeni bgVoid zemininin
/// "gece gökyüzü" karakterini bozmaması ve altın vurguların öne çıkması
/// için 0.60'a düşürüldü.
const double kCosmicBackgroundOpacity = 0.60;

/// Yıldızlı arka plan görselini [child] arkasına yerleştirir.
///
/// `child` bir `Scaffold` olacaksa, bu widget Scaffold'un DIŞINDA
/// kullanılmalı ve Scaffold'un arka planı [Colors.transparent] olmalıdır;
/// böylece klavye açıldığında görsel yeniden boyutlanmaz.
class CosmicBackground extends StatelessWidget {
  const CosmicBackground({
    super.key,
    required this.child,
    this.opacity = kCosmicBackgroundOpacity,
  });

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // (a) En altta düz zemin
        const ColoredBox(color: AppColors.bgDeep),
        // (b) Üstünde yıldızlı arka plan görseli (dokunuşları yutmaz)
        Positioned.fill(
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/logo/background.jpg',
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation<double>(opacity),
            ),
          ),
        ),
        // (c) En üstte içerik
        child,
      ],
    );
  }
}
