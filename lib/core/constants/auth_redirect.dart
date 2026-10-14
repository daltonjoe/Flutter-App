import 'package:flutter/foundation.dart' show kIsWeb;

// Web: uygulamanin kendi adresi (Chrome); mobil: derin baglanti semasi (bundle ID ile degisecek).
String get kAuthRedirectUrl =>
    kIsWeb ? Uri.base.origin : 'soulbound://login-callback';
