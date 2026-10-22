# GRANT (Tools' tools/schemas/ and tools/fixtures/cases.json, for Simulation's ricochet.py beside this): a closed schema
# for data/fight/ricochet.json, its rule in map.json, its self-test fixtures (the file as it is, and five it must refuse)
# and its copy in the self-test's virtual folder (data/fight is one). Without them the validator warns "no-schema"
# (exit 0). It writes only what is missing. Tools applies it, or grants it. Usage: python grant_tools.py <repo root>
import json, os, shutil, sys
os.chdir(sys.argv[1])
OPEN = {"^_": True}

def num(lo=None, hi=None, integer=False, desc=None):
    d = {"type": "integer" if integer else "number"}
    if lo is not None:
        d["minimum"] = lo
    if hi is not None:
        d["maximum"] = hi
    if desc:
        d["description"] = desc
    return d

def obj(props):
    return {"type": "object", "required": list(props), "properties": props, "additionalProperties": False, "patternProperties": OPEN}

BOOL = {"type": "boolean", "description": "the one switch (off: nothing reads the rest)"}
SCHEMAS = {
    "data/fight/ricochet.json": ("fight-ricochet", "fight.ricochet/1",
        "data/fight/ricochet.json: the ricochet's glance (docs/architecture/ricochet-core.md; Game Design's fight-feel.md section 3). Policy: closed except keys starting with an underscore.",
        {"enabled": BOOL,
         "line": num(0, 100000, desc="units a second of his whole speed: at or above it a shallow contact glances"),
         "maxAngle": num(1, 89, desc="degrees to the surface: under it, a glance"),
         "keep": num(0, 1, desc="the share of his speed a glance keeps"),
         "minSlope": num(0, 89, desc="degrees: the ground a ricochet comes off is sloped this much or more"),
         "maxInRow": num(0, 16, True, "the most ricochets in a row for one send")},
        [("required-schema", {"del": ["/schema"]}, "required", ""),
         ("extra-key", {"set": {"/bounce": 1}}, "additionalProperties", "/bounce"),
         ("enabled-not-bool", {"set": {"/enabled": 1}}, "type", "/enabled"),
         ("keep-over-one", {"set": {"/keep": 1.5}}, "maximum", "/keep"),
         ("angle-zero", {"set": {"/maxAngle": 0}}, "minimum", "/maxAngle")]),
}
mp = 'tools/schemas/map.json'
m = json.load(open(mp, encoding='utf-8'))
cp = 'tools/fixtures/cases.json'
c = json.load(open(cp, encoding='utf-8'))
done = []
for data, (name, ver, desc, props, bad) in SCHEMAS.items():
    file = name + '.schema.json'
    p = os.path.join('tools/schemas', file)
    if not os.path.exists(data) or os.path.exists(p):
        continue   # its park is not in, or this ran after it already
    full = {"schema": {"const": ver}}
    full.update(props)
    s = {"$schema": "https://json-schema.org/draft/2020-12/schema", "$id": "meridian/" + name, "title": name + ' (schema "' + ver + '")',
         "description": desc, "type": "object", "required": list(full), "properties": full,
         "additionalProperties": False, "patternProperties": OPEN}
    open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(s, indent=2, ensure_ascii=False) + '\n')
    assert not any(r.get("match") == data for r in m["rules"])
    m["rules"].append({"match": data, "schema": file})
    c["cases"].append({"id": name + "-valid", "schema": file, "mutate": [{"file": data, "set": {"/schema": ver}}], "expect": None})
    for cid, mut, rule, ptr in bad:
        mm = {"file": data}
        mm.update(mut)
        c["cases"].append({"id": name + "-" + cid, "schema": file, "mutate": [mm], "expect": {"rule": rule, "pointer": ptr}})
    vp = os.path.join('tools/fixtures/virtual', data)   # data/fight is one of the self-test's virtual folders: it reads this copy
    if not os.path.exists(vp):
        shutil.copyfile(data, vp)
    done.append(data)
if not done:
    print('nothing to grant: each data file in the tree has its schema')
    sys.exit(0)
open(mp, 'w', encoding='utf-8', newline='\n').write(json.dumps(m, indent=2, ensure_ascii=False) + '\n')
open(cp, 'w', encoding='utf-8', newline='\n').write(json.dumps(c, indent=2, ensure_ascii=False) + '\n')
print("schemas for " + ", ".join(done))
