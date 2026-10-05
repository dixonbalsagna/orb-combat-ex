import sys, json
R = sys.argv[1].rstrip('/') + '/'
leave = float(sys.argv[2])
p = R + 'sim/world/structures.gd'
s = open(p, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
s = s.replace('\r\n', '\n')
a = '		damageBuilding(S, b, dmg * (1.0 - SimMathx.jclamp(d / r, 0.0, 1.0) * 0.7), cause, "implode", x, evt, false, kp)\n'
assert s.count(a) == 1
s = s.replace(a, '''		var dd: float = dmg * (1.0 - SimMathx.jclamp(d / r, 0.0, 1.0) * 0.7)
		if not beam and LEAVE_FRAC > 0.0 and b.hp > LEAVE_FRAC * b.maxhp:   # one blast cannot take a standing building below this share of its hit points: it needs a second blast to finish it
			dd = minf(dd, b.hp - LEAVE_FRAC * b.maxhp)
		damageBuilding(S, b, dd, cause, "implode", x, evt, false, kp)
''')
s = s.replace('const BUCKETS: int = 128', 'static var LEAVE_FRAC: float = %s\nconst BUCKETS: int = 128' % leave, 1)
open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', nl))
print('ok')
