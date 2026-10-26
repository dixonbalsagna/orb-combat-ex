# GRANT (Tools' tools/schemas/fight-campaign.schema.json, cases.json and the self-test's virtual copy, for Simulation's
# campaign1c.py beside this): data/fight/campaign.json's crossBack {from, to} (campaign.md 2.2: column `from`'s untaken
# place asked of World again at column `to`), required and closed, with one case. Run after campaign1c.py, on a tree
# with slice 1b's grant_tools.py applied. Usage: python grant_tools.py <repo root>
import json, os, shutil, sys
os.chdir(sys.argv[1])
SCHEMA = 'tools/schemas/fight-campaign.schema.json'
sc = json.load(open(SCHEMA, encoding='utf-8'))
assert 'ringCols' in sc['properties'] and 'crossBack' not in sc['properties'], "slice 1b's campaign schema, without crossBack"
cnt = lambda lo, hi, what: {"type": "integer", "minimum": lo, "maximum": hi, "description": what}
P = {}
for k, v in sc['properties'].items():
    P[k] = v
    if k == 'columns':
        P['crossBack'] = {"type": "object", "required": ["from", "to"],
                          "properties": {"from": cnt(1, 9, "the column whose untaken named place comes back"), "to": cnt(1, 9, "the column it is asked again in (before the climax)")},
                          "additionalProperties": False, "patternProperties": {"^_": True},
                          "description": "the cross-back (campaign.md 2.2): asked of World as WorldCampaign.column's prefer"}
sc['properties'] = P
r = sc['required']
r.insert(r.index('columns') + 1, 'crossBack')
open(SCHEMA, 'w', encoding='utf-8', newline='\n').write(json.dumps(sc, indent=2, ensure_ascii=False) + '\n')

p = 'tools/fixtures/cases.json'
c = json.load(open(p, encoding='utf-8'))
F, S = 'data/fight/campaign.json', 'fight-campaign.schema.json'
assert not any(x.get('id') == 'fight-campaign-cross-back-to-zero' for x in c['cases'])
k = [n for n, x in enumerate(c['cases']) if x.get('id') == 'fight-campaign-ring-cols-stride']
assert len(k) == 1
c['cases'].insert(k[0] + 1, {"id": "fight-campaign-cross-back-to-zero", "schema": S, "mutate": [{"file": F, "set": {"/crossBack/to": 0}}], "expect": {"rule": "minimum", "pointer": "/crossBack/to"}})
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(c, indent=2, ensure_ascii=False) + '\n')
shutil.copyfile(F, 'tools/fixtures/virtual/data/fight/campaign.json')
print("Tools: fight-campaign's crossBack, its case, and the virtual copy")
