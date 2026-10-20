# GRANT (Tools' tools/schemas/ and tools/fixtures/cases.json, for Simulation's parks in docs/architecture/pending/):
# closed schemas for the new data files of data/fight/ (boons.json, catastrophe.json, flight.json, hitstop.json), their
# rules in map.json, and their self-test fixtures (the file as it is, and three or more it must refuse; data/fight is a
# virtual folder of the self-test, so each file's copy goes to tools/fixtures/virtual/data/fight as well). Without them
# the validator warns "no-schema" (exit 0) and the self-test's coverage fails for any schema without fixtures.
# Each is written only for a data file in the tree that has no schema yet, so it runs after any of the parks, or after
# each. Tools applies it, or grants it. Usage: python grant_tools_fight.py <repo root>
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
    "data/fight/boons.json": ("fight-boons", "fight.boons/1",
        "data/fight/boons.json: the run's rare boons (docs/architecture/boons-core.md; Game Design's rulings-2026-10-18b.md section 4). Run-only: a match's setup names them. Policy: closed except keys starting with an underscore.",
        {"born_ready": obj({"steps": num(1, 5, True, "the forms above base every fight starts in")}),
         "second_skin": obj({"steps": num(2, 5, True, "... one higher than born_ready's")}),
         "borrowed": obj({"firstBreakSooner": num(0, 0.89, desc="the share sooner his first broken region comes")})},
        [("required-schema", {"del": ["/schema"]}, "required", ""),
         ("extra-key", {"set": {"/bonus": 1}}, "additionalProperties", "/bonus"),
         ("born-ready-steps-zero", {"set": {"/born_ready/steps": 0}}, "minimum", "/born_ready/steps"),
         ("borrowed-sooner-too-high", {"set": {"/borrowed/firstBreakSooner": 0.95}}, "maximum", "/borrowed/firstBreakSooner")]),
    "data/fight/catastrophe.json": ("fight-catastrophe", "fight.catastrophe/1",
        "data/fight/catastrophe.json: the catastrophe tier's sky, the blast cloud's cue and the world's ash (docs/architecture/run-core.md section 6; sim/core/cata.gd). Policy: closed except keys starting with an underscore.",
        {"ash": obj({"perCloud": num(0, 1000, True, "thousandths of ash each blast cloud adds"),
                     "riseTicks": num(7200, None, True, "the ticks of its rise: 120 s or more (Legal c05)"),
                     "max": num(0, 1000, True, "the ash's cap, in thousandths")}),
         "cloud": obj({"radius": num(0, 100000, desc="the cloud's size, the cue's amount")})},
        [("required-schema", {"del": ["/schema"]}, "required", ""),
         ("extra-key", {"set": {"/flash": 1}}, "additionalProperties", "/flash"),
         ("rise-under-120s", {"set": {"/ash/riseTicks": 1200}}, "minimum", "/ash/riseTicks"),
         ("ash-over-max", {"set": {"/ash/max": 1500}}, "maximum", "/ash/max")]),
    "data/fight/flight.json": ("fight-flight", "fight.flight/1",
        "data/fight/flight.json: a launch's flight on a curve (docs/architecture/feel-core.md; Game Design's fight-feel.md section 1). Policy: closed except keys starting with an underscore.",
        {"enabled": BOOL,
         "curve": obj({"ramp": num(1, 60, True, "ticks of the kick's ramp to the peak"),
                       "hold": num(0, 60, True, "ticks at the peak"),
                       "easeTo": num(2, 600, True, "the tick the glide is reached"),
                       "glide": num(0.05, 1, desc="the glide's share of the peak"),
                       "arrive": num(0.05, 1.5, desc="the arrival's share of the peak"),
                       "arriveTicks": num(1, 120, True, "ticks of the arrival's ramp, before his contact")}),
         "pace": obj({"kMin": num(0.01, 1, desc="the least his physics is slowed in a tick"),
                      "kMax": num(1, 10, desc="the most his physics is sped up in a tick")})},
        [("required-schema", {"del": ["/schema"]}, "required", ""),
         ("extra-key", {"set": {"/speed": 1}}, "additionalProperties", "/speed"),
         ("enabled-not-bool", {"set": {"/enabled": 1}}, "type", "/enabled"),
         ("ramp-zero", {"set": {"/curve/ramp": 0}}, "minimum", "/curve/ramp"),
         ("glide-over-one", {"set": {"/curve/glide": 1.5}}, "maximum", "/curve/glide")]),
    "data/fight/hitstop.json": ("fight-hitstop", "fight.hitstop/1",
        "data/fight/hitstop.json: hit-stop by weight with a freeze budget (docs/architecture/feel-core.md; Game Design's rulings-2026-10-19b.md section 4). Policy: closed except keys starting with an underscore.",
        {"enabled": BOOL,
         "ticks": obj({w: num(0, 120, True, "a hit's stop in ticks") for w in ["light_mash", "light", "medium", "heavy", "launch", "launch_full", "decisive", "ko"]}),
         "mashFloor": num(0, 120, True, "a mashed light's stop over the budget"),
         "budget": obj({"share": num(0, 1, desc="the most of the window that may be frozen"),
                        "windowS": num(1, 600, True, "the window, in live seconds")})},
        [("required-schema", {"del": ["/schema"]}, "required", ""),
         ("extra-key", {"set": {"/slowmo": 1}}, "additionalProperties", "/slowmo"),
         ("heavy-negative", {"set": {"/ticks/heavy": -1}}, "minimum", "/ticks/heavy"),
         ("share-over-one", {"set": {"/budget/share": 2}}, "maximum", "/budget/share"),
         ("ticks-missing-ko", {"del": ["/ticks/ko"]}, "required", "/ticks")]),
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
