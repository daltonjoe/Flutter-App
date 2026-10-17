# Temizlik Adayları

Mevcut koddaki ölü/tekrar/gereksiz parçalar. Silme yalnızca kullanıcı ilgili maddeye açıkça izin verirse yapılır.

- lib/redesign/chart/planet_carousel.dart:40 — burç indeksi -> element rengi eşlemesi (`_elementColor`) lib/screens/chart_page.dart:64 ile aynı tabloyu iki kez tekrar ediyor; tek bir yardımcıya taşınabilir (Prompt 10).

## Düzeltme C (Chart)

- lib/services/chart_repository.dart:112-121 — `elementDistribution` tüm `planets.values` (Moon dahil) üzerinden hesaplanıyor; `ChartBalanceSection` ise birthTimeKnown=false iken Moon'u dışlıyor. Erişilebilir bir ekran artık bunu okumuyor (tek okuyan eski `lib/screens/chart_page.dart`, yalnız ölü `/chart` route'unda; hiçbir yerden navigate edilmiyor) → Ay uyumsuzluğu pratikte kapandı; backend'e gönderim `lib/models/natal_chart_response.dart:55` üzerinden sürüyor.
- lib/core/constants/astro_glyphs.dart — `AstroGlyphs.glyphs` içindeki 10 gezegen Unicode kaydı `Glyph`'in Unicode dalından kullanılmıyor (PlanetGlyphIcon kancasına düşüyor); ancak `lib/screens/today_page.dart:1804` `AstroGlyphs.glyphFor()` ile doğrudan okuyor (venus/saturn/sun/mars) → KALIYOR; o çağrı `PlanetGlyphIcon`'a taşınırsa kayıtlar silinebilir.
