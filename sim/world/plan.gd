class_name WorldPlan
extends RefCounted
## Towns and cities by plan (docs/world/ring-any-angle/world.md 9.2; research.md T6 stage 9, first cut): a place's buildings are generated in the place's OWN frame, a pure function of the planet and the place's
## id, and the strip takes the ones whose lateral offset from the line falls in a lane. The same town stands the same at any bearing: the same buildings, the same plan indices, each at a fixed point of the planet.
##
## The plan: WorldSettle.generate, run on a flat dry stand-in for the strip (so nothing is trimmed or refused for ground) with the place's diameter as its span, gives a street along one axis and rows behind it (the
## lanes). The axis is the place's frame (WorldPlanet._frame: east and north at its centre) turned by a keyed yaw, so streets differ place to place and the town does not turn with the ring. A building's plan
## position (u along the street, v its lane depth) is a planet point: the centre moved along the sphere by u on the axis and v across it.
##
## Laying it on a ring: each building's planet point is read against the ring (arc along, lateral offset l; z = -l: the sim's z is positive toward the camera, away from the ring's centre (the side lateral() counts positive), the opposite of farColumn's and farPlaces' z). It stands on the strip if l falls in a block or scenery lane of
## data/biomes/lanes.json, takes that lane's row and flush z, and is kept when the ground under it takes a footprint (WorldTerrain._footOk) and no kept building of its row overlaps it. Footprints are not rotated: a
## building keeps its width along the line, so an oblique cut shows a staircase of lanes, not a rotated town. Streets (avenues) are kept only where the axis runs within about 10 degrees of the line.
## People are shared out among the buildings that stand (WorldSettle.assignPeople), not among all the plan's.
##
## The result has WorldSettle.generate's shape ({buildings, span, districts, rejected}) with two more keys on each building: "pi", its index in the plan (what a building's `plan` is, stable across rings) and "dir",
## its unit planet direction (Simulation's bound pose arrays read it). Behind data/biomes/field.json plans; used only for a gen 3 planet. A place that would stand fewer than `minBuildings` falls back to the chord's layout.

const BH: float = 75.0
static var _memo: Dictionary = {}
static var overrideOn: int = -1   # a tool's choice: -1 the data's, 0 off, 1 on
static var alignOverride: int = -1   # a tool's choice for plans.align: -1 the data's, 0 off, 1 on
static var everywhereOverride: int = -1   # a tool's choice for plans.everywhere: -1 the data's, 0 off, 1 on


static func enabled() -> bool:
	if overrideOn >= 0:
		return overrideOn == 1
	return bool(WorldField.data().get("plans", {}).get("enabled", false))


## Whether every place the first ring does not hold is laid too, as the whole of its plan (layFree), so a swing or a launch onto any town finds buildings (docs/world/places-everywhere.md). Off, only the first ring's places stand.
static func everywhere() -> bool:
	if everywhereOverride >= 0:
		return everywhereOverride == 1
	return bool(WorldField.data().get("plans", {}).get("everywhere", false))


## The most the ground may depart from a straight slope between a free building's centre and a corner of its plan footprint (plans.maxFootSlope, units; 0 or less: no limit). A building over a cliff or a step of another record
## is not laid (like one in the sea): its underside would show (docs/world/lot-gap.md). A smooth slope, however steep, passes: the lot's tilt and the view's plinth answer that. `footSlopeOverride` (a test's) is used when it is 0 or more.
static var footSlopeOverride: float = -1.0


static func maxFootSlope() -> float:
	if footSlopeOverride >= 0.0:
		return footSlopeOverride
	return float(WorldField.data().get("plans", {}).get("maxFootSlope", 0.0))


## Do the far places' buildings hold people (farPeople), and do those people count toward the hero's anguish (farAnguish)? Both off: a far building has none (docs/world/places-everywhere.md).
static func farPeople() -> bool:
	return everywhere() and bool(WorldField.data().get("plans", {}).get("farPeople", false))


static func farAnguish() -> bool:
	return farPeople() and bool(WorldField.data().get("plans", {}).get("farAnguish", false))


static func farShare() -> float:
	return float(WorldField.data().get("plans", {}).get("farShare", 1.0))


## The depth in front of the line (z positive toward the camera) past which a planet-fixed building is not indexed, so is neither drawn nor struck, in units, tested on the building's front face (z + d / 2):
## -2 bh = -150, where Rendering's rule starts to bring a building down. A first-ring block is flush to the street's back edge, -2.5 bh, so its face is -187.5 and it is always kept.
static func indexFront() -> float:
	return float(WorldField.data().get("plans", {}).get("indexFrontBH", -3.0)) * BH


## The depth behind the line out to which a planet-fixed building is indexed, units: swing.json's indexBand, or the background lane's far edge (lanes.json, row 3 ends at 44.5 bh) if that is further.
static func indexBack(band: float) -> float:
	return maxf(band, float(WorldField.data().get("plans", {}).get("indexBackBH", 45.0)) * BH)


static func farReach() -> float:
	return float(WorldField.data().get("plans", {}).get("farReach", 9000.0))


## ===================================================================== the far places in the cache
## A far place's laid plan (its buildings with their planet points and ground, its districts, its lots) is a pure function of the planet and the data, not of the ring: only a building's strip x and z read the ring,
## and they are two reads from its planet point. So the whole set is kept in the field cache (WorldFieldCache.writeBlob, one blob a planet, `var_to_bytes`) and a warm match start reads it back: the plans' geometry
## and the bake's ground reads, about 1 s native, are not done again. Not kept while rivers are on (a river cuts the ground the lots read, and it is read through the ring).
const PLACES_REV: int = 1


static func placesKey(P: WorldPlanet.Planet) -> String:
	return "places|rev %d|seed %d|%s|%s|%s|%s" % [PLACES_REV, P.seed, WorldPlanet.dataHash(3), WorldField.dataHash(), WorldSettle.dataHash(), str(Engine.get_version_info().get("string", ""))]


static func placesCached() -> bool:
	return WorldFieldCache.enabled() and not WorldRivers.enabled()


## pid -> {"b": buildings, "dist", "yaw", "lots"} for the planet, or {} when none is kept.
static func placesLoad(P: WorldPlanet.Planet) -> Dictionary:
	if not placesCached():
		return {}
	var bytes: PackedByteArray = WorldFieldCache.readBlob(placesKey(P))
	if bytes.is_empty():
		return {}
	var v = bytes_to_var(bytes)
	return v if v is Dictionary else {}


static func placesStore(P: WorldPlanet.Planet, places: Dictionary) -> void:
	if placesCached() and not places.is_empty():
		WorldFieldCache.writeBlob(placesKey(P), var_to_bytes(places))


## A kept place as layFree returns it: each building's strip x and z read against `circ`.
static func placesRestore(P: WorldPlanet.Planet, kept: Dictionary, circ: Dictionary) -> Dictionary:
	var span: float = float(SimConst.NC) * SimConst.COL
	var bs: Array = kept.b
	for e in bs:
		var q: Array = e.dir
		var cx0: float = stripX(P, circ, q)
		e["x"] = cx0 - floor(cx0 / span) * span
		e["z"] = -WorldPlanet.lateral(P, circ, q[0], q[1], q[2])
	return {"buildings": bs, "dist": kept.dist, "yaw": kept.yaw}


static func minBuildings() -> int:
	return int(WorldField.data().get("plans", {}).get("minBuildings", 6))


## The street axis's yaw from east, radians in [0, pi): one of `yawSteps` values, keyed by the planet and the place.
static func yawOf(P: WorldPlanet.Planet, id: int) -> float:
	var steps: int = int(WorldField.data().get("plans", {}).get("yawSteps", 24))
	var u: float = SimRng.keyed(P.seed, "plan.yaw", id)
	return float(int(u * float(steps))) * SimMathx.PI / float(steps)


## The plan of a place in its own frame: {"b": buildings (generate's dicts, x re-centred as "u", z as "v"), "dist": districts, "xc": the centre x of the stand-in strip}. Memoised by planet, place and the data.
static func geometry(P: WorldPlanet.Planet, id: int, shift: float = 0.0) -> Dictionary:
	var key: String = "%d/%d/%d/%s/%s/%d" % [P.seed, id, int(P.kind[id]), WorldSettle.dataHash(), WorldField.dataHash(), int(round(shift / 8.0))]
	if _memo.has(key):
		return _memo[key]
	var NC: int = SimConst.NC
	var COL: float = SimConst.COL
	var PS: float = SimConst.PS
	var city: bool = int(P.kind[id]) == WorldPlanet.KIND_CITY
	var arch: Dictionary = {}
	for sd in WorldSettle.data().settlements:
		arch[sd.id] = sd
	var sd2: Dictionary = (arch[WorldPlanetWorld.ARCH_CITY] if city else arch[WorldPlanetWorld.ARCH_TOWN]).duplicate(true)
	WorldDensity.apply(sd2, "city" if city else "town")
	sd2.pop_share = 0.0
	var S := SimState.new()
	S.base.resize(NC)
	S.base.fill(WorldTerrain.SETTLE_FLOOR + 1.0)   # flat and dry: nothing trimmed, nothing refused for its ground
	# bands: the plan is the street's strip laid side by side, one lane-band apart (pitchBH fighter heights, the lanes' whole depth), as many each side as the place's radius holds, each as long as the
	# disc is wide at its offset. A ring at any bearing then crosses several bands, so an oblique cut stands about as many buildings as an aligned one; its own seeded layout each (the band number is in the id).
	var pd: Dictionary = WorldField.data().get("plans", {})
	var kmax: int = int(pd.get("bandsCity", 2)) if city else int(pd.get("bandsTown", 1))
	var pitch: float = float(pd.get("pitchBH", 32.0)) * BH
	var xc: float = float(NC / 2) * COL
	var out: Array = []
	var dist: Array = []
	for kb in range(-kmax, kmax + 1):
		var vk: float = float(kb) * pitch + shift
		var rr: float = P.rad[id]
		if absf(vk) >= rr:
			continue
		var half: int = mini(int(sqrt(rr * rr - vk * vk) / COL), NC / 2 - 2)
		if half < 20:
			continue
		var sdb: Dictionary = sd2.duplicate(true)
		sdb.id = "p%d" % id if kb == 0 else "p%d.%d" % [id, kb]
		sdb.span = [float(NC / 2 - half) * COL / PS, float(NC / 2 + half) * COL / PS]
		var g: Dictionary = WorldSettle.generate(S, sdb)
		var doff: int = dist.size()
		for dd in g.districts:
			dist.append(dd)
		for e in g.buildings:
			e["band"] = kb
			e["z"] = float(e.z) + vk
			e["district"] = int(e.district) + doff
			e["pi"] = out.size()
			out.append(e)
	var geo: Dictionary = {"b": out, "dist": dist, "xc": xc}
	if _memo.size() > 192:
		_memo.clear()
	_memo[key] = geo
	return geo


## The planet point at plan offset (u along the street, v across it, v positive toward the camera, so to the right of the ring's travel when the camera looks from its right) of place `id`: the centre moved over the sphere by that vector. Returns a unit direction.
static func pointOf(P: WorldPlanet.Planet, id: int, yaw: float, u: float, v: float) -> Array:
	var c: Array = [P.px[id], P.py[id], P.pz[id]]
	var e: Array = WorldPlanet._unit(WorldPlanet._cross([0.0, 1.0, 0.0], c))
	var nrt: Array = WorldPlanet._cross(c, e)
	var cy: float = SimDetMath.cos(yaw)
	var sy: float = SimDetMath.sin(yaw)
	var ax: float = cy * e[0] + sy * nrt[0]
	var ay: float = cy * e[1] + sy * nrt[1]
	var az: float = cy * e[2] + sy * nrt[2]
	var px: float = -sy * e[0] + cy * nrt[0]
	var py: float = -sy * e[1] + cy * nrt[1]
	var pz: float = -sy * e[2] + cy * nrt[2]
	var ox: float = u * ax - v * px
	var oy: float = u * ay - v * py
	var oz: float = u * az - v * pz
	var dist: float = sqrt(ox * ox + oy * oy + oz * oz)
	if dist < 1.0e-9:
		return c
	var s: float = dist / P.R
	var cs: float = SimDetMath.cos(s)
	var sn: float = SimDetMath.sin(s) / dist
	return [c[0] * cs + ox * sn, c[1] * cs + oy * sn, c[2] * cs + oz * sn]


## The ring's unit tangent at a planet point (the way columns run).
static func ringTangent(circ: Dictionary, q: Array) -> Array:
	var ax: Array = circ.c if circ.has("st") else circ.n
	return WorldPlanet._unit(WorldPlanet._cross(ax, q))


## The strip x (units, in [0, NC * COL)) of a planet point on a ring: the arc along it from the touch-down column, as _heldPlaces does for a place's centre.
static func stripX(P: WorldPlanet.Planet, circ: Dictionary, q: Array) -> float:
	var u: Array = circ.u
	var v: Array = circ.v
	var stf: float = circ.get("st", 1.0)
	var along: float = WorldPlanet.atan2f(q[0] * v[0] + q[1] * v[1] + q[2] * v[2], q[0] * u[0] + q[1] * u[1] + q[2] * u[2])
	var span: float = float(SimConst.NC) * SimConst.COL
	var x: float = (float(WorldPlanet.touchCol()) * SimConst.COL + along * P.R * stf)
	return x - floor(x / span) * span


## The planet direction of strip (x, z) on a ring: the column's point moved sideways by z along the great circle at right angles (the SIM's z: positive toward the camera, away from the ring's centre; farColumn's and farPlaces' z are the opposite sign and must be flipped before they are used as a depth).
static func dirAtStrip(P: WorldPlanet.Planet, circ: Dictionary, x: float, z: float) -> Array:
	var nc: int = SimConst.NC
	var col: int = ((int(floor(x / SimConst.COL + 0.5)) % nc) + nc) % nc
	var p: Array = WorldPlanet.columnPoint(P, circ, col)
	if z == 0.0:
		return p
	var m: Array = circ.get("c", circ.n)
	var d: float = m[0] * p[0] + m[1] * p[1] + m[2] * p[2]
	var t: Array = WorldPlanet._unit([m[0] - p[0] * d, m[1] - p[1] * d, m[2] - p[2] * d])
	var a: float = -z / P.R   # the sim's z is positive toward the camera, away from the ring's centre; farColumn's is the opposite
	var co: float = SimDetMath.cos(a)
	var si: float = SimDetMath.sin(a)
	return [p[0] * co + t[0] * si, p[1] * co + t[1] * si, p[2] * co + t[2] * si]


## The lanes buildings can stand in: [{row, top, bottom, kind}] in units, block and scenery lanes (rows 0 and 3 only if the foreground is on, as generate does).
static func _lanes() -> Array:
	var out: Array = []
	var fg: bool = bool(WorldSettle.data().get("foreground", true))
	for l in WorldLanes.data().get("lanes", []):
		if String(l.kind) != "block" and String(l.kind) != "scenery":
			continue
		if int(l.row) == 0 and not fg:
			continue
		out.append({"row": int(l.row), "top": float(l.top) * BH, "bottom": float(l.bottom) * BH, "kind": String(l.kind)})
	return out


## Place `id` of planet P laid on ring `circ` (S.base the ring's ground, platforms in): generate's shape, or {} when fewer than minBuildings would stand (the caller lays the chord's layout then).
## popShare: the place's share of the match's people. `tc` below is the touch column, the ring's origin.
static func lay(S: SimState, P: WorldPlanet.Planet, id: int, circ: Dictionary, popShare: float) -> Dictionary:
	var geo: Dictionary = {}
	var yaw: float = yawOf(P, id)
	var shift: float = 0.0   # the plan's offset across the street, so one of its bands lies on the ring's lanes
	var aligned: bool = aligning() and not circ.is_empty()
	var xcen: float = 0.0
	var zc0: float = 0.0
	if aligned:
		var c0: Array = [P.px[id], P.py[id], P.pz[id]]
		var ee0: Array = WorldPlanet._unit(WorldPlanet._cross([0.0, 1.0, 0.0], c0))
		var nn0: Array = WorldPlanet._cross(c0, ee0)
		var t0: Array = ringTangent(circ, c0)
		yaw = WorldPlanet.atan2f(t0[0] * nn0[0] + t0[1] * nn0[1] + t0[2] * nn0[2], t0[0] * ee0[0] + t0[1] * ee0[1] + t0[2] * ee0[2])
		var pitch: float = float(WorldField.data().get("plans", {}).get("pitchBH", 32.0)) * BH
		var zc: float = -WorldPlanet.lateral(P, circ, c0[0], c0[1], c0[2])
		zc0 = zc
		xcen = stripX(P, circ, c0)
		shift = round(zc / pitch) * pitch - zc
	geo = geometry(P, id, shift)
	var lanes: Array = _lanes()
	var kept: Array = []
	var rest: Array = []
	var byRow: Dictionary = {}
	var rejected: int = 0
	var span: float = float(SimConst.NC) * SimConst.COL
	var plan: Array = geo.b
	for k in range(plan.size()):
		var e: Dictionary = plan[k]
		var q: Array
		var z: float
		var cx0: float
		if aligned:   # the plan wraps along the ring (the street curves with it), so its band lies on the lanes the whole way
			cx0 = xcen + (float(e.x) - float(geo.xc))
			z = zc0 + float(e.z)
			q = pointAtX(P, circ, cx0, z)
		else:
			q = pointOf(P, id, yaw, float(e.x) - float(geo.xc), float(e.z))
			z = -WorldPlanet.lateral(P, circ, q[0], q[1], q[2])
			cx0 = stripX(P, circ, q)
		var lane: Dictionary = {}
		for l in lanes:
			if z <= float(l.top) and z >= float(l.bottom):
				lane = l
				break
		var cx: float = cx0 - floor(cx0 / span) * span
		if lane.is_empty():
			if everywhere():   # the rest of the plan, outside the lanes of this ring: it stands too (planet-fixed, no people), for a line that turns toward it
				rest.append(_restOf(e, geo, q, cx, z))
			continue
		if not WorldTerrain._footOk(S, cx, float(e.w)):
			rejected += 1
			if everywhere():
				rest.append(_restOf(e, geo, q, cx, z))
			continue
		var row: int = int(lane.row)
		var dd: float = minf(float(e.d), float(lane.top) - float(lane.bottom))
		var zc: float = (float(lane.top) - dd * 0.5) if String(lane.kind) == "block" else 0.5 * (float(lane.top) + float(lane.bottom))
		var clash: bool = false
		for o in byRow.get(row, []):
			var dx: float = absf(sdx(float(o.x), cx, span))
			if dx < (float(o.w) + float(e.w)) * 0.5:
				clash = true
				break
		if clash:
			rejected += 1
			if everywhere():
				rest.append(_restOf(e, geo, q, cx, z))
			continue
		var b: Dictionary = e.duplicate()
		b["x"] = cx
		b["row"] = row
		b["d"] = dd
		b["z"] = zc
		b["pdir"] = q   # the plan's own point (identity across rings); dir is where the building is laid, after the lane snap: what the pad, the pose arrays and the tiles use
		b["dir"] = pointAtX(P, circ, cx, zc)
		kept.append(b)
		if not byRow.has(row):
			byRow[row] = []
		byRow[row].append(b)
	if kept.size() < minBuildings():
		return {}
	WorldSettle.assignPeople(kept, popShare)
	kept.sort_custom(func(p, r): return p.x < r.x or (p.x == r.x and p.row < r.row))
	# districts: the extent each one has on this ring; its avenues only when the street runs along the line
	var tq: Array = ringTangent(circ, [P.px[id], P.py[id], P.pz[id]])
	var cy: float = SimDetMath.cos(yaw)
	var sy: float = SimDetMath.sin(yaw)
	var c: Array = [P.px[id], P.py[id], P.pz[id]]
	var ee: Array = WorldPlanet._unit(WorldPlanet._cross([0.0, 1.0, 0.0], c))
	var nn: Array = WorldPlanet._cross(c, ee)
	var alongness: float = absf((cy * ee[0] + sy * nn[0]) * tq[0] + (cy * ee[1] + sy * nn[1]) * tq[1] + (cy * ee[2] + sy * nn[2]) * tq[2])
	var districts: Array = []
	var remap: Dictionary = {}
	for di in range(geo.dist.size()):
		var gd: Dictionary = geo.dist[di]
		var lo: float = 1.0e30
		var hi: float = -1.0e30
		for b in kept:
			if int(b.district) == di:
				lo = minf(lo, float(b.x) - float(b.w) * 0.5)
				hi = maxf(hi, float(b.x) + float(b.w) * 0.5)
		if lo > hi:
			continue
		var av: Array = []
		if alongness >= 0.985:
			var u0: Array = pointOf(P, id, yaw, 0.0, 0.0)
			var xc0: float = stripX(P, circ, u0)
			var sgn: float = 1.0 if (cy * ee[0] + sy * nn[0]) * tq[0] + (cy * ee[1] + sy * nn[1]) * tq[1] + (cy * ee[2] + sy * nn[2]) * tq[2] > 0.0 else -1.0
			for a in gd.avenues:
				var a0: float = xc0 + sgn * (float(a[0]) - float(geo.xc))
				var a1: float = xc0 + sgn * (float(a[1]) - float(geo.xc))
				av.append([minf(a0, a1), maxf(a0, a1)])
		remap[di] = districts.size()
		districts.append({"name": gd.name, "look": gd.look, "a": lo, "b": hi, "avenues": av, "rows": gd.rows, "traffic": float(gd.get("traffic", 0.0))})
	for b in kept:
		b["district"] = int(remap.get(int(b.district), 0))
	for b in rest:
		b["district"] = int(remap.get(int(b.district), 0))
	var sp: Array = [float(kept[0].x), float(kept[kept.size() - 1].x)]
	return {"buildings": kept, "span": sp, "districts": districts, "rejected": rejected, "rest": rest, "yaw": yaw}


## A plan building this ring does not lay (outside its lanes, on ground that takes no footprint, or clashing with one it laid), as a planet-fixed building at its plan point `q`: strip x `cx`, z `z`.
static func _restOf(e: Dictionary, geo: Dictionary, q: Array, cx: float, z: float) -> Dictionary:
	var rb: Dictionary = e.duplicate()
	rb["x"] = cx
	rb["z"] = z
	rb["pdir"] = q
	rb["dir"] = q
	rb["u"] = float(e.x) - float(geo.xc)
	rb["v"] = float(e.z)
	rb["pop"] = 0
	return rb


## Signed shortest distance from a to b on a loop of `span` units (b minus a).
static func sdx(a: float, b: float, span: float) -> float:
	var d: float = b - a
	return d - round(d / span) * span


## Whether a place's plan is turned to the ring it is first laid on (plans.align): the street runs along the line and a band lies on its lanes, so a place stands as dense as the chord's layout did. The place keeps that
## turn for the whole match (the plan is then a fixed thing the line swings across); another match on another ring turns it again. Off, the street's yaw is the planet's own (yawOf) and an oblique ring stands about half.
static func aligning() -> bool:
	if alignOverride >= 0:
		return alignOverride == 1
	return bool(WorldField.data().get("plans", {}).get("align", false))


## The planet direction of strip (x, z) on a ring, exactly (x need not be a column): the ring's point at arc x, moved sideways by -z along the great circle at right angles (z the SIM's: positive toward the camera, away from
## the ring's centre).
static func pointAtX(P: WorldPlanet.Planet, circ: Dictionary, x: float, z: float) -> Array:
	var stf: float = circ.get("st", 1.0)
	var ang: float = (x - float(WorldPlanet.touchCol()) * SimConst.COL) / (P.R * stf)
	var co: float = SimDetMath.cos(ang)
	var si: float = SimDetMath.sin(ang)
	var u: Array = circ.u
	var v: Array = circ.v
	var p: Array
	if circ.has("st"):
		var c: Array = circ.c
		var ct: float = circ.ct
		p = [c[0] * ct + stf * (u[0] * co + v[0] * si), c[1] * ct + stf * (u[1] * co + v[1] * si), c[2] * ct + stf * (u[2] * co + v[2] * si)]
	else:
		p = [u[0] * co + v[0] * si, u[1] * co + v[1] * si, u[2] * co + v[2] * si]
	if z == 0.0:
		return p
	var m: Array = circ.get("c", circ.n)
	var d: float = m[0] * p[0] + m[1] * p[1] + m[2] * p[2]
	var t: Array = WorldPlanet._unit([m[0] - p[0] * d, m[1] - p[1] * d, m[2] - p[2] * d])
	var a: float = -z / P.R
	var cs: float = SimDetMath.cos(a)
	var sn: float = SimDetMath.sin(a)
	return [p[0] * cs + t[0] * sn, p[1] * cs + t[1] * sn, p[2] * cs + t[2] * sn]


## ===================================================================== places everywhere
## Place `id` as the whole of its plan, planet-fixed (a place the first ring does not hold; docs/world/places-everywhere.md): every building of the plan at its planet point (pointOf at the planet's own yaw: a plan
## turned to a ring is the first ring's business), no lane and no lane snap, its strip x and z read against the ring `circ` (the first frame; Simulation's pose arrays follow the frame from `dir`). A building whose
## ground (the bake, with the platform) is in the sea is not laid. People are 0: a far town's people wait on Game Design's ruling (they would otherwise fill the lure buckets at x that has nothing near the line).
## Returns {"buildings": [generate's dicts + pi, dir, pdir], "dist": the plan's districts, "yaw", "geo"}.
static func layFree(S: SimState, P: WorldPlanet.Planet, id: int, circ: Dictionary) -> Dictionary:
	var yaw: float = yawOf(P, id)
	var geo: Dictionary = geometry(P, id, 0.0)
	var span: float = float(SimConst.NC) * SimConst.COL
	var kept: Array = []
	var gmax: float = maxFootSlope()
	var cliffed: int = 0
	for e in geo.b:
		var q: Array = pointOf(P, id, yaw, float(e.x) - float(geo.xc), float(e.z))
		var g0: float = WorldField.applyRecords(S, q[0], q[1], q[2], WorldField.heightBake(P, q[0], q[1], q[2]), P)
		if g0 < WorldTerrain.TRIM_G:
			continue
		if gmax > 0.0 and _overhangs(S, P, id, yaw, float(e.x) - float(geo.xc), float(e.z), 0.5 * float(e.w), 0.5 * float(e.d), g0, gmax):
			cliffed += 1
			continue
		var cx0: float = stripX(P, circ, q)
		var b: Dictionary = e.duplicate()
		b["x"] = cx0 - floor(cx0 / span) * span
		b["z"] = -WorldPlanet.lateral(P, circ, q[0], q[1], q[2])
		b["pop"] = 0
		b["g"] = g0
		b["pdir"] = q
		b["dir"] = q
		b["u"] = float(e.x) - float(geo.xc)
		b["v"] = float(e.z)
		kept.append(b)
	return {"buildings": kept, "dist": geo.dist, "yaw": yaw, "cliffed": cliffed}


## Is the ground steeper than `slope` (rise over run) between the footprint's centre and any of eight points on the circle round it (radius r, the half diagonal: a footprint turned to any line has its corners on it)? Read from
## the bake with the platform, as layFree reads it. A cliff has a slope of 3 or more; a hillside town stands on 0.3 to 0.6.
static func _overhangs(S: SimState, P: WorldPlanet.Planet, id: int, yaw: float, u: float, v: float, hw: float, hd: float, g0: float, slope: float) -> bool:
	var r: float = sqrt(hw * hw + hd * hd)
	var q4: float = SimMathx.f64("3fe921fb54442d18")   # pi/4 from its bits (the parity lint allows no float literal over 15 digits)
	for k in range(8):
		var qc: Array = pointOf(P, id, yaw, u + r * SimDetMath.cos(float(k) * q4), v + r * SimDetMath.sin(float(k) * q4))
		var gc: float = WorldField.applyRecords(S, qc[0], qc[1], qc[2], WorldField.heightBake(P, qc[0], qc[1], qc[2]), P)
		if absf(g0 - gc) > r * slope:
			return true
	return false


## The lots of a free place, in its plan frame (a lot is the buildings of one band's row within `lots.gap` along the street; the strip's x means nothing for a far place): the same record as WorldField.lotRecords, its
## height the mean of the bake's ground (with the platform) at its buildings (read once, in layFree), so a place's lots cost reads of the bake, not of the planet. `first`: the id of its first lot.
static func freeLots(S: SimState, P: WorldPlanet.Planet, id: int, laid: Dictionary, first: int) -> Array:
	var cfg: Dictionary = WorldField.data().get("lots", {})
	var side: float = float(cfg.get("sidewalk", 15.0))
	var gap_max: float = float(cfg.get("gap", 300.0))
	var yaw: float = float(laid.yaw)
	var bs: Array = laid.buildings
	var groups: Dictionary = {}
	for i in range(bs.size()):
		var key: String = "%d/%d" % [int(bs[i].band), int(bs[i].row)]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(i)
	var keys: Array = groups.keys()
	keys.sort()
	var out: Array = []
	for key in keys:
		var idxs: Array = groups[key]
		idxs.sort_custom(func(a, c): return float(bs[a].u) < float(bs[c].u) or (float(bs[a].u) == float(bs[c].u) and a < c))
		var run: Array = []
		var right: float = -1.0e30
		for ii in idxs:
			var left: float = float(bs[ii].u) - float(bs[ii].w) * 0.5
			if not run.is_empty() and left - right > gap_max:
				out.append(_freeLot(S, P, id, yaw, bs, run, side, first + out.size()))
				run = []
				right = -1.0e30
			run.append(ii)
			right = maxf(right, float(bs[ii].u) + float(bs[ii].w) * 0.5)
		if not run.is_empty():
			out.append(_freeLot(S, P, id, yaw, bs, run, side, first + out.size()))
	WorldField._blends(out, P.R, cfg)   # the blends, along the street and across it
	return out


static func _freeLot(S: SimState, P: WorldPlanet.Planet, id: int, yaw: float, bs: Array, run: Array, side: float, lid: int) -> Dictionary:
	var ul: float = 1.0e30
	var ur: float = -1.0e30
	var vsum: float = 0.0
	var dmax: float = 0.0
	var alongs: Array = []
	var ground: Array = []
	for m in run:
		var b: Dictionary = bs[m]
		ul = minf(ul, float(b.u) - float(b.w) * 0.5)
		ur = maxf(ur, float(b.u) + float(b.w) * 0.5)
		vsum += float(b.v)
		dmax = maxf(dmax, float(b.d))
		alongs.append(float(b.u))
		ground.append(float(b.g))
	var pl: Array = WorldField._plane(alongs, ground, 0.5 * (ul + ur), float(WorldField.data().get("lots", {}).get("grade", 0.0)))
	var cx: float = 0.0
	var cy: float = 0.0
	var cz: float = 0.0
	for m in run:
		var qd: Array = bs[m].dir
		cx += qd[0]
		cy += qd[1]
		cz += qd[2]
	var c: Array = WorldPlanet._unit([cx, cy, cz])
	var tx: float
	var ty: float
	var tz: float
	if run.size() > 1:   # along the street: from the first member to the last, by the plan's order
		var qa: Array = bs[run[0]].dir
		var qb: Array = bs[run[run.size() - 1]].dir
		tx = qb[0] - qa[0]
		ty = qb[1] - qa[1]
		tz = qb[2] - qa[2]
	else:
		var vc: float = vsum / float(run.size())
		var uc: float = 0.5 * (ul + ur)
		var p1: Array = pointOf(P, id, yaw, uc + 50.0, vc)
		var p0: Array = pointOf(P, id, yaw, uc - 50.0, vc)
		tx = p1[0] - p0[0]
		ty = p1[1] - p0[1]
		tz = p1[2] - p0[2]
	var along: float = tx * c[0] + ty * c[1] + tz * c[2]
	var t: Array = WorldPlanet._unit([tx - c[0] * along, ty - c[1] * along, tz - c[2] * along])
	var s: Array = WorldPlanet._unit(WorldPlanet._cross(c, t))
	var R: float = P.R   # the box covers every member's footprint as it stands (a street that curves leaves the straight run's extent)
	var hl: float = 0.5 * (ur - ul) + side
	var hd: float = 0.5 * dmax + side
	for m in run:
		var bq: Array = bs[m].dir
		var ex: float = (bq[0] - c[0]) * R
		var ey: float = (bq[1] - c[1]) * R
		var ez: float = (bq[2] - c[2]) * R
		hl = maxf(hl, absf(ex * t[0] + ey * t[1] + ez * t[2]) + 0.5 * float(bs[m].w) + side)
		hd = maxf(hd, absf(ex * s[0] + ey * s[1] + ez * s[2]) + 0.5 * float(bs[m].d) + side)
	var gs: float = 0.0
	var gA: float = float(WorldField.data().get("lots", {}).get("gradeAcross", 0.0))
	if gA > 0.0:
		var gg: Array = []
		for sg in [1.0, -1.0]:
			var x: float = c[0] + s[0] * hd * sg / R
			var y: float = c[1] + s[1] * hd * sg / R
			var z: float = c[2] + s[2] * hd * sg / R
			var nn: float = 1.0 / sqrt(x * x + y * y + z * z)
			gg.append(WorldField.applyRecords(S, x * nn, y * nn, z * nn, WorldField.heightBake(P, x * nn, y * nn, z * nn), P))
		gs = clampf((float(gg[0]) - float(gg[1])) / (2.0 * hd), -gA, gA)
	return {"k": "lot", "id": lid, "c": c, "t": t, "s": s, "hl": hl, "hd": hd, "r": sqrt(hl * hl + hd * hd), "blend": 20.0, "bs": 20.0, "h": pl[0], "gt": pl[1], "gs": gs, "n": run.size(), "lone": run.size() == 1}
