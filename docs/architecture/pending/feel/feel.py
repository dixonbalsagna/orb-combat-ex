# PARKED BUILD (Simulation): the fight's feel in the core, for the camera (Game Design's rulings-2026-10-19.md 1 and
# 19b section 4; fight-feel.md sections 1 and 6; Research's cinematic-storytelling.md recommendations 9 and 10;
# docs/architecture/feel-core.md). Two switches, both off: with them off, no golden moves.
#   the launch's curve   data/fight/flight.json (S.flightOn): a launched body is paced along its path (the kick's ramp,
#                        the peak, the glide at 0.4, the arrival's rise to 0.6), and the flight cue tells the camera
#   hit-stop by weight   data/fight/hitstop.json (S.hitstopOn): a hit's o.weight names its stop from the table; a broken
#                        region and the KO are the core's own; the freeze budget (12% of a minute) floors mashed lights
#   new   sim/core/flight.gd (SimFlight), sim/core/hitstop.gd (SimHitstop), data/fight/flight.json, hitstop.json
#   edits sim/core/state.gd, sim.gd, fighter.gd, damage.gd, hash.gd, replay.gd, fx.gd, view/fx.gd, tools/parity.gd,
#         docs/architecture/fx-events.md
# Needs an import (two new classes). Applies before or after the other parks. Usage: python feel.py <repo root>
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

assert not os.path.exists('sim/core/flight.gd') and not os.path.exists('sim/core/hitstop.gd'), 'already in'
for a, b in [('flight.gd', 'sim/core/flight.gd'), ('hitstop.gd', 'sim/core/hitstop.gd'),
             ('flight.json', 'data/fight/flight.json'), ('hitstop.json', 'data/fight/hitstop.json')]:
    shutil.copyfile(os.path.join(HERE, 'src', a), b)

edit('sim/core/state.gd', [
("var formsOn: bool = false             # forms (sim/core/forms.gd): the Protagonist's five steps and the slingshot (data/fight/forms.json, or the setup's \"forms\"); off\n",
 "var formsOn: bool = false             # forms (sim/core/forms.gd): the Protagonist's five steps and the slingshot (data/fight/forms.json, or the setup's \"forms\"); off\n"
 "var flightOn: bool = false            # the launch's curve (sim/core/flight.gd): data/fight/flight.json's switch, or the setup's \"flight\"; off\n"
 "var hitstopOn: bool = false           # hit-stop by weight (sim/core/hitstop.gd): data/fight/hitstop.json's switch, or the setup's \"hitstop\"; off\n"
 "var hs = null                         # ... its freeze budget: StopState while hitstopOn, null otherwise\n"),
("## A fighter's forms while S.formsOn (sim/core/forms.gd)",
 "## A launched fighter's curve while S.flightOn (sim/core/flight.gd): the send it paces, and where it is on the curve.\n"
 "class FlightState:\n"
 "\tvar n: int = 0             # the launch number of the send it paces (Fighter.launchN): a new one starts the curve\n"
 "\tvar t: int = 0             # live ticks of the send's first leg so far\n"
 "\tvar peak: float = 0.0      # the send's speed at the send (world units a second)\n"
 "\tvar on: bool = false       # the first leg is being paced (until a contact, a building, water or the brake)\n"
 "\tvar arr: int = -1          # the live tick the arrival's ramp started, or -1\n"
 "\tvar from: float = 0.0      # ... the curve's share it started from\n"
 "\tvar k: float = 1.0         # this tick's pace: his physics steps by dt x k\n"
 "\n\n"
 "## The hit-stop's freeze budget while S.hitstopOn (sim/core/hitstop.gd): frozen ticks by live second, for the last minute.\n"
 "class StopState:\n"
 "\tvar sec: Array = []        # frozen ticks in each of the last windowS live seconds (a ring)\n"
 "\tvar i: int = 0             # this second's bucket\n"
 "\tvar n: int = 0             # live ticks into this second\n"
 "\tvar sum: int = 0           # frozen ticks in the window\n"
 "\n\n"
 "## A fighter's forms while S.formsOn (sim/core/forms.gd)"),
("\tvar form = null                  # forms: FormState while S.formsOn (sim/core/forms.gd), null otherwise\n",
 "\tvar form = null                  # forms: FormState while S.formsOn (sim/core/forms.gd), null otherwise\n"
 "\tvar flt = null                   # the launch's curve: FlightState while S.flightOn (sim/core/flight.gd), null otherwise\n"),
])
edit('sim/core/sim.gd', [
("\tSimForms.setup(S)   # each fighter's form state while forms are on, and his own steps when his data has them\n",
 "\tSimForms.setup(S)   # each fighter's form state while forms are on, and his own steps when his data has them\n"
 "\tS.flightOn = setup.get(\"flight\", SimFlight.enabled()) == true   # the launch's curve: the data's switch (data/fight/flight.json), or the setup's own\n"
 "\tSimFlight.setup(S)   # each fighter's flight state while the curve is on\n"
 "\tS.hitstopOn = setup.get(\"hitstop\", SimHitstop.enabled()) == true   # hit-stop by weight: the data's switch (data/fight/hitstop.json), or the setup's own\n"
 "\tSimHitstop.setup(S)   # the freeze budget while it is on\n"),
("\tif S.dirS.stop > 0.0:\n\t\tS.dirS.stop -= dtReal\n",
 "\tif S.dirS.stop > 0.0:\n\t\tS.dirS.stop -= dtReal\n"
 "\t\tif S.hitstopOn:\n\t\t\tSimHitstop.frozen(S)   # the freeze budget counts every frozen tick of a hit-stop\n"),
("\tS.T += dt\n\tSimPause.liveTick(S)",
 "\tS.T += dt\n\tif S.hitstopOn:\n\t\tSimHitstop.live(S)   # ... over the last minute of fight\n\tSimPause.liveTick(S)"),
])
edit('sim/core/fighter.gd', [
("\telif f.state == \"launched\":\n\t\tstepLaunched(S, f, dt)\n",
 "\telif f.state == \"launched\":\n\t\tstepLaunched(S, f, dt)\n"
 "\t\tif S.flightOn:\n\t\t\tSimFlight.settle(S, f)   # a contact this tick ends the curve's leg, told now\n"),
("static func stepLaunched(S: SimState, f, dt: float) -> void:\n\tf.stateT += dt\n",
 "static func stepLaunched(S: SimState, f, dt: float) -> void:\n"
 "\tif S.flightOn:\n"
 "\t\tdt = SimFlight.pace(S, f, dt)   # the launch's curve: his first leg is paced along its path (sim/core/flight.gd)\n"
 "\tf.stateT += dt\n"),
])
edit('sim/core/damage.gd', [
("\tS.dirS.stop = SimMathx.jmax(S.dirS.stop, jor(o.get(\"stop\", 0.0), 0.05))\n",
 "\tS.dirS.stop = SimMathx.jmax(S.dirS.stop, SimHitstop.forHit(S, o, jor(o.get(\"stop\", 0.0), 0.05)) if S.hitstopOn else jor(o.get(\"stop\", 0.0), 0.05))   # hit-stop by weight: the table's for o.weight\n"),
("\tvar n0: int = S.out.fx.size()\n\tvar region: int = hurt(",
 "\tvar st0: Array = D.stage.duplicate() if S.hitstopOn else []\n"
 "\tvar n0: int = S.out.fx.size()\n\tvar region: int = hurt("),
("\tif n0 < S.out.fx.size() and S.out.fx[n0].type == \"damage\":   # view fields outside the hash (Animation)",
 "\tif S.hitstopOn:\n"
 "\t\tSimHitstop.afterHit(S, D, st0)   # a blow that breaks a region holds decisive\n"
 "\tif n0 < S.out.fx.size() and S.out.fx[n0].type == \"damage\":   # view fields outside the hash (Animation)"),
("\tS.game.ts = 0.35\n",
 "\tS.game.ts = 0.35\n"
 "\tif S.hitstopOn:\n"
 "\t\tSimHitstop.hold(S, \"ko\")   # hit-stop by weight: the KO holds the cap\n"),
])
edit('sim/core/hash.gd', [
("\t\tif S.formsOn:   # forms: only when on, so a match without them hashes as before\n\t\t\t_obj(out, f.form, SimForms.HASHED)\n",
 "\t\tif S.formsOn:   # forms: only when on, so a match without them hashes as before\n\t\t\t_obj(out, f.form, SimForms.HASHED)\n"
 "\t\tif S.flightOn:   # the launch's curve: only when on\n\t\t\t_obj(out, f.flt, SimFlight.HASHED)\n"),
("\tout.append(S.depthOn)   # fight lanes (L0)\n",
 "\tout.append(S.depthOn)   # fight lanes (L0)\n"
 "\tif S.hitstopOn:   # hit-stop by weight's freeze budget: only when on, so a match without it hashes as before\n"
 "\t\t_obj(out, S.hs, [\"i\", \"n\", \"sum\"])\n"
 "\t\tfor v in S.hs.sec:\n"
 "\t\t\tout.append(float(v))\n"),
("\"transform_ready\": [\"actor\", \"tier\", \"source\"], ",
 "\"transform_ready\": [\"actor\", \"tier\", \"source\"], \"flight\": [\"actor\", \"text\", \"kind\", \"amount\", \"n\", \"t\"], "),
])
edit('sim/core/replay.gd', [
("\tif setup.get(\"forms\", SimForms.enabled()) == true:",
 "\tif setup.get(\"flight\", SimFlight.enabled()) == true:   # the launch's curve: data/fight/flight.json, only for a match with it on\n"
 "\t\th.text(SimFlight.dataHash())\n"
 "\tif setup.get(\"hitstop\", SimHitstop.enabled()) == true:   # hit-stop by weight: data/fight/hitstop.json, only for a match with it on\n"
 "\t\th.text(SimHitstop.dataHash())\n"
 "\tif setup.get(\"forms\", SimForms.enabled()) == true:"),
])
edit('sim/core/fx.gd', [
("static func transformReady(S: SimState, f, tier: float, source: String) -> void:\n",
 "## The launch's curve (sim/core/flight.gd), for the camera: text kick (the send's ramp begins; amount the peak), glide\n"
 "## (the cruise is reached), arrive (his contact is the arrival's ticks ahead) or end (the paced leg is over: kind\n"
 "## contact, brake or send); amount the speed he shows, n the launch number, t the live ticks since the send.\n"
 "static func flight(S: SimState, f, text: String, amount: float, t: int, why: String = \"\") -> void:\n"
 "\tvar e := _ev(S, \"flight\")\n"
 "\te.actor = float(S.fighters.find(f)); e.text = text; e.kind = why; e.amount = amount; e.n = int(f.launchN); e.t = float(t)\n"
 "\n\n"
 "static func transformReady(S: SimState, f, tier: float, source: String) -> void:\n"),
])
edit('sim/core/view/fx.gd', [
("\"decisive\", ", "\"decisive\", \"flight\", "),
])
edit('docs/architecture/fx-events.md', [
("| `struggle_press` |",
 "| `flight` | actor, text, kind, amount, n, t | the launch's curve only (`S.flightOn`; `sim/core/flight.gd`): `text` kick (the send's ramp begins; `amount` the peak), glide (the cruise is reached), arrive (his contact is the arrival's ticks ahead), end (the paced leg is over: `kind` contact, brake or send); `amount` the speed he shows, `n` the launch number, `t` the live ticks since the send | nothing; Camera (the push, the whip at the kick, the glide's framing, the arrival's hold), Animation, Audio |\n"
 "| `struggle_press` |"),
])
p = 'sim/core/tools/parity.gd'
edit(p, [
("\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n",
 "\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n"
 "\tcheck(\"the launch's curve\", _flight())\n"
 "\tcheck(\"hit-stop by weight\", _hitstop())\n"),
])
s = open(p, encoding='utf-8').read()
assert s.endswith('\n') and '_flight() -> String' not in s
s += open(os.path.join(HERE, 'src', 'feel_check.gd'), encoding='utf-8').read()
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("the launch's curve and hit-stop by weight are in, both off")
