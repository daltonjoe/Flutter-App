import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../assets_map.dart';
import 'splash_clock.dart';

/// Tek yükleme görseli: sessiz, döngüde oynayan video.
const String kLoadingVideoAsset = 'assets/videos/loading_1.mp4';

/// Açılış ve hesaplama ekranlarının video arka planı.
///
/// Video hazır olana kadar [RdAssets.earthHome] posteri görünür; hazır olunca
/// posterin üstüne kısa bir fade ile biner. Video başlatılamazsa, web'de veya
/// hareket azaltma açıkken yalnız statik poster kalır. Hata sessizce yutulur;
/// uygulama açılışı asla bloklanmaz.
class LoadingVideo extends StatefulWidget {
  const LoadingVideo({super.key, this.showTexts = false});

  /// true ise splash başlık/tagline metinleri video üstüne bindirilir.
  final bool showTexts;

  @override
  State<LoadingVideo> createState() => _LoadingVideoState();
}

class _LoadingVideoState extends State<LoadingVideo>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _started = false;

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
    WidgetsBinding.instance.addObserver(this);
    if (widget.showTexts && _textsClock.value < 1.0) _textsClock.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (kIsWeb || MediaQuery.disableAnimationsOf(context)) return;
    try {
      final c = VideoPlayerController.asset(
        kLoadingVideoAsset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = c;
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(true);
      if (!mounted) {
        await c.dispose();
        _controller = null;
        return;
      }
      await c.play();
      setState(() => _ready = true);
    } catch (e) {
      debugPrint('LoadingVideo init failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !_ready) return;
    if (state == AppLifecycleState.resumed) {
      c.play();
    } else {
      c.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textsClock.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
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
                  RdAssets.earthHome,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                AnimatedOpacity(
                  opacity: _ready ? 1 : 0,
                  duration: fade,
                  curve: Curves.easeOut,
                  child: _video(),
                ),
              ],
            ),
          ),
          if (widget.showTexts) _texts(context),
        ],
      ),
    );
  }

  Widget _video() {
    final c = _controller;
    if (c == null || !_ready) return const SizedBox.shrink();
    final size = c.value.size;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(c),
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
