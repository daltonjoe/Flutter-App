import json, os

LOCALES_DIR = "locales"
LANGS = ["en", "tr", "de", "fr", "es", "pt", "it"]

KEYS = {
 "ask.lang_reset": (
  "Language changed, so the chat was reset.",
  "Dil değiştiği için sohbet sıfırlandı.",
  "Die Sprache wurde geändert, der Chat wurde zurückgesetzt.",
  "La langue a changé, la conversation a été réinitialisée.",
  "Cambió el idioma, así que se reinició el chat.",
  "O idioma mudou, então o chat foi reiniciado.",
  "La lingua è cambiata, quindi la chat è stata azzerata."),
}

for i, lang in enumerate(LANGS):
    path = os.path.join(LOCALES_DIR, lang + ".json")
    with open(path, encoding="utf-8-sig") as f:
        data = json.load(f)
    added = 0
    for k, vals in KEYS.items():
        if k not in data:
            data[k] = vals[i]
            added += 1
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(lang, "added", added)