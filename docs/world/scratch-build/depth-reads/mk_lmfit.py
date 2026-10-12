"""A landmark that fits no building in its row is slid into the nearest block that is wide enough (scratch). python mk_lmfit.py <root>"""
import sys
R = sys.argv[1].rstrip('/') + '/'


def rw(p, fn):
    s = open(R + p, encoding='utf-8', newline='').read()
    cr = '\r\n' in s
    s = fn(s.replace('\r\n', '\n'))
    open(R + p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if cr else s)


def rep(s, a, b):
    assert s.count(a) == 1, (a[:80], s.count(a))
    return s.replace(a, b)


def f(s):
    s = rep(s, '''				if best < 0:
					continue
				var b2: Dictionary = out[best]
				b2.landmark = li
''', '''				var shift_x: float = NAN
				if best < 0:
					# no building of the row holds the landmark between the avenues: slide it into the nearest block that is wide enough
					# (a tight grid leaves a landmark of 9 fighter heights no candidate; the ones that fit above are unchanged)
					var lw3: float = float(lm.width_bh) * BH * 0.5
					for i in range(first, out.size()):
						var c: Dictionary = out[i]
						if c.landmark != 0 or c.row != int(lmr.row):
							continue
						var lo: float = da
						var hi: float = db
						for av in avenues:
							if av[1] <= c.x and av[1] > lo:
								lo = av[1]
							if av[0] >= c.x and av[0] < hi:
								hi = av[0]
						if hi - lo < lw3 * 2.0:
							continue
						var nx: float = clampf(c.x, lo + lw3, hi - lw3)
						var dist2: float = absf(nx - target)
						if dist2 < bestd:
							bestd = dist2
							best = i
							shift_x = nx
				if best < 0:
					continue
				var b2: Dictionary = out[best]
				if not is_nan(shift_x):
					b2.x = shift_x
				b2.landmark = li
''')
    return s


rw('sim/world/settlements.gd', f)
print('landmark fit applied')
