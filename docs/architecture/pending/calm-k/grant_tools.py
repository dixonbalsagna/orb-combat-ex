# GRANT (Tools' tools/schemas/director-interrupts.schema.json and biomes-rings.schema.json, for the keys in
# grant_encounter.py and grant_world.py beside this): calmTurn.warmColsGen2 (required, an integer from 1) and
# turn.warmTotal (required, 0 or 1). Run after both.
# Usage: python grant_tools.py <repo root>
import json, os, sys
os.chdir(sys.argv[1])
p = 'tools/schemas/director-interrupts.schema.json'
s = json.load(open(p, encoding='utf-8'))


def find(o):
    if isinstance(o, dict):
        if 'calmTurn' in o.get('properties', {}):
            return o['properties']['calmTurn']
        for v in o.values():
            r = find(v)
            if r is not None:
                return r
    if isinstance(o, list):
        for v in o:
            r = find(v)
            if r is not None:
                return r
    return None


ct = find(s)
assert ct is not None and 'warmColsGen2' not in ct['properties']
P = {}
for k, v in ct['properties'].items():
    P[k] = v
    if k == 'warmColsMax':
        P['warmColsGen2'] = {"type": "integer", "minimum": 1, "description": "On a gen 2 planet (Game Design's rulings-2026-10-26 item 28; docs/architecture/calm-turn-read.md): the columns a pick's rings are read a tick in all, whatever the lead (one ring all of it, two half each), so no tick hitches on a slow device; a form step's warm begins at its ready tell."}
ct['properties'] = P
r = ct['required']
r.insert(r.index('warmColsMax') + 1, 'warmColsGen2')
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(s, indent=2, ensure_ascii=False) + '\n')
p = 'tools/schemas/biomes-rings.schema.json'
s = json.load(open(p, encoding='utf-8'))
t = s['properties']['turn']
assert 'warmTotal' not in t['properties']
P = {}
for k, v in t['properties'].items():
    P[k] = v
    if k == 'fallbackDeg':
        P['warmTotal'] = {"type": "integer", "enum": [0, 1], "description": "1: a pick's k is the total columns a tick across the rings it warms, each reading its share (the calm turn's read, docs/architecture/calm-turn-read.md); 0: k of each ring"}
t['properties'] = P
t['required'].insert(t['required'].index('fallbackDeg') + 1, 'warmTotal')
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(s, indent=2, ensure_ascii=False) + '\n')
print("Tools: director-interrupts' calmTurn.warmColsGen2, biomes-rings' turn.warmTotal")
