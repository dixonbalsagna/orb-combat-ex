#!/usr/bin/env python3
"""Horde trial T2 (on T1): falling, the place going away and being inert, `fresh`, the wave table, the end.
A scripted fall (DirHorde.fell) stands in for blows. python t2_build.py <tree>"""
import sys, os
root = sys.argv[1]
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from t1_build import edit, put  # noqa: E402  (t1_build applies T1 when imported with the tree in argv)

put('sim/core/horde.gd', open(os.path.join(HERE, 'horde_core.gd'), encoding='utf8').read())
put('sim/director/horde.gd', open(os.path.join(HERE, 'horde_dir.gd'), encoding='utf8').read())
edit('sim/director/exchange.gd', [
    ('\tDirOutside.tick(S, dt)   # 2v2: a blow from outside lands on an opening, waits or whiffs\n',
     '\tDirOutside.tick(S, dt)   # 2v2: a blow from outside lands on an opening, waits or whiffs\n'
     '\tDirHorde.tick(S, dt)   # the horde: the run, the waves, the refills, the pack (sim/director/horde.gd)\n'),
])
edit('sim/director/ai.gd', [
    ('\ti.mode = 0   # the physical family, unless this tick\'s press is a blast (below)\n',
     '\ti.mode = 0   # the physical family, unless this tick\'s press is a blast (below)\n'
     '\tif DirHorde.aiInput(S, f, i):\n\t\treturn   # the horde: the pack\'s own play, and an empty seat presses nothing\n'),
])
put('sim/director/tools/horde_check.gd', open(os.path.join(HERE, 'horde_check.gd'), encoding='utf8').read())
print('T2 applied to', root)

# the one-on-one rules that must not run in a horde match (moved up from T3: the 11:00 cap's pause stalls the run's own clock)
edit('sim/director/exchange.gd', [
    ('\tif cap > 0.0 and not S.game.timeCap and now >= cap:\n',
     '\tif cap > 0.0 and not S.game.timeCap and now >= cap and not S.hordeOn:   # (the horde: the run has its own backstop, horde.json cap)\n'),
])
edit('sim/director/ending.gd', [
    ('static func tick(S: SimState) -> void:\n\tif not on() or S.game.ko != null:\n',
     'static func tick(S: SimState) -> void:\n\tif not on() or S.game.ko != null or DirHorde.on(S):   # (the horde: the one-on-one ending would open one player\'s brink to the other)\n'),
])
print('T2 one-on-one guards applied')
