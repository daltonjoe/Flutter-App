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

- SİLİNDİ (faz-9a temizlik): locales/*.json → `ask.disclaimer` (8 dil). "Eğlence/öz-yansıtma; sağlık-hukuk-finans tavsiyesi değildir" notunu gösteren widget'lar bu işte kaldırıldı (ask_page.dart composer altı, today_page.dart altı); kodda sıfır referans doğrulandı ve 8 dilden silindi.

## Profile + Settings yeniden tasarımı (faz-9a)

- SİLİNDİ (faz-9a temizlik): locales/*.json → `profile_switcher.add` ("Add new profile", 8 dil). Profil şeridindeki ekleme chip'i artık kısa etiket `profile_switcher.new_short` kullanıyor; uzun varyant kodda okunmuyordu, 8 dilden silindi.
- SİLİNDİ (faz-9a temizlik): lib/screens/settings_page.dart:962 — `MISSING TOKENS` yorum satırı artık güncel değildi (skeleton rengi `bgSurface` yerine `navyRaised`, divider token'ı `hairline`); sıfır kod referansı, silindi.
- KALAN (kullanılmayan anahtar): locales/*.json → `sen.new_profile` (8 dil) kodda okunmuyor (profil ekleme akışı `profile_switcher.new_short`/onboarding rotalarını kullanıyor). Silme adayı.


- lib/redesign/splash/splash_backdrop.dart: video_layer sonrasi referanssiz (flow ve sign-in artik kullanmiyor). Silme adayi, izin gerekir.

## Ask klavye + composer revizesi (faz-9a)

- SİLİNDİ (faz-9a temizlik): locales/*.json → `ask.empty_title`, `ask.empty_body`, `ask.suggest_1/2/3` (8 dil). Ask boş durumu artık moda özel `ask.empty_title.$mode`, `ask.empty_body.$mode` ve `ask.suggest.$mode.N` anahtarlarını kullanıyor; eski tekil anahtarlar kodda okunmuyordu, 8 dilden silindi.
- SİLİNDİ: locales/*.json → `ask.disclaimer` (8 dil). Yukarıdaki "Dipnot kaldırma" bölümünde kayıtlıydı; faz-9a temizlik turunda silindi.
- lib/screens/ask_page.dart:1340 — `/// AV: balonlar sÄ±rayla ...` yorum satırı mojibake (UTF-8 bozulması); metin düzeltmesi veya silme adayı.
- AYRI İŞ (bu turda düzeltilmedi): lib/screens/ask_page.dart — hardcode ölçüler: kullanıcı balonu 20/14/10 (~739-744), balon genişlikleri 0.80/0.82 (~732/~795), ay seçici sheet sabitleri 12/200/40/48/16 (~329-386), composer blur 12 (~1063).

## Faz-9a temizlik turu (FAZ 5)

- SİLİNDİ: locales/{ar,de,en,es,fr,it,pt,tr}.json → 7 anahtar (`ask.empty_title`, `ask.empty_body`, `ask.suggest_1/2/3`, `ask.disclaimer`, `profile_switcher.add`); 8 dilde parite korundu (508 → 501). Moda özel `ask.empty_title.$mode`/`ask.empty_body.$mode`/`ask.suggest.$mode.N` aileleri korundu.
- SİLİNDİ: lib/screens/settings_page.dart — `MISSING TOKENS` yorum satırı (güncel değildi).
- BIRAKILDI (referanslı): lib/theme/app_theme.dart — re-export shim; 10+ dosya (main.dart, language_switcher/selector, planet_report_page, placement_content_page, natal_report_page, forecast_*_page, analysis/*) bu yolu import ediyor. Silme = çok dosyalı refaktör; bu turda dokunulmadı.
- SİLİNDİ (2026-10-19, sıfır kod referansı): lib/redesign/splash/splash_backdrop.dart — `SplashBackdrop` kodda hiçbir yerde import/çağrılmıyor (yalnız kendi dosyası; TEMIZLIK.md dokümanı hariç). Silindi.
- SİLİNDİ (2026-10-19, sıfır kod referansı): lib/widgets/city_search_field.dart — `CitySearchField` kodda hiçbir yerde import/çağrılmıyor (yalnız kendi dosyası + cosmic_input_field.dart:62 doc yorumu). Silindi.
- ADAY (yetim kaldı): assets/images/redesign/earth_home.jpg + lib/redesign/assets_map.dart:5 `RdAssets.earthHome` — tek kullanıcı splash_backdrop.dart:75 idi ve silindi; asset dosyası ve pubspec.yaml kaydı yerinde kaldı (pubspec DOKUNMA). Kullanılmıyor; temizlik adayı.
- YENİ ADAY: assets/glyphs/ klasörü yalnız .gitkeep (SVG asset yok, `kSvgGlyphs` boş) ve pubspec.yaml'da asset olarak bildirilmiş (assets/glyphs/). FAZ 2d SVG işi için placeholder; SVG eklenmezse klasör+bildirim kaldırılabilir.
- TARAMA SONUCU: assets/ altındaki tüm görsel/video/json dosyaları (logo, relationship, zodiac, redesign/planets, earth_home, background, loading_1.mp4, cities.json) kodda referanslı; referanssız asset bulunamadı.

