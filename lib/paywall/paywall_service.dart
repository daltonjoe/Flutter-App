import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _kIosKey = String.fromEnvironment('RC_IOS_KEY');
const String _kAndroidKey = String.fromEnvironment('RC_ANDROID_KEY');
const String kProEntitlement = 'pro';

class PaywallOffer {
  const PaywallOffer({this.yearly, this.monthly});
  final Package? yearly;
  final Package? monthly;
  bool get hasPlans => yearly != null || monthly != null;
}

class PaywallService {
  static bool _ready = false;

  static String get _key {
    if (defaultTargetPlatform == TargetPlatform.iOS) return _kIosKey;
    if (defaultTargetPlatform == TargetPlatform.android) return _kAndroidKey;
    return '';
  }

  static bool get supported => !kIsWeb && _key.isNotEmpty;

  static Future<bool> init() async {
    if (!supported) return false;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      if (!_ready) {
        await Purchases.configure(
          PurchasesConfiguration(_key)..appUserID = uid,
        );
        _ready = true;
      } else {
        await Purchases.logIn(uid);
      }
      return true;
    } catch (e) {
      debugPrint('paywall init error: $e');
      return false;
    }
  }

  static Future<PaywallOffer?> loadOffer() async {
    if (!await init()) return null;
    try {
      final offerings = await Purchases.getOfferings();
      final cur = offerings.current;
      return PaywallOffer(
        yearly: cur?.annual,
        monthly: cur?.monthly,
      );
    } catch (e) {
      debugPrint('paywall offerings error: $e');
      return null;
    }
  }

  static bool _cancelled(Object e) {
    if (e is PlatformException) {
      return PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError;
    }
    return false;
  }

  /// true = tamamlandi, false = kullanici iptal etti; hata firlatir.
  static Future<bool> buyPackage(Package p) async {
    try {
      await Purchases.purchasePackage(p);
      return true;
    } catch (e) {
      if (_cancelled(e)) return false;
      debugPrint('paywall purchase error: $e');
      rethrow;
    }
  }

  static Future<bool> restore() async {
    if (!await init()) throw StateError('paywall_unsupported');
    final info = await Purchases.restorePurchases();
    return info.entitlements.active.containsKey(kProEntitlement);
  }

  static Future<bool> hasPro() async {
    if (!await init()) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(kProEntitlement);
    } catch (e) {
      debugPrint('paywall hasPro error: $e');
      return false;
    }
  }
}
