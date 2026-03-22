import csv
import json

input_filename = 'Quran-Sauber.csv'
output_filename = 'QuranVocabulary.json'

vocab_list = []

# 'utf-8-sig' ist der Zaubertrick: Es ignoriert das unsichtbare Zeichen, das Excel am Anfang hinzufügt!
with open(input_filename, mode='r', encoding='utf-8-sig') as csv_file:
    
    # 1. Wir lesen die erste Zeile, um zu prüfen, ob Excel Kommas oder Semikolons benutzt hat
    first_line = csv_file.readline()
    delimiter = ';' if ';' in first_line else ','
    csv_file.seek(0) # Zurück zum Anfang der Datei
    
    reader = csv.DictReader(csv_file, delimiter=delimiter)
    
    # 2. Wir entfernen alle fiesen Leerzeichen aus den Spaltennamen
    if reader.fieldnames:
        reader.fieldnames = [name.strip() for name in reader.fieldnames if name]
        print(f"🔍 Gefundene Spalten: {reader.fieldnames}") # Hilft uns beim Debuggen
    
    id_counter = 1
    for row in reader:
        # 3. Wir entfernen auch alle Leerzeichen aus den Zellen selbst
        clean_row = {k: v.strip() if isinstance(v, str) else v for k, v in row.items() if k}
        
        try:
            # Lese die Prozentzahl
            percentage_str = clean_row.get('Percentage So Far', '')
            if not percentage_str:
                continue
                
            percentage_str = percentage_str.replace(',', '.')
            percentage = float(percentage_str)
            
            # Wir filtern alles bis ca. 80.0 %
            if percentage <= 80.0:
                arabic_word = clean_row.get('Word', '')
                
                if not arabic_word or arabic_word.startswith('_'):
                    continue

                freq_str = clean_row.get('Frequency', '0')
                frequency = int(freq_str) if freq_str else 0
                part_of_speech = clean_row.get('Part-of-speech', '')
                
                vocab_list.append({
                    "id": str(id_counter),
                    "arabic": arabic_word,
                    "frequency": frequency,
                    "partOfSpeech": part_of_speech,
                    "percentage": round(percentage, 2),
                    "meaningDE": f"Übersetzung für {arabic_word} fehlt"
                })
                id_counter += 1
            else:
                break
                
        except ValueError:
            continue

# JSON speichern
with open(output_filename, mode='w', encoding='utf-8') as json_file:
    json.dump(vocab_list, json_file, ensure_ascii=False, indent=4)

print(f"✅ Erfolg! Es wurden {len(vocab_list)} Wörter extrahiert und mit echtem Arabisch in '{output_filename}' gespeichert.")