// lib/widgets/navigation/cosmic_bottom_nav.dart
// Cosmic Sanctum — yüzen (cam zeminli) tek parça "hap" alt gezinme çubuğu.
//
// Gezinme mantığı içermez: [selectedIndex]'i vurgular ve dokunulan öğenin
// `index` değerini [onTap] ile yukarı bildirir.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/ask_context_provider.dart';
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

/// Yüzen, cam zeminli "hap" alt gezinme çubuğu.
///
/// Tüm öğeler tek bir yatay hizada, eşit genişlikte slotlarda durur; zikzak
/// (dalga) dizilimi kullanılmaz. Etiket yalnızca aktif öğede görünür ve aktif
/// öğenin altında, slotlar arasında kayan 4 px'lik altın bir gösterge bulunur.
/// Ask sekmesi (index = [kAskTab]) çok hafif bir altın "nefes" glow'u taşır.
class CosmicBottomNav extends StatefulWidget {
  const CosmicBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.badgeCounts = const <int, int>{},
  });

  /// Görünür sekmeler, ekrandaki sırayla (3–5 arası değişebilir).
  final List<CosmicNavItem> items;

  /// Seçili sekmenin [items] içindeki konumu.
  final int selectedIndex;

  /// Dokunulan öğenin [CosmicNavItem.index] değeri ile çağrılır.
  final ValueChanged<int> onTap;

  /// `item.index` → gösterilecek sayı. Boş bırakılırsa rozet çizilmez.
  final Map<int, int> badgeCounts;

  @override
  State<CosmicBottomNav> createState() => _CosmicBottomNavState();
}

class _CosmicBottomNavState extends State<CosmicBottomNav>
    with SingleTickerProviderStateMixin {
  /// Ask "nefes" glow döngüsü süresi (tek yön).
  static const Duration _glowDuration = Duration(seconds: 5);

  /// Aktif gösterge kayma süresi.
  static const Duration _indicatorDuration = Duration(milliseconds: 320);

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: _glowDuration,
  );

  late final Animation<double> _glowOpacity = Tween<double>(
    begin: 0.10,
    end: 0.22,
  ).animate(CurvedAnimation(parent: _glow, curve: Curves.easeInOutSine));

  /// [CosmicBottomNav.items] içinde Ask sekmesinin slotu (yoksa null).
  int? _askSlot;

  @override
  void initState() {
    super.initState();
    _askSlot = _findAskSlot();
  }

  @override
  void didUpdateWidget(CosmicBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    _askSlot = _findAskSlot();
    _syncGlow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGlow();
  }

  int? _findAskSlot() {
    for (var i = 0; i < widget.items.length; i++) {
      if (widget.items[i].index == kAskTab) return i;
    }
    return null;
  }

  /// Nefes animasyonunu yalnızca hareket kısıtı yokken çalıştırır; aksi halde
  /// durdurur. Sekme görünmezken [SingleTickerProviderStateMixin] ticker'ı
  /// TickerMode üzerinden otomatik askıya alır.
  void _syncGlow() {
    final shouldRun =
        _askSlot != null && !MediaQuery.disableAnimationsOf(context);
    if (shouldRun) {
      if (!_glow.isAnimating) _glow.repeat(reverse: true);
    } else if (_glow.isAnimating) {
      _glow.stop();
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : _indicatorDuration;
    final glowOn = !reduceMotion && _askSlot != null;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final slotCount = widget.items.length;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.screenH,
        end: AppSpacing.screenH,
        bottom: AppSizes.navBarBottomGap + bottomSafe,
      ),
      child: SizedBox(
        height: AppSizes.navBarHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.hairline, width: 1),
            boxShadow: AppShadows.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppSizes.navBarBlurSigma,
                sigmaY: AppSizes.navBarBlurSigma,
              ),
              child: ColoredBox(
                color: AppColors.navyDeep.withValues(alpha: 0.80),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final slotWidth = slotCount == 0
                        ? 0.0
                        : constraints.maxWidth / slotCount;
                    return Stack(
                      children: [
                        // Slotlar arasında kayan aktif gösterge.
                        if (slotCount > 0)
                          AnimatedPositionedDirectional(
                            duration: duration,
                            curve: Curves.easeInOutCubic,
                            start: slotWidth * (widget.selectedIndex + 0.5) -
                                AppSizes.navDotSize / 2,
                            bottom: AppSizes.navDotInset,
                            width: AppSizes.navDotSize,
                            height: AppSizes.navDotSize,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            for (var i = 0; i < slotCount; i++)
                              Expanded(
                                child: _NavSlot(
                                  item: widget.items[i],
                                  selected: i == widget.selectedIndex,
                                  badgeCount:
                                      widget.badgeCounts[widget.items[i].index],
                                  glow: i == _askSlot ? _glowOpacity : null,
                                  glowOn: glowOn && i == _askSlot,
                                  onTap: () {
                                    if (i != widget.selectedIndex) {
                                      HapticFeedback.selectionClick();
                                    }
                                    widget.onTap(widget.items[i].index);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tek bir sekme yuvası: ikon (+ yalnızca aktifken etiket) ve rozet.
class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.selected,
    required this.badgeCount,
    required this.glow,
    required this.glowOn,
    required this.onTap,
  });

  final CosmicNavItem item;
  final bool selected;
  final int? badgeCount;

  /// Ask sekmesinin "nefes" opaklık animasyonu (yalnızca Ask slotunda dolu).
  final Animation<double>? glow;
  final bool glowOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.gold : AppColors.mist;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.innerBr,
        splashColor: AppColors.gold.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: AppSizes.navBarIconSize,
              height: AppSizes.navBarIconSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (glowOn && glow != null)
                    FadeTransition(
                      opacity: glow!,
                      child: const SizedBox(
                        width: AppSizes.navGlowSize,
                        height: AppSizes.navGlowSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold,
                                blurRadius: AppSizes.navGlowBlur,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Icon(
                    selected ? item.activeIcon : item.icon,
                    size: AppSizes.navBarIconSize,
                    color: iconColor,
                  ),
                  PositionedDirectional(
                    top: -AppSpacing.xs,
                    end: -AppSpacing.xs,
                    child: NavBadge(count: badgeCount),
                  ),
                ],
              ),
            ),
            // Etiket yalnızca aktif öğede çizilir; pasifte yer tutulur ki ikon
            // dikey konumu değişmesin. FittedBox dar ekranda taşmayı önler.
            SizedBox(
              height: AppSizes.navBarLabelHeight,
              child: selected
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.miniTag(color: AppColors.gold),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
