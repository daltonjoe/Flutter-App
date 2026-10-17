// lib/redesign/ask/ask_hero.dart
// Ask — boş durum kahraman alanı: moda göre başlık, açıklama ve kısayol.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_chip.dart';
import 'star_typing.dart';

/// Sohbet boşken gösterilen kompakt karşılama alanı.
///
/// Moda göre içerik değişir: `forecast` ay-yıl seçicisini, `synastry` iki
/// profilli köprü düzenini gösterir. `natal` yalnız başlık ve açıklamadır.
class AskHero extends StatelessWidget {
  const AskHero({
    super.key,
    required this.mode,
    this.month,
    this.onPickMonth,
    this.partnerName,
    this.partnersEmpty = false,
    this.onPickPartner,
  });

  /// 'natal' | 'forecast' | 'synastry'
  final String mode;

  /// Seçili ay (YYYY-MM) — yalnız `forecast`.
  final String? month;
  final VoidCallback? onPickMonth;

  /// Seçili partner adı — yalnız `synastry`.
  final String? partnerName;
  final bool partnersEmpty;
  final VoidCallback? onPickPartner;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          t(context, 'ask.empty_title.$mode'),
          textAlign: TextAlign.center,
          style: AppTextStyles.displayLarge(),
        ),
        const SizedBox(height: 8),
        Text(
          t(context, 'ask.empty_body.$mode'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm(color: AppColors.mist),
        ),
        if (mode == 'forecast') ...[
          const SizedBox(height: 16),
          CosmicChip(
            label: month == null
                ? t(context, 'ask.forecast.pick')
                : '${t(context, 'ask.forecast.for')}: ${month!.substring(5)}-${month!.substring(0, 4)}',
            selected: month == null,
            icon: Icons.calendar_month_outlined,
            onTap: onPickMonth,
          ),
        ],
        if (mode == 'synastry') ...[
          const SizedBox(height: 16),
          if (partnersEmpty)
            Text(
              t(context, 'ask.avatar.synastry.need_profile'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm(),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _avatar(
                  highlight: false,
                  child: const Icon(
                    Icons.person_outline,
                    size: 22,
                    color: AppColors.mist,
                  ),
                ),
                _connector(),
                _avatar(
                  highlight: partnerName == null,
                  child: partnerName == null
                      ? const Icon(Icons.add, size: 22, color: AppColors.gold)
                      : Text(
                          _initial(partnerName!),
                          style: AppTextStyles.h3(color: AppColors.starlight),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CosmicChip(
              label: partnerName == null
                  ? t(context, 'ask.avatar.partner.pick')
                  : '${t(context, 'ask.avatar.partner.for')}: $partnerName',
              icon: Icons.people_outline,
              onTap: onPickPartner,
            ),
          ],
        ],
      ],
    );
  }

  static String _initial(String name) {
    final s = name.trim();
    return s.isEmpty ? '?' : s.substring(0, 1);
  }

  Widget _avatar({required bool highlight, required Widget child}) {
    return Container(
      width: AppSizes.personHeroAvatar,
      height: AppSizes.personHeroAvatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navyRaised,
        border: Border.all(
          color: highlight ? AppColors.gold : AppColors.hairline,
        ),
      ),
      child: child,
    );
  }

  Widget _connector() {
    final line = Container(
      height: 1,
      color: AppColors.gold.withValues(alpha: 0.35),
    );
    return SizedBox(
      width: 72,
      child: Row(
        children: [
          Expanded(child: line),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: AskStar(size: 10),
          ),
          Expanded(child: line),
        ],
      ),
    );
  }
}
