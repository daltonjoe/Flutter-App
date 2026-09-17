// lib/presentation/widgets/components/cosmic_input_field.dart
// SoulBound Cosmic Sanctum — labelled input field with validation states

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// A labelled input field following the Cosmic Sanctum design language.
///
/// Features:
/// - 56px minimum height dark-surface container
/// - Subtle violet border by default; red when [errorText] is set
/// - Upper-left icon + uppercase overline label row
/// - Optional trailing [actionWidget] (e.g. a calendar icon button)
/// - Validation visual state driven by [errorText]
/// - [readOnly] / [disabled] states
class CosmicInputField extends StatelessWidget {
  const CosmicInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.errorText,
    this.actionWidget,
    this.readOnly = false,
    this.disabled = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.child,
  });

  /// Uppercase overline label shown above the input.
  final String label;

  /// Leading icon displayed beside the label.
  final IconData icon;

  final TextEditingController controller;
  final String? hint;

  /// Non-null value renders the red error border and an error message below.
  final String? errorText;

  /// Optional trailing widget in the label row (e.g. a date-picker button).
  final Widget? actionWidget;

  final bool readOnly;
  final bool disabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final int maxLines;

  /// When set, the [child] replaces the internal [TextField] entirely.
  /// Useful for wrapping custom inputs (e.g. [CitySearchField]).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final borderColor =
        hasError ? AppColors.borderError : AppColors.borderSubtle;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.fieldBottomGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label row ────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: disabled ? AppColors.textDisabled : AppColors.violetPrimary,
              ),
              const SizedBox(width: 12),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.fieldLabel(
                  color: disabled ? AppColors.textDisabled : AppColors.textMuted,
                ),
              ),
              if (actionWidget != null) ...[
                const Spacer(),
                actionWidget!,
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.inputLabelGap),

          // ── Input container ──────────────────────────────────────────
          child != null
              ? child!
              : Container(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.inputHeight,
                  ),
                  decoration: BoxDecoration(
                    color: disabled
                        ? AppColors.bgSurfaceLow
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: TextField(
                    controller: controller,
                    readOnly: readOnly || disabled,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    onChanged: onChanged,
                    onTap: onTap,
                    maxLines: maxLines,
                    enabled: !disabled,
                    style: AppTextStyles.bodyLg(
                      color: disabled
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                    ).copyWith(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: AppTextStyles.bodyMd(
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.inputPaddingH,
                        vertical: AppSpacing.inputPaddingV,
                      ),
                    ),
                  ),
                ),

          // ── Error text ───────────────────────────────────────────────
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                errorText!,
                style: AppTextStyles.bodyXs(color: AppColors.errorRed),
              ),
            ),
        ],
      ),
    );
  }
}
