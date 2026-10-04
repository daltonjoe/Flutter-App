import json, io, os
# Kullanım: yeni anahtar = KEYS'e satır ekle; yeni dil = LANGS'a kod ekle + satırlara sona değer ekle.
# Eksik değer en'e düşer (uyarı basılır). Mevcut anahtarlara dokunmaz (idempotent).
LANGS = ["tr", "en", "de", "fr", "es", "pt", "it"]
KEYS = [
 # key, tr, en, de, fr, es, pt, it
 ("nav.today", "Bugün", "Today", "Heute", "Aujourd'hui", "Hoy", "Hoje", "Oggi"),
 ("nav.chart", "Harita", "Chart", "Horoskop", "Thème", "Carta", "Mapa", "Tema"),
 ("nav.profile", "Profil", "Profile", "Profil", "Profil", "Perfil", "Perfil", "Profilo"),
 ("today.title", "Bugün", "Today", "Heute", "Aujourd'hui", "Hoy", "Hoje", "Oggi"),
 ("today.empty", "Bu profil için bugün olay yok.", "No events today for this profile.", "Heute keine Ereignisse für dieses Profil.", "Aucun événement aujourd'hui pour ce profil.", "Hoy no hay eventos para este perfil.", "Hoje não há eventos para este perfil.", "Nessun evento oggi per questo profilo."),
 ("today.error", "Bugün yüklenemedi.", "Couldn't load Today.", "Heute konnte nicht geladen werden.", "Impossible de charger Aujourd'hui.", "No se pudo cargar Hoy.", "Não foi possível carregar Hoje.", "Impossibile caricare Oggi."),
 ("today.retry", "Tekrar dene", "Retry", "Erneut versuchen", "Réessayer", "Reintentar", "Tentar de novo", "Riprova"),
 ("today.events", "Bugünün olayları", "Today's events", "Ereignisse heute", "Événements du jour", "Eventos de hoy", "Eventos de hoje", "Eventi di oggi"),
 ("today.unknown_time_hint", "Doğum saatini eklersen Ay ve Yükselen bazlı okumalar açılır.", "Add your birth time to unlock Moon and Ascendant readings.", "Mit der Geburtszeit werden Mond- und Aszendenten-Deutungen freigeschaltet.", "Ajoute ton heure de naissance pour débloquer la Lune et l'Ascendant.", "Añade tu hora de nacimiento para desbloquear la Luna y el Ascendente.", "Adicione sua hora de nascimento para liberar a Lua e o Ascendente.", "Aggiungi l'ora di nascita per sbloccare Luna e Ascendente."),
 ("today.rarity", "Haritaların %{pct}'inde bu açı aktif", "This aspect is active in {pct}% of charts", "Dieser Aspekt ist in {pct}% der Horoskope aktiv", "Cet aspect est actif dans {pct}% des thèmes", "Este aspecto está activo en el {pct}% de las cartas", "Este aspecto está ativo em {pct}% dos mapas", "Questo aspetto è attivo nel {pct}% dei temi"),
 ("valence.power", "Akış", "Flow", "Fluss", "Flux", "Flujo", "Fluxo", "Flusso"),
 ("valence.pressure", "Baskı", "Pressure", "Druck", "Pression", "Presión", "Pressão", "Pressione"),
 ("valence.trouble", "Dikkat", "Caution", "Vorsicht", "Prudence", "Cautela", "Cautela", "Cautela"),
 ("valence.neutral", "Nötr", "Neutral", "Neutral", "Neutre", "Neutro", "Neutro", "Neutro"),
 ("theme.love", "Aşk", "Love", "Liebe", "Amour", "Amor", "Amor", "Amore"),
 ("theme.career", "Kariyer", "Career", "Karriere", "Carrière", "Carrera", "Carreira", "Carriera"),
 ("theme.identity", "Kimlik", "Identity", "Identität", "Identité", "Identidad", "Identidade", "Identità"),
 ("theme.health", "Sağlık", "Health", "Gesundheit", "Santé", "Salud", "Saúde", "Salute"),
  ("today.offline", "Çevrimdışı – son güncelleme {time}", "Offline – last updated {time}", "Offline – zuletzt aktualisiert {time}", "Hors ligne – dernière mise à jour {time}", "Sin conexión – última actualización {time}", "Offline – última atualização {time}", "Offline – ultimo aggiornamento {time}"),
   ("transit.orb", "Orb", "Orb", "Orbis", "Orbe", "Orbe", "Orbe", "Orbe"),
 ("transit.applying", "Yaklaşıyor", "Applying", "Sich nähernd", "En approche", "Acercándose", "Aproximando-se", "In avvicinamento"),
 ("transit.separating", "Uzaklaşıyor", "Separating", "Sich entfernend", "En éloignement", "Alejándose", "Afastando-se", "In allontanamento"),
 ("transit.no_text", "Bu olay için henüz açıklama yok.", "No description for this event yet.", "Für dieses Ereignis gibt es noch keine Beschreibung.", "Pas encore de description pour cet événement.", "Aún no hay descripción para este evento.", "Ainda não há descrição para este evento.", "Nessuna descrizione per questo evento ancora."),
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