"""The destruction hook, scratch experiments.  python mk_dh.py <root> [tierF a,b,c,d]
1. WorldLanes.crossingAlong (the next crossing along an avenue, deeper or nearer, from a point), for Encounter's send down an avenue.
2. the brunt's tier factor from a list (the experiment: escalation by tier as data)."""
import sys
R = sys.argv[1].rstrip('/') + '/'
TF = [float(v) for v in sys.argv[2].split(',')] if len(sys.argv) > 2 else None


def rw(p, fn):
    s = open(R + p, encoding='utf-8', newline='').read()
    cr = '\r\n' in s
    s = fn(s.replace('\r\n', '\n'))
    open(R + p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if cr else s)


def rep(s, a, b):
    assert s.count(a) == 1, (a[:80], s.count(a))
    return s.replace(a, b)


CA = '''## The next crossing along the avenue that holds x (the nearest avenue within reach units of x), from depth z toward the camera (dirz +1)
## or deeper (dirz -1): [cx, cz, hx, hz, dz] with dz the depth distance from z (always above 0.5 unit), or [] when the band ends first or no
## avenue is in reach. A send "down the cross street" (docs/design/depth.md section 5) lands there. A pure read.
static func crossingAlong(S: SimState, x: float, z: float, dirz: float, reach: float = 225.0) -> Array:
	var ix: Array = intersections(S, x, reach)
	if ix.is_empty():
		return []
	var cx: float = ix[0][0]
	var best: Array = []
	var bd: float = 1.0e30
	for c in ix:
		if absf(c[0] - cx) > 1.0:
			continue
		var dz: float = (c[1] - z) * dirz
		if dz > 0.5 and dz < bd:
			bd = dz
			best = [c[0], c[1], c[2], c[3], dz]
	return best


'''
rw('sim/world/lanes.gd', lambda s: rep(s, '## S.lanes (docs/world/fight-lanes-world.md section 10)', CA + '## S.lanes (docs/world/fight-lanes-world.md section 10)'))

if TF:
    arr = '[%s]' % ', '.join(str(v) for v in TF)
    rw('sim/world/brunt.gd', lambda s: rep(s, 'return outcomeDmg(S, b, y, spN * (0.55 + 0.25 * tier) * BRUNT_MUL)', 'return outcomeDmg(S, b, y, spN * %s[clampi(int(tier), 1, 4) - 1] * BRUNT_MUL)' % arr))
print('dh applied', TF)
