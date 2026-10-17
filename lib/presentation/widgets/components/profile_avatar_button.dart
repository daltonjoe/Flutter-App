// lib/presentation/widgets/components/profile_avatar_button.dart
// Üst çubuk sağındaki küçük profil avatarı: aktif profilin Güneş burcu
// görselini (özet yoksa baş harfini) gösterir; dokununca Profil sekmesine geçer.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../i18n/app_localizations.dart';
import '../../../providers/active_profile_provider.dart';
import '../../../redesign/assets_map.dart';
import '../../../screens/main_shell.dart' show shellTab, kProfileTab;

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<ActiveProfileProvider>().summary;
    final name = summary?.name ?? '';
    final sunIndex = summary?.sunIndex;

    return Semantics(
      button: true,
      label: name.isEmpty ? t(context, 'nav.profile') : name,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: InkWell(
            borderRadius: AppRadius.pillBr,
            onTap: () {
              HapticFeedback.selectionClick();
              shellTab.value = kProfileTab;
            },
            child: Container(
              width: 32,
              height: 32,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.navyRaised,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: sunIndex == null
                  ? _initial(name)
                  : Image.asset(
                      RdAssets.signIcon(sunIndex),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _initial(name),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _initial(String name) {
    final trimmed = name.trim();
    return Center(
      child: Text(
        trimmed.isEmpty ? '' : trimmed.characters.first,
        style: AppTextStyles.chip(color: AppColors.starlight),
      ),
    );
  }
}
