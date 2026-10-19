// lib/redesign/splash/loading_video_host.dart
// Uygulama genelinde paylaşılan tek yükleme videosu controller'ı + talep listesi.
//
// Video, MaterialApp.builder içindeki kalıcı [LoadingVideoLayer] katmanında
// yaşar ve hiç unmount olmaz (web'de unmount <video>'yu DOM'dan çıkarıp
// oynatmayı bozuyordu). Ekranlar [LoadingVideo] ile yalnız talep bildirir:
// talep varken katman tam ekran olur ve video oynar, yokken 1x1 pikselde
// durur ve duraklatılır.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Tek yükleme görseli: sessiz, döngüde oynayan video.
const String kLoadingVideoAsset = 'assets/videos/loading_1.mp4';

/// Yalniz gelistirme teshisi: --dart-define=FORCE_LOADING_VIDEO=true ile
/// hareket azaltma kapisi yok sayilir. Varsayilan false: davranis degismez.
const bool kForceLoadingVideo = bool.fromEnvironment('FORCE_LOADING_VIDEO');

/// Bir ekranın "yükleme katmanı göster" talebi.
class LoadingVideoRequest {
  LoadingVideoRequest({this.message, this.showTexts = false});

  String? message;
  bool showTexts;
}

/// Paylaşılan video controller'ı ve talep listesi (singleton).
class LoadingVideoHost with WidgetsBindingObserver {
  LoadingVideoHost._();

  static final LoadingVideoHost instance = LoadingVideoHost._();

  /// Hazır olduğunda initialize edilmiş controller ile dolar.
  final ValueNotifier<VideoPlayerController?> controller =
      ValueNotifier<VideoPlayerController?>(null);

  /// Talep listesi değiştikçe artar (katman yeniden çizilir).
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  final List<LoadingVideoRequest> _reqs = <LoadingVideoRequest>[];
  bool _creating = false;
  bool _observing = false;
  bool _recovering = false;
  bool _changePending = false;
  int _retries = 0;

  bool get active => _reqs.isNotEmpty;
  LoadingVideoRequest? get top => _reqs.isEmpty ? null : _reqs.last;

  /// Videoyu arka planda hazırlar. Beklenmez, açılışı geciktirmez;
  /// hata debugPrint ile yutulur.
  void warmUp() {
    if (controller.value != null || _creating) return;
    // Hareket azaltma açıkken video hiç hazırlanmaz (yalnız poster kalır).
    final reduce = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduce && !kForceLoadingVideo) return;
    _creating = true;
    _create();
  }

  /// Yükleme katmanı talebi ekler.
  LoadingVideoRequest attach({String? message, bool showTexts = false}) {
    if (_reqs.isEmpty) _retries = 0;
    final r = LoadingVideoRequest(message: message, showTexts: showTexts);
    _reqs.add(r);
    _changed();
    return r;
  }

  void update(
    LoadingVideoRequest r, {
    String? message,
    bool showTexts = false,
  }) {
    r.message = message;
    r.showTexts = showTexts;
    _changed();
  }

  void detach(LoadingVideoRequest r) {
    if (_reqs.remove(r)) _changed();
  }

  // initState/dispose build sırasında çağrılır; bildirimi mikro göreve
  // erteler (build içinde setState olmasın) ve aynı kare içindeki
  // detach+attach çiftlerini tek bildirimde birleştirir.
  void _changed() {
    if (_changePending) return;
    _changePending = true;
    scheduleMicrotask(() {
      _changePending = false;
      revision.value++;
      _sync();
    });
  }

  void _sync() {
    if (active) {
      warmUp();
      _play();
    } else {
      controller.value?.pause();
    }
  }

  Future<void> _create() async {
    _bindObserver();
    VideoPlayerController? c;
    try {
      c = VideoPlayerController.asset(
        kLoadingVideoAsset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(true);
      c.addListener(_onVideoValue);
      controller.value = c;
      if (active) await _play();
    } catch (e) {
      debugPrint('LoadingVideo init failed: ${e.runtimeType} $e');
      try {
        await c?.dispose();
      } catch (_) {}
    } finally {
      _creating = false;
    }
  }

  Future<void> _play() async {
    final c = controller.value;
    if (c == null || !active) return;
    try {
      await c.play();
    } catch (e) {
      debugPrint('LoadingVideo play failed: ${e.runtimeType} $e');
    }
  }

  /// Controller hataya düştüyse ya da boyutu 0 ise yeniden oluşturur.
  void _onVideoValue() {
    final c = controller.value;
    if (c == null) return;
    final v = c.value;
    if (v.hasError || (v.isInitialized && v.size == Size.zero)) {
      unawaited(_recover());
    }
  }

  Future<void> _recover() async {
    if (_recovering || _retries >= 5) return;
    _recovering = true;
    _retries++;
    final old = controller.value;
    debugPrint(
      'LoadingVideo: recreate #$_retries '
      'error=${old?.value.errorDescription} size=${old?.value.size}',
    );
    controller.value = null;
    old?.removeListener(_onVideoValue);
    try {
      await old?.dispose();
    } catch (_) {}
    _creating = false;
    _recovering = false;
    warmUp();
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
      if (active) c.play();
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
