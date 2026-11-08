#!/usr/bin/env python3
"""Scratch (Performance and Platform, 2026-11-07): the second layer of sim timers for the late-match slow ticks of a two-fights match (docs/perf/late-ticks-2026-11-07.md).
   python hook-latetimers.py <scratch tree>      (apply AFTER hook-simtimers.py, and after making SimCore.step reset `stg` once per tick instead of once per fight tick)
 Wraps each plain `DirX.y(...)` / `SimX.y(...)` / `WorldX.y(...)` call statement inside SimControl.control, SimFighter.stepFighter, DirBeam.beamStep, WorldWater.step and WorldFill.stepWindow with SimCore._tm("<call>", ...),
 times WorldWater.step's flow loop as "water.flowloop" and records the water windows ("#win" count, "#span" columns) in SimCore.stg. Timers read the clock and write a dictionary; nothing the sim hashes changes.
"""
import re, sys, os

root = sys.argv[1]


def rd(p):
    return open(os.path.join(root, p), encoding='utf8').read()


def wr(p, s):
    open(os.path.join(root, p), 'w', encoding='utf8').write(s)


PAT = re.compile(r'^(Dir|Sim|World)\w+\.\w+\(.*\)\s*(#.*)?$')


def wrap_calls(path, fn_start, qname):
    L = rd(path).split('\n')
    i0 = next(i for i, l in enumerate(L) if l.startswith(fn_start))
    i1 = next((i for i in range(i0 + 1, len(L)) if L[i].startswith('static func ') or L[i].startswith('func ')), len(L))
    out = L[:i0 + 1]
    out.append('\tvar %s: int = 0' % qname)
    n = 0
    for l in L[i0 + 1:i1]:
        st = l.lstrip('\t')
        ind = l[:len(l) - len(st)]
        # a call statement at the function's own level or inside a plain if/elif/else block, never a line that continues an expression
        if PAT.match(st) and st.count('(') == st.count(')') and len(ind) <= 2:
            name = re.match(r'^(\w+\.\w+)', st).group(1)
            out += [ind + '%s = Time.get_ticks_usec()' % qname, l, ind + 'SimCore._tm("%s", %s)' % (name, qname)]
            n += 1
        else:
            out.append(l)
    out += L[i1:]
    wr(path, '\n'.join(out))
    return n


n = {}
n['control'] = wrap_calls('sim/input/control.gd', 'static func control(', '_c')
n['stepFighter'] = wrap_calls('sim/core/fighter.gd', 'static func stepFighter(', '_f')
n['beamStep'] = wrap_calls('sim/director/beam.gd', 'static func beamStep(', '_g')
n['waterStep'] = wrap_calls('sim/world/water.gd', 'static func step(', '_w')
# the water step's flow loop and the windows it holds
s = rd('sim/world/water.gd')
a = '\tvar wc: int = maxi(warmCols(), 1)\n'
assert s.count(a) == 1, 'water step anchor'
s = s.replace(a, '\tvar _wl: int = Time.get_ticks_usec()\n\tvar _sp: int = 0\n\tfor _ww in S.waterWin:\n\t\t_sp += int(_ww[1]) * 2 + 1\n\tSimCore.stg["#win"] = S.waterWin.size()\n\tSimCore.stg["#span"] = _sp\n' + a)
open(os.path.join(root, 'sim/world/water.gd'), 'w', encoding='utf8').write(s)
L = s.split('\n')
i0 = next(i for i, l in enumerate(L) if l.startswith('static func step('))
i1 = next(i for i in range(i0 + 1, len(L)) if L[i].startswith('static func ') or L[i].startswith('func '))
j = i1 - 1
while L[j].strip() == '' or L[j].lstrip().startswith('##'):
    j -= 1
L.insert(j + 1, '\tSimCore._tm("water.flowloop", _wl)')
wr('sim/world/water.gd', '\n'.join(L))
n['stepWindow'] = wrap_calls('sim/world/fill.gd', 'static func stepWindow(', '_s') if os.path.exists(os.path.join(root, 'sim/world/fill.gd')) else 'no fill.gd'
print('late timers applied:', n)
