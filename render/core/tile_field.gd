class_name RenderTileField
extends RefCounted
## The planet's ground as tiles keyed to the planet (docs/world/ring-any-angle/rendering.md, research.md T6 stage 4), for
## RenderTileGround to draw. A cube sphere on World's lattice (WorldField): 75 cells a face at 512 units (the bake), so 3
## tiles of 25 cells a face edge at level 0, 6 at level 1 (256), 12 at level 2 (128). On a field world (gen 3) a node is
## World's own, with the places' records on it, so what's drawn is what the sim reads through its frame. On gen 2, kept to
## compare, a node is the planet's read (WorldPlanet.surfAt) with the strip's own height near the line and inside a place's
## band. Nothing here writes the sim: a node read is pure and fills only what sits outside the state.
##
## Level 0 is filled at the match's load (build_steps), free on a field world since the load baked it; finer tiles come on
## demand, a slice a frame, nearest first. One field serves every pane. Each layer of the two arrays holds a tile's 26 nodes a side and a ring outside them, so a
## vertex morphing to its parent's lattice and a slope at the tile's edge both find their node.

const CELLS: int = 25
const TEX: int = CELLS + 3        # nodes a side in a layer: the tile's, and one more each way
const LEVEL0: int = 3             # tiles a face edge at level 0
const BASE_LEVEL: int = 2         # the ground a mesh level can always read: finer data may still be on its way
const LEVELS: int = 5             # 512, 256, 128, 64, 32 units: the last two are World's sub-nodes, for the ground near the camera
const POOL: int = 800             # layers: the 54 of level 0 stay, the rest are reused, least recently wanted first; never one a pane is using. Two panes want about 190 each, more in a wide shot
const FACES: Array = [
	[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
	[Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
	[Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)],
	[Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
	[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
	[Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0)],
]

var R: float = 1.0
var hts: Texture2DArray
var ids: Texture2DArray
var off_tex: ImageTexture         # per column (mod OFF_N): drawn ground less the sim's, and the sim's: RenderTileGround.lift
const WET_STEP: float = 4.0          # a lake's or a river's depth in the ids' second channel, in these units
const OFF_N: int = 1024
const OFF_REACH: int = 384          # columns kept, either side together: the width of the widest view of a pair

var P: WorldPlanet.Planet
var field_world: bool = false       # on World's field, through Simulation's frame (gen 3)
var _F = null
var _pal_field: Dictionary = {}
var _p0 := Vector3.ZERO
var _t0 := Vector3.ZERO
var _s0 := Vector3.ZERO
var _S: SimState
var version: int = 0                 # counts the tiles stored: the walk looks again when it moves
var _u := Vector3.ZERO
var _v := Vector3.ZERO
var _c := Vector3.ZERO
var _touch_x: float = 0.0
var _place := PackedFloat32Array()   # per column: how far inside a place's band (1 inside, 0 away from any building)
var _pal: Dictionary = {}
var _layer: Dictionary = {}          # tile key -> layer
var _keys := PackedInt32Array()      # layer -> tile key, -1 while free
var _stamp := PackedInt32Array()     # layer -> the frame it was last wanted
var _hs: Array = []                  # layer -> its heights (PackedFloat32Array)
var _wanted: Dictionary = {}         # tile key -> distance, this frame's
static var steady_fill: bool = false   # a capture's frames are slow by nature: its fill doesn't lean on the frame time, so a reel shows what play shows
var frame_room: bool = true          # the frame is under its target: the fill may take its urgent budget
var _off_stale_at: int = -1000000
var _live: Dictionary = {}           # pane -> the tile keys its current selection uses: these aren't evicted
var _live_now: Dictionary = {}
var _frame: int = 0
var _job_key: int = -1
var _job_h := PackedFloat32Array()
var _job_t := PackedFloat32Array()   # its nodes' lake or river depth
var _job_any_wet: bool = false
var _wet_tile := PackedByteArray()   # layer -> 1 if the water sheet draws it
var _wets: Array = []                # layer -> its nodes' lake or river depth, empty for a dry tile
var _job_c := PackedByteArray()
var _job_at: int = 0
var _job_recs: bool = false
var _job_wet: bool = false
var _job_band: bool = false
var _has_pads: bool = false
var _urgent_until: int = 0
var _ask_list: Array = []            # tiles asked for ahead of the camera, level 1 first
var _asked: Dictionary = {}
var _ask_until: int = 0
var ground: GroundField = null
var _standing: Array = []            # [multimesh, instance, x, z] of what a crater can take
var _crater_seen: int = 0
var _crater_k: int = 0
var _near_list: Array = []
var _near_made: bool = false
var _boot_f: int = 0
var _boot_i: int = 0
var _foots: Array = []               # [multimesh, next instance] still to be set on the ground
var _off := PackedFloat32Array()
var _off_col := PackedInt32Array()
var _off_img: Image
var _off_dirty: bool = false
var _off_axis := Vector3.ZERO
var reads: int = 0
var fill_us: int = 0


## Ready for the match in S: its planet, its ring (a Whole ring, the one great circle a strip can lie on), its places.
func begin(S: SimState) -> void:
	_S = S
	field_world = S.frame != null
	if field_world:
		P = SimField._planet(int(S.frame.seed), int(S.frame.gen))
		_F = WorldField.of(P)
		R = float(SimField.R)
		_place_mask(S)
		for rec in S.fieldRecs:
			if str(rec.k) == "pad" or str(rec.k) == "lot":
				_has_pads = true   # World's lots: a place's ground is in the records, and the band's heights aren't needed
				break
		var f0: Array = frame_at(float(S.frame0.x0), S.frame0)
		_p0 = f0[0]
		_t0 = f0[1]
		_s0 = f0[2]
	else:
		P = WorldPlanet.make(int(S.planetRing.seed))
		R = float(P.R)
		var ring: Dictionary = WorldRingPick.ringFrom(S.planetRing.c, int(S.planetRing.cols), S.planetRing.t)
		_u = Vector3(ring.u[0], ring.u[1], ring.u[2])
		_v = Vector3(ring.v[0], ring.v[1], ring.v[2])
		_c = Vector3(ring.c[0], ring.c[1], ring.c[2])
		_touch_x = float(WorldPlanet.touchCol()) * SimConst.COL
		_place_mask(S)
	var ih: Array[Image] = []
	var ic: Array[Image] = []
	var eh := PackedFloat32Array()
	eh.resize(TEX * TEX)
	var ec := PackedByteArray()
	ec.resize(TEX * TEX * 4)
	var ih0 := Image.create_from_data(TEX, TEX, false, Image.FORMAT_RF, eh.to_byte_array())
	var ic0 := Image.create_from_data(TEX, TEX, false, Image.FORMAT_RGBA8, ec)
	for k in range(POOL):
		ih.append(ih0)
		ic.append(ic0)
	hts = Texture2DArray.new()
	hts.create_from_images(ih)
	ids = Texture2DArray.new()
	ids.create_from_images(ic)
	_keys.resize(POOL)
	_keys.fill(-1)
	_stamp.resize(POOL)
	_stamp.fill(0)
	_hs.resize(POOL)
	_wets.resize(POOL)
	_wet_tile.resize(POOL)
	_off.resize(OFF_N * 2)
	_off_col.resize(OFF_N)
	_off_col.fill(-1)
	_off_img = Image.create_from_data(OFF_N, 1, false, Image.FORMAT_RGF, _off.to_byte_array())
	off_tex = ImageTexture.create_from_image(_off_img)
	_foots.clear()


## Per column, how far inside a place's band: the buildings stand on the strip's ground, so its heights hold there.
func _place_mask(S: SimState) -> void:
	var nc: int = SimConst.NC
	var dist := PackedFloat32Array()
	dist.resize(nc)
	dist.fill(1.0e9)
	for b in S.buildings:
		var half: float = float(b.w) * 0.5 + RenderLook.TILE_PLACE_MARGIN
		var bx: float = float(b.g.x)
		var c0: int = int(floor((bx - half) / SimConst.COL))
		var c1: int = int(floor((bx + half) / SimConst.COL))
		for c in range(c0, c1 + 1):
			dist[posmod(c, nc)] = 0.0
	for pass_i in range(2):
		for c in range(nc):
			dist[c] = minf(dist[c], dist[posmod(c - 1, nc)] + SimConst.COL)
		for c in range(nc - 1, -1, -1):
			dist[c] = minf(dist[c], dist[(c + 1) % nc] + SimConst.COL)
	_place.resize(nc)
	for c in range(nc):
		_place[c] = 1.0 - smoothstep(0.0, RenderLook.TILE_PLACE_EASE, dist[c])


## The frame at strip x on the line: the point, the heading there, and toward the camera. fr: the sim's frame on a field
## world (S.frame, or S.frame0, the plan the world's things were laid in); the ring's, on gen 2.
func frame_at(x: float, fr = null) -> Array:
	if fr != null:
		var a0: float = SimWrap.sdx(fr.x0, x) / R
		var c0: float = cos(a0)
		var s0: float = sin(a0)
		var p := Vector3(fr.px, fr.py, fr.pz)
		var t := Vector3(fr.tx, fr.ty, fr.tz)
		var p1: Vector3 = (p * c0 + t * s0).normalized()
		var t1: Vector3 = (t * c0 - p * s0).normalized()
		return [p1, t1, t1.cross(p1).normalized()]
	var a: float = (x - _touch_x) / R
	var co: float = cos(a)
	var si: float = sin(a)
	return [(_u * co + _v * si).normalized(), (_v * co - _u * si).normalized(), -_c]


## The planet's direction at strip x and depth z, as the shared placement (bend.gdshaderinc) has it.
func dir_at(x: float, z: float, fr = null) -> Vector3:
	var f: Array = frame_at(x, fr)
	var zr: float = z / R
	return ((f[0] as Vector3) * cos(zr) + (f[2] as Vector3) * sin(zr)).normalized()


## The tile's key, and the direction of its node a, b (0 to CELLS on the tile, a step outside either way).
static func key_of(f: int, L: int, i: int, j: int) -> int:
	return f | (L << 3) | (i << 6) | (j << 13)


static func level_n(L: int) -> int:
	return LEVEL0 << L


static func node_dir(f: int, n: int, i: int, j: int, a: int, b: int) -> Vector3:
	var size: float = 2.0 / float(n)
	var s: float = -1.0 + (float(i) + float(a) / float(CELLS)) * size
	var t: float = -1.0 + (float(j) + float(b) / float(CELLS)) * size
	var fc: Array = FACES[f]
	return ((fc[0] as Vector3) + (fc[1] as Vector3) * tan(s * PI / 4.0) + (fc[2] as Vector3) * tan(t * PI / 4.0)).normalized()


## The node's height and palette id: the planet's, the strip's own near the line and inside a place's band.
func node(d: Vector3) -> Array:
	reads += 1
	WorldPlanet.surfAt(P, d.x, d.y, d.z)
	var h: float = float(P.outH)
	var bi: int = int(P.outB)
	var fi: int = int(P.outF)
	var nm: String = WorldClimate.fineName(fi) if fi >= 0 else str(WorldPlanetWorld.BIOME_NAME[clampi(bi, 0, WorldPlanetWorld.BIOME_NAME.size() - 1)])
	var z: float = -d.dot(_c)
	z = asin(clampf(z, -1.0, 1.0)) * R
	var az: float = absf(z)
	if az < RenderLook.TILE_PLACE_DEPTH + RenderLook.TILE_PLACE_EASE:
		var x: float = fposmod(atan2(d.dot(_v), d.dot(_u)) * R + _touch_x, SimConst.W)
		var col: float = x / SimConst.COL
		var i0: int = int(col) % SimConst.NC
		var i1: int = (i0 + 1) % SimConst.NC
		var w: float = maxf(1.0 - smoothstep(RenderLook.TILE_LINE_NEAR, RenderLook.TILE_LINE_FAR, az), _place[i0] * (1.0 - smoothstep(RenderLook.TILE_PLACE_DEPTH, RenderLook.TILE_PLACE_DEPTH + RenderLook.TILE_PLACE_EASE, az)))
		if w > 0.0:
			h = lerpf(h, lerpf(float(_S.base[i0]), float(_S.base[i1]), col - floor(col)), w)
			if w > 0.5:
				nm = WorldBiomes.fineNameAt((float(i0) + 0.5) * SimConst.COL)
	if not _pal.has(nm):
		_pal[nm] = RenderBiomeLook.id_of(nm)
	return [h, int(_pal[nm])]


## The load's last step: the finer ground round the fight's start, so the first look is at 128. True when it's there.
func boot_near(budget_us: int) -> bool:
	if _near_list.is_empty() and not _near_made:
		_near_made = true
		var f0: Variant = _S.frame
		var cx: float = middle_x(_S)
		for dx in [0.0, -1600.0, 1600.0, -3200.0, 3200.0]:
			for dz in [0.0, -1600.0, 1600.0]:
				var d: Vector3 = dir_at(cx + dx, dz, f0)
				for L in [2, 1]:
					var k: int = key_at(d, L)
					if not _layer.has(k) and not _near_list.has(k):
						_near_list.append(k)
	var t0: int = Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < budget_us:
		if _job_key < 0:
			if _near_list.is_empty():
				return true
			var k: int = _near_list.pop_front()
			if _layer.has(k):
				continue
			_start(k)
		if not _fill_job(t0, budget_us):
			return false
	return false


## Where the fighters are along the line: their middle, by the shortest arc from the first (the near tiles are made
## around it, and the test turn's pivot is there).
static func middle_x(S: SimState) -> float:
	var x0: float = float(S.fighters.front().x)
	var sum: float = 0.0
	for f in S.fighters:
		sum += SimWrap.sdx(x0, float(f.x))
	return SimWrap.wrap(x0 + sum / float(S.fighters.size()))


## The tile of level L a direction falls in.
static func key_at(d: Vector3, L: int) -> int:
	var ad := Vector3(absf(d.x), absf(d.y), absf(d.z))
	var f: int
	if ad.x >= ad.y and ad.x >= ad.z:
		f = 0 if d.x > 0.0 else 1
	elif ad.y >= ad.z:
		f = 2 if d.y > 0.0 else 3
	else:
		f = 4 if d.z > 0.0 else 5
	var fc: Array = FACES[f]
	var w: float = (fc[0] as Vector3).dot(d)
	var n: int = level_n(L)
	var i: int = clampi(int((atan((fc[1] as Vector3).dot(d) / w) / (PI / 4.0) + 1.0) * 0.5 * float(n)), 0, n - 1)
	var j: int = clampi(int((atan((fc[2] as Vector3).dot(d) / w) / (PI / 4.0) + 1.0) * 0.5 * float(n)), 0, n - 1)
	return key_of(f, L, i, j)


## The load's step: level 0's tiles, a slice a call. True when they are all there.
func boot(budget_us: int) -> bool:
	var t0: int = Time.get_ticks_usec()
	var n: int = LEVEL0
	while _boot_f < 6:
		var k: int = key_of(_boot_f, 0, _boot_i % n, _boot_i / n)
		if not _layer.has(k):
			if _job_key != k:
				_start(k)
			if not _fill_job(t0, budget_us):
				return false
		_boot_i += 1
		if _boot_i >= n * n:
			_boot_i = 0
			_boot_f += 1
		if Time.get_ticks_usec() - t0 > budget_us:
			return _boot_f >= 6
	return true


func has(k: int) -> bool:
	return _layer.has(k)


func layer_of(k: int) -> int:
	return int(_layer.get(k, -1))


## A pane is choosing its tiles again: what it wants from here on is what it's using.
func begin_wants(pane_id: int) -> void:
	_live_now = {}
	_live[pane_id] = _live_now


## A pane no longer draws: its tiles can go.
func forget_wants(pane_id: int) -> void:
	_live.erase(pane_id)


## The layer a new tile can take: a free one, else the least recently wanted that no pane is using. -1 when there is none.
func _free_slot() -> int:
	var slot: int = -1
	var oldest: int = 2147483647
	for q in range(POOL):
		if _keys[q] < 0:
			return q
		if ((_keys[q] >> 3) & 7) > 0 and _stamp[q] < oldest:
			var used: bool = false
			for keys in _live.values():
				if keys.has(_keys[q]):
					used = true
					break
			if not used:
				oldest = _stamp[q]
				slot = q
	return slot


## A pane wants this tile drawn at this distance from its pivot. The tile's kept fresh; a missing one joins the queue.
func want(k: int, dist: float) -> void:
	_live_now[k] = true
	if _layer.has(k):
		_stamp[int(_layer[k])] = _frame
	elif not _wanted.has(k) or dist < float(_wanted[k]):
		_wanted[k] = dist


## Ask for the ground under a place the camera will reach: strip x on the line (fr: the frame to read it through), the line
## either side and three depths, level 1 first so something finer than the bake is there soonest. The meteor's send names its
## landing here; RenderTileGround looks ahead of anything flying fast. A tile already there, or already asked for, is left.
func ask_around(x: float, fr = null) -> void:
	for L in [1, 2]:
		var step: float = 38400.0 / float(level_n(L))
		var dx: float = -RenderLook.TILE_ASK_REACH
		while dx <= RenderLook.TILE_ASK_REACH:
			for dz in [0.0, -RenderLook.TILE_ASK_DEPTH, RenderLook.TILE_ASK_DEPTH]:
				var k: int = key_at(dir_at(x + dx, dz, fr), L)
				if not _layer.has(k) and not _asked.has(k):
					_asked[k] = true
					_ask_list.append(k)
			dx += step
	_ask_until = _frame + RenderLook.TILE_ASK_FRAMES


## How many asked-for tiles are still to come.
func asked_left() -> int:
	return _ask_list.size()


## The frame's slice: the coarsest wanted level, nearest first, then what's been asked for ahead, while the budget lasts. More of it while the ground
## round the camera is still coarse (arriving at a new place is when it shows), and while asked-for tiles are coming.
func fill(budget_us: int) -> void:
	_frame += 1
	var t0: int = Time.get_ticks_usec()
	for k in _wanted:
		if float(_wanted[k]) < RenderLook.TILE_URGENT_NEAR:
			_urgent_until = _frame + 30
			break
	if _frame < _urgent_until:
		if frame_room:
			budget_us = maxi(budget_us, RenderLook.TILE_FILL_US * RenderLook.TILE_URGENT_X)
	elif _frame < _ask_until and not _ask_list.is_empty():
		budget_us = maxi(budget_us, RenderLook.TILE_ASK_US)
	while Time.get_ticks_usec() - t0 < budget_us:
		if _job_key < 0:
			var best: int = -1
			var bd: float = INF
			var bl: int = LEVELS
			for k in _wanted:
				var kl: int = (int(k) >> 3) & 7
				if kl < bl or (kl == bl and float(_wanted[k]) < bd):
					bl = kl
					bd = float(_wanted[k])
					best = k
			if best < 0:
				while best < 0 and not _ask_list.is_empty():
					var ak: int = _ask_list.pop_front()
					_asked.erase(ak)
					if not _layer.has(ak):
						best = ak
			if best < 0:
				break
			_wanted.erase(best)
			if _layer.has(best):
				continue
			if _free_slot() < 0:
				break   # every layer is in use: keep what's drawn, and what's missing is asked for again when the view moves
			_start(best)
		if not _fill_job(t0, budget_us):
			break
	_foot_slice(t0, budget_us)
	_crater_slice()
	fill_us = Time.get_ticks_usec() - t0
	_wanted.clear()


func _start(k: int) -> void:
	_job_key = k
	_job_at = 0
	_job_h.resize(TEX * TEX)
	_job_t.resize(TEX * TEX)
	_job_any_wet = false
	_job_c.resize(TEX * TEX * 4)
	if field_world:
		_job_recs = _records_reach(k)
		_job_wet = true   # level 0 too: in fast flight it lies under the fight for much of a crossing, and a lake without its water reads as a brown table
		var n: int = level_n((k >> 3) & 7)
		var c: Vector3 = node_dir(k & 7, n, (k >> 6) & 127, (k >> 13) & 127, CELLS / 2, CELLS / 2)
		_job_band = absf(c.dot(_s0)) * R < RenderLook.TILE_PLACE_DEPTH + RenderLook.TILE_PLACE_EASE + 38400.0 / float(n)


## Does any place's or water's record reach this tile? Most don't, and then its nodes read none.
func _records_reach(k: int) -> bool:
	if _S.fieldRecs.is_empty():
		return false
	var n: int = level_n((k >> 3) & 7)
	var c: Vector3 = node_dir(k & 7, n, (k >> 6) & 127, (k >> 13) & 127, CELLS / 2, CELLS / 2)
	var reach: float = 38400.0 / float(n)
	for rec in _S.fieldRecs:
		var rq: Vector3
		var rr: float
		if str(rec.k) == "platform":
			rq = Vector3(rec.px, rec.py, rec.pz)
			rr = float(rec.r) + float(rec.blend)
		else:
			var cc: Array = rec.c
			rq = Vector3(cc[0], cc[1], cc[2])
			rr = float(rec.r) + float(rec.get("blend", 0.0))
		if (rq - c).length() * R < rr + reach:
			return true
	return false


func _fill_job(t0: int, budget_us: int) -> bool:
	var f: int = _job_key & 7
	var L: int = (_job_key >> 3) & 7
	var i: int = (_job_key >> 6) & 127
	var j: int = (_job_key >> 13) & 127
	var n: int = level_n(L)
	var total: int = TEX * TEX
	while _job_at < total:
		var a: int = _job_at % TEX
		var b: int = _job_at / TEX
		var r: Array = node(node_dir(f, n, i, j, a - 1, b - 1)) if not field_world else _field_node(f, n, i, j, a - 1, b - 1)
		_job_h[_job_at] = r[0]
		# A lake's or a river's depth, and whether this tile has any water: the sheet draws only the tiles that do.
		var wet: float = float(r[2]) if r.size() > 2 else 0.0
		_job_t[_job_at] = wet
		if wet > 0.0 or float(r[0]) < 0.0:
			_job_any_wet = true
		var o: int = _job_at * 4
		_job_c[o] = r[1]
		_job_c[o + 1] = clampi(int(wet / WET_STEP + 0.5), 0, 255)
		_job_c[o + 3] = 255
		_job_at += 1
		if _job_at % 4 == 0 and Time.get_ticks_usec() - t0 > budget_us:
			return false
	_store()
	return true


## World's node at this tile's a, b, and the places' records on it. A node past the face's rim takes the rim's: only a slope at
## the rim reads it, since a rim is on every coarser lattice and no vertex morphs past it.
func _field_node(f: int, n: int, i: int, j: int, a: int, b: int) -> Array:
	var ni: int
	var nj: int
	var h: float
	var dp: Array
	var idx: int
	if n * CELLS > 300:
		# Finer than the canonical nodes: World's sub-nodes, the sim's own ground there. The biome is its nearest canonical node's.
		var sub: int = 1200 / (n * CELLS)
		var qi: int = clampi((i * CELLS + a) * sub, 0, 1200)
		var qj: int = clampi((j * CELLS + b) * sub, 0, 1200)
		dp = WorldField.dirOf(f, qi, qj, 1200)
		h = SimField.heightOf(int(_S.frame.seed), int(_S.frame.gen), 1, dp[0], dp[1], dp[2])
		idx = WorldField.ensure(_F, f, mini((qi + 2) / 4, 300), mini((qj + 2) / 4, 300))
	else:
		var stride: int = 300 / (n * CELLS)
		ni = clampi((i * CELLS + a) * stride, 0, 300)
		nj = clampi((j * CELLS + b) * stride, 0, 300)
		idx = WorldField.ensure(_F, f, ni, nj)
		h = _F.h[idx]
		dp = WorldField.dirOf(f, ni, nj, 300)
	reads += 1
	var wet: float = 0.0
	if _job_recs:
		h = WorldField.applyRecords(_S, dp[0], dp[1], dp[2], h)
	var place_w: float = 0.0
	var pc: int = 0
	var px: float = 0.0
	if _job_band:
		# A place stands on the line's height; the field beside the line can be far below it. Its footprint isn't World's yet,
		# so inside its band the ground is the plan's strip, as on gen 2.
		var dv := Vector3(dp[0], dp[1], dp[2])
		var pz: float = absf(asin(clampf(dv.dot(_s0), -1.0, 1.0))) * R
		if pz < RenderLook.TILE_PLACE_DEPTH + RenderLook.TILE_PLACE_EASE:
			px = fposmod(float(_S.frame0.x0) + atan2(dv.dot(_t0), dv.dot(_p0)) * R, SimConst.W)
			pc = int(px / SimConst.COL) % SimConst.NC
			place_w = _place[pc] * (1.0 - smoothstep(RenderLook.TILE_PLACE_DEPTH, RenderLook.TILE_PLACE_DEPTH + RenderLook.TILE_PLACE_EASE, pz))
			if place_w > 0.0 and not _has_pads:
				var col: float = px / SimConst.COL
				h = lerpf(h, lerpf(float(_S.base[pc]), float(_S.base[(pc + 1) % SimConst.NC]), col - floor(col)), place_w)
	if _job_recs and _job_wet and place_w < 0.5:
		wet = WorldField.recordWater(_S, dp[0], dp[1], dp[2], h)
	if place_w > 0.5:
		var pn: String = WorldBiomes.biomeAt(px)
		if pn != "city" and pn != "village":
			pn = "city"
		if not _pal.has(pn):
			_pal[pn] = RenderBiomeLook.id_of(pn)
		return [h, _pal[pn], wet]
	var key: int = int(_F.f[idx]) * 16 + int(_F.b[idx])
	if not _pal_field.has(key):
		var fi: int = int(_F.f[idx])
		_pal_field[key] = RenderBiomeLook.id_of(WorldClimate.fineName(fi) if fi > 0 else str(WorldPlanetWorld.BIOME_NAME[clampi(int(_F.b[idx]), 0, WorldPlanetWorld.BIOME_NAME.size() - 1)]))
	return [h, _pal_field[key], wet]


func _store() -> void:
	var slot: int = _free_slot()
	if slot < 0:
		_job_key = -1   # the view moved on while it was filling, and took the last layer
		return
	if _keys[slot] >= 0:
		_layer.erase(_keys[slot])
	_keys[slot] = _job_key
	_stamp[slot] = _frame
	_layer[_job_key] = slot
	version += 1
	_hs[slot] = _job_h.duplicate()
	hts.update_layer(Image.create_from_data(TEX, TEX, false, Image.FORMAT_RF, _job_h.to_byte_array()), slot)
	_wets[slot] = _job_t.duplicate() if _job_any_wet else PackedFloat32Array()
	_wet_tile[slot] = 1 if _job_any_wet else 0
	ids.update_layer(Image.create_from_data(TEX, TEX, false, Image.FORMAT_RGBA8, _job_c), slot)
	if ((_job_key >> 3) & 7) > 0 and _job_on_line():
		stale_off()
	_job_key = -1


## Does the tile have water for the sheet to draw?
func tile_wet(lay: int) -> bool:
	return _wet_tile[lay] != 0


## The water's top at a planet direction, or below every height if there's none: the sea, or a lake's or a river's level at the nearest node.
func water_top(d: Vector3) -> float:
	var h: float = height_at(d)
	if h < 0.0:
		return 0.0
	var ad := Vector3(absf(d.x), absf(d.y), absf(d.z))
	var f: int
	if ad.x >= ad.y and ad.x >= ad.z:
		f = 0 if d.x > 0.0 else 1
	elif ad.y >= ad.z:
		f = 2 if d.y > 0.0 else 3
	else:
		f = 4 if d.z > 0.0 else 5
	var fc: Array = FACES[f]
	var w: float = (fc[0] as Vector3).dot(d)
	var s: float = atan((fc[1] as Vector3).dot(d) / w) / (PI / 4.0)
	var t: float = atan((fc[2] as Vector3).dot(d) / w) / (PI / 4.0)
	for L in [4, 3, 2, 1]:
		var n: int = level_n(L)
		var ps: float = (s + 1.0) * 0.5 * float(n)
		var pt: float = (t + 1.0) * 0.5 * float(n)
		var i: int = clampi(int(ps), 0, n - 1)
		var j: int = clampi(int(pt), 0, n - 1)
		var lay: int = int(_layer.get(key_of(f, L, i, j), -1))
		if lay >= 0:
			var ws: PackedFloat32Array = _wets[lay]
			if ws.is_empty():
				return -1.0e9
			var q: int = clampi(int((pt - float(j)) * float(CELLS) + 1.5), 0, TEX - 1) * TEX + clampi(int((ps - float(i)) * float(CELLS) + 1.5), 0, TEX - 1)
			return h + ws[q] if ws[q] > 0.0 else -1.0e9
	return -1.0e9


## Does the tile just stored lie on the fighters' line? Only then can the lift's table change.
func _job_on_line() -> bool:
	var n: int = level_n((_job_key >> 3) & 7)
	var c: Vector3 = node_dir(_job_key & 7, n, (_job_key >> 6) & 127, (_job_key >> 13) & 127, CELLS / 2, CELLS / 2)
	if not field_world:
		return true
	var d: float = absf(c.dot(_off_axis)) * R
	return d < 38400.0 / float(n)


## The drawn ground at a planet direction: the same triangles as the mesh (the mesh's own diagonal), on the finest tile there.
func height_at(d: Vector3) -> float:
	var ad := Vector3(absf(d.x), absf(d.y), absf(d.z))
	var f: int
	if ad.x >= ad.y and ad.x >= ad.z:
		f = 0 if d.x > 0.0 else 1
	elif ad.y >= ad.z:
		f = 2 if d.y > 0.0 else 3
	else:
		f = 4 if d.z > 0.0 else 5
	var fc: Array = FACES[f]
	var w: float = (fc[0] as Vector3).dot(d)
	var s: float = atan((fc[1] as Vector3).dot(d) / w) / (PI / 4.0)
	var t: float = atan((fc[2] as Vector3).dot(d) / w) / (PI / 4.0)
	for L in [4, 3, 2, 1, 0]:
		var n: int = level_n(L)
		var ps: float = (s + 1.0) * 0.5 * float(n)
		var pt: float = (t + 1.0) * 0.5 * float(n)
		var i: int = clampi(int(ps), 0, n - 1)
		var j: int = clampi(int(pt), 0, n - 1)
		var lay: int = int(_layer.get(key_of(f, L, i, j), -1))
		if lay >= 0:
			var ga: float = (ps - float(i)) * float(CELLS) + 1.0
			var gb: float = (pt - float(j)) * float(CELLS) + 1.0
			var a0: int = clampi(int(ga), 0, TEX - 2)
			var b0: int = clampi(int(gb), 0, TEX - 2)
			var fa: float = ga - float(a0)
			var fb: float = gb - float(b0)
			var hs: PackedFloat32Array = _hs[lay]
			var q: int = b0 * TEX + a0
			if fa + fb <= 1.0:
				return hs[q] + fa * (hs[q + 1] - hs[q]) + fb * (hs[q + TEX] - hs[q])
			return hs[q + TEX + 1] + (1.0 - fa) * (hs[q + TEX] - hs[q + TEX + 1]) + (1.0 - fb) * (hs[q + 1] - hs[q + TEX + 1])
	return 0.0


## The body offset's table, for the columns round x: drawn ground less the sim's base. A function of place alone, so what
## stands there takes the same lift whoever stands there. A few columns a frame; it uploads only if one moved.
func keep_off(x: float, budget: int) -> void:
	if field_world:
		# Another line, other ground under the same columns. The line's axis: x0 following the pair doesn't change it.
		var fr = _S.frame
		var ax := Vector3(fr.py * fr.tz - fr.pz * fr.ty, fr.pz * fr.tx - fr.px * fr.tz, fr.px * fr.ty - fr.py * fr.tx)
		if ax.dot(_off_axis) < 0.9999999 and _frame - _off_stale_at >= RenderLook.TILE_OFF_STALE_FRAMES:
			_off_axis = ax
			_off_stale_at = _frame
			stale_off()
	var c0: int = int(floor(x / SimConst.COL)) - OFF_N / 2
	var done: int = 0
	for q in range(OFF_REACH):
		# Outward from the middle: the columns at the feet first.
		var k: int = OFF_N / 2 + (q + 1) / 2 * (1 if q % 2 == 0 else -1)
		var col: int = posmod(c0 + k, SimConst.NC)
		var idx: int = col % OFF_N
		if _off_col[idx] == col:
			continue
		_off_col[idx] = col
		var cx: float = (float(col) + 0.5) * SimConst.COL
		var d: Vector3 = dir_at(cx, 0.0, _S.frame)
		var b: float = float(_S.base[col]) if not field_world else _sim_ground(d)
		# Dry ground below sea level is drawn at the sea's level; past the shore he's on the water either way.
		_off[idx * 2] = maxf(height_at(d), 0.0) - (b if b >= WorldWater.SHORE_WET else maxf(b, 0.0))
		_off[idx * 2 + 1] = b
		_off_dirty = true
		done += 1
		if done >= budget:
			break
	if _off_dirty:
		_off_dirty = false
		_off_img.set_data(OFF_N, 1, false, Image.FORMAT_RGF, _off.to_byte_array())
		off_tex.update(_off_img)


func _sim_ground(d: Vector3) -> float:
	return WorldField.applyRecords(_S, d.x, d.y, d.z, SimField.heightOf(int(_S.frame.seed), int(_S.frame.gen), 1, d.x, d.y, d.z))


## A finer tile came: the table's columns are read again as the frames go on.
func stale_off() -> void:
	_off_col.fill(-1)


## The lift the shared placement gives what stands at strip x, height y, depth z (bend.gdshaderinc globe_lift's twin).
func lift(x: float, y: float, z: float) -> float:
	var idx: int = posmod(int(floor(x / SimConst.COL)), SimConst.NC) % OFF_N
	var over: float = y - _off[idx * 2 + 1]
	return _off[idx * 2] * (1.0 - smoothstep(RenderLook.TILE_LIFT_FROM, RenderLook.TILE_LIFT_TO, over)) * (1.0 - smoothstep(RenderLook.TILE_LIFT_Z0, RenderLook.TILE_LIFT_Z1, absf(z)))


## The cover's, the trees' and the props' feet: on the planet's ground, a slice a frame. Nothing stands in the sea.
func add_feet(mm: MultiMesh) -> void:
	if mm != null and mm.instance_count > 0:
		_foots.append([mm, 0])


func feet_left() -> int:
	return _foots.size()


## A crater takes what stands in it (Art: the cover inside a crater is removed), a few shapes a frame.
func _crater_slice() -> void:
	if ground == null:
		return
	if ground.crater_gen != _crater_seen:
		_crater_seen = ground.crater_gen
		_crater_k = 0
	var n: int = mini(_crater_k + RenderLook.TILE_CRATER_CHECKS, _standing.size())
	while _crater_k < n:
		var e: Array = _standing[_crater_k]
		_crater_k += 1
		var xw: float = SimWrap.wrap(float(e[2]))
		var i: int = int(xw / SimConst.COL) % SimConst.NC
		var cd: Vector3 = dir_at(float(e[2]), float(e[3]), _S.frame0 if field_world else null)
		if ground.offset_at(_S, i, xw, float(e[3])) + WorldStore.heightDelta(_S, cd.x, cd.y, cd.z) < -6.0 * RenderLook.WS:
			var mm: MultiMesh = e[0]
			var t: Transform3D = mm.get_instance_transform(int(e[1]))
			t.basis = t.basis.scaled(Vector3.ZERO)
			mm.set_instance_transform(int(e[1]), t)
			_standing[_crater_k - 1] = _standing[_standing.size() - 1]
			_standing.pop_back()
			n = mini(n, _standing.size())
			_crater_k -= 1


func _foot_slice(t0: int, budget_us: int) -> void:
	while not _foots.is_empty() and Time.get_ticks_usec() - t0 < budget_us:
		var e: Array = _foots[0]
		var mm: MultiMesh = e[0]
		var k: int = e[1]
		while k < mm.instance_count:
			var t: Transform3D = mm.get_instance_transform(k)
			var d: Vector3 = dir_at(t.origin.x, t.origin.z, _S.frame0 if field_world else null)
			var fh: float = height_at(d)
			t.origin.y = fh
			if fh < WorldWater.SHORE_WET or (field_world and WorldField.recordWater(_S, d.x, d.y, d.z, fh) > 0.0):
				t.basis = t.basis.scaled(Vector3.ZERO)
			else:
				_standing.append([mm, k, t.origin.x, t.origin.z])
			mm.set_instance_transform(k, t)
			k += 1
			if k % 8 == 0 and Time.get_ticks_usec() - t0 > budget_us:
				break
		e[1] = k
		if k >= mm.instance_count:
			_foots.pop_front()
