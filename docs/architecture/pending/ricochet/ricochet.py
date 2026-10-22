# PARKED BUILD (Simulation): the ricochet's glance (Game Design's fight-feel.md section 3; rulings-2026-10-22.md 2b; the
# EP's brief of 2026-10-22; docs/architecture/ricochet-core.md). Behind data/fight/ricochet.json (off): no golden moves.
#   new   sim/core/ricochet.gd (SimRicochet: the rule, predict, the row's count, told, offFace), data/fight/ricochet.json
#   edits sim/core/state.gd (S.ricOn; Fighter.rics, ricN), sim.gd (the switch), hash.gd (the row, only when on; the
#         event's fields), replay.gd (the data, only when on), fx.gd and view/fx.gd (the ricochet event), flight.gd
#         (SimFlight.endLeg, public), tools/parity.gd (one check), docs/architecture/fx-events.md
# World's lines (contact.gd's landing and brunt.gd's face) are grant_world.py beside this, in the same commit.
# Needs an import (a new class). Applies before or after shared/. Usage: python ricochet.py <repo root>
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

assert not os.path.exists('sim/core/ricochet.gd'), 'already in'
shutil.copyfile(os.path.join(HERE, 'src', 'ricochet.gd'), 'sim/core/ricochet.gd')
shutil.copyfile(os.path.join(HERE, 'src', 'ricochet.json'), 'data/fight/ricochet.json')

edit('sim/core/state.gd', [
("var hs = null                         # ... its freeze budget: StopState while hitstopOn, null otherwise\n",
 "var hs = null                         # ... its freeze budget: StopState while hitstopOn, null otherwise\n"
 "var ricOn: bool = false               # the ricochet's glance (sim/core/ricochet.gd): data/fight/ricochet.json's switch, or the setup's \"ricochet\"; off\n"),
("\tvar flt = null                   # the launch's curve: FlightState while S.flightOn (sim/core/flight.gd), null otherwise\n",
 "\tvar flt = null                   # the launch's curve: FlightState while S.flightOn (sim/core/flight.gd), null otherwise\n"
 "\tvar rics: int = 0                # ricochets (glances and plants) in this send's row (sim/core/ricochet.gd); hashed only while S.ricOn\n"
 "\tvar ricN: int = 0                # ... the launch number the row belongs to (a new send starts a new row)\n"),
])
edit('sim/core/sim.gd', [
("\tSimHitstop.setup(S)   # the freeze budget while it is on\n",
 "\tSimHitstop.setup(S)   # the freeze budget while it is on\n"
 "\tS.ricOn = setup.get(\"ricochet\", SimRicochet.enabled()) == true   # the ricochet's glance: the data's switch (data/fight/ricochet.json), or the setup's own\n"),
])
edit('sim/core/hash.gd', [
("\t\tif S.flightOn:   # the launch's curve: only when on\n\t\t\t_obj(out, f.flt, SimFlight.HASHED)\n",
 "\t\tif S.flightOn:   # the launch's curve: only when on\n\t\t\t_obj(out, f.flt, SimFlight.HASHED)\n"
 "\t\tif S.ricOn:   # the ricochet's row: only when on\n\t\t\t_obj(out, f, SimRicochet.HASHED)\n"),
("\"transform_ready\": [\"actor\", \"tier\", \"source\"], ",
 "\"transform_ready\": [\"actor\", \"tier\", \"source\"], \"ricochet\": [\"actor\", \"kind\", \"text\", \"x\", \"y\", \"ux\", \"uy\", \"amount\", \"n\"], "),
])
edit('sim/core/replay.gd', [
("\tif setup.get(\"hitstop\", SimHitstop.enabled()) == true:",
 "\tif setup.get(\"ricochet\", SimRicochet.enabled()) == true:   # the ricochet's glance: data/fight/ricochet.json, only for a match with it on\n"
 "\t\th.text(SimRicochet.dataHash())\n"
 "\tif setup.get(\"hitstop\", SimHitstop.enabled()) == true:"),
])
edit('sim/core/fx.gd', [
("static func flight(S: SimState, f, text: String, amount: float, t: int, why: String = \"\") -> void:\n",
 "## A ricochet (sim/core/ricochet.gd), for Encounter and Camera: kind glance (or Encounter's plant), text the surface\n"
 "## (the ground's surface name, or building), at x, y; ux, uy his direction after it and amount his speed (normalised:\n"
 "## the traversal factor divided out); n the ricochets in this row so far, this one included.\n"
 "static func ricochet(S: SimState, f, kind: String, surface: String, x: float, y: float, ux: float, uy: float, amount: float, n: int) -> void:\n"
 "\tvar e := _ev(S, \"ricochet\")\n"
 "\te.actor = float(S.fighters.find(f)); e.kind = kind; e.text = surface; e.x = x; e.y = y; e.ux = ux; e.uy = uy; e.amount = amount; e.n = n\n"
 "\n\n"
 "static func flight(S: SimState, f, text: String, amount: float, t: int, why: String = \"\") -> void:\n"),
])
edit('sim/core/view/fx.gd', [
("\"decisive\", ", "\"decisive\", \"ricochet\", "),
])
edit('sim/core/flight.gd', [
("static func _end(S: SimState, f, why: String) -> void:\n",
 "## The paced leg ends here for a reason of another system's (a ricochet: SimRicochet.told), told with it.\n"
 "static func endLeg(S: SimState, f, why: String) -> void:\n"
 "\tif f.flt != null and f.flt.on:\n"
 "\t\t_end(S, f, why)\n"
 "\n\n"
 "static func _end(S: SimState, f, why: String) -> void:\n"),
])
edit('docs/architecture/fx-events.md', [
("| `flight` |",
 "| `ricochet` | actor, kind, text, x, y, ux, uy, amount, n | the ricochet's glance only (`S.ricOn`; `sim/core/ricochet.gd`): `kind` glance (or Encounter's plant, told the same way), `text` the surface met (the ground's surface name, or building), at `x`, `y`; `ux`, `uy` his direction after it and `amount` his speed (normalised: the traversal factor divided out); `n` the ricochets in this send's row, this one included (at most `maxInRow`). A ground glance is also World's `bounce` (with its `keep`) | nothing; Encounter (the choreographer), Camera, VFX (the scrape), Audio |\n"
 "| `flight` |"),
])
p = 'sim/core/tools/parity.gd'
edit(p, [
("\tcheck(\"hit-stop by weight\", _hitstop())\n",
 "\tcheck(\"hit-stop by weight\", _hitstop())\n"
 "\tcheck(\"the ricochet's glance\", _ricochet())\n"),
])
s = open(p, encoding='utf-8').read()
assert s.endswith('\n') and '_ricochet() -> String' not in s
s += open(os.path.join(HERE, 'src', 'ricochet_check.gd'), encoding='utf-8').read()
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("the ricochet's glance is in, off")
