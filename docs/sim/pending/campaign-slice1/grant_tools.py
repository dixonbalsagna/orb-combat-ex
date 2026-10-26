# GRANT (Tools' tools/schemas/, map.json, cases.json and the self-test's virtual copy, for Simulation's campaign.py
# beside this): the schema of the new data/fight/campaign.json (the campaign's switch, off, and Game Design's first
# values), its map rule after the run's, its cases, and the virtual folder's copy. Closed, so it lands in the same
# commit as the data. Run after campaign.py. Usage: python grant_tools.py <repo root>
import json, os, shutil, sys
os.chdir(sys.argv[1])
SCHEMA = 'tools/schemas/fight-campaign.schema.json'
assert not os.path.exists(SCHEMA), 'the campaign schema is already there'
U = {"^_": True}
cnt = lambda lo, hi, what: {"type": "integer", "minimum": lo, "maximum": hi, "description": what}
schema = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "meridian/fight-campaign",
    "title": "fight-campaign (schema \"fight.campaign/1\")",
    "description": "data/fight/campaign.json: the campaign's numbers (docs/design/campaign.md; sim/core/campaign.gd; docs/architecture/campaign-core.md). Campaign-only: no versus match and no fighter reads it (Legal mc01, mc06). Policy: closed except keys starting with an underscore.",
    "type": "object",
    "required": ["schema", "enabled", "columns", "placesPerColumn", "crossBack", "sideShare", "arcEpisodes", "families", "stageCols"],
    "properties": {
        "schema": {"const": "fight.campaign/1"},
        "enabled": {"type": "boolean", "description": "the switch: the campaign's host uses none of it while it is off"},
        "columns": cnt(1, 9, "an episode's stages, each a column of the route"),
        "placesPerColumn": {"type": "object", "required": ["min", "max"], "properties": {"min": cnt(1, 6, "a column's fewest places"), "max": cnt(1, 6, "a column's most places")},
                            "additionalProperties": False, "patternProperties": U},
        "crossBack": {"type": "object", "required": ["from", "to"], "properties": {"from": cnt(1, 9, "the column whose untaken place can come back"), "to": cnt(1, 9, "the column it comes back in")},
                      "additionalProperties": False, "patternProperties": U},
        "sideShare": cnt(0, 1000, "thousandths: the share of main-story episodes won that offer a side story"),
        "arcEpisodes": cnt(1, 9, "a filler arc's episodes"),
        "families": {"type": "array", "minItems": 2, "maxItems": 16, "uniqueItems": True, "items": {"type": "string", "pattern": "^[a-z_]{1,32}$"}, "description": "Narrative's filler families"},
        "stageCols": {"type": "integer", "minimum": 600, "maximum": 4800, "multipleOf": 8, "description": "a stage's stand-in ring round its place, in columns"},
    },
    "additionalProperties": False,
    "patternProperties": U,
}
open(SCHEMA, 'w', encoding='utf-8', newline='\n').write(json.dumps(schema, indent=2, ensure_ascii=False) + '\n')

p = 'tools/schemas/map.json'
m = json.load(open(p, encoding='utf-8'))
assert not any(r.get('match') == 'data/fight/campaign.json' for r in m['rules'])
i = [k for k, r in enumerate(m['rules']) if r.get('match') == 'data/fight/run.json'][0]
m['rules'].insert(i + 1, {"match": "data/fight/campaign.json", "schema": "fight-campaign.schema.json"})
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(m, indent=2, ensure_ascii=False) + '\n')

p = 'tools/fixtures/cases.json'
c = json.load(open(p, encoding='utf-8'))
F, S = 'data/fight/campaign.json', 'fight-campaign.schema.json'
new = [
    {"id": "fight-campaign-valid", "schema": S, "mutate": [{"file": F, "set": {"/schema": "fight.campaign/1"}}], "expect": None},
    {"id": "fight-campaign-required-enabled", "schema": S, "mutate": [{"file": F, "del": ["/enabled"]}], "expect": {"rule": "required", "pointer": ""}},
    {"id": "fight-campaign-extra-key", "schema": S, "mutate": [{"file": F, "set": {"/bonus": 1}}], "expect": {"rule": "additionalProperties", "pointer": "/bonus"}},
    {"id": "fight-campaign-columns-zero", "schema": S, "mutate": [{"file": F, "set": {"/columns": 0}}], "expect": {"rule": "minimum", "pointer": "/columns"}},
    {"id": "fight-campaign-side-share-over", "schema": S, "mutate": [{"file": F, "set": {"/sideShare": 1001}}], "expect": {"rule": "maximum", "pointer": "/sideShare"}},
    {"id": "fight-campaign-family-bad-id", "schema": S, "mutate": [{"file": F, "set": {"/families/0": "Training Day"}}], "expect": {"rule": "pattern", "pointer": "/families/0"}},
    {"id": "fight-campaign-stage-cols-stride", "schema": S, "mutate": [{"file": F, "set": {"/stageCols": 1201}}], "expect": {"rule": "multipleOf", "pointer": "/stageCols"}},
]
ids = [x.get('id') for x in c['cases']]
assert not any(x['id'] in ids for x in new)
k = max(n for n, x in enumerate(c['cases']) if str(x.get('id', '')).startswith('fight-run-'))
c['cases'][k + 1:k + 1] = new
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(c, indent=2, ensure_ascii=False) + '\n')
shutil.copyfile(F, 'tools/fixtures/virtual/data/fight/campaign.json')
print("Tools: fight-campaign.schema.json, its map rule, 7 cases, and the virtual copy")
