"""Window 20, third add-on, part 2 (World, 2026-10-26): a warm ring's last step (the fine biomes' blend and the held places: 1.9 ms) moved off the tick the count says the ring is read, into its preparation's first two
ticks.   python mk_p24.py <root>   (after mk_p23.py)
 - sim/world/sites.gd: WorldSites.blend is blendBegin + blendStep (a run of one biome at a time, resumable): the same arithmetic, a few columns a call
 - sim/world/planet.gd: Slice.pending/hctx; readHeld is the blend and _heldPlaces; heldBegin and heldStep make them in steps; RingJob.lazy reads the columns only, then heldStep finishes the job
 - sim/world/epoch.gd: a warm ring's job is lazy; the preparation's tick 0 is half the blend, tick 1 the rest and the places (the ring is memoised then), ticks 2 on are the preparation as it was (prepTicks - 2 ticks
   for it); the slice's hash waits (one column short) until the blend is done. The state after the swap is the same: the ring is read on the same tick, the swap is allowed on the same tick (prepTicks after)."""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def sites(s):
    a = s.index("static func blend(P: WorldPlanet.Planet, S: WorldPlanet.Slice) -> void:")
    b = s.index("\tS.fine = out\n", a) + len("\tS.fine = out\n")
    new = '''static func blend(P: WorldPlanet.Planet, S: WorldPlanet.Slice) -> void:
	var ctx: Dictionary = blendBegin(P, S)
	if not ctx.is_empty():
		blendStep(S, ctx, 1 << 40)


## The start of a stepped blend ({} when there is nothing to blend): the runs are visited in order from the first border, as blend always did, a few columns a blendStep.
static func blendBegin(P: WorldPlanet.Planet, S: WorldPlanet.Slice) -> Dictionary:
	if not _loaded:
		_load()
	var n: int = S.fine.size()
	if n == 0 or K_E_W <= 0 or K_E_MAX <= 0.0:
		return {}
	var fine: PackedByteArray = S.fine
	var s0: int = -1
	for i in range(n):
		if fine[i] != fine[(i + n - 1) % n]:
			s0 = i
			break
	if s0 < 0:
		return {}   # one biome all the way round
	var seed: int = (P.seed + K_E_SEED) & 0xFFFFFFFF
	return {"n": n, "s0": s0, "fine": fine, "out": fine.duplicate(),
		"x1": SimRng._fmix((seed ^ _fnv("ecotone")) & SimRng.MASK),   # SimRng.keyed(seed, key, n) is _fmix(x ^ imul(n, 0x9E3779B1)) with x = _fmix(seed ^ fnv(key)): the first half, once
		"x2": SimRng._fmix((seed ^ _fnv("ecotone.big")) & SimRng.MASK),
		"i": 0, "k": -1, "rl": 0, "f": 0, "prev": 0, "next": 0, "pOk": false, "nOk": false}


## Up to `units` more columns of the blend (a column of an active run is one unit, a run that is not active a sixteenth of its length); true when the slice's fine and stored biomes are the blended ones.
static func blendStep(S: WorldPlanet.Slice, ctx: Dictionary, units: int) -> bool:
	var n: int = ctx.n
	var s0: int = ctx.s0
	var fine: PackedByteArray = ctx.fine
	var out: PackedByteArray = ctx.out
	var x1: int = ctx.x1
	var x2: int = ctx.x2
	var left: int = units
	while int(ctx.i) < n and left > 0:
		var i: int = ctx.i
		if int(ctx.k) < 0:
			var a: int = (s0 + i) % n
			var f: int = fine[a]
			var rl: int = 1
			while i + rl < n and fine[(s0 + i + rl) % n] == f:
				rl += 1
			var prev: int = fine[(a + n - 1) % n]
			var next: int = fine[(s0 + i + rl) % n]
			var act: bool = false
			var pOk: bool = false
			var nOk: bool = false
			if f < _inset.size() and _inset[f] == 1:
				pOk = prev < _inset.size() and _inset[prev] == 1 and prev != f
				nOk = next < _inset.size() and _inset[next] == 1 and next != f
				act = pOk or nOk
			if not act:
				ctx.i = i + rl
				left -= maxi(1, rl / 16)
				continue
			ctx.rl = rl
			ctx.f = f
			ctx.prev = prev
			ctx.next = next
			ctx.pOk = pOk
			ctx.nOk = nOk
			ctx.k = 0
		var rl2: int = ctx.rl
		var pOk2: bool = ctx.pOk
		var nOk2: bool = ctx.nOk
		var prev2: int = ctx.prev
		var next2: int = ctx.next
		var k0: int = ctx.k
		var kend: int = mini(rl2, k0 + left)
		for k in range(k0, kend):
			var dl: int = k + 1
			var dr: int = rl2 - k
			var g: int = -1
			var d: int = 0
			if pOk2 and (not nOk2 or dl <= dr):
				g = prev2
				d = dl
			elif nOk2:
				g = next2
				d = dr
			if g < 0 or d > K_E_W:
				continue
			var p: float = K_E_MAX * (1.0 - float(d - 1) / float(K_E_W))
			var col: int = (s0 + i + k) % n
			var u: float = 0.5 * (float(SimRng._fmix(x1 ^ SimRng.imul((col / K_E_CELL) & SimRng.MASK, 0x9E3779B1))) + float(SimRng._fmix(x2 ^ SimRng.imul((col / (4 * K_E_CELL)) & SimRng.MASK, 0x9E3779B1)))) / 4294967296.0   # two scales, so the patches cluster
			if u < p:
				out[col] = g
		left -= kend - k0
		ctx.k = kend
		if kend >= rl2:
			ctx.i = i + rl2
			ctx.k = -1
	if int(ctx.i) < n:
		return false
	for c in range(n):
		if out[c] != fine[c]:
			S.biomes[c] = WorldClimate.aliasOf(int(out[c]))
	S.fine = out
	return true
'''
    return s[:a] + new + s[b:]


def planet(s):
    s = rep(s, '''	var circ: Dictionary = {}
	var T: Array = []
	var seed: int = 0
''', '''	var circ: Dictionary = {}
	var T: Array = []
	var seed: int = 0
	var pending: bool = false                 # a warm ring's columns are read and its blend and held places are not yet (WorldPlanet.heldBegin, heldStep)
	var hctx = null
''')
    s = rep(s, '''static func readHeld(P: Planet, S: Slice, standing: PackedByteArray = PackedByteArray()) -> void:
	if P.gen >= 2:
		WorldSites.blend(P, S)   # window 4: the fine biomes meet in a ragged band (the last step of every read, whole or stepped, before anything hashes the biomes)
	var c: Dictionary = P.c
''', '''static func readHeld(P: Planet, S: Slice, standing: PackedByteArray = PackedByteArray()) -> void:
	if P.gen >= 2:
		WorldSites.blend(P, S)   # window 4: the fine biomes meet in a ragged band (the last step of every read, whole or stepped, before anything hashes the biomes)
	_heldPlaces(P, S, standing)


## The last step of a read in two: the blend (stepped) and then the places. `heldBegin` marks a slice whose columns are read as pending; `heldStep` spends up to `units` of the blend (a column a unit) and, when it
## is done, lays the places; true when the slice is as readHeld leaves it (the same one, to the bit).
static func heldBegin(P: Planet, S: Slice) -> void:
	S.pending = true
	S.hctx = WorldSites.blendBegin(P, S) if P.gen >= 2 else {}


static func heldStep(P: Planet, S: Slice, units: int, standing: PackedByteArray = PackedByteArray()) -> bool:
	if not S.pending:
		return true
	if P.gen >= 2 and not S.hctx.is_empty():
		if not WorldSites.blendStep(S, S.hctx, units):
			return false
	_heldPlaces(P, S, standing)
	S.pending = false
	S.hctx = null
	return true


static func _heldPlaces(P: Planet, S: Slice, standing: PackedByteArray) -> void:
	var c: Dictionary = P.c
''')
    s = rep(s, '''	var i: int = 0
	var done: bool = false

	func _init(p: WorldPlanet.Planet, r: Dictionary) -> void:''', '''	var i: int = 0
	var done: bool = false
	var lazy: bool = false     # the columns only: the blend and the places are left to heldStep (the calm turn's warm: its preparation does them a few ticks later)
	var _began: bool = false

	func _init(p: WorldPlanet.Planet, r: Dictionary) -> void:''')
    s = rep(s, '''		i = j
		if i >= SimConst.NC:
			WorldPlanet.readHeld(P, slice)
			done = true
		return done
''', '''		i = j
		if i >= SimConst.NC:
			if lazy:
				if not _began:
					_began = true
					WorldPlanet.heldBegin(P, slice)
				return false
			WorldPlanet.readHeld(P, slice)
			done = true
		return done

	## A lazy job's last step: up to `units` of the blend, then the places; true when the job is done (the slice whole).
	func heldStep(units: int) -> bool:
		if done:
			return true
		if i < SimConst.NC or not _began:
			return false
		if WorldPlanet.heldStep(P, slice, units):
			done = true
		return done
''')
    return s


def epoch(s):
    s = rep(s, '''		job = WorldPlanet.RingJob.new(P, WorldRingPick.ringFrom(w.spec.c, int(w.spec.cols), w.spec.t))
		if int(w.cols) > 0:
			job.readTo(int(w.cols))   # the catch-up of a carried state
''', '''		job = WorldPlanet.RingJob.new(P, WorldRingPick.ringFrom(w.spec.c, int(w.spec.cols), w.spec.t))
		job.lazy = true   # the columns on the warm ticks; the blend and the places in the preparation's first two ticks
		if int(w.cols) > 0:
			job.readTo(int(w.cols))   # the catch-up of a carried state
''')
    s = rep(s, '''			if int(w.ptk) < 0:
				w.ptk = 0   # read: its preparation's ticks begin (the first is this one: _prep, below)
			WorldPlanet.memoRing(int(E.seed), job.ring, job.slice)
''', '''			if int(w.ptk) < 0:
				w.ptk = 0   # read: its preparation's ticks begin (the first is this one: _prep, below)
''')
    s = rep(s, '''		_hashTo(ep, job.slice, mini(int(w.cols), SimConst.NC))   # the slice's heights are hashed as the columns are counted read (a job a host has read ahead is not the count)
		if int(w.ptk) >= 0 and int(w.ptk) < pt:
			_prepTo(S, E, pl, ep, job.slice, int(w.ptk), pt)   # the preparation's tick p of prepTicks
			w.ptk = int(w.ptk) + 1
''', '''		_hashTo(ep, job.slice, mini(int(w.cols), SimConst.NC - 1 if job.slice.pending or not job.done else SimConst.NC))   # the slice's heights are hashed as the columns are counted read (a job a host has read ahead is not the count); the biomes wait for the blend
		if int(w.ptk) >= 0 and int(w.ptk) < pt:
			var p: int = int(w.ptk)
			var ht: int = mini(HELD_TICKS, pt - 1)
			if p < ht:   # the ring's last step, the blend and the held places, off the tick it was read on: half the blend, then the rest and the places
				if not job.done:
					job.heldStep(SimConst.NC / ht if p < ht - 1 else 1 << 30)
				if p == ht - 1:
					WorldPlanet.memoRing(int(E.seed), job.ring, job.slice)   # whole now: where sliceRing finds it
			else:
				_prepTo(S, E, pl, ep, job.slice, p - ht, pt - ht)   # the preparation's tick of prepTicks - HELD_TICKS
			w.ptk = p + 1
''')
    s = rep(s, '''const HASH_STEP: int = 3000   # bytes of a ring's slice hash made a warm tick
''', '''const HASH_STEP: int = 3000   # bytes of a ring's slice hash made a warm tick
const HELD_TICKS: int = 2     # of the preparation's prepTicks, the first ones are the ring's blend and held places (the rest are the preparation proper)
''')
    # a swap that finds its ring not yet whole (a state carried into another process) finishes it with the same functions
    s = rep(s, '''static func _prepTo(S: SimState, E: Dictionary, pl: Dictionary, ep: Dictionary, sl: WorldPlanet.Slice, p: int, pt: int) -> void:
''', '''static func _prepTo(S: SimState, E: Dictionary, pl: Dictionary, ep: Dictionary, sl: WorldPlanet.Slice, p: int, pt: int) -> void:
	if sl.pending:   # a ring whose blend and places are not made (a preparation begun again): made now, the same
		WorldPlanet.heldStep(WorldPlanet.make(sl.seed), sl, 1 << 30)
''')
    s = rep(s, '''	if job != null and job.done:
		sl = job.slice
''', '''	if job != null and job.i >= SimConst.NC and not job.slice.pending:   # read whole (a lazy job's `done` is set by its preparation's ticks: a lost preparation finds the slice whole all the same)
		sl = job.slice
''')
    return s


rw(R, 'sim/world/sites.gd', sites)
rw(R, 'sim/world/planet.gd', planet)
rw(R, 'sim/world/epoch.gd', epoch)
print('p24 applied')
