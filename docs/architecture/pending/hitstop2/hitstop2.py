# PARKED BUILD (Simulation): hit-stop by weight re-cut on Game Design's rulings-2026-10-22.md 5b (the EP's brief of
# 2026-10-22), behind the hit-stop switch (data/fight/hitstop.json, off): with it off nothing moves.
#   the table   a mashed or burst light 2, a tapped light 3, a medium 5, a heavy 8, a launch 12, a full launch 14,
#               decisive 20, the KO 24
#   the budget  18% of a rolling 10 s of fight; over it, every stop under a decisive blow is x0.75 (rounded, at least
#               2) until the share falls back under. Decisive blows and the KO are never cut. (The mashed-light floor,
#               the old one lever, is gone.)
#   whole ticks a stop of n ticks freezes n. The count-down in seconds left a residue of about 1e-17 after n ticks, so
#               every stop of 3 ticks or more froze one tick more than asked (4 held 5; the brawl's heavy 6 held 7).
#               With the switch on the residue is dropped; off, today's count stands (it is in every golden match).
#   edits sim/core/hitstop.gd, data/fight/hitstop.json, sim/core/fx.gd (stopTicks counts whole ticks when asked),
#         sim/core/damage.gd (the damage event's stop, whole with the switch on), tools/parity.gd (the hit-stop check)
# Tools' schema lines (cutMul and cutFloor in place of mashFloor; the virtual copy) are grant_tools.py, same commit.
# Usage: python hitstop2.py <repo root>
import json, os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

p = 'sim/core/hitstop.gd'
assert 'cutMul' not in open(p, encoding='utf-8').read(), 'already in'
edit(p, [
("##   the budget:  the frozen ticks of the last minute of fight (live seconds, in buckets) are counted, whatever froze\n"
 "##                them. Over `share` of the minute, a mashed light's stop is `mashFloor` (2). Stops merge (the longer\n"
 "##                one holds), as today; they never add.\n",
 "##   the budget:  the frozen ticks of the last windowS (10) seconds of fight (live seconds, in buckets) are counted,\n"
 "##                whatever froze them. Over `share` (18%) of it, every stop under a decisive blow is x cutMul (0.75,\n"
 "##                rounded, at least cutFloor 2) until the share falls back under (Game Design's rulings-2026-10-22.md\n"
 "##                5b). Decisive blows and the KO are never cut. Stops merge (the longer one holds); they never add.\n"
 "##   whole ticks: a stop of n ticks freezes n. The step counts a stop down in seconds, and 1/60 taken n times from n/60\n"
 "##                leaves about 1e-17 for n of 3 or more, a tick more than asked; frozen() drops that residue. With the\n"
 "##                switch off, today's count stands.\n"
 "##   a mash flows: light_flow is 0, no stop (Game Design's rulings-2026-10-22.md 6): a mash's later blows, which\n"
 "##                Encounter names. Only the mash's first blow stops (light_mash, 2). A 0 is never raised by the cut's floor,\n"
 "##                and freezes nothing, so the budget never counts it.\n"),
("const WEIGHTS: Array = [\"light_mash\", \"light\", \"medium\", \"heavy\", \"launch\", \"launch_full\", \"decisive\", \"ko\"]\n",
 "const WEIGHTS: Array = [\"light_flow\", \"light_mash\", \"light\", \"medium\", \"heavy\", \"launch\", \"launch_full\", \"decisive\", \"ko\"]\n"
 "const NEVER_CUT: Array = [\"decisive\", \"ko\"]\n"
 "const RESIDUE: float = 1.0e-9   # seconds: far under a tick, far over the count-down's float residue\n"),
("static var mashFloor: int = 2\nstatic var windowS: int = 60\nstatic var budgetTicks: int = 432   # derived: share x windowS seconds of ticks\n",
 "static var cutMul: float = 0.75\nstatic var cutFloor: int = 2\nstatic var windowS: int = 10\nstatic var budgetTicks: int = 108   # derived: share x windowS seconds of ticks\n"),
("\tmashFloor = _int(\"mashFloor\", j.get(\"mashFloor\"), 0, int(ticks_.light_mash))\n",
 "\tvar cm = j.get(\"cutMul\")\n"
 "\tif not (cm is float or cm is int) or float(cm) <= 0.0 or float(cm) > 1.0:\n"
 "\t\t_err(\"cutMul: a share above 0, at most 1\")\n"
 "\t\tcm = 1.0\n"
 "\tcutMul = float(cm)\n"
 "\tcutFloor = _int(\"cutFloor\", j.get(\"cutFloor\"), 0, 120)\n"),
("## The frozen ticks of the last minute of fight are over the budget.\n",
 "## The frozen ticks of the last windowS seconds of fight are over the budget.\n"),
("## The table's ticks for a weight, after the budget (a mashed light at its floor when over). -1 for a weight not in it.\n"
 "static func ticks(S: SimState, weight: String) -> int:\n"
 "\t_ensure()\n"
 "\tif not ticks_.has(weight):\n"
 "\t\treturn -1\n"
 "\tif weight == \"light_mash\" and over(S):\n"
 "\t\treturn mashFloor\n"
 "\treturn int(ticks_[weight])\n",
 "## The table's ticks for a weight, after the budget: over it, a stop under a decisive blow is x cutMul (rounded, at\n"
 "## least cutFloor); a stop of 0 (a mash's flowing blow) stays 0. -1 for a weight not in it.\n"
 "static func ticks(S: SimState, weight: String) -> int:\n"
 "\t_ensure()\n"
 "\tif not ticks_.has(weight):\n"
 "\t\treturn -1\n"
 "\tvar n: int = int(ticks_[weight])\n"
 "\tif n > 0 and over(S) and not NEVER_CUT.has(weight):\n"
 "\t\tn = maxi(cutFloor, int(SimMathx.jround(float(n) * cutMul)))\n"
 "\treturn n\n"),
("## Each frozen tick of a hit-stop (SimCore.step): counted in this second's bucket.\n"
 "static func frozen(S: SimState) -> void:\n"
 "\tvar h = S.hs\n",
 "## Each frozen tick of a hit-stop (SimCore.step, after the count-down): counted in this second's bucket; and the\n"
 "## count-down's float residue dropped, so a stop of n ticks freezes n.\n"
 "static func frozen(S: SimState) -> void:\n"
 "\tif S.dirS.stop < RESIDUE:\n"
 "\t\tS.dirS.stop = 0.0\n"
 "\tvar h = S.hs\n"),
("## Each live tick (SimCore.step): a minute of fight is windowS live seconds; the oldest second's frozen ticks leave it.\n",
 "## Each live tick (SimCore.step): the window is windowS live seconds; the oldest second's frozen ticks leave it.\n"),
])

p = 'data/fight/hitstop.json'
d = json.load(open(p, encoding='utf-8'))
assert 'mashFloor' in d
out = {}
for k, v in d.items():
    if k == 'mashFloor':
        out['cutMul'] = 0.75
        out['cutFloor'] = 2
        out['_cut'] = "Game Design's second step (rulings-2026-10-22.md 5b): over the budget, every stop under a decisive blow is x cutMul, rounded, at least cutFloor, until the share falls back under. Decisive blows and the KO are never cut"
        continue
    out[k] = v
out['ticks'] = {"light_flow": 0, "light_mash": 2, "light": 3, "medium": 5, "heavy": 8, "launch": 12, "launch_full": 14, "decisive": 20, "ko": 24,
                "_note": "a hit's stop in ticks by the weight it names (o.weight), Game Design's table of rulings-2026-10-22.md 5b and 6: a mash's later blows flow (light_flow, 0: no stop; Encounter names them), its first blow stops (light_mash, a mashed or burst light, 2), a tapped light 3, a medium 5, a heavy 8, a launch or a close 12, a full launch 14; decisive (a finisher's last, a duel of perfects' send, a blow that breaks a region: the core's) 20; ko the KO, 24 at most. A stop of n ticks freezes n"}
out['budget'] = {"share": 0.18, "windowS": 10,
                 "_note": "the frozen time of the last windowS live seconds is at most share of it (18% of 10 s: 108 ticks). Over it, the second step (cutMul) applies"}
s = json.dumps(out, indent=2, ensure_ascii=False) + '\n'
open(p, 'w', encoding='utf-8', newline='\n').write(s)

edit('sim/core/fx.gd', [
("static func stopTicks(stop: float) -> int:\n\tvar n: int = 0\n\tvar s: float = stop\n\twhile s > 0.0 and n < 3600:\n",
 "static func stopTicks(stop: float, whole: bool = false) -> int:   # whole: hit-stop by weight's count (no residue's extra tick)\n"
 "\tvar n: int = 0\n\tvar s: float = stop\n\twhile s > (SimHitstop.RESIDUE if whole else 0.0) and n < 3600:\n"),
])
edit('sim/core/damage.gd', [
("\t\tS.out.fx[n0].stop = SimFx.stopTicks(S.dirS.stop)\n",
 "\t\tS.out.fx[n0].stop = SimFx.stopTicks(S.dirS.stop, S.hitstopOn)\n"),
])

p = 'sim/core/tools/parity.gd'
edit(p, [
("\tvar want: Dictionary = {\"light_mash\": 3, \"light\": 4, \"medium\": 7, \"heavy\": 10, \"launch\": 14, \"launch_full\": 16, \"decisive\": 24, \"ko\": 30}\n",
 "\tvar want: Dictionary = {\"light_flow\": 0, \"light_mash\": 2, \"light\": 3, \"medium\": 5, \"heavy\": 8, \"launch\": 12, \"launch_full\": 14, \"decisive\": 20, \"ko\": 24}\n"),
])
s = open(p, encoding='utf-8').read()
i = s.index("\tS.dirS.stop = 0.0\n\tSimDamage.hit(S, null, A, D, 1.0, {\"weight\": \"heavy\"})\n\tSimDamage.hit(S, null, A, D, 1.0, {\"weight\": \"light\"})\n")
j = s.index("\tS.dirS.stop = 0.0\n\tSimHitstop.afterHit(S, D, [0, 2, 0, 0])\n")
s = s[:i] + open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'src', 'budget_check.gd.txt'), encoding='utf-8').read() + s[j:]
s = s.replace("\tif S.dirS.stop != 24.0 * SimConst.DT:\n\t\treturn \"a broken region held %s ticks (want decisive's 24)\" % str(S.dirS.stop / SimConst.DT)\n",
              "\tif S.dirS.stop != 20.0 * SimConst.DT:\n\t\treturn \"a broken region held %s ticks (want decisive's 20)\" % str(S.dirS.stop / SimConst.DT)\n")
s = s.replace("\tif S.game.ko != D or S.dirS.stop != 30.0 * SimConst.DT:\n\t\treturn \"the KO held %s ticks (want the cap's 30), KO %s\"",
              "\tif S.game.ko != D or S.dirS.stop != 24.0 * SimConst.DT:\n\t\treturn \"the KO held %s ticks (want the cap's 24), KO %s\"")
s = s.replace("## Hit-stop by weight (sim/core/hitstop.gd). Off: a hit's stop is the one passed. On: each weight's ticks; a hit that\n## names none keeps the one passed; stops merge; over the budget a mashed light holds the floor, and a minute of fight\n## later the budget is back; the step counts the frozen ticks; a broken region's decisive and the KO's cap (in ko).",
              "## Hit-stop by weight (sim/core/hitstop.gd). Off: a hit's stop is the one passed, and a stop's count-down is today's.\n## On: each weight's ticks; a hit that names none keeps the one passed; stops merge; over the budget every stop under\n## a decisive blow is x0.75 (rounded, at least 2) and decisive blows are not, and 10 s of fight later the budget is\n## back; a stop of n ticks freezes n; a broken region's decisive and the KO's cap (in ko).")
assert "decisive's 20" in s and "the cap's 24" in s and "x0.75" in s
# the curve's replay test needs a paced launch: with the new table its 60 s of seed 11 holds none, so it plays at least
# 60 s, and on until one has been paced (at most 3 minutes)
a = ("\tvar kicks: int = 0\n\tfor t in range(3600):\n\t\trec.step([null, null])\n\t\tfor e in R.out.fx:\n"
     "\t\t\tif e.type == \"flight\" and e.text == \"kick\":\n\t\t\t\tkicks += 1\n")
assert s.count(a) == 1
s = s.replace(a, "\tvar kicks: int = 0\n\tvar tk: int = 0\n\twhile tk < 10800 and (kicks == 0 or tk < 3600):\n\t\ttk += 1\n\t\trec.step([null, null])\n\t\tfor e in R.out.fx:\n"
                 "\t\t\tif e.type == \"flight\" and e.text == \"kick\":\n\t\t\t\tkicks += 1\n")
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("hit-stop by weight: Game Design's table of 2026-10-22, the second step at 18%, whole ticks")
