import json, io, os
# Kullanım: yeni anahtar = KEYS'e satır ekle; yeni dil = LANGS'a kod ekle + satırlara sona değer ekle.
# Eksik değer en'e düşer (uyarı basılır). Mevcut anahtarlara dokunmaz (idempotent).
LANGS = ["tr", "en", "de", "fr", "es", "pt", "it"]
KEYS = [
 # key, tr, en, de, fr, es, pt, it
]

def load(p):
    return json.load(io.open(p, encoding="utf-8-sig")) if os.path.exists(p) else None

en = load("locales/en.json") or {}
for i, loc in enumerate(LANGS):
    p = f"locales/{loc}.json"
    d = load(p)
    if d is None:
        d = dict(en)  # yeni dil: en'den başlar, eksikler uyarılır
        print(f"UYARI {loc}: dosya yoktu, en kopyasından oluşturuldu")
    added = fb = 0
    for row in KEYS:
        k = row[0]
        vals = row[1:]
        v = vals[i] if i < len(vals) and vals[i] else None
        if v is None:
            v = vals[LANGS.index("en")]
            fb += 1
        if k not in d:
            d[k] = v
            added += 1
    io.open(p, "w", encoding="utf-8", newline="\n").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
    print(f"{loc}: +{added} eklendi, {fb} en'e düştü")