// Kategori çubuğu: Hepsi · Güneş · Ay · Yükselen (chip satırı).
import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_chip.dart';

class ChartCategoryBar extends StatelessWidget {
  const ChartCategoryBar({
    super.key,
    required this.birthTimeKnown,
    required this.selectedKey,
    required this.onSelect,
  });

  final bool birthTimeKnown;

  /// Seçili sekme anahtarı: 'all' | 'sun' | 'moon' | 'ascendant'.
  final String selectedKey;

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.screenH,
      ),
      child: Row(
        children: [
          _chip(
            label: t(context, 'rd.tab.all'),
            selected: selectedKey == 'all',
            onTap: () => onSelect('all'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _chip(
            label: t(context, 'chart.sun'),
            selected: selectedKey == 'sun',
            onTap: () => onSelect('sun'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _chip(
            label: t(context, 'chart.moon'),
            selected: selectedKey == 'moon',
            enabled: birthTimeKnown,
            onTap: () => onSelect('moon'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _chip(
            label: t(context, 'chart.ascendant'),
            selected: selectedKey == 'ascendant',
            enabled: birthTimeKnown,
            onTap: () => onSelect('ascendant'),
          ),
        ],
      ),
    );
  }

  /// Sekme chip'i. [enabled] false iken dokunuş kapanır ve chip soluklaştırılır
  /// (CosmicChip'in ayrı bir pasif durumu yok).
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final chip = CosmicChip(
      label: label,
      selected: selected,
      onTap: enabled ? onTap : null,
    );
    if (enabled) return chip;
    return Opacity(opacity: 0.5, child: chip);
  }
}
