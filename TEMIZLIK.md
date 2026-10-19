# Temizlik Adayları

Mevcut koddaki ölü/tekrar/gereksiz parçalar. Silme yalnızca kullanıcı ilgili maddeye açıkça izin verirse yapılır.

- lib/redesign/chart/planet_carousel.dart:40 — burç indeksi -> element rengi eşlemesi (`_elementColor`); aynı tabloyu tekrar ettiği `lib/screens/chart_page.dart` bu işte silindi, artık tek kopya; yine de ortak bir yardımcıya taşınabilir (Prompt 10).

## Düzeltme C (Chart)

- lib/services/chart_repository.dart:112-121 — `elementDistribution` tüm `planets.values` (Moon dahil) üzerinden hesaplanıyor; `ChartBalanceSection` ise birthTimeKnown=false iken Moon'u dışlıyor. Tek okuyan eski `lib/screens/chart_page.dart` bu işte silindi → erişilebilir ekranda artık okunmuyor; backend'e gönderim `lib/models/natal_chart_response.dart:55` üzerinden sürüyor.
- SİLİNDİ: lib/core/constants/astro_glyphs.dart — 10 gezegen Unicode kaydı (sun…pluto) kaldırıldı; `lib/screens/today_page.dart` koşulu artık `PlanetGlyphIcon.supports()`'u da geçerli sayıyor, render zaten PlanetGlyphIcon üzerinden (davranış aynı). Burç/açı/asc/mc/element kayıtları kaldı.

## Faz 9a — Eski tasarım / ölü kod temizliği

- SİLİNDİ: lib/screens/chart_page.dart — yalnızca ölü `/chart` rota'sı ve active_chart_page bayrak dalından referans alıyordu; ikisi de bu işte kaldırıldı.
- SİLİNDİ: lib/redesign/redesign_flags.dart — tek sabit `kUseRedesign` içeriyordu; tüm kullanımları yeni tasarıma sabitlendi.
- lib/theme/app_theme.dart:17-21 — `unnecessary_import` (5 adet): bu import'lar `cosmic_theme.dart` re-export'u ile örtüşüyor; dosya başlığı "Direct imports needed" dediği için dokunulmadı. TAMAMLANDI (2026-10-19): app_theme.dart shim'i kaldırıldı (10 importer `cosmic_theme.dart`'a, `AppTheme.*` kullanımları karşılıklarına çevrildi), dosya silindi.
- SİLİNDİ: lib/models/zodiac_sign.dart:71-79 — `SoulBoundAssets` sınıfı (referanssız; var olmayan `assets/images/logo/soulbound_logo.png`'a işaret ediyordu).
- DÜZELTİLDİ: lib/screens/onboarding/onboarding_gender_page.dart:33 — `prefernottosay.png` → `prefer_not_to_say.png` (dosya adı değişmedi, kod düzeltildi; görsel artık yüklenir).
- SİLİNDİ: assets/images/logo/background2.jpg, assets/images/logo/background2.png, assets/fonts/LibreCaslonCondensed-Italic.ttf, assets/fonts/LibreCaslonCondensed-MediumItalic.ttf, assets/fonts/LibreCaslonCondensed-SemiBoldItalic.ttf, assets/fonts/LibreCaslonCondensed-BoldItalic.ttf (hepsi referanssız; italikler pubspec'te kayıtlı değildi).
- KALAN: assets/fonts "Libre Caslon Condensed" family'si kodda hiçbir yerde kullanılmıyor (yalnız pubspec kaydı) — family + 4 normal ağırlık temizlik adayı. assets/glyphs/ yalnız .gitkeep (SVG yok; `kSvgGlyphs` boş, kod Unicode fallback'e düşüyor).
- tools_add_keys_k33.py — tek seferlik anahtar ekleme script'i (birth_data.*, sen.edit_birth_data zaten uygulandı); temizlik adayı, bu işte silinmedi. TAMAMLANDI (2026-10-19): diğer kök script'lerle (tools_add_keys.py, tools_check_keys.py, scan-flutter.js) birlikte silindi.

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
- AYRI İŞ (bu turda düzeltilmedi): lib/screens/ask_page.dart — hardcode ölçüler: kullanıcı balonu 20/14/10 (~739-744), balon genişlikleri 0.80/0.82 (~732/~795), ay seçici sheet sabitleri 12/200/40/48/16 (~329-386), composer blur 12 (~1063). KISMEN TAMAMLANDI (2026-10-19): birebir tokenı olan ölçüler tokena çevrildi (sheet 12→`AppSpacing.cardGap`, 16→`AppSpacing.md`; balon dikey `margin`/`padding` 4→`AppSpacing.xs`). KALAN (birebir uygun token yok): radius 20, balon `padding` 14/10, genişlik 0.80/0.82, sheet 200/40/48, composer blur 12.

## Ask token turu + kök temizlik (2026-10-19)

- TAMAMLANDI (2026-10-19): lib/redesign/ask/ask_hero.dart — `SizedBox` 8/16/12 → `AppSpacing.sm`/`md`/`cardGap`; connector `horizontal: 4` → `AppSpacing.xs`.
- TAMAMLANDI (2026-10-19): lib/redesign/ask/star_typing.dart — padding 8/4 → `AppSpacing.sm`/`xs`; `SizedBox(width: 4)` → `AppSpacing.xs` (app_dimensions import eklendi).
- TAMAMLANDI (2026-10-19): lib/main.dart:100-103 — `TOKEN=` debug logu artık token değerini yazmıyor (yalnız `present`/`null`); `kDebugMode` sarması korundu.
- TAMAMLANDI (2026-10-19): kök tek seferlik script'ler silindi — scan-flutter.js, tools_add_keys.py, tools_add_keys_k33.py, tools_check_keys.py (kaynak referansı yok).
- ATLANDI: lib/diag68.dart — silinmedi; 8 dosya import edip çağırıyor (main.dart, settings_page.dart, account_deletion_service.dart, active_chart_page.dart, onboarding_sign_in/register/flow/consent_page.dart).
- ATLANDI (birebir/uygun token yok): ask_hero ikon 22 / glyph 16 / connector width 72, star_typing yıldız 8/10/14 + 900ms döngü + 0.30 opaklık tabanı, ask_add ikon 18.

## Faz-9a temizlik turu (FAZ 5)

- SİLİNDİ: locales/{ar,de,en,es,fr,it,pt,tr}.json → 7 anahtar (`ask.empty_title`, `ask.empty_body`, `ask.suggest_1/2/3`, `ask.disclaimer`, `profile_switcher.add`); 8 dilde parite korundu (508 → 501). Moda özel `ask.empty_title.$mode`/`ask.empty_body.$mode`/`ask.suggest.$mode.N` aileleri korundu.
- SİLİNDİ: lib/screens/settings_page.dart — `MISSING TOKENS` yorum satırı (güncel değildi).
- TAMAMLANDI (2026-10-19): lib/theme/app_theme.dart — re-export shim; 10 dosya (main.dart, language_switcher/selector, planet_report_page, placement_content_page, natal_report_page, forecast_*_page, analysis/*) `cosmic_theme.dart`'a taşındı, `AppTheme.*` kullanımları karşılıklarına çevrildi (kalan 0), dosya silindi. (Önceki turda BIRAKILMIŞTI.)
- SİLİNDİ (2026-10-19, sıfır kod referansı): lib/redesign/splash/splash_backdrop.dart — `SplashBackdrop` kodda hiçbir yerde import/çağrılmıyor (yalnız kendi dosyası; TEMIZLIK.md dokümanı hariç). Silindi.
- SİLİNDİ (2026-10-19, sıfır kod referansı): lib/widgets/city_search_field.dart — `CitySearchField` kodda hiçbir yerde import/çağrılmıyor (yalnız kendi dosyası + cosmic_input_field.dart:62 doc yorumu). Silindi.
- SİLİNDİ (2026-10-19, sıfır kod referansı): lib/screens/planet_report_page.dart + lib/screens/placement_content_page.dart — ikisi de yalnız kendi dosyasından + doc yorumlarından referanslı; `lib/redesign/detail/redesign_detail_page.dart` ikisini ikame etti. Silindi.
- ADAY (yetim kaldı): assets/images/redesign/earth_home.jpg + lib/redesign/assets_map.dart:5 `RdAssets.earthHome` — tek kullanıcı splash_backdrop.dart:75 idi ve silindi; asset dosyası ve pubspec.yaml kaydı yerinde kaldı (pubspec DOKUNMA). Kullanılmıyor; temizlik adayı.
- YENİ ADAY: assets/glyphs/ klasörü yalnız .gitkeep (SVG asset yok, `kSvgGlyphs` boş) ve pubspec.yaml'da asset olarak bildirilmiş (assets/glyphs/). FAZ 2d SVG işi için placeholder; SVG eklenmezse klasör+bildirim kaldırılabilir. TAMAMLANDI (2026-10-19): klasörde 34 SVG var, placeholder .gitkeep silindi.
- TARAMA SONUCU: assets/ altındaki tüm görsel/video/json dosyaları (logo, relationship, zodiac, redesign/planets, earth_home, background, loading_1.mp4, cities.json) kodda referanslı; referanssız asset bulunamadı.

## Match v2 glyph/çip revizesi (faz-9a)

- lib/screens/match_page.dart:882 — `_signCell(int? id, bool show, String? pid)` artık yalnız `show=false` ile çağrılıyor (Güneş/Yükselen satırları `_signLine`'a geçti); `if (show && id != null)` dalı ölü, `show` parametresi gereksiz. Silme izne bağlı. TAMAMLANDI (2026-10-19): ölü dal + `show` parametresi kaldırıldı; imza `_signCell(String? pid)` (kullanılmayan `id` de kaldırıldı); `separatorBuilder (_, i)` → `(_, __)`.

## Emoji → glyph dönüşümü (faz-9a)

- lib/redesign/data/planet_card_view_model.dart:30 (+ :45-56 `_emojis`, :82) — `emoji` alanı bu turda hiçbir tüketici tarafından okunmuyor (planet_hero.dart:202 ve redesign_detail_page `_emoji` glyph'e çevrildi); alan kullanıcı kuralı gereği silinmedi, silme adayı. TAMAMLANDI (2026-10-19): `emoji` alanı + `_emojis` map'i silindi (kaynak hardcoded map; Supabase/servis değil).
- lib/screens/planet_report_page.dart:50-59 (`_meta` emoji map'i), :176, :307 — legacy sayfa emoji akışı (hedef 5 dosya dışı); `PlanetGlyphIcon`/`Glyph` ile dönüştürülebilir, silme değil dönüşüm adayı. TAMAMLANDI (2026-10-19): dosya sıfır kod referansı nedeniyle silindi.
- lib/screens/forecast_result_page.dart:37-42 + :288-295 ve lib/screens/forecast_selection_page.dart:22-43 — dönem (`🌅🗓️🌙✨`) ve kategori (`❤️💼💰🏥`) emojileri; astrolojik anahtar yok, dönüştürülmedi (süs/metafor).


