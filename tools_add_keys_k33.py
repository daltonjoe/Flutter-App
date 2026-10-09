import json
LG = ["en", "de", "tr", "fr", "es", "pt", "it"]
KEYS = {
 "birth_data.title": ["Edit birth details", "Geburtsdaten bearbeiten", "Doğum bilgilerini düzenle", "Modifier les données de naissance", "Editar datos de nacimiento", "Editar dados de nascimento", "Modifica i dati di nascita"],
 "birth_data.date": ["Birth date", "Geburtsdatum", "Doğum tarihi", "Date de naissance", "Fecha de nacimiento", "Data de nascimento", "Data di nascita"],
 "birth_data.city": ["Birth city", "Geburtsort", "Doğum yeri", "Ville de naissance", "Ciudad de nacimiento", "Cidade de nascimento", "Città di nascita"],
 "birth_data.time": ["Birth time", "Geburtszeit", "Doğum saati", "Heure de naissance", "Hora de nacimiento", "Hora de nascimento", "Ora di nascita"],
 "birth_data.time_known": ["I know my birth time", "Ich kenne meine Geburtszeit", "Doğum saatimi biliyorum", "Je connais mon heure de naissance", "Sé mi hora de nacimiento", "Sei minha hora de nascimento", "So la mia ora di nascita"],
 "sen.edit_birth_data": ["Edit birth details", "Geburtsdaten bearbeiten", "Doğum bilgilerini düzenle", "Modifier les données de naissance", "Editar datos de nacimiento", "Editar dados de nascimento", "Modifica i dati di nascita"],
}
for i, lg in enumerate(LG):
    p = "locales/%s.json" % lg
    with open(p, encoding="utf-8") as f:
        d = json.load(f)
    n = 0
    for k, v in KEYS.items():
        if k not in d:
            d[k] = v[i]
            n += 1
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
    print(lg, "+%d" % n, len(d))