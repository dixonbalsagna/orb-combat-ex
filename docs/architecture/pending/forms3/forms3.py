# PARKED BUILD (Simulation): forms, the third window, on Game Design's rulings of 2026-10-18 (rulings-2026-10-18.md 2a,
# rulings-2026-10-18b.md 2). Behind the forms switch (data/fight/forms.json, off): with it off nothing moves.
#   The slingshot's working rule: one step a transformation (a release takes only the next step; the steps still ready
#   stay ready), and the coil makes that one form stronger: its step gains x (1 + c x perPoint), at most maxMul, for as
#   long as he is in it. Withdrawn: the jump of several steps, the burst, the surge and its armour, the lasting gain.
#   Witness's perPerson goes to 4.
#   edits sim/core/forms.gd, state.gd, tools/parity.gd (the two forms checks), data/fighters/PROTAGONIST/forms.json,
#         three comments in damage.gd and fighter.gd that named the surge,
#         docs/architecture/fx-events.md (form_release's n is 1)
# Tools' schema lines are grant_tools.py beside this (the release block's keys), in the same commit.
# Usage: python forms3.py <repo root>
import os, re, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
def between(p, start, end, new):
    s = open(p, encoding='utf-8').read()
    assert s.count(start) == 1 and s.count(end) >= 1, (p, start[:60], s.count(start), s.count(end))
    i = s.index(start)
    j = s.index(end, i)
    open(p, 'w', encoding='utf-8', newline='\n').write(s[:i] + new + s[j:])

assert 'formMul' not in open('sim/core/forms.gd', encoding='utf-8').read(), 'the working rule is already in'

# ------------------------------------------------------------------------------------------------------------ the state
# three comments that name the withdrawn surge
edit('sim/core/damage.gd', [
("SimForms.damageMul(S, A)   # the tier's step (with forms: his own steps and the surge)",
 "SimForms.damageMul(S, A)   # the tier's step (with forms: his own steps, by the coil's factor on his form)"),
])
edit('sim/core/fighter.gd', [
("SimForms.speedMul(S, f)   # the tier's step (with forms: his own steps and the surge)",
 "SimForms.speedMul(S, f)   # the tier's step (with forms: his own steps, by the coil's factor on his form)"),
("SimForms.readyTick(S, f, dt)   # his ready steps, banked while he waits; the coil; the surge",
 "SimForms.readyTick(S, f, dt)   # his ready steps, banked while he waits; the coil"),
])

edit('sim/core/state.gd', [
("\tvar surgeT: int = 0        # live ticks of a release's surge left\n"
 "\tvar surgeMul: float = 1.0  # ... its speed and damage factor\n"
 "\tvar armour: int = 0        # his next blows that land with armour (the director spends them)\n"
 "\tvar lasting: float = 1.0   # his step gains' lasting factor (the largest release so far)\n",
 "\tvar formMul: float = 1.0   # the coil's factor on his step gains in the form he is in (until his next step)\n"),
])

# ----------------------------------------------------------------------------------------------------------- the module
p = 'sim/core/forms.gd'
edit(p, [
("## comes ready while he waits is banked, and the coil fills while he holds; the release takes every banked step at once,\n"
 "## with a burst, a surge and a lasting gain. The hold and the release are told for every fighter (form_hold,\n",
 "## comes ready while he waits is banked, and the coil fills while he holds. A release takes the next step only, and the\n"
 "## coil makes that one form stronger (Game Design's working rule, 2026-10-18). The hold and the release are told for\n"
 "## every fighter (form_hold,\n"),
("\"pendCoil\", \"surgeT\", \"surgeMul\", \"armour\", \"lasting\",", "\"pendCoil\", \"formMul\","),
("\tvar minCoil: float = 0.0       # the release's extras need at least this much coil\n"
 "\tvar burst: float = 0.0         # the release's burst, at a full coil, as a share of a ground power-up's\n"
 "\tvar surgeTicks: int = 0        # the surge: its length, and its speed and damage at a full coil\n"
 "\tvar surge: float = 0.0\n"
 "\tvar armour: int = 0            # blows with armour at a full coil (rounded by the coil's share)\n"
 "\tvar lastingPer: float = 0.0    # the lasting gain: the step gains x (1 + coil x lastingPer), at most lastingMax\n"
 "\tvar lastingMax: float = 1.0\n",
 "\tvar minCoil: float = 0.0       # the coil a release needs to make its form stronger (a step taken at once has a sliver)\n"
 "\tvar perPoint: float = 0.0      # the form's step gains x (1 + coil x perPoint) ...\n"
 "\tvar maxMul: float = 1.0        # ... at most this, for as long as he is in it\n"),
("\tvar k: int = mini(f.fd.steps.size(), f.form.step + maxi(1, f.form.ready))\n",
 "\tvar k: int = mini(f.fd.steps.size(), f.form.step + 1)   # one step a transformation\n"),
("## while the opponent's tier is above his. The surge runs down. Nothing comes ready while a taken release waits for its\n"
 "## break, as today.\n",
 "## while the opponent's tier is above his. Nothing comes ready while a taken release waits for its break, as today.\n"),
("\tvar fs = f.form\n\tif fs.surgeT > 0:\n\t\tfs.surgeT -= 1\n\t\tif fs.surgeT == 0:\n\t\t\tfs.surgeMul = 1.0\n\tif SimRoster.opp(S, f).tier > f.tier:",
 "\tvar fs = f.form\n\tif SimRoster.opp(S, f).tier > f.tier:"),
("\t\tm *= 1.0 - f.fd.gChip * float(f.form.step) * f.form.lasting\n",
 "\t\tm *= 1.0 - f.fd.gChip * float(f.form.step) * f.form.formMul\n"),
])
between(p, "## The release (SimFighter.transform, for a fighter with steps): he takes every ready step at once.",
        "## A taken form, told (every fighter while forms are on)",
"""## The release (SimFighter.transform, for a fighter with steps): one step a transformation. He takes the next step only,
## and the steps still ready stay ready. It rises at the break (rise), on this tick or at the end of the version's
## gather, with the coil he held. False if nothing was ready.
static func take(S: SimState, f) -> bool:
	if not f.act.formReady:
		return false
	var fs = f.form
	f.act.formReady = false
	if fs.ready <= 0 or fs.step >= f.fd.steps.size():
		f.act.breakIn = -1
		fs.ready = 0
		return false
	fs.pend = 1
	fs.pendCoil = fs.coil
	var k: int = fs.step + 1
	released(S, f, 1, fs.coil, k, float(f.fd.steps[k - 1].tier))
	fs.ready -= 1
	if f.act.breakIn <= 0:
		SimFighter.formBreak(S, f)
	return true


""")
between(p, "## The break of a release (SimFighter.formBreak, for a fighter with steps): the taken steps rise.",
        "## True when every ready step is a live one",
"""## The break of a release (SimFighter.formBreak, for a fighter with steps): the taken step rises. His tier for the
## world follows it (with today's power-up when it rises). The coil makes this one form stronger: its step gains x
## (1 + c x perPoint), at most maxMul, for as long as he is in it; under minCoil (a step taken at once) the form is plain.
## The coil is spent. The steps still ready stay ready.
static func rise(S: SimState, f) -> void:
	var fs = f.form
	var n: int = fs.pend
	var c: float = fs.pendCoil
	fs.pend = 0
	fs.pendCoil = 0.0
	if n <= 0:
		return
	var from: int = fs.step
	fs.step = mini(f.fd.steps.size(), fs.step + n)
	var cross: bool = _pick(S, f, from)
	var s: Dictionary = f.fd.steps[fs.step - 1]
	var t: float = float(s.tier)
	if t > f.tier:
		f.tier = t
		SimFighter.tierUp(S, f)
	fs.formMul = SimMathx.jmin(f.fd.maxMul, 1.0 + c * f.fd.perPoint) if (c >= f.fd.minCoil and c > 0.0) else 1.0
	SimFx.formStep(S, f, fs.step, String(s.kind), f.tier, c, fs.branch, cross)
	fs.coil = 0.0
	fs.coiling = false
	var more: int = byPower(f) - fs.step
	if more > 0:
		fs.ready = more
		f.act.formReady = true
		SimFx.transformReady(S, f, nextTier(S, f), DirExchange.transformSource(f))
	DirExchange.formBreak(S, f)   # the rival in reach is pushed back at the break, as at every step


""")
edit(p, [
("\tfor k in range(fs.step, mini(f.fd.steps.size(), fs.step + fs.ready)):\n",
 "\tfor k in range(fs.step, mini(f.fd.steps.size(), fs.step + 1)):   # one step a transformation: the next one\n"),
("## True when every ready step is a live one (SimPause.request: a live release never pauses the fight).",
 "## True when the next step is a live one (SimPause.request: a live release never pauses the fight)."),
("## The step gains, with the lasting gain: 1 + g x steps x lasting.\nstatic func _g(f, g: float) -> float:\n\treturn 1.0 + g * float(f.form.step) * f.form.lasting\n",
 "## The step gains, with the coil's factor on the form he is in: 1 + g x steps x formMul.\nstatic func _g(f, g: float) -> float:\n\treturn 1.0 + g * float(f.form.step) * f.form.formMul\n"),
])
s = open(p, encoding='utf-8').read()
a = "static func _surge(f) -> float:\n\treturn f.form.surgeMul if f.form.surgeT > 0 else 1.0\n\n\n"
assert s.count(a) == 1
s = s.replace(a, "")
for a, b in [("\treturn _g(f, f.fd.gSpeed) * _surge(f) * (1.0 +", "\treturn _g(f, f.fd.gSpeed) * (1.0 +"),
             ("\treturn _g(f, f.fd.gDamage) * _surge(f) * (1.0 +", "\treturn _g(f, f.fd.gDamage) * (1.0 +"),
             ("\treturn t * SimMathx.jmax(0.0, 1.0 - f.fd.gRecover * float(f.form.step) * f.form.lasting)\n",
              "\treturn t * SimMathx.jmax(0.0, 1.0 - f.fd.gRecover * float(f.form.step) * f.form.formMul)\n")]:
    assert s.count(a) == 1, a[:60]
    s = s.replace(a, b)
i = s.index("## Armour on his next blows after a release")
j = s.index("static func useArmour(S: SimState, f) -> void:")
j = s.index("\n\n\n", j) + 3
s = s[:i] + s[j:]
s = s.replace("## Free-flight speed's tier factor (SimFighter.flightSpeed; the director's estimate of it). Without steps, today's.",
              "## Free-flight speed's tier factor (SimFighter.flightSpeed; the director's estimate of it). Without steps, today's.", 1)
for a, b in [
 ("\td.minCoil = _num(w + \": release.minCoil\", r.get(\"minCoil\"), 0.0, 100.0)\n"
  "\td.burst = _num(w + \": release.burst\", r.get(\"burst\"), 0.0, 4.0)\n"
  "\td.surgeTicks = _int(w + \": release.surgeTicks\", r.get(\"surgeTicks\"), 0)\n"
  "\td.surge = _num(w + \": release.surge\", r.get(\"surge\"), 0.0, 1.0)\n"
  "\td.armour = _int(w + \": release.armour\", r.get(\"armour\"), 0)\n"
  "\td.lastingPer = _num(w + \": release.lastingPer\", r.get(\"lastingPer\"), 0.0, 0.1)\n"
  "\td.lastingMax = _num(w + \": release.lastingMax\", r.get(\"lastingMax\"), 1.0, 3.0)\n",
  "\td.minCoil = _num(w + \": release.minCoil\", r.get(\"minCoil\"), 0.0, 100.0)\n"
  "\td.perPoint = _num(w + \": release.perPoint\", r.get(\"perPoint\"), 0.0, 0.1)\n"
  "\td.maxMul = _num(w + \": release.maxMul\", r.get(\"maxMul\"), 1.0, 4.0)\n"),
]:
    assert s.count(a) == 1, a[:60]
    s = s.replace(a, b)
assert 'lasting' not in s and 'surge' not in s and 'armour' not in s and '_burst' not in s, [w for w in ['lasting', 'surge', 'armour', '_burst'] if w in s]
open(p, 'w', encoding='utf-8', newline='\n').write(s)

# -------------------------------------------------------------------------------------------------------------- the data
p = 'data/fighters/PROTAGONIST/forms.json'
s = open(p, encoding='utf-8').read()
i = s.index('  "release": {')
j = s.index('\n  },', i) + len('\n  },')
s = s[:i] + '''  "release": {
    "minCoil": 1.0,
    "perPoint": 0.01,
    "maxMul": 2.0
  },''' + s[j:]
i = s.index('  "_release": "')
j = s.index('"', s.index(': "', i) + 3)
while s[j - 1] == '\\':
    j = s.index('"', j + 1)
s = s[:i] + '''  "_release": "one step a transformation (Game Design's working rule, 2026-10-18): holding Transform takes the next step only, and the steps still ready stay ready. A coil of c (minCoil or more: a step taken at once carries a sliver, and stays plain) makes that one form stronger: its step gains x (1 + c x perPoint), at most maxMul, for as long as he is in it. The burst, the surge, its armour and the lasting gain are withdrawn, pending Narrative's lore paper"''' + s[j + 1:]
a = '      "perPerson": 1.0,\n'
assert s.count(a) == 1
s = s.replace(a, '      "perPerson": 4.0,\n')
open(p, 'w', encoding='utf-8', newline='\n').write(s)
import json
json.loads(s)

# --------------------------------------------------------------------------------------------------- the two forms checks
p = 'sim/core/tools/parity.gd'
s = open(p, encoding='utf-8').read()
i = s.index("func _forms() -> String:")
j = s.index("func _brake() -> String:")
body = s[i:j]
for a, b in [
 ("\tif p.form.lasting != 1.0 or p.form.surgeT != 0:\n\t\treturn \"a step taken at once carried a release's extras\"\n",
  "\tif p.form.formMul != 1.0:\n\t\treturn \"a step taken at once made its form stronger\"\n"),
 (" * p.form.surgeMul", ""),
]:
    assert body.count(a) >= 1, a[:60]
    body = body.replace(a, b)
body = body.replace("p.form.lasting", "p.form.formMul")
k0 = body.index("\tvar c: float = p.form.coil\n\tB.out.fx.clear()\n")
k1 = body.index("\tp.form.coiling = true\n\tSimForms.traded(B, p, null, 100000.0)\n")
body = body[:k0] + open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'src', 'release_check.gd.txt'), encoding='utf-8').read() + body[k1:]
for a, b in [
 # the picks: one step a transformation, so step I is taken before II, and III before IV
 ("\tp.power = 35.0\n\tSimForms.readyTick(M, p, dt)\n\tp.form.witness = 30.0\n",
  "\tp.power = 35.0\n\tSimForms.readyTick(M, p, dt)\n\tSimFighter.transform(M, p)   # one step a transformation: I first\n\tp.form.witness = 30.0\n"),
 ("\tp.power = 65.0\n\tSimForms.readyTick(M, p, dt)\n\tp.form.witness = 5.0\n",
  "\tp.power = 65.0\n\tSimForms.readyTick(M, p, dt)\n\tSimFighter.transform(M, p)   # III first\n\tp.form.witness = 5.0\n"),
 ("\tp.power = 35.0\n\tSimForms.readyTick(T, p, dt)\n\tp.form.witness = 7.0\n",
  "\tp.power = 35.0\n\tSimForms.readyTick(T, p, dt)\n\tSimFighter.transform(T, p)\n\tp.form.witness = 7.0\n"),
 ("\tp.power = 65.0\n\tSimForms.readyTick(T, p, dt)\n\tp.form.witness = 3.0\n",
  "\tp.power = 65.0\n\tSimForms.readyTick(T, p, dt)\n\tSimFighter.transform(T, p)\n\tp.form.witness = 3.0\n"),
 # a live release: with I and II ready, the release is I alone (live); after it, II alone is not
 ("\tif SimForms.releaseLive(p) or p.form.ready != 2:\n\t\treturn \"a release with step II in it is live\"\n",
  "\tif not SimForms.releaseLive(p) or p.form.ready != 2:\n\t\treturn \"with I and II ready, the release (I alone) is not live\"\n"
  "\tif not SimFighter.transform(L, p) or p.form.step != 1 or SimForms.releaseLive(p):\n\t\treturn \"after step I, a release of step II is live\"\n"),
]:
    assert body.count(a) == 1, a[:60]
    body = body.replace(a, b)
u0 = body.index("\tvar U := SimCore.createSim()\n")
u1 = body.index("\tSimCore.dispose(U)\n", u0) + len("\tSimCore.dispose(U)\n")
body = body[:u0] + '''\tvar U := SimCore.createSim()
	SimCore.newMatch(U, 7, {"p1": false, "p2": false}, {"forms": true})
	p = U.fighters[0]
	p.power = 65.0
	SimForms.readyTick(U, p, dt)
	p.form.witness = 20.0
	p.form.trial = 10.0
	SimFighter.transform(U, p)
	if p.form.step != 1 or p.form.branch != "" or p.form.witness != 20.0 or p.form.ready != 3 or not p.act.formReady:
		return "a release from base at 65 took more than step I, or picked: step %d, %s, %d still ready" % [p.form.step, p.form.branch, p.form.ready]
	SimFighter.transform(U, p)
	if p.form.step != 2 or p.form.branch != "witness" or p.form.witness != 0.0 or p.form.trial != 10.0:
		return "the next release, at II, picked %s (fills %s and %s)" % [p.form.branch, str(p.form.witness), str(p.form.trial)]
	SimCore.dispose(U)
''' + body[u1:]
assert 'surge' not in body and 'armour' not in body and 'lasting' not in body, [w for w in ['surge', 'armour', 'lasting'] if w in body]
s = s[:i] + body + s[j:]
s = s.replace("## Forms (hero-forms.md sections 4 and 4b; docs/architecture/forms-core.md). Off (the committed switch), a match has no\n## form state and a replay carries no forms data. On: the Protagonist's five steps come ready at their powers and his tier\n## for the world steps at three of them; steps that come ready while he waits are banked, and one release takes them all,\n## none lost;",
              "## Forms (hero-forms.md sections 4 and 4b; docs/architecture/forms-core.md). Off (the committed switch), a match has no\n## form state and a replay carries no forms data. On: the Protagonist's five steps come ready at their powers and his tier\n## for the world steps at three of them; steps that come ready while he waits are banked, and a release takes the next\n## one only, none lost;", 1)
open(p, 'w', encoding='utf-8', newline='\n').write(s)

p = 'docs/architecture/fx-events.md'
s = open(p, encoding='utf-8').read()
a = "forms only: `actor` takes `n` steps at once (the release), spending the coil `amount`,"
if a in s:
    s = s.replace(a, "forms only: `actor` takes the next step (the release: `n` is 1, one step a transformation), spending the coil `amount`,", 1)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("forms: one step a transformation, the coil on that form; Witness 4")
