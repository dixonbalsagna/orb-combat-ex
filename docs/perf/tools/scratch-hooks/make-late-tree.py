#!/usr/bin/env python3
"""Scratch (Performance and Platform, 2026-11-07): builds the timed tree for docs/perf/tools/preplay/long_2v2.gd from a kept build's tree (or any folder with sim/, data/, net/, project.godot).
   python make-late-tree.py <source tree> <NEW scratch folder>
 Copies sim/data/net/project.godot and long_2v2.gd, applies hook-simtimers.py, makes SimCore.step reset the stage timers once a tick (not once a fight tick, so a two-fights tick adds both fights up), then hook-latetimers.py.
 Then (once): godot --headless --path <folder> --import ; and run long_2v2.gd below normal priority (its header). Refuses a folder that exists. Nothing in the repo is changed.
"""
import os, shutil, subprocess, sys

src, dst = sys.argv[1], sys.argv[2]
here = os.path.dirname(os.path.abspath(__file__))
if os.path.exists(dst):
    sys.exit('refused: %s exists' % dst)
os.makedirs(dst)
for d in ('sim', 'data', 'net'):
    shutil.copytree(os.path.join(src, d), os.path.join(dst, d), ignore=shutil.ignore_patterns('.godot'))
shutil.copy(os.path.join(src, 'project.godot'), dst)
shutil.copy(os.path.join(here, '..', 'preplay', 'long_2v2.gd'), dst)
for root, _, files in os.walk(dst):
    for f in files:
        os.chmod(os.path.join(root, f), 0o666)   # a kept build's files are read-only
subprocess.check_call([sys.executable, os.path.join(here, 'hook-simtimers.py'), dst])
p = os.path.join(dst, 'sim', 'core', 'sim.gd')
s = open(p, encoding='utf8').read()
a = 'static func step(S: SimState, inputs = null) -> bool:\n\tvar live: bool = _step(S, inputs)'
assert a in s, 'step() anchor'
s = s.replace(a, 'static func step(S: SimState, inputs = null) -> bool:\n\tstg = {}\n\tvar live: bool = _step(S, inputs)')
b = '\tvar _a: int = 0\n\tstg = {}\n'
assert s.count(b) == 1, '_fightTick reset anchor'
s = s.replace(b, '\tvar _a: int = 0\n')
open(p, 'w', encoding='utf8').write(s)
subprocess.check_call([sys.executable, os.path.join(here, 'hook-latetimers.py'), dst])
print('timed tree ready:', dst)
