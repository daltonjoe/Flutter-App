import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import 'loading_video_host.dart';
import 'splash_clock.dart';

/// Uygulamanın kendi yıldızlı arka planı (CosmicBackground ile aynı görsel).
/// Video hazır olana kadar poster olarak bu görünür.
const String kLoadingPosterAsset = 'assets/images/logo/background.jpg';

/// Açılış ve hesaplama ekranlarının video arka planı.
///
/// Video, ekranlar arası paylaşılan tek controller ([LoadingVideoHost]) ile
/// çizilir; bu widget kendi controller'ını oluşturmaz. Controller hazır
/// olana kadar poster ([kLoadingPosterAsset]) görünür, hazır olunca 250 ms
/// fade ile video üstüne biner. Hareket azaltma açıkken yalnız poster kalır.
class LoadingVideo extends StatefulWidget {
  const LoadingVideo({super.key, this.showTexts = false});

  /// true ise splash başlık/tagline metinleri video üstüne bindirilir.
  final bool showTexts;

  @override
  State<LoadingVideo> createState() => _LoadingVideoState();
}

class _LoadingVideoState extends State<LoadingVideo>
    with SingleTickerProviderStateMixin {
  bool _attached = false;

  // showTexts: SplashBackdrop ile aynı metin sönümü (2100 → 2500 ms).
  late final AnimationController _textsClock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: SplashClock.durationMs),
    value: SplashClock.progress,
  );
  late final Animation<double> _textsFade = _textsClock.drive(
    Tween<double>(
      begin: 1,
      end: 0,
    ).chain(CurveTween(curve: const Interval(0.84, 1.0))),
  );

  @override
  void initState() {
    super.initState();
    if (widget.showTexts && _textsClock.value < 1.0) _textsClock.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_attached) return;
    // Erişilebilirlik: hareket azaltma açıkken videoya hiç bağlanılmaz.
    if (MediaQuery.disableAnimationsOf(context)) {
      debugPrint('LoadingVideo: reduceMotion');
      return;
    }
    _attached = true;
    LoadingVideoHost.instance.attach();
  }

  @override
  void dispose() {
    if (_attached) LoadingVideoHost.instance.detach();
    _textsClock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.bgDeep),
          RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  kLoadingPosterAsset,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                if (!reduceMotion)
                  ValueListenableBuilder<VideoPlayerController?>(
                    valueListenable: LoadingVideoHost.instance.controller,
                    builder: (context, controller, _) {
                      final ready = controller?.value.isInitialized ?? false;
                      return AnimatedOpacity(
                        opacity: ready ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: ready
                            ? _video(controller!)
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
              ],
            ),
          ),
          if (widget.showTexts) _texts(context),
        ],
      ),
    );
  }

  Widget _video(VideoPlayerController controller) {
    final size = controller.value.size;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _texts(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _textsFade,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  t(context, 'rd.splash.title'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppTextStyles.heroTitle(),
                ),
                const Spacer(),
                Text(
                  t(context, 'rd.splash.tagline'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTextStyles.h1(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
