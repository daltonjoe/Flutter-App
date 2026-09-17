// lib/presentation/widgets/components/cosmic_outline_button.dart
// SoulBound Cosmic Sanctum — secondary / outline button

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Secondary action button — dark background, violet border, violet text.
///
/// Height is 52px by default; pass [height] to match 58px on screens that
/// align primary and secondary buttons side-by-side.
class CosmicOutlineButton extends StatelessWidget {
  const CosmicOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 52.0,
    this.borderColor,
    this.labelColor,
  });

  final String label;
  final VoidCallback? onTap;

  /// Optional leading icon widget.
  final Widget? icon;

  /// Button height (default 52px; use 58px to match [CosmicCtaButton]).
  final double height;

  /// Override border colour (defaults to 35% violet).
  final Color? borderColor;

  /// Override label colour (defaults to [AppColors.violetPrimary]).
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final color = labelColor ?? AppColors.violetPrimary;
    final border = borderColor ?? const Color(0x598B5CF6);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: border, width: 1.0),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.ctaSecondary(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
