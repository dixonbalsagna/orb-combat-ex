# GRANT (Tools' tools/schemas/fight-run.schema.json, cases.json and the self-test's virtual copy, for Simulation's
# units.py beside this): fight-run's ground gains planetUnitsPerRead (required, a whole number from 1 to 100000), a case,
# and the virtual copy of data/fight/run.json. Run after units.py. Usage: python grant_tools.py <repo root>
import json, os, shutil, sys
os.chdir(sys.argv[1])
p = 'tools/schemas/fight-run.schema.json'
d = json.load(open(p, encoding='utf-8'))
g = d['properties']['ground']
assert 'planetUnitsPerRead' not in g['properties']
props = {}
for k, v in g['properties'].items():
    props[k] = v
    if k == 'framesPerRead':
        props['planetUnitsPerRead'] = {"type": "integer", "minimum": 1, "maximum": 100000, "description": "planet units a read spends on a cold planet's make"}
g['properties'] = props
req = []
for k in g['required']:
    req += [k, 'planetUnitsPerRead'] if k == 'framesPerRead' else [k]
g['required'] = req
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
p = 'tools/fixtures/cases.json'
c = json.load(open(p, encoding='utf-8'))
new = {"id": "fight-run-planet-units-zero", "schema": "fight-run.schema.json", "mutate": [{"file": "data/fight/run.json", "set": {"/ground/planetUnitsPerRead": 0}}],
       "expect": {"rule": "minimum", "pointer": "/ground/planetUnitsPerRead"}}
assert not any(x.get('id') == new['id'] for x in c['cases'])
k = max(n for n, x in enumerate(c['cases']) if str(x.get('id', '')).startswith('fight-run-'))
c['cases'].insert(k + 1, new)
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(c, indent=2, ensure_ascii=False) + '\n')
shutil.copyfile('data/fight/run.json', 'tools/fixtures/virtual/data/fight/run.json')
print("Tools: fight-run's ground.planetUnitsPerRead, a case, and the virtual copy")
