#!/usr/bin/env python3
"""Horde trial T4 (on T1 to T3 and Orb's switches): the pack's play (in horde_dir.gd), the arrival ease off for pack bodies, and the probe.
python t4_build.py <tree> <repo>"""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import t3_build  # noqa: E402,F401  (applies T1, T2, T3 and the switches)
from t1_build import put, edit  # noqa: E402

edit('sim/director/bands.gd', [
    ('\tif not arriveOn() or f.state != "free" or f.rush != null or f.input == null or dt <= 0.0:\n\t\treturn\n',
     '\tif not arriveOn() or f.state != "free" or f.rush != null or f.input == null or dt <= 0.0:\n\t\treturn\n'
     '\tif S.hordeOn and f.hd.kind != 0:\n'
     '\t\treturn   # the horde: the pack\'s own play steps it in to its 1.5 bh reach; the dash\'s ease would hold it at engageBh (2.5 bh)\n'),
])
put('sim/director/tools/horde_probe.gd', open(os.path.join(HERE, 'horde_probe.gd'), encoding='utf8').read())
print('T4 applied to', sys.argv[1])
