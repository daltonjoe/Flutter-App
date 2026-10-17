// lib/presentation/widgets/components/cosmic_segmented.dart
// SoulBound Cosmic Sanctum — kayan altın lensli segment kontrolü.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import 'glyph.dart';

/// [CosmicSegmented] içindeki tek bir sekme.
class CosmicSegment<T> {
  const CosmicSegment({required this.value, required this.label, this.glyph});

  final T value;
  final String label;

  /// İsteğe bağlı astroloji glyph anahtarı ([Glyph] üzerinden çizilir).
  final String? glyph;
}

/// Hap biçimli, kayan altın lensli segment seçici.
///
/// Seçili öğenin arkasındaki lens [AnimatedAlign] ile kayar; tüm renk ve
/// boyut değerleri merkezî tasarım sisteminden gelir.
class CosmicSegmented<T> extends StatelessWidget {
  const CosmicSegmented({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<CosmicSegment<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final n = items.length;
    final idx = items.indexWhere((e) => e.value == selected);
    final sel = idx < 0 ? 0 : idx;
    // Toplam yükseklik 44 dp; içeride kalan lens alanı 36 dp.
    final total = AppSizes.segmentHeight + 4;
    final lens = AppSizes.segmentHeight - 4;

    return Container(
      width: double.infinity,
      height: total,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.navyDeep.withValues(alpha: 0.65),
        borderRadius: AppRadius.pillBr,
        border: Border.all(color: AppColors.hairline),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = c.maxWidth / n;
          return Stack(
            children: [
              AnimatedAlign(
                alignment: AlignmentDirectional(
                  n == 1 ? 0.0 : -1.0 + 2.0 * sel / (n - 1),
                  0.0,
                ),
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                child: Container(
                  width: segW,
                  height: lens,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.16),
                    borderRadius: AppRadius.pillBr,
                    border: Border.all(color: AppColors.gold),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: _SegmentItem<T>(
                          item: items[i],
                          selected: i == sel,
                          onTap: () => onChanged(items[i].value),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentItem<T> extends StatelessWidget {
  const _SegmentItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CosmicSegment<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.gold : AppColors.mist;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.pillBr,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.glyph != null) ...[
                  Glyph(item.glyph!, size: 16, color: fg, decorative: true),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.chip(color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
