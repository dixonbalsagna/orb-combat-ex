# PARKED BUILD (Simulation): a mash flows (Game Design's rulings-2026-10-22.md 6), and the budget's deep step (7d), on
# hitstop2 as applied (83405d99), behind the hit-stop switch (data/fight/hitstop.json, off): with it off nothing moves.
#   A new weight, light_flow, holds no stop: a mash's later blows (each within 12 ticks of the last), which Encounter
#   names. Only the mash's first blow stops (light_mash, 2). A 0 is never raised by the second step's floor (cutFloor 2),
#   and since it freezes nothing the budget never counts it. The 18% budget and its x0.75 step stand.
#   The deep step: over 40% of the window (budget.deepShare), the step is x0.5 (cutDeepMul, rounded, at least cutFloor)
#   in place of x0.75, against stutter: no ten-second block over 40% frozen. Decisive blows and the KO are never cut.
#   edits sim/core/hitstop.gd, data/fight/hitstop.json, sim/core/tools/parity.gd (the hit-stop check)
# Tools' schema lines (the ticks' light_flow, cutDeepMul, budget.deepShare; the virtual copy) are grant_tools.py beside
# this, in the same commit.
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
("##                5b). Decisive blows and the KO are never cut. Stops merge (the longer one holds); they never add.\n",
 "##                5b). Decisive blows and the KO are never cut. Stops merge (the longer one holds); they never add.\n"
 "##   the deep step: over `deepShare` (40%) of the window, the step is x cutDeepMul (0.5, rounded, at least cutFloor)\n"
 "##                in place of x cutMul, against stutter: no ten-second block over 40% frozen (Game Design's\n"
 "##                rulings-2026-10-22.md 7d).\n"),
("##                leaves about 1e-17 for n of 3 or more, a tick more than asked; frozen() drops that residue. With the\n"
 "##                switch off, today's count stands.\n",
 "##                leaves about 1e-17 for n of 3 or more, a tick more than asked; frozen() drops that residue. With the\n"
 "##                switch off, today's count stands.\n"
 "##   a mash flows: light_flow is 0, no stop (Game Design's rulings-2026-10-22.md 6): a mash's later blows, which\n"
 "##                Encounter names; only the mash's first blow stops (light_mash, 2). A 0 is never raised by the cut's\n"
 "##                floor, and freezes nothing, so the budget never counts it.\n"),
("const WEIGHTS: Array = [\"light_mash\", \"light\", \"medium\", \"heavy\", \"launch\", \"launch_full\", \"decisive\", \"ko\"]\n",
 "const WEIGHTS: Array = [\"light_flow\", \"light_mash\", \"light\", \"medium\", \"heavy\", \"launch\", \"launch_full\", \"decisive\", \"ko\"]\n"),
("static var cutMul: float = 0.75\n",
 "static var cutMul: float = 0.75\n"
 "static var cutDeepMul: float = 0.5\n"),
("static var budgetTicks: int = 108   # derived: share x windowS seconds of ticks\n",
 "static var budgetTicks: int = 108   # derived: share x windowS seconds of ticks\n"
 "static var deepTicks: int = 240     # derived: deepShare x windowS seconds of ticks\n"),
("\tcutMul = float(cm)\n",
 "\tcutMul = float(cm)\n"
 "\tvar dm = j.get(\"cutDeepMul\")\n"
 "\tif not (dm is float or dm is int) or float(dm) <= 0.0 or float(dm) > cutMul:\n"
 "\t\t_err(\"cutDeepMul: a share above 0, at most cutMul\")\n"
 "\t\tdm = cutMul\n"
 "\tcutDeepMul = float(dm)\n"),
("\tbudgetTicks = int(SimMathx.jround(share * float(windowS) / SimConst.DT))\n",
 "\tbudgetTicks = int(SimMathx.jround(share * float(windowS) / SimConst.DT))\n"
 "\tvar ds = b.get(\"deepShare\")\n"
 "\tif not (ds is float or ds is int) or float(ds) < share or float(ds) > 1.0:\n"
 "\t\t_err(\"budget.deepShare: a share from budget.share to 1\")\n"
 "\t\tds = 1.0\n"
 "\tdeepTicks = int(SimMathx.jround(float(ds) * float(windowS) / SimConst.DT))\n"),
("\treturn S.hs.sum >= budgetTicks\n",
 "\treturn S.hs.sum >= budgetTicks\n"
 "\n"
 "\n"
 "## ... and over the deep line: the step cuts deeper.\n"
 "static func deep(S: SimState) -> bool:\n"
 "\treturn S.hs.sum >= deepTicks\n"),
("## The table's ticks for a weight, after the budget: over it, a stop under a decisive blow is x cutMul (rounded, at\n"
 "## least cutFloor). -1 for a weight not in it.\n",
 "## The table's ticks for a weight, after the budget: over it, a stop under a decisive blow is x cutMul, over the deep\n"
 "## line x cutDeepMul (rounded, at least cutFloor); a stop of 0 (a mash's flowing blow) stays 0. -1 for a weight not\n"
 "## in it.\n"),
("\tif over(S) and not NEVER_CUT.has(weight):\n"
 "\t\tn = maxi(cutFloor, int(SimMathx.jround(float(n) * cutMul)))\n",
 "\tif n > 0 and over(S) and not NEVER_CUT.has(weight):\n"
 "\t\tn = maxi(cutFloor, int(SimMathx.jround(float(n) * (cutDeepMul if deep(S) else cutMul))))\n"),
])

p = 'data/fight/hitstop.json'
d = json.load(open(p, encoding='utf-8'))
assert 'light_flow' not in d['ticks'] and 'cutDeepMul' not in d
t2 = {"light_flow": 0}
for k, v in d['ticks'].items():
    t2[k] = v
t2['_note'] = ("a hit's stop in ticks by the weight it names (o.weight), Game Design's table of rulings-2026-10-22.md 5b and 6: "
               "a mash's later blows flow (light_flow, 0: no stop; Encounter names them, each within 12 ticks of the last), "
               "its first blow stops (light_mash, a mashed or burst light, 2), a tapped light 3, a medium 5, a heavy 8, a launch "
               "or a close 12, a full launch 14; decisive (a finisher's last, a duel of perfects' send, a blow that breaks a "
               "region: the core's) 20; ko the KO, 24 at most. A stop of n ticks freezes n")
d2 = {}
for k, v in d.items():
    if k == 'ticks':
        v = t2
    if k == 'budget':
        b2 = {}
        for bk, bv in v.items():
            if bk == '_note':
                b2['deepShare'] = 0.4
                bv = ("the frozen time of the last windowS live seconds is at most share of it (18% of 10 s: 108 ticks). Over it, "
                      "the second step (cutMul) applies; over deepShare of it (40%: 240 ticks), the deep step (cutDeepMul)")
            b2[bk] = bv
        assert 'deepShare' in b2
        v = b2
    d2[k] = v
    if k == 'cutFloor':
        d2['cutDeepMul'] = 0.5
    if k == '_cut':
        d2[k] = ("Game Design's second step (rulings-2026-10-22.md 5b): over the budget, every stop under a decisive blow is x "
                 "cutMul, rounded, at least cutFloor, until the share falls back under; over budget.deepShare, x cutDeepMul in "
                 "place of cutMul, against stutter (7d: no ten-second block over 40% frozen). Decisive blows and the KO are never "
                 "cut, and a stop of 0 stays 0")
assert 'cutDeepMul' in d2
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d2, indent=2, ensure_ascii=False) + '\n')

p = 'sim/core/tools/parity.gd'
edit(p, [
("\tvar want: Dictionary = {\"light_mash\": 2, \"light\": 3,",
 "\tvar want: Dictionary = {\"light_flow\": 0, \"light_mash\": 2, \"light\": 3,"),
("\tvar cut: Dictionary = {\"light_mash\": 2, \"light\": 2,",
 "\tvar cut: Dictionary = {\"light_flow\": 0, \"light_mash\": 2, \"light\": 2,"),
("\tvar h0: String = SimHash.stateHash(S).gameplay\n"
 "\tfor i in range(SimHitstop.windowS * 60 - 1):\n"
 "\t\tSimHitstop.live(S)\n"
 "\tif SimHitstop.ticks(S, \"heavy\") != 6:\n",
 "\t# the deep step (Game Design's 7d): over 40% of the window, x0.5, rounded, at least 2\n"
 "\tif SimHitstop.deepTicks != 240:\n"
 "\t\treturn \"the deep line is %d ticks (want 40%% of 10 s, 240)\" % SimHitstop.deepTicks\n"
 "\tfor i in range(SimHitstop.deepTicks - SimHitstop.budgetTicks - 1):\n"
 "\t\tSimHitstop.frozen(S)\n"
 "\tif SimHitstop.ticks(S, \"heavy\") != 6:\n"
 "\t\treturn \"a tick under the deep line, a heavy holds %d (want 6: x0.75)\" % SimHitstop.ticks(S, \"heavy\")\n"
 "\tSimHitstop.frozen(S)\n"
 "\tvar deep: Dictionary = {\"light_flow\": 0, \"light_mash\": 2, \"light\": 2, \"medium\": 3, \"heavy\": 4, \"launch\": 6, \"launch_full\": 7, \"decisive\": 20, \"ko\": 24}\n"
 "\tfor w in deep:\n"
 "\t\tif SimHitstop.ticks(S, w) != deep[w]:\n"
 "\t\t\treturn \"over the deep line, %s holds %d (want %d: x0.5, rounded, at least 2; decisive and the KO never cut)\" % [w, SimHitstop.ticks(S, w), deep[w]]\n"
 "\tvar h0: String = SimHash.stateHash(S).gameplay\n"
 "\tfor i in range(SimHitstop.windowS * 60 - 1):\n"
 "\t\tSimHitstop.live(S)\n"
 "\tif SimHitstop.ticks(S, \"heavy\") != 4:\n"),
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
print("a mash flows: light_flow, no stop; the deep step, x0.5 over 40%")
