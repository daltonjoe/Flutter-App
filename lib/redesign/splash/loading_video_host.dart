// lib/redesign/splash/loading_video_host.dart
// Uygulama genelinde paylaşılan tek yükleme videosu controller'ı.
//
// Amaç: ekranlar arası geçişte video yeniden başlamasın (başa sarmasın) ve
// poster flaşı olmasın. Controller uygulama açılışında bir kez hazırlanır;
// ekranda [LoadingVideo] olduğu sürece oynar, hiç yokken duraklar (dispose
// edilmez, böylece yeniden açılışta anında hazırdır).

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Tek yükleme görseli: sessiz, döngüde oynayan video.
const String kLoadingVideoAsset = 'assets/videos/loading_1.mp4';

/// Paylaşılan video controller'ı (singleton).
class LoadingVideoHost with WidgetsBindingObserver {
  LoadingVideoHost._();

  static final LoadingVideoHost instance = LoadingVideoHost._();

  /// Hazır olduğunda initialize edilmiş controller ile dolar.
  /// null ise henüz hazır değil (poster gösterilir).
  final ValueNotifier<VideoPlayerController?> controller =
      ValueNotifier<VideoPlayerController?>(null);

  int _refs = 0;
  bool _creating = false;
  bool _errorLogged = false;
  bool _observing = false;

  /// Videoyu arka planda hazırlar. Beklenmez, açılışı geciktirmez;
  /// hata debugPrint ile yutulur.
  void warmUp() {
    if (controller.value != null || _creating) return;
    // Hareket azaltma açıkken video hiç hazırlanmaz (yalnız poster kalır).
    if (WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations) {
      debugPrint('LoadingVideo: reduceMotion');
      return;
    }
    _creating = true;
    _create();
  }

  /// Ekranda bir [LoadingVideo] göründüğünde çağrılır.
  void attach() {
    _refs++;
    warmUp();
    if (_refs == 1) _play();
  }

  /// Ekrandan bir [LoadingVideo] kalktığında çağrılır.
  void detach() {
    if (_refs > 0) _refs--;
    if (_refs == 0) controller.value?.pause();
  }

  Future<void> _create() async {
    _bindObserver();
    try {
      final c = VideoPlayerController.asset(
        kLoadingVideoAsset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      c.addListener(_onVideoValue);
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(true);
      controller.value = c;
      debugPrint('LoadingVideo: ready');
      if (_refs > 0) await c.play();
    } catch (e) {
      debugPrint('LoadingVideo init failed: ${e.runtimeType} $e');
    } finally {
      _creating = false;
    }
  }

  void _play() {
    final c = controller.value;
    if (c == null) return;
    c.play();
    debugPrint('LoadingVideo: playing');
  }

  /// Oynatma sırasında oluşan hatayı (tek sefer) loglar.
  void _onVideoValue() {
    final c = controller.value;
    if (c == null || _errorLogged || !c.value.hasError) return;
    _errorLogged = true;
    debugPrint('LoadingVideo value error: ${c.value.errorDescription}');
  }

  void _bindObserver() {
    if (_observing) return;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = controller.value;
    if (c == null) return;
    if (state == AppLifecycleState.resumed) {
      if (_refs > 0) c.play();
    } else if (state == AppLifecycleState.detached) {
      // Uygulama kapanıyor: controller'ı serbest bırak.
      _release();
    } else {
      c.pause();
    }
  }

  void _release() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    final c = controller.value;
    controller.value = null;
    c?.dispose();
  }
}
