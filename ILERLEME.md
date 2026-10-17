# Ephemerai redesign: ilerleme ve çalışma kuralları
Branch: redesign/faz-9a. UI_ENHANCED.MD'yi Trae ile uyguluyoruz.

## Çalışma düzeni (Trae için)
- Tek seferde TEK prompt. Rapor kısa olsun (ne yapıldı, silme yok, emin olunmayan nokta).
- Promptlardaki dosya yolları "#" ile başlar (#lib/...); dosyayı aramadan doğrudan oku.
- Dart dosyaları CRLF, locale json (./locales/*.json) LF: korunmalı.
- Yeni i18n anahtarı 8 dile eklenir (ar,de,en,es,fr,it,pt,tr). AppLocalizations eksik anahtarda anahtarın kendisini gösterir (İngilizce fallback yok).
- Gereksiz dosya üretme. Silmeden önce izin iste; adayları TEMIZLIK.md'ye yaz. Silme izni verilmişse bile önce referans taraması yap; referans varsa silme, raporla.
- Dokunulmaz: route/argüman, Supabase, session, paywall, silme akışları, onboarding mantığı, Ask güvenlik/kota/notlar/rapor akışları.
- Doğrulama: flutter analyze (önce/sonra issue sayısı) + json doğrulama + CRLF/LF kontrolü.

## Yapılanlar
Token'lar, global zemin, ortak bileşenler, hap alt menü, Glyph altyapısı (commit'lendi).
Today tamam (4 prompt + mini). OverlineText, CosmicChip dolduruldu.
Chart tamam: 5 prompt + Düzeltme A, B, C. Chip sekmeler, gezegen glyph şeridi (PlanetGlyphIcon, tek renk), hero sahnesi (glow, 3 halka, OrbitStars 15 yıldız), karusel (0.80, kart 168, nokta göstergesi), gezegen kartı (burç PNG opaklık 0.60, 12°36′, "7. Ev", Rx), açılır "7. Ev nedir?", Chart Points, tek kartta Element + Polarity + Modality halkaları (+ çıkarım cümlesi), Rx sheet, CTA düzeni.
Chart kapanış silmeleri (izinli) büyük kısmı yapıldı: _valenceIcon, mloc, 7 locale anahtarı, _OrbitDot*, eski _element* zinciri.
Ask tamam: mod chip'leri CosmicSegmented (natal/forecast/synastry, altın lens), AskHero (boş durum, mod başlığı; natal chip'leri artık ActiveProfile özetinden Güneş/Ay/Yükselen; forecast ay seçici chip; synastry iki avatar + altın bağ), öneri kartları (CosmicCard compact + Glyph + kademeli fade), cam hap composer (tek blur, 40px gönder dairesi), mesajlar (kullanıcı sağda Navy Raised hap; asistan balonsuz + ✦ yalnız ilk balonda, aksiyon satırı Hatırla/Kopyala + rapor linki), StarTyping, CosmicChip tabanlı context strip, ilk-kez bilgi kartı (shared_preferences 'ask_first_note_seen'). Mantık (güvenlik/kota/not/rapor/bridge/draft) korundu.
ActiveProfile özeti + avatar: ActiveProfileProvider'a `ActiveProfileSummary` (id, name, sun/moon/asc sign id, birthTimeKnown) tek satır select ile eklendi; RefIds.signIndex ile 0 tabanlı burç indeksi. `ProfileAvatarButton` (32px, navyRaised, gold@%60 çerçeve, Güneş burcu PNG / baş harf) Today, Chart ve Ask başlık satırlarına eklendi; dokununca Profile sekmesi (kProfileTab=2). main_shell'e `kProfileTab` sabiti eklendi.
Profile (profile_switcher_page) tamam: kimlik kartı (Güneş·Ay·Yükselen glyph satırı + 600ms altın çizgi, Cormorant ad, "Güneş · Yengeç" chip'leri, arkada Güneş burcu PNG %4→%7 nefes), Güneş-burcu PNG'li profil şeridi (altın halka, aktif 2px gold + "Aktif", "Yeni" chip'i), doğum kartı (tek blur; 2 sütun, localized tarih, saat rozeti Kesin/Bilinmiyor + time_hint, kalem ikonu → edit_birth_data), yolculuk kartı (CheckinService 60 gün; seri + ruh hali sayısı, 600ms CountUp → StreakPage), tek "Ayarlar" satırı, kart dışı silme metin butonu + bottom-sheet onay (Vazgeç gold / Sil statusDanger). Supabase okuma/silme mantığı aynen.
Settings (settings_page) tamam: token eşlemesi (Switch onGold/gold, hairline divider, gold seçili/aktif, navyDeep sheet'ler, statusDanger, mist@%50 disabled), satırlara 20px mist ikon, skeleton navyRaised, `_sectionLabel` → OverlineText, scrollBottomPadding. Dil seçici davranışı (Arapça gizli) korundu; hold-to-delete/AccountDeletionService/signOut/UserSettingsService mantığı aynen.

## Kalan
Profile + Settings TAMAM. Kalan: Prompt 10 temizlik, Match.
Bu aşamadan kalan kararlar: ad çakışması uyarısı, Yaklaşık doğum saati kesinliği (backend), Premium kartı, "Yöntem" satırı, Arapça dil seçici görünürlüğü kararı.
Faz 9a temizlik (Bölüm A) tamam: chart_page.dart, AstroGlyphs gezegen kayıtları (sun…pluto) ve SoulBoundAssets silindi; prefernottosay.png yolu düzeltildi; background2.* + 4 italik font silindi; ar.json paritesi (496 anahtar) sağlandı.
Cihaz görsel doğrulaması bekleyen: Düzeltme C (şerit ikonları, iç halka yıldızları, 3 halkalı kart dar ekran/Arapça).

## Güncel token/bileşen adları
AppColors: bgVoid, navyDeep, navyRaised, hairline, gold, goldGlow, goldDeep, starlight, mist, dim, info, onGold, statusSupportive, statusChallenging, statusDanger, statusNeutral, themeLove/Career/Identity/Health, elementFire/Earth/Air/Water, borderStrong, textDisabled(eski).
AppSizes: bottomNavInset, bottomNavHeight, scrollBottomPadding(context), ctaHeight 52. AppShadows: cardShadow, glow(color,blur,alpha). AppRadius.card 24, md 16.
Bileşenler: CosmicCard(blur; sayfa başına en fazla 2-3 blur), CosmicCtaButton, CosmicOutlineButton, CosmicChip(label,selected,onTap), CosmicSegmented(items,selected,onChanged), OverlineText, Glyph(name,size,color,decorative) (gezegen adları PlanetGlyphIcon'a yönlenir). Chart: PlanetCarousel, PlanetGlyphStrip, PlanetHero, OrbitStars, HouseMeaningPanel, ChartExtras, ChartBalanceSection.
Varlıklar: RdAssets.planetImage, RdAssets.signIcon (assets/images/zodiac/*.png), assets/images/redesign/planets/*.png, assets/fonts/NotoSansSymbols2-Regular.ttf.
Ask modları kodda: natal (Haritam/Öz) | forecast (Öngörü/Seyir) | synastry (Köprü). kAskTab=4. Tab sırası: Today0, Chart1, Ask4, Match3(flag), Profile2.

## Açık işler
- Ekranlar bottomNavInset → scrollBottomPadding'e geçecek: streak, match, natal_report, planet_report, placement_content, transit_detail, forecast_result/selection, edit_birth_data, redesign_detail (today, redesign_chart, ask_page, settings ve profile_switcher yapıldı).
- SVG glyph'ler sonra (kSvgGlyphs boş; element SVG'leri yok). Cormorant/Inter assets'e paketlenecek.
- dim (3.4:1) ve textMuted gövde metninde kullanılıyorsa düzelt. Colors.black: EntryRoute.notFound Scaffold (main.dart).
- Today açık işleri: mood mini ikonu hafta şeridinde, hero glow nefes, bildirim priming, SVG mood yüzleri, Story paylaşım kartı, akşam yansıtma, gün noktası açıklaması.
- Chart açık işleri: gezegen kartı tek cümle yorum (içerik kaynağı yok), element glyph SVG, ASC/MC sembol, natal çark/transit, doğum saati üç kademeli kesinlik (backend, kullanıcıya sor). (Başlıktaki aktif profil avatarı yapıldı.)
- Prompt 10: planet_carousel.dart'ı kart/şerit/hero dosyalarına böl (onaylandı), burç→element renk eşlemesini tek yere al, eski token sayımı.
- Locale: 8 dil = 508 anahtar. Ask: 4 anahtar (first_note.body/ok, copy, copied). Profile+Settings: 8 anahtar (profile_switcher.active/new_short/time_exact/time_unknown/time_hint/journey.title/journey.streak/journey.moods). Parite tam; placeholder yok.
