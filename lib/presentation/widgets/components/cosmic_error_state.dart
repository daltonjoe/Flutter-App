// lib/presentation/widgets/components/cosmic_error_state.dart
// SoulBound Cosmic Sanctum — reusable error state component

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import 'cosmic_cta_button.dart';

/// A full-area error state with a cosmic visual treatment.
///
/// Shows an error icon with a rose glow, the [message] text, and an optional
/// [onRetry] button. Drop it inside a [SliverFillRemaining], a [Center], or
/// any container that provides height.
///
/// [compact] removes the icon glow and reduces vertical spacing — useful inside
/// cards or section-level error states rather than full-screen ones.
class CosmicErrorState extends StatelessWidget {
  const CosmicErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.compact = false,
    this.icon = Icons.error_outline_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  /// Compact mode omits the glow halo and reduces padding.
  final bool compact;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Error icon with rose glow ─────────────────────────────
            if (!compact)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.errorRed.withValues(alpha: 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.errorRed.withValues(alpha: 0.22),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.errorRed,
                    size: 32,
                  ),
                ),
              )
            else
              Icon(icon, color: AppColors.errorRed, size: 36),

            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),

            // ── Message ───────────────────────────────────────────────
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm(color: AppColors.errorRed)
                  .copyWith(fontSize: 14),
            ),

            if (onRetry != null) ...[
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              // ── Retry button ──────────────────────────────────────────
              SizedBox(
                width: compact ? 160 : 220,
                child: CosmicCtaButton(
                  label: retryLabel,
                  onTap: onRetry,
                  height: 46,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
