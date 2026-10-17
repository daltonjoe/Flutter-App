// lib/presentation/widgets/components/cosmic_card.dart
// SoulBound Cosmic Sanctum — reusable card surface

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_dimensions.dart';

/// The primary card surface used across all Cosmic Sanctum screens.
///
/// Default look: 24px radius, a flat [AppColors.navyDeep] surface at 65 %
/// opacity, a 1px white hairline border, a subtle 1px inner top highlight and
/// the single neutral [AppShadows.cardShadow]. Pass [gradient] to override the
/// flat fill, or [blur] to place a [BackdropFilter] behind the content.
///
/// Content padding defaults to 20px standard or 16px compact — pass
/// [compact: true] for the denser variant.
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
    this.blur = false,
  });

  final Widget child;

  /// When true, uses 16px padding instead of the default 20px.
  final bool compact;

  /// Override the default content padding entirely.
  final EdgeInsetsGeometry? padding;

  /// Optional outer margin.
  final EdgeInsetsGeometry? margin;

  /// Override the default flat surface (defaults to navyDeep @ 65 %).
  final Gradient? gradient;

  /// Override the border colour (defaults to [AppColors.borderSubtle]).
  final Color? borderColor;

  /// Override the elevation shadows (defaults to [AppShadows.cardShadow]).
  final List<BoxShadow>? shadows;

  /// Override the corner radius (defaults to [AppRadius.card] = 24px).
  final double? radius;

  /// Optional tap callback — wraps the card in [InkWell] with matching radius.
  final VoidCallback? onTap;

  /// Whether to clip child content to the card's border radius (default true).
  final bool clipContent;

  /// When true, a [BackdropFilter] (sigma 16) blurs whatever sits behind the
  /// card. Off by default for performance.
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppRadius.card;
    final effectivePadding = padding ??
        EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.cardPadding);

    final surface = Stack(
      children: [
        // 1px inner top highlight — suggests a light source above the card.
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: Container(height: 1.0, color: AppColors.hairlineTop),
        ),
        Padding(padding: effectivePadding, child: child),
      ],
    );

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? AppColors.navyDeep.withValues(alpha: 0.65)
            : null,
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
              child: blur
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: surface,
                    )
                  : surface,
            )
          : surface,
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
