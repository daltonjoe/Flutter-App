import json, os
LANGS = ["en", "de", "tr", "fr", "es", "pt", "it"]
KEYS = {
 "ask.empty_title.natal": ["Ask about your birth chart", "Frag nach deinem Geburtshoroskop", "Haritanı sor", "Interroge ton thème natal", "Pregunta sobre tu carta natal", "Pergunte sobre seu mapa natal", "Chiedi del tuo tema natale"],
 "ask.empty_body.natal": ["Planets, signs, houses and aspects in your chart. Pick a question or write your own.", "Planeten, Zeichen, Häuser und Aspekte in deinem Horoskop. Wähle eine Frage oder schreib selbst.", "Haritandaki gezegen, burç, ev ve açılar. Bir soru seç ya da kendin yaz.", "Planètes, signes, maisons et aspects de ton thème. Choisis une question ou écris la tienne.", "Planetas, signos, casas y aspectos de tu carta. Elige una pregunta o escribe la tuya.", "Planetas, signos, casas e aspectos do seu mapa. Escolha uma pergunta ou escreva a sua.", "Pianeti, segni, case e aspetti del tuo tema. Scegli una domanda o scrivi la tua."],
 "ask.empty_title.forecast": ["Ask about a month ahead", "Frag nach einem Monat", "Bir ayı sor", "Interroge un mois", "Pregunta por un mes", "Pergunte sobre um mês", "Chiedi di un mese"],
 "ask.empty_body.forecast": ["First choose month and year (MM-YYYY). The outlook uses slow planets (Mars to Pluto) active in your chart that month.", "Wähle zuerst Monat und Jahr (MM-JJJJ). Der Ausblick nutzt langsame Planeten (Mars bis Pluto), die in diesem Monat in deinem Horoskop wirken.", "Önce ay ve yılı seç (AA-YYYY). Öngörü, o ay haritanda etkin olan yavaş gezegenlere (Mars–Plüton) dayanır.", "Choisis d'abord le mois et l'année (MM-AAAA). La prévision utilise les planètes lentes (Mars à Pluton) actives dans ton thème ce mois-là.", "Elige primero mes y año (MM-AAAA). La previsión usa los planetas lentos (Marte a Plutón) activos en tu carta ese mes.", "Escolha primeiro mês e ano (MM-AAAA). A previsão usa os planetas lentos (Marte a Plutão) ativos no seu mapa nesse mês.", "Scegli prima mese e anno (MM-AAAA). La previsione usa i pianeti lenti (da Marte a Plutone) attivi nel tuo tema quel mese."],
 "ask.suggest.natal.1": ["What do my Sun sign, house and degree mean?", "Was bedeuten mein Sonnenzeichen, Haus und Grad?", "Güneşim burç, ev ve derece olarak ne anlama geliyor?", "Que signifient mon signe solaire, ma maison et mon degré ?", "¿Qué significan mi signo solar, casa y grado?", "O que significam meu signo solar, casa e grau?", "Cosa significano il mio segno solare, la casa e il grado?"],
 "ask.suggest.natal.2": ["How do my Moon and Venus shape love?", "Wie prägen Mond und Venus meine Liebe?", "Ay ve Venüs aşkı nasıl şekillendiriyor?", "Comment ma Lune et ma Vénus façonnent-elles l'amour ?", "¿Cómo moldean el amor mi Luna y Venus?", "Como a Lua e Vênus moldam o amor para mim?", "Come Luna e Venere plasmano il mio amore?"],
 "ask.suggest.natal.3": ["Which aspects in my chart stand out most?", "Welche Aspekte in meinem Horoskop stechen heraus?", "Haritamda en belirgin açılar hangileri?", "Quels aspects de mon thème ressortent le plus ?", "¿Qué aspectos de mi carta destacan más?", "Quais aspectos do meu mapa mais se destacam?", "Quali aspetti del mio tema spiccano di più?"],
 "ask.suggest.forecast.1": ["How does this month look for my career?", "Wie sieht dieser Monat für meine Karriere aus?", "Bu ay kariyerim için nasıl görünüyor?", "Comment ce mois se présente pour ma carrière ?", "¿Cómo se ve este mes para mi carrera?", "Como esse mês se apresenta para minha carreira?", "Come si presenta questo mese per la mia carriera?"],
 "ask.suggest.forecast.2": ["Which themes shape love this month?", "Welche Themen prägen die Liebe in diesem Monat?", "Bu ay aşkta hangi temalar öne çıkıyor?", "Quels thèmes marquent l'amour ce mois-ci ?", "¿Qué temas marcan el amor este mes?", "Quais temas marcam o amor neste mês?", "Quali temi segnano l'amore questo mese?"],
 "ask.suggest.forecast.3": ["Which transit matters most this month?", "Welcher Transit ist in diesem Monat am wichtigsten?", "Bu ay en önemli transit hangisi?", "Quel transit compte le plus ce mois-ci ?", "¿Qué tránsito importa más este mes?", "Qual trânsito mais importa neste mês?", "Quale transito conta di più questo mese?"],
 "ask.forecast.pick": ["Choose month and year", "Monat und Jahr wählen", "Ay ve yıl seç", "Choisir mois et année", "Elegir mes y año", "Escolher mês e ano", "Scegli mese e anno"],
 "ask.forecast.for": ["Outlook for", "Ausblick für", "Öngörü ayı", "Prévision pour", "Previsión para", "Previsão para", "Previsione per"],
}
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