"""Shifting arena, window 1: the arena as a plane (World, scratch, parked; docs/world/shifting-arena-design.md section 3).
python mk_arena.py <root>     (root: an export of main's HEAD with planet window 2's draft applied: mk_window2.py)
 - SimConst.W, NC, HALF become statics set once in newMatch from setup.arena (the columns); the planet's own size is SimConst.PLANET_NC, fixed
 - WorldPlanet reads a ring (a small circle: axis, angular radius, side) as it reads a great circle, with today's expressions to the bit when the ring is the great circle
 - the three compile-time constants that read W are functions; DirLocation's step follows the arena's length
Lines in files that are not World's: constants.gd, sim.gd (Simulation's); director/location.gd (Encounter's)."""
import sys, shutil, os
from mk_wbc_lib import rw, rep

R = sys.argv[1].rstrip('/') + '/'


def constants(s):
    return rep(s, '''const W: float = 9600.0 * PS   # planet circumference; x wraps into [0, W)
const COL: float = 32.0        # terrain column width (0.43 fighter heights)
const NC: int = 4800           # number of terrain columns (W / COL)
const HALF: float = W / 2.0    # the largest shortest-arc separation''', '''const COL: float = 32.0        # terrain column width (0.43 fighter heights)
const PLANET_NC: int = 4800    # the planet's circumference in columns: fixed (the planet is 4,800 columns round whatever the arena is)
## The arena's length (docs/world/shifting-arena-design.md): the planet's great circle by default, or a smaller ring of a planet's plane through the pair. Set once at the top
## of newMatch from setup.arena (its columns), so a match always sets it and none is stale; absent means the planet's own 4,800.
static var W: float = 9600.0 * PS   # the arena's length: x wraps into [0, W)
static var NC: int = 4800           # number of terrain columns (W / COL)
static var HALF: float = 9600.0 * PS / 2.0    # the largest shortest-arc separation


static func setArena(cols: int) -> void:
	NC = cols
	W = float(cols) * COL
	HALF = W / 2.0''')


def sim(s):
    s = rep(s, '''	S.rng = SimRng.new(seed & 0xFFFFFFFF)
	WorldBiomes.planetCols = PackedByteArray()''', '''	S.rng = SimRng.new(seed & 0xFFFFFFFF)
	S.arenaCols = _arenaCols(setup)   # the arena's length in columns (World: a ring of the planet's; needs a planet), else the planet's 4,800
	SimConst.setArena(S.arenaCols)
	WorldBiomes.planetCols = PackedByteArray()''')
    s = rep(s, '''## One fixed step (sim.js step).''', '''## The arena's columns from the setup, guarded: setup.arena {"cols": n, "side": 1 or -1} with a setup.planet, n an even whole number from 600 to 4,800 (a ring a fight fits
## in, with a middle column); anything else is the planet's own 4,800, with an error (World: docs/world/shifting-arena-design.md section 3).
static func _arenaCols(setup: Dictionary) -> int:
	var arena = setup.get("arena", null)
	if arena == null:
		return SimConst.PLANET_NC
	var n = arena.get("cols", null) if arena is Dictionary else null
	var ok: bool = setup.has("planet") and (n is int or n is float) and float(n) == floorf(float(n)) and float(n) >= 600.0 and float(n) <= float(SimConst.PLANET_NC) and int(n) % 2 == 0
	if not ok:
		if not FighterData.quiet:
			push_error("SimCore.newMatch: setup.arena %s needs a planet and cols an even whole number from 600 to %d; the planet's own arena plays" % [str(arena), SimConst.PLANET_NC])
		return SimConst.PLANET_NC
	return int(n)


## One fixed step (sim.js step).''')
    s = rep(s, '''static func step(S: SimState, inputs = null) -> bool:
	var dtReal: float = SimConst.DT''', '''static func step(S: SimState, inputs = null) -> bool:
	if SimConst.NC != S.arenaCols or WorldBiomes.worldId != S.worldId:   # the arena's length and a planet's biomes are statics: a match takes its own again, whatever another match has built since (two sims alive in one process)
		SimConst.setArena(S.arenaCols)
		WorldBiomes.planetCols = S.planetCols
		WorldBiomes.worldId = S.worldId
	var dtReal: float = SimConst.DT''')
    s = rep(s, '''		WorldTerrain.genWorld(S)
	S.contactOn''', '''		WorldTerrain.genWorld(S)
	S.planetCols = WorldBiomes.planetCols   # the statics a world sets belong to this match: step takes them again when another match has built since
	S.worldId = WorldBiomes.claim()
	S.contactOn''')
    s = rep(s, '''float(WorldPlanet.TOUCH_COL) * SimConst.COL''', '''float(WorldPlanet.touchCol()) * SimConst.COL''')
    return s


def state(s):
    return rep(s, '''var contactOn: bool = false           # ground contact on''', '''var arenaCols: int = 4800            # World: this match's arena length in columns (SimConst.setArena; newMatch sets it, step sets the static again when another match has changed it). Not hashed
var planetCols := PackedByteArray()  # World: this match's planet world's biome by column (WorldBiomes.planetCols), kept for the same reason; empty for the hand-made world. Not hashed
var worldId: int = 0                 # World: which world this match built (WorldBiomes.claim); step compares it with the last built. Not hashed
var contactOn: bool = false           # ground contact on''')


def biomes(s):
    return rep(s, '''static var planetCols := PackedByteArray()
''', '''static var planetCols := PackedByteArray()
static var worldId: int = 0   # the last world a match built (SimCore.newMatch: claim); a match's step takes its own tables again when this is not its id
static var _ids: int = 0


## A new id for the world a match is building, which is now the current one.
static func claim() -> int:
	_ids += 1
	worldId = _ids
	return worldId
''')


def planet(s):
    s = rep(s, '''const TOUCH_COL := SimConst.NC / 2       # the touch-down is the middle column of its slice (the seam is the antipode)
''', '''## The touch-down is the middle column of its slice (the seam is the antipode); the slice is the arena's columns (SimConst.NC).
static func touchCol() -> int:
	return SimConst.NC / 2
''')
    s = rep(s, '''	P.L = float(SimConst.NC) * SimConst.COL''', '''	P.L = float(SimConst.PLANET_NC) * SimConst.COL''')
    s = rep(s, '''## The point at column i of the circle: the middle column is T, a column is SimConst.COL units of arc.
static func columnPoint(P: Planet, circ: Dictionary, i: int) -> Array:
	var ang: float = float(i - TOUCH_COL) * SimConst.COL / P.R
	var co: float = SimDetMath.cos(ang)
	var si: float = SimDetMath.sin(ang)
	var u: Array = circ.u
	var v: Array = circ.v
	return [u[0] * co + v[0] * si, u[1] * co + v[1] * si, u[2] * co + v[2] * si]
''', '''## A ring of the arena's length (docs/world/shifting-arena-design.md section 1): the small circle through the great circle's touch-down T (= circ.u), tangent to it there, of
## `cols` columns, on the left (side 1, towards the great circle's normal) or the right of it. Its radius is sin(theta) = cols / 4,800 of the planet's, so a column is exactly
## SimConst.COL of arc and the ring closes. Returns the same dictionary shape as circleOf (u: the direction from the centre to T, v: the travel direction, n: the axis) plus
## c (the axis), st and ct (sin and cos of the angular radius), th (the radius) and s (the side), which read as "a ring". cols of 4,800 or more is the great circle itself.
static func ringThrough(circ: Dictionary, cols: int, side: int) -> Dictionary:
	var st: float = float(cols) / float(SimConst.PLANET_NC)
	if st >= 1.0:
		return circ
	var ct: float = sqrt(1.0 - st * st)
	var s: float = 1.0 if side >= 0 else -1.0
	var n: Array = circ.n
	var t: Array = circ.u
	var c: Array = _unit([t[0] * ct + n[0] * (s * st), t[1] * ct + n[1] * (s * st), t[2] * ct + n[2] * (s * st)])
	var e1: Array = _unit([t[0] * st - n[0] * (s * ct), t[1] * st - n[1] * (s * ct), t[2] * st - n[2] * (s * ct)])
	return {"u": e1, "v": circ.v, "n": c, "c": c, "st": st, "ct": ct, "th": asinf(st), "s": s}


## A place's signed lateral offset from the line (units, left of the line positive): from a great circle by its normal, from a ring by its angular radius.
static func lateral(P: Planet, circ: Dictionary, x: float, y: float, z: float) -> float:
	if circ.has("st"):
		var c: Array = circ.c
		return circ.s * P.R * (circ.th - acosf(SimMathx.jclamp(c[0] * x + c[1] * y + c[2] * z, -1.0, 1.0)))
	var n: Array = circ.n
	return P.R * asinf(n[0] * x + n[1] * y + n[2] * z)


## The point at column i of the circle: the middle column is T, a column is SimConst.COL units of arc.
static func columnPoint(P: Planet, circ: Dictionary, i: int) -> Array:
	var stf: float = circ.get("st", 1.0)
	var ang: float = float(i - touchCol()) * SimConst.COL / (P.R * stf)
	var co: float = SimDetMath.cos(ang)
	var si: float = SimDetMath.sin(ang)
	var u: Array = circ.u
	var v: Array = circ.v
	if circ.has("st"):
		var c: Array = circ.c
		var ct: float = circ.ct
		return [c[0] * ct + stf * (u[0] * co + v[0] * si), c[1] * ct + stf * (u[1] * co + v[1] * si), c[2] * ct + stf * (u[2] * co + v[2] * si)]
	return [u[0] * co + v[0] * si, u[1] * co + v[1] * si, u[2] * co + v[2] * si]
''')
    # readSlice
    s = rep(s, '''	var u: Array = circ.u
	var v: Array = circ.v
	for i in range(nc):
		var ang: float = float(i - TOUCH_COL) * SimConst.COL / P.R
		var co: float = SimDetMath.cos(ang)
		var si: float = SimDetMath.sin(ang)
		var qx: float = u[0] * co + v[0] * si
		var qy: float = u[1] * co + v[1] * si
		var qz: float = u[2] * co + v[2] * si
		surfAt(P, qx, qy, qz)''', '''	var u: Array = circ.u
	var v: Array = circ.v
	var small: bool = circ.has("st")
	var stf: float = circ.get("st", 1.0)
	var ct: float = circ.get("ct", 0.0)
	var ca: Array = circ.get("c", u)
	var tc: int = touchCol()
	for i in range(nc):
		var ang: float = float(i - tc) * SimConst.COL / (P.R * stf)
		var co: float = SimDetMath.cos(ang)
		var si: float = SimDetMath.sin(ang)
		var qx: float = u[0] * co + v[0] * si
		var qy: float = u[1] * co + v[1] * si
		var qz: float = u[2] * co + v[2] * si
		if small:
			qx = ca[0] * ct + stf * qx
			qy = ca[1] * ct + stf * qy
			qz = ca[2] * ct + stf * qz
		surfAt(P, qx, qy, qz)''')
    s = rep(s, '''	var n: Array = circ.n
	for i in range(P.n):
		var lat: float = P.R * asinf(n[0] * P.px[i] + n[1] * P.py[i] + n[2] * P.pz[i])
		var reach: float = (c.cityReach if P.kind[i] == KIND_CITY else c.townReach) * P.rad[i]
		if absf(lat) >= reach:
			continue
		var along: float = atan2f(P.px[i] * v[0] + P.py[i] * v[1] + P.pz[i] * v[2], P.px[i] * u[0] + P.py[i] * u[1] + P.pz[i] * u[2])
		var col: int = TOUCH_COL + int(floor(along * P.R / SimConst.COL + 0.5))''', '''	for i in range(P.n):
		var lat: float = lateral(P, circ, P.px[i], P.py[i], P.pz[i])
		var reach: float = (c.cityReach if P.kind[i] == KIND_CITY else c.townReach) * P.rad[i]
		if absf(lat) >= reach:
			continue
		var along: float = atan2f(P.px[i] * v[0] + P.py[i] * v[1] + P.pz[i] * v[2], P.px[i] * u[0] + P.py[i] * u[1] + P.pz[i] * u[2])
		var col: int = tc + int(floor(along * (P.R * stf) / SimConst.COL + 0.5))''')
    # sliceFor: cols and side
    s = rep(s, '''static func sliceFor(seed: int, touch: int, standing: PackedByteArray = PackedByteArray(), relaxed: bool = false) -> Slice:
	var key: String = "%d/%d/%s/%d/%s" % [seed, touch, str(standing.hex_encode()), 1 if relaxed else 0, dataHash()]''', '''static func sliceFor(seed: int, touch: int, standing: PackedByteArray = PackedByteArray(), relaxed: bool = false, side: int = 1) -> Slice:
	var key: String = "%d/%d/%s/%d/%s/%d/%d" % [seed, touch, str(standing.hex_encode()), 1 if relaxed else 0, dataHash(), SimConst.NC, side]''')
    s = rep(s, '''	var S: Slice = readSlice(P, r.circle, r.T, standing)
	if _slices.size() > 4:''', '''	var S: Slice = readSlice(P, ringThrough(r.circle, SimConst.NC, side), r.T, standing)   # the arena's columns: the great circle itself at 4,800, else a ring through the touch-down
	if _slices.size() > 4:''')
    # wearMarks
    s = rep(s, '''	var u: Array = S.circ.u
	var v: Array = S.circ.v
	var n: Array = S.circ.n
	var nc: int = SimConst.NC
	var band: float = c.bandUnits''', '''	var u: Array = S.circ.u
	var v: Array = S.circ.v
	var stf: float = S.circ.get("st", 1.0)
	var nc: int = SimConst.NC
	var band: float = c.bandUnits''')
    s = rep(s, '''		var lat: float = P.R * asinf(n[0] * q[0] + n[1] * q[1] + n[2] * q[2])
		if absf(lat) > band + float(q[3]) / 16.0:
			continue
		var along: float = atan2f(q[0] * v[0] + q[1] * v[1] + q[2] * v[2], q[0] * u[0] + q[1] * u[1] + q[2] * u[2])
		var col: int = TOUCH_COL + int(floor(along * P.R / SimConst.COL + 0.5))''', '''		var lat: float = lateral(P, S.circ, q[0], q[1], q[2])
		if absf(lat) > band + float(q[3]) / 16.0:
			continue
		var along: float = atan2f(q[0] * v[0] + q[1] * v[1] + q[2] * v[2], q[0] * u[0] + q[1] * u[1] + q[2] * u[2])
		var col: int = touchCol() + int(floor(along * (P.R * stf) / SimConst.COL + 0.5))''')
    assert 'TOUCH_COL' not in s
    return s


def planet_check(s):
    return rep(s, 'WorldPlanet.TOUCH_COL', 'WorldPlanet.touchCol()')


def planet_world(s):
    return rep(s, '''	var sl: WorldPlanet.Slice = WorldPlanet.sliceFor(seed, touch)''', '''	var arena = setup.get("arena", {})
	var sl: WorldPlanet.Slice = WorldPlanet.sliceFor(seed, touch, PackedByteArray(), false, int(arena.get("side", 1)) if arena is Dictionary else 1)   # the arena's columns are SimConst.NC (newMatch set them)''')


def collateral(s):
    s = rep(s, '''const HIST_STEP: float = SimConst.W / 48.0
''', '''''')
    s = rep(s, '''	return mini(int(SimWrap.wrap(x) / HIST_STEP), HIST_BUCKETS - 1)''', '''	return mini(int(SimWrap.wrap(x) / (SimConst.W / 48.0)), HIST_BUCKETS - 1)   # one bucket is a 48th of the arena (director/location.gd STEP)''')
    return s


def structures(s):
    s = rep(s, '''const BUCKET_W: float = SimConst.W / 128.0
''', '''''')
    s = rep(s, '''		var k: int = mini(int(SimWrap.wrap(b.x) / BUCKET_W), BUCKETS - 1)''', '''		var k: int = mini(int(SimWrap.wrap(b.x) / (SimConst.W / 128.0)), BUCKETS - 1)''')
    s = rep(s, '''	var k0: int = int(floor((SimWrap.wrap(x) - reach) / BUCKET_W))
	var k1: int = int(floor((SimWrap.wrap(x) + reach) / BUCKET_W))''', '''	var bw: float = SimConst.W / 128.0   # a bucket is a 128th of the arena
	var k0: int = int(floor((SimWrap.wrap(x) - reach) / bw))
	var k1: int = int(floor((SimWrap.wrap(x) + reach) / bw))''')
    assert 'BUCKET_W' not in s
    return s


def location(s):
    s = rep(s, '''const STEP: float = 200.0 * SimConst.PS   # one histogram bucket: SimConst.W / BUCKETS''', '''static var STEP: float = 200.0 * SimConst.PS   # one histogram bucket: SimConst.W / BUCKETS (set in _ensure: the arena's length can change)
static var _key: String = ""''')
    s = rep(s, '''static func _ensure() -> void:
	if _d != null:
		return
	_text = FileAccess.get_file_as_string(PATH)
	_d = JSON.parse_string(_text)
	if _d == null:
		push_error("DirLocation: could not parse " + PATH)
		_d = {}
	_planet.resize(BIOMES.size())
	_planet.fill(0.0)
	for sg in WorldBiomes.SEG:
		_planet[BIOMES.find(sg[2])] += (sg[1] - sg[0]) / SimConst.W
	_bucketBiome.resize(BUCKETS)''', '''static func _ensure() -> void:
	if _d == null:
		_text = FileAccess.get_file_as_string(PATH)
		_d = JSON.parse_string(_text)
		if _d == null:
			push_error("DirLocation: could not parse " + PATH)
			_d = {}
	# the tables follow the arena's length and a planet's world: rebuilt when either changes (a match on the hand-made world keeps today's)
	var key: String = "%s/%d" % [str(SimConst.W), WorldBiomes.worldId]
	if key == _key:
		return
	_key = key
	STEP = SimConst.W / float(BUCKETS)
	_planet.resize(BIOMES.size())
	_planet.fill(0.0)
	for sg in WorldBiomes.SEG:
		_planet[BIOMES.find(sg[2])] += (sg[1] - sg[0]) / (9600.0 * SimConst.PS)
	_bucketBiome.resize(BUCKETS)''')
    return s


rw(R, 'sim/core/constants.gd', constants)
rw(R, 'sim/core/sim.gd', sim)
rw(R, 'sim/core/state.gd', state)
rw(R, 'sim/world/biomes.gd', biomes)
rw(R, 'sim/world/planet.gd', planet)
rw(R, 'sim/world/tools/planet_check.gd', planet_check)
rw(R, 'sim/world/tools/planet_world_check.gd', planet_check)   # (the same one-token change: TOUCH_COL is a function now)
rw(R, 'sim/world/planet_world.gd', planet_world)
rw(R, 'sim/world/collateral.gd', collateral)
rw(R, 'sim/world/structures.gd', structures)
rw(R, 'sim/director/location.gd', location)
print('arena window 1 applied')
