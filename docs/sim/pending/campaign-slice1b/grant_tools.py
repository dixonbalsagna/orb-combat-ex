# GRANT (Tools' tools/schemas/fight-campaign.schema.json, cases.json and the self-test's virtual copy, for
# Simulation's campaign1b.py beside this): data/fight/campaign.json's new shape. The route's numbers (the places a
# column, the cross-back, the stage's ring) are World's now, in data/biomes/campaign.json, so placesPerColumn,
# crossBack and stageCols go, and ringCols (the episode's first ring) comes in. Its enabled is the campaign's one
# switch. The stage-cols case becomes a ring-cols one. Closed, so it lands in the same commit as the data. Run after
# campaign1b.py, on a tree with slice 1's grant_tools.py applied. Usage: python grant_tools.py <repo root>
import json, os, shutil, sys
os.chdir(sys.argv[1])
SCHEMA = 'tools/schemas/fight-campaign.schema.json'
sc = json.load(open(SCHEMA, encoding='utf-8'))
assert 'stageCols' in sc['properties'], "slice 1's campaign schema first"
sc['description'] = sc['description'].replace("(Legal mc01, mc06). Policy:", "(Legal mc01, mc06). Its enabled is the campaign's one switch. Policy:")
sc['required'] = ["schema", "enabled", "columns", "sideShare", "arcEpisodes", "families", "ringCols"]
P = sc['properties']
for k in ('placesPerColumn', 'crossBack', 'stageCols'):
    del P[k]
P['enabled']['description'] = "the campaign's one switch: the host uses none of it while it is off"
P['ringCols'] = {"type": "integer", "minimum": 600, "maximum": 4800, "multipleOf": 8, "description": "the episode's first ring, round the player's home, in columns"}
open(SCHEMA, 'w', encoding='utf-8', newline='\n').write(json.dumps(sc, indent=2, ensure_ascii=False) + '\n')

p = 'tools/fixtures/cases.json'
c = json.load(open(p, encoding='utf-8'))
F, S = 'data/fight/campaign.json', 'fight-campaign.schema.json'
k = [n for n, x in enumerate(c['cases']) if x.get('id') == 'fight-campaign-stage-cols-stride']
assert len(k) == 1 and not any(x.get('id') == 'fight-campaign-ring-cols-stride' for x in c['cases'])
c['cases'][k[0]] = {"id": "fight-campaign-ring-cols-stride", "schema": S, "mutate": [{"file": F, "set": {"/ringCols": 2401}}], "expect": {"rule": "multipleOf", "pointer": "/ringCols"}}
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(c, indent=2, ensure_ascii=False) + '\n')
shutil.copyfile(F, 'tools/fixtures/virtual/data/fight/campaign.json')
print("Tools: fight-campaign's ringCols in place of placesPerColumn, crossBack and stageCols, its case, and the virtual copy")
