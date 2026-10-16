// Redesign varlık (asset) yolları.
class RdAssets {
  RdAssets._();

  static const String earthHome = 'assets/images/redesign/earth_home.jpg';

  // Gezegen görseli yolu: chart anahtarı -> küçük harf dosya adı.
  static String planetImage(String planetKey) =>
      'assets/images/redesign/planets/${planetKey.toLowerCase()}.png';
}
