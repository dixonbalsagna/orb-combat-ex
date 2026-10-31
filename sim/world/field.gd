class_name WorldField
extends RefCounted
## Planet generation 3: the ground is a field of nodes on the planet (docs/world/ring-any-angle/research.md T6 stage 3, simulation.md section 9; data/biomes/field.json). A node is gen 2's own surface read at one
## point of a cube-sphere (surfAt plus the surface detail, the value a ring column holds today); the ground between nodes is the two triangles of its cell. Nothing noise-based is read between nodes, so a point's
## height is a lookup: the same at any bearing, for any ring, in any order. Gen 2 is untouched; a planet is gen 3 only when a setup names planetGen 3.
##
## The lattice: six faces of `cells` cells (128 units a cell at 300), nodes at the cell corners; a node on a face's edge is read once from each face (the same point, the same value to the last bit or a rounding
## of it). The bake is the same lattice at every `bakeStride`-th node (512 units at 4): nested, not separate, so a bake node is a canonical node and the two levels agree at every shared point. A reader picks its
## level by what it is (near readers the canonical nodes, the forecasts the bake) and never by what has been read already, or two machines would stand on different ground.
##
## The convention is Rendering's tile key (a cube-sphere of equal-angle faces: direction = normalize(n + e1 tan(s pi/4) + e2 tan(t pi/4)), s and t in [-1, 1]; docs/rendering/pending/2026-10-31-swing-test/bake.gd).
## Float64 arithmetic with our own sin, cos and atan only; the node values are stored as float32, as S.base is. The field is memoised outside the sim state by the planet's seed and is a pure function of it and of
## the data, so a cache changes nothing it returns.

const PATH := "res://data/biomes/field.json"
const SCHEMA := "biomes.field/1"
const UNKNOWN := 255          # a node not read yet (a biome is 0 to 6, a fine biome 0 to 14)
const NODE_UNITS := 2         # a node is about 45 to 55 microseconds; a load unit (SimPlanetLoad) is about 20

## n, e1, e2 of each face (Rendering's FACES table).
const FACES: Array = [
	[[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],
	[[-1.0, 0.0, 0.0], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0]],
	[[0.0, 1.0, 0.0], [0.0, 0.0, 1.0], [1.0, 0.0, 0.0]],
	[[0.0, -1.0, 0.0], [1.0, 0.0, 0.0], [0.0, 0.0, 1.0]],
	[[0.0, 0.0, 1.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]],
	[[0.0, 0.0, -1.0], [0.0, 1.0, 0.0], [1.0, 0.0, 0.0]],
]

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""
static var _fields: Dictionary = {}     # seed -> Field (a few: each holds about 3.2 MB when whole)
static var _lf: int = 0                 # locate's answer: the face and the point in it, in cells
static var _la: float = 0.0
static var _lb: float = 0.0
static var _PI4: float = 0.0
static var refineOverride: int = -1     # a tool's choice for the records: -1 the data's, 0 off, 1 on (set before a field is made)
static var _vh: float = 0.0             # _read's answer: height (with the surface detail), stored biome, fine biome
static var _vb: int = 0
static var _vf: int = 0


## One planet's nodes. h: float32 heights; b: the stored biome (UNKNOWN until read); f: the fine biome. Index face * (cells + 1)^2 + j * (cells + 1) + i.
class Field extends RefCounted:
	var P: WorldPlanet.Planet
	var seed: int = 0
	var N: int = 300
	var stride: int = 4
	var side: int = 301
	var h := PackedFloat32Array()
	var b := PackedByteArray()
	var f := PackedByteArray()
	var reads: int = 0            # nodes read (not state: a count for tools and the load's progress)
	var bakeK: int = 0            # the bake's progress: nodes done, in bake order
	var bakeN: int = 0            # the bake's nodes in all
	var bakeDone: bool = false
	var bakeHash: String = ""
	var oh: float = 0.0           # the last sample's height, stored biome and fine biome
	var ob: int = 0
	var ofine: int = 0
	var refine: bool = false      # the records on (field.json refine.enabled, or a tool's override)
	var sub: int = 4
	var S4: int = 1201            # sub-nodes along a face's edge (cells * sub + 1)
	var rf := PackedByteArray()   # a cell's state: 0 not decided, 1 plain, 2 refined
	var sh: Dictionary = {}       # sub-node key -> height (float64 of the exact read; the canonical ones are the canonical node's)
	var sb: Dictionary = {}       # sub-node key -> stored biome | fine biome << 8
	var refined: int = 0          # cells refined so far (a count for tools)
	var subReads: int = 0


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


## A hash of the parsed data without the "_" notes: folded into a gen 3 planet's data hash (WorldPlanet.dataHash).
static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash


static func _load() -> void:
	_loaded = true
	_d = {}
	_errors = []
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_errors.append("field.json: cannot open " + PATH)
		return
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("field.json: not a %s object" % SCHEMA)
		return
	for k in ["cells", "bakeStride", "refine"]:
		if not j.has(k):
			_errors.append("field.json: %s is missing" % k)
			return
	var cells: int = int(j.cells)
	var st: int = int(j.bakeStride)
	if cells < 4 or st < 1 or cells % st != 0:
		_errors.append("field.json: cells must be a multiple of bakeStride")
		return
	_d = j
	var h := SimHash.Hasher.new()
	h.text("biomes.field")
	FighterData._canon(h, j)
	_hash = h.hex()


static func cells() -> int:
	return int(data().get("cells", 300))


static func bakeStride() -> int:
	return int(data().get("bakeStride", 4))


## The field of planet P (a gen 3 planet): memoised by the seed. Only a few are kept, the oldest made first out.
static func of(P: WorldPlanet.Planet) -> Field:
	if _fields.has(P.seed):
		return _fields[P.seed]
	var F := Field.new()
	F.P = P
	F.seed = P.seed
	F.N = cells()
	F.stride = bakeStride()
	F.side = F.N + 1
	var n: int = 6 * F.side * F.side
	F.h.resize(n)
	F.h.fill(0.0)
	F.b.resize(n)
	F.b.fill(UNKNOWN)
	F.f.resize(n)
	F.f.fill(0)
	var bs: int = F.N / F.stride + 1
	F.bakeN = 6 * bs * bs
	var rd: Dictionary = data().get("refine", {})
	F.refine = bool(rd.get("enabled", false)) if refineOverride < 0 else refineOverride == 1
	F.sub = int(rd.get("sub", 4))
	F.S4 = F.N * F.sub + 1
	if F.refine:
		F.rf.resize(6 * F.N * F.N)
		F.rf.fill(0)
	while _fields.size() >= 3:
		_fields.erase(_fields.keys()[0])
	_fields[P.seed] = F
	return F


static func forget() -> void:
	_fields.clear()


## Whether a planet's bake is done (a load's step finished it, or a tool ran it): the field exists and holds every bake node.
static func bakeReady(seed: int) -> bool:
	return _fields.has(seed) and (_fields[seed] as Field).bakeDone


## ===================================================================== the lattice
static func _tanq(k2: int, n: int) -> float:
	if k2 == 0:
		return 0.0
	if k2 == n:
		return 1.0
	if k2 == -n:
		return -1.0
	var x: float = float(k2) / float(n) * (SimMathx.PI / 4.0)
	return SimDetMath.sin(x) / SimDetMath.cos(x)


## The unit direction of node (i, j) of a face at `n` cells a face: n + e1 tan(s pi/4) + e2 tan(t pi/4), s = 2 i / n - 1.
static func dirOf(face: int, i: int, j: int, n: int) -> Array:
	var fc: Array = FACES[face]
	var nn: Array = fc[0]
	var e1: Array = fc[1]
	var e2: Array = fc[2]
	var ts: float = _tanq(2 * i - n, n)
	var tt: float = _tanq(2 * j - n, n)
	var x: float = nn[0] + e1[0] * ts + e2[0] * tt
	var y: float = nn[1] + e1[1] * ts + e2[1] * tt
	var z: float = nn[2] + e1[2] * ts + e2[2] * tt
	var l: float = 1.0 / sqrt(x * x + y * y + z * z)
	return [x * l, y * l, z * l]


## Where a unit direction falls: sets _lf (the face) and _la, _lb (the point in it, in cells of `n` a face, 0 to n).
static func _locate(qx: float, qy: float, qz: float, n: int) -> void:
	if _PI4 == 0.0:
		_PI4 = SimMathx.PI / 4.0
	var ax: float = absf(qx)
	var ay: float = absf(qy)
	var az: float = absf(qz)
	var face: int
	if ax >= ay and ax >= az:
		face = 0 if qx > 0.0 else 1
	elif ay >= az:
		face = 2 if qy > 0.0 else 3
	else:
		face = 4 if qz > 0.0 else 5
	var fc: Array = FACES[face]
	var nn: Array = fc[0]
	var e1: Array = fc[1]
	var e2: Array = fc[2]
	var w: float = nn[0] * qx + nn[1] * qy + nn[2] * qz
	var s: float = WorldPlanet.atanf((e1[0] * qx + e1[1] * qy + e1[2] * qz) / w) / _PI4
	var t: float = WorldPlanet.atanf((e2[0] * qx + e2[1] * qy + e2[2] * qz) / w) / _PI4
	_lf = face
	_la = (s + 1.0) * 0.5 * float(n)
	_lb = (t + 1.0) * 0.5 * float(n)


## ===================================================================== a node
## The surface read at a unit direction, as a ring column holds it: gen 2's surface there, and the surface detail (ordinary land; a quarter on an ice sheet above 100 units). Sets _vh, _vb, _vf.
static func _read(F: Field, d: Array) -> void:
	var P: WorldPlanet.Planet = F.P
	WorldPlanet.surfAt(P, d[0], d[1], d[2])
	var hh: float = P.outH
	var bb: int = P.outB
	var c: Dictionary = P.c
	if bb >= WorldPlanet.BIO_PLAINS and bb <= WorldPlanet.BIO_MOUNTAINS:
		hh += (WorldPlanet._fbm(P.R, d[0], d[1], d[2], c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp
	elif bb == WorldPlanet.BIO_ICE_SHEET and hh > 100.0:
		hh += (WorldPlanet._fbm(P.R, d[0], d[1], d[2], c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp * c.detailSheet
	_vh = hh
	_vb = bb
	_vf = P.outF if P.outF >= 0 else bb


## Reads node (face, i, j) if it has not been; returns its index.
static func ensure(F: Field, face: int, i: int, j: int) -> int:
	var idx: int = face * F.side * F.side + j * F.side + i
	if F.b[idx] != UNKNOWN:
		return idx
	_read(F, dirOf(face, i, j, F.N))
	F.h[idx] = _vh
	F.f[idx] = _vf
	F.b[idx] = _vb
	F.reads += 1
	return idx


## ===================================================================== the records: exact sub-nodes where the ground is creased
## Sub-node (i4, j4) of a face at `sub` times the canonical resolution: a canonical node where both are multiples of sub, else the planet's function read there (the direction by dirOf at cells * sub, so a
## sub-node on a cell's edge is the same point, to the bit, from either cell). Returns its key in F.sh and F.sb.
static func _subKey(F: Field, face: int, i4: int, j4: int) -> int:
	var key: int = (face * F.S4 + j4) * F.S4 + i4
	if F.sh.has(key):
		return key
	if i4 % F.sub == 0 and j4 % F.sub == 0:
		var idx: int = ensure(F, face, i4 / F.sub, j4 / F.sub)
		F.sh[key] = F.h[idx]
		F.sb[key] = int(F.b[idx]) | (int(F.f[idx]) << 8)
	else:
		_read(F, dirOf(face, i4, j4, F.N * F.sub))
		F.sh[key] = float(PackedFloat32Array([_vh])[0])   # as a column stores it
		F.sb[key] = _vb | (_vf << 8)
		F.subReads += 1
	return key


## Whether cell (i, j) of a face is refined: a function of its own four corners, so the same on every machine whatever has been read. A cell on a face's rim is never refined (its neighbour is on another face).
static func cellRefined(F: Field, face: int, i: int, j: int) -> bool:
	if not F.refine or i < 1 or j < 1 or i > F.N - 2 or j > F.N - 2:
		return false
	var ci: int = (face * F.N + j) * F.N + i
	var st: int = F.rf[ci]
	if st != 0:
		return st == 2
	var k00: int = ensure(F, face, i, j)
	var k10: int = ensure(F, face, i + 1, j)
	var k01: int = ensure(F, face, i, j + 1)
	var k11: int = ensure(F, face, i + 1, j + 1)
	var flag: bool = refinedByCorners(F.h[k00], F.h[k10], F.h[k01], F.h[k11])
	F.rf[ci] = 2 if flag else 1
	if flag:
		F.refined += 1
	return flag


## THE ONE RULE for whether a cell is read at 32 units, from its four corner heights alone (no noise, no state): the corners step by more than refine.step, or their span reaches the shoreline height widened by
## refine.shoreBand each side. Renderers that hold a tile's corner heights call this and agree with the sim by construction. (A cell on a face's rim is never refined whatever its corners say: cellRefined, refined.)
static func refinedByCorners(h00: float, h10: float, h01: float, h11: float) -> bool:
	var lo: float = minf(minf(h00, h10), minf(h01, h11))
	var hi: float = maxf(maxf(h00, h10), maxf(h01, h11))
	var rd: Dictionary = data().refine
	var band: float = float(rd.shoreBand)
	return hi - lo > float(rd.step) or (lo < WorldWater.SHORE_WET + band and hi > WorldWater.SHORE_WET - band)


## Whether canonical cell (i, j) of a face is refined, for a planet (reads its four corner nodes, which are computed if missing; nothing else). The refined cell's sub-nodes are on the N = 1200 lattice, nested in the
## canonical 300: dirOf(face, i4, j4, cells() * sub) with i4 = i * sub + k, 32 units, and every fourth is the canonical node.
static func refined(P: WorldPlanet.Planet, face: int, i: int, j: int) -> bool:
	return cellRefined(of(P), face, i, j)


## The height of the shoreline test (the sim's WorldWater.SHORE_WET: the sea fills every sea-connected column whose ground is below it, and a body wades there). The water's surface is WorldWater.SEA_LEVEL (0);
## open sea is ground below WorldWater.RESERVOIR_BASE. The records use this one value.
static func shore() -> float:
	return WorldWater.SHORE_WET


## A refined cell's ground at (u, v) in it: the two triangles of the sub-cell the point is in, from the exact sub-nodes. Sets oh, ob and ofine (the nearest sub-node's).
static func _sampleRefined(F: Field, face: int, i0: int, j0: int, u: float, v: float) -> void:
	var sub: int = F.sub
	var fa: float = u * float(sub)
	var fb: float = v * float(sub)
	var ka: int = mini(int(fa), sub - 1)
	var kb: int = mini(int(fb), sub - 1)
	var su: float = fa - float(ka)
	var sv: float = fb - float(kb)
	var a0: int = i0 * sub + ka
	var b0: int = j0 * sub + kb
	var q00: int = _subKey(F, face, a0, b0)
	var q10: int = _subKey(F, face, a0 + 1, b0)
	var q01: int = _subKey(F, face, a0, b0 + 1)
	var q11: int = _subKey(F, face, a0 + 1, b0 + 1)
	var h00: float = F.sh[q00]
	var h10: float = F.sh[q10]
	var h01: float = F.sh[q01]
	var h11: float = F.sh[q11]
	if su + sv <= 1.0:
		F.oh = h00 + (h10 - h00) * su + (h01 - h00) * sv
	else:
		F.oh = h11 + (h01 - h11) * (1.0 - su) + (h10 - h11) * (1.0 - sv)
	var kn: int = (q00 if su < 0.5 else q10) if sv < 0.5 else (q01 if su < 0.5 else q11)
	var pb: int = F.sb[kn]
	F.ob = pb & 255
	F.ofine = pb >> 8


## The difference between the exact sub-nodes along one edge of a cell (e: 0 the v = 0 edge, 1 the v = 1, 2 the u = 0, 3 the u = 1) and the straight line between the corners, at t along it, in units.
static func _edgeDelta(F: Field, face: int, i0: int, j0: int, e: int, t: float) -> float:
	var sub: int = F.sub
	var ca: float
	var cb: float
	var ia: int = i0 * sub
	var ja: int = j0 * sub
	var di: int = 0
	var dj: int = 0
	if e == 0:
		ca = F.h[ensure(F, face, i0, j0)]
		cb = F.h[ensure(F, face, i0 + 1, j0)]
		di = 1
	elif e == 1:
		ca = F.h[ensure(F, face, i0, j0 + 1)]
		cb = F.h[ensure(F, face, i0 + 1, j0 + 1)]
		ja += sub
		di = 1
	elif e == 2:
		ca = F.h[ensure(F, face, i0, j0)]
		cb = F.h[ensure(F, face, i0, j0 + 1)]
		dj = 1
	else:
		ca = F.h[ensure(F, face, i0 + 1, j0)]
		cb = F.h[ensure(F, face, i0 + 1, j0 + 1)]
		ia += sub
		dj = 1
	var fa: float = t * float(sub)
	var k: int = mini(int(fa), sub - 1)
	var f: float = fa - float(k)
	var d0: float = F.sh[_subKey(F, face, ia + di * k, ja + dj * k)] - (ca + (cb - ca) * float(k) / float(sub))
	var d1: float = F.sh[_subKey(F, face, ia + di * (k + 1), ja + dj * (k + 1))] - (ca + (cb - ca) * float(k + 1) / float(sub))
	return d0 + (d1 - d0) * f


## What a plain cell adds where a neighbour across one of its edges is refined: that edge's difference, fading to nothing across the cell, so the ground is whole along the edge and there is no crack.
static func _edgeCorrections(F: Field, face: int, i0: int, j0: int, u: float, v: float) -> float:
	var sum: float = 0.0
	if j0 > 0 and cellRefined(F, face, i0, j0 - 1):
		sum += _edgeDelta(F, face, i0, j0, 0, u) * (1.0 - v)
	if j0 < F.N - 1 and cellRefined(F, face, i0, j0 + 1):
		sum += _edgeDelta(F, face, i0, j0, 1, u) * v
	if i0 > 0 and cellRefined(F, face, i0 - 1, j0):
		sum += _edgeDelta(F, face, i0, j0, 2, v) * (1.0 - u)
	if i0 < F.N - 1 and cellRefined(F, face, i0 + 1, j0):
		sum += _edgeDelta(F, face, i0, j0, 3, v) * u
	return sum


## THE DIAGONAL RULE (World, Simulation and Rendering split a cell the same way): a cell (a, b) with corners h(a, b), h(a+1, b), h(a, b+1), h(a+1, b+1) is cut along the diagonal from (a+1, b) to (a, b+1), at u + v = 1
## (u along the first face axis, v along the second). Below it (u + v <= 1) the triangle (a, b), (a+1, b), (a, b+1); above it the triangle (a+1, b+1), (a, b+1), (a+1, b). A refined cell cuts each of its sub-cells the same way.
## The ground at a unit direction, one call: sets F.oh (height, from the cell's two triangles), F.ob (the stored biome of the nearest node) and F.ofine (its fine biome). `step` is 1 for the canonical
## nodes and the bake's stride for the bake; the same cell geometry, so a bake read at a bake node is the canonical read there. The canonical read adds the records (refine): exact sub-nodes in a creased
## cell, the difference along a shared edge in its neighbours. The bake never does: it is the forecasts' coarse ground.
static func sample(F: Field, qx: float, qy: float, qz: float, step: int = 1) -> void:
	var n: int = F.N / step
	_locate(qx, qy, qz, n)
	var face: int = _lf
	var i0: int = int(_la)
	var j0: int = int(_lb)
	if i0 > n - 1:
		i0 = n - 1
	if j0 > n - 1:
		j0 = n - 1
	if i0 < 0:
		i0 = 0
	if j0 < 0:
		j0 = 0
	var u: float = _la - float(i0)
	var v: float = _lb - float(j0)
	if step == 1 and F.refine and cellRefined(F, face, i0, j0):
		_sampleRefined(F, face, i0, j0, u, v)
		return
	var a0: int = i0 * step
	var b0: int = j0 * step
	var a1: int = a0 + step
	var b1: int = b0 + step
	var k00: int = ensure(F, face, a0, b0)
	var k10: int = ensure(F, face, a1, b0)
	var k01: int = ensure(F, face, a0, b1)
	var k11: int = ensure(F, face, a1, b1)
	if u + v <= 1.0:
		F.oh = F.h[k00] + (F.h[k10] - F.h[k00]) * u + (F.h[k01] - F.h[k00]) * v
	else:
		F.oh = F.h[k11] + (F.h[k01] - F.h[k11]) * (1.0 - u) + (F.h[k10] - F.h[k11]) * (1.0 - v)
	if step == 1 and F.refine:
		F.oh += _edgeCorrections(F, face, i0, j0, u, v)
	var kn: int = (k00 if u < 0.5 else k10) if v < 0.5 else (k01 if u < 0.5 else k11)
	F.ob = F.b[kn]
	F.ofine = F.f[kn]


## A block of nodes for a renderer's tile: (n + 1)^2 nodes from (i0, j0) of a face, every `step` nodes (step 1 the canonical lattice, the bake's stride the bake). Returns {"h": float32 heights, "b": stored
## biomes, "f": fine biomes}, row j * (n + 1) + i. Nodes not read yet are read.
static func block(F: Field, face: int, i0: int, j0: int, n: int, step: int = 1) -> Dictionary:
	var hs := PackedFloat32Array()
	var bs := PackedByteArray()
	var fs := PackedByteArray()
	var m: int = (n + 1) * (n + 1)
	hs.resize(m)
	bs.resize(m)
	fs.resize(m)
	var k: int = 0
	for j in range(n + 1):
		for i in range(n + 1):
			var idx: int = ensure(F, face, i0 + i * step, j0 + j * step)
			hs[k] = F.h[idx]
			bs[k] = F.b[idx]
			fs[k] = F.f[idx]
			k += 1
	return {"h": hs, "b": bs, "f": fs}


## ===================================================================== the bake
## The bake's nodes, in order: face, then j, then i, every stride-th node. Reads up to `units` of load (NODE_UNITS a node); true when the bake is whole and hashed. A whole-bake budget does it in one call.
static func bakeStep(F: Field, units: int) -> bool:
	if F.bakeDone:
		return true
	var left: int = maxi(1, units / NODE_UNITS)
	var bs: int = F.N / F.stride + 1
	while left > 0 and F.bakeK < F.bakeN:
		var k: int = F.bakeK
		var face: int = k / (bs * bs)
		var r: int = k - face * bs * bs
		var j: int = r / bs
		var i: int = r - j * bs
		ensure(F, face, i * F.stride, j * F.stride)
		F.bakeK += 1
		left -= 1
	if F.bakeK >= F.bakeN:
		F.bakeHash = _hashBake(F)
		F.bakeDone = true
	return F.bakeDone


static func bakeUnits(F: Field) -> int:
	return F.bakeN * NODE_UNITS


## The hash of the bake's nodes (heights as their float32 values, biomes and fine biomes): what two builds must agree on before a match starts.
static func _hashBake(F: Field) -> String:
	var h := SimHash.Hasher.new()
	h.text("field/%d/%d/%d" % [F.seed, F.N, F.stride])
	var bs: int = F.N / F.stride + 1
	for face in range(6):
		for j in range(bs):
			for i in range(bs):
				var idx: int = face * F.side * F.side + j * F.stride * F.side + i * F.stride
				h.num(F.h[idx])
				h.u(F.b[idx] | (F.f[idx] << 8))
	return h.hex()


## The planet cell of the last sample (step 1), as one integer: the face and the point in it in quarters of a cell (32 units at 300 cells), so the same patch of ground has the same key whichever ring reads it.
## Trees and other keyed draws use it in place of a column's index, which belongs to the ring and not to the planet.
static func cellKey(F: Field) -> int:
	var sub: int = F.N * 4
	var ia: int = int(_la * 4.0)
	var ib: int = int(_lb * 4.0)
	if ia >= sub:
		ia = sub - 1
	if ib >= sub:
		ib = sub - 1
	return (_lf * sub + maxi(ia, 0)) * sub + maxi(ib, 0)


## ===================================================================== the contract (simulation.md section 11)
## Pure reads at a unit direction: the same bits in any order, in any process. A missing node is computed on the spot; what is loaded never picks the level.
static func height(P: WorldPlanet.Planet, x: float, y: float, z: float) -> float:
	var F: Field = of(P)
	sample(F, x, y, z)
	return F.oh


static func biome(P: WorldPlanet.Planet, x: float, y: float, z: float) -> int:
	var F: Field = of(P)
	sample(F, x, y, z)
	return F.ob


static func fine(P: WorldPlanet.Planet, x: float, y: float, z: float) -> int:
	var F: Field = of(P)
	sample(F, x, y, z)
	return F.ofine


## The 512 bake's reads, for the forecasts (the reader's rule: inside a planner everything reads these).
static func heightBake(P: WorldPlanet.Planet, x: float, y: float, z: float) -> float:
	var F: Field = of(P)
	sample(F, x, y, z, F.stride)
	return F.oh


static func biomeBake(P: WorldPlanet.Planet, x: float, y: float, z: float) -> int:
	var F: Field = of(P)
	sample(F, x, y, z, F.stride)
	return F.ob


## A canonical node's height and stored biome, by face, i, j (the lattice of dirOf at cells()).
static func nodeH(P: WorldPlanet.Planet, face: int, i: int, j: int) -> float:
	var F: Field = of(P)
	return F.h[ensure(F, face, i, j)]


## ===================================================================== the field's records (platforms; lakes and rivers after)
## The edits a place makes to the ground, as planet records Simulation applies after the field read (S.fieldRecs, constant for the match). A platform is the lift under a settlement: the ground inside the place
## is at least `floor` (WorldTerrain.SETTLE_FLOOR) where it is dry (at least WorldTerrain.TRIM_G, so it never fills the sea in), with a smooth blend across PLATFORM_BLEND columns each side of the place's edge. The
## record is {"k": "platform", "id", "px", "py", "pz", "r", "floor", "blend"}; r is the place's radius and blend a width in units. A kind not known here is skipped, so lakes and rivers join the list later.
static func recordsOf(P: WorldPlanet.Planet, ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append({"k": "platform", "id": int(id), "px": P.px[id], "py": P.py[id], "pz": P.pz[id], "r": P.rad[id], "floor": WorldTerrain.SETTLE_FLOOR, "blend": float(WorldTerrain.PLATFORM_BLEND) * SimConst.COL})
	return out


## The ground at a unit direction after the records: `h` is the field's height there (and the store's craters, if the caller added them first); a platform lifts it toward its floor, a river's channel cuts it to the bed.
## Pure in (S.fieldRecs, q, h). The records near a point come from WorldWaterRec's index.
static func applyRecords(S, qx: float, qy: float, qz: float, h: float) -> float:
	if S.fieldRecs.is_empty():
		return h
	var R: float = SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI)
	var out: float = h
	var P = null
	for rec in WorldWaterRec.near(S, qx, qy, qz):
		var kind: String = rec.k
		if kind == "platform":
			if out >= WorldTerrain.SETTLE_FLOOR or out < WorldTerrain.TRIM_G:
				continue
			var dx: float = (qx - rec.px) * R
			var dy: float = (qy - rec.py) * R
			var dz: float = (qz - rec.pz) * R
			var d: float = sqrt(dx * dx + dy * dy + dz * dz)
			var b: float = rec.blend
			if d >= rec.r + b:
				continue
			var w: float = clampf((rec.r + b - d) / (2.0 * b), 0.0, 1.0)
			w = w * w * (3.0 - 2.0 * w)
			out += (rec.floor - out) * w if out < rec.floor else 0.0
		elif kind == "river":
			if P == null:
				P = WorldPlanet.make(int(S.planetRing.seed))
			var bl: Array = WorldWaterRec.riverBed(P, rec, qx, qy, qz)
			if not bl.is_empty() and float(bl[0]) < out:
				out = float(bl[0])
	return out


## The water the records hold at a unit direction whose ground (after applyRecords) is `h`: the deepest of the lakes and rivers there, in units; 0 for none. The sea is not a record: it is derived from the ground.
static func recordWater(S, qx: float, qy: float, qz: float, h: float) -> float:
	if S.fieldRecs.is_empty():
		return 0.0
	var best: float = 0.0
	var lakeBest: float = 0.0
	var lakeLevel: float = 1.0e30
	var P = null
	for rec in WorldWaterRec.near(S, qx, qy, qz):
		var kind: String = rec.k
		if kind == "lake":
			if P == null:
				P = WorldPlanet.make(int(S.planetRing.seed))
			var ld: float = WorldWaterRec.lakeDepth(of(P), rec, qx, qy, qz, h)   # where two lakes both reach a point the lower one holds it (the higher is the one its flood was stopped by)
			if ld > 0.0 and float(rec.level) < lakeLevel:
				lakeLevel = float(rec.level)
				lakeBest = ld
		elif kind == "river":
			if P == null:
				P = WorldPlanet.make(int(S.planetRing.seed))
			var bl: Array = WorldWaterRec.riverBed(P, rec, qx, qy, qz)
			if not bl.is_empty():
				best = maxf(best, float(bl[1]) - h)
	return maxf(best, lakeBest)
