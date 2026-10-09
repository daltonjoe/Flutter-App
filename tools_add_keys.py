import json, os
LANGS = ["en", "de", "tr", "fr", "es", "pt", "it"]
KEYS = {
         "match.ask.cta": ["Ask AI"]*2 + ["AI'ya sor"] + ["Ask AI"]*4,
    "match.ask.q1": ["How does this feel between us?"]*2 + ["Bu aramızda nasıl hissettirir?"] + ["How does this feel between us?"]*4,
    "match.ask.q2": ["Where could this create friction?"]*2 + ["Bu nerede sürtüşme yaratabilir?"] + ["Where could this create friction?"]*4,
    "match.ask.q3": ["How can we work with this?"]*2 + ["Bununla nasıl çalışabiliriz?"] + ["How can we work with this?"]*4,
    
    
    }
base = os.path.join(os.path.dirname(os.path.abspath(__file__)), "locales")
for i, lg in enumerate(LANGS):
    p = os.path.join(base, lg + ".json")
    with open(p, encoding="utf-8-sig") as f:
        d = json.load(f)
    n = 0
    for k, v in KEYS.items():
        if k not in d:
            d[k] = v[i]
            n += 1
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
    print(lg, "+%d" % n, len(d))