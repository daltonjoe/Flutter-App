import json, os
LANGS = ["en", "de", "tr", "fr", "es", "pt", "it"]
KEYS = {
        "match.filter.all": ["All"]*2 + ["Tümü"] + ["All"]*4,
    "match.filter.harmony": ["Harmony"]*2 + ["Uyum"] + ["Harmony"]*4,
    "match.filter.tension": ["Tension"]*2 + ["Gerilim"] + ["Tension"]*4,}
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