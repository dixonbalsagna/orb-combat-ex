#!/usr/bin/env python3
"""Scratch (Performance and Platform, 2026-11-06): statement-level timers inside the launch tick's functions, for docs/perf/tools/preplay/replay_prof.gd on a scratch copy (never the repo).
   python hook-launchtimers.py <scratch tree>      (apply hook-simtimers.py FIRST: it defines SimCore.stg and SimCore._tm and renames chooseLaunch/swing functions to _x0)
 Wraps every plain call statement (a bare call, `var x = f(...)`, `x = f(...)`, `x += f(...)`) of these functions in a pair of clock reads and adds the time to SimCore.stg under "<file>.<function>:<call>":
   launch.gd  _chooseLaunch0, _biomeCands, _insideAim, bruntScore, _landTerms     (L.)
   swing.gd   _atLaunch0, _launchPick0, _candidates0, _scored0, _direction0, _standing0, _builtPlaces0, _offer0     (S.)
   brunt.gd   aim, candidates     visit.gd   offer, cost     (B., V.)
 A call inside a loop adds up over the loop; the count of calls is in SimCore.stg too ("<same key>#n"). Clock reads only: nothing the sim hashes changes.
"""
import re, sys, os
root = sys.argv[1]
SPEC = [
    ('sim/director/launch.gd', 'L.', ['_chooseLaunch0', '_biomeCands', '_biomeCandsRead', '_propTargets', '_propFlight', '_cliffRead', '_skimAshoreRead', '_insideAim', 'bruntScore', '_landTerms']),
    ('sim/director/swing.gd', 'S.', ['_atLaunch0', '__launchPick0', '_candidates0', '_scored0', '__direction0', '__standing0', '__builtPlaces0', '__offer0', '_places0']),
    ('sim/world/brunt.gd', 'B.', ['aim', 'candidates']),
    ('sim/director/visit.gd', 'V.', ['offer', 'cost']),
    ('sim/world/contact.gd', 'C.', ['lookAt']),
]
CALL = re.compile(r'^(?:var [A-Za-z_0-9]+(?:: [A-Za-z0-9_\[\]]+)? = |[A-Za-z_0-9.\[\]]+ (?:\+|-)?= )?((?:[A-Za-z_]\w*\.)*[A-Za-z_]\w*)\(.*\)\s*(#.*)?$')
SKIP = re.compile(r'^(if |elif |else|for |while |return|match |pass|continue|break|assert)')
tot = 0
for rel, pre, fns in SPEC:
    path = os.path.join(root, rel)
    L = open(path, encoding='utf8').read().split('\n')
    for fn in fns:
        i0 = next((i for i, l in enumerate(L) if re.match(r'^static func %s\(' % re.escape(fn), l)), None)
        if i0 is None:
            print('skip', rel, fn)
            continue
        # the signature may continue on the next lines; the body starts after the line ending with ':'
        j = i0
        while not L[j].rstrip().endswith(':'):
            j += 1
        i1 = next((i for i in range(j + 1, len(L)) if L[i].startswith('static func ') or L[i].startswith('func ') or L[i].startswith('## ')), len(L))
        out = L[:j + 1] + ['\tvar _q: int = 0']
        n = 0
        for l in L[j + 1:i1]:
            st = l.lstrip('\t')
            ind = l[:len(l) - len(st)]
            m = CALL.match(st)
            if m and not SKIP.match(st) and st.count('(') == st.count(')') and not st.rstrip().endswith(('[', '{', '(')) and 'lambda' not in st and 'func(' not in st:
                key = '%s%s:%s' % (pre, fn.strip('_').rstrip('0') if fn.endswith('0') else fn, m.group(1))
                out += [ind + '_q = Time.get_ticks_usec()', l, ind + 'SimCore._tm("%s", _q)' % key, ind + 'SimCore.stg["%s#n"] = int(SimCore.stg.get("%s#n", 0)) + 1' % (key, key)]
                n += 1
            else:
                out.append(l)
        L = out + L[i1:]
        tot += n
    open(path, 'w', encoding='utf8').write('\n'.join(L))
print('launch timers applied:', tot, 'statements')
