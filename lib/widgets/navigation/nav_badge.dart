// lib/widgets/navigation/nav_badge.dart
// Cosmic Sanctum — alt gezinme rozeti.
//
// Kırmızı yuvarlak sayaç rozeti. Sayı yoksa/sıfırsa hiçbir şey çizmez.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

class NavBadge extends StatelessWidget {
  const NavBadge({super.key, required this.count});

  /// Gösterilecek sayı. `null` veya `0` ise rozet gizlenir.
  final int? count;

  static const int _maxDisplayed = 99;

  @override
  Widget build(BuildContext context) {
    final value = count;
    if (value == null || value <= 0) return const SizedBox.shrink();

    final label = value > _maxDisplayed ? '$_maxDisplayed+' : '$value';

    return Container(
      constraints: const BoxConstraints(
        minWidth: AppSpacing.md,
        minHeight: AppSpacing.md,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.errorRed,
        borderRadius: AppRadius.pillBr,
      ),
      child: Text(
        label,
        maxLines: 1,
        style: AppTextStyles.miniTag(color: Colors.white),
      ),
    );
  }
}
