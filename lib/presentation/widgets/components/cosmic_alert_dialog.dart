import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import 'cosmic_cta_button.dart';

class CosmicAlertAction {
  final String label;
  final bool primary;
  final VoidCallback? onTap;
  const CosmicAlertAction({required this.label, this.primary = true, this.onTap});
}

Future<void> showCosmicAlert(
  BuildContext context, {
  required String message,
  required List<CosmicAlertAction> actions,
  String? title,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'alert',
    barrierColor: AppColors.bgVoid.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final slide = CurvedAnimation(
          parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      final fade = CurvedAnimation(parent: anim, curve: const Interval(0.4, 1.0));
      // daire -> yuvarlatılmış kare
      final radius = 150 - 126 * Curves.easeInOut.transform(anim.value);

      return SlideTransition(
        position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(slide),
        child: FadeTransition(
          opacity: anim,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.statusDanger.withValues(alpha: 0.18),
                          AppColors.bgVoid,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: AppColors.borderError),
                      boxShadow: AppShadows.glow(
                        AppColors.statusDanger,
                        blur: 24,
                      ),
                    ),
                    child: FadeTransition(
                      opacity: fade,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/images/logo/logo.png', height: 56),
                            const SizedBox(height: 16),
                            if (title != null) ...[
                              Text(title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                            ],
                            Text(message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSecondary, height: 1.4)),
                            const SizedBox(height: 20),
                            for (final a in actions)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: a.primary
                                    ? CosmicCtaButton(
                                        label: a.label,
                                        gradient: LinearGradient(colors: [
                                          AppColors.statusDanger,
                                          AppColors.statusChallenging,
                                        ]),
                                        onTap: () {
                                          Navigator.of(ctx).pop();
                                          a.onTap?.call();
                                        },
                                      )
                                    : TextButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          a.onTap?.call();
                                        },
                                        child: Text(a.label,
                                            style: const TextStyle(
                                                color: AppColors.textSecondary)),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}