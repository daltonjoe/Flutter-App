# Temizlik Adayları

Mevcut koddaki ölü/tekrar/gereksiz parçalar. Silme yalnızca kullanıcı ilgili maddeye açıkça izin verirse yapılır.

- lib/redesign/chart/planet_carousel.dart:40 — burç indeksi -> element rengi eşlemesi (`_elementColor`); aynı tabloyu tekrar ettiği `lib/screens/chart_page.dart` bu işte silindi, artık tek kopya; yine de ortak bir yardımcıya taşınabilir (Prompt 10).

## Düzeltme C (Chart)

- lib/services/chart_repository.dart:112-121 — `elementDistribution` tüm `planets.values` (Moon dahil) üzerinden hesaplanıyor; `ChartBalanceSection` ise birthTimeKnown=false iken Moon'u dışlıyor. Tek okuyan eski `lib/screens/chart_page.dart` bu işte silindi → erişilebilir ekranda artık okunmuyor; backend'e gönderim `lib/models/natal_chart_response.dart:55` üzerinden sürüyor.
- lib/core/constants/astro_glyphs.dart — `AstroGlyphs.glyphs` içindeki 10 gezegen Unicode kaydı `Glyph`'in Unicode dalından kullanılmıyor (PlanetGlyphIcon kancasına düşüyor); ancak `lib/screens/today_page.dart:1804` `AstroGlyphs.glyphFor()` ile doğrudan okuyor (venus/saturn/sun/mars) → KALIYOR; o çağrı `PlanetGlyphIcon`'a taşınırsa kayıtlar silinebilir.

## Faz 9a — Eski tasarım / ölü kod temizliği

- SİLİNDİ: lib/screens/chart_page.dart — yalnızca ölü `/chart` rota'sı ve active_chart_page bayrak dalından referans alıyordu; ikisi de bu işte kaldırıldı.
- SİLİNDİ: lib/redesign/redesign_flags.dart — tek sabit `kUseRedesign` içeriyordu; tüm kullanımları yeni tasarıma sabitlendi.
- lib/theme/app_theme.dart:17-21 — `unnecessary_import` (5 adet): bu import'lar `cosmic_theme.dart` re-export'u ile örtüşüyor; dosya başlığı "Direct imports needed" dediği için dokunulmadı.
- lib/models/zodiac_sign.dart:71-79 — `SoulBoundAssets` sınıfı hiçbir yerden referans almıyor (public olduğu için analyzer görmüyor) ve var olmayan `assets/images/logo/soulbound_logo.png`'a işaret ediyor; silinmedi.
- lib/screens/onboarding/onboarding_gender_page.dart:33 — kod `assets/images/logo/prefernottosay.png` arıyor ama mevcut dosya `prefer_not_to_say.png` (ad uyuşmuyor, görsel yüklenmez).
- Referanssız asset'ler (silinmedi): assets/images/logo/background2.jpg, assets/images/logo/background2.png, assets/images/logo/prefer_not_to_say.png, assets/fonts/LibreCaslonCondensed-Italic.ttf, assets/fonts/LibreCaslonCondensed-MediumItalic.ttf, assets/fonts/LibreCaslonCondensed-SemiBoldItalic.ttf, assets/fonts/LibreCaslonCondensed-BoldItalic.ttf (ikincil fontlar pubspec'te kayıtlı değil).
- tools_add_keys_k33.py — tek seferlik anahtar ekleme script'i (birth_data.*, sen.edit_birth_data zaten uygulandı); temizlik adayı, bu işte silinmedi.
