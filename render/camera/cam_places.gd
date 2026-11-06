class_name CamPlaces
extends RefCounted
## The camera's one door to where places are while the world turns (docs/camera/swing-view.md), on Simulation's arena API
## (docs/world/ring-any-angle/simulation.md section 11). `S.frame` says which great circle the fight's line lies on; on gen 3 the sim poses
## buildings near the fighters as it turns, so `b.x` and `b.z` already read the view. A thing that keeps its own planet point (a mark once
## it's a record) reads through the frame here. Pure reads: nothing here writes the sim or holds match state.
##
## With the switch off or off gen 3 (`S.frame` null) the rig doesn't come here at all and reads the strip as it always has.

## A check's frame, swing, biome and tall land, in place of the sim's (Callables).
static var frame_source: Callable = Callable()
static var swing_source: Callable = Callable()
static var biome_source: Callable = Callable()
static var land_source: Callable = Callable()

const _DATA: String = "res://data/camera/swing.json"
static var _d = null


## Camera's numbers a reading can move (data/camera/swing.json).
static func data() -> Dictionary:
	if _d == null:
		var j = JSON.parse_string(FileAccess.get_file_as_string(_DATA))
		if not (j is Dictionary):
			push_error("CamPlaces: could not parse " + _DATA)
			j = {}
		_d = j
	return _d

const _TALL_RINGS: Array = [0.5, 1.0]
const _TALL_SPOKES: int = 8

static var _field_script = null
static var _field_looked: bool = false


## SimField when it's in the build: this door is the camera's only reference to it, so the park can land before or after it.
static func _field():
	if not _field_looked:
		_field_looked = true
		for c in ProjectSettings.get_global_class_list():
			if String(c["class"]) == "SimField":
				_field_script = load(String(c["path"]))
	return _field_script


## The frame as [point x, y, z, heading x, y, z, its column's x], or empty when there is none.
static func frame_of(S: SimState) -> PackedFloat64Array:
	if frame_source.is_valid():
		return frame_source.call(S)
	var fr = S.get("frame")
	if fr == null:
		return PackedFloat64Array()
	return PackedFloat64Array([fr.px, fr.py, fr.pz, fr.tx, fr.ty, fr.tz, fr.x0])


## The planet's radius for this line: the line is a great circle W long.
static func radius() -> float:
	return SimConst.W / TAU


## The line's point at x, and its heading there: the frame carried along its own great circle. [px, py, pz, hx, hy, hz]
static func on_line(f: PackedFloat64Array, x: float) -> PackedFloat64Array:
	var a: float = SimWrap.sdx(f[6], x) / radius()
	var c: float = cos(a)
	var s: float = sin(a)
	return PackedFloat64Array([
		c * f[0] + s * f[3], c * f[1] + s * f[4], c * f[2] + s * f[5],
		c * f[3] - s * f[0], c * f[4] - s * f[1], c * f[5] - s * f[2]])


## Toward the camera on the line: the same at every x, because a great circle has one axis. Rendering's `sd`: heading cross point.
static func side(f: PackedFloat64Array) -> Vector3:
	return Vector3(f[3], f[4], f[5]).cross(Vector3(f[0], f[1], f[2]))


## Where a planet point is in the view from the line's point at x_from: (signed distance along the line, depth toward the camera),
## on Rendering's projection (azimuthal equidistant about that point), so the rig and the drawn world agree at any radius.
static func view_of(f: PackedFloat64Array, x_from: float, p: Array) -> Vector2:
	var q: PackedFloat64Array = on_line(f, x_from)
	var sv: Vector3 = side(f)
	var vx: float = p[0] * q[3] + p[1] * q[4] + p[2] * q[5]
	var vz: float = p[0] * sv.x + p[1] * sv.y + p[2] * sv.z
	var vp: float = p[0] * q[0] + p[1] * q[1] + p[2] * q[2]
	var s: float = sqrt(vx * vx + vz * vz)
	var k: float = atan2(s, vp) / s if s > 1.0e-9 else 1.0
	var r: float = radius()
	return Vector2(vx * k * r, vz * k * r)


## A building's or a mark's place in the view from x_from: (signed distance, depth). Through the frame when it has its own point (`anchor`, a
## mark as a record). A building in a running swing reads its planet point too, since the sim poses only those near the pivot until rest
## (SimSwing's reach) and a pane on a far fighter can look past that. Otherwise where the sim poses it.
static func place(S: SimState, f: PackedFloat64Array, x_from: float, thing, x: float, z: float = 0.0) -> Vector2:
	var an = thing.get("anchor") if thing is Object else thing.get("anchor", null)
	if an != null:
		return view_of(f, x_from, an)
	var sw = S.get("swing")
	if sw != null and bool(sw.active) and thing is SimState.Building:
		var dirs = S.get("bDir")
		var i: int = int(thing.idx) * 3
		if dirs != null and i + 2 < dirs.size():
			return view_of(f, x_from, [dirs[i], dirs[i + 1], dirs[i + 2]])
	return Vector2(SimWrap.sdx(x_from, x), z)


## The biome under the line at x: WorldBiomes follows the frame on a field world.
static func biome(S: SimState, x: float) -> String:
	if biome_source.is_valid():
		return biome_source.call(S, x)
	return WorldBiomes.biomeAt(x)


## The same frame with its heading turned by a radians about its own column: what the swing's own turn does, and what the shown heading adds.
static func turned(f: PackedFloat64Array, a: float) -> PackedFloat64Array:
	if a == 0.0:
		return f
	var sv: Vector3 = side(f)
	var c: float = cos(a)
	var s: float = sin(a)
	return PackedFloat64Array([f[0], f[1], f[2], c * f[3] + s * sv.x, c * f[4] + s * sv.y, c * f[5] + s * sv.z, f[6]])


## How far the line turned from frame a to frame b, signed as `turned` turns: the angle between the two great circles' axes.
static func turn_between(a: PackedFloat64Array, b: PackedFloat64Array) -> float:
	var na: Vector3 = side(a)
	var nb: Vector3 = side(b)
	var cr: Vector3 = na.cross(nb)
	return atan2(-(cr.x * b[0] + cr.y * b[1] + cr.z * b[2]), na.dot(nb))


## The sim's running swing: {cause, toGo (radians still to turn)}, {} at rest. `S.swing.left` is signed degrees.
static func swing_of(S: SimState) -> Dictionary:
	if swing_source.is_valid():
		return swing_source.call(S)
	var sw = S.get("swing")
	if sw == null or not bool(sw.active):
		return {}
	return {"cause": String(sw.cause), "toGo": deg_to_rad(float(sw.left))}


## Tall land round x within r (Game Design's fixed test, height only): the bake's heights on two rings of points, on the view's own line.
static func land_tall(S: SimState, x: float, r: float, tall: float) -> bool:
	if land_source.is_valid():
		return land_source.call(S, x, r)
	var F = _field()
	if F == null or S.get("frame") == null:
		return false
	var base: float = WorldTerrain.groundY(S, x)
	for ring in _TALL_RINGS:
		for k in range(_TALL_SPOKES):
			var a: float = TAU * float(k) / float(_TALL_SPOKES)
			F.placeAt(S, SimWrap.wrap(x + float(ring) * r * cos(a)), float(ring) * r * sin(a))
			if F.heightOf(S.frame.seed, S.frame.gen, 0, F.ox, F.oy, F.oz) - base > tall:
				return true
	return false
