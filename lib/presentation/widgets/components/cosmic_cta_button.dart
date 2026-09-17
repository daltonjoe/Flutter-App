// lib/presentation/widgets/components/cosmic_cta_button.dart
// SoulBound Cosmic Sanctum — primary CTA button

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Primary call-to-action button for the Cosmic Sanctum design system.
///
/// 58px height · full width · violet gradient · 16px radius · ambient glow.
/// Supports an optional leading [icon], a [loading] spinner state, and a
/// [disabled] state that mutes the gradient and suppresses the glow.
class CosmicCtaButton extends StatelessWidget {
  const CosmicCtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
    this.disabled = false,
    this.height = AppSizes.ctaHeight,
    this.gradient,
  });

  final String label;
  final VoidCallback? onTap;

  /// Optional leading widget — typically an [Icon] or emoji [Text].
  final Widget? icon;

  /// Shows a [CircularProgressIndicator] and disables the tap target.
  final bool loading;

  /// Greys out the button; suppresses gradient and glow.
  final bool disabled;

  /// Override the default 58px height.
  final double height;

  /// Override the default [AppGradients.primaryCta] gradient.
  final Gradient? gradient;

  bool get _interactive => !loading && !disabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: _interactive ? (gradient ?? AppGradients.primaryCta) : null,
        color: _interactive ? null : AppColors.bgSurface,
        boxShadow: _interactive ? AppShadows.violetGlow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: _interactive ? onTap : null,
          child: Center(child: _buildContent()),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            disabled ? AppColors.textMuted : AppColors.violetPrimary,
          ),
        ),
      );
    }

    final textStyle = AppTextStyles.ctaPrimary.copyWith(
      color: disabled ? AppColors.textDisabled : Colors.white,
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 10),
          Text(label, style: textStyle),
        ],
      );
    }

    return Text(label, style: textStyle);
  }
}
