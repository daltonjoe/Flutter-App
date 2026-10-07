import json, os

LOCALES_DIR = "locales"
LANGS = ["en", "tr", "de", "fr", "es", "pt", "it"]

KEYS = {
 "ask.safety.crisis": (
  "I'm really sorry you're going through this. Please reach out to someone you trust or your local emergency number or crisis line right now. You don't have to carry this alone.",
  "Bunu yaşadığına çok üzüldüm. Lütfen şimdi güvendiğin biriyle ya da bulunduğun yerdeki acil durum numarası veya kriz hattıyla iletişime geç. Bunu tek başına taşımak zorunda değilsin.",
  "Es tut mir sehr leid, dass du das durchmachst. Bitte wende dich jetzt an eine Vertrauensperson oder an den Notruf bzw. eine Krisenhotline in deiner Nähe. Du musst das nicht allein tragen.",
  "Je suis vraiment désolé que tu traverses cela. Parle dès maintenant à une personne de confiance ou contacte les urgences ou une ligne d'écoute près de chez toi. Tu n'as pas à porter ça seul.",
  "Lamento mucho que estés pasando por esto. Habla ahora con alguien de confianza o llama al número de emergencias o a una línea de crisis de tu zona. No tienes que cargar con esto solo.",
  "Sinto muito que você esteja passando por isso. Fale agora com alguém de confiança ou ligue para o número de emergência ou uma linha de apoio da sua região. Você não precisa carregar isso sozinho.",
  "Mi dispiace molto che tu stia vivendo questo. Parla subito con una persona di fiducia o chiama il numero di emergenza o una linea di ascolto della tua zona. Non devi portarlo da solo."),
 "ask.safety.redirect": (
  "This is beyond what astrology can speak to. For health, legal, money or safety questions, please talk to a qualified professional.",
  "Bu konu astrolojinin alanı dışında. Sağlık, hukuk, para ya da güvenlik soruları için lütfen uzman bir kişiye danış.",
  "Dazu kann Astrologie nichts sagen. Bei Fragen zu Gesundheit, Recht, Geld oder Sicherheit wende dich bitte an eine Fachperson.",
  "Cela dépasse ce que l'astrologie peut dire. Pour la santé, le droit, l'argent ou la sécurité, parle à un professionnel qualifié.",
  "Esto va más allá de lo que puede decir la astrología. Para temas de salud, legales, dinero o seguridad, habla con un profesional cualificado.",
  "Isso vai além do que a astrologia pode dizer. Para questões de saúde, jurídicas, dinheiro ou segurança, fale com um profissional qualificado.",
  "Questo va oltre ciò che l'astrologia può dire. Per salute, legge, denaro o sicurezza, rivolgiti a un professionista qualificato."),
 "ask.safety.fallback": (
  "I can't answer that reliably. Try rephrasing, or add something from Today or Match.",
  "Buna güvenilir bir yanıt veremiyorum. Soruyu farklı sor ya da Bugün veya Uyum'dan bir şey ekle.",
  "Dazu kann ich keine verlässliche Antwort geben. Formuliere es anders oder füge etwas aus Heute oder Match hinzu.",
  "Je ne peux pas répondre de façon fiable. Reformule, ou ajoute un élément d'Aujourd'hui ou d'Affinité.",
  "No puedo responder eso con fiabilidad. Reformula o añade algo de Hoy o Afinidad.",
  "Não consigo responder isso com segurança. Reformule ou adicione algo de Hoje ou Afinidade.",
  "Non posso rispondere in modo affidabile. Riformula, oppure aggiungi qualcosa da Oggi o Affinità."),
 "ask.error.rate": (
  "Too many questions. Wait a minute and try again.",
  "Çok fazla soru. Bir dakika bekleyip tekrar dene.",
  "Zu viele Fragen. Warte eine Minute und versuche es erneut.",
  "Trop de questions. Attends une minute puis réessaie.",
  "Demasiadas preguntas. Espera un minuto e inténtalo de nuevo.",
  "Muitas perguntas. Aguarde um minuto e tente novamente.",
  "Troppe domande. Aspetta un minuto e riprova."),
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