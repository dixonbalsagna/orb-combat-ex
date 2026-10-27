# PARKED BUILD (Simulation): a match's start in pieces (docs/architecture/match-start.md; Performance's phone freeze,
# docs/perf/phone-freeze-2026-10-26.md). SimCore.newMatch becomes SimCore.beginMatch and its MatchJob run to the end:
# the same work in the same order, cut at its seams (the head with a planet's world or the first piece of World's, the
# world's pieces, the fighters, the setups a few a piece, the intro, the mood), so the state is the same however it is
# stepped, and the golden does not move. A host steps a piece a frame and draws its loading screen between them.
#   sim/core/sim.gd: newMatch, beginMatch, MatchJob (step, progress), _mHead, _mFighters, _mSetupsA/B/C, _mEnd;
#   sim/core/tools/parity.gd: "the match's start in pieces".
# Needs World's genWorld in pieces (grant_world.py: WorldTerrain.genBegin, genStep, GenJob; genWorld is them run to the
# end). Rendering's host stepping it is grant_rendering.py. Usage: python match_start.py <repo root> (after grant_world.py)
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
assert 'static func genStep' in open('sim/world/terrain.gd', encoding='utf-8').read(), "World's grant first (genWorld in pieces)"


def text(name):
    return open(os.path.join(HERE, 'files', name), encoding='utf-8').read()


p = 'sim/core/sim.gd'
s = open(p, encoding='utf-8').read()
a = 'static func newMatch(S: SimState, seed: int, ai: Dictionary = {}, setup: Dictionary = {}) -> void:\n'
b = '\n\n## The arena\'s columns from the setup'
assert s.count(a) == 1 and s.count(b) == 1 and s.index(a) < s.index(b)
i = s.index(a)
j = s.index(b)
s = s[:i] + text('newmatch_new.gd.txt') + s[j:]
open(p, 'w', encoding='utf-8', newline='\n').write(s)

p = 'sim/core/tools/parity.gd'
s = open(p, encoding='utf-8').read()
for a2, b2 in [("\tcheck(\"the planet's load\", _planetLoad())\n", "\tcheck(\"the planet's load\", _planetLoad())\n\tcheck(\"the match's start in pieces\", _matchStart())\n"),
               ("func _ringHolds(ev: Dictionary, id: int) -> bool:\n", text('parity_match_start.gd.txt') + "\n\nfunc _ringHolds(ev: Dictionary, id: int) -> bool:\n")]:
    assert s.count(a2) == 1, a2[:60]
    s = s.replace(a2, b2)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("the match's start in pieces: SimCore.beginMatch and its MatchJob (newMatch is it run to the end), parity's check")
