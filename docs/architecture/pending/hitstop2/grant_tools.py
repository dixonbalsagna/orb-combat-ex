# GRANT (Tools' tools/schemas/fight-hitstop.schema.json and the self-test's virtual copy, for Simulation's hitstop2.py
# beside this): the second step's keys, cutMul (a share above 0, at most 1) and cutFloor (whole ticks), in place of
# mashFloor; the virtual folder's copy of data/fight/hitstop.json follows the data. The schema is closed, so it changes
# in the same commit. Run after hitstop2.py. Tools applies it, or grants it. Usage: python grant_tools.py <repo root>
import json, os, shutil, sys
os.chdir(sys.argv[1])
p = 'tools/schemas/fight-hitstop.schema.json'
d = json.load(open(p, encoding='utf-8'))
assert 'mashFloor' in d['properties'], 'the hit-stop schema is already the second step'
props = {}
for k, v in d['properties'].items():
    if k == 'mashFloor':
        props['cutMul'] = {"type": "number", "minimum": 0, "maximum": 1, "description": "over the budget, a stop under a decisive blow is x this"}
        props['cutFloor'] = {"type": "integer", "minimum": 0, "maximum": 120, "description": "... rounded, at least this many ticks"}
        continue
    props[k] = v
d['properties'] = props
req = []
for k in d['required']:
    req += ['cutMul', 'cutFloor'] if k == 'mashFloor' else [k]
d['required'] = req
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
shutil.copyfile('data/fight/hitstop.json', 'tools/fixtures/virtual/data/fight/hitstop.json')
print("Tools: the hit-stop schema's second step, and the virtual copy")
