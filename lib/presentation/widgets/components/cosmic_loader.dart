import "package:flutter/material.dart";
import "package:lottie/lottie.dart";
import "../../../core/constants/app_animations.dart";
import "../../../core/theme/app_colors.dart";
import "../../../i18n/app_localizations.dart";

/// Tek ortak yukleme gostergesi: Lottie + baslik + ilerleme cubugu.
/// message ve useLottie eski cagirilar bozulmasin diye durur, yok sayilir.
class CosmicLoader extends StatelessWidget {
  const CosmicLoader({super.key, this.message, this.useLottie = true});

  final String? message;
  final bool useLottie;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Container(
      color: AppColors.bgDeep,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: Lottie.asset(
                  AppAnimations.astrologyLoading,
                  animate: !reduce,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  t(context, "onboarding.calculating.title"),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.violetPrimary.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(AppColors.violetPrimary),
                    minHeight: 3,
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

/// Tam ekran yukleme iskeleti.
class CosmicLoadingScreen extends StatelessWidget {
  const CosmicLoadingScreen({super.key, this.message, this.useLottie = true});

  final String? message;
  final bool useLottie;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: CosmicLoader(message: message, useLottie: useLottie),
      );
}
