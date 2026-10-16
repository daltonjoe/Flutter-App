// Kategori çubuğu: All · Sun · Moon · Ascendant · Satellites (Faz 5).
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';

class ChartCategoryBar extends StatelessWidget {
  const ChartCategoryBar({
    super.key,
    required this.birthTimeKnown,
    required this.onOpenPlacement,
  });

  final bool birthTimeKnown;
  final ValueChanged<String> onOpenPlacement;

  @override
  Widget build(BuildContext context) {
    final bool moonEnabled = birthTimeKnown;
    final bool ascEnabled = birthTimeKnown;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.screenH,
      ),
      child: Row(
        children: [
          // "All" her zaman seçili.
          _BarItem(
            label: t(context, 'rd.tab.all'),
            color: AppColors.violetPrimary,
            selected: true,
            onTap: null,
          ),
          const SizedBox(width: AppSpacing.lg),
          _BarItem(
            label: t(context, 'chart.sun'),
            color: AppColors.textSecondary,
            selected: false,
            onTap: () => onOpenPlacement('sun'),
          ),
          const SizedBox(width: AppSpacing.lg),
          _BarItem(
            label: t(context, 'chart.moon'),
            color: moonEnabled ? AppColors.textSecondary : AppColors.textDisabled,
            selected: false,
            onTap: moonEnabled ? () => onOpenPlacement('moon') : null,
          ),
          const SizedBox(width: AppSpacing.lg),
          _BarItem(
            label: t(context, 'chart.ascendant'),
            color: ascEnabled ? AppColors.textSecondary : AppColors.textDisabled,
            selected: false,
            onTap: ascEnabled ? () => onOpenPlacement('ascendant') : null,
          ),
          const SizedBox(width: AppSpacing.lg),
          _BarItem(
            label: t(context, 'rd.tab.satellites'),
            color: AppColors.textDisabled,
            selected: false,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        alignment: AlignmentDirectional.centerStart,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyLg(color: color),
                maxLines: 1,
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                height: 2.5,
                color: selected ? AppColors.violetPrimary : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
