class_name UiPlanetMap
extends RefCounted
## The planet map (docs/ui/planet-map.md): a small globe at the foot of the screen with the fight's trail round the planet and the pair on it, no labels, numbers or icons.
## A stand-in until Simulation's planet-direction API is out: it reads `planet_map_fn() -> {"pair": [dir, dir], "tick": int}` from the host, where a dir is a Vector3 (a unit
## direction on the planet) or a Dictionary {"lon": radians, "lat": radians}; with no feed the pair is read off the planet strip's data (the ring's x as a longitude on the
## equator, the only planet position the fight has today) and the biome segments are the land. Drawn from points, never a shader, so the Compatibility renderer and the web
## build draw it as they draw everything else. The trail is sampled every SAMPLE_TICKS ticks of the feed's tick and kept for the whole match (decimated, never cut).
## It only reads: nothing here touches the sim, and nothing pulses or fades (the area is under the flash threshold at every supported size).

const SAMPLE_TICKS := 15
const MAX_TRAIL := 2400          # points kept; when full the older half is thinned to every other point, so the whole match is always there
const STEP := 0.0087266          # the globe turns in half-degree steps, so it redraws only when it has turned
const LAND_ROWS: Array = [-0.36, -0.18, 0.0, 0.18, 0.36]
const LAND_ALPHA := 0.55


## A direction (Vector3 or {lon, lat}) as [lon, lat] in radians.
static func lonlat(d) -> Array:
	if d is Vector3:
		var v: Vector3 = (d as Vector3).normalized()
		return [atan2(v.x, v.z), asin(clampf(v.y, -1.0, 1.0))]
	if d is Dictionary:
		return [float((d as Dictionary).get("lon", 0.0)), float((d as Dictionary).get("lat", 0.0))]
	return [0.0, 0.0]


## The stand-in feed from the planet strip's data: each fighter's ring x as a longitude on the equator.
static func feed_from_strip(data: Dictionary, tick: int) -> Dictionary:
	var W: float = float(data.get("W", 9600.0))
	var pair: Array = []
	for f in data.get("fighters", []):
		pair.append({"lon": fposmod(float((f as Dictionary).get("x", 0.0)), W) / W * TAU, "lat": 0.0})
	return {"pair": pair, "tick": tick, "segs": data.get("segs", []), "W": W}


## The longitude and latitude the globe faces: the pair's middle by the short way round (one point when together).
static func centre(pair: Array) -> Array:
	if pair.is_empty():
		return [0.0, 0.0]
	var p0: Array = lonlat(pair[0])
	if pair.size() < 2:
		return p0
	var p1: Array = lonlat(pair[1])
	var dl: float = wrapf(float(p1[0]) - float(p0[0]), -PI, PI)
	return [float(p0[0]) + dl * 0.5, (float(p0[1]) + float(p1[1])) * 0.5]


## The step the centre is held to (so the layer redraws only when the globe has turned).
static func turned(v: float) -> float:
	return roundf(v / STEP) * STEP


## A point on the sphere as a disc offset and its depth: x and y in -1..1 (y down), z > 0 on the near side.
static func project(lon: float, lat: float, clon: float, clat: float) -> Vector3:
	var dl: float = lon - clon
	var cl: float = cos(lat)
	var x: float = cl * sin(dl)
	var y: float = cos(clat) * sin(lat) - sin(clat) * cl * cos(dl)
	var z: float = sin(clat) * sin(lat) + cos(clat) * cl * cos(dl)
	return Vector3(x, -y, z)


## Add a position to the trail when a sample is due; returns true when it changed. A tick that went backwards (a new match) clears it first.
static func sample(state: Dictionary, feed: Dictionary) -> bool:
	var tick: int = int(feed.get("tick", 0))
	var last: int = int(state.get("last_tick", -1000000))
	var pair: Array = feed.get("pair", [])
	if pair.is_empty():
		return false
	var changed := false
	if tick < last:
		state["trail"] = PackedFloat32Array()
		state["last_tick"] = -1000000
		last = -1000000
		changed = true
	if tick - last < SAMPLE_TICKS:
		return changed
	var c: Array = centre(pair)
	var tr: PackedFloat32Array = state.get("trail", PackedFloat32Array())
	tr.append(float(c[0]))
	tr.append(float(c[1]))
	if tr.size() > MAX_TRAIL * 2:
		var thin := PackedFloat32Array()
		var half: int = tr.size() / 4   # the older half of the points, thinned to every other one
		for k in range(0, half, 2):
			thin.append(tr[k * 2])
			thin.append(tr[k * 2 + 1])
		for i in range(half * 2, tr.size()):
			thin.append(tr[i])
		tr = thin
	state["trail"] = tr
	state["last_tick"] = tick
	return true


## The redraw key: the globe's turn, the trail's length, the pair's places at a pixel's worth, the land.
static func sig(state: Dictionary, feed: Dictionary) -> Array:
	var pair: Array = feed.get("pair", [])
	var c: Array = centre(pair)
	var key: Array = [int(roundf(float(c[0]) / STEP)), int(roundf(float(c[1]) / STEP)), (state.get("trail", PackedFloat32Array()) as PackedFloat32Array).size(), pair.size()]
	for d in pair:
		var p: Array = lonlat(d)
		key.append(int(roundf(float(p[0]) / (STEP * 2.0))))
		key.append(int(roundf(float(p[1]) / (STEP * 2.0))))
	return key


## The runs of a line of [lon, lat] points that are on the near side, as screen polylines.
static func _runs(pts: Array, clon: float, clat: float, c: Vector2, r: float) -> Array:
	var out: Array = []
	var cur := PackedVector2Array()
	for p in pts:
		var q: Vector3 = project(float(p[0]), float(p[1]), clon, clat)
		if q.z > 0.02:
			cur.append(c + Vector2(q.x, q.y) * r)
		elif cur.size() > 0:
			out.append(cur)
			cur = PackedVector2Array()
	if cur.size() > 0:
		out.append(cur)
	return out


## Draw the globe in `rect` (the HUD's map slot). `state` holds the trail; `feed` the pair now (and the land).
static func draw(ci: CanvasItem, rect: Rect2, state: Dictionary, feed: Dictionary, s: float, alpha: float) -> void:
	if rect.size.x <= 0.0 or alpha <= 0.01:
		return
	var pair: Array = feed.get("pair", [])
	var cc: Array = centre(pair)
	var clon: float = turned(float(cc[0]))
	var clat: float = turned(float(cc[1]))
	var r: float = minf(rect.size.x, rect.size.y) * 0.5
	var c: Vector2 = rect.get_center()
	var ink := Color(UiLook.col(UiLook.INK), alpha)
	var edge := Color(UiLook.col(UiLook.EDGE), 0.7 * alpha)
	ci.draw_circle(c, r, Color(UiLook.col(UiLook.SCRIM), 0.8 * alpha))
	# The land: the biome bands along the equator (the stand-in for Rendering's far map), muted so the trail reads against it.
	var W: float = float(feed.get("W", 9600.0))
	for seg in feed.get("segs", []):
		var a0: float = float(seg[0]) / W * TAU
		var a1: float = float(seg[1]) / W * TAU
		var n: int = maxi(2, int(ceil((a1 - a0) / 0.1)))
		var col := Color(UiLook.col(UiLook.BIOME.get(seg[2], "#666666")), LAND_ALPHA * alpha)
		for row in LAND_ROWS:
			var line: Array = []
			for i in range(n + 1):
				line.append([a0 + (a1 - a0) * float(i) / float(n), float(row)])
			for run in _runs(line, clon, clat, c, r):
				if (run as PackedVector2Array).size() >= 2:
					ci.draw_polyline(run, col, maxf(r * 0.2, 2.0), false)
	# The trail: a still line of the whole match, drawn over the land.
	var tr: PackedFloat32Array = state.get("trail", PackedFloat32Array())
	if tr.size() >= 4:
		var pts: Array = []
		var prev_lon: float = tr[0]
		var acc: float = tr[0]
		for i in range(0, tr.size(), 2):
			acc += wrapf(tr[i] - prev_lon, -PI, PI)   # unwrapped, so a lap is a line round the globe
			prev_lon = tr[i]
			pts.append([acc, tr[i + 1]])
		for run in _runs(pts, clon, clat, c, r):
			if (run as PackedVector2Array).size() >= 2:
				ci.draw_polyline(run, Color(0.0, 0.0, 0.0, 0.55 * alpha), maxf(3.0 * s, 3.0), true)
				ci.draw_polyline(run, ink, maxf(1.6 * s, 1.5), true)
	# The pair: a circle for the first fighter, a diamond for the second (a shape each, never a colour alone); one point when they are together.
	var tiny: float = maxf(r * 0.16, 2.5)
	var drawn: Array = []
	for i in range(pair.size()):
		var p: Array = lonlat(pair[i])
		var q: Vector3 = project(float(p[0]), float(p[1]), clon, clat)
		if q.z <= 0.02:
			continue
		var at: Vector2 = c + Vector2(q.x, q.y) * r
		var together := false
		for o in drawn:
			together = together or at.distance_to(o) < tiny * 1.2
		if together:
			continue
		drawn.append(at)
		if i == 0:
			ci.draw_circle(at, tiny * 1.35, Color(0.0, 0.0, 0.0, 0.8 * alpha))
			ci.draw_circle(at, tiny, ink)
		else:
			var d: float = tiny * 1.25
			var dia := PackedVector2Array([at + Vector2(0, -d), at + Vector2(d, 0), at + Vector2(0, d), at + Vector2(-d, 0)])
			ci.draw_colored_polygon(dia, ink)
			ci.draw_polyline(PackedVector2Array([dia[0], dia[1], dia[2], dia[3], dia[0]]), Color(0.0, 0.0, 0.0, 0.8 * alpha), 1.5, true)
	ci.draw_arc(c, r, 0.0, TAU, 40, edge, maxf(1.5 * s, 1.5), true)
