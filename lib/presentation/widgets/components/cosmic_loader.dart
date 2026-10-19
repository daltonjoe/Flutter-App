// lib/presentation/widgets/components/cosmic_loader.dart
// SoulBound Cosmic Sanctum — reusable loading state component
//
// Yükleme görseli (video + mesaj + ilerleme) MaterialApp.builder içindeki
// kalıcı katmanda ([LoadingVideoLayer]) tam ekran çizilir. Bu widget yalnız
// o katmanı talep eder; kendisi bir şey çizmez.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../i18n/app_localizations.dart';
import '../../../redesign/splash/loading_video.dart';

/// Inline loading widget. Place wherever a screen section is pending.
///
/// Görünür olduğu sürece yükleme katmanı tam ekran açılır.
class CosmicLoader extends StatelessWidget {
  const CosmicLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return LoadingVideo(
      message: message ?? t(context, 'onboarding.calculating.title'),
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
