# PARKED BUILD (Simulation): the air brake (Game Design, docs/design/buildings.md section 7.2), with the air_brake event
# Animation asked for. Behind data/fight/brake.json "enabled" (off): with it off every match, replay and checkpoint is
# the same to the bit.
#   new   sim/core/brake.gd (SimBrake), data/fight/brake.json
#   edits sim/core/state.gd, sim.gd, hash.gd, fighter.gd, replay.gd, fx.gd, view/fx.gd, tools/parity.gd (one check);
#         docs/architecture/fx-events.md (the event)
# World's one function is grant_world.py, beside this (the brake calls it only while on). Applies before or after
# docs/architecture/pending/forms/forms.py. Needs an import after applying (a new class name).
# Usage: python brake.py <repo root>      (run from anywhere; it reads src/ beside itself)
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:80], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

assert not os.path.exists('sim/core/brake.gd'), 'the brake is already in'
shutil.copyfile(os.path.join(HERE, 'src', 'brake.gd'), 'sim/core/brake.gd')
shutil.copyfile(os.path.join(HERE, 'src', 'brake.json'), 'data/fight/brake.json')

edit('sim/core/state.gd', [
("var depthOn: bool = false             # fight lanes: depth is physical (the director's depth.json switch, or the setup's \"depth\"); off until L4\n",
 "var depthOn: bool = false             # fight lanes: depth is physical (the director's depth.json switch, or the setup's \"depth\"); off until L4\n"
 "var brakeOn: bool = false             # the air brake (sim/core/brake.gd): data/fight/brake.json's switch, or the setup's \"brake\"; off\n"),
("class Fighter:\n\tvar name: String = \"\"\n",
 "## A fighter's air brake while S.brakeOn (sim/core/brake.gd).\n"
 "class BrakeState:\n"
 "\tvar n: int = 0             # the launch number of his last send (Fighter.launchN): a new one is a new send\n"
 "\tvar t: int = 0             # live ticks since that send\n"
 "\tvar v0: float = 0.0        # the send's own speed (the traversal factor divided out)\n"
 "\tvar at: int = 0            # the tick after the send from which he may brake (the start window)\n"
 "\tvar no: bool = false       # a set piece's send: no brake\n"
 "\tvar on: bool = false       # braking now\n"
 "\tvar marks: int = 0         # the send kind's marks on him (air sense): the sender's to set; 0 until launch-anywhere\n"
 "\n\n"
 "class Fighter:\n\tvar name: String = \"\"\n"),
("\tvar style = null                 # M1: StyleState (sim/core/mood.gd)\n",
 "\tvar style = null                 # M1: StyleState (sim/core/mood.gd)\n"
 "\tvar brk = null                   # the air brake: BrakeState while S.brakeOn (sim/core/brake.gd), null otherwise\n"),
])

edit('sim/core/sim.gd', [
("## Fight lanes: \"depth\": true makes depth physical for this match (S.depthOn).\n",
 "## Fight lanes: \"depth\": true makes depth physical for this match (S.depthOn).\n"
 "## The air brake: \"brake\": true turns it on for this match (S.brakeOn).\n"),
("\tS.depthOn = setup.get(\"depth\", SimDepth.enabled()) == true   # fighters in depth: the data's switch (data/combat/depth.json), or the setup's own for this match\n",
 "\tS.depthOn = setup.get(\"depth\", SimDepth.enabled()) == true   # fighters in depth: the data's switch (data/combat/depth.json), or the setup's own for this match\n"
 "\tS.brakeOn = setup.get(\"brake\", SimBrake.enabled()) == true   # the air brake: the data's switch (data/fight/brake.json), or the setup's own for this match\n"
 "\tSimBrake.setup(S)   # each fighter's brake state while the brake is on\n"),
])

edit('sim/core/hash.gd', [
("\t\t_obj(out, act, [\"v2\", \"guardSince\", \"dodgeTick\", \"dodgeCool\", \"burstCool\", \"mode\", \"assist\", \"formReady\", \"burstFired\", \"breakIn\", \"flow\"])\n",
 "\t\t_obj(out, act, [\"v2\", \"guardSince\", \"dodgeTick\", \"dodgeCool\", \"burstCool\", \"mode\", \"assist\", \"formReady\", \"burstFired\", \"breakIn\", \"flow\"])\n"
 "\t\tif S.brakeOn:   # the air brake: only when on, so a match without it hashes as before\n"
 "\t\t\t_obj(out, f.brk, SimBrake.HASHED)\n"),
("\"transform_ready\": [\"actor\", \"tier\", \"source\"], ",
 "\"transform_ready\": [\"actor\", \"tier\", \"source\"], \"air_brake\": [\"actor\", \"text\", \"kind\", \"amount\", \"ux\", \"uy\"], "),
])

edit('sim/core/fighter.gd', [
("\tvar i: SimIntent = f.input\n\tf.power = SimMathx.jmin(100.0, f.power + f.ld.fill * dt)\n",
 "\tvar i: SimIntent = f.input\n"
 "\tif S.brakeOn:\n"
 "\t\tSimBrake.tick(S, f, dt)   # the air brake: a sent fighter who holds it slows, and has control back under a third of the send's speed\n"
 "\tf.power = SimMathx.jmin(100.0, f.power + f.ld.fill * dt)\n"),
])

edit('sim/core/replay.gd', [
("\tif SimDepth.enabled():   # fighters in depth: data/combat/depth.json, once its switch is on (a match with depth off reads none of it)\n\t\th.text(SimDepth.dataHash())\n",
 "\tif SimDepth.enabled():   # fighters in depth: data/combat/depth.json, once its switch is on (a match with depth off reads none of it)\n\t\th.text(SimDepth.dataHash())\n"
 "\tif setup.get(\"brake\", SimBrake.enabled()) == true:   # the air brake: data/fight/brake.json, only for a match with it on\n"
 "\t\th.text(SimBrake.dataHash())\n"),
])

edit('sim/core/fx.gd', [
("static func transformReady(S: SimState, f, tier: float, source: String) -> void:\n",
 "## The air brake (sim/core/brake.gd; only while S.brakeOn): text start or end; kind the reason (held at the start; at the\n"
 "## end speed, his control back under a third of the send's speed, released, ground, or hit, a new send); amount his\n"
 "## own speed, and ux, uy his flight's direction (both with the traversal factor divided out).\n"
 "static func airBrake(S: SimState, f, phase: String, why: String, speed: float, ux: float, uy: float) -> void:\n"
 "\tvar e := _ev(S, \"air_brake\")\n"
 "\te.actor = float(S.fighters.find(f)); e.text = phase; e.kind = why; e.amount = speed; e.ux = ux; e.uy = uy\n"
 "\n\n"
 "static func transformReady(S: SimState, f, tier: float, source: String) -> void:\n"),
])
edit('sim/core/view/fx.gd', [
("\"decisive\", \"finisher_start\",",
 "\"decisive\", \"air_brake\", \"finisher_start\","),
])

edit('docs/architecture/fx-events.md', [
("| `struggle_press` |",
 "| `air_brake` | actor, text, kind, amount, ux, uy | the air brake only (`S.brakeOn`; `sim/core/brake.gd`): `text` start or end; `kind` the reason (held at the start; at the end speed, his control back under a third of the send's speed, released, ground, or hit, a new send); `amount` his own speed, and `ux`, `uy` his flight's direction, both with the launch's traversal factor divided out. With ground contact on, control back also ends his journey (`journey_end`, kind brake) | nothing; Animation (the midair skid), VFX (its trail), Audio, Camera |\n"
 "| `struggle_press` |"),
])

p = 'sim/core/tools/parity.gd'
edit(p, [
("\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n",
 "\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n"
 "\tcheck(\"the air brake\", _brake())\n"),
])
s = open(p, encoding='utf-8').read()
assert s.endswith('\n') and '_brake() -> String' not in s
s += open(os.path.join(HERE, 'src', 'brake_check.gd'), encoding='utf-8').read()
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("the air brake is in (the switch is off)")
