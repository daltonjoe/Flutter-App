// lib/presentation/widgets/components/cosmic_card.dart
// SoulBound Cosmic Sanctum — reusable card surface

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_dimensions.dart';

/// The primary card surface used across all Cosmic Sanctum screens.
///
/// Provides the standard cosmic gradient background, 1px subtle violet border,
/// 24px corner radius and dark elevation shadow. Content padding defaults to
/// 20px standard or 16px compact — pass [compact: true] for the denser variant.
///
/// All visual tokens are sourced from the centralised design system; no raw
/// values are written here.
class CosmicCard extends StatelessWidget {
  const CosmicCard({
    super.key,
    required this.child,
    this.compact = false,
    this.padding,
    this.margin,
    this.gradient,
    this.borderColor,
    this.shadows,
    this.radius,
    this.onTap,
    this.clipContent = true,
  });

  final Widget child;

  /// When true, uses 16px padding instead of the default 20px.
  final bool compact;

  /// Override the default content padding entirely.
  final EdgeInsetsGeometry? padding;

  /// Optional outer margin.
  final EdgeInsetsGeometry? margin;

  /// Override the card gradient (defaults to [AppGradients.cosmicCard]).
  final Gradient? gradient;

  /// Override the border colour (defaults to [AppColors.borderSubtle]).
  final Color? borderColor;

  /// Override the elevation shadows (defaults to [AppShadows.cardShadow]).
  final List<BoxShadow>? shadows;

  /// Override the corner radius (defaults to [AppRadius.lg] = 24px).
  final double? radius;

  /// Optional tap callback — wraps the card in [InkWell] with matching radius.
  final VoidCallback? onTap;

  /// Whether to clip child content to the card's border radius (default true).
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppRadius.lg;
    final effectivePadding = padding ??
        EdgeInsets.all(compact ? AppSpacing.md : 20.0);

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.cosmicCard,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: borderColor ?? AppColors.borderSubtle,
          width: 1.0,
        ),
        boxShadow: shadows ?? AppShadows.cardShadow,
      ),
      child: clipContent
          ? ClipRRect(
              borderRadius: BorderRadius.circular(r),
              child: Padding(padding: effectivePadding, child: child),
            )
          : Padding(padding: effectivePadding, child: child),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(r),
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}
