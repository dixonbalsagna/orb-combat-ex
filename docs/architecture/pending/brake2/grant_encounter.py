# GRANT (Encounter's sim/director/melee.gd, for Simulation's brake2.py beside this). Air sense: before a launch anywhere
# send, the marks of its kind already on the sent fighter go to his brake (SimBrake spends them at the send). Only while
# the brake is on. Usage: python grant_encounter.py <repo root>
import os, sys
os.chdir(sys.argv[1])
p = 'sim/director/melee.gd'
s = open(p, encoding='utf-8').read()
a = "\tDirLaunch.doLaunch(S, att, tgt, r.best, force, longOnly)\n\tDirBrawl.powerCue(S, att, tgt, lkind, (lpow * kf) if lpow >= 0.0 else 1.0)\n"
assert s.count(a) == 1, s.count(a)
s = s.replace(a, "\tif S.brakeOn and tgt.brk != null:   # the air brake's air sense: the marks of this kind already on him (SimBrake spends them)\n\t\ttgt.brk.marks = DirBrawl.freshMarks(S, tgt, lkind)\n" + a)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("air sense reads the send kind's marks")
