// lib/presentation/widgets/components/cosmic_loader.dart
// SoulBound Cosmic Sanctum — reusable loading state component
//
// Wraps the project's existing ZodiacOrbitalAnimation and AppLoader so the
// loading state is consistent with the Cosmic Sanctum visual language.
// Business logic and animation logic are untouched.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/animations/zodiac_orbital_animation.dart';
import '../../../i18n/app_localizations.dart';
import '../../../redesign/splash/loading_video.dart';

/// Inline loading widget. Place wherever a screen section is pending.
///
class CosmicLoader extends StatefulWidget {
  const CosmicLoader({super.key, this.message});

  final String? message;

  @override
  State<CosmicLoader> createState() => _CosmicLoaderState();
}

class _CosmicLoaderState extends State<CosmicLoader> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka plan: tek yükleme görseli (video; poster fallback'li).
        const Positioned.fill(child: LoadingVideo()),
        SafeArea(
          child: Column(
            children: [
              // Animation region
              Expanded(
                flex: 7,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: const ZodiacOrbitalAnimation(size: 400),
                    ),
                  ),
                ),
              ),

              // Progress region
              Expanded(
                flex: 3,
                child: DecoratedBox(
                  // Metin/progress okunabilirliği için hafif karartma.
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.bgDeep.withValues(alpha: 0.30),
                        AppColors.bgDeep.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16,
                          left: 24,
                          right: 24,
                        ),
                        child: Text(
                          widget.message ??
                              t(context, 'onboarding.calculating.title'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            backgroundColor: AppColors.violetPrimary.withValues(
                              alpha: 0.12,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.violetPrimary,
                            ),
                            minHeight: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-screen loading scaffold. Wraps [CosmicLoader] in a [Scaffold] so it
/// can be used as a screen body or a full-page replacement.
class CosmicLoadingScreen extends StatelessWidget {
  const CosmicLoadingScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgDeep,
    body: CosmicLoader(message: message),
  );
}
