#!/usr/bin/env python3
"""Scratch (Performance and Platform, 2026-11-01): millisecond timers in the sim, for docs/perf/tools/preplay/replay_prof.gd on a scratch copy of a tree (never the repo).
   python hook-simtimers.py <scratch tree>
 Adds `SimCore.stg` (a Dictionary of name -> microseconds for the tick just stepped; reset at the start of each fight tick) and timers around:
   sim/core/sim.gd        _fightTick: SimSwing.tick, WorldEpoch.tick, SimControl.control, SimFighter.stepFighter, DirExchange.dirUpdate, DirBeam.beamStep, SimShots.step, WorldWater.step, SimMood.tick, WorldCollateral.tick, SimFx.tickMark
   sim/director/exchange.gd  dirUpdate: each plain `DirX.y(...)` / `SimX.y(...)` / `WorldX.y(...)` call statement
   sim/director/launch.gd    chooseLaunch and predictFlight (renamed wrappers; the body is untouched)
   sim/director/swing.gd     _standing, _builtPlaces, places, candidates, scored, _launchPick, _offer, _brawlTick, _fleeTick, _nudgeTick, atBlow, atLaunch, atSend, _direction, _timing (renamed wrappers)
 Timers read the clock and add to a dictionary; they change nothing the sim hashes (a replay on the timed copy must still reproduce the recording's final hash: replay_prof says so).
"""
import re, sys, os

root = sys.argv[1]


def rd(p):
    return open(os.path.join(root, p), encoding='utf8').read()


def wr(p, s):
    open(os.path.join(root, p), 'w', encoding='utf8').write(s)


def wrap_calls(path, fn_start, targets=None, pat=None, qname='_a'):
    L = rd(path).split('\n')
    i0 = next(i for i, l in enumerate(L) if l.startswith(fn_start))
    i1 = next((i for i in range(i0 + 1, len(L)) if L[i].startswith('static func ') or L[i].startswith('func ')), len(L))
    out = L[:i0 + 1]
    out.append('\tvar %s: int = 0' % qname)
    n = 0
    for l in L[i0 + 1:i1]:
        st = l.lstrip('\t')
        ind = l[:len(l) - len(st)]
        name = None
        if targets:
            for t, nm in targets:
                if st.startswith(t) and not st.startswith('if '):
                    name = nm
                    break
        elif pat is not None and pat.match(st) and not st.startswith('if ') and st.count('(') == st.count(')'):
            name = re.match(r'^(\w+\.\w+)', st).group(1)
        if name:
            out += [ind + '%s = Time.get_ticks_usec()' % qname, l, ind + 'SimCore._tm("%s", %s)' % (name, qname)]
            n += 1
        else:
            out.append(l)
    out += L[i1:]
    wr(path, '\n'.join(out))
    return n


# 1. sim.gd
s = rd('sim/core/sim.gd')
tg = [('SimSwing.tick(S)', 'swing'), ('WorldEpoch.tick(S, DirCalm.hold(S))', 'epoch'), ('SimControl.control(', 'control'), ('SimFighter.stepFighter(S, f, dt)', 'stepFighter'),
      ('DirExchange.dirUpdate(S, dt)', 'dirUpdate'), ('DirBeam.beamStep(S, dt)', 'beamStep'), ('SimShots.step(S, dt)', 'shots'), ('WorldWater.step(S)', 'water'), ('SimMood.tick(S)', 'mood'),
      ('WorldCollateral.tick(S)', 'collateral'), ('SimFx.tickMark(S, dt, false)', 'fx')]
n1 = wrap_calls('sim/core/sim.gd', 'static func _fightTick(', targets=tg)
s = rd('sim/core/sim.gd')
s = s.replace('static func _fightTick(', 'static var stg: Dictionary = {}\n\n\nstatic func _tm(name: String, a: int) -> void:\n\tstg[name] = int(stg.get(name, 0)) + Time.get_ticks_usec() - a\n\n\nstatic func _fightTick(', 1)
s = s.replace('\tvar _a: int = 0\n', '\tvar _a: int = 0\n\tstg = {}\n', 1)
wr('sim/core/sim.gd', s)
# 2. exchange.gd dirUpdate
n2 = wrap_calls('sim/director/exchange.gd', 'static func dirUpdate(', pat=re.compile(r'^(Dir|Sim|World)\w+\.\w+\(.*\)\s*(#.*)?$'), qname='_b')


# 3 and 4. renamed wrappers
def rename_wrap(path, names, prefix, ret_default='Dictionary'):
    s = rd(path)
    n = 0
    for nm in names:
        m = re.search(r'^static func %s\((.*?)\)( -> ([A-Za-z0-9_]+))?:$' % re.escape(nm), s, re.M)
        if not m:
            print('skip', path, nm)
            continue
        args, ret = m.group(1), m.group(3)
        an = [a.split(':')[0].split('=')[0].strip() for a in args.split(',') if a.strip()]
        sig = m.group(0)
        inner = sig.replace('static func %s(' % nm, 'static func _%s0(' % nm, 1)
        call = '_%s0(%s)' % (nm, ', '.join(an))
        if ret == 'void':
            wrap = sig + '\n\tvar _a: int = Time.get_ticks_usec()\n\t' + call + '\n\tSimCore._tm("%s%s", _a)\n\n\n' % (prefix, nm) + inner
        else:
            wrap = sig + '\n\tvar _a: int = Time.get_ticks_usec()\n\tvar _r = ' + call + '\n\tSimCore._tm("%s%s", _a)\n\treturn _r\n\n\n' % (prefix, nm) + inner
        s = s.replace(sig, wrap, 1)
        n += 1
    wr(path, s)
    return n


n3 = rename_wrap('sim/director/launch.gd', ['chooseLaunch', 'predictFlight'], '')
n4 = rename_wrap('sim/director/swing.gd', ['_standing', '_builtPlaces', 'places', 'candidates', 'scored', '_launchPick', '_offer', '_brawlTick', '_fleeTick', '_nudgeTick', 'atBlow', 'atLaunch', 'atSend', '_direction', '_timing'], 'DirSwing.')
print('sim timers applied: fightTick %d, dirUpdate %d, launch %d, swing %d' % (n1, n2, n3, n4))
