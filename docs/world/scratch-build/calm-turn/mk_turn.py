"""Shifting arena, window 3: the calm-moment turn (World, scratch, parked; docs/world/shifting-arena-design.md section 4, docs/world/calm-turn-world.md).
python mk_turn.py <root> <epoch.gd> <planet_world_tail.gd>     (root: main with windows 0, 1, 4 and farColumn applied)
 - sim/world/epoch.gd (WorldEpoch): the geometry of a turn, the candidates, ask/choose/prewarm/tick, World's calm check, the swap
 - WorldPlanet: readSlice in three steps (begin, columns, held: the same result) and RingJob, a stepped read of a ring; memoRing
 - WorldPlanetWorld: gen split into chordsOf, settleBiomes, platform, settle (the same world) and the epoch's start
 - data/biomes/rings.json: a `turn` block (off), its schema; Tools' case
 - WorldContact: the surface class per column is rebuilt for each world a match builds (a fix to windows 0 and 1: it was built once, so a planet world or a smaller arena read stale or short columns)
 - Simulation's lines: state.gd (S.epoch), hash.gd (the epoch's three numbers, the arena_turn event's fields), view/fx.gd (the event), sim.gd (S.epoch reset; the tick)"""
import sys, shutil, json, collections
from mk_wbc_lib import rw, rep
OD = collections.OrderedDict
R = sys.argv[1].rstrip('/') + '/'
shutil.copyfile(sys.argv[2], R + 'sim/world/epoch.gd')
tail = open(sys.argv[3], encoding='utf-8').read()


def planet(s):
    i = s.index("static func readSlice(P: Planet, circ: Dictionary, T: Array, standing: PackedByteArray = PackedByteArray()) -> Slice:")
    j = s.index("## The slice memoised outside the sim state")
    new = '''static func readSlice(P: Planet, circ: Dictionary, T: Array, standing: PackedByteArray = PackedByteArray()) -> Slice:
	var S: Slice = readBegin(P, circ, T)
	readColumns(P, S, 0, SimConst.NC)
	readHeld(P, S, standing)
	return S


## The read in three steps (a host spends a few columns a frame: RingJob; the module owns no clock). readSlice is these three in order, so a stepped read is the same slice.
static func readBegin(P: Planet, circ: Dictionary, T: Array) -> Slice:
	var S := Slice.new()
	S.seed = P.seed
	S.circ = circ
	S.T = T
	var nc: int = SimConst.NC
	S.heights.resize(nc)
	S.biomes.resize(nc)
	return S


## Columns i0 up to i1 (exclusive) of the slice.
static func readColumns(P: Planet, S: Slice, i0: int, i1: int) -> void:
	var c: Dictionary = P.c
	var circ: Dictionary = S.circ
	var u: Array = circ.u
	var v: Array = circ.v
	var small: bool = circ.has("st")
	var stf: float = circ.get("st", 1.0)
	var ct: float = circ.get("ct", 0.0)
	var ca: Array = circ.get("c", u)
	var tc: int = touchCol()
	for i in range(i0, i1):
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
		surfAt(P, qx, qy, qz)
		var h: float = P.outH
		var b: int = P.outB
		if b >= BIO_PLAINS and b <= BIO_MOUNTAINS:
			h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp
		elif b == BIO_ICE_SHEET and h > 100.0:
			h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp * c.detailSheet
		S.heights[i] = h
		S.biomes[i] = b


## The places the line holds, with their nearest column and lateral offset.
static func readHeld(P: Planet, S: Slice, standing: PackedByteArray = PackedByteArray()) -> void:
	var c: Dictionary = P.c
	var circ: Dictionary = S.circ
	var u: Array = circ.u
	var v: Array = circ.v
	var stf: float = circ.get("st", 1.0)
	var nc: int = SimConst.NC
	var tc: int = touchCol()
	for i in range(P.n):
		var lat: float = lateral(P, circ, P.px[i], P.py[i], P.pz[i])
		var reach: float = (c.cityReach if P.kind[i] == KIND_CITY else c.townReach) * P.rad[i]
		if absf(lat) >= reach:
			continue
		var along: float = atan2f(P.px[i] * v[0] + P.py[i] * v[1] + P.pz[i] * v[2], P.px[i] * u[0] + P.py[i] * u[1] + P.pz[i] * u[2])
		var col: int = tc + int(floor(along * (P.R * stf) / SimConst.COL + 0.5))
		col = ((col % nc) + nc) % nc
		var half: float = sqrt(maxf(0.0, P.rad[i] * P.rad[i] - lat * lat))
		S.held.append({"id": i, "kind": int(P.kind[i]), "col": col, "d": lat, "half": half, "r": P.rad[i],
			"standing": standing.size() == 0 or standing[i] != 0})


## A stepped read of a ring (WorldEpoch.prewarm): `step(n)` reads n more columns; at the end the places. `slice` is readSlice's answer once `done`.
class RingJob extends RefCounted:
	var P: WorldPlanet.Planet
	var ring: Dictionary
	var slice: WorldPlanet.Slice
	var i: int = 0
	var done: bool = false

	func _init(p: WorldPlanet.Planet, r: Dictionary) -> void:
		P = p
		ring = r
		slice = WorldPlanet.readBegin(P, ring, ring.u)

	func step(n: int) -> bool:
		if done:
			return true
		var j: int = mini(SimConst.NC, i + n)
		WorldPlanet.readColumns(P, slice, i, j)
		i = j
		if i >= SimConst.NC:
			WorldPlanet.readHeld(P, slice)
			done = true
		return done


'''
    s = s[:i] + new + s[j:]
    s = rep(s, '''static func sliceRing(seed: int, ring: Dictionary, standing: PackedByteArray = PackedByteArray()) -> Slice:
	var key: String = "ring/%d/%s/%s/%s/%d" % [seed, str(ring.c), str(ring.u), str(standing.hex_encode()), SimConst.NC]
	if _slices.has(key):''', '''static func _ringKey(seed: int, ring: Dictionary, standing: PackedByteArray) -> String:
	return "ring/%d/%s/%s/%s/%d" % [seed, str(ring.c), str(ring.u), str(standing.hex_encode()), SimConst.NC]


## A ring's slice read in steps is put where sliceRing finds it.
static func memoRing(seed: int, ring: Dictionary, slice: Slice) -> void:
	if _slices.size() > 4:
		_slices.clear()
	_slices[_ringKey(seed, ring, PackedByteArray())] = slice


static func sliceRing(seed: int, ring: Dictionary, standing: PackedByteArray = PackedByteArray()) -> Slice:
	var key: String = _ringKey(seed, ring, standing)
	if _slices.has(key):''')
    return s


def planet_world(s):
    i = s.index("static func gen(S: SimState, setup: Dictionary) -> bool:")
    return s[:i] + tail


def rings_cfg(s):
    return rep(s, '''	for k in ["stride", "biomeShare"''', '''	if not (j.get("turn") is Dictionary):
		_cErrors.append("rings.json: turn is an object")
	for k in ["stride", "biomeShare"''')


def sim(s):
    s = rep(s, '''	WorldBiomes.planetCols = PackedByteArray()
''', '''	WorldBiomes.planetCols = PackedByteArray()
	S.epoch = null   # World's calm-moment turn (world/epoch.gd): a planet match with it on sets it
''')
    s = rep(s, '''	S.T += dt
	if S.hitstopOn:''', '''	S.T += dt
	if S.epoch != null:
		WorldEpoch.tick(S)   # the calm-moment turn: swap when decided, held (Encounter's DirCalm.hold, once it exists) and calm
	if S.hitstopOn:''')
    return s


def state(s):
    return rep(s, '''var contactOn: bool = false           # ground contact on''', '''var epoch = null                      # World: the calm-moment turn's state (world/epoch.gd), a Dictionary while the arena may turn, else null. Hashed (hash.gd) only while set: the turns made (n), the last turn's time, the drift, the ring's slice hash, and for a decided turn its bearing, pivot column, how many of its rings are read, k and the fallback bearing
var contactOn: bool = false           # ground contact on''')


def hashf(s):
    s = rep(s, '''	out.append(1.0 if S.contactOn else 0.0)   # World's ground contact (G2)
''', '''	out.append(1.0 if S.contactOn else 0.0)   # World's ground contact (G2)
	if S.epoch != null:   # World's calm-moment turn: only a match that can turn hashes it, so a match without it hashes as before. The count, the last turn's time, the drift, whether a turn is decided
		out.append(float(S.epoch.n)); out.append(S.epoch.lastT); out.append(S.epoch.drift)   # (and its bearing and pivot column), and the hash of the ring's slice: the world the match is on
		out.append(1.0 if S.epoch.next != null else 0.0)
		if S.epoch.next != null:
			out.append(S.epoch.next.bearing); out.append(float(S.epoch.next.pc)); out.append(float(WorldEpoch.warmAngles(S).size()))   # and how many of its rings are read: when a swap may happen
			out.append(float(S.epoch.next.k)); out.append(S.epoch.next.fb)   # and how it is warmed (the columns a tick, the second ring's bearing)
		out.append(float(S.epoch.sh))
''')
    s = rep(s, '''"interior_contact": [''', '''"arena_turn": ["n", "x", "amount", "k"], "interior_contact": [''')
    return s


def viewfx(s):
    return rep(s, '"crowd_state", "building_hit":', '"crowd_state", "building_hit", "arena_turn":')   # the end of the pass list: other events are added in its middle


def rings_json(p):
    d = json.load(open(p, encoding='utf-8'), object_pairs_hook=OD)
    d['turn'] = OD([("on", 0), ("maxTurns", 4), ("gapSeconds", 60.0), ("driftDeg", 40.0), ("bearings", [2.5, 5.0, 7.5, 10.0]), ("carryUnits", 12000.0), ("viewUnits", 16000.0), ("moveMax", 300.0), ("minDeg", 2.0), ("warmCols", 32), ("fallbackDeg", 2.5)])
    d['_about'] = d['_about'] + " turn: the calm-moment turn (docs/world/calm-turn-world.md; WorldEpoch; Game Design rulings-2026-10-19b.md 1a to 1d): on 0 or 1 (off), maxTurns a fight, gapSeconds of fight time between turns, driftDeg the most the ring's axis may move in all, bearings the candidate turns in degrees (none over 10), carryUnits how far each way from the pair the ground, craters and buildings stay, viewUnits how far each way a turn counts the places it brings into view, moveMax the most the ground under a fighter may move at a turn (a turn about a mispredicted pivot is scaled down to it: Game Design 2026-10-22 5a) minDeg the least angle it is scaled to warmCols the columns of each of a decided turn's rings the sim reads a tick and fallbackDeg the bearing of the second ring it warms (Encounter's pick may set its own)."
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(d, indent=2) + '\n')


def rings_schema(p):
    j = json.load(open(p, encoding='utf-8'), object_pairs_hook=OD)
    j['required'].append('turn')
    num = lambda lo, hi, desc: OD([("type", "number"), ("minimum", lo), ("maximum", hi), ("description", desc)])
    j['properties']['turn'] = OD([("type", "object"), ("required", ["on", "maxTurns", "gapSeconds", "driftDeg", "bearings", "carryUnits", "viewUnits", "moveMax", "minDeg", "warmCols", "fallbackDeg"]), ("additionalProperties", False), ("properties", OD([
        ("on", OD([("enum", [0, 1]), ("description", "The calm-moment turn: 0 off, 1 on.")])),
        ("maxTurns", OD([("type", "integer"), ("minimum", 0), ("maximum", 12), ("description", "Turns a fight (Game Design: 4).")])),
        ("gapSeconds", num(0, 600, "Fight seconds between turns (Game Design: 60).")),
        ("driftDeg", num(0, 90, "The most the ring's axis may move in all, in degrees (Game Design: 40).")),
        ("bearings", OD([("type", "array"), ("minItems", 1), ("maxItems", 8), ("items", num(0.5, 10, "A candidate turn in degrees: none over 10 (Game Design).")), ("description", "The candidate bearings.")])),
        ("carryUnits", num(1000, 40000, "How far each way from the pair the ground and its marks and buildings stay.")),
        ("viewUnits", num(1000, 40000, "How far each way a turn counts the places it brings into view.")),
        ("moveMax", num(0, 5000, "The most the ground under a fighter may move at a turn, in units (Game Design: 300): a turn about a mispredicted pivot is scaled down to it.")),
        ("minDeg", num(0.1, 10, "The least angle a turn is scaled to (Game Design: 2 degrees).")),
        ("warmCols", OD([("type", "integer"), ("minimum", 1), ("maximum", 4800), ("description", "The columns of each of a decided turn's rings the sim reads a tick, unless Encounter's pick brings its own (16 to 32). 32 reads a Whole ring in 150 ticks.")])),
        ("fallbackDeg", num(0, 10, "The bearing in degrees of the second ring a decided turn warms (a landing off the pivot falls back to it), unless Encounter's pick brings its own; 0 for none."))]))])
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2) + '\n')


def cases(s):
    a = '''    {
      "id": "rings-minimum-land-over-one",'''
    b = '''    {
      "id": "rings-turn-bearing-over-10",
      "schema": "biomes-rings.schema.json",
      "mutate": [
        {
          "file": "data/biomes/rings.json",
          "set": {
            "/turn/bearings/3": 12
          }
        }
      ],
      "expect": {
        "rule": "maximum",
        "pointer": "/turn/bearings/3"
      }
    },
''' + a
    return rep(s, a, b)


def contact(s):
    # a planet world's biomes are per match (WorldBiomes.planetCols), and so is a ring's length: the surface class of each column is built for the world a match built, not once
    s = rep(s, '''	# the biome's surface per terrain column: the biome layout is fixed, so this is built once
	_colSurf.resize(SimConst.NC)
	for i in range(SimConst.NC):
		var biome: String = WorldBiomes.biomeAt(float(i) * SimConst.COL)
		var code: int = SURF_NAMES.find(String(D.biomeSurface.get(biome, "soil")))
		code = maxi(code, 0) & 3
		if D.paving.biomes.has(biome):
			code |= 4
		_colSurf[i] = code
''', '''	_buildSurf()   # the biome's surface per terrain column, for the world built now (and again for each world a match builds: surfaceAt)


static var _colSurfKey: int = -1


## The biome's surface per terrain column, for the world the current match built (WorldBiomes.worldId): the hand-made world's biome layout is fixed, a planet's is its slice's, and the
## columns are the arena's.
static func _buildSurf() -> void:
	var D: Dictionary = _d
	_colSurfKey = WorldBiomes.worldId
	_colSurf.resize(SimConst.NC)
	for i in range(SimConst.NC):
		var biome: String = WorldBiomes.biomeAt(float(i) * SimConst.COL)
		var code: int = SURF_NAMES.find(String(D.biomeSurface.get(biome, "soil")))
		code = maxi(code, 0) & 3
		if D.paving.biomes.has(biome):
			code |= 4
		_colSurf[i] = code
''')
    s = rep(s, '''	var col: int = int(floor(SimWrap.wrap(x) / SimConst.COL)) % SimConst.NC
	if S.rubble[col] >= K_RUBBLE_MIN:''', '''	if _colSurfKey != WorldBiomes.worldId or _colSurf.size() != SimConst.NC:
		_buildSurf()
	var col: int = int(floor(SimWrap.wrap(x) / SimConst.COL)) % SimConst.NC
	if S.rubble[col] >= K_RUBBLE_MIN:''')
    return s


import os
if '_buildSurf' not in open(R + 'sim/world/contact.gd', encoding='utf-8').read():   # the surface-class fix is on main (79693404) once applied
    rw(R, 'sim/world/contact.gd', contact)
rw(R, 'sim/world/planet.gd', planet)
rw(R, 'sim/world/planet_world.gd', planet_world)
rw(R, 'sim/world/ringpick.gd', rings_cfg)
rw(R, 'sim/core/sim.gd', sim)
rw(R, 'sim/core/state.gd', state)
rw(R, 'sim/core/hash.gd', hashf)
rw(R, 'sim/core/view/fx.gd', viewfx)
rw(R, 'tools/fixtures/cases.json', cases)
rings_json(R + 'data/biomes/rings.json')
rings_schema(R + 'tools/schemas/biomes-rings.schema.json')
print('calm-moment turn applied')
