#!/usr/bin/env python3
"""
Merge assets/überarbeitete_thinkers_quotes.json into assets/thinkers_quotes.json
- create backup of original
- replace entries by 'id'
- add new entries
- output counts
"""
import json
from pathlib import Path
from datetime import datetime

BASE = Path('assets')
ORIG = BASE / 'thinkers_quotes.json'
UPDATE = BASE / 'überarbeitete_thinkers_quotes.json'

if not ORIG.exists():
    print(f'ERROR: original file not found: {ORIG}')
    raise SystemExit(1)
if not UPDATE.exists():
    print(f'ERROR: update file not found: {UPDATE}')
    raise SystemExit(1)

with open(ORIG, 'r', encoding='utf-8') as f:
    orig = json.load(f)

with open(UPDATE, 'r', encoding='utf-8') as f:
    updated = json.load(f)

orig_by_id = {q['id']: q for q in orig}
updated_by_id = {q['id']: q for q in updated}

replaced = 0
added = 0

for uid, q in updated_by_id.items():
    if uid in orig_by_id:
        orig_by_id[uid] = q
        replaced += 1
    else:
        orig_by_id[uid] = q
        added += 1

merged = list(orig_by_id.values())

# Backup original
stamp = datetime.now().strftime('%Y%m%d_%H%M%S')
backup_path = ORIG.with_suffix(f'.bak_pre_merge_{stamp}.json')
with open(backup_path, 'w', encoding='utf-8') as f:
    json.dump(orig, f, ensure_ascii=False, indent=2)

# Write merged
with open(ORIG, 'w', encoding='utf-8') as f:
    json.dump(merged, f, ensure_ascii=False, indent=2)

print('Merge complete')
print(f'Original entries: {len(orig)}')
print(f'Updated entries provided: {len(updated)}')
print(f'Replaced: {replaced}')
print(f'Added: {added}')
print(f'Total after merge: {len(merged)}')
print(f'Backup saved to: {backup_path}')
