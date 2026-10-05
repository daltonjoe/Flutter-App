import json, io, os, sys
LOC = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'locales')
LANGS = ['en','tr','de','fr','es','pt','it']
KEYS = {
 'sen.birth_date': {'en':'Birth date','tr':'Doğum tarihi','de':'Geburtsdatum','fr':'Date de naissance','es':'Fecha de nacimiento','pt':'Data de nascimento','it':'Data di nascita'},
 'sen.birth_place': {'en':'Birth place','tr':'Doğum yeri','de':'Geburtsort','fr':'Lieu de naissance','es':'Lugar de nacimiento','pt':'Local de nascimento','it':'Luogo di nascita'},
 'sen.birth_time': {'en':'Birth time','tr':'Doğum saati','de':'Geburtszeit','fr':'Heure de naissance','es':'Hora de nacimiento','pt':'Hora de nascimento','it':'Ora di nascita'},
 'today.ritual.title': {'en':'Your daily ritual','tr':'Günlük ritüelin','de':'Dein tägliches Ritual','fr':'Ton rituel quotidien','es':'Tu ritual diario','pt':'Seu ritual diário','it':'Il tuo rituale quotidiano'},
 'today.ritual.body': {'en':'Choose the time you want your daily reading.','tr':'Günlük okumanı hangi saatte almak istediğini seç.','de':'Wähle die Uhrzeit für deine tägliche Deutung.','fr':"Choisis l'heure de ta lecture quotidienne.",'es':'Elige la hora de tu lectura diaria.','pt':'Escolha a hora da sua leitura diária.','it':"Scegli l'ora della tua lettura quotidiana."},
 'today.ritual.set_time': {'en':'Set time','tr':'Saat seç','de':'Zeit wählen','fr':"Choisir l'heure",'es':'Elegir hora','pt':'Escolher hora','it':"Scegli l'ora"},
 'today.ritual.change_time': {'en':'Change time','tr':'Saati değiştir','de':'Zeit ändern','fr':"Changer l'heure",'es':'Cambiar hora','pt':'Alterar hora','it':"Cambia l'ora"},
 'today.ritual.dismiss': {'en':'Dismiss','tr':'Kapat','de':'Schließen','fr':'Fermer','es':'Cerrar','pt':'Fechar','it':'Chiudi'},
 'today.ritual.preview_label': {'en':'Preview','tr':'Önizleme','de':'Vorschau','fr':'Aperçu','es':'Vista previa','pt':'Prévia','it':'Anteprima'},
 'today.ritual.saved': {'en':'Time saved','tr':'Saat kaydedildi','de':'Zeit gespeichert','fr':'Heure enregistrée','es':'Hora guardada','pt':'Hora salva','it':'Ora salvata'},
}
for lg in LANGS:
    p = os.path.join(LOC, lg + '.json')
    with io.open(p, 'r', encoding='utf-8-sig') as f:
        d = json.load(f)
    n = 0
    for k, v in KEYS.items():
        if k not in d:
            d[k] = v[lg]; n += 1
    with io.open(p, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print(lg, 'added', n)