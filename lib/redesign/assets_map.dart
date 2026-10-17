// Redesign varlık (asset) yolları.
class RdAssets {
  RdAssets._();

  static const String earthHome = 'assets/images/redesign/earth_home.jpg';

  // Gezegen görseli yolu: chart anahtarı -> küçük harf dosya adı.
  static String planetImage(String planetKey) =>
      'assets/images/redesign/planets/${planetKey.toLowerCase()}.png';

  /// Burç görsellerinin dosya adları: 0 = Koç … 11 = Balık.
  static const List<String> _signFiles = <String>[
    'aries',
    'taurus',
    'gemini',
    'cancer',
    'leo',
    'virgo',
    'libra',
    'scorpio',
    'sagittarius',
    'capricorn',
    'aquarius',
    'pisces',
  ];

  /// Burç görseli yolu (0 tabanlı indeks).
  static String signIcon(int signIndex) =>
      'assets/images/zodiac/${_signFiles[signIndex % _signFiles.length]}.png';
}
