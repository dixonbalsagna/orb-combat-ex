# GRANT (Tools' tools/schemas/, tools/schemas/map.json, tools/fixtures/cases.json and the self-test's virtual copy, for
# Simulation's run_ground.py beside this): the schema of the new data/fight/run.json (the run's ground switch, off),
# its map rule, its cases, and the virtual folder's copy of the data. The schema is closed, so it lands in the same
# commit as the data. Run after run_ground.py. Tools applies it, or grants it. Usage: python grant_tools.py <repo root>
import json, os, shutil, sys
os.chdir(sys.argv[1])
SCHEMA = 'tools/schemas/fight-run.schema.json'
assert not os.path.exists(SCHEMA), 'the run schema is already there'
U = {"^_": True}
schema = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "meridian/fight-run",
    "title": "fight-run (schema \"fight.run/1\")",
    "description": "data/fight/run.json: the run's numbers (docs/architecture/run-core.md; sim/core/run.gd). Run-only: no versus match reads it. Policy: closed except keys starting with an underscore.",
    "type": "object",
    "required": ["schema", "ground"],
    "properties": {
        "schema": {"const": "fight.run/1"},
        "ground": {
            "type": "object",
            "required": ["enabled", "framesPerRead", "stagesBeforeBoss", "phases", "provingSize"],
            "properties": {
                "enabled": {"type": "boolean", "description": "the switch: the story mode's host picks each stage's ground with World's ring picker only while it is on"},
                "framesPerRead": {"type": "object", "required": ["close", "half", "whole"], "properties": {sz: {"type": "integer", "minimum": 1, "maximum": 10, "description": "a candidate ring read every this many frames of the beats"} for sz in ["close", "half", "whole"]}, "additionalProperties": False, "patternProperties": U},
                "stagesBeforeBoss": {"type": "integer", "minimum": 1, "maximum": 12, "description": "the stages before the boss"},
                "phases": {"type": "array", "minItems": 1, "maxItems": 12, "items": {"enum": ["early", "mid"]}, "description": "the claim's size phase by chapter before the boss"},
                "provingSize": {"enum": ["close", "half", "whole"], "description": "a Proving ground's ring"}
            },
            "additionalProperties": False,
            "patternProperties": U
        }
    },
    "additionalProperties": False,
    "patternProperties": U
}
open(SCHEMA, 'w', encoding='utf-8', newline='\n').write(json.dumps(schema, indent=2, ensure_ascii=False) + '\n')

p = 'tools/schemas/map.json'
m = json.load(open(p, encoding='utf-8'))
assert not any(r.get('match') == 'data/fight/run.json' for r in m['rules'])
i = [k for k, r in enumerate(m['rules']) if r.get('match') == 'data/fight/boons.json'][0]
m['rules'].insert(i + 1, {"match": "data/fight/run.json", "schema": "fight-run.schema.json"})
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(m, indent=2, ensure_ascii=False) + '\n')

p = 'tools/fixtures/cases.json'
d = json.load(open(p, encoding='utf-8'))
F = 'data/fight/run.json'
S = 'fight-run.schema.json'
new = [
    {"id": "fight-run-valid", "schema": S, "mutate": [{"file": F, "set": {"/schema": "fight.run/1"}}], "expect": None},
    {"id": "fight-run-required-ground", "schema": S, "mutate": [{"file": F, "del": ["/ground"]}], "expect": {"rule": "required", "pointer": ""}},
    {"id": "fight-run-extra-key", "schema": S, "mutate": [{"file": F, "set": {"/bonus": 1}}], "expect": {"rule": "additionalProperties", "pointer": "/bonus"}},
    {"id": "fight-run-enabled-not-bool", "schema": S, "mutate": [{"file": F, "set": {"/ground/enabled": 1}}], "expect": {"rule": "type", "pointer": "/ground/enabled"}},
    {"id": "fight-run-frames-per-read-zero", "schema": S, "mutate": [{"file": F, "set": {"/ground/framesPerRead/whole": 0}}], "expect": {"rule": "minimum", "pointer": "/ground/framesPerRead/whole"}},
    {"id": "fight-run-phase-unknown", "schema": S, "mutate": [{"file": F, "set": {"/ground/phases/0": "late"}}], "expect": {"rule": "enum", "pointer": "/ground/phases/0"}},
    {"id": "fight-run-proving-size-unknown", "schema": S, "mutate": [{"file": F, "set": {"/ground/provingSize": "tiny"}}], "expect": {"rule": "enum", "pointer": "/ground/provingSize"}},
]
ids = [c.get('id') for c in d['cases']]
assert not any(c['id'] in ids for c in new)
k = max(n for n, c in enumerate(d['cases']) if str(c.get('id', '')).startswith('fight-boons-'))
d['cases'][k + 1:k + 1] = new
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')

shutil.copyfile(F, 'tools/fixtures/virtual/data/fight/run.json')
print("Tools: fight-run.schema.json, its map rule, 7 cases, and the virtual copy")
