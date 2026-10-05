import json, io, os
# Kullanım: yeni anahtar = KEYS'e satır ekle; yeni dil = LANGS'a kod ekle + satırlara sona değer ekle.
# Eksik değer en'e düşer (uyarı basılır). Mevcut anahtarlara dokunmaz (idempotent).
LANGS = ["tr", "en", "de", "fr", "es", "pt", "it"]
KEYS = [
 # key, tr, en, de, fr, es, pt, it   (D1.1a settings.*; de/fr/es/pt/it taslak, K17)
 ("settings.title", "Ayarlar", "Settings", "Einstellungen", "Paramètres", "Ajustes", "Configurações", "Impostazioni"),
 ("settings.section.notifications", "Bildirimler", "Notifications", "Benachrichtigungen", "Notifications", "Notificaciones", "Notificações", "Notifiche"),
 ("settings.section.language", "Dil", "Language", "Sprache", "Langue", "Idioma", "Idioma", "Lingua"),
 ("settings.section.account", "Hesap", "Account", "Konto", "Compte", "Cuenta", "Conta", "Account"),
 ("settings.section.about", "Hakkında", "About", "Info", "À propos", "Acerca de", "Sobre", "Info"),
 ("settings.notifications.enabled", "Günlük okuma", "Daily reading", "Tägliche Deutung", "Lecture quotidienne", "Lectura diaria", "Leitura diária", "Lettura quotidiana"),
 ("settings.notifications.time", "Gönderim saati", "Delivery time", "Zustellzeit", "Heure d'envoi", "Hora de envío", "Horário de envio", "Orario di invio"),
 ("settings.notifications.note",
  "Tercihin kaydedilir. Bildirimler sonraki bir güncellemede başlar.",
  "Saved as your preference. Notifications start in a later update.",
  "Wird als Einstellung gespeichert. Benachrichtigungen starten in einem späteren Update.",
  "Enregistré comme préférence. Les notifications arriveront dans une prochaine mise à jour.",
  "Se guarda como preferencia. Las notificaciones llegarán en una actualización posterior.",
  "Salvo como preferência. As notificações começam em uma atualização futura.",
  "Salvato come preferenza. Le notifiche arriveranno in un prossimo aggiornamento."),
 ("settings.language.title", "Uygulama dili", "App language", "App-Sprache", "Langue de l'app", "Idioma de la app", "Idioma do app", "Lingua dell'app"),
 ("settings.account.anonymous", "Hesap bağlı değil", "Account not linked", "Konto nicht verknüpft", "Compte non lié", "Cuenta sin vincular", "Conta não vinculada", "Account non collegato"),
 ("settings.account.linked", "Hesap bağlı", "Account linked", "Konto verknüpft", "Compte lié", "Cuenta vinculada", "Conta vinculada", "Account collegato"),
 ("settings.about.version", "Sürüm", "Version", "Version", "Version", "Versión", "Versão", "Versione"),
 ("settings.save", "Kaydet", "Save", "Speichern", "Enregistrer", "Guardar", "Salvar", "Salva"),
 ("settings.error.save", "Kaydedilemedi. Tekrar dene.", "Could not save. Try again.", "Speichern fehlgeschlagen. Versuch es erneut.", "Échec de l'enregistrement. Réessaie.", "No se pudo guardar. Inténtalo de nuevo.", "Não foi possível salvar. Tente de novo.", "Impossibile salvare. Riprova."),
 ("settings.error.load", "Ayarlar yüklenemedi.", "Settings could not be loaded.", "Einstellungen konnten nicht geladen werden.", "Impossible de charger les paramètres.", "No se pudieron cargar los ajustes.", "Não foi possível carregar as configurações.", "Impossibile caricare le impostazioni."),
 ("settings.retry", "Tekrar dene", "Try again", "Erneut versuchen", "Réessayer", "Reintentar", "Tentar de novo", "Riprova"),
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