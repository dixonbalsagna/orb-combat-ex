"""A demo start at a crossing (scratch): WorldLanes.demoStartX, the data key demo_start in lanes.json, and the two granted lines in sim.gd.
python mk_demostart.py <root>"""
import sys, json
R = sys.argv[1].rstrip('/') + '/'


def rw(p, fn):
    s = open(R + p, encoding='utf-8', newline='').read()
    cr = '\r\n' in s
    s = fn(s.replace('\r\n', '\n'))
    open(R + p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if cr else s)


def rep(s, a, b):
    assert s.count(a) == 1, (a[:80], s.count(a))
    return s.replace(a, b)


FN = '''## Where a demo start puts the first fighter so the pair stands astride a crossing (a setup's "start": "crossing"): the crossing of the
## street named by data/biomes/lanes.json demo_start.lane nearest the middle of the first district with demo_start.look, less half the gap
## between the fighters. START_X (the caller's default) when the data names nothing, the look is not in the world or no avenue crosses.
static func demoStartX(S: SimState, gap: float, default_x: float) -> float:
	var ds: Dictionary = data().get("demo_start", {})
	if ds.is_empty() or S.lanes.size() < 13:
		return default_x
	var looks: Array = WorldSettle.data().get("looks", [])
	var li: int = looks.find(str(ds.get("look", "")))
	if li < 0:
		return default_x
	var t: PackedFloat32Array = S.lanes
	var nd: int = int(t[3])
	var oD: int = int(t[12])
	var mx: float = -1.0
	for i in range(nd):
		if int(t[oD + 6 * i + 2]) == li:
			mx = (t[oD + 6 * i] + t[oD + 6 * i + 1]) * 0.5
			break
	if mx < 0.0:
		return default_x
	var zl: float = 0.0
	for l in data().get("lanes", []):
		if l.name == str(ds.get("lane", "front_street")):
			zl = (float(l.top) + float(l.bottom)) * 0.5 * BH
	var c: Array = crossingNear(S, mx, zl, 12.0 * BH * 4.0)
	if c.is_empty():
		return default_x
	return SimWrap.wrap(float(c[0]) - gap * 0.5)


'''

rw('sim/world/lanes.gd', lambda s: rep(s, '## S.lanes (docs/world/fight-lanes-world.md section 10)', FN + '## S.lanes (docs/world/fight-lanes-world.md section 10)'))


def sim(s):
    s = rep(s, '	var x0: float = SimConst.START_X\n	var x1: float = SimConst.START_X + SimConst.START_GAP\n',
            '	var start_x: float = SimConst.START_X\n	if setup.get("start", "") == "crossing":   # a demo start astride a crossing of the city (World: lanes.json demo_start); default off\n		start_x = WorldLanes.demoStartX(S, SimConst.START_GAP, SimConst.START_X)\n	var x0: float = start_x\n	var x1: float = start_x + SimConst.START_GAP\n')
    return s


rw('sim/core/sim.gd', sim)


def lanes_json(R):
    p = R + 'data/biomes/lanes.json'
    t = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'
    d = json.loads(t)
    d['demo_start'] = {"look": "downtown", "lane": "front_street"}
    open(p, 'w', encoding='utf-8', newline='').write((json.dumps(d, indent=2, ensure_ascii=False) + '\n').replace('\n', nl))


lanes_json(R)
print('demo start applied')
