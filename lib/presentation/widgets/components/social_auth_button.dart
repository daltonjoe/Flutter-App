// lib/presentation/widgets/components/social_auth_button.dart
// SoulBound Cosmic Sanctum — ortak sosyal giriş / kayıt butonu
//
// Ölçüler, köşe yarıçapı, kenarlık ve renkler "Giriş yap"
// (onboarding_sign_in_page) ekranındaki sosyal giriş butonlarıyla
// birebir aynıdır; tek doğruluk kaynağı burasıdır.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// İkon + etiketli, pill köşeli ortak sosyal giriş butonu.
///
/// Yükseklik [AppSizes.ctaHeight]'tir. [onTap] `null` ise buton
/// devre dışı görünür.
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.leading,
    required this.label,
    required this.onTap,
  });

  /// Butonun solunda, metnin hemen yanında gösterilen ikon/logo.
  final Widget leading;

  /// Buton metni (yerelleştirilmiş).
  final String label;

  /// Buton davranışı — `null` ise devre dışı.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return SizedBox(
      height: AppSizes.ctaHeight,
      child: Material(
        color: AppColors.navyDeep,
        borderRadius: AppRadius.pillBr,
        child: InkWell(
          borderRadius: AppRadius.pillBr,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.pillBr,
              border: Border.all(color: AppColors.borderMedium),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AppTextStyles.ctaSecondary(
                        color: disabled
                            ? AppColors.textDisabled
                            : AppColors.starlight,
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

/// Giriş yap ekranındakiyle aynı resmî çok renkli Google logosu.
///
/// Asset eksikse çökmek yerine aynı ölçüde boşluk bırakır.
class GoogleLogoMark extends StatelessWidget {
  const GoogleLogoMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo/google_logo.png',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) =>
          SizedBox(width: size, height: size),
    );
  }
}
