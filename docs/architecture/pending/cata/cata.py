# PARKED BUILD (Simulation): VFX's ask for the catastrophe tier's sky (docs/vfx/blast-cloud.md): the blast_cloud cue
# (x, y, amount, n) and the world's ash, read-only, as run-core.md section 6 lays it out (S.cata's ash, its start,
# target and ticks left, in thousandths). Nothing calls it until the catastrophe tier is built, so no golden moves: S.cata is null
# until a blast cloud and hashed only once it is not.
#   new   sim/core/cata.gd (SimCata), data/fight/catastrophe.json
#   edits sim/core/state.gd (S.cata, CataState), sim.gd (cleared at a new match; the ash's rise each live tick),
#         hash.gd (S.cata, only when not null; the event's fields), fx.gd and view/fx.gd (blast_cloud),
#         tools/parity.gd (one check), docs/architecture/fx-events.md (the event)
# Needs an import (a new class). Applies before or after the other parks. Usage: python cata.py <repo root>
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

assert not os.path.exists('sim/core/cata.gd'), 'already in'
shutil.copyfile(os.path.join(HERE, 'src', 'cata.gd'), 'sim/core/cata.gd')
shutil.copyfile(os.path.join(HERE, 'src', 'catastrophe.json'), 'data/fight/catastrophe.json')

edit('sim/core/state.gd', [
("var out := Out.new()\n",
 "var cata = null                       # the catastrophe's state (sim/core/cata.gd): CataState from the first blast cloud, null before\n"
 "var out := Out.new()\n"),
("## A fighter's forms while S.formsOn (sim/core/forms.gd)",
 "## The catastrophe's state (sim/core/cata.gd; docs/architecture/run-core.md section 6): the ash so far. The tier-5\n"
 "## window adds the rest of the block (the phase, the tremor, the events' counts, the hazard wear, the magma).\n"
 "class CataState:\n"
 "\tvar ash: int = 0           # the ash over the planet, in thousandths: no rule reads it, the views do (SimCata.ash)\n"
 "\tvar ashFrom: int = 0       # ... the level the last cloud found\n"
 "\tvar ashTo: int = 0         # ... the level it rises to\n"
 "\tvar ashLeft: int = 0       # ... and the live ticks of its rise left\n"
 "\n\n"
 "## A fighter's forms while S.formsOn (sim/core/forms.gd)"),
])
edit('sim/core/sim.gd', [
("\tSimMood.tick(S)   # M1: reads this tick's events; writes only its own state and events\n",
 "\tSimMood.tick(S)   # M1: reads this tick's events; writes only its own state and events\n"
 "\tif S.cata != null and S.cata.ashLeft > 0:\n"
 "\t\tSimCata.tick(S)   # the catastrophe's ash rises (a blast cloud started it)\n"),
("\tS.depthOn = setup.get(\"depth\", SimDepth.enabled()) == true",
 "\tS.cata = null   # no catastrophe yet (the tier-5 window sets it up from the stage's ceiling)\n"
 "\tS.depthOn = setup.get(\"depth\", SimDepth.enabled()) == true"),
])
edit('sim/core/hash.gd', [
("\tout.append(S.depthOn)   # fight lanes (L0)\n",
 "\tout.append(S.depthOn)   # fight lanes (L0)\n"
 "\tif S.cata != null:   # the catastrophe's state: only once a blast cloud set it, so a match without one hashes as before\n"
 "\t\t_obj(out, S.cata, [\"ash\", \"ashFrom\", \"ashTo\", \"ashLeft\"])\n"),
("\"transform_ready\": [\"actor\", \"tier\", \"source\"], ",
 "\"transform_ready\": [\"actor\", \"tier\", \"source\"], \"blast_cloud\": [\"actor\", \"x\", \"y\", \"amount\", \"n\"], "),
])
edit('sim/core/fx.gd', [
("static func transformReady(S: SimState, f, tier: float, source: String) -> void:\n",
 "## The catastrophe tier's blast cloud (sim/core/cata.gd): by f (or none), landing at x, y on tick n, amount its size.\n"
 "## VFX's cloud, Audio's hush before it and Camera read it; the ash it raises is SimCata.ash(S).\n"
 "static func blastCloud(S: SimState, f, x: float, y: float, amount: float, n: int) -> void:\n"
 "\tvar e := _ev(S, \"blast_cloud\")\n"
 "\te.actor = float(S.fighters.find(f)) if f != null else -1.0; e.x = x; e.y = y; e.amount = amount; e.n = n\n"
 "\n\n"
 "static func transformReady(S: SimState, f, tier: float, source: String) -> void:\n"),
])
edit('sim/core/view/fx.gd', [
("\"decisive\", ", "\"decisive\", \"blast_cloud\", "),
])
edit('docs/architecture/fx-events.md', [
("| `struggle_press` |",
 "| `blast_cloud` | actor, x, y, amount, n | the catastrophe tier's blast cloud (`sim/core/cata.gd`; nothing sends it until the catastrophe tier is built): by `actor` (-1 for none), landing at `x`, `y` on tick `n`, `amount` its size (3,000). It raises the world's ash (`SimCata.ash(S)`, 0 to 1, read-only), which rises over at least 120 s (Legal c05) and has no rule effect | nothing; VFX (the cloud), Audio (the hush at `n` - 8), Camera |\n"
 "| `struggle_press` |"),
])
p = 'sim/core/tools/parity.gd'
edit(p, [
("\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n",
 "\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n"
 "\tcheck(\"the catastrophe's blast cloud and ash\", _cata())\n"),
])
s = open(p, encoding='utf-8').read()
assert s.endswith('\n') and '_cata() -> String' not in s
s += open(os.path.join(HERE, 'src', 'cata_check.gd'), encoding='utf-8').read()
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("the blast cloud's cue and the ash are in (nothing calls them yet)")
