# PARKED BUILD (Simulation): the run's stage ground (docs/architecture/run-core.md section 11). Each stage's ring is
# picked by World's ring picker (WorldRingPick, on main) from Narrative's claims (data/narrative/opponent_grounds.json),
# in steps the host spends during the previous stage's beats. Behind data/fight/run.json's ground.enabled (off).
# Nothing in a match's tick reads it and nothing is hashed: the golden does not move.
#   adds sim/core/run.gd (SimRun: H, the stage seeds, the stand-in homes, beginGround and GroundJob) and its .uid,
#        sim/core/tools/run_ground.gd (a sample run's grounds) and its .uid, data/fight/run.json (the switch, off);
#   edits sim/core/tools/parity.gd: a check, "the run's ground".
# Tools' schema lines (fight-run.schema.json, its map rule, its cases, the virtual copy) are grant_tools.py beside
# this, in the same commit. Usage: python run_ground.py <repo root>
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
FILES = ['sim/core/run.gd', 'sim/core/run.gd.uid', 'sim/core/tools/run_ground.gd', 'sim/core/tools/run_ground.gd.uid', 'data/fight/run.json']
for f in FILES:
    assert not os.path.exists(f), f + ' is already there'
for f in FILES:
    shutil.copyfile(os.path.join(HERE, 'files', f + '.txt'), f)

def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

edit('sim/core/tools/parity.gd', [
("\tcheck(\"the ricochet's glance\", _ricochet())\n",
 "\tcheck(\"the ricochet's glance\", _ricochet())\n"
 "\tcheck(\"the run's ground\", _runGround())\n"),
("func _flatX(S: SimState, from: float) -> float:\n",
 "## The run's stage ground (run-core.md section 11): the run's keyed hash pinned; the first stage Close round the\n"
 "## player's home; a stage between picked from its opponent's claim, the same stepped a candidate a frame as at once,\n"
 "## and its setup (read back from JSON, as a header is) building the match on that ring; the boss on the Whole circle\n"
 "## through his home, and on his claim when no other place stands. The data ships off.\n"
 "func _runGround() -> String:\n"
 "\tSimRun.reload()\n"
 "\tif not SimRun.errors().is_empty():\n"
 "\t\treturn \"the run's data: %s\" % str(SimRun.errors())\n"
 "\tif SimRun.groundOn():\n"
 "\t\treturn \"the run's ground is on in the data (it ships off)\"\n"
 "\tvar run: String = \"00c0ffee0badf00d\"\n"
 "\tvar pins: Array = [SimRun.planetSeed(run), SimRun.stageSeed(run, 1, 0), SimRun.stageSeed(run, 2, 0)]\n"
 "\tif pins != [2634364773, 2944602543, 4034252320]:\n"
 "\t\treturn \"H: the planet and two stage seeds are %s (want [2634364773, 2944602543, 4034252320]: a port gives the same)\" % str(pins)\n"
 "\tif SimRun.H(run, \"ground\", 2, 0) == SimRun.H(run, \"ground\", 2, 1) or SimRun.H(run, \"ground\", 2, 0) == SimRun.H(run, \"ground\", 3, 0):\n"
 "\t\treturn \"H: the chapter and the offer don't part the streams\"\n"
 "\tvar P: WorldPlanet.Planet = WorldPlanet.make(SimRun.planetSeed(run))\n"
 "\tvar hm: Dictionary = SimRun.homes(P)\n"
 "\tvar g1: SimRun.GroundJob = SimRun.beginGround(run, 1, \"RIVAL\")\n"
 "\tg1.finishNow()\n"
 "\tif g1.rule != \"first\" or int(g1.result.spec.cols) != WorldRingPick.sizeCols(\"close\") or not _ringHolds(g1.result.ev, int(hm.PROTAGONIST)):\n"
 "\t\treturn \"the first stage: rule %s, %d columns, the player's home held %s (want first, Close, held)\" % [g1.rule, int(g1.result.spec.cols), str(_ringHolds(g1.result.ev, int(hm.PROTAGONIST)))]\n"
 "\tvar g2: SimRun.GroundJob = SimRun.beginGround(run, 2, \"EMPRESS\")\n"
 "\tvar frames: int = 1\n"
 "\twhile not g2.frame():\n"
 "\t\tframes += 1\n"
 "\tvar g2b: SimRun.GroundJob = SimRun.beginGround(run, 2, \"EMPRESS\")\n"
 "\tg2b.finishNow()\n"
 "\tvar want: int = int(WorldRingPick.cfg().candidates.half)\n"
 "\tif g2.rule != \"claim\" or g2.size != \"half\" or g2.reads != want or frames != want or JSON.stringify(g2.setup()) != JSON.stringify(g2b.setup()) or not g2.result.ok:\n"
 "\t\treturn \"a stage between: rule %s, size %s, %d reads in %d frames (want claim, half, %d in %d), the same at once %s, ok %s\" % [g2.rule, g2.size, g2.reads, frames, want, want,\n"
 "\t\t\tstr(JSON.stringify(g2.setup()) == JSON.stringify(g2b.setup())), str(g2.result.ok)]\n"
 "\tvar S := SimCore.createSim()\n"
 "\tSimCore.newMatch(S, g2.matchSeed(), {}, JSON.parse_string(JSON.stringify(g2.setup())))\n"
 "\tvar cols: int = S.arenaCols\n"
 "\tSimCore.dispose(S)\n"
 "\tif cols != WorldRingPick.sizeCols(\"half\"):\n"
 "\t\treturn \"a stage's setup built a match of %d columns, not its ring's %d\" % [cols, WorldRingPick.sizeCols(\"half\")]\n"
 "\tvar g4: SimRun.GroundJob = SimRun.beginGround(run, SimRun.stages + 1, \"RIVAL\")\n"
 "\tg4.finishNow()\n"
 "\tif g4.rule != \"boss\" or int(g4.result.spec.cols) != SimConst.PLANET_NC or not _ringHolds(g4.result.ev, int(hm.RIVAL)):\n"
 "\t\treturn \"the boss: rule %s, %d columns, his home held %s (want boss, the Whole circle, held)\" % [g4.rule, int(g4.result.spec.cols), str(_ringHolds(g4.result.ev, int(hm.RIVAL)))]\n"
 "\tvar st := PackedByteArray()\n"
 "\tst.resize(P.n)\n"
 "\tst.fill(0)\n"
 "\tst[int(hm.RIVAL)] = 1\n"
 "\tvar g5: SimRun.GroundJob = SimRun.beginGround(run, SimRun.stages + 1, \"RIVAL\", {\"standing\": st})\n"
 "\tif g5.rule != \"boss_claim\" or g5.size != \"whole\":\n"
 "\t\treturn \"the boss with no other place standing: rule %s, size %s (want his claim at Whole)\" % [g5.rule, g5.size]\n"
 "\treturn \"\"\n"
 "\n"
 "\n"
 "func _ringHolds(ev: Dictionary, id: int) -> bool:\n"
 "\tfor h in ev.held:\n"
 "\t\tif int(h.id) == id:\n"
 "\t\t\treturn true\n"
 "\treturn false\n"
 "\n"
 "\n"
 "func _flatX(S: SimState, from: float) -> float:\n"),
])
print("the run's ground: SimRun, the sample tool, the switch (off), parity's check")
