// lib/services/ad_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ödüllü reklam gösterim sonucu.
enum RewardedResult { shown, dismissed, unavailable, error }

/// AdMob altyapısı (yalnızca Android/iOS).
///
/// Ödüllü reklam gösterimi ve gizlilik (UMP/ATT) yönetimi. Kredi istemcide
/// verilmez; yalnızca SSV ile sunucu tarafında eklenir. Web ve masaüstünde
/// tüm çağrılar no-op'tur.
class AdService {
  AdService._();

  // --- Resmi Google TEST birim ID'leri (yalnızca kDebugMode'da kullanılır).
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  // --- Gerçek birim ID'leri --dart-define ile verilir.
  static const String _rewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
  );
  static const String _rewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
  );
  static const String _bannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
  );
  static const String _bannerIos = String.fromEnvironment('ADMOB_BANNER_IOS');

  // --- Debug test cihaz ID'leri (virgüllü) --dart-define ile verilir.
  static const String _rawTestDeviceIds = String.fromEnvironment(
    'ADMOB_TEST_DEVICE_IDS',
  );

  static Future<void>? _initFuture;
  static bool _privacyOptionsRequired = false;

  /// Önbellekteki tek ödüllü reklam ve yükleme durumu.
  static RewardedAd? _rewarded;
  static bool _loadingRewarded = false;

  /// UMP onayı alınıp MobileAds başlatıldıysa true; reklam istekleri buna bağlıdır.
  static bool _adsReady = false;

  /// Yalnızca Android/iOS'ta true; web ve masaüstünde false.
  static bool get supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Ödüllü reklam birim ID'si; release'te dart-define boşsa null (reklam kapalı).
  static String? get rewardedUnitId {
    if (!supported) return null;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _resolveUnitId(_rewardedAndroid, _testRewardedAndroid);
    }
    return _resolveUnitId(_rewardedIos, _testRewardedIos);
  }

  /// Banner reklam birim ID'si; release'te dart-define boşsa null (reklam kapalı).
  static String? get bannerUnitId {
    if (!supported) return null;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _resolveUnitId(_bannerAndroid, _testBannerAndroid);
    }
    return _resolveUnitId(_bannerIos, _testBannerIos);
  }

  /// Gizlilik seçenekleri giriş noktası gerekli mi (Ayarlar satırı için).
  static bool get privacyOptionsRequired => _privacyOptionsRequired;

  /// Desteklenen platformda bir kez çalışır (idempotent).
  ///
  /// Sıra: UMP onay güncellemesi + formu -> iOS ATT (UMP'ye bırakıldı) ->
  /// canRequestAds() true ise MobileAds başlatma.
  static Future<void> init() {
    return _initFuture ??= _init();
  }

  static Future<void> _init() async {
    if (!supported) return;
    try {
      // 1) UMP: onay bilgisini güncelle, gerekliyse formu göster.
      await _requestConsentInfoUpdate(
        ConsentRequestParameters(consentDebugSettings: _debugSettings),
      );
      await ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {
        if (e != null) {
          debugPrint('AdService UMP form error: ${e.errorCode} ${e.message}');
        }
      });
      _privacyOptionsRequired =
          (await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus()) ==
          PrivacyOptionsRequirementStatus.required;

      // 2) iOS ATT: UMP/AdMob IDFA mesajı tetikler (Dart API'sinde çağrı yok).

      // 3) Onay varsa SDK'yı başlat.
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            maxAdContentRating: MaxAdContentRating.pg,
            testDeviceIds: _debugTestDeviceIds.isEmpty
                ? null
                : _debugTestDeviceIds,
          ),
        );
        _adsReady = true;
        _preloadRewarded();
      }
    } catch (e) {
      // Sessizce kapalı kalır; reklam yüklenemezse unavailable döner.
      debugPrint('AdService.init failed: $e');
    } finally {
      // Hazır değilse (hata, ağ yok, onay yok) sonraki init() yeniden denesin.
      if (!_adsReady) _initFuture = null;
    }
  }

  /// Gizlilik seçenekleri formunu gösterir.
  static Future<void> showPrivacyOptionsForm() async {
    if (!supported) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((FormError? e) {
        if (e != null) {
          debugPrint(
            'AdService privacy options error: ${e.errorCode} ${e.message}',
          );
        }
      });
    } catch (e) {
      debugPrint('AdService.showPrivacyOptionsForm failed: $e');
    }
  }

  /// Ödüllü reklamı önceden yükler (önbellekte en fazla bir adet tutulur).
  static void _preloadRewarded() {
    if (!supported || !_adsReady || _rewarded != null || _loadingRewarded) {
      return;
    }
    final unitId = rewardedUnitId;
    if (unitId == null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewarded = ad;
        },
        onAdFailedToLoad: (e) {
          _loadingRewarded = false;
          debugPrint('AdService rewarded load failed: ${e.code} ${e.message}');
        },
      ),
    );
  }

  /// Ödüllü reklamı gösterir. Kredi istemcide EKLENMEZ; yalnızca sunucu SSV
  /// callback'i ile verir ([shown] yalnızca ödül kazanıldığında döner).
  ///
  /// Önbellekte hazır reklam yoksa [unavailable] döner ve yükleme tetiklenir.
  /// Gösterim bitince bir sonraki reklam önceden yüklenir.
  static Future<RewardedResult> showRewarded({required String userId}) async {
    if (!supported) return RewardedResult.unavailable;
    final unitId = rewardedUnitId;
    if (unitId == null) return RewardedResult.unavailable;
    if (!_adsReady) {
      unawaited(init()); // init yarım kaldıysa yeniden dener
      return RewardedResult.unavailable;
    }
    final ad = _rewarded;
    if (ad == null) {
      _preloadRewarded();
      return RewardedResult.unavailable;
    }
    _rewarded = null;
    final completer = Completer<RewardedResult>();
    void finish(RewardedResult r) {
      if (!completer.isCompleted) completer.complete(r);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        finish(RewardedResult.dismissed);
        _preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        debugPrint('AdService rewarded show failed: ${e.code} ${e.message}');
        a.dispose();
        finish(RewardedResult.error);
        _preloadRewarded();
      },
    );
    // SSV: userId show'dan ÖNCE set edilir; sunucu ödülü bu kimlikle verir.
    try {
      await ad.setServerSideOptions(
        ServerSideVerificationOptions(userId: userId),
      );
    } catch (e) {
      debugPrint('AdService rewarded SSV set failed: $e');
      ad.dispose();
      _preloadRewarded();
      return RewardedResult.error;
    }
    try {
      ad.show(onUserEarnedReward: (_, _) => finish(RewardedResult.shown));
    } catch (e) {
      debugPrint('AdService rewarded show threw: $e');
      ad.dispose();
      return RewardedResult.error;
    }
    return completer.future;
  }

  static Future<void> _requestConsentInfoUpdate(
    ConsentRequestParameters params,
  ) {
    final completer = Completer<void>();
    void done() {
      if (!completer.isCompleted) completer.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(params, done, (
      FormError e,
    ) {
      debugPrint('AdService consent update error: ${e.errorCode} ${e.message}');
      done();
    });
    // Ağ adımı takılırsa akış devam eder; form etkileşimi bu sınırın dışındadır.
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => debugPrint('AdService consent update timed out'),
    );
  }

  static String? _resolveUnitId(String defined, String test) {
    final value = defined.trim();
    if (value.isNotEmpty) return value;
    return kDebugMode ? test : null;
  }

  static ConsentDebugSettings? get _debugSettings {
    final ids = _debugTestDeviceIds;
    if (!kDebugMode || ids.isEmpty) return null;
    return ConsentDebugSettings(testIdentifiers: ids);
  }

  static List<String> get _debugTestDeviceIds {
    if (!kDebugMode) return const <String>[];
    return _rawTestDeviceIds
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
