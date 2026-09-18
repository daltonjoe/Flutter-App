enum ZodiacSign {
  aries,
  taurus,
  gemini,
  cancer,
  leo,
  virgo,
  libra,
  scorpio,
  sagittarius,
  capricorn,
  aquarius,
  pisces;

  String get assetPath => 'assets/images/zodiac/$name.png';

  static ZodiacSign fromString(String sign) {
    switch (sign.toLowerCase().trim()) {
      case 'aries':
      case 'koç':
      case 'koc':
        return ZodiacSign.aries;
      case 'taurus':
      case 'boğa':
      case 'boga':
        return ZodiacSign.taurus;
      case 'gemini':
      case 'ikizler':
        return ZodiacSign.gemini;
      case 'cancer':
      case 'yengeç':
      case 'yengec':
        return ZodiacSign.cancer;
      case 'leo':
      case 'aslan':
        return ZodiacSign.leo;
      case 'virgo':
      case 'başak':
      case 'basak':
        return ZodiacSign.virgo;
      case 'libra':
      case 'terazi':
        return ZodiacSign.libra;
      case 'scorpio':
      case 'akrep':
        return ZodiacSign.scorpio;
      case 'sagittarius':
      case 'yay':
        return ZodiacSign.sagittarius;
      case 'capricorn':
      case 'oğlak':
      case 'oglak':
        return ZodiacSign.capricorn;
      case 'aquarius':
      case 'kova':
        return ZodiacSign.aquarius;
      case 'pisces':
      case 'balık':
      case 'balik':
        return ZodiacSign.pisces;
      default:
        return ZodiacSign.aries;
    }
  }
}

abstract class SoulBoundAssets {
  static const String logo = 'assets/images/logo/soulbound_logo.png';

  static String getZodiac(String signName) =>
      ZodiacSign.fromString(signName).assetPath;
}