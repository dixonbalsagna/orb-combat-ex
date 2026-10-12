"""World's depth reads (docs/design/depth.md): home, depthRoom, crossingNear in lanes.gd; nearestFace in structures.gd.  python mk_reads.py <root>"""
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


LANES = '''## The crossing nearest to (x, z) within r units in plan, or []: [cx, cz, d] with d the plan distance to its middle. A cross street is the
## avenue, a crossing its meeting with a street (intersections()).
static func crossingNear(S: SimState, x: float, z: float, r: float) -> Array:
	var best: Array = []
	var bd: float = r
	for c in intersections(S, x, r):
		var d: float = sqrt(c[4] * c[4] + (c[1] - z) * (c[1] - z))
		if d <= bd:
			bd = d
			best = [c[0], c[1], d]
	return best


## "The middle of the street or the crossing here" (docs/design/depth.md, the ease home): the point a brawl at (x, z) settles toward, as
## [hx, hz, kind]. kind 1: the point is in a street lane and an avenue holds x (within pad): the middle of the crossing, hx the avenue's
## middle. kind 0: in a street lane only: hx = x (the street runs on), hz the lane's middle. kind 2: in no street (a cross street between
## the blocks, or inside a block row at street level, a wreck): hz the middle of the nearest street, hx = x. A pure function of the table
## and the data: no state, no draw.
static func home(S: SimState, x: float, z: float, pad: float = 0.0) -> Array:
	var best_mid: float = z
	var best_d: float = 1.0e30
	var hit_lane: bool = false
	var mid: float = z
	for l in data().get("lanes", []):
		if l.kind != "street":
			continue
		var top: float = float(l.top) * BH
		var bot: float = float(l.bottom) * BH
		var m: float = (top + bot) * 0.5
		if z <= top and z >= bot:
			hit_lane = true
			mid = m
			break
		var d: float = minf(absf(z - top), absf(z - bot))
		if d < best_d:
			best_d = d
			best_mid = m
	if not hit_lane:
		return [x, best_mid, 2]
	var t: PackedFloat32Array = S.lanes
	if t.size() >= 13:
		var nd: int = int(t[3])
		var na: int = int(t[4])
		var oA: int = int(t[12]) + 6 * nd
		for i in range(na):
			var a0: float = t[oA + 3 * i]
			var a1: float = t[oA + 3 * i + 1]
			var cx: float = (a0 + a1) * 0.5
			if absf(SimWrap.sdx(x, cx)) <= (a1 - a0) * 0.5 - pad:
				return [cx, mid, 1]
	return [x, mid, 0]


## The depth interval open around z at x for a body of half depth rz at height y: [z_lo, z_hi] in units. The whole band when x is
## in an avenue (clear air across the blocks) or the body is above every roof in reach; otherwise the street lane that holds z, kept
## rz in from its edges; [z, z] when z is in no street (a wreck: the caller eases out). This is what a drift in depth clamps to: the
## part that runs into a face stops, the rest carries on along the street (the slide).
static func depthRoom(S: SimState, x: float, y: float, z: float, rx: float, rz: float) -> Array:
	var lim: Array = limits()
	var band: Array = [lim[1] + rz, lim[0] - rz]
	if avenueAt(S, x, rx) >= 0:
		return band
	var roof: float = 0.0
	for bi in WorldStructures.near(S, x, rx):
		var b = S.buildings[bi]
		if b.alive and absf(SimWrap.sdx(x, b.x)) < b.w * 0.5 + rx:
			roof = maxf(roof, WorldStructures.baseY(S, b) + WorldStructures.curH(b))
	if y > roof + rz:
		return band
	for l in data().get("lanes", []):
		if l.kind != "street":
			continue
		var top: float = float(l.top) * BH
		var bot: float = float(l.bottom) * BH
		if z <= top and z >= bot:
			return [bot + rz, top - rz]
	return [z, z]


'''

STRUCT = '''## "The nearest face" (docs/design/depth.md): the face of the building nearest to a body at (x, y, z) within reach units in plan, or {}.
## {"b": index, "d": plan distance to the face (0 inside the footprint), "face": "front" (toward the camera), "back" or "end", "nx", "nz": the face's
## outward normal, the way the body is pushed off it}. A body above a building's standing top has no face on that building; a fallen
## building has none. Ties go to the lower index. A pure read.
static func nearestFace(S: SimState, x: float, y: float, z: float, reach: float) -> Dictionary:
	var best: Dictionary = {}
	var bd: float = reach
	for bi in near(S, x, reach):
		var b = S.buildings[bi]
		if not b.alive:
			continue
		var gy: float = baseY(S, b)
		if y > gy + curH(b):
			continue
		var ex: float = SimWrap.sdx(x, b.x)   # the building's centre minus the body's
		var dx: float = maxf(absf(ex) - b.w * 0.5, 0.0)
		var dz: float = maxf(absf(z - b.z) - b.d * 0.5, 0.0)
		var d: float = sqrt(dx * dx + dz * dz)
		if d > bd or (not best.is_empty() and d == bd and bi > int(best.b)):
			continue
		bd = d
		var fz: float = z - b.z   # positive: the body is nearer the camera than the building's middle
		var face: String
		var nx: float = 0.0
		var nz: float = 0.0
		if dx > dz or (dx == dz and dx > 0.0):
			face = "end"
			nx = -1.0 if ex > 0.0 else 1.0
		elif fz >= 0.0:
			face = "front"
			nz = 1.0
		else:
			face = "back"
			nz = -1.0
		best = {"b": bi, "d": d, "face": face, "nx": nx, "nz": nz}
	return best


'''

rw('sim/world/lanes.gd', lambda s: rep(s, '## S.lanes (docs/world/fight-lanes-world.md section 10)', LANES + '## S.lanes (docs/world/fight-lanes-world.md section 10)'))
rw('sim/world/structures.gd', lambda s: rep(s, '## The index of the lowest building whose box the body overlaps right now, or -1.', STRUCT + '## The index of the lowest building whose box the body overlaps right now, or -1.'))
print('reads applied')
