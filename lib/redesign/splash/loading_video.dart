import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import 'loading_video_host.dart';
import 'splash_clock.dart';

/// Uygulamanın kendi yıldızlı arka planı (CosmicBackground ile aynı görsel).
/// Video hazır olana kadar (ve hareket azaltma açıkken) bu görünür.
const String kLoadingPosterAsset = 'assets/images/logo/background.jpg';

/// "Yükleme katmanı göster" talebi. Kendisi bir şey çizmez; ekranda
/// göründüğü sürece [LoadingVideoLayer] tam ekran olur, mesajı o çizer.
/// Ağaçta görünmeyen yerlerde (başka sekme, üstü kapanmış sayfa) talep
/// bildirmez ([TickerMode] kapalı).
class LoadingVideo extends StatefulWidget {
  const LoadingVideo({super.key, this.message, this.showTexts = false});

  /// Katmanın ortasında gösterilen yükleme mesajı.
  final String? message;

  /// true ise mesaj yerine splash başlık/tagline metinleri gösterilir.
  final bool showTexts;

  @override
  State<LoadingVideo> createState() => _LoadingVideoState();
}

class _LoadingVideoState extends State<LoadingVideo> {
  LoadingVideoRequest? _req;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.of(context);
    final host = LoadingVideoHost.instance;
    if (visible && _req == null) {
      _req = host.attach(message: widget.message, showTexts: widget.showTexts);
    } else if (!visible && _req != null) {
      host.detach(_req!);
      _req = null;
    }
  }

  @override
  void didUpdateWidget(LoadingVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    final r = _req;
    if (r != null &&
        (r.message != widget.message || r.showTexts != widget.showTexts)) {
      LoadingVideoHost.instance.update(
        r,
        message: widget.message,
        showTexts: widget.showTexts,
      );
    }
  }

  @override
  void dispose() {
    final r = _req;
    if (r != null) LoadingVideoHost.instance.detach(r);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// MaterialApp.builder içinde, Navigator'ın ÜSTÜNDE yaşayan kalıcı katman.
///
/// Talep yokken 1x1 pikseldir (ağaçta ve DOM'da kalır, hiç unmount olmaz,
/// video duraklatılır); talep varken tam ekran olur. Ağaç yapısı iki durumda
/// da aynıdır: yalnız Positioned ölçüleri değişir.
class LoadingVideoLayer extends StatelessWidget {
  const LoadingVideoLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final host = LoadingVideoHost.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([host.revision, host.controller]),
      builder: (context, _) {
        final active = host.active;
        final c = host.controller.value;
        final req = host.top;
        final reduce =
            MediaQuery.disableAnimationsOf(context) && !kForceLoadingVideo;
        final showVideo =
            !reduce &&
            c != null &&
            c.value.isInitialized &&
            !c.value.hasError &&
            c.value.size != Size.zero;
        return Positioned(
          left: 0,
          top: 0,
          right: active ? 0 : null,
          bottom: active ? 0 : null,
          width: active ? null : 1,
          height: active ? null : 1,
          child: AbsorbPointer(
            absorbing: active,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.bgDeep),
                  Image.asset(
                    kLoadingPosterAsset,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  showVideo ? _video(c) : const SizedBox.shrink(),
                  (active && req != null)
                      ? _overlay(context, req)
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        );
      },
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

  Widget _overlay(BuildContext context, LoadingVideoRequest req) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!req.showTexts)
            IgnorePointer(
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
          if (req.showTexts)
            const _SplashTexts()
          else
            _message(context, req.message),
        ],
      ),
    );
  }

  // Mesaj + ilerleme bloğu: ortak çapa ([AppSizes.loadingMessageAlignment]).
  Widget _message(BuildContext context, String? message) {
    return SafeArea(
      child: Align(
        alignment: AppSizes.loadingMessageAlignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message != null && message.isNotEmpty) ...[
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
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

/// Splash başlık/tagline metinleri (2100 → 2500 ms arası sönümlenir).
class _SplashTexts extends StatefulWidget {
  const _SplashTexts();

  @override
  State<_SplashTexts> createState() => _SplashTextsState();
}

class _SplashTextsState extends State<_SplashTexts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: SplashClock.durationMs),
    value: SplashClock.progress,
  );
  late final Animation<double> _fade = _clock.drive(
    Tween<double>(
      begin: 1,
      end: 0,
    ).chain(CurveTween(curve: const Interval(0.84, 1.0))),
  );

  @override
  void initState() {
    super.initState();
    if (_clock.value < 1.0) _clock.forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
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
                style: AppTextStyles.h1(color: AppColors.mist),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
