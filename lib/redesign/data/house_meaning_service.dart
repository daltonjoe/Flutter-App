// YER TUTUCU. Faz 8'de Supabase'e bağlanacak. null => panel yer tutucu metin gösterir.
class HouseMeaningService {
  const HouseMeaningService._();

  static Future<String?> fetch({
    required int house,
    required String locale,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return null;
  }
}
