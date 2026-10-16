// lib/widgets/navigation/cosmic_bottom_nav.dart
// Cosmic Sanctum — yüzen (şeffaf zeminli) alt gezinme çubuğu.
//
// Gezinme mantığı içermez: [selectedIndex]'i vurgular ve dokunulan öğenin
// `index` değerini [onTap] ile yukarı bildirir.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import 'nav_badge.dart';

/// Alt gezinme çubuğunda gösterilecek tek bir sekme tanımı.
class CosmicNavItem {
  const CosmicNavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  /// Mantıksal sekme kimliği — [CosmicBottomNav.onTap] bu değeri geri verir.
  final int index;

  /// Seçili olmayan durumda gösterilen (outlined) ikon.
  final IconData icon;

  /// Seçili durumda gösterilen (filled) ikon.
  final IconData activeIcon;

  /// Sekme etiketi (yerelleştirilmiş).
  final String label;
}

/// Şeffaf zeminli, yüzen alt gezinme çubuğu.
///
/// Daireler tek bir çizgide değil, [NavWavePattern] çarpanlarına göre
/// zikzaklı (dalgalı) dizilir; her etiket kendi dairesini takip eder.
/// Ofsetler slot sırasına bağlıdır, seçime göre değişmez.
class CosmicBottomNav extends StatelessWidget {
  const CosmicBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.badgeCounts = const <int, int>{},
  });

  /// Görünür sekmeler, ekrandaki sırayla (3–5 arası değişebilir).
  final List<CosmicNavItem> items;

  /// Seçili sekenin [items] içindeki konumu.
  final int selectedIndex;

  /// Dokunulan öğenin [CosmicNavItem.index] değeri ile çağrılır.
  final ValueChanged<int> onTap;

  /// `item.index` → gösterilecek sayı. Boş bırakılırsa rozet çizilmez.
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);

    // Etiketin dikey alanı metin ölçeğiyle birlikte büyür, ancak ayrılan
    // banda ([AppSizes.navLabelHeight]) sığacak şekilde sınırlanır.
    final double labelHeight = MediaQuery.textScalerOf(context)
        .scale(AppSpacing.md)
        .clamp(AppSpacing.md, AppSizes.navLabelHeight)
        .toDouble();

    // Zikzak ofsetleri: slot sırasına göre sabit (seçime bağlı değil).
    final pattern = NavWavePattern.forCount(items.length);
    final List<double> offsets = pattern.length == items.length
        ? [for (final m in pattern) m * AppSizes.navWaveAmplitude]
        : List<double>.filled(items.length, 0);

    // Daire yuvası + ara boşluk + etiket bandı.
    final double contentHeight =
        AppSizes.navItemSelectedSize + AppSpacing.xs + labelHeight;

    // İçerik, en yüksek ve en alçak slotun sığacağı kadar dikey boşlukla
    // ortalanır; böylece hiçbir daire/etiket taşmaz.
    final double minOffset = offsets.reduce(math.min);
    final double maxOffset = offsets.reduce(math.max);
    final double slack =
        AppSizes.bottomNavHeight - contentHeight - (maxOffset - minOffset);
    final double topPad = slack / 2 - minOffset;

    // Zemin şeffaftır; okunabilirlik perdesi sayfa seviyesinde (MainShell)
    // çizilir. ColoredBox dokunuşları yutar: çubuğun boş alanına yapılan
    // dokunuş arkadaki sayfa içeriğine geçmez (öğeler yine kendi
    // dokunuşlarını alır).
    return ColoredBox(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: AppSizes.bottomNavHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Row(
              // Her hücre tam yüksekliğe yayılır: dokunma alanı ofsetle
              // birlikte hareket eder, komşularla çakışmaz.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: topPad + offsets[i]),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _NavItemCell(
                          item: items[i],
                          selected: i == selectedIndex,
                          badgeCount: badgeCounts[items[i].index],
                          duration: duration,
                          labelHeight: labelHeight,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(items[i].index);
                          },
                        ),
                      ),
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

class _NavItemCell extends StatelessWidget {
  const _NavItemCell({
    required this.item,
    required this.selected,
    required this.badgeCount,
    required this.duration,
    required this.labelHeight,
    required this.onTap,
  });

  final CosmicNavItem item;
  final bool selected;
  final int? badgeCount;
  final Duration duration;
  final double labelHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final circleColor = selected ? AppColors.textPrimary : AppColors.bgSurface;
    final iconColor = selected ? AppColors.bgDeep : AppColors.textSecondary;
    final labelColor = selected
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final double diameter = selected
        ? AppSizes.navItemSelectedSize
        : AppSizes.navItemSize;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.xxl,
          minHeight: AppSpacing.xxl,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgBr,
          splashColor: AppColors.violetPrimary.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Column(
            // İçerik tam olarak kendi yüksekliği kadar yer kaplar; böylece
            // zikzak ofseti kırpılmadan (yarıya inmeden) uygulanır.
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sabit yükseklikli daire yuvası: seçili daire büyüse de
              // diğer sekmeler ve etiketler kaymaz.
              SizedBox(
                height: AppSizes.navItemSelectedSize,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        width: diameter,
                        height: diameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: circleColor,
                          border: selected
                              ? null
                              : Border.all(color: AppColors.borderSubtle),
                          boxShadow: selected ? AppShadows.violetGlow : null,
                        ),
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: selected ? 1 : 0,
                            ),
                            duration: duration,
                            curve: Curves.easeOutCubic,
                            builder: (context, t, _) {
                              final color =
                                  Color.lerp(
                                    AppColors.textSecondary,
                                    AppColors.bgDeep,
                                    t,
                                  ) ??
                                  iconColor;
                              final double iconSize =
                                  AppSizes.navIconSize +
                                  (AppSizes.navIconSelectedSize -
                                          AppSizes.navIconSize) *
                                      t;
                              return AnimatedSwitcher(
                                duration: duration,
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeOutCubic,
                                child: Icon(
                                  selected ? item.activeIcon : item.icon,
                                  key: ValueKey<bool>(selected),
                                  size: iconSize,
                                  color: color,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: NavBadge(count: badgeCount),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: labelHeight,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyXs(color: labelColor).copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
