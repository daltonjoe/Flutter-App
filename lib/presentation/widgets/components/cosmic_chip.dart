// lib/presentation/widgets/components/cosmic_chip.dart
// SoulBound Cosmic Sanctum — seçilebilir etiket hapı (chip).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Tek satırlık, seçilebilir küçük etiket.
///
/// Varsayılan: navyRaised dolgu + 1px hairline çerçeve + starlight metin.
/// [selected] true olduğunda çerçeve ve metin altın rengine döner.
class CosmicChip extends StatelessWidget {
  const CosmicChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.gold : AppColors.starlight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pillBr,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Container(
          height: AppSizes.chipHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.navyRaised,
            borderRadius: AppRadius.pillBr,
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.chip(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
