# GRANT (Encounter's sim/director/calm.gd and data/director/interrupts.json, for Simulation's calm_k.py beside this):
# the calm turn's slower read on a gen 2 planet (Game Design's rulings-2026-10-26 item 28; docs/architecture/
# calm-turn-read.md), on World's turn.warmTotal (World's gen2-read-speed-b; grant_world.py flips it to 1, shared on a
# gen 2 planet only). A gen 1 planet's pick is as it always was: its k each ring's, its hash the same.
#   - on a gen 2 planet the pick passes K a tick in all (calmTurn.warmColsGen2, 12; one ring 12, two rings 6 each),
#     whatever the lead, so no tick hitches on a slow device: the total with World's warmTotal, else each ring's share;
#   - warmRate: the waiting pick's rate a ring (on gen 2 with warmTotal, the total over the rings);
#   - DirCalm.gen2(S), gen2Cols(), totalK(S);
#   - a pausing form step on gen 2 asks only when a new ring could be warm by its pause's end at K (so in practice it
#     takes the pick its ready tell began);
#   - DirCalm.atReady(S, f): on gen 2, a form step's ready tell (SimFx.transformReady) begins the warm, the earliest
#     moment its choice is known. The pivot is predicted (the pair's midpoint now), so World's smallest bearing is
#     warmed as the fallback, as a landing's; a pick already waiting is kept. Its moment is the step's pause, or a
#     later one (the waiting rule).
# A launch's warm already begins as it is thrown (atSend). Usage: python grant_encounter.py <repo root>
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])


def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)


def text(name):
    return open(os.path.join(HERE, 'files', name), encoding='utf-8').read()


edit('sim/director/calm.gd', [
('static func on(S: SimState) -> bool:\n\treturn bool(cfg().get("enabled", false)) and S.epoch != null\n',
 'static func on(S: SimState) -> bool:\n\treturn bool(cfg().get("enabled", false)) and S.epoch != null\n' + text('enc_gen2.gd.txt')),
('\tif int(ceil(float(cols) / float(lead))) > int(cfg().get("warmColsMax", 32)):\n'
 '\t\treturn   # a new ring can\'t be warm by the pause\'s end: the next moment\n',
 '\tif int(ceil(float(cols) / float(lead))) > (gen2Cols() if gen2(S) else int(cfg().get("warmColsMax", 32))):\n'
 '\t\treturn   # a new ring can\'t be warm by the pause\'s end: the next moment (on gen 2 the ready tell began the warm)\n'),
('## A launch is sent (DirMelee.launchBeat, after doLaunch): the moment after its landing is coming.\n',
 text('enc_ready.gd.txt') + '## A launch is sent (DirMelee.launchBeat, after doLaunch): the moment after its landing is coming.\n'),
(text('enc_k_old.gd.txt'), text('enc_k_new.gd.txt')),
(text('enc_rate_old.gd.txt'), text('enc_rate_new.gd.txt')),
])

p = 'data/director/interrupts.json'
s = open(p, encoding='utf-8').read()
a = '    "warmColsMax": 32,\n'
assert s.count(a) == 1
s = s.replace(a, a + '    "warmColsGen2": 12,\n')
open(p, 'w', encoding='utf-8', newline='\n').write(s)
json.loads(s)
print("Encounter: the calm turn's read a total a tick (K 12 on gen 2), the ready tell's ask, and calmTurn.warmColsGen2")
