class_name WorldWaterRec
extends RefCounted
## Lakes and rivers as planet records on the field (docs/world/gen3-field.md; research.md T6 stage 8, first cut). On gen 2 a lake is a valley of the ring's own line and a river a crossing of it, so both are planned on
## the line and would blink when the line turns. Here each is a record at planet points, read at any point of the sphere:
##   lake   {"k": "lake", "id", "c": [x, y, z], "r": reach in units, "level", "nodes": {node index: true}}. The basin is the set of canonical nodes the lake's flood reaches (connected, ground under the level, from the
##          seed cell); a point has the lake's water where its cell touches the set and the ground there is under the level: depth = level - ground. The level is flat, as the ring's plan has it.
##   river  {"k": "river", "c", "r", "a": [x, y, z], "b": [x, y, z], "flow"}: one segment of the planet's drainage (WorldRivers.Flow), from a cell centre to its receiver. A point within half the river's width of the
##          segment is in the channel: the level is the lower of the two banks (a few columns either side, across the river) less a freeboard, flat across the channel and changing along it, and the bed is the level less
##          the depth with the ring plan's profile (WorldRivers.depthOf; flat in the middle, easing to the bank).
## The records are planned once, at the match's start, in the neighbourhood of its ring (lakes: the ones the ring's plan found, flooded in two dimensions; rivers: the drainage segments within a band of the ring), and
## are constant for the match (S.fieldRecs). Reads are pure functions of the records and the field. Off gen 3 nothing here runs. Lakes beyond the ring's neighbourhood are not planned: water out of a swing's path.

const BOX: float = 1024.0
const BIG: float = 2048.0           # a record reaching further than this is scanned every read (a few), not listed in the grid
const MAX_NODES: int = 8000         # a lake's flood stops here (a basin that large is a sea)
const BAND: float = 9000.0          # rivers are planned within this lateral distance of the ring

static var _ix: Dictionary = {}     # state instance id -> {recs (the array), grid, big}


static func _R() -> float:
	return SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI)


static func _key(ix: int, iy: int, iz: int) -> int:
	return ((ix + 64) * 128 + (iy + 64)) * 128 + (iz + 64)


static func _box(v: float) -> int:
	return int(floor(v / BOX))


## ===================================================================== lakes
## A lake record from a ring lake entry [first column, last column, level, width]: the seed is the lowest of its columns' points; the flood runs on the field's canonical nodes from the seed's cell.
## `claimed` is shared by the lakes of one plan, planned from the lowest level up: nodes a lake holds are not entered by the next.
static func lakeOf(P: WorldPlanet.Planet, F: WorldField.Field, circ: Dictionary, lk: Array, base: PackedFloat32Array, id: int, claimed: Dictionary = {}) -> Dictionary:
	var nc: int = base.size()
	var first: int = int(lk[0])
	var w: int = int(lk[3])
	var level: float = float(lk[2])
	var m: int = first
	var bm: float = 1.0e18
	for k in range(w):
		var c: int = (first + k) % nc
		if base[c] < bm:
			bm = base[c]
			m = c
	var q: Array = WorldPlanet.columnPoint(P, circ, m)
	WorldField._locate(q[0], q[1], q[2], F.N)
	var face: int = WorldField._lf
	var ci: int = clampi(int(WorldField._la), 0, F.N - 1)
	var cj: int = clampi(int(WorldField._lb), 0, F.N - 1)
	var nodes: Dictionary = {}
	var maxr: float = clampf(2.0 * float(w) * SimConst.COL, 800.0, 6000.0)   # the 2D basin is bounded to twice the lake's width on the line: the ring's plan reads a valley on one line, and its level may spill in 2D (a leak is cut here)
	var s2: int = F.side * F.side
	var best: int = -1
	var bh: float = 1.0e18
	for dj in range(2):
		for di in range(2):
			var idx: int = WorldField.ensure(F, face, ci + di, cj + dj)
			nodes[idx] = true   # the seed cell's corners always count, so a lake narrower than a cell still has its cell
			if F.h[idx] < bh:
				bh = F.h[idx]
				best = idx
	if bh < level:
		var stack: Array = [best]
		var seen: Dictionary = {best: true}
		while not stack.is_empty() and seen.size() < MAX_NODES:
			var cur: int = stack.pop_back()
			nodes[cur] = true
			var cf: int = cur / s2
			var rem: int = cur - cf * s2
			var j: int = rem / F.side
			var i: int = rem - j * F.side
			for nb in [[i - 1, j], [i + 1, j], [i, j - 1], [i, j + 1]]:
				var ni: int = _nodeAcross(F, cf, nb[0], nb[1])
				if seen.has(ni):
					continue
				seen[ni] = true
				if claimed.has(ni) or not _within(F, ni, q, maxr):
					continue
				if F.h[ni] < level:
					stack.append(ni)
	for idx in nodes:   # the nodes this lake holds are claimed: a lake planned after it (a higher level) stops at its shore
		claimed[idx] = true
	# the reach: the farthest node from the seed, and a cell for the shore
	var R: float = _R()
	var far2: float = 0.0
	for idx in nodes:
		var f2: int = int(idx) / s2
		var rem2: int = int(idx) - f2 * s2
		var j2: int = rem2 / F.side
		var i2: int = rem2 - j2 * F.side
		var d: Array = WorldField.dirOf(f2, i2, j2, F.N)
		var dx: float = (d[0] - q[0]) * R
		var dy: float = (d[1] - q[1]) * R
		var dz: float = (d[2] - q[2]) * R
		far2 = maxf(far2, dx * dx + dy * dy + dz * dz)
	return {"k": "lake", "id": id, "c": q, "r": sqrt(far2) + 2.0 * float(F.N > 0) * (38400.0 / float(F.N)), "level": level, "nodes": nodes, "face": face}


## The depth of a lake record's water at a point whose ground is h (units; 0 when the lake does not hold the point).
static func lakeDepth(F: WorldField.Field, rec: Dictionary, qx: float, qy: float, qz: float, h: float) -> float:
	if h >= float(rec.level):
		return 0.0
	WorldField._locate(qx, qy, qz, F.N)
	var i: int = clampi(int(WorldField._la), 0, F.N - 1)
	var j: int = clampi(int(WorldField._lb), 0, F.N - 1)
	var s2: int = F.side * F.side
	var nodes: Dictionary = rec.nodes
	# the cell's four corners and the ring of nodes round them: a gorge narrower than a cell, or a shore cell whose exact ground dips under the level between nodes above it, is still the lake's
	for dj in range(-1, 3):
		for di in range(-1, 3):
			var ii: int = i + di
			var jj: int = j + dj
			if ii < 0 or jj < 0 or ii > F.N or jj > F.N:
				continue
			if nodes.has(WorldField._lf * s2 + jj * F.side + ii):
				return float(rec.level) - h
	return 0.0


## ===================================================================== rivers
## The drainage segments within BAND of the ring as river records (rivers.json on; none otherwise). Each segment is a cell centre to its receiver, above the sea and with at least the river threshold of flow.
static func riversNear(P: WorldPlanet.Planet, circ: Dictionary) -> Array:
	var out: Array = []
	if not WorldRivers.enabled():
		return out
	var F: WorldRivers.Flow = WorldRivers.flowOf(P)
	if F == null or P.grid == null:
		return out
	var R: float = _R()
	var G: WorldClimate.Grid = P.grid
	for i in range(F.w * F.h):
		var rc: int = F.recv[i]
		if rc < 0 or G.ht[i] < 0.0 or F.flow[i] < WorldRivers.K_RIVER:
			continue
		var mx: float = F.px[i] + F.px[rc]
		var my: float = F.py[i] + F.py[rc]
		var mz: float = F.pz[i] + F.pz[rc]
		var ml: float = sqrt(mx * mx + my * my + mz * mz)
		if ml < 1.0e-9:
			continue
		mx /= ml
		my /= ml
		mz /= ml
		if absf(WorldPlanet.lateral(P, circ, mx, my, mz)) > BAND:
			continue
		var dx: float = (F.px[i] - F.px[rc]) * R
		var dy: float = (F.py[i] - F.py[rc]) * R
		var dz: float = (F.pz[i] - F.pz[rc]) * R
		var half: float = 0.5 * sqrt(dx * dx + dy * dy + dz * dz)
		var wcols: int = clampi(int(round(WorldRivers.K_W0 + WorldRivers.K_W1 * sqrt(float(F.flow[i]) / WorldRivers.K_REF))), WorldRivers.K_MIN_COLS, WorldRivers.K_MAX_COLS)
		out.append({"k": "river", "c": [mx, my, mz], "r": half + 0.5 * float(wcols) * SimConst.COL, "a": [F.px[i], F.py[i], F.pz[i]], "b": [F.px[rc], F.py[rc], F.pz[rc]], "flow": float(F.flow[i]), "w": float(wcols) * SimConst.COL})
	return out


## A river record's channel at a unit direction: [distance from the river's axis in units, the closest point's unit direction, the along-river unit tangent], or [] when the point is outside the record's reach.
static func _axis(rec: Dictionary, qx: float, qy: float, qz: float) -> Array:
	var a: Array = rec.a
	var b: Array = rec.b
	var ex: float = b[0] - a[0]
	var ey: float = b[1] - a[1]
	var ez: float = b[2] - a[2]
	var e2: float = ex * ex + ey * ey + ez * ez
	if e2 < 1.0e-18:
		return []
	var t: float = clampf(((qx - a[0]) * ex + (qy - a[1]) * ey + (qz - a[2]) * ez) / e2, 0.0, 1.0)
	var px: float = a[0] + ex * t
	var py: float = a[1] + ey * t
	var pz: float = a[2] + ez * t
	var pl: float = sqrt(px * px + py * py + pz * pz)
	px /= pl
	py /= pl
	pz /= pl
	var dx: float = (qx - px) * _R()
	var dy: float = (qy - py) * _R()
	var dz: float = (qz - pz) * _R()
	var el: float = sqrt(e2)
	return [sqrt(dx * dx + dy * dy + dz * dz), [px, py, pz], [ex / el, ey / el, ez / el]]


## The river's level at its axis point p with along-tangent t: the lower bank, a few columns each side across the river, less the freeboard. NAN where the banks are below WorldRivers.K_FLOOR (no river there).
static func _level(P: WorldPlanet.Planet, p: Array, t: Array) -> float:
	var nx: float = p[1] * t[2] - p[2] * t[1]
	var ny: float = p[2] * t[0] - p[0] * t[2]
	var nz: float = p[0] * t[1] - p[1] * t[0]
	var nl: float = sqrt(nx * nx + ny * ny + nz * nz)
	if nl < 1.0e-12:
		return NAN
	nx /= nl
	ny /= nl
	nz /= nl
	var s: float = float(WorldRivers.K_BANK) * SimConst.COL / _R()
	var ax: float = p[0] + nx * s
	var ay: float = p[1] + ny * s
	var az: float = p[2] + nz * s
	var al: float = sqrt(ax * ax + ay * ay + az * az)
	var bx: float = p[0] - nx * s
	var by: float = p[1] - ny * s
	var bz: float = p[2] - nz * s
	var bl: float = sqrt(bx * bx + by * by + bz * bz)
	var lv: float = minf(WorldField.height(P, ax / al, ay / al, az / al), WorldField.height(P, bx / bl, by / bl, bz / bl)) - WorldRivers.K_FREE
	return lv if lv >= WorldRivers.K_FLOOR else NAN


## The bed of a river record at a point and the level there: [bed, level] or [] outside the channel.
static func riverBed(P: WorldPlanet.Planet, rec: Dictionary, qx: float, qy: float, qz: float) -> Array:
	var ax: Array = _axis(rec, qx, qy, qz)
	if ax.is_empty():
		return []
	var half: float = 0.5 * float(rec.w)
	var d: float = float(ax[0])
	if d >= half:
		return []
	var level: float = _level(P, ax[1], ax[2])
	if is_nan(level):
		return []
	var u: float = d / half
	var p: float = 1.0
	if u > 0.5:
		var s: float = (u - 0.5) / 0.5
		p = 1.0 - s * s * (3.0 - 2.0 * s)
	return [level - WorldRivers.depthOf(float(rec.flow)) * p, level]


## ===================================================================== the index and the reads
static func _index(S) -> Dictionary:
	var id: int = S.get_instance_id()
	var ent: Dictionary = _ix.get(id, {})
	if ent.is_empty() or not is_same(ent.recs, S.fieldRecs) or int(ent.n) != S.fieldRecs.size():   # the records grow while a match is planned (pads after platforms): the index follows the array
		var grid: Dictionary = {}
		var big: Array = []
		var R: float = _R()
		for k in range(S.fieldRecs.size()):
			var rec: Dictionary = S.fieldRecs[k]
			var c: Array = rec.get("c", [])
			if c.is_empty():
				c = [rec.get("px", 0.0), rec.get("py", 0.0), rec.get("pz", 0.0)]
			var reach: float = float(rec.get("r", 0.0)) + float(rec.get("blend", 0.0))
			if reach > BIG:
				big.append(k)
				continue
			var cx: float = c[0] * R
			var cy: float = c[1] * R
			var cz: float = c[2] * R
			for ix in range(_box(cx - reach), _box(cx + reach) + 1):
				for iy in range(_box(cy - reach), _box(cy + reach) + 1):
					for iz in range(_box(cz - reach), _box(cz + reach) + 1):
						var key: int = _key(ix, iy, iz)
						var lst: PackedInt32Array = grid.get(key, PackedInt32Array())
						lst.append(k)
						grid[key] = lst
		ent = {"recs": S.fieldRecs, "n": S.fieldRecs.size(), "grid": grid, "big": big}
		if _ix.size() > 16:
			_ix.clear()
		_ix[id] = ent
	return ent


## The records that can reach a unit direction: the grid's box and the big ones.
static func near(S, qx: float, qy: float, qz: float) -> Array:
	if S.fieldRecs.is_empty():
		return []
	var ent: Dictionary = _index(S)
	var R: float = _R()
	var key: int = _key(_box(qx * R), _box(qy * R), _box(qz * R))
	var ids := PackedInt32Array()
	if ent.grid.has(key):
		ids.append_array(ent.grid[key])
	ids.append_array(PackedInt32Array(ent.big))
	if ent.big.size() > 0:
		ids.sort()   # the records apply in the order they were planned (a platform before the pads on it), whichever list holds them
	var out: Array = []
	for k in ids:
		out.append(S.fieldRecs[k])
	return out


## The index of the node at (i, j) of `face`, where i or j may be one past the face (-1 or N + 1): across the face's edge it is the node of the neighbouring face nearest the same direction.
static func _nodeAcross(F: WorldField.Field, face: int, i: int, j: int) -> int:
	if i >= 0 and j >= 0 and i <= F.N and j <= F.N:
		return WorldField.ensure(F, face, i, j)
	var d: Array = WorldField.dirOf(face, i, j, F.N)
	WorldField._locate(d[0], d[1], d[2], F.N)
	return WorldField.ensure(F, WorldField._lf, clampi(int(round(WorldField._la)), 0, F.N), clampi(int(round(WorldField._lb)), 0, F.N))


## Is node idx within `maxr` units of the unit direction q?
static func _within(F: WorldField.Field, idx: int, q: Array, maxr: float) -> bool:
	var s2: int = F.side * F.side
	var f: int = idx / s2
	var rem: int = idx - f * s2
	var j: int = rem / F.side
	var i: int = rem - j * F.side
	var d: Array = WorldField.dirOf(f, i, j, F.N)
	var R: float = _R()
	var dx: float = (d[0] - q[0]) * R
	var dy: float = (d[1] - q[1]) * R
	var dz: float = (d[2] - q[2]) * R
	return dx * dx + dy * dy + dz * dz <= maxr * maxr
