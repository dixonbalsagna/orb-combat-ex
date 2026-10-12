class_name RenderLanes
extends RefCounted
## World's lane table for the renderer (ADR 0009; docs/world/fight-lanes-world.md sections 2 and 10; World's
## docs/world/rendering-brief-lanes.md): the band of two streets and two block rows, the street strips (sidewalk, kerb
## parking, carriageway), the districts' x intervals and the avenues that cross the blocks. It is S.lanes, a flat packed
## array the sim derives with the world (not hashed). Reads the sim only; never writes it.
##
## The array (World's layout): a header of 13 floats (version, nLanes, nStrips, nDistricts, nAvenues, nRows, rowZ0,
## rowStep, zFront, zBack, offLanes, offStrips, offDistricts); lanes, 4 floats each (zTop, zBottom, kind: 0 street, 1
## block, 2 scenery, 3 ridge, row); strips, 4 each (lane, zTop, zBottom, kind: 0 sidewalk, 1 kerb parking, 2
## carriageway); districts, 6 each (x0, x1, look, laneMask, traffic, settlement); avenues, 3 each (x0, x1, district),
## after the districts.

const HEADER := 13
const NONE: Array = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 13.0, 13.0, 13.0]   # a table with nothing in it


## The lane table: the sim's, or an empty one for a world with no settlements (nothing is painted then).
static func table(S: SimState) -> PackedFloat32Array:
	var t: PackedFloat32Array = S.lanes
	return t if t.size() >= HEADER else PackedFloat32Array(NONE)


## The street strips for the ground shader: (zTop, zBottom, kind, the street's centre z), at most `cap`.
static func strips(t: PackedFloat32Array, cap: int) -> Array:
	var out: Array = []
	var off_lanes: int = int(t[10])
	var off_strips: int = int(t[11])
	for k in range(mini(int(t[2]), cap)):
		var o: int = off_strips + 4 * k
		var lane: int = off_lanes + 4 * int(t[o])
		out.append(Vector4(t[o + 1], t[o + 2], t[o + 3], (t[lane] + t[lane + 1]) * 0.5))
	return out


## The districts' x intervals for the ground shader: (x0, x1, laneMask, look), at most `cap` (the widest first).
static func districts(t: PackedFloat32Array, cap: int) -> Array:
	var out: Array = []
	var off: int = int(t[12])
	for k in range(int(t[3])):
		var o: int = off + 6 * k
		out.append(Vector4(t[o], t[o + 1], t[o + 3], t[o + 2]))
	if out.size() > cap:
		out.sort_custom(func(a, b): return a.y - a.x > b.y - b.x)
		out.resize(cap)
	return out


## The avenues, the cross streets that part the blocks, for the ground shader: (x0, x1, their district, 0), at most `cap`.
static func avenues(t: PackedFloat32Array, cap: int) -> Array:
	var out: Array = []
	var off: int = int(t[12]) + 6 * int(t[3])
	for k in range(mini(int(t[4]), cap)):
		var o: int = off + 3 * k
		if o + 2 < t.size():
			out.append(Vector4(t[o], t[o + 1], t[o + 2], 0.0))
	return out


## The block lanes (kind 1) for the ground shader's paved lots: (zTop, zBottom) each, front to back, at most two.
static func blocks(t: PackedFloat32Array) -> Array:
	var out: Array = []
	var off: int = int(t[10])
	for k in range(int(t[1])):
		var o: int = off + 4 * k
		if int(t[o + 2]) == 1 and out.size() < 2:
			out.append(Vector2(t[o], t[o + 1]))
	return out


## The fighters' band, front to back (zFront, zBack).
static func band(t: PackedFloat32Array) -> Vector2:
	return Vector2(t[8], t[9])
