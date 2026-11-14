#!/usr/bin/env python3
"""Horde trial T3 (on T1 and T2): the mark, the player's pack blow with each weight's own wind-up and the lunge, the side rule for shots,
and the guards that keep every exchange from starting (the stick's beam and the grab refused, said). Then the switches of the build Orb plays
(docs/tools/runs/6a30b4c9/switch-list.txt, its 87 ON rows), flipped in the tree's data.
python t3_build.py <tree> <repo>"""
import sys, os, subprocess
root = sys.argv[1]
repo = sys.argv[2]
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from t1_build import edit, put  # noqa: E402  (applies T1)
import t2_build  # noqa: E402,F401  (applies T2)

# --- the core
edit('sim/core/roster.gd', [
    ('static func opp(S: SimState, f) -> SimState.Fighter:\n',
     'static func opp(S: SimState, f) -> SimState.Fighter:\n'
     '\tif S.hordeOn and S.horde != null:\n'
     '\t\treturn S.fighters[S.horde.mark[S.fighters.find(f)]]   # the horde: the body\'s mark (sim/core/horde.gd)\n'),
])
edit('sim/core/shots.gd', [
    ('\t\t\t\tif sh.owner < 0 and not sh.wild and SimCross.teamOf(sh.from) == SimCross.team(S.fighters[k]):\n',
     '\t\t\t\tif S.hordeOn and sh.owner >= 0 and k != sh.owner and SimHorde.side(S, k) == SimHorde.side(S, sh.owner):\n'
     '\t\t\t\t\tcontinue   # the horde: a shot passes a body of its shooter\'s side, wild or not (a deflected shot flies as its deflector\'s); its owner as one-on-one\n'
     '\t\t\t\tif sh.owner < 0 and not sh.wild and SimCross.teamOf(sh.from) == SimCross.team(S.fighters[k]):\n'),
    ('\t\tfor f in S.fighters:\n\t\t\tif f.state == "intro" or f.out:\n\t\t\t\tcontinue\n\t\t\tvar dx: float = SimWrap.sdx(sh.x, f.x)\n',
     '\t\tfor f in S.fighters:\n\t\t\tif f.state == "intro" or f.out:\n\t\t\t\tcontinue\n'
     '\t\t\tif S.hordeOn and f != S.fighters[sh.owner] and SimHorde.side(S, S.fighters.find(f)) == SimHorde.side(S, sh.owner):\n'
     '\t\t\t\tcontinue   # the horde: a mine\'s blast passes its layer\'s partner\n'
     '\t\t\tvar dx: float = SimWrap.sdx(sh.x, f.x)\n'),
    ('\t\t\t\t\tif k == sh.owner or S.fighters[k].state == "intro" or S.fighters[k].out:\n',
     '\t\t\t\t\tif k == sh.owner or S.fighters[k].state == "intro" or S.fighters[k].out or (S.hordeOn and sh.owner >= 0 and SimHorde.side(S, k) == SimHorde.side(S, sh.owner)):\n'),
])
edit('sim/core/clock.gd', [
    ('static func hold(S: SimState, secs: float, _a = null, _b = null) -> void:\n',
     'static func hold(S: SimState, secs: float, _a = null, _b = null) -> void:\n'
     '\tif S.hordeOn and not SimHorde.wholeFight:\n'
     '\t\treturn   # the horde: nothing holds the whole fight; a struck pack body\'s hold is its own reel (sim/director/horde.gd)\n'),
])
edit('sim/core/damage.gd', [
    ('static func ko(S: SimState, D, A) -> void:\n\tif S.game.ko != null:\n',
     'static func ko(S: SimState, D, A) -> void:\n\tif S.game.ko != null or S.hordeOn:   # (the horde: a pack body\'s fall and a seat going down are the run\'s own)\n'),
])

# --- the director's guarded lines
edit('sim/director/exchange.gd', [
    ('\tif DirDriver.takes(S, A, kind):\n\t\treturn   # RB + B: the Driver gathers\n',
     '\tif DirDriver.takes(S, A, kind):\n\t\treturn   # RB + B: the Driver gathers\n'
     '\tif DirHorde.takes(S, A, kind):\n\t\treturn   # the horde: a press is a pack blow, never a request (sim/director/horde.gd)\n'),
    ('\t\tif up > 0 and DirBrawl.takes(S, f, "heavy" if up == 1 else "sig"):\n',
     '\t\tif up > 0 and (DirHorde.takes(S, f, "heavy" if up == 1 else "sig") or DirBrawl.takes(S, f, "heavy" if up == 1 else "sig")):   # (the horde is asked first, as the brawl is)\n'),
])
edit('sim/director/stick.gd', [
    ('\tif (mask & RB) != 0:\n\t\tif dir == TOWARD and DirBeamPlay.stickAnswer(S, f):\n',
     '\tif (mask & RB) != 0:\n'
     '\t\tif DirHorde.on(S):\n'
     '\t\t\tDirExchange.refused(S, f, "horde_sig")\n'
     '\t\t\tSimFx.cue(S, f, "stick_refused", NAMES[dir], "horde_sig")   # the horde: the stick\'s beam is refused in the trial, said\n'
     '\t\t\treturn\n'
     '\t\tif dir == TOWARD and DirBeamPlay.stickAnswer(S, f):\n'),
    ('\tasking = false\n\tif askRefused:\n',
     '\tasking = false\n'
     '\tif DirHorde.on(S):\n'
     '\t\t_s(f, ST_PEND, 0)   # the horde took the press as a pack blow: nothing is pending, so no late refusal is said\n'
     '\tif askRefused:\n'),
])
edit('sim/director/grapple.gd', [
    ('static func press(S: SimState, f) -> bool:\n',
     'static func press(S: SimState, f) -> bool:\n'
     '\tif on() and DirHorde.on(S):\n'
     '\t\tDirExchange.refused(S, f, "horde_grab")   # the horde: the grab is not in the first version, said\n'
     '\t\treturn true\n'),
])
edit('sim/director/bands.gd', [
    ('static func _bandTick(S: SimState) -> void:\n',
     'static func _bandTick(S: SimState) -> void:\n'
     '\tif S.hordeOn:   # the horde: each body\'s band is to its own mark\n'
     '\t\tfor f in S.fighters:\n'
     '\t\t\tif not f.out:\n'
     '\t\t\t\tDirInterrupt.si(f, DirInterrupt.BAND, _bandAt(dist(f, DirBrawl.rivalOf(S, f)), DirInterrupt.gi(f, DirInterrupt.BAND) - 1) + 1)\n'
     '\t\treturn\n'),
])
put('sim/director/horde.gd', open(os.path.join(HERE, 'horde_dir.gd'), encoding='utf8').read())
put('sim/director/tools/horde_check.gd', open(os.path.join(HERE, 'horde_check.gd'), encoding='utf8').read())
print('T3 applied to', root)

# --- the switches of the build Orb plays
OLD = os.environ.get('PAGEFLIP', 'pageflip.mjs')   # (a scratch tool: applies a switch list's rows to a tree through tools/preview/switches.mjs)
out = subprocess.run(['node', OLD, repo, root, os.path.join(HERE, 'page_hz.json')], capture_output=True, text=True)
print(out.stdout.strip().splitlines()[-1] if out.stdout.strip() else out.stderr[-400:])
