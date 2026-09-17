// lib/presentation/widgets/components/soulbound_bottom_nav.dart
// SoulBound Cosmic Sanctum — glass bottom navigation bar
//
// 68px base height + safe area inset.
// Five destinations: Horoscope · Natal Chart · Moon · Insights · Sanctuary
//
// Does NOT introduce navigation logic or routing. It calls [onTap] with the
// tapped index and highlights [currentIndex] — exactly like BottomNavigationBar.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const List<_NavDestination> _kDestinations = [
  _NavDestination(
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome_rounded,
    label: 'Horoscope',
  ),
  _NavDestination(
    icon: Icons.workspaces_outline,
    activeIcon: Icons.workspaces_filled,
    label: 'Natal',
  ),
  _NavDestination(
    icon: Icons.nightlight_outlined,
    activeIcon: Icons.nightlight_round,
    label: 'Moon',
  ),
  _NavDestination(
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights_rounded,
    label: 'Insights',
  ),
  _NavDestination(
    icon: Icons.temple_buddhist_outlined,
    activeIcon: Icons.temple_buddhist_rounded,
    label: 'Sanctuary',
  ),
];

/// Glass-effect bottom navigation bar for the Cosmic Sanctum shell.
///
/// Parameters map directly to the standard Flutter bottom-nav contract:
/// [currentIndex] and [onTap]. Wrap in a [SafeArea] if you need to control
/// padding yourself, otherwise the bar adds its own bottom safe-area inset.
class SoulBoundBottomNav extends StatelessWidget {
  const SoulBoundBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: AppSizes.bottomNavHeight + bottomPadding,
      decoration: const BoxDecoration(
        // Glass-dark background
        color: Color(0xE6110E22), // bgCard at ~90 % opacity
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          children: List.generate(_kDestinations.length, (i) {
            return Expanded(
              child: _NavItem(
                destination: _kDestinations[i],
                active: i == currentIndex,
                onTap: () => onTap(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        active ? AppColors.textPrimary : AppColors.textMuted;
    final labelColor =
        active ? const Color(0xFFD4C7FF) : AppColors.textMuted; // lavender active

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.violetPrimary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Icon with glow when active ─────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 30,
            decoration: active
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.violetPrimary.withValues(alpha: 0.14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violetPrimary.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  )
                : null,
            child: Center(
              child: Icon(
                active ? destination.activeIcon : destination.icon,
                size: 20,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            destination.label,
            style: AppTextStyles.tinyLabel(color: labelColor).copyWith(
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
