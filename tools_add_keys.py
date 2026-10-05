import json, os

LOCALES_DIR = "locales"
LANGS = ["en", "tr", "de", "fr", "es", "pt", "it"]

KEYS = {
 "streak.checkin.title": ("How are you today?", "Bugün nasılsın?", "Wie geht's dir heute?", "Comment te sens-tu aujourd'hui ?", "¿Cómo estás hoy?", "Como você está hoje?", "Come stai oggi?"),
 "streak.checkin.body": ("One tap, once a day.", "Günde bir dokunuş.", "Ein Tipp, einmal am Tag.", "Un geste, une fois par jour.", "Un toque, una vez al día.", "Um toque, uma vez por dia.", "Un tocco, una volta al giorno."),
 "streak.mood.1": ("Drained", "Bitkin", "Erschöpft", "Épuisé", "Agotado", "Esgotado", "Esausto"),
 "streak.mood.2": ("Low", "Düşük", "Gedrückt", "Bas", "Bajo", "Baixo", "Giù"),
 "streak.mood.3": ("Steady", "Dengeli", "Ausgeglichen", "Stable", "Estable", "Estável", "Stabile"),
 "streak.mood.4": ("Good", "İyi", "Gut", "Bien", "Bien", "Bem", "Bene"),
 "streak.mood.5": ("Radiant", "Parlak", "Strahlend", "Rayonnant", "Radiante", "Radiante", "Radioso"),
 "streak.checked_in": ("Checked in today", "Bugün işaretlendi", "Heute eingetragen", "Noté aujourd'hui", "Registrado hoy", "Registrado hoje", "Registrato oggi"),
 "streak.change": ("Change", "Değiştir", "Ändern", "Modifier", "Cambiar", "Alterar", "Cambia"),
 "streak.days": ("day streak", "günlük seri", "Tage in Folge", "jours d'affilée", "días seguidos", "dias seguidos", "giorni di fila"),
 "streak.best": ("Best", "En uzun", "Rekord", "Record", "Récord", "Recorde", "Record"),
 "streak.error.save": ("Couldn't save. Try again.", "Kaydedilemedi. Tekrar dene.", "Speichern fehlgeschlagen. Versuch es erneut.", "Échec de l'enregistrement. Réessaie.", "No se pudo guardar. Inténtalo de nuevo.", "Não foi possível salvar. Tente novamente.", "Salvataggio non riuscito. Riprova."),
 "streak.detail.title": ("Your rhythm", "Ritmin", "Dein Rhythmus", "Ton rythme", "Tu ritmo", "Seu ritmo", "Il tuo ritmo"),
 "streak.detail.last30": ("Last 30 days", "Son 30 gün", "Letzte 30 Tage", "30 derniers jours", "Últimos 30 días", "Últimos 30 dias", "Ultimi 30 giorni"),
 "streak.detail.empty": ("No check-ins yet.", "Henüz işaret yok.", "Noch keine Einträge.", "Aucun check-in pour l'instant.", "Aún no hay registros.", "Ainda sem registros.", "Ancora nessun check-in."),
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