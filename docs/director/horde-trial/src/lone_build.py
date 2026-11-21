#!/usr/bin/env python3
"""Horde trial: one player left up (Game Design, docs/design/horde-trial.md, 2026-11-15). While only one player is up, the pack plays
one-player values at once: the lane gap back to the one-player value (live bodies too, from that tick), new spawns at one-player toughness,
the wave's remaining count x 1/countMul (live bodies keep their toughness); two-player values come back at the next wave.
horde.json two.lone (true) is the switch the check turns off for its negative control. Scratch trial tree only (never lands).
python lone_build.py <the trial tree at 1aadbbd>"""
import sys, os, json
root = sys.argv[1]
HERE = os.path.dirname(os.path.abspath(__file__))


def edit(rel, pairs):
    p = os.path.join(root, rel)
    s = open(p, encoding='utf8', newline='').read()
    crlf = '\r\n' in s
    s = s.replace('\r\n', '\n')
    for a, b in pairs:
        assert s.count(a) == 1, (rel, s.count(a), a[:100])
        s = s.replace(a, b)
    if crlf:
        s = s.replace('\n', '\r\n')
    open(p, 'w', encoding='utf8', newline='').write(s)


edit('sim/core/state.gd', [
    ('\tvar lane := PackedInt32Array()    # for each seat, `places` lanes: the tick the lane is free from; -1 while a wind-up holds it\n',
     '\tvar lane := PackedInt32Array()    # for each seat, `places` lanes: the tick the lane is free from; -1 while a wind-up holds it\n'
     '\tvar size2: int = 0                # 1: this wave\'s count was sized for two (both seats played at its start)\n'
     '\tvar lone: int = 0                 # 1: only one player has been up this wave: the pack plays one-player values until the next wave\n'),
])
edit('sim/core/horde.gd', [
    ('const HASHED_RUN: Array = ["wave", "up", "rest", "t", "over", "sent", "felled"]',
     'const HASHED_RUN: Array = ["wave", "up", "rest", "t", "over", "sent", "felled", "size2", "lone"]'),
])
edit('sim/director/horde.gd', [
    # the tick: one player left up is read once a live tick, after the seats
    ('\t_seats(S)\n\t_run(S)\n',
     '\t_seats(S)\n\t_lone(S)\n\t_run(S)\n'),
    # the wave: its count's size, and two-player values back
    ('\tvar m: float = float(_c().two.countMul) if pads(S) >= 2 else 1.0\n',
     '\tvar m: float = float(_c().two.countMul) if pads(S) >= 2 else 1.0\n'
     '\tR.size2 = 1 if pads(S) >= 2 else 0\n'
     '\tR.lone = 0   # two-player values come back at the next wave (Game Design, 2026-11-15)\n'),
    # spawns: one-player toughness while one player is left up
    ('\tf.hd.worth = float(c.worth) * (float(_c().pack.twoPlayers.toughMul) if pads(S) >= 2 else 1.0)   # with two players the pack is tougher (Game Design, 2026-11-15)\n',
     '\tf.hd.worth = float(c.worth) * (float(_c().pack.twoPlayers.toughMul) if two(S) else 1.0)   # with two players up the pack is tougher (Game Design, 2026-11-15)\n'),
    # the gap: one-player while one player is left up
    ('\treturn int(round(float(g) * float(_c().pack.twoPlayers.gapMul))) if pads(S) >= 2 else g   # with two players the gap is shorter: 90 at medium (Game Design, 2026-11-15)\n',
     '\treturn int(round(float(g) * float(_c().pack.twoPlayers.gapMul))) if two(S) else g   # with two players up the gap is shorter: 90 at medium (Game Design, 2026-11-15)\n'),
    ('static func _left(R) -> int:\n',
     '## Played seats that are up: in the run, not away, not down.\n'
     'static func ups(S: SimState) -> int:\n'
     '\tvar n: int = 0\n'
     '\tfor k in range(SimHorde.seats):\n'
     '\t\tvar P = S.fighters[k]\n'
     '\t\tif P.ai == null and not P.out and P.hd.phase != 7:\n'
     '\t\t\tn += 1\n'
     '\treturn n\n'
     '\n\n'
     '## The pack plays two-player values: both seats played, and not one player left up this wave.\n'
     'static func two(S: SimState) -> bool:\n'
     '\treturn pads(S) >= 2 and S.horde.lone == 0\n'
     '\n\n'
     '## One player left up (Game Design, docs/design/horde-trial.md, 2026-11-15): in a wave sized for two, or with two played, once fewer than two\n'
     '## are up the pack plays one-player values at once and until the next wave. The lane gap goes back to the one-player value from this tick:\n'
     '## a lane waiting out the two-player gap waits the difference too. A wave sized for two loses what a one-player wave would not have left\n'
     '## (its remaining count x 1/countMul, taken from the bodies still to send, the largest kind first). The live bodies keep their toughness.\n'
     'static func _lone(S: SimState) -> void:\n'
     '\tvar R = S.horde\n'
     '\tif R.lone != 0 or R.wave <= 0 or R.rest > 0 or not bool(_c().two.get("lone", true)):\n'
     '\t\treturn\n'
     '\tif ups(S) >= 2 or (R.size2 == 0 and pads(S) < 2):\n'
     '\t\treturn\n'
     '\tvar g0: int = gapTicks(S)\n'
     '\tR.lone = 1\n'
     '\tvar dg: int = gapTicks(S) - g0\n'
     '\tif dg != 0:\n'
     '\t\tfor i in range(R.lane.size()):\n'
     '\t\t\tif R.lane[i] > S.tick:\n'
     '\t\t\t\tR.lane[i] += dg\n'
     '\tvar cut: int = 0\n'
     '\tif R.size2 == 1:\n'
     '\t\tvar want: int = int(floor(float(R.up) / float(_c().two.countMul) + 0.5))\n'
     '\t\tcut = clampi(R.up - want, 0, _left(R))\n'
     '\t\tfor _n in range(cut):\n'
     '\t\t\tvar big: int = 0\n'
     '\t\t\tfor i in range(1, 3):\n'
     '\t\t\t\tif R.mix[i] > R.mix[big]:\n'
     '\t\t\t\t\tbig = i\n'
     '\t\t\tR.mix[big] -= 1\n'
     '\t\tR.up -= cut\n'
     '\tSimFx.cue(S, null, "horde_lone", str(cut), str(R.up))\n'
     '\tif R.up <= 0:\n'
     '\t\t_cleared(S)\n'
     '\n\n'
     'static func _left(R) -> int:\n'),
])
p = os.path.join(root, 'data/fight/horde.json')
d = json.load(open(p, encoding='utf8'))
d['two']['lone'] = True
d['two']['_lone'] = "Game Design's ruling of 2026-11-15 (horde-trial.md, one player left up): while only one player is up, one-player values at once (the gap, new spawns' toughness, the wave's remaining count x 1/countMul); live bodies keep their toughness; two-player values come back at the next wave. false: the check's negative control"
open(p, 'w', encoding='utf8', newline='\n').write(json.dumps(d, indent=2) + '\n')
open(os.path.join(root, 'sim/director/tools/horde_lone_check.gd'), 'w', encoding='utf8', newline='').write(
    open(os.path.join(HERE, 'horde_lone_check.gd'), encoding='utf8').read())
print('one player left up applied to', root)
