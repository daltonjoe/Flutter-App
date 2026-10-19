// lib/redesign/ask/ask_hero.dart
// Ask — boş durum kahraman alanı: moda göre başlık, açıklama ve kısayol.

import 'package:flutter/material.dart';

import '../../core/reference_ids.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_chip.dart';
import '../../presentation/widgets/components/glyph.dart';
import '../../providers/active_profile_provider.dart';
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
    this.summary,
  });

  /// 'natal' | 'forecast' | 'synastry'
  final String mode;

  /// Aktif profilin özeti — yalnız `natal` modunda chip üretir.
  final ActiveProfileSummary? summary;

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
        const SizedBox(height: AppSpacing.sm),
        Text(
          t(context, 'ask.empty_title.$mode'),
          textAlign: TextAlign.center,
          style: AppTextStyles.displayLarge(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          t(context, 'ask.empty_body.$mode'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm(color: AppColors.mist),
        ),
        if (mode == 'forecast') ...[
          const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.cardGap),
            CosmicChip(
              label: partnerName == null
                  ? t(context, 'ask.avatar.partner.pick')
                  : '${t(context, 'ask.avatar.partner.for')}: $partnerName',
              icon: Icons.people_outline,
              onTap: onPickPartner,
            ),
          ],
        ],
        if (mode == 'natal') ..._natalChips(context),
      ],
    );
  }

  /// Natal modunda Güneş/Ay/Yükselen chip'leri; özet yoksa hiç üretilmez.
  ///
  /// Yükselen yalnız doğum saati biliniyorsa gösterilir.
  List<Widget> _natalChips(BuildContext context) {
    final s = summary;
    if (s == null) return const [];
    final chips = <Widget>[
      if (s.sunIndex != null)
        _tripleChip(context, 'sun', 'chart.sun', s.sunIndex!),
      if (s.moonIndex != null)
        _tripleChip(context, 'moon', 'chart.moon', s.moonIndex!),
      if (s.birthTimeKnown && s.ascIndex != null)
        _tripleChip(context, 'asc', 'chart.ascendant', s.ascIndex!),
    ];
    if (chips.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.md),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: chips,
      ),
    ];
  }

  /// "Güneş · Yengeç" biçiminde glyph + rol + burç adı chip'i.
  Widget _tripleChip(
    BuildContext context,
    String glyph,
    String roleKey,
    int signIndex,
  ) {
    final code = RefIds.signCode(signIndex);
    final signName = code == null ? '' : t(context, 'signs.$code');
    return Container(
      height: AppSizes.chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navyRaised,
        borderRadius: AppRadius.pillBr,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Glyph(glyph, size: 16, color: AppColors.gold, decorative: true),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${t(context, roleKey)} · $signName',
            style: AppTextStyles.chip(color: AppColors.starlight),
          ),
        ],
      ),
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
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: AskStar(size: 10),
          ),
          Expanded(child: line),
        ],
      ),
    );
  }
}
