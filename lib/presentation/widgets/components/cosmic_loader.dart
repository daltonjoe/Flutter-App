// lib/presentation/widgets/components/cosmic_loader.dart
// SoulBound Cosmic Sanctum — reusable loading state component
//
// Wraps the project's existing ZodiacOrbitalAnimation and AppLoader so the
// loading state is consistent with the Cosmic Sanctum visual language.
// Business logic and animation logic are untouched.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../widgets/animations/zodiac_orbital_animation.dart';

/// Inline loading widget. Place wherever a screen section is pending.
///
/// [useLottie] — use the Lottie AppLoader animation instead of ZodiacOrbitalAnimation.
class CosmicLoader extends StatefulWidget {
  const CosmicLoader({
    super.key,
    this.message,
    this.useLottie = false,
  });

  final String? message;
  final bool useLottie;

  @override
  State<CosmicLoader> createState() => _CosmicLoaderState();
}

class _CosmicLoaderState extends State<CosmicLoader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep,
      child: SafeArea(
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
                    child: widget.useLottie
                        ? const AppLoader()
                        : const ZodiacOrbitalAnimation(size: 400),
                  ),
                ),
              ),
            ),

            // Progress region
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        backgroundColor:
                            AppColors.violetPrimary.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.violetPrimary),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen loading scaffold. Wraps [CosmicLoader] in a [Scaffold] so it
/// can be used as a screen body or a full-page replacement.
class CosmicLoadingScreen extends StatelessWidget {
  const CosmicLoadingScreen({
    super.key,
    this.message,
    this.useLottie = false,
  });

  final String? message;
  final bool useLottie;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: CosmicLoader(message: message, useLottie: useLottie),
      );
}