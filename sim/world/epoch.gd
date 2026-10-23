class_name WorldEpoch
## The calm-moment turn (docs/world/shifting-arena-design.md section 4, docs/world/calm-turn-world.md; Game Design rulings-2026-10-19b.md section 1; Encounter's docs/director/calm-turn.md).
## At a calm moment the arena's ring turns about the pair: a new plane through the pair's point, at most 10 degrees of bearing from the old, at most 4 turns a fight, at least 60 s of fight
## time apart, at most 40 degrees of drift of the ring's axis in all. The ground near the pair stays (a zone of carryUnits each way keeps its columns, its craters, its buildings and people);
## beyond it the ground is the new ring's, with the new ring's places laid fresh. Everything is a function of the match's state and the planet: a turn happens on a tick the sim chooses
## (Encounter's DirCalm.hold, World's calm check), so a replay turns on the same tick, and the slice it reads is computed then if the host has not warmed it.
##
## The calls (nothing runs unless S.epoch is set: the data's turn switch, or setup.arena.turn):
##   ask(S, why, pivotX, side, due) -> candidates       when a moment is coming (Encounter's DirCalm.ask); [] when the caps refuse
##   choose(S, i, k, fallbackDeg)                       Encounter's pick (DirCalm.pick): the turn is decided. k: columns of each ring the sim reads a tick (0 = the data's warmCols); fallbackDeg: the second ring's bearing (2.5 for a landing pick, 0 for none)
##   warmAngles(S)                                      the bearings (signed, degrees) whose ring is read: the angles a swap may use
##   tick(S, hold)                                      each sim tick (SimCore.step): reads k more columns of each of the decided turn's rings (the chosen bearing's and the fallback's if it has one; the warm is the SIM's, a host never
##                                                      calls it: a replay, a determinism run or a tool with no host warms and swaps on the same ticks as play); then, when held (Encounter's hold) and calm (below): swap on the largest warm angle that keeps the pair's ground within moveMax, wait if none does, refuse if even minDeg would not
##   cancel(S)                                          Encounter's: drop a pending pick (the director asks again)
##   calm(S)                                            World's check: no beam, shot, flight, rush, slide, open set piece, water flowing or catastrophe

static var _PI: float = SimMathx.f64("400921fb54442d18")   # pi from its bits, and SimDetMath for every sin and cos: no engine trig in the sim (the parity lint allows no float literal over 15 digits)
static var _jobs: Dictionary = {}   # "worldId/bearing" -> RingJob (the warm read of a candidate ring, kept whole until the swap): derived data outside the state; the state keeps how many columns it was asked for


static func data() -> Dictionary:
	return WorldRingPick.cfg().turn


## Is the turn on for this setup? The data's switch, or setup.arena.turn.
static func enabled(setup: Dictionary) -> bool:
	var a = setup.get("arena", null)
	if a is Dictionary and a.has("turn"):
		return a.turn == true
	return int(data().on) == 1


# ===================================================================== the epoch's state

## The epoch of a new planet match (WorldPlanetWorld.gen, after the world is built): the ring it plays on, the turn counters, the settlements' chords and districts (for the carry). A
## Dictionary, hashed only through n, lastT and drift.
static func begin(S: SimState, seed: int, ring: Dictionary, spec: Dictionary, chords: Array, dlist: Array, sliceHash: int) -> Dictionary:
	return {"seed": seed, "sh": sliceHash, "n": 0, "lastT": 0.0, "drift": 0.0, "c0": spec.c, "ring": spec, "ask": null, "next": null, "warm": [], "refused": 0, "waited": 0, "cold": 0, "chords": chords, "dlist": dlist}


# ===================================================================== the geometry

static func _rot(v: Array, axis: Array, a: float) -> Array:
	var c: float = SimDetMath.cos(a)
	var s: float = SimDetMath.sin(a)
	var k: Array = WorldPlanet._cross(axis, v)
	var d: float = axis[0] * v[0] + axis[1] * v[1] + axis[2] * v[2]
	return [v[0] * c + k[0] * s + axis[0] * d * (1.0 - c), v[1] * c + k[1] * s + axis[1] * d * (1.0 - c), v[2] * c + k[2] * s + axis[2] * d * (1.0 - c)]


## The ring that results from turning `ring` by `deg` degrees (positive is counter-clockwise seen from outside) about its point at column pc: through the same point, the same length, the
## touch-down placed so that column pc is still that point (the fighters' columns do not move). Returns {c, t, cols}.
static func turned(P: WorldPlanet.Planet, spec: Dictionary, pc: int, deg: float) -> Dictionary:
	var cols: int = int(spec.cols)
	var ring: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
	var st: float = ring.st
	var ct: float = ring.ct
	var mid: int = WorldPlanet.touchCol()
	var step: float = SimConst.COL / (P.R * st)
	var a: float = float(pc - mid) * step
	var M: Array = WorldRingPick.ringPoint(ring, a)
	var u: Array = ring.u
	var v: Array = ring.v
	var co: float = SimDetMath.cos(a)
	var si: float = SimDetMath.sin(a)
	var T: Array = WorldPlanet._unit([-u[0] * si + v[0] * co, -u[1] * si + v[1] * co, -u[2] * si + v[2] * co])
	var T2: Array = _rot(T, M, deg * _PI / 180.0)
	var ng: Array = WorldPlanet._unit(WorldPlanet._cross(M, T2))
	var c2: Array = WorldPlanet._unit([M[0] * ct + ng[0] * st, M[1] * ct + ng[1] * st, M[2] * ct + ng[2] * st])
	var ringM: Dictionary = WorldRingPick.ringFrom(c2, cols, M)
	var t2: Array = WorldRingPick.ringPoint(ringM, -a)   # the point (pc - mid) columns before M along the new ring: column mid
	return {"c": c2, "t": t2, "cols": cols}


## The angle in degrees between two rings' axes: how far the loop has drifted.
static func driftOf(c0: Array, c: Array) -> float:
	return WorldPlanet.acosf(SimMathx.jclamp(c0[0] * c[0] + c0[1] * c[1] + c0[2] * c[2], -1.0, 1.0)) * 180.0 / _PI


static func _held(P: WorldPlanet.Planet, ring: Dictionary, i: int) -> bool:
	var lat: float = WorldPlanet.lateral(P, ring, P.px[i], P.py[i], P.pz[i])
	var reach: float = (P.c.cityReach if P.kind[i] == WorldPlanet.KIND_CITY else P.c.townReach) * P.rad[i]
	return absf(lat) < reach


## The candidate turns on a side (+1 toward +x, -1 toward -x), from the pivot column: one for each of the data's bearings, with the places the turn brings into view (places the new ring
## holds that the old did not, within viewUnits of the pivot, with their signed arc from it), the spec of the new ring, and the drift it would make. Encounter picks one (DirCalm.pick).
## Candidates that would pass the drift cap are left out.
static func candidates(P: WorldPlanet.Planet, E: Dictionary, pc: int, side: int) -> Array:
	var d: Dictionary = data()
	var spec: Dictionary = E.ring
	var old: Dictionary = WorldRingPick.ringFrom(spec.c, int(spec.cols), spec.t)
	var out: Array = []
	var mid: int = WorldPlanet.touchCol()
	var s: float = 1.0 if side >= 0 else -1.0
	for deg in d.bearings:
		var ns: Dictionary = turned(P, spec, pc, float(deg) * s)
		var drift: float = driftOf(E.c0, ns.c)
		if drift > float(d.driftDeg):
			continue
		var nr: Dictionary = WorldRingPick.ringFrom(ns.c, int(ns.cols), ns.t)
		var places: Array = []
		var arcR: float = P.R * float(nr.st)
		for i in range(P.n):
			if not _held(P, nr, i) or _held(P, old, i):
				continue
			var q: Array = [P.px[i], P.py[i], P.pz[i]]
			var along: float = WorldPlanet.atan2f(q[0] * nr.v[0] + q[1] * nr.v[1] + q[2] * nr.v[2], q[0] * nr.u[0] + q[1] * nr.u[1] + q[2] * nr.u[2])
			var arc: float = SimWrap.sdx(float(pc) * SimConst.COL, (along * arcR) + float(mid) * SimConst.COL)
			if absf(arc) > float(d.viewUnits):
				continue
			places.append({"id": i, "kind": "city" if P.kind[i] == WorldPlanet.KIND_CITY else "town", "owner": -1, "arc": arc})
		out.append({"bearing": float(deg) * s, "places": places, "spec": ns, "drift": drift})
	return out


# ===================================================================== asking, choosing, preparing

## A calm moment is coming. Returns the candidates Encounter scores, or [] when the caps refuse (4 turns, 60 s of fight apart) or a turn is already decided.
static func ask(S: SimState, why: String, pivotX: float, side: int, due: int) -> Array:
	var E = S.epoch
	if E == null or E.next != null:
		return []
	var d: Dictionary = data()
	if int(E.n) >= int(d.maxTurns) or S.T - float(E.lastT) < float(d.gapSeconds):
		return []
	var P := WorldPlanet.make(int(E.seed))
	var pc: int = posmod(int(round(pivotX / SimConst.COL)), SimConst.NC)
	var cands: Array = candidates(P, E, pc, side)
	if cands.is_empty():
		return []
	E.ask = {"why": why, "pc": pc, "side": side, "due": due, "cands": cands}
	return cands


## Encounter's pick: candidate i, with how it is warmed. k: the columns of each ring the sim reads a tick (Encounter's data; 0 = the data's warmCols). fallbackDeg: the second ring, the bearing a landing
## off the pivot falls back to (2.5 for a landing pick), on the chosen candidate's side; 0 for none (a form pick: its pivot is exact, so one ring, at up to 32 columns a tick). A fallback that is
## not under the chosen bearing, or would pass the drift cap, is left out. Both are kept in E.next and in the hash. From here tick() warms the rings and swaps when held, calm and warm.
static func choose(S: SimState, i: int, k: int = 0, fallbackDeg: float = -1.0) -> void:
	var E = S.epoch
	if E == null or E.ask == null:
		return
	var d: Dictionary = data()
	var cands: Array = E.ask.cands
	var c: Dictionary = cands[clampi(i, 0, cands.size() - 1)]
	var fb: float = float(d.fallbackDeg) if fallbackDeg < 0.0 else fallbackDeg
	if fb > 0.0:
		fb = maxf(fb, float(d.minDeg))
	var warm: Array = [{"deg": c.bearing, "spec": c.spec, "cols": 0}]
	if fb > 0.0 and fb < absf(float(c.bearing)) - 1e-9:
		var sgn: float = 1.0 if float(c.bearing) >= 0.0 else -1.0
		var ns: Dictionary = turned(WorldPlanet.make(int(E.seed)), E.ring, int(E.ask.pc), sgn * fb)
		if driftOf(E.c0, ns.c) <= float(d.driftDeg):
			warm.append({"deg": sgn * fb, "spec": ns, "cols": 0})
	E.next = {"spec": c.spec, "pc": E.ask.pc, "bearing": c.bearing, "drift": c.drift, "why": E.ask.why, "tick": S.tick, "due": E.ask.due, "k": k if k > 0 else int(d.warmCols), "fb": absf(float(warm[1].deg)) if warm.size() > 1 else 0.0}   # tick: the pick's; due: the moment it is for. k and fb are hashed
	E.warm = warm
	E.ask = null
	_dropJobs(S)


## Encounter's cancel (DirCalm): a pending pick whose pair has moved off its pivot is dropped, so the director can ask again.
static func cancel(S: SimState) -> void:
	var E = S.epoch
	if E == null:
		return
	E.next = null
	E.ask = null
	E.warm = []
	_dropJobs(S)


static func _jkey(S: SimState, deg: float) -> String:
	return "%d/%s" % [S.worldId, str(deg)]


static func _dropJobs(S: SimState) -> void:
	var pre: String = "%d/" % S.worldId
	for k in _jobs.keys():
		if String(k).begins_with(pre):
			_jobs.erase(k)


## The sim reads the decided turn's rings, k columns of each a sim tick, from tick() (a Whole ring is 4,800 columns, so k = 64 reads both in 75 ticks, 1.25 s). How far a ring is read is counted in the
## state (`cols`, columns read), so when a ring counts as warm is a function of the ticks since the pick and not of any host. The slices are derived data kept outside the state (`_jobs`): a state
## carried into a process that has not got a job makes it again and reads up to `cols` at once (the same columns, a hitch). True when every ring is read.
static func _warm(S: SimState) -> bool:
	var E = S.epoch
	var n: int = int(E.next.k)
	var all: bool = true
	for w in E.warm:
		if int(w.cols) >= SimConst.NC:
			continue
		var key: String = _jkey(S, float(w.deg))
		var job = _jobs.get(key)
		if job == null:
			var P := WorldPlanet.make(int(E.seed))
			job = WorldPlanet.RingJob.new(P, WorldRingPick.ringFrom(w.spec.c, int(w.spec.cols), w.spec.t))
			if int(w.cols) > 0:
				job.step(int(w.cols))   # the catch-up of a carried state
			_jobs[key] = job
		job.step(n)
		w.cols = int(w.cols) + n
		if job.done:
			w.cols = maxi(int(w.cols), SimConst.NC)
			WorldPlanet.memoRing(int(E.seed), job.ring, job.slice)
		else:
			w.cols = mini(int(w.cols), SimConst.NC - 1)
			all = false
	return all


## The bearings (signed, degrees) whose ring is read: the angles a swap may use. [] when no turn is decided.
static func warmAngles(S: SimState) -> Array:
	var out: Array = []
	var E = S.epoch
	if E == null or E.next == null:
		return out
	for w in E.warm:
		if int(w.cols) >= SimConst.NC:
			out.append(float(w.deg))
	return out


# ===================================================================== calm

## World's part of calm (Encounter's docs/director/calm-turn.md section 1): nothing in flight and nothing moving that the swap would disturb.
static func calm(S: SimState) -> bool:
	if S.beams.size() > 0 or S.shots.size() > 0 or S.waterWin.size() > 0:
		return false
	if S.cata != null or S.world.evtToken != 0.0:
		return false
	for f in S.fighters:
		if f.state == "launched" or f.rush != null or f.slide > 0.0 or f.interior != null:
			return false
	return true


## How far from the pivot the farthest fighter is, in units.
static func _reach(S: SimState, pc: int) -> float:
	var px: float = float(pc) * SimConst.COL
	var smax: float = 0.0
	for f in S.fighters:
		smax = maxf(smax, absf(SimWrap.sdx(px, f.x)))
	return smax


## Each live tick (SimCore.step), with Encounter's hold: a turn that is decided, held and calm swaps. The ring turns about the pivot fixed at the ask, so the ground under a fighter s units from it moves
## s x sin(angle) (Game Design rulings-2026-10-22 5a: at most moveMax, 300 units). There is NO ring read on this tick (Executive Producer, 2026-10-22: the swap must not hitch): the swap uses the largest
## WARM angle (warmAngles) that keeps that within moveMax, which is the chosen bearing when the pair rest on the pivot. If none does the turn waits (it stays decided; Encounter's cancel drops it at
## the end of the moment). If even minDeg (2) would move the pair's ground more than moveMax (the pair about 8,600 units or more off the pivot) the turn is refused: the pick is dropped, so the director
## asks again at its next send. The 300 rule wins over "never under 2 degrees".
static func tick(S: SimState, hold: bool = true) -> void:
	var E = S.epoch
	if E == null or E.next == null:
		return
	_warm(S)
	if not hold or not calm(S):
		return
	var d: Dictionary = data()
	var smax: float = _reach(S, int(E.next.pc))
	if smax * SimDetMath.sin(float(d.minDeg) * _PI / 180.0) > float(d.moveMax):
		E.refused = int(E.refused) + 1
		cancel(S)
		return
	var best = null
	for w in E.warm:
		if int(w.cols) < SimConst.NC:
			continue
		var a: float = absf(float(w.deg))
		if a < float(d.minDeg) - 1e-9 or smax * SimDetMath.sin(a * _PI / 180.0) > float(d.moveMax):
			continue
		if best == null or a > absf(float(best.deg)):
			best = w
	if best == null:
		E.waited = int(E.waited) + 1
		return
	var nx: Dictionary = E.next
	nx.scaled = absf(float(best.deg)) < absf(float(nx.bearing)) - 1e-9
	nx.spec = best.spec
	nx.bearing = best.deg
	nx.drift = driftOf(E.c0, best.spec.c)
	swap(S)


# ===================================================================== the swap

static func _w(px: float, i: int, Z0: float, Z1: float) -> float:
	var s: float = absf(SimWrap.sdx(px, float(i) * SimConst.COL))
	if s <= Z0:
		return 0.0
	if s >= Z1:
		return 1.0
	var t: float = (s - Z0) / (Z1 - Z0)
	return t * t * (3.0 - 2.0 * t)


## The swap, in one step, on a calm tick (docs/world/calm-turn-world.md). The ground inside the zone keeps its columns and fades into the new ring's; the marks (craters, rubble, scorch, cracks)
## fade the same way and are gone outside; the buildings inside the zone stay as they are, with their people; the new ring's other places are laid fresh outside it; the fighters keep their
## columns and are set on the new ground. The epoch moves on. An `arena_turn` event tells Rendering and Camera.
static func swap(S: SimState) -> void:
	var E: Dictionary = S.epoch
	var nx: Dictionary = E.next
	var seed: int = int(E.seed)
	var P := WorldPlanet.make(seed)
	var spec: Dictionary = nx.spec
	var ring: Dictionary = WorldRingPick.ringFrom(spec.c, int(spec.cols), spec.t)
	var job = _jobs.get(_jkey(S, float(nx.bearing)))
	var sl: WorldPlanet.Slice
	if job != null and job.done:
		sl = job.slice
	else:
		E.cold = int(E.cold) + 1   # a ring read on the swap tick: only for a state carried into a process that never warmed it (the same slice, and a hitch). tick() swaps only on a ring the state counts as read, so this stays 0
		sl = WorldPlanet.sliceRing(seed, ring)
	_dropJobs(S)
	var NC: int = SimConst.NC
	var COL: float = SimConst.COL
	var d: Dictionary = data()
	var px: float = float(nx.pc) * COL
	var Z1: float = minf(float(d.carryUnits), SimConst.W * 0.25)
	var Z0: float = Z1 * 0.25
	var wt := PackedFloat32Array()
	wt.resize(NC)
	for i in range(NC):
		wt[i] = _w(px, i, Z0, Z1)
	# --- the ground and its marks
	var newBase: PackedFloat32Array = sl.heights
	for i in range(NC):
		var w: float = wt[i]
		S.base[i] = S.base[i] * (1.0 - w) + newBase[i] * w
		S.deform[i] = S.deform[i] * (1.0 - w)
		S.rubble[i] = S.rubble[i] * (1.0 - w)
		S.scorch[i] = S.scorch[i] * (1.0 - w)
		S.crack[i] = S.crack[i] * (1.0 - w)
	# --- the buildings: those inside the zone stay; the places they belong to are not laid again
	var keep: Array = []
	var keptPlaces: Dictionary = {}
	for b in S.buildings:
		if absf(SimWrap.sdx(px, b.x)) <= Z1:
			keep.append(b)
			keptPlaces[b.place] = true
	var keptChords: Array = []
	for ch in E.chords:
		if keptPlaces.has(ch[0]):
			keptChords.append(ch)
	var newChords: Array = WorldPlanetWorld.chordsOf(sl, newBase)
	var fresh: Array = []
	for ch in newChords:
		if not keptPlaces.has(ch[0]):
			fresh.append(ch)
	# the districts the kept buildings use, in order, and the new ones after them
	var used: Dictionary = {}
	for b in keep:
		used[b.district] = true
	var remap: Dictionary = {}
	var dlist: Array = []
	var dkeys: Array = used.keys()
	dkeys.sort()
	var maxSet: int = -1
	for k in dkeys:
		remap[k] = dlist.size()
		dlist.append(E.dlist[k])
		maxSet = maxi(maxSet, int(E.dlist[k].get("settlement", -1)))
	for b in keep:
		b.district = remap[b.district]
	var wsum: float = 0.0
	for ch in newChords:
		wsum += float(P.people[ch[0]])
	var gen: Dictionary = WorldPlanetWorld.settle(S, P, fresh, wsum, int(E.n) + 1, dlist.size(), maxSet + 1)
	var made: Array = []
	for b in gen.buildings:
		if absf(SimWrap.sdx(px, b.x)) > Z1:
			made.append(b)
	for dd in gen.dlist:
		dlist.append(dd)
	S.buildings = keep + made
	# the biome of each column, and a settlement's ground; then the platforms under every settlement, kept and fresh, over the blended ground
	var chordsAll: Array = keptChords.duplicate()
	for ch in fresh:
		chordsAll.append(ch)
	var cols := PackedByteArray()
	cols.resize(NC)
	for i in range(NC):
		cols[i] = sl.biomes[i] if wt[i] >= 0.5 else S.planetCols[i]
	WorldPlanetWorld.settleBiomes(cols, S.base, chordsAll)
	WorldPlanetWorld.platform(S.base, chordsAll)
	WorldBiomes.planetCols = cols
	S.planetCols = cols
	# --- the derived and per-building state
	S.lanes = WorldLanes.build(S, dlist)
	WorldStructures.buildIndex(S)
	var lot := PackedFloat32Array()
	lot.resize(S.buildings.size())
	lot.fill(0.0)
	S.world.lotAcc = lot
	S.popHist.fill(0.0)
	for b in S.buildings:
		S.popHist[WorldCollateral.histBucket(b.x)] += b.popAlive
	WorldWater.init(S)
	var cr: Array = []
	for c in S.craters:
		if absf(SimWrap.sdx(px, c.x)) <= Z1:
			cr.append(c)
	S.craters = cr
	var sk: Array = []
	for s in S.slides:
		if absf(SimWrap.sdx(px, s.x0)) <= Z1:
			sk.append(s)
	S.slides = sk
	# --- the fighters keep their columns and stand on the new ground
	for f in S.fighters:
		var g: float = WorldTerrain.groundY(S, f.x)
		if f.y < g:
			f.y = g
	# --- the epoch moves on
	S.worldId = WorldBiomes.claim()   # the director's tables and the renderer's caches follow the world
	E.n = int(E.n) + 1
	E.lastT = S.T
	E.drift = nx.drift
	E.ring = spec
	S.planetRing = {"seed": seed, "c": spec.c, "t": spec.t, "cols": spec.cols}   # unhashed: the ring now played on
	E.sh = WorldPlanet.sliceHash(sl)   # the ring now played on, as the state hash sees it
	E.chords = chordsAll
	E.dlist = dlist
	E.next = null
	E.warm = []
	var ev := SimFx._ev(S, "arena_turn")
	ev.n = int(E.n)
	ev.x = px
	ev.amount = float(nx.bearing)
	ev.k = float(nx.drift)
