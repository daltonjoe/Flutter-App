# Ephemerai redesign: ilerleme
Branch: redesign/faz-9a. UI_ENHANCED.MD uygulandi (Today, Chart, Ask, Profile, Settings, Match, hap menu, Glyph, token gecisi). Kurallar: DEVIR_TESLIM.md.
Baseline: analyze 38 info/0/0, test 49, locale 504 (8 dil).

## Yapildi (ozet)
Tum ekran redesign'lari, alias->token (app_theme shim, eski alias'lar, planet_report/placement_content, diag68, splash_backdrop, kok artiklar silindi), emoji->glyph (planet_hero, redesign_detail, natal hero chip), Match v2 (burc karti, glyph uclusu, akis/surtunme cubugu, CosmicChip, ProfileAvatarButton, alt gradyan maskesi), Ask spacing tokenlari, token log maskeleme, mc/quincunx SVG silindi.

## KULLANICI ISLERI (once)
1. Son tur commit + push: `git add -A -- . ":!CLAUDE.md"` ; commit ; `git push origin redesign/faz-9a`. (Match B1/B2, mc/quincunx silme, TEMIZLIK.md bekliyor olabilir; `git status --short` ile dogrula.)
2. Cihaz kontrolu: Match (cubuk centigi gorunur mu, saatsiz profil rozeti, Arapca RTL, alt maske, avatar), Chart hero fallback glyph, Detay gezegen karti, loader renkleri, Ask (balon/genislik/ay secici/typing), forecast secim ay ikonu, Profile (rozet, silme sheet), Settings hold-to-delete, hesap silme akisi (diag68 kalkti), acilis/giris/onboarding.
3. Sorun yoksa PR ac: redesign/faz-9a -> main (once `git fetch`, `git log main..origin/main` bos olmali). main'e dogrudan push YOK.
4. Cormorant + Inter font dosyalarini ver (pubspec asset; once sor), native splash zemin rengi karari.

## Kalan kod isleri (kucuk)
- TAMAMLANDI (2026-10-19): Element SVG wiring - kSvgGlyphs'e fire/earth/air/water eklendi; glyph.dart cizim sirasi duzeltildi (kSvgGlyphs once, null sonra) ki SVG gercekten cizilsin. chart_balance_section.dart element lejantinda Glyph kullaniyor (renk element tokeni). 10 gezegen SVG'si (sun..pluto) + asc.svg referanssiz; TEMIZLIK.md'ye eklendi, silinmedi.
- TAMAMLANDI (2026-10-19): Yetim locale anahtari `planet_report.title` 8 dilden silindi (504 -> 503). Diger planet_report.* (house/retrograde/loading/unexpected_error/time_unknown) hala referansli. `chart.planet_report` de referanssiz ama kapsam disi (silinmedi).
- Anahtarsiz emojiler (forecast_result/selection donem+kategori, natal _keywordIcons/_getIconForTitle, redesign_detail '✦'): karar bekliyor, istenirse ayri tur.
- match_v2 bayragi Supabase feature_flags'ten (varsayilan false). Kalici acilirsa v1 (_aspectRow, v1 _body) silinir.
- Cihazda cubuk kisa kalirsa Match flow cubugu `v` olcekleme (sqrt). Duzeltme D (cihaz goruntuleriyle).
- TEMIZLIK.md: kalan acik maddeler orada; CRLF/LF uyarisi zararsiz.

## Backlog (yeni chat, sirayla istenirse)
Today: hafta seridi mood mini ikonu, hero glow nefes, bildirim izni on metni, SVG mood yuzleri, Story karti, aksam yansitma, gun noktasi anlami, today.* ceviri gozden gecirme.
Chart: gezegen karti tek cumle yorum, sayi sayma, natal cark/transit.
Profile: ad cakismasi uyarisi, Premium karti, Yontem satiri, yolculuk karti kayitli yorum sayisi, harf fallback Turkce i.
Ask: + baglam butonu, sohbet gecmisi, dipnot satiri (8 dil yeni anahtar).
Token'siz Ask sabitleri (radius 20, 14/10, 0.80/0.82, sheet 200/40/48) BILINCLI kalir, tekrar acma.

## Backend gerektirenler
Ask kaynak chip JSON + response_type; birth_time_accuracy (kademeli saat rozeti); pair-seviyesi Ask baglami (yeni type); uyum yuzdesi (karar: eklenmiyor).

## Acik kararlar
Arapca dil secicide gizli: acilsin mi. Yontem satiri icin gercek ev sistemi/efemeris. Anahtarsiz emojiler. Native splash rengi.

## SIRADAKI PROJE: ONBOARDING
Redesign bittiginde onboarding'e gec. Dosyalar: lib/screens/onboarding/* (consent, language, name, sign_in, register, flow, link_account), main.dart EntryRoute. Onboarding artik kapsamda; mantik/route/auth/session/Supabase yazma yine DOKUNMA (yalniz acik izinle). Ilk adim: salt okunur Asama A (ekran goruntuleri + akis haritasi), sonra tek faz plani. Cinsiyet gorseli ve onboarding_link_account kaydirma cihaz dogrulamasi hala acik.
