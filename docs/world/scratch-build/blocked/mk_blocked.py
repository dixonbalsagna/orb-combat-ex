"""WorldStructures.blockedAt for the zip (docs/world/point-clear.md): behaviour-neutral (nothing calls it), no golden change.
python mk_blocked.py <root>   inserts the function into sim/world/structures.gd and copies blockcheck.gd to sim/world/tools/ (run --import after)"""
import sys, os, shutil
R = sys.argv[1].rstrip('/') + '/'
H = os.path.dirname(os.path.abspath(__file__)) + '/'
p = R + 'sim/world/structures.gd'
s = open(p, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
s = s.replace('\r\n', '\n')
a = '## Send building_stage when'
assert s.count(a) == 1 and 'static func blockedAt' not in s
s = s.replace(a, open(H + 'blocked_at.gd.txt', encoding='utf-8').read() + a)
open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', nl))
shutil.copy(H + 'blockcheck.gd', R + 'sim/world/tools/blockcheck.gd')
print('blockedAt applied')
