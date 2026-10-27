# PARKED BUILD (Simulation): the calm turn's slower read on a gen 2 planet (Game Design's rulings-2026-10-26 item 28;
# docs/architecture/calm-turn-read.md): the total K columns a tick (12) across a pick's rings, held in the state (the
# pick's k, World's E.next.k), and a form step's warm begun at its ready tell. A launch's warm already begins as it is
# thrown, and a warm not done in time goes to the next calm moment (Encounter's waiting rule).
#   sim/core/fx.gd: the ready tell (SimFx.transformReady) calls DirCalm.atReady (Encounter's, grant_encounter.py), which
#     does nothing unless the director's calm turn is on and the planet is gen 2;
#   sim/core/tools/parity.gd: "the calm turn on gen 2".
# Encounter's lines (calm.gd, interrupts.json calmTurn.warmColsGen2) are grant_encounter.py, World's flip (rings.json
# turn.warmTotal 1, World's switch in World's calm-read park) grant_world.py, Tools' two schema lines grant_tools.py.
# On a gen 1 planet each ring reads as before, and the golden does not move.
# Usage, on World's calm-read park: grant_world.py, grant_encounter.py, calm_k.py, then grant_tools.py (each <root>).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
assert 'static func atReady' in open('sim/director/calm.gd', encoding='utf-8').read(), "Encounter's grant first"


def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)


edit('sim/core/fx.gd', [
("static func transformReady(S: SimState, f, tier: float, source: String) -> void:\n"
 "\tvar e := _ev(S, \"transform_ready\")\n"
 "\te.actor = float(S.fighters.find(f)); e.tier = tier; e.source = source\n",
 "static func transformReady(S: SimState, f, tier: float, source: String) -> void:\n"
 "\tvar e := _ev(S, \"transform_ready\")\n"
 "\te.actor = float(S.fighters.find(f)); e.tier = tier; e.source = source\n"
 "\tDirCalm.atReady(S, f)   # the ready tell begins a calm turn's warm on a gen 2 planet (Game Design's rulings-2026-10-26 item 28)\n"),
])

CHECK = open(os.path.join(HERE, 'files', 'parity_calm_gen2.gd.txt'), encoding='utf-8').read()
edit('sim/core/tools/parity.gd', [
("\tcheck(\"the planet's load\", _planetLoad())\n",
 "\tcheck(\"the planet's load\", _planetLoad())\n"
 "\tcheck(\"the calm turn on gen 2\", _calmGen2())\n"),
("func _ringHolds(ev: Dictionary, id: int) -> bool:\n", CHECK + "\n\nfunc _ringHolds(ev: Dictionary, id: int) -> bool:\n"),
])
print("the calm turn's gen 2 read: the ready tell's warm (SimFx.transformReady), parity's check")
