# PARKED BUILD (Simulation): the run's first stage stepped like the others. On run-ground as applied, with World's
# first-ring (docs/world/scratch-build/first-ring/: Game Design's rulings-2026-10-23.md 6, a first ring under Close's
# minimum turned toward land with the home kept on it, and the stepped beginFirstRing / FirstJob): SimRun's first
# stage calls beginFirstRing and steps it a read a frame (one read when the story's ring meets the minimum, 13 when it
# is turned), then reads the chosen ring once for its report. The result says `turned`. Behind data/fight/run.json
# (off); nothing in a match's tick reads it, and the golden does not move.
#   edits sim/core/run.gd, sim/core/tools/run_ground.gd (the sample prints a turned ring) and sim/core/tools/parity.gd
#   ("the run's ground": a first ring that meets the minimum is not turned; a coastal home's is, holding the home).
# Usage: python first_host.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

assert os.path.exists('sim/core/run.gd'), 'run-ground first'
assert 'static func beginFirstRing' in open('sim/world/ringpick.gd', encoding='utf-8').read(), "World's first-ring first"
assert 'beginFirstRing' not in open('sim/core/run.gd', encoding='utf-8').read(), 'already in'

edit('sim/core/run.gd', [
("##   the first stage: a Close ring round the player's own home (WorldRingPick.firstRing);\n",
 "##   the first stage: a Close ring round the player's own home, turned toward land when it is under Close's minimum\n"
 "##                with the home kept on it (WorldRingPick.beginFirstRing; Game Design's rulings-2026-10-23.md 6);\n"),
("\t\tif g.home >= 0:\n"
 "\t\t\tg.spec = WorldRingPick.firstRing(g.P, g.home, stream)\n"
 "\t\t\tg.spec[\"kind\"] = \"round\"   # a ring round a place holds it (WorldRingPick.evalRing)\n"
 "\t\t\tg.spec[\"place\"] = g.home\n",
 "\t\tif g.home >= 0:   # stepped like the others: one read, 13 when the ring is turned toward land\n"
 "\t\t\tg.first = WorldRingPick.beginFirstRing(g.P, g.home, stream, {\"standing\": g.standing, \"damaged\": g.damaged})\n"),
("\tif g.spec.is_empty():\n\t\tg.rule = \"boss_claim\" if g.rule == \"boss\" else \"claim\"\n",
 "\tif g.spec.is_empty() and g.first == null:\n\t\tg.rule = \"boss_claim\" if g.rule == \"boss\" else \"claim\"\n"),
("\tvar job: WorldRingPick.PickJob = null      # a claim's pick\n",
 "\tvar job: WorldRingPick.PickJob = null      # a claim's pick\n"
 "\tvar first: WorldRingPick.FirstJob = null   # the first stage's ring\n"),
("\t\tvar ev: Dictionary = WorldRingPick.evalRing(P, spec, standing, damaged)\n\t\treads += 1\n",
 "\t\twhile first != null and not first.done and n > 0:\n"
 "\t\t\tfirst.step(1)\n"
 "\t\t\treads += 1\n"
 "\t\t\tn -= 1\n"
 "\t\tif first != null and spec.is_empty():\n"
 "\t\t\tif not first.done or n <= 0:\n"
 "\t\t\t\treturn done\n"
 "\t\t\tspec = first.spec.duplicate()\n"
 "\t\t\tspec[\"place\"] = home   # on the ring, round or through it (a round ring's centre counts as held)\n"
 "\t\tvar ev: Dictionary = WorldRingPick.evalRing(P, spec, standing, damaged)\n\t\treads += 1\n"),
("\t\t\t\"relaxed\": false, \"kind\": rule, \"place\": home, \"ev\": ev, \"idx\": -1, \"tried\": 1,\n",
 "\t\t\t\"relaxed\": false, \"kind\": rule, \"place\": home, \"ev\": ev, \"idx\": -1, \"tried\": 1, \"turned\": bool(spec.get(\"turned\", false)),\n"),
])

edit('sim/core/tools/run_ground.gd', [
("\t\tvar okText: String = str(r.ok) + (\" (waived: Game Design 2026-10-23 4, his home and a standing city held)\" if r.get(\"waived\", false) else \"\")\n",
 "\t\tvar okText: String = str(r.ok) + (\" (waived: Game Design 2026-10-23 4, his home and a standing city held)\" if r.get(\"waived\", false) else \"\")\n"
 "\t\tif r.get(\"turned\", false):\n"
 "\t\t\tokText += \" (turned toward land, the home kept on it: Game Design 2026-10-23 6, land %d%%)\" % int(round(float(r.ev.land) * 100.0))\n"),
])

edit('sim/core/tools/parity.gd', [
("## The run's stage ground (run-core.md section 11): the run's keyed hash pinned; the first stage Close round the\n"
 "## player's home;",
 "## The run's stage ground (run-core.md section 11): the run's keyed hash pinned; the first stage Close round the\n"
 "## player's home, and turned toward land, holding it, for a coastal home (Game Design's 2026-10-23 6);"),
("\t\treturn \"the first stage: rule %s, %d columns, the player's home held %s (want first, Close, held)\" % [g1.rule, int(g1.result.spec.cols), str(_ringHolds(g1.result.ev, int(hm.PROTAGONIST)))]\n",
 "\t\treturn \"the first stage: rule %s, %d columns, the player's home held %s (want first, Close, held)\" % [g1.rule, int(g1.result.spec.cols), str(_ringHolds(g1.result.ev, int(hm.PROTAGONIST)))]\n"
 "\tif g1.result.get(\"turned\", true):\n"
 "\t\treturn \"the first stage turned a ring that meets Close's minimum\"\n"
 "\tvar coast: String = \"0123456789abcdef\"   # its stand-in home is a coastal city: the ring round it is 70% ocean\n"
 "\tvar gc: SimRun.GroundJob = SimRun.beginGround(coast, 1, \"RIVAL\")\n"
 "\tvar fc: int = 1\n"
 "\twhile not gc.frame():\n"
 "\t\tfc += 1\n"
 "\tvar hc: Dictionary = SimRun.homes(WorldPlanet.make(SimRun.planetSeed(coast)))\n"
 "\tif not gc.result.get(\"turned\", false) or not gc.result.ok or not _ringHolds(gc.result.ev, int(hc.PROTAGONIST)) or gc.reads != fc:\n"
 "\t\treturn \"a coastal home's first ring: turned %s, ok %s, home held %s, %d reads in %d frames (want turned, ok, held, a read a frame)\" % [str(gc.result.get(\"turned\")), str(gc.result.ok),\n"
 "\t\t\tstr(_ringHolds(gc.result.ev, int(hc.PROTAGONIST))), gc.reads, fc]\n"),
])
print("the first stage: World's beginFirstRing, stepped")
