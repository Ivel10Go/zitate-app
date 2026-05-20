import json

file_path = r'f:\Levi\flutter_projekts\Marx\marx_app\assets\thinkers_quotes.json'

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        quotes = json.load(f)

    print(f'Gelesene Zitate: {len(quotes)}')

    print('\nAlle Zitate (Author und text_de):')
    for q in quotes:
        print(f"- {q.get('author')}: {q.get('text_de')}")

    # Bestimmung des 'bekanntesten' Zitats
    # Kriterium: Aristoteles falls vorhanden, sonst das erste
    top_quote = None
    for q in quotes:
        if q.get('author') == 'Aristoteles':
            top_quote = q
            break
    
    if not top_quote and quotes:
        top_quote = quotes[0]

    print('\nTop-Zitat Identifizierung:')
    if top_quote:
        print(f"Top-Zitat: \"{top_quote.get('text_de')}\" von {top_quote.get('author')}")
    else:
        print("Kein Zitat gefunden.")

except Exception as e:
    print(f'Fehler: {e}')
