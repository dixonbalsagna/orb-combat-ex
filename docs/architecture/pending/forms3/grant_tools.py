# GRANT (Tools' tools/schemas/fighters-forms.schema.json, for Simulation's forms3.py beside this). The release block
# follows Game Design's working rule (2026-10-18): minCoil, perPoint and maxMul; the burst, the surge, its armour and the
# lasting gain are withdrawn. The schema is closed, so it changes in the same commit as the data. Tools applies it, or
# grants it. Usage: python grant_tools.py <repo root>
import json, os, sys
os.chdir(sys.argv[1])
p = 'tools/schemas/fighters-forms.schema.json'
d = json.load(open(p, encoding='utf-8'))
r = d['properties']['release']
assert 'burst' in r['properties'], 'the release block is already the working rule'
r['required'] = ["minCoil", "perPoint", "maxMul"]
r['properties'] = {
    "minCoil": {"type": "number", "minimum": 0, "description": "the coil a release needs to make its form stronger"},
    "perPoint": {"type": "number", "minimum": 0, "maximum": 0.1, "description": "the form's step gains x (1 + coil x perPoint)"},
    "maxMul": {"type": "number", "minimum": 1, "maximum": 4, "description": "... at most this, for as long as he is in that form"},
}
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')

# the self-test's fixture hero (tools/fixtures/virtual/data/fighters/FIXTURE_HERO/forms.json) takes the same release
# block, and the fixture cases follow it: the withdrawn keys' cases go, and perPoint's and maxMul's come in their place
fp = 'tools/fixtures/virtual/data/fighters/FIXTURE_HERO/forms.json'
t = open(fp, encoding='utf-8').read()
i = t.index('  "release": {')
j = t.index('\n  },', i) + len('\n  },')
t = t[:i] + '''  "release": {
    "minCoil": 1.0,
    "perPoint": 0.01,
    "maxMul": 2.0
  },''' + t[j:]
json.loads(t)
open(fp, 'w', encoding='utf-8', newline='\n').write(t)
cp = 'tools/fixtures/cases.json'
c = json.load(open(cp, encoding='utf-8'))
gone = ['burst', 'surgeticks', 'surge', 'armour', 'lastingper', 'lastingmax']
keep = []
at = -1
for k in c['cases']:
    if k['schema'] == 'fighters-forms.schema.json' and any(k['id'].endswith('-release-' + g) for g in gone):
        if at < 0:
            at = len(keep)
        continue
    keep.append(k)
assert at >= 0, 'the release cases moved'
new = []
for key in ['perPoint', 'maxMul']:
    for kind, val, rule in [('type', 'x', 'type'), ('negative', -1, 'minimum')]:
        new.append({"id": "fighters-forms-%s-release-%s" % (kind, key.lower()), "schema": "fighters-forms.schema.json",
                    "mutate": [{"file": "data/fighters/FIXTURE_HERO/forms.json", "set": {"/release/" + key: val}}],
                    "expect": {"rule": rule, "pointer": "/release/" + key}})
c['cases'] = keep[:at] + new + keep[at:]
open(cp, 'w', encoding='utf-8', newline='\n').write(json.dumps(c, indent=2, ensure_ascii=False) + '\n')
print("the forms schema, its fixture hero and its release cases follow the working rule")
