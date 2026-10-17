# PARKED BUILD (Simulation): the Protagonist's five steps and the slingshot (Game Design, docs/design/hero-forms.md
# sections 4 and 4b), with the hold and release signals for the waiting game (docs/narrative/waiting-game-lines.md).
# Behind data/fight/forms.json "enabled" (off): with it off every match, replay and checkpoint is the same to the bit.
#   new   sim/core/forms.gd (SimForms), data/fight/forms.json, data/fighters/PROTAGONIST/forms.json
#   edits sim/core/state.gd, sim.gd, hash.gd, fighter.gd, damage.gd, pause.gd, replay.gd, fx.gd, view/fx.gd,
#         tools/parity.gd (one check); docs/architecture/fx-events.md (three events)
# The director's four lines are grant-encounter.py, beside this. Needs an import after applying (a new class name).
# Usage: python forms.py <repo root>      (run from anywhere; it reads src/ beside itself)
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:80], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

assert not os.path.exists('sim/core/forms.gd'), 'forms are already in'
shutil.copyfile(os.path.join(HERE, 'src', 'forms.gd'), 'sim/core/forms.gd')
shutil.copyfile(os.path.join(HERE, 'src', 'fight_forms.json'), 'data/fight/forms.json')
shutil.copyfile(os.path.join(HERE, 'src', 'protagonist_forms.json'), 'data/fighters/PROTAGONIST/forms.json')

edit('sim/core/state.gd', [
("var depthOn: bool = false             # fight lanes: depth is physical (the director's depth.json switch, or the setup's \"depth\"); off until L4\n",
 "var depthOn: bool = false             # fight lanes: depth is physical (the director's depth.json switch, or the setup's \"depth\"); off until L4\n"
 "var formsOn: bool = false             # forms (sim/core/forms.gd): the Protagonist's five steps and the slingshot (data/fight/forms.json, or the setup's \"forms\"); off\n"),
("class Fighter:\n\tvar name: String = \"\"\n",
 "## A fighter's forms while S.formsOn (sim/core/forms.gd): his steps, the coil and the release, and the hold's signal.\n"
 "class FormState:\n"
 "\tvar step: int = 0          # steps taken (0 his base; his forms.json's count at the top)\n"
 "\tvar ready: int = 0         # steps his power has reached that he has not taken: banked while he waits\n"
 "\tvar coil: float = 0.0      # the slingshot's coil, 0 to its max\n"
 "\tvar coiling: bool = false  # the coil fills (from his first banked step until the release spends it)\n"
 "\tvar holdT: int = 0         # live ticks a ready form has been held (every fighter's)\n"
 "\tvar held: int = 0          # the ready steps the last form_hold told\n"
 "\tvar pend: int = 0          # the steps a taken release raises at its break\n"
 "\tvar pendCoil: float = 0.0  # ... and the coil it spends there\n"
 "\tvar surgeT: int = 0        # live ticks of a release's surge left\n"
 "\tvar surgeMul: float = 1.0  # ... its speed and damage factor\n"
 "\tvar armour: int = 0        # his next blows that land with armour (the director spends them)\n"
 "\tvar lasting: float = 1.0   # his step gains' lasting factor (the largest release so far)\n"
 "\n\n"
 "class Fighter:\n\tvar name: String = \"\"\n"),
("\tvar style = null                 # M1: StyleState (sim/core/mood.gd)\n",
 "\tvar style = null                 # M1: StyleState (sim/core/mood.gd)\n"
 "\tvar form = null                  # forms: FormState while S.formsOn (sim/core/forms.gd), null otherwise\n"
 "\tvar fd = null                    # forms: his FormsDef while S.formsOn, when his data has steps; not hashed (data)\n"),
])

edit('sim/core/sim.gd', [
("## Fight lanes: \"depth\": true makes depth physical for this match (S.depthOn).\n",
 "## Fight lanes: \"depth\": true makes depth physical for this match (S.depthOn).\n"
 "## Forms: \"forms\": true turns on the Protagonist's five steps and the slingshot for this match (S.formsOn).\n"),
("\tS.depthOn = setup.get(\"depth\", SimDepth.enabled()) == true   # fighters in depth: the data's switch (data/combat/depth.json), or the setup's own for this match\n",
 "\tS.depthOn = setup.get(\"depth\", SimDepth.enabled()) == true   # fighters in depth: the data's switch (data/combat/depth.json), or the setup's own for this match\n"
 "\tS.formsOn = setup.get(\"forms\", SimForms.enabled()) == true   # forms: the data's switch (data/fight/forms.json), or the setup's own for this match\n"
 "\tSimForms.setup(S)   # each fighter's form state while forms are on, and his own steps when his data has them\n"),
])

edit('sim/core/hash.gd', [
("\t\t_obj(out, act, [\"v2\", \"guardSince\", \"dodgeTick\", \"dodgeCool\", \"burstCool\", \"mode\", \"assist\", \"formReady\", \"burstFired\", \"breakIn\", \"flow\"])\n",
 "\t\t_obj(out, act, [\"v2\", \"guardSince\", \"dodgeTick\", \"dodgeCool\", \"burstCool\", \"mode\", \"assist\", \"formReady\", \"burstFired\", \"breakIn\", \"flow\"])\n"
 "\t\tif S.formsOn:   # forms: only when on, so a match without them hashes as before\n"
 "\t\t\t_obj(out, f.form, SimForms.HASHED)\n"),
])

edit('sim/core/fighter.gd', [
# the tier's speed step
("\tvar sp: float = 430.0 * f.spd * (1.0 + f.ld.speed * (f.tier - 1.0))\n",
 "\tvar sp: float = 430.0 * f.spd * SimForms.speedMul(S, f)   # the tier's step (with forms: his own steps and the surge)\n"),
# readiness: his own steps in place of the thresholds; the hold signal
("\tvar nt: float = tierByPower(f)\n"
 "\tif f.act.formReady and f.tier >= topTier(f):   # a form readied with no tier above it is dropped, before the director can take it\n",
 "\tvar nt: float = tierByPower(f)\n"
 "\tvar steps: bool = SimForms.has(S, f)   # forms: his own steps (sim/core/forms.gd) in place of the ladder's thresholds\n"
 "\tif f.act.formReady and not steps and f.tier >= topTier(f):   # a form readied with no tier above it is dropped, before the director can take it\n"),
("\tif nt > f.tier and f.act.breakIn < 0:   # (not while a taken step waits for its break)\n",
 "\tif steps:\n"
 "\t\tSimForms.readyTick(S, f, dt)   # his ready steps, banked while he waits; the coil; the surge\n"
 "\telif nt > f.tier and f.act.breakIn < 0:   # (not while a taken step waits for its break)\n"),
("\tif f.lastStandLeft > 0 and (f.state == \"free\" or f.state == \"charging\") and f.stunTicks == 0 and S.game.ko == null:\n",
 "\tif S.formsOn:\n"
 "\t\tSimForms.holdTick(S, f)   # forms: how long a ready form is held, told for the waiting game (every fighter's)\n"
 "\tif f.lastStandLeft > 0 and (f.state == \"free\" or f.state == \"charging\") and f.stunTicks == 0 and S.game.ko == null:\n"),
# ki regen
("\tif SimWounds.battered(f, SimWounds.CORE):\n\t\tregen *= f.wd.coreKiRegen\n",
 "\tif SimWounds.battered(f, SimWounds.CORE):\n\t\tregen *= f.wd.coreKiRegen\n"
 "\tif steps:\n\t\tregen *= SimForms.regenMul(f)   # forms: his steps' regen gain\n"),
# the transform: a release takes every banked step
("static func transform(S: SimState, f) -> bool:\n\tif not f.act.formReady:\n\t\treturn false\n\tf.act.formReady = false\n\tif f.tier >= topTier(f):\n\t\tf.act.breakIn = -1\n\t\treturn false\n",
 "static func transform(S: SimState, f) -> bool:\n"
 "\tif SimForms.has(S, f):   # forms: the release takes every banked step (sim/core/forms.gd)\n"
 "\t\treturn SimForms.take(S, f)\n"
 "\tif not f.act.formReady:\n\t\treturn false\n\tf.act.formReady = false\n\tif f.tier >= topTier(f):\n\t\tf.act.breakIn = -1\n\t\treturn false\n"
 "\tif S.formsOn:   # forms: a one-step take is told too, for the waiting game\n"
 "\t\tSimForms.released(S, f, 1, 0.0, 0, f.tier + 1.0)\n"),
("static func formBreak(S: SimState, f) -> void:\n\tf.act.breakIn = -1\n",
 "static func formBreak(S: SimState, f) -> void:\n\tf.act.breakIn = -1\n"
 "\tif SimForms.has(S, f):   # forms: his taken steps rise, with the coil's release\n"
 "\t\tSimForms.rise(S, f)\n"
 "\t\treturn\n"),
# a launch's recovery in water
("\t\tif SimDetMath.hypot(f.vx, f.vy) < 200.0 and f.stateT > 0.3:\n",
 "\t\tif SimDetMath.hypot(f.vx, f.vy) < 200.0 and f.stateT > SimForms.recoverAfter(S, f, 0.3):   # (forms: sooner by his steps)\n"),
])

edit('sim/core/damage.gd', [
("\tvar m: float = A.dmgMul * (1.0 + A.ld.damage * (A.tier - 1.0))\n",
 "\tvar m: float = A.dmgMul * SimForms.damageMul(S, A)   # the tier's step (with forms: his own steps and the surge)\n"),
("\t# Since S2 hp is a readout only (the HUD bar): it floors at 0, and wounds and finishers decide the match.\n",
 "\tif S.formsOn:   # forms: patience and his guard's step gain on what reaches him; the coil counts what is traded\n"
 "\t\tamt = SimForms.taken(S, f, amt, fam)\n"
 "\t\tSimForms.traded(S, f, by, amt)\n"
 "\t# Since S2 hp is a readout only (the HUD bar): it floors at 0, and wounds and finishers decide the match.\n"),
])

edit('sim/core/pause.gd', [
("\t\tvar step: int = int(f.tier) - 1   # the step being taken: called before the tier rises\n"
 "\t\tif step >= 0 and step < f.ld.stepKinds.size() and f.ld.stepKinds[step] == \"live\":\n",
 "\t\tvar step: int = int(f.tier) - 1   # the step being taken: called before the tier rises\n"
 "\t\tvar live: bool = SimForms.releaseLive(f) if SimForms.has(S, f) else (step >= 0 and step < f.ld.stepKinds.size() and f.ld.stepKinds[step] == \"live\")   # forms: a release of live steps only\n"
 "\t\tif live:\n"),
])

edit('sim/core/replay.gd', [
("\tif SimDepth.enabled():   # fighters in depth: data/combat/depth.json, once its switch is on (a match with depth off reads none of it)\n\t\th.text(SimDepth.dataHash())\n",
 "\tif SimDepth.enabled():   # fighters in depth: data/combat/depth.json, once its switch is on (a match with depth off reads none of it)\n\t\th.text(SimDepth.dataHash())\n"
 "\tif setup.get(\"forms\", SimForms.enabled()) == true:   # forms: data/fight/forms.json and each fighter's forms.json, only for a match with them on\n"
 "\t\th.text(SimForms.dataHash())\n"),
])

edit('sim/core/fx.gd', [
("static func transformReady(S: SimState, f, tier: float, source: String) -> void:\n",
 "## Forms (sim/core/forms.gd; only while S.formsOn): f has held a ready form for dur seconds, with n steps ready (banked)\n"
 "## and his coil. Sent once the hold has lasted data/fight/forms.json's signal, and again for each step banked since.\n"
 "static func formHold(S: SimState, f, n: int, dur: float, coil: float) -> void:\n"
 "\tvar e := _ev(S, \"form_hold\")\n"
 "\te.actor = float(S.fighters.find(f)); e.n = n; e.dur = dur; e.amount = coil\n"
 "\n\n"
 "## Forms: f takes n steps at once (the release), spending a coil, after holding the ready form dur seconds; k is the\n"
 "## step it reaches (0 for a fighter without steps), tier the tier for the world it brings. Sent at the take.\n"
 "static func formRelease(S: SimState, f, n: int, coil: float, dur: float, k: int, tier: float) -> void:\n"
 "\tvar e := _ev(S, \"form_release\")\n"
 "\te.actor = float(S.fighters.find(f)); e.n = n; e.amount = coil; e.dur = dur; e.k = float(k); e.tier = tier\n"
 "\n\n"
 "## Forms: f's taken steps rise at the break: he stands at step k, of kind live or pausing (the last one taken), at tier\n"
 "## for the world, and coil is what the release spent (0 for a step taken at once). A tier_up comes first when the tier rose.\n"
 "static func formStep(S: SimState, f, k: int, kind: String, tier: float, coil: float) -> void:\n"
 "\tvar e := _ev(S, \"form_step\")\n"
 "\te.actor = float(S.fighters.find(f)); e.k = float(k); e.kind = kind; e.tier = tier; e.amount = coil\n"
 "\n\n"
 "static func transformReady(S: SimState, f, tier: float, source: String) -> void:\n"),
])
edit('sim/core/hash.gd', [
("\"transform_ready\": [\"actor\", \"tier\", \"source\"], ",
 "\"transform_ready\": [\"actor\", \"tier\", \"source\"], \"form_hold\": [\"actor\", \"n\", \"dur\", \"amount\"], \"form_release\": [\"actor\", \"n\", \"amount\", \"dur\", \"k\", \"tier\"], \"form_step\": [\"actor\", \"k\", \"kind\", \"tier\", \"amount\"], "),
])
edit('sim/core/view/fx.gd', [
("\t\t\t\"drop_start\", \"drop_land\", \"drop_end\", \"decisive\",",
 "\t\t\t\"form_hold\", \"form_release\", \"form_step\", \"drop_start\", \"drop_land\", \"drop_end\", \"decisive\","),
])

edit('docs/architecture/fx-events.md', [
("| `struggle_press` |",
 "| `form_hold` | actor, n, dur, amount | forms only (`S.formsOn`; `sim/core/forms.gd`): `actor` has held a ready form `dur` seconds, with `n` steps ready (banked), and his coil `amount`. Sent once the hold has lasted `data/fight/forms.json`'s `hold.signalTicks`, and again for each step banked since. With forms off, a hold is the time from `transform_ready` to `transform` | nothing; Narrative's waiting-game lines, UI, Audio |\n"
 "| `form_release` | actor, n, amount, dur, k, tier | forms only: `actor` takes `n` steps at once (the release), spending the coil `amount`, after holding `dur` seconds; `k` is the step it reaches (0 for a fighter without steps of his own), `tier` the tier for the world it brings. Sent at the take; the steps rise at the break (`form_step`) | nothing; Narrative, UI, Camera, Audio |\n"
 "| `form_step` | actor, k, kind, tier, amount | forms only: the taken steps rise at the break. `actor` stands at step `k` (`kind` live or pausing, the last one taken) at `tier` for the world, and `amount` is the coil the release spent (0 for a step taken at once). A `tier_up` comes first when the tier rose | nothing; Art, Animation, VFX (the marks at the live steps) |\n"
 "| `struggle_press` |"),
])

# ---------------------------------------------------------------------------------------------------------------- parity
p = 'sim/core/tools/parity.gd'
edit(p, [
("\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n",
 "\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n"
 "\tcheck(\"forms: five steps and the slingshot\", _forms())\n"),
])
s = open(p, encoding='utf-8').read()
assert s.endswith('\n') and '_forms() -> String' not in s
s += open(os.path.join(HERE, 'src', 'forms_check.gd'), encoding='utf-8').read()
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("forms are in (the switch is off)")
