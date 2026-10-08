import json, os

LOCALES_DIR = "locales"
LANGS = ["en", "tr", "de", "fr", "es", "pt", "it"]

KEYS = {
"ask.about.button": ["Ask AI about details","Detayları AI'ya sor","Details an die AI fragen","Demander les détails à l'AI","Preguntar detalles a la AI","Perguntar detalhes à AI","Chiedi i dettagli all'AI"],
"ask.about.placement": ["My {planet} is in {sign}, {house}. How should I use this placement in my life?","{planet} {sign} burcunda, {house} konumunda. Bu konumu hayatımda nasıl kullanmalıyım?","{planet} steht in {sign}, {house}. Wie sollte ich diese Position in meinem Leben nutzen?","{planet} est en {sign}, {house}. Comment utiliser cette position dans ma vie ?","{planet} está en {sign}, {house}. ¿Cómo debo usar esta posición en mi vida?","{planet} está em {sign}, {house}. Como devo usar esta posição na minha vida?","{planet} è in {sign}, {house}. Come dovrei usare questa posizione nella mia vita?"],
"ask.about.nohouse": ["My {planet} is in {sign}. How should I use this placement in my life?","{planet} {sign} burcunda. Bu konumu hayatımda nasıl kullanmalıyım?","{planet} steht in {sign}. Wie sollte ich diese Position in meinem Leben nutzen?","{planet} est en {sign}. Comment utiliser cette position dans ma vie ?","{planet} está en {sign}. ¿Cómo debo usar esta posición en mi vida?","{planet} está em {sign}. Como devo usar esta posição na minha vida?","{planet} è in {sign}. Come dovrei usare questa posizione nella mia vita?"],
"ask.about.asc": ["My ascendant is {sign}. How should I use this energy in my life?","Yükselenim {sign}. Bu enerjiyi hayatımda nasıl kullanmalıyım?","Mein Aszendent ist {sign}. Wie sollte ich diese Energie in meinem Leben nutzen?","Mon ascendant est {sign}. Comment utiliser cette énergie dans ma vie ?","Mi ascendente es {sign}. ¿Cómo debo usar esta energía en mi vida?","Meu ascendente é {sign}. Como devo usar essa energia na minha vida?","Il mio ascendente è {sign}. Come dovrei usare questa energia nella mia vita?"],
}

for i, lang in enumerate(LANGS):
    path = os.path.join(LOCALES_DIR, lang + ".json")
    with open(path, encoding="utf-8-sig") as f:
        data = json.load(f)
    added = 0
    for k, vals in KEYS.items():
     if k not in data or k.startswith("ask.about."):
            data[k] = vals if isinstance(vals, str) else vals[i]
            added += 1
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(lang, "added", added)