// lib/presentation/widgets/components/analysis_section_card.dart
// SoulBound Cosmic Sanctum — analysis section card (replaces legacy version)
//
// Drop-in replacement for lib/widgets/analysis/analysis_section_card.dart.
// Existing screens that import the old path keep working; new screens import
// from lib/presentation/widgets/components/.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import 'cosmic_analysis_icon.dart';

/// A full-width card that renders one section of an AI-generated report.
///
/// Structure:
///   [icon circle] + [Playfair section title]
///   body text
///   optional bullet points
///
/// The [color] parameter tints the icon badge, section glow, bullet dots
/// and title shadow — use the planet or element accent colour.
class AnalysisSectionCard extends StatelessWidget {
  const AnalysisSectionCard({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.color,
    this.bulletPoints,
  });

  final String title;
  final String content;

  /// Emoji / glyph rendered inside the icon circle.
  final String? icon;

  /// Accent colour for the icon, glow, bullet dots and title shadow.
  final Color? color;

  final List<String>? bulletPoints;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.violetPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: accent.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            // ── Subtle corner glow ────────────────────────────────────
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.05),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ───────────────────────────────────────
                  Row(
                    children: [
                      if (icon != null) ...[
                        CosmicAnalysisIcon(
                          icon: icon!,
                          size: AppSizes.sectionIconBadge,
                          color: accent,
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.h2(
                            color: AppColors.textPrimary,
                          ).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: accent.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Body text ────────────────────────────────────────
                  Text(
                    content,
                    style: AppTextStyles.bodyLg(
                      color: AppColors.textSecondary,
                    ).copyWith(
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),

                  // ── Bullet points ────────────────────────────────────
                  if (bulletPoints != null && bulletPoints!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...bulletPoints!.map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                point,
                                style: AppTextStyles.bodySm(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
