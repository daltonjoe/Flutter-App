import json, os

LOCALES_DIR = "locales"
LANGS = ["en", "tr", "de", "fr", "es", "pt", "it"]

KEYS = {
 "nav.ask": ("Ask", "Sor", "Fragen", "Demander", "Preguntar", "Perguntar", "Chiedi"),
 "ask.title": ("Ask", "Sor", "Fragen", "Demander", "Preguntar", "Perguntar", "Chiedi"),
 "ask.placeholder": ("Ask about your day or a match…", "Gününü ya da bir uyumu sor…", "Frag nach deinem Tag oder einem Match …", "Pose une question sur ta journée ou une affinité…", "Pregunta sobre tu día o una afinidad…", "Pergunte sobre o seu dia ou uma afinidade…", "Chiedi del tuo giorno o di un'affinità…"),
 "ask.send": ("Send", "Gönder", "Senden", "Envoyer", "Enviar", "Enviar", "Invia"),
 "ask.add": ("Add to chat", "Sohbete ekle", "Zum Chat hinzufügen", "Ajouter au chat", "Añadir al chat", "Adicionar ao chat", "Aggiungi alla chat"),
 "ask.empty_title": ("Talk it through", "Birlikte konuşalım", "Sprich darüber", "Parlons-en", "Hablémoslo", "Vamos conversar", "Parliamone"),
 "ask.empty_body": ("Add something from Today or Match, or ask your own question.", "Bugün ya da Uyum'dan bir şey ekle, ya da kendi sorunu sor.", "Füge etwas aus Heute oder Match hinzu oder stell deine eigene Frage.", "Ajoute un élément d'Aujourd'hui ou d'Affinité, ou pose ta propre question.", "Añade algo de Hoy o Afinidad, o haz tu propia pregunta.", "Adicione algo de Hoje ou Afinidade, ou faça sua própria pergunta.", "Aggiungi qualcosa da Oggi o Affinità, oppure fai la tua domanda."),
 "ask.suggest_1": ("What does this mean for me?", "Bu benim için ne anlama geliyor?", "Was bedeutet das für mich?", "Qu'est-ce que cela signifie pour moi ?", "¿Qué significa esto para mí?", "O que isso significa para mim?", "Cosa significa per me?"),
 "ask.suggest_2": ("Explain it in simple words.", "Sade bir dille anlat.", "Erkläre es einfach.", "Explique-le simplement.", "Explícalo con palabras sencillas.", "Explique com palavras simples.", "Spiegalo con parole semplici."),
 "ask.suggest_3": ("How could I work with this?", "Bununla nasıl çalışabilirim?", "Wie kann ich damit umgehen?", "Comment puis-je composer avec ça ?", "¿Cómo puedo trabajar con esto?", "Como posso lidar com isso?", "Come posso lavorarci?"),
 "ask.context.today_headline": ("Today's headline", "Bugünün başlığı", "Schlagzeile des Tages", "Titre du jour", "Titular de hoy", "Manchete de hoje", "Titolo di oggi"),
 "ask.context.today_event": ("Today's event", "Bugünün olayı", "Ereignis des Tages", "Événement du jour", "Evento de hoy", "Evento de hoje", "Evento di oggi"),
 "ask.context.synastry": ("Chart match", "Harita uyumu", "Kartenvergleich", "Comparaison de cartes", "Comparación de cartas", "Comparação de mapas", "Confronto tra carte"),
 "ask.context.remove": ("Remove", "Kaldır", "Entfernen", "Retirer", "Quitar", "Remover", "Rimuovi"),
 "ask.context.limit": ("You can attach up to 5 items.", "En fazla 5 öğe ekleyebilirsin.", "Du kannst bis zu 5 Elemente anhängen.", "Tu peux joindre jusqu'à 5 éléments.", "Puedes adjuntar hasta 5 elementos.", "Você pode anexar até 5 itens.", "Puoi allegare fino a 5 elementi."),
 "ask.typing": ("Writing…", "Yazıyor…", "Schreibt …", "Écrit…", "Escribiendo…", "Escrevendo…", "Sta scrivendo…"),
 "ask.error": ("Couldn't get a reply.", "Yanıt alınamadı.", "Keine Antwort erhalten.", "Impossible d'obtenir une réponse.", "No se pudo obtener una respuesta.", "Não foi possível obter uma resposta.", "Impossibile ottenere una risposta."),
 "ask.retry": ("Try again", "Tekrar dene", "Erneut versuchen", "Réessayer", "Reintentar", "Tentar novamente", "Riprova"),
 "ask.disclaimer": ("For entertainment and self-reflection only; not health, legal or financial advice.", "Eğlence ve öz-düşünme amaçlıdır; sağlık, hukuk, finans tavsiyesi değildir.", "Nur zur Unterhaltung und Selbstreflexion; keine Gesundheits-, Rechts- oder Finanzberatung.", "À but de divertissement et de réflexion personnelle ; pas un conseil de santé, juridique ou financier.", "Solo para entretenimiento y autorreflexión; no es consejo de salud, legal ni financiero.", "Apenas para entretenimento e autorreflexão; não é aconselhamento de saúde, jurídico ou financeiro.", "Solo per intrattenimento e riflessione personale; non è un consiglio su salute, diritto o finanze."),
 "ask.dev_reply": ("Preview only: the assistant isn't connected yet.", "Yalnız önizleme: asistan henüz bağlı değil.", "Nur Vorschau: Der Assistent ist noch nicht verbunden.", "Aperçu uniquement : l'assistant n'est pas encore connecté.", "Solo vista previa: el asistente aún no está conectado.", "Apenas prévia: o assistente ainda não está conectado.", "Solo anteprima: l'assistente non è ancora collegato."),
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