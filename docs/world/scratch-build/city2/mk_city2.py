"""The city, shorter and broader (Orb, 2026-10-11): downtown 20 to 40 fighter heights, wider and deeper footprints, an aspect rule, three landmarks that stand
clear, and the people thinned on the front block (the fight's sidewalk) by data.  python mk_city2.py <root> [variant]
variant: 'full' (default) or 'nopop' (no row_pop) or 'norule' (no aspect rule)"""
import sys, json
R = sys.argv[1].rstrip('/') + '/'
VAR = sys.argv[2] if len(sys.argv) > 2 else 'full'


def rw(p, fn):
    s = open(R + p, encoding='utf-8', newline='').read()
    cr = '\r\n' in s
    s = fn(s.replace('\r\n', '\n'))
    open(R + p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if cr else s)


def rep(s, a, b):
    assert s.count(a) == 1, (a[:100], s.count(a))
    return s.replace(a, b)


def settle(s):
    # the aspect rule: a footprint's height is at most aspect_max times its narrower side (a kind may carry its own)
    s = rep(s, '''				var zc: float = (float(ln.top) - dd_bh * 0.5) if ln.kind == "block" else 0.5 * (float(ln.top) + float(ln.bottom))
''', '''				var amax: float = float(kd.get("aspect_max", data().get("aspect_max", 0.0)))
				if amax > 0.0:
					h = minf(h, amax * minf(w, dd_bh * BH))   # the aspect rule: no tower is thinner than a believable ratio of its height
				var zc: float = (float(ln.top) - dd_bh * 0.5) if ln.kind == "block" else 0.5 * (float(ln.top) + float(ln.bottom))
''')
    # the people by row (the fight's sidewalk is the front block's street side): a district's row_pop factors, default 1
    s = rep(s, '"hp_mult": 1.0, "pop_mult": 1.0, "dens": float(dd.pop_density)})', '"hp_mult": 1.0, "pop_mult": 1.0, "dens": float(dd.pop_density) * float(dd.get("row_pop", [1.0, 1.0, 1.0, 1.0])[int(row)])})')
    s = rep(s, '''			if not _num(dd.get("pop_density", null)) or dd.pop_density < 0.0:
				_err(dn + "/pop_density: a number >= 0")
''', '''			if not _num(dd.get("pop_density", null)) or dd.pop_density < 0.0:
				_err(dn + "/pop_density: a number >= 0")
			var rpop = dd.get("row_pop", null)
			if rpop != null and (not (rpop is Array) or rpop.size() != 4):
				_err(dn + "/row_pop: four factors, one per row")
''')
    return s


rw('sim/world/settlements.gd', settle)

p = R + 'data/biomes/settlements.json'
t = open(p, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in t else '\n'
d = json.loads(t)
if VAR != 'norule':
    d['aspect_max'] = 5.0
for lm in d['landmarks']:
    if lm['key'] == 'bell_tower':
        lm.update(height_bh=65, width_bh=10)
    if lm['key'] == 'chimney_stack':
        lm.update(height_bh=36, width_bh=4)
d['landmarks'].append({"key": "crown_tower", "width_bh": 12, "shape": "crown", "height_bh": 52, "hp_mult": 1.6, "pop_mult": 1.2})
d['landmarks'].append({"key": "ledger_hall", "width_bh": 13, "shape": "stepped", "height_bh": 46, "hp_mult": 1.6, "pop_mult": 1.2})
for s_ in d['settlements']:
    for x in s_['districts']:
        if x['name'] == 'downtown':
            x['height_bh'] = {"median": 28, "spread": 0.22, "min": 18, "max": 40, "centre_bump": 0.3}
            x['width_bh'] = [7, 14]
            x['depth_fill'] = [0.85, 1.0]
            x['gap_bh'] = [0.4, 1.4]
            x['landmarks'] = [{"key": "bell_tower", "count": 1, "place": "centre", "row": 1},
                              {"key": "ledger_hall", "count": 1, "place": "start", "row": 1},
                              {"key": "crown_tower", "count": 1, "place": "end", "row": 2}]
        if x['look'] == 'mid_rise':
            x['height_bh'] = {"median": 12, "spread": 0.3, "min": 7, "max": 20, "centre_bump": 0.2}
            x['width_bh'] = [6, 12]
            x['depth_fill'] = [0.75, 1.0]
            x['gap_bh'] = [0.6, 1.6]
        if x['look'] == 'industrial':
            for k in x['kinds']:
                if k['shape'] == 'chimney':
                    k['aspect_max'] = 10
        if VAR != 'nopop':
            x['row_pop'] = [1.0, 0.25, 1.0, 1.0]
out = json.dumps(d, indent=2, ensure_ascii=False) + '\n'
open(p, 'w', encoding='utf-8', newline='').write(out.replace('\n', nl))
print('city2 applied', VAR)
