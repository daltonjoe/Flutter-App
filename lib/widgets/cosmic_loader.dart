// lib/widgets/cosmic_loader.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/widgets/app_loader.dart';
import './animations/zodiac_orbital_animation.dart';

class CosmicLoader extends StatelessWidget {
  final String? message;
  final bool useLottie;

  const CosmicLoader({super.key, this.message, this.useLottie = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 7,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: useLottie
                        ? const AppLoader()
                        : const ZodiacOrbitalAnimation(size: 400),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        backgroundColor: AppTheme.violet.withOpacity(0.12),
                        valueColor: const AlwaysStoppedAnimation(AppTheme.violet),
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

class CosmicLoadingScreen extends StatelessWidget {
  final String? message;
  final bool useLottie;

  const CosmicLoadingScreen({super.key, this.message, this.useLottie = false});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDeep,
    body: CosmicLoader(message: message, useLottie: useLottie),
  );
}