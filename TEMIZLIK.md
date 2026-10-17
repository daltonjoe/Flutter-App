# Temizlik Adayları

Mevcut koddaki ölü/tekrar/gereksiz parçalar. Silme yalnızca kullanıcı ilgili maddeye açıkça izin verirse yapılır.

- lib/redesign/chart/planet_carousel.dart:40 — burç indeksi -> element rengi eşlemesi (`_elementColor`); aynı tabloyu tekrar ettiği `lib/screens/chart_page.dart` bu işte silindi, artık tek kopya; yine de ortak bir yardımcıya taşınabilir (Prompt 10).

## Düzeltme C (Chart)

- lib/services/chart_repository.dart:112-121 — `elementDistribution` tüm `planets.values` (Moon dahil) üzerinden hesaplanıyor; `ChartBalanceSection` ise birthTimeKnown=false iken Moon'u dışlıyor. Tek okuyan eski `lib/screens/chart_page.dart` bu işte silindi → erişilebilir ekranda artık okunmuyor; backend'e gönderim `lib/models/natal_chart_response.dart:55` üzerinden sürüyor.
- SİLİNDİ: lib/core/constants/astro_glyphs.dart — 10 gezegen Unicode kaydı (sun…pluto) kaldırıldı; `lib/screens/today_page.dart` koşulu artık `PlanetGlyphIcon.supports()`'u da geçerli sayıyor, render zaten PlanetGlyphIcon üzerinden (davranış aynı). Burç/açı/asc/mc/element kayıtları kaldı.

## Faz 9a — Eski tasarım / ölü kod temizliği

- SİLİNDİ: lib/screens/chart_page.dart — yalnızca ölü `/chart` rota'sı ve active_chart_page bayrak dalından referans alıyordu; ikisi de bu işte kaldırıldı.
- SİLİNDİ: lib/redesign/redesign_flags.dart — tek sabit `kUseRedesign` içeriyordu; tüm kullanımları yeni tasarıma sabitlendi.
- lib/theme/app_theme.dart:17-21 — `unnecessary_import` (5 adet): bu import'lar `cosmic_theme.dart` re-export'u ile örtüşüyor; dosya başlığı "Direct imports needed" dediği için dokunulmadı.
- SİLİNDİ: lib/models/zodiac_sign.dart:71-79 — `SoulBoundAssets` sınıfı (referanssız; var olmayan `assets/images/logo/soulbound_logo.png`'a işaret ediyordu).
- DÜZELTİLDİ: lib/screens/onboarding/onboarding_gender_page.dart:33 — `prefernottosay.png` → `prefer_not_to_say.png` (dosya adı değişmedi, kod düzeltildi; görsel artık yüklenir).
- SİLİNDİ: assets/images/logo/background2.jpg, assets/images/logo/background2.png, assets/fonts/LibreCaslonCondensed-Italic.ttf, assets/fonts/LibreCaslonCondensed-MediumItalic.ttf, assets/fonts/LibreCaslonCondensed-SemiBoldItalic.ttf, assets/fonts/LibreCaslonCondensed-BoldItalic.ttf (hepsi referanssız; italikler pubspec'te kayıtlı değildi).
- KALAN: assets/fonts "Libre Caslon Condensed" family'si kodda hiçbir yerde kullanılmıyor (yalnız pubspec kaydı) — family + 4 normal ağırlık temizlik adayı. assets/glyphs/ yalnız .gitkeep (SVG yok; `kSvgGlyphs` boş, kod Unicode fallback'e düşüyor).
- tools_add_keys_k33.py — tek seferlik anahtar ekleme script'i (birth_data.*, sen.edit_birth_data zaten uygulandı); temizlik adayı, bu işte silinmedi.

## Dipnot kaldırma + Ask balon düzleştirme

- KALAN (kullanılmayan anahtar): locales/*.json → `ask.disclaimer` (8 dil). "Eğlence/öz-yansıtma; sağlık-hukuk-finans tavsiyesi değildir" notunu gösteren widget'lar bu işte kaldırıldı (ask_page.dart composer altı, today_page.dart altı); anahtar/değer locale kuralı gereği silinmedi. Silme adayı.

## Profile + Settings yeniden tasarımı (faz-9a)

- KALAN (kullanılmayan anahtar): locales/*.json → `profile_switcher.add` ("Add new profile", 8 dil). Profil şeridindeki ekleme chip'i artık kısa etiket `profile_switcher.new_short` kullanıyor; uzun varyant kodda okunmuyor. Silme adayı.
- lib/screens/settings_page.dart:962 — `MISSING TOKENS` yorum satırı artık güncel değil: skeleton rengi `bgSurface` yerine `navyRaised` kullanılıyor, divider token'ı `hairline` olarak uygulandı. Yorum güncellenebilir/silinebilir.
- KALAN (kullanılmayan anahtar): locales/*.json → `sen.new_profile` (8 dil) kodda okunmuyor (profil ekleme akışı `profile_switcher.new_short`/onboarding rotalarını kullanıyor). Silme adayı.

