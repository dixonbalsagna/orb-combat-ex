# GRANT (Tools' tools/schemas/fight-hitstop.schema.json and the self-test's virtual copy, for Simulation's mash_flow.py
# beside this): the ticks' new weight light_flow (a mash's flowing blow, 0 ticks: Game Design's rulings-2026-10-22.md
# 6), and the virtual folder's copy of data/fight/hitstop.json following the data. The schema is closed, so it changes
# in the same commit. Run after mash_flow.py. Tools applies it, or grants it. Usage: python grant_tools.py <repo root>
import json, os, shutil, sys
os.chdir(sys.argv[1])
p = 'tools/schemas/fight-hitstop.schema.json'
d = json.load(open(p, encoding='utf-8'))
t = d['properties']['ticks']
assert 'light_flow' not in t['properties'], 'the schema already has light_flow'
t['properties'] = dict([('light_flow', {"type": "integer", "minimum": 0, "maximum": 120, "description": "a hit's stop in ticks"})] + list(t['properties'].items()))
t['required'] = ['light_flow'] + list(t['required'])
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
shutil.copyfile('data/fight/hitstop.json', 'tools/fixtures/virtual/data/fight/hitstop.json')
print("Tools: the hit-stop schema's light_flow, and the virtual copy")
