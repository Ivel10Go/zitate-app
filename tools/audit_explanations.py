#!/usr/bin/env python3
"""
Audit thinkers_quotes.json for generic/template-based explanations
and report problems
"""

import json
from pathlib import Path
from collections import defaultdict

def load_quotes():
    """Load quotes from thinkers_quotes.json"""
    path = Path('assets/thinkers_quotes.json')
    with open(path, encoding='utf-8') as f:
        return json.load(f)

def check_explanation_quality(quotes):
    """Check for generic and template-based explanations"""
    issues = defaultdict(list)
    
    # Patterns that indicate generic/template content
    generic_patterns = [
        'konzeptualisiert hier einen Aspekt von',
        'verdeutlicht die Bedeutung von',
        'verdichtet einen komplexen Sachverhalt',
        'Es behandelt die Frage, wie sich',
        'brachte bedeutende Gedanken ein',
        'Die Aussage betrifft nicht nur theoretische Reflexion',
        'Kontinuität und Bruch zugleich markiert',
        'Verständnis schärft für das Zusammenspiel'
    ]
    
    for quote in quotes:
        short_exp = quote.get('explanation_short', '')
        long_exp = quote.get('explanation_long', '')
        
        # Check short explanation
        if short_exp:
            for pattern in generic_patterns:
                if pattern in short_exp:
                    issues['generic_short'].append({
                        'id': quote['id'],
                        'author': quote.get('author', 'Unknown'),
                        'text': quote.get('text_de', '')[:50] + '...',
                        'pattern': pattern
                    })
                    break
        
        # Check long explanation
        if long_exp:
            generic_count = sum(1 for pattern in generic_patterns if pattern in long_exp)
            if generic_count >= 3:  # If multiple generic patterns, it's likely template-based
                issues['generic_long'].append({
                    'id': quote['id'],
                    'author': quote.get('author', 'Unknown'),
                    'text': quote.get('text_de', '')[:50] + '...',
                    'pattern_count': generic_count
                })
    
    return issues

def main():
    print("Auditing explanation quality in thinkers_quotes.json...\n")
    
    quotes = load_quotes()
    print(f"Total quotes: {len(quotes)}\n")
    
    issues = check_explanation_quality(quotes)
    
    print(f"✗ Generic short explanations: {len(issues['generic_short'])}")
    print(f"✗ Generic long explanations: {len(issues['generic_long'])}\n")
    
    if issues['generic_short']:
        print("Examples of generic SHORT explanations:")
        for item in issues['generic_short'][:5]:
            print(f"  - {item['id']} ({item['author']}): \"{item['text']}\"")
            print(f"    Pattern: {item['pattern']}\n")
    
    if issues['generic_long']:
        print(f"\nExamples of generic LONG explanations (>2 patterns):")
        for item in issues['generic_long'][:5]:
            print(f"  - {item['id']} ({item['author']}): \"{item['text']}\"")
            print(f"    Generic patterns detected: {item['pattern_count']}\n")
    
    total_issues = len(issues['generic_short']) + len(issues['generic_long'])
    print(f"\n{'='*60}")
    print(f"VERDICT: {total_issues} / {len(quotes)} entries have problematic explanations")
    print(f"That's {100*total_issues//len(quotes)}% of the dataset!")
    print(f"\n⚠️  The explanations are clearly wrong and need rewriting")
    print(f"✓  Each quote needs a UNIQUE, contextual explanation")

if __name__ == '__main__':
    main()
