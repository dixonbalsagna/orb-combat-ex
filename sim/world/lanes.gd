class_name WorldLanes
## The fight lanes (docs/world/fight-lanes-world.md, data/biomes/lanes.json): the lane table the ground shader and the props read
## (build, S.lanes: derived, not hashed), which lane a depth is in, the nearest clear street, and the half extents of a fighter's body
## for the swept test. Pure functions of the data and the buildings; nothing is drawn from S.rng. Depths in the file are fighter
## heights (1 bh = 75 units); the functions work in world units.

const PATH: String = "res://data/biomes/lanes.json"
const BH: float = 75.0
const KIND: Dictionary = {"street": 0.0, "block": 1.0, "scenery": 2.0, "ridge": 3.0}
const STRIP_KIND: Dictionary = {"sidewalk": 0.0, "kerb": 1.0, "carriageway": 2.0}
static var _d: Dictionary = {}
static var _loaded: bool = false


static func data() -> Dictionary:
	if not _loaded:
		_loaded = true
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f != null:
			var j = JSON.parse_string(f.get_as_text())
			if j is Dictionary:
				_d = j
	return _d


## The body's half extents [rx, ry, rz] in units.
static func body() -> Array:
	var b: Dictionary = data().get("body", {})
	return [float(b.get("rx_bh", 0.3)) * BH, float(b.get("ry_bh", 0.5)) * BH, float(b.get("rz_bh", 0.3)) * BH]


## The index of the lane that holds depth z (units), or -1.
static func laneAt(z: float) -> int:
	var lanes: Array = data().get("lanes", [])
	for i in range(lanes.size()):
		var l: Dictionary = lanes[i]
		if z <= float(l.top) * BH and z >= float(l.bottom) * BH:
			return i
	return -1


## The nearest depth to z, at x, inside a street that no footprint overlaps for a body of half depth rz: z clamped into each street,
## the closest unblocked one wins; z itself when there is no street.
static func clearLane(S: SimState, x: float, z: float) -> float:
	var rz: float = body()[2]
	var rx: float = body()[0]
	var best: float = z
	var bestd: float = 1.0e30
	for l in data().get("lanes", []):
		if l.kind != "street":
			continue
		var lo: float = float(l.bottom) * BH + rz + 0.5
		var hi: float = float(l.top) * BH - rz - 0.5
		if hi < lo:
			continue
		var zc: float = clampf(z, lo, hi)
		var blockedHere: bool = false
		for bi in WorldStructures.near(S, x, rx):
			var b = S.buildings[bi]
			if not b.alive:
				continue
			if absf(SimWrap.sdx(x, b.x)) < b.w * 0.5 + rx and zc > b.z - b.d * 0.5 - rz and zc < b.z + b.d * 0.5 + rz:
				blockedHere = true
				break
		if blockedHere:
			continue
		var dd: float = absf(zc - z)
		if dd < bestd:
			bestd = dd
			best = zc
	return best


## The depth limits of the band in units, [z_front, z_back]: z_front is toward the camera. A flight that leaves them is a bug (the band clamp).
static func limits() -> Array:
	return [float(data().get("z_front", 0.0)) * BH, float(data().get("z_back", 0.0)) * BH]


## The street lanes of the table, front to back, as [z_top, z_bottom] in units: the corridors along the planet a brawl may drift through.
static func streets() -> Array:
	var out: Array = []
	for l in data().get("lanes", []):
		if l.kind == "street":
			out.append([float(l.top) * BH, float(l.bottom) * BH])
	return out


## The avenue that holds x with the body's half width to spare (an inset of pad at each side), or -1. A body in an avenue may stand at any depth of
## the band: the avenue is clear air across the blocks, from the front street to the back street.
static func avenueAt(S: SimState, x: float, pad: float = 0.0) -> int:
	var t: PackedFloat32Array = S.lanes
	if t.size() < 13:
		return -1
	var nd: int = int(t[3])
	var na: int = int(t[4])
	var oA: int = int(t[12]) + 6 * nd
	for i in range(na):
		var a0: float = t[oA + 3 * i]
		var a1: float = t[oA + 3 * i + 1]
		if absf(SimWrap.sdx(x, (a0 + a1) * 0.5)) <= (a1 - a0) * 0.5 - pad:
			return i
	return -1


## The intersections within r of x, nearest first, each [cx, cz, hx, hz, d]: the centre of the crossing of an avenue (S.lanes) and a street lane,
## its half extents and its distance from x. Clear air from the ground to the sky by construction: no footprint stands in an avenue (the
## generator skips it) nor in a street lane. Empty when the table has no avenues (an open field, a village without cross streets).
static func intersections(S: SimState, x: float, r: float) -> Array:
	var t: PackedFloat32Array = S.lanes
	var out: Array = []
	if t.size() < 13:
		return out
	var nd: int = int(t[3])
	var na: int = int(t[4])
	var oA: int = int(t[12]) + 6 * nd
	var st: Array = streets()
	for i in range(na):
		var a0: float = t[oA + 3 * i]
		var a1: float = t[oA + 3 * i + 1]
		var cx: float = (a0 + a1) * 0.5
		var hx: float = (a1 - a0) * 0.5
		var d: float = absf(SimWrap.sdx(x, cx))
		if d > r + hx:
			continue
		for sl in st:
			out.append([cx, (sl[0] + sl[1]) * 0.5, hx, (sl[0] - sl[1]) * 0.5, d])
	out.sort_custom(func(p, q): return p[4] < q[4] or (p[4] == q[4] and p[1] > q[1]))
	return out


## The crossing nearest to (x, z) within r units in plan, or []: [cx, cz, d] with d the plan distance to its middle. A cross street is the
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


## Where a demo start puts the first fighter so the pair stands astride a crossing (a setup's "start": "crossing"): the crossing of the
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


## S.lanes (docs/world/fight-lanes-world.md section 10): a flat PackedFloat32Array, world units, z positive toward the camera.
## 0 to 12 header (version, nLanes, nStrips, nDistricts, nAvenues, nRows, rowZ0, rowStep, zFront, zBack, offLanes, offStrips,
## offDistricts); lanes 4 floats each (zTop, zBottom, kind 0 street / 1 block / 2 scenery / 3 ridge, row or -1); strips 4 each (lane,
## zTop, zBottom, kind 0 sidewalk / 1 kerb / 2 carriageway); districts 6 each (x0, x1, look index, lane mask, traffic, settlement);
## then avenues 3 each (x0, x1, district). dlist is the generator's district records over all settlements, west to east.
static func build(S: SimState, dlist: Array) -> PackedFloat32Array:
	var d: Dictionary = data()
	var lanes: Array = d.get("lanes", [])
	var strips: Array = d.get("strips", [])
	var looks: Array = WorldSettle.data().get("looks", [])
	var nav: int = 0
	for dd in dlist:
		nav += dd.avenues.size()
	var out := PackedFloat32Array()
	var offL: int = 13
	var offS: int = offL + 4 * lanes.size()
	var offD: int = offS + 4 * strips.size()
	out.resize(offD + 6 * dlist.size() + 3 * nav)
	out.fill(0.0)
	out[0] = 1.0
	out[1] = float(lanes.size())
	out[2] = float(strips.size())
	out[3] = float(dlist.size())
	out[4] = float(nav)
	out[5] = float(WorldTerrain.ROWS)
	out[6] = WorldTerrain.ROW_Z0
	out[7] = WorldTerrain.ROW_STEP
	out[8] = float(d.get("z_front", 5.0)) * BH
	out[9] = float(d.get("z_back", -27.0)) * BH
	out[10] = float(offL)
	out[11] = float(offS)
	out[12] = float(offD)
	var names := {}
	for i in range(lanes.size()):
		var l: Dictionary = lanes[i]
		names[l.name] = i
		var o: int = offL + 4 * i
		out[o] = float(l.top) * BH
		out[o + 1] = float(l.bottom) * BH
		out[o + 2] = float(KIND.get(l.kind, 2.0))
		out[o + 3] = float(l.row)
	for i in range(strips.size()):
		var st: Dictionary = strips[i]
		var o2: int = offS + 4 * i
		out[o2] = float(names.get(st.lane, -1))
		out[o2 + 1] = float(st.top) * BH
		out[o2 + 2] = float(st.bottom) * BH
		out[o2 + 3] = float(STRIP_KIND.get(st.kind, 0.0))
	var oa: int = offD + 6 * dlist.size()
	for i in range(dlist.size()):
		var dd: Dictionary = dlist[i]
		var mask: int = 0
		var blocks: bool = false
		for li in range(lanes.size()):
			var ln: Dictionary = lanes[li]
			if ln.kind != "street" and int(ln.row) in dd.rows:
				mask |= 1 << li
				blocks = blocks or ln.kind == "block"
		for li in range(lanes.size()):
			if lanes[li].kind == "street" and blocks:
				mask |= 1 << li
		var o3: int = offD + 6 * i
		out[o3] = float(dd.a)
		out[o3 + 1] = float(dd.b)
		out[o3 + 2] = float(looks.find(dd.look))
		out[o3 + 3] = float(mask)
		out[o3 + 4] = float(dd.get("traffic", 0.0))
		out[o3 + 5] = float(dd.get("settlement", 0))
		for av in dd.avenues:
			out[oa] = float(av[0])
			out[oa + 1] = float(av[1])
			out[oa + 2] = float(i)
			oa += 3
	return out
