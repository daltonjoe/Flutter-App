import json, os

LOCALES_DIR = "locales"
LANGS = ["en", "tr", "de", "fr", "es", "pt", "it"]

KEYS = {
 "streak.detail.empty": ("No check-ins yet.", "Henüz işaret yok.", "Noch keine Einträge.", "Aucun check-in pour l'instant.", "Aún no hay registros.", "Ainda sem registros.", "Ancora nessun check-in."),
 "nav.match": ("Match", "Uyum", "Match", "Affinité", "Afinidad", "Afinidade", "Affinità"),
 "match.title": ("Compatibility", "Uyum", "Kompatibilität", "Compatibilité", "Compatibilidad", "Compatibilidade", "Compatibilità"),
 "match.pick_a": ("First profile", "Birinci profil", "Erstes Profil", "Premier profil", "Primer perfil", "Primeiro perfil", "Primo profilo"),
 "match.pick_b": ("Second profile", "İkinci profil", "Zweites Profil", "Deuxième profil", "Segundo perfil", "Segundo perfil", "Secondo profilo"),
 "match.pick_hint": ("Choose two of your profiles to compare their charts.", "Haritalarını karşılaştırmak için iki profilini seç.", "Wähle zwei deiner Profile, um ihre Karten zu vergleichen.", "Choisis deux de tes profils pour comparer leurs cartes.", "Elige dos de tus perfiles para comparar sus cartas.", "Escolha dois dos seus perfis para comparar os mapas.", "Scegli due dei tuoi profili per confrontare le loro carte."),
 "match.empty": ("Add a second profile to compare charts.", "Haritaları karşılaştırmak için ikinci bir profil ekle.", "Füge ein zweites Profil hinzu, um Karten zu vergleichen.", "Ajoute un deuxième profil pour comparer les cartes.", "Añade un segundo perfil para comparar cartas.", "Adicione um segundo perfil para comparar mapas.", "Aggiungi un secondo profilo per confrontare le carte."),
 "match.need_two": ("Pick both profiles to see the aspects between them.", "Aralarındaki açıları görmek için iki profili de seç.", "Wähle beide Profile, um die Aspekte zwischen ihnen zu sehen.", "Choisis les deux profils pour voir les aspects entre eux.", "Elige ambos perfiles para ver los aspectos entre ellos.", "Escolha os dois perfis para ver os aspectos entre eles.", "Scegli entrambi i profili per vedere gli aspetti tra loro."),
 "match.no_aspects": ("No close aspects between these charts.", "Bu haritalar arasında yakın açı yok.", "Keine engen Aspekte zwischen diesen Karten.", "Aucun aspect serré entre ces cartes.", "No hay aspectos cercanos entre estas cartas.", "Não há aspectos próximos entre estes mapas.", "Nessun aspetto stretto tra queste carte."),
 "match.error": ("Couldn't load the comparison.", "Karşılaştırma yüklenemedi.", "Der Vergleich konnte nicht geladen werden.", "Impossible de charger la comparaison.", "No se pudo cargar la comparación.", "Não foi possível carregar a comparação.", "Impossibile caricare il confronto."),
 "match.retry": ("Try again", "Tekrar dene", "Erneut versuchen", "Réessayer", "Reintentar", "Tentar novamente", "Riprova"),
 "match.time_unknown_note": ("One profile has no birth time, so its Moon is left out.", "Bir profilde doğum saati yok, bu yüzden Ay hesaba katılmadı.", "Bei einem Profil fehlt die Geburtszeit, daher bleibt der Mond unberücksichtigt.", "Un profil n'a pas d'heure de naissance ; la Lune est donc exclue.", "Un perfil no tiene hora de nacimiento, así que se omite la Luna.", "Um perfil não tem hora de nascimento, por isso a Lua fica de fora.", "Un profilo non ha l'ora di nascita, quindi la Luna è esclusa."),
 "match.aspects_title": ("Aspects between charts", "Haritalar arası açılar", "Aspekte zwischen den Karten", "Aspects entre les cartes", "Aspectos entre cartas", "Aspectos entre mapas", "Aspetti tra le carte"),
"match.orb": ("Orb {value}°", "Orb {value}°", "Orbis {value}°", "Orbe {value}°", "Orbe {value}°", "Orbe {value}°", "Orbita {value}°"),
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
