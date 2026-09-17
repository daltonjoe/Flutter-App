// lib/presentation/widgets/components/cosmic_loader.dart
// SoulBound Cosmic Sanctum — reusable loading state component
//
// Wraps the project's existing ZodiacOrbitalAnimation and AppLoader so the
// loading state is consistent with the Cosmic Sanctum visual language.
// Business logic and animation logic are untouched.

import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../i18n/app_localizations.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../widgets/animations/zodiac_orbital_animation.dart';

/// Inline loading widget. Place wherever a screen section is pending.
///
/// [message] — override the rotating message string. If null, cycles through
/// localised loader messages automatically every 3 s.
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

class _CosmicLoaderState extends State<CosmicLoader>
    with SingleTickerProviderStateMixin {
  static const List<String> _messageKeys = [
    'loader.msg_1',
    'loader.msg_2',
    'loader.msg_3',
    'loader.msg_4',
    'loader.msg_5',
    'loader.msg_6',
    'loader.msg_7',
  ];

  int _msgIndex = 0;
  Timer? _msgTimer;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    if (widget.message == null) {
      _msgTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _fadeCtrl.reverse().then((_) {
          if (!mounted) return;
          setState(
              () => _msgIndex = (_msgIndex + 1) % _messageKeys.length);
          _fadeCtrl.forward();
        });
      });
    }
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message =
        widget.message ?? t(context, _messageKeys[_msgIndex]);

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

            // Message + progress region
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLg(
                          color: AppColors.textPrimary,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
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
