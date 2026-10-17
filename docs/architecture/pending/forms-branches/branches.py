# PARKED BUILD (Simulation): the forms' two branches, Witness and Trial (Game Design, docs/design/hero-forms.md
# section 3, and section 4's pick), on main's forms (8f157894). Behind the forms switch (data/fight/forms.json, off):
# with it off every match, replay and checkpoint is the same to the bit.
#   edits sim/core/forms.gd (the fills, the pick, the branch extras), state.gd (FormState's fills and branch), sim.gd
#         (the Trial fill reads the tick's events), fx.gd and hash.gd (form_step carries the branch and a cross),
#         data/fighters/PROTAGONIST/forms.json (the branch steps and the branches' numbers), tools/parity.gd (the forms
#         check's gains with the branch; one new check), docs/architecture/fx-events.md (form_step's fields)
# World's two lines are grant_world.py, beside this (the casualty's place for Witness; anguish no longer fed by the
# opponent's kills for a fighter with branches). No new class, no import needed.
# Usage: python branches.py <repo root>      (run from anywhere; it reads src/ beside itself)
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:80], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

assert 'var witness: float' not in open('sim/core/state.gd', encoding='utf-8').read(), 'the branches are already in'

edit('sim/core/state.gd', [
("\tvar lasting: float = 1.0   # his step gains' lasting factor (the largest release so far)\n",
 "\tvar lasting: float = 1.0   # his step gains' lasting factor (the largest release so far)\n"
 "\tvar witness: float = 0.0   # the Witness fill: his opponent's kills near him; his own take from it (hero-forms.md section 3)\n"
 "\tvar trial: float = 0.0     # the Trial fill: the opponent risen first, a deficit fought out, his commitments met, the coil\n"
 "\tvar branch: String = \"\"    # the branch of the form he is in: \"\", witness or trial\n"
 "\tvar crossed: bool = false  # his last branch step changed branch (a cross: Narrative voices the turn)\n"),
])

edit('sim/core/fx.gd', [
("## Forms: f's taken steps rise at the break: he stands at step k, of kind live or pausing (the last one taken), at tier\n"
 "## for the world, and coil is what the release spent (0 for a step taken at once). A tier_up comes first when the tier rose.\n"
 "static func formStep(S: SimState, f, k: int, kind: String, tier: float, coil: float) -> void:\n"
 "\tvar e := _ev(S, \"form_step\")\n"
 "\te.actor = float(S.fighters.find(f)); e.k = float(k); e.kind = kind; e.tier = tier; e.amount = coil\n",
 "## Forms: f's taken steps rise at the break: he stands at step k, of kind live or pausing (the last one taken), at tier\n"
 "## for the world, and coil is what the release spent (0 for a step taken at once). A tier_up comes first when the tier rose.\n"
 "## text is the branch of the form he is in (\"\" before II), and source \"cross\" when this rise changed it.\n"
 "static func formStep(S: SimState, f, k: int, kind: String, tier: float, coil: float, branch: String = \"\", cross: bool = false) -> void:\n"
 "\tvar e := _ev(S, \"form_step\")\n"
 "\te.actor = float(S.fighters.find(f)); e.k = float(k); e.kind = kind; e.tier = tier; e.amount = coil\n"
 "\te.text = branch; e.source = \"cross\" if cross else \"\"\n"),
])
edit('sim/core/hash.gd', [
("\"form_step\": [\"actor\", \"k\", \"kind\", \"tier\", \"amount\"]",
 "\"form_step\": [\"actor\", \"k\", \"kind\", \"tier\", \"amount\", \"text\", \"source\"]"),
])
edit('sim/core/sim.gd', [
("\tSimMood.tick(S)   # M1: reads this tick's events; writes only its own state and events\n",
 "\tSimMood.tick(S)   # M1: reads this tick's events; writes only its own state and events\n"
 "\tif S.formsOn:\n"
 "\t\tSimForms.events(S)   # forms: the Trial fill reads this tick's events (the opponent's forms, his blows, the opponent's commitments)\n"),
])

p = 'sim/core/forms.gd'
edit(p, [
("const HASHED: Array = [\"step\", \"ready\", \"coil\", \"coiling\", \"holdT\", \"held\", \"pend\", \"pendCoil\", \"surgeT\", \"surgeMul\", \"armour\", \"lasting\"]\n",
 "const HASHED: Array = [\"step\", \"ready\", \"coil\", \"coiling\", \"holdT\", \"held\", \"pend\", \"pendCoil\", \"surgeT\", \"surgeMul\", \"armour\", \"lasting\", \"witness\", \"trial\", \"branch\", \"crossed\"]\n"),
("\tvar lastingMax: float = 1.0\n",
 "\tvar lastingMax: float = 1.0\n"
 "\t# The branches (hero-forms.md section 3): the steps that pick one, the fills' sources and each branch's extras\n"
 "\tvar branchAt: Array = []      # the steps (1-based) at which a release picks a branch: II and IV\n"
 "\tvar wRange: float = 0.0       # Witness: an opponent's kill this near him (shortest arc) fills it ...\n"
 "\tvar wPerPerson: float = 0.0   # ... by this a person, times 425 / pop0 as every gain a person\n"
 "\tvar wOwnKill: float = 0.0     # ... and each person he kills takes this off it\n"
 "\tvar wDamage: float = 0.0      # in a Witness form: damage and launch force x (1 + these), his care + wCare\n"
 "\tvar wLaunch: float = 0.0\n"
 "\tvar wCare: float = 0.0\n"
 "\tvar tForm: float = 0.0        # Trial: the opponent takes a form while his tier is no higher ...\n"
 "\tvar tFormHeld: float = 0.0    # ... this instead when his own form was ready and he held it\n"
 "\tvar tPerSec: float = 0.0      # ... a second of fight time while the opponent's tier is above his\n"
 "\tvar tBlow: float = 0.0        # ... a blow of a medium or more he lands while it is\n"
 "\tvar tCommit: float = 0.0      # ... the opponent commits fully: a finisher, a beam clash, fighting on at the brink\n"
 "\tvar tSpeed: float = 0.0       # in a Trial form: speed x (1 + this); the perfect-block window wider by tBlock[level - 1]\n"
 "\tvar tBlock: Array = [0, 0]    # ticks; perfect follow-ups worth tFollow more (the director reads both)\n"
 "\tvar tFollow: int = 0\n"
 "\tvar firstTie: String = \"trial\"   # the pick's first tie (he is on no branch yet)\n"),
# the deficit second, and each coil point a Trial point
("\tif f.act.breakIn >= 0:\n\t\treturn\n\tvar n: int = byPower(f) - fs.step\n",
 "\tif SimRoster.opp(S, f).tier > f.tier:   # Trial: a second of fight time fought a tier down\n"
 "\t\tfs.trial += f.fd.tPerSec * dt\n"
 "\tif f.act.breakIn >= 0:\n\t\treturn\n\tvar n: int = byPower(f) - fs.step\n"),
("\tif fs.coiling:\n\t\tfs.coil = SimMathx.jmin(f.fd.coilMax, fs.coil + f.fd.coilPerSec * _behind(S, f) * dt)\n",
 "\tif fs.coiling:\n"
 "\t\tvar c0: float = fs.coil\n"
 "\t\tfs.coil = SimMathx.jmin(f.fd.coilMax, fs.coil + f.fd.coilPerSec * _behind(S, f) * dt)\n"
 "\t\tfs.trial += fs.coil - c0   # each coil point is a Trial point (the coil is Trial's road: hero-forms.md section 4b)\n"),
("\t\tif x != null and has(S, x) and x.form.coiling:\n"
 "\t\t\tx.form.coil = SimMathx.jmin(x.fd.coilMax, x.form.coil + amt * x.fd.coilPerDamage * _behind(S, x))\n",
 "\t\tif x != null and has(S, x) and x.form.coiling:\n"
 "\t\t\tvar c0: float = x.form.coil\n"
 "\t\t\tx.form.coil = SimMathx.jmin(x.fd.coilMax, x.form.coil + amt * x.fd.coilPerDamage * _behind(S, x))\n"
 "\t\t\tx.form.trial += x.form.coil - c0\n"),
# the pick at the break
("\tfs.step = mini(f.fd.steps.size(), fs.step + n)\n\tvar s: Dictionary = f.fd.steps[fs.step - 1]\n",
 "\tvar from: int = fs.step\n"
 "\tfs.step = mini(f.fd.steps.size(), fs.step + n)\n"
 "\tvar cross: bool = _pick(S, f, from)\n"
 "\tvar s: Dictionary = f.fd.steps[fs.step - 1]\n"),
("\tSimFx.formStep(S, f, fs.step, String(s.kind), f.tier, c)\n",
 "\tSimFx.formStep(S, f, fs.step, String(s.kind), f.tier, c, fs.branch, cross)\n"),
# the branch extras on the gains
("\t\treturn 1.0 + f.ld.speed * (f.tier - 1.0)\n\treturn _g(f, f.fd.gSpeed) * _surge(f)\n",
 "\t\treturn 1.0 + f.ld.speed * (f.tier - 1.0)\n\treturn _g(f, f.fd.gSpeed) * _surge(f) * (1.0 + (f.fd.tSpeed if f.form.branch == \"trial\" else 0.0))\n"),
("\t\treturn 1.0 + f.ld.damage * (f.tier - 1.0)\n\treturn _g(f, f.fd.gDamage) * _surge(f)\n",
 "\t\treturn 1.0 + f.ld.damage * (f.tier - 1.0)\n\treturn _g(f, f.fd.gDamage) * _surge(f) * (1.0 + (f.fd.wDamage if f.form.branch == \"witness\" else 0.0))\n"),
("\t\treturn 1.0 + f.ld.launch * (f.tier - 1.0)\n\treturn _g(f, f.fd.gLaunch)\n",
 "\t\treturn 1.0 + f.ld.launch * (f.tier - 1.0)\n\treturn _g(f, f.fd.gLaunch) * (1.0 + (f.fd.wLaunch if f.form.branch == \"witness\" else 0.0))\n"),
# the data
("\t\td.steps.append({\"power\": p, \"tier\": t, \"kind\": String(s.get(\"kind\", \"live\")), \"id\": String(s.get(\"id\", \"\"))})\n",
 "\t\td.steps.append({\"power\": p, \"tier\": t, \"kind\": String(s.get(\"kind\", \"live\")), \"id\": String(s.get(\"id\", \"\"))})\n"
 "\t\tif s.has(\"branch\") and not (s.branch is bool):\n"
 "\t\t\t_err(at + \".branch: true or false\")\n"
 "\t\tif s.get(\"branch\") == true:\n"
 "\t\t\td.branchAt.append(i + 1)\n"),
("\td.lastingMax = _num(w + \": release.lastingMax\", r.get(\"lastingMax\"), 1.0, 3.0)\n\treturn d\n",
 "\td.lastingMax = _num(w + \": release.lastingMax\", r.get(\"lastingMax\"), 1.0, 3.0)\n"
 "\tif not _branches(w, d, j.get(\"branches\")):\n"
 "\t\treturn null\n"
 "\treturn d\n"),
])
s = open(p, encoding='utf-8').read()
a = "# --------------------------------------------------------------------------------------------------------------- the data\n"
assert s.count(a) == 1
s = s.replace(a, open(os.path.join(HERE, 'src', 'branches_fns.gd'), encoding='utf-8').read() + a)
a2 = "static func _num(where: String, x, lo: float, hi: float) -> float:\n"
assert s.count(a2) == 1
s = s.replace(a2, open(os.path.join(HERE, 'src', 'branches_data.gd'), encoding='utf-8').read() + a2)
open(p, 'w', encoding='utf-8', newline='\n').write(s)

edit('data/fighters/PROTAGONIST/forms.json', [
("{\"power\": 35.0, \"tier\": 2, \"kind\": \"pausing\", \"id\": \"form_ii\"}",
 "{\"power\": 35.0, \"tier\": 2, \"kind\": \"pausing\", \"id\": \"form_ii\", \"branch\": true}"),
("{\"power\": 65.0, \"tier\": 3, \"kind\": \"pausing\", \"id\": \"form_iv\"}",
 "{\"power\": 65.0, \"tier\": 3, \"kind\": \"pausing\", \"id\": \"form_iv\", \"branch\": true}"),
("  \"_release\":",
 open(os.path.join(HERE, 'src', 'branches.json.txt'), encoding='utf-8').read() + "  \"_release\":"),
])

p = 'sim/core/tools/parity.gd'
edit(p, [
("\tif SimForms.speedMul(M, p) != 1.0 + p.fd.gSpeed * 5.0 * p.form.lasting or SimForms.damageMul(M, p) != 1.0 + p.fd.gDamage * 5.0 * p.form.lasting:\n",
 "\tvar xs: float = 1.0 + (p.fd.tSpeed if p.form.branch == \"trial\" else 0.0)   # the branch's extras (the branches' check has them)\n"
 "\tvar xd: float = 1.0 + (p.fd.wDamage if p.form.branch == \"witness\" else 0.0)\n"
 "\tvar xl: float = 1.0 + (p.fd.wLaunch if p.form.branch == \"witness\" else 0.0)\n"
 "\tif SimForms.speedMul(M, p) != (1.0 + p.fd.gSpeed * 5.0 * p.form.lasting) * xs or SimForms.damageMul(M, p) != (1.0 + p.fd.gDamage * 5.0 * p.form.lasting) * xd:\n"),
("\tif SimForms.launchMul(M, p) != 1.0 + p.fd.gLaunch * 5.0 * p.form.lasting or SimForms.recoverAfter(M, p, 0.3) != 0.3 * (1.0 - p.fd.gRecover * 5.0 * p.form.lasting):\n",
 "\tif SimForms.launchMul(M, p) != (1.0 + p.fd.gLaunch * 5.0 * p.form.lasting) * xl or SimForms.recoverAfter(M, p, 0.3) != 0.3 * (1.0 - p.fd.gRecover * 5.0 * p.form.lasting):\n"),
("\tif SimForms.speedMul(B, p) != (1.0 + p.fd.gSpeed * 5.0 * p.form.lasting) * p.form.surgeMul:\n",
 "\tvar bs: float = 1.0 + (p.fd.tSpeed if p.form.branch == \"trial\" else 0.0)\n"
 "\tif SimForms.speedMul(B, p) != (1.0 + p.fd.gSpeed * 5.0 * p.form.lasting) * p.form.surgeMul * bs:\n"),
("\tif p.form.surgeT != 0 or p.form.surgeMul != 1.0 or SimForms.speedMul(B, p) != 1.0 + p.fd.gSpeed * 5.0 * p.form.lasting:\n",
 "\tif p.form.surgeT != 0 or p.form.surgeMul != 1.0 or SimForms.speedMul(B, p) != (1.0 + p.fd.gSpeed * 5.0 * p.form.lasting) * 1.0 * bs:\n"),
("\tcheck(\"forms: five steps and the slingshot\", _forms())\n",
 "\tcheck(\"forms: five steps and the slingshot\", _forms())\n"
 "\tcheck(\"forms: Witness and Trial\", _formBranches())\n"),
])
s = open(p, encoding='utf-8').read()
assert s.endswith('\n') and '_formBranches() -> String' not in s
s += open(os.path.join(HERE, 'src', 'branches_check.gd'), encoding='utf-8').read()
open(p, 'w', encoding='utf-8', newline='\n').write(s)

p = 'docs/architecture/fx-events.md'
s = open(p, encoding='utf-8').read()
i = s.index('| `form_step` | actor, k, kind, tier, amount |')
j = s.index('\n', i)
row = s[i:j].replace('| `form_step` | actor, k, kind, tier, amount |', '| `form_step` | actor, k, kind, tier, amount, text, source |', 1)
row = row.replace(' | nothing; Art,', '. `text` is the branch of the form he is in (witness or trial; empty before II), and `source` is cross when this rise changed it (Narrative voices the turn) | nothing; Art,', 1)
s = s[:i] + row + s[j:]
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("Witness and Trial are in (the forms switch is off)")
