# PARKED BUILD (Simulation): a mash flows (Game Design's rulings-2026-10-22.md 6), on hitstop2 as applied (83405d99),
# behind the hit-stop switch (data/fight/hitstop.json, off): with it off nothing moves.
#   A new weight, light_flow, holds no stop: a mash's later blows (each within 12 ticks of the last), which Encounter
#   names. Only the mash's first blow stops (light_mash, 2). A 0 is never raised by the second step's floor (cutFloor 2),
#   and since it freezes nothing the budget never counts it. The 18% budget and its x0.75 step stand.
#   edits sim/core/hitstop.gd, data/fight/hitstop.json, sim/core/tools/parity.gd (the hit-stop check)
# Tools' schema line (the ticks' light_flow; the virtual copy) is grant_tools.py beside this, in the same commit.
# Usage: python mash_flow.py <repo root>
import json, os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

p = 'sim/core/hitstop.gd'
assert 'light_flow' not in open(p, encoding='utf-8').read(), 'already in'
edit(p, [
("##                leaves about 1e-17 for n of 3 or more, a tick more than asked; frozen() drops that residue. With the\n"
 "##                switch off, today's count stands.\n",
 "##                leaves about 1e-17 for n of 3 or more, a tick more than asked; frozen() drops that residue. With the\n"
 "##                switch off, today's count stands.\n"
 "##   a mash flows: light_flow is 0, no stop (Game Design's rulings-2026-10-22.md 6): a mash's later blows, which\n"
 "##                Encounter names; only the mash's first blow stops (light_mash, 2). A 0 is never raised by the cut's\n"
 "##                floor, and freezes nothing, so the budget never counts it.\n"),
("const WEIGHTS: Array = [\"light_mash\", \"light\", \"medium\", \"heavy\", \"launch\", \"launch_full\", \"decisive\", \"ko\"]\n",
 "const WEIGHTS: Array = [\"light_flow\", \"light_mash\", \"light\", \"medium\", \"heavy\", \"launch\", \"launch_full\", \"decisive\", \"ko\"]\n"),
("## least cutFloor). -1 for a weight not in it.\n",
 "## least cutFloor); a stop of 0 (a mash's flowing blow) stays 0. -1 for a weight not in it.\n"),
("\tif over(S) and not NEVER_CUT.has(weight):\n",
 "\tif n > 0 and over(S) and not NEVER_CUT.has(weight):\n"),
])

p = 'data/fight/hitstop.json'
d = json.load(open(p, encoding='utf-8'))
t = d['ticks']
assert 'light_flow' not in t
t2 = {"light_flow": 0}
for k, v in t.items():
    t2[k] = v
t2['_note'] = ("a hit's stop in ticks by the weight it names (o.weight), Game Design's table of rulings-2026-10-22.md 5b and 6: "
               "a mash's later blows flow (light_flow, 0: no stop; Encounter names them, each within 12 ticks of the last), "
               "its first blow stops (light_mash, a mashed or burst light, 2), a tapped light 3, a medium 5, a heavy 8, a launch "
               "or a close 12, a full launch 14; decisive (a finisher's last, a duel of perfects' send, a blow that breaks a "
               "region: the core's) 20; ko the KO, 24 at most. A stop of n ticks freezes n")
d['ticks'] = t2
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')

p = 'sim/core/tools/parity.gd'
edit(p, [
("\tvar want: Dictionary = {\"light_mash\": 2, \"light\": 3,",
 "\tvar want: Dictionary = {\"light_flow\": 0, \"light_mash\": 2, \"light\": 3,"),
("\tvar cut: Dictionary = {\"light_mash\": 2, \"light\": 2,",
 "\tvar cut: Dictionary = {\"light_flow\": 0, \"light_mash\": 2, \"light\": 2,"),
("\t# whole ticks: a stop of n ticks freezes n (the count-down's residue gave n + 1 for n of 3 or more), and the damage\n",
 "\t# a mash flows (Game Design's 6): a flowing blow holds no stop, and the clock runs on\n"
 "\tS.dirS.stop = 0.0\n"
 "\tvar tf: float = S.T\n"
 "\tSimDamage.hit(S, null, A, D, 1.0, {\"weight\": \"light_flow\", \"stop\": 0.5})\n"
 "\tSimCore.step(S, [null, null])\n"
 "\tif S.dirS.stop != 0.0 or S.T == tf:\n"
 "\t\treturn \"a mash's flowing blow held %s ticks, the clock %s\" % [str(S.dirS.stop / SimConst.DT), \"ran\" if S.T != tf else \"froze\"]\n"
 "\t# whole ticks: a stop of n ticks freezes n (the count-down's residue gave n + 1 for n of 3 or more), and the damage\n"),
])
print("a mash flows: light_flow, no stop")
