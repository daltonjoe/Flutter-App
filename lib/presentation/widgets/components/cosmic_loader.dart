// lib/presentation/widgets/components/cosmic_loader.dart
// SoulBound Cosmic Sanctum — reusable loading state component
//
// Renders the shared LoadingVideo backdrop with the message + progress strip
// anchored above the floating bottom nav so the loading state is consistent
// with the Cosmic Sanctum visual language.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
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
        // Okunabilirlik perdesi (yalnız görsel; dokunuşu yutmaz).
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bgDeep.withValues(alpha: 0.0),
                    AppColors.bgDeep.withValues(alpha: 0.60),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Mesaj + ilerleme bloğu: ortak çapa ([AppSizes.loadingMessageAlignment])
        // ile ekranın ~%65'ine yerleşir, yüzen alt menünün üstünde kalır.
        SafeArea(
          child: Align(
            alignment: AppSizes.loadingMessageAlignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.message ??
                        t(context, 'onboarding.calculating.title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
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
