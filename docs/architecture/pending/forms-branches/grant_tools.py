# GRANT (Tools' tools/schemas/fighters-forms.schema.json, for Simulation's forms branches: branches.py beside this). The
# forms file gains a step's "branch" (true at II and IV) and the "branches" block; the schema is closed, so it must say so
# in the same commit, or CI's data job fails on three unknown properties. Tools applies it, or grants it.
# Usage: python grant_tools.py <repo root>
import json, os, sys
os.chdir(sys.argv[1])
p = 'tools/schemas/fighters-forms.schema.json'
d = json.load(open(p, encoding='utf-8'))
items = d['properties']['steps']['items']
assert 'branch' not in items['properties'] and 'branches' not in d['properties']
items['properties']['branch'] = {"type": "boolean", "description": "true at a step that picks a branch (II and IV: hero-forms.md section 4)"}
closed = {"additionalProperties": False, "patternProperties": {"^_": True}}
num = lambda lo, hi=None: dict({"type": "number", "minimum": lo}, **({"maximum": hi} if hi is not None else {}))
d['properties']['branches'] = dict({
    "type": "object",
    "description": "the two branches (hero-forms.md section 3): Witness's and Trial's fills and each branch's extras; firstTie the pick's first tie",
    "required": ["witness", "trial", "firstTie"],
    "properties": {
        "witness": dict({"type": "object", "required": ["range", "perPerson", "ownKill", "damage", "launch", "care"],
                         "properties": {"range": num(0), "perPerson": num(0, 100), "ownKill": num(0, 100), "damage": num(0, 1), "launch": num(0, 1), "care": num(0, 2)}}, **closed),
        "trial": dict({"type": "object", "required": ["opponentForm", "opponentFormHeld", "deficitPerSec", "blowUp", "commit", "speed", "block", "followUp"],
                       "properties": {"opponentForm": num(0, 100), "opponentFormHeld": num(0, 100), "deficitPerSec": num(0, 100), "blowUp": num(0, 100), "commit": num(0, 100), "speed": num(0, 1),
                                      "block": {"type": "array", "items": {"type": "integer", "minimum": 0}, "minItems": 2, "maxItems": 2},
                                      "followUp": {"type": "integer", "minimum": 0}}}, **closed),
        "firstTie": {"enum": ["witness", "trial"]},
    }}, **closed)
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
print("the forms schema knows the branches")
