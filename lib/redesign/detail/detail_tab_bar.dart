// Detay tema çubuğu (Faz 7a). ChartCategoryBar ile aynı görünüm ve davranış.
import 'package:flutter/material.dart';

import '../../core/content_theme_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';

class DetailTabBar extends StatelessWidget {
  const DetailTabBar({
    super.key,
    required this.themeCodes,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> themeCodes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.screenH,
      ),
      child: Row(
        children: [
          for (var i = 0; i < themeCodes.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            _TabItem(
              label: t(context, 'placement.theme.${themeCodes[i]}'),
              color: themeColorFor(themeCodes[i]),
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

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
                style: AppTextStyles.bodyLg(
                  color: selected ? color : AppColors.mist,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 2.5,
                color: selected ? color : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
