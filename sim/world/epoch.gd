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
const WT_STEP: int = 600      # columns of the carry weights made a warm tick
const HASH_STEP: int = 3000   # bytes of a ring's slice hash made a warm tick
const HELD_TICKS: int = 2     # of the preparation's prepTicks, the first ones are the ring's blend and held places (the rest are the preparation proper)
static var _plans: Dictionary = {}   # worldId -> the swap's preparation: {wt, wtN, e: {ring key -> entry}}: derived data outside the state, made by the warm ticks from what the swap does not change
static var _jobs: Dictionary = {}   # "worldId/bearing" -> RingJob (the warm read of a candidate ring, kept whole until the swap): derived data outside the state; the state keeps how many columns it was asked for
static var _owners: Dictionary = {}   # worldId -> the instance id of the sim that made the entries (release drops what a disposed sim made, whichever world id it has by then)
static var _retired: Array = []   # [[worldId, owner (the sim's instance id), the S.tick the world's jobs and preparation go at]]: a swap leaves the world it turned away from in _plans and _jobs for KEEP_TICKS (see swap)
static var coldCount: int = 0     # process diagnostics, not state (a rolled-back re-run of a swap must leave the state as a straight run does): swaps that read their ring on the swap tick
static var unprepCount: int = 0   # ... and swaps that made their preparation on the swap tick
const KEEP_TICKS: int = 21        # the rollback window of 20 + 1: a rollback can run a swap again at most this many ticks after it


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
	return {"seed": seed, "sh": sliceHash, "n": 0, "lastT": 0.0, "drift": 0.0, "c0": spec.c, "ring": spec, "ask": null, "next": null, "warm": [], "refused": 0, "waited": 0, "chords": chords, "dlist": dlist}


# ===================================================================== the geometry

static func _rot(v: Array, axis: Array, a: float) -> Array:
	var c: float = SimDetMath.cos(a)
	var s: float = SimDetMath.sin(a)
	var k: Array = WorldPlanet._cross(axis, v)
	var d: float = axis[0] * v[0] + axis[1] * v[1] + axis[2] * v[2]
	return [v[0] * c + k[0] * s + axis[0] * d * (1.0 - c), v[1] * c + k[1] * s + axis[1] * d * (1.0 - c), v[2] * c + k[2] * s + axis[2] * d * (1.0 - c)]


## The ring that results from turning `ring` by `deg` degrees (positive is counter-clockwise seen from outside) about its point at column pc: through the same point, the same length, the
## touch-down placed so that column pc is still that point (the fighters' columns do not move). Returns {c, t, cols}.
static func turned(P: WorldPlanet.Planet, spec: Dictionary, pc: int, deg: float, midCol: int = -1) -> Dictionary:
	var cols: int = int(spec.cols)
	var ring: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
	var st: float = ring.st
	var ct: float = ring.ct
	var mid: int = WorldPlanet.touchCol() if midCol < 0 else midCol   # midCol: the ring's own middle column, for a caller outside a match (the campaign's planner: SimConst.NC is not its ring's)
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


## The campaign's turn (docs/world/campaign-route.md; campaign.md 2.3: between columns the ring turns at a calm moment so the next column's places lie along it): the same machinery as a fight's turn with one candidate,
## the planner's bearing (WorldCampaign.column's `turn.deg`, up to the campaign data's largest, not the fight's 10 degrees), and none of the fight's caps (four turns, 60 s apart, 40 degrees of drift): a campaign
## turn is not counted in `n`. Returns the one candidate (as `ask` does), or [] when a turn is already decided or the bearing is under minDeg. Encounter picks it with `choose(S, 0, k, 0.0)` (no fallback ring).
static func askCampaign(S: SimState, pivotX: float, deg: float, due: int) -> Array:
	var E = S.epoch
	if E == null or E.next != null or absf(deg) < float(data().minDeg):
		return []
	var P := WorldPlanet.make(int(E.seed))
	var pc: int = posmod(int(round(pivotX / SimConst.COL)), SimConst.NC)
	var ns: Dictionary = turned(P, E.ring, pc, deg)
	var cand: Dictionary = {"bearing": deg, "places": [], "spec": ns, "drift": driftOf(E.c0, ns.c)}
	E.ask = {"why": "campaign", "pc": pc, "side": 1 if deg >= 0.0 else -1, "due": due, "cands": [cand], "camp": true}
	return [cand]


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
	var warm: Array = [{"deg": c.bearing, "spec": c.spec, "cols": 0, "ptk": -1}]
	if fb > 0.0 and fb < absf(float(c.bearing)) - 1e-9:
		var sgn: float = 1.0 if float(c.bearing) >= 0.0 else -1.0
		var ns: Dictionary = turned(WorldPlanet.make(int(E.seed)), E.ring, int(E.ask.pc), sgn * fb)
		if driftOf(E.c0, ns.c) <= float(d.driftDeg):
			warm.append({"deg": sgn * fb, "spec": ns, "cols": 0, "ptk": -1})
	E.next = {"spec": c.spec, "pc": E.ask.pc, "bearing": c.bearing, "drift": c.drift, "why": E.ask.why, "camp": bool(E.ask.get("camp", false)), "tick": S.tick, "due": E.ask.due, "k": k if k > 0 else int(d.warmCols), "fb": absf(float(warm[1].deg)) if warm.size() > 1 else 0.0}   # tick: the pick's; due: the moment it is for. k and fb are hashed
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
	_dropWorld(S.worldId)


static func _dropWorld(wid: int) -> void:
	_owners.erase(wid)
	_plans.erase(wid)
	var pre: String = "%d/" % wid
	for k in _jobs.keys():
		if String(k).begins_with(pre):
			_jobs.erase(k)


## The swap leaves its world's ring jobs and preparation in place for KEEP_TICKS, keyed by the world it turned away from (the new world has its own id): a rollback that restores a state of that world and
## runs the swap again finds them, and the re-run is the swap it was (no ring read on the tick, no preparation made on it) instead of the cold one. A swap run again renews the term.
static func _retire(S: SimState) -> void:
	var me: int = S.get_instance_id()
	for r in _retired:
		if int(r[0]) == S.worldId and int(r[1]) == me:
			r[2] = S.tick + KEEP_TICKS
			return
	_retired.append([S.worldId, me, S.tick + KEEP_TICKS])


## Drops what has aged out, for this sim's retired worlds: called each tick, free when nothing is retired.
static func _sweep(S: SimState) -> void:
	var me: int = S.get_instance_id()
	var keep: Array = []
	for r in _retired:
		if int(r[1]) == me and S.tick >= int(r[2]):
			_dropWorld(int(r[0]))
		else:
			keep.append(r)
	_retired = keep


## A sim is disposed (SimCore.dispose): its world's jobs and preparation and every world it retired go with it. They are derived data in static dictionaries, so nothing else would drop them.
static func release(S: SimState) -> void:
	var me: int = S.get_instance_id()
	var keep: Array = []
	for r in _retired:
		if int(r[1]) == me:
			_dropWorld(int(r[0]))
		else:
			keep.append(r)
	_retired = keep
	for wid in _owners.keys():
		if int(_owners[wid]) == me:
			_dropWorld(int(wid))
	_dropWorld(S.worldId)


## The sim reads the decided turn's rings, k columns of each a sim tick, from tick() (a Whole ring is 4,800 columns, so k = 64 reads both in 75 ticks, 1.25 s). How far a ring is read is counted in the
## state (`cols`, columns read), so when a ring counts as warm is a function of the ticks since the pick and not of any host. The slices are derived data kept outside the state (`_jobs`): a state
## carried into a process that has not got a job makes it again and reads up to `cols` at once (the same columns, a hitch). True when every ring is read.
static func _warm(S: SimState) -> bool:
	var E = S.epoch
	var n: int = _share(E)
	var all: bool = true
	for w in E.warm:
		if int(w.cols) >= SimConst.NC:
			continue
		var job = _jobFor(S, E, w)
		var target: int = int(w.cols) + n
		job.readTo(target)   # up to the counted columns: a job a host has read ahead is there already
		w.cols = target
		if target >= SimConst.NC:   # the count says read (never how far a host's job has got: a replay warms on the same tick)
			w.cols = maxi(int(w.cols), SimConst.NC)
			if int(w.ptk) < 0:
				w.ptk = 0   # read: its preparation's ticks begin (the first is this one: _prep, below)
		else:
			w.cols = mini(int(w.cols), SimConst.NC - 1)
			all = false
	_prep(S, E)
	return all


## The columns a warm tick reads of each ring: the pick's k each (the turn data's `warmTotal` 0, as always), or k in all shared among the warm rings (`warmTotal` 1: a launch pick's two rings cost a tick what a form pick's one does).
static func _share(E: Dictionary) -> int:
	var n: int = int(E.next.k)
	if int(data().get("warmTotal", 0)) == 1 and E.warm.size() > 1 and WorldClimate.genNow() >= 2:   # gen 2 only: a gen 1 pick's k is each ring's, as always
		n = maxi(1, n / E.warm.size())
	return n


## The warm ring's job (derived data outside the state): made when first asked, caught up to the columns the state counts.
static func _jobFor(S: SimState, E: Dictionary, w: Dictionary):
	var key: String = _jkey(S, float(w.deg))
	var job = _jobs.get(key)
	if job == null:
		var P := WorldPlanet.make(int(E.seed))
		job = WorldPlanet.RingJob.new(P, WorldRingPick.ringFrom(w.spec.c, int(w.spec.cols), w.spec.t))
		job.lazy = true   # the columns on the warm ticks; the blend and the places in the preparation's first two ticks
		if int(w.cols) > 0:
			job.readTo(int(w.cols))   # the catch-up of a carried state
		_jobs[key] = job
		_owners[S.worldId] = S.get_instance_id()
	return job


## A host's idle time (Rendering's SimHost, a frame with time left): steps the decided turn's rings' jobs on past the columns the state has counted, `units` of about 20 us (a column of gen 2 is about 3) in all,
## the ring nearest to done first. The state is not touched (the slices are derived data outside it): a ring counts as read, and the swap happens, on the same ticks whatever a host does; the sim's tick then finds
## its columns read and reads nothing. Returns the columns read now. A host calls it between sim ticks (never from inside one).
static func readAhead(S: SimState, units: int, colUnits: int = 3) -> int:
	var E = S.epoch
	if E == null or E.next == null:
		return 0
	var left: int = maxi(0, units / maxi(1, colUnits))
	var did: int = 0
	var best: Array = []
	for w in E.warm:
		var job = _jobFor(S, E, w)
		if not job.done:
			best.append(job)
	best.sort_custom(func(a, b): return a.i > b.i)
	for job in best:
		if left <= 0:
			break
		var from: int = job.i
		job.step(left)
		did += job.i - from
		left -= job.i - from
	return did


## What is warming, for a host that reads ahead: [[columns read now, columns of the ring, counted by the state]] a warm ring.
static func warmPlan(S: SimState) -> Array:
	var E = S.epoch
	var out: Array = []
	if E == null or E.next == null:
		return out
	for w in E.warm:
		var job = _jobs.get(_jkey(S, float(w.deg)))
		out.append([int(job.i) if job != null else 0, SimConst.NC, int(w.cols)])
	return out


# ===================================================================== the swap's preparation

## The swap's preparation, a little each warm tick (Performance: the swap tick cost 8.7 ms, 38 to 46 at x4). What the swap computes without reading what it swaps is a pure function of the decided
## turn and of state that does not change while a turn waits (the buildings' places and columns, the base ground, the planet's biome table, the epoch's places and districts): the carry weights
## (from the pivot), the new ring's slice hash, the kept and fresh places, the fresh places' layouts, the blended and platformed ground and the biome table. They are made here, one step of each a
## tick, once a ring is read, for every warm ring (the swap may use either), and the swap takes what is ready; what is not it makes itself with the same functions, so the turn is the same
## either way (`E.unprep` counts a swap that had to). The marks (deform, rubble, scorch, cracks) change in a fight and are blended at the swap.
static func _plan(S: SimState) -> Dictionary:
	var pl = _plans.get(S.worldId)
	if pl == null:
		var wt := PackedFloat32Array()
		wt.resize(SimConst.NC)
		pl = {"wt": wt, "wtN": 0, "e": {}}
		_plans[S.worldId] = pl
		_owners[S.worldId] = S.get_instance_id()
	return pl


static func _zone() -> Array:
	var d: Dictionary = data()
	var Z1: float = minf(float(d.carryUnits), SimConst.W * 0.25)
	return [Z1 * 0.25, Z1]


static func _wtStep(E: Dictionary, pl: Dictionary, n: int) -> void:
	var NC: int = SimConst.NC
	var z: Array = _zone()
	var px: float = float(E.next.pc) * SimConst.COL
	var i1: int = mini(NC, int(pl.wtN) + n)
	for i in range(int(pl.wtN), i1):
		pl.wt[i] = _w(px, i, z[0], z[1])
	pl.wtN = i1


static func _prep(S: SimState, E: Dictionary) -> void:
	var pl: Dictionary = _plan(S)
	_wtStep(E, pl, WT_STEP)
	var pt: int = int(data().prepTicks)
	for w in E.warm:
		var key: String = _jkey(S, float(w.deg))
		var job = _jobs.get(key)
		if job == null:
			if int(w.ptk) < 0 or int(w.ptk) >= pt:
				continue
			job = _jobFor(S, E, w)   # read and preparing, its job gone (a rollback to before the swap, a state carried into another process): made again, read up to the count at once
		var ep = pl.e.get(key)
		if ep == null:
			ep = _entry()
			pl.e[key] = ep
		_hashTo(ep, job.slice, mini(int(w.cols), SimConst.NC - 1 if job.slice.pending or not job.done else SimConst.NC))   # the slice's heights are hashed as the columns are counted read (a job a host has read ahead is not the count); the biomes wait for the blend
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


static func _entry() -> Dictionary:
	return {"pos": 0, "h": 0x811c9dc5, "sh": -1, "stage": 0, "fi": 0, "si": 0, "ready": false}


## The slice hash (WorldPlanet.sliceHash: FNV over the heights' bytes, then the biomes') as far as `ncols` columns are read: the heights as they come, the biomes once the ring is whole. Catches up from
## wherever it is, so a lost preparation is made again to the same value.
static func _hashTo(ep: Dictionary, sl: WorldPlanet.Slice, ncols: int) -> void:
	if int(ep.sh) >= 0:
		return
	var NC: int = SimConst.NC
	var h: int = ep.h
	var pos: int = ep.pos
	var upto: int = mini(ncols, NC)
	if pos < upto * 4:
		var hb: PackedByteArray = sl.heights.slice(pos / 4, upto).to_byte_array()
		for i in range(hb.size()):
			h = SimRng.imul((h ^ hb[i]) & WorldPlanet.MASK, 0x01000193)
		pos = upto * 4
	if ncols >= NC:
		for i in range(NC):
			h = SimRng.imul((h ^ sl.biomes[i]) & WorldPlanet.MASK, 0x01000193)
		ep.sh = h & WorldPlanet.MASK
		pos = NC * 5
	ep.h = h
	ep.pos = pos


## The preparation due by tick p of pt: the stage that needs the whole slice at p 0, then the new places' layouts spread so that all are laid by the last tick, and the assembly on it. Anything due that
## is not yet made (a preparation lost and begun again) is made now, so the state after tick p is the same whatever came before.
static func _prepTo(S: SimState, E: Dictionary, pl: Dictionary, ep: Dictionary, sl: WorldPlanet.Slice, p: int, pt: int) -> void:
	if sl.pending:   # a ring whose blend and places are not made (a preparation begun again): made now, the same
		WorldPlanet.heldStep(WorldPlanet.make(sl.seed), sl, 1 << 30)
	if int(pl.wtN) < SimConst.NC:
		_wtStep(E, pl, SimConst.NC)
	_hashTo(ep, sl, SimConst.NC)
	if int(ep.stage) == 0:
		_geomStep(S, E, pl, ep, sl)
	var F: int = ep.fresh.size()
	if sl.fine.size() == SimConst.NC and S.planetRing.has("fine"):   # a gen 2 ring: the layouts, the assembly, the trees and the lakes are F + 3 steps spread over the ticks (si counts them)
		var T: int = F + 3
		var wantG: int = T if p >= pt - 1 else (T * p) / maxi(1, pt - 1)
		while int(ep.si) < wantG and not bool(ep.ready):
			_geomStep(S, E, pl, ep, sl)
		while p >= pt - 1 and not bool(ep.ready):
			_geomStep(S, E, pl, ep, sl)
		return
	var want: int = F if p >= pt - 1 else (F * p) / maxi(1, pt - 1)
	while int(ep.fi) < want:
		_geomStep(S, E, pl, ep, sl)
	if p >= pt - 1 and not bool(ep.ready):
		_geomStep(S, E, pl, ep, sl)


## One step of a ring's geometry (once the weights are whole): stage 0 the kept and fresh places and the blended ground, then one fresh place's layout, then the assembly (the biome table and the platforms
## over the blended ground).
static func _geomStep(S: SimState, E: Dictionary, pl: Dictionary, ep: Dictionary, sl: WorldPlanet.Slice) -> void:
	if bool(ep.ready) or int(pl.wtN) < SimConst.NC:
		return
	var NC: int = SimConst.NC
	var P := WorldPlanet.make(int(E.seed))
	if int(ep.stage) == 0:
		var z: Array = _zone()
		var px: float = float(E.next.pc) * SimConst.COL
		var newBase: PackedFloat32Array = sl.heights
		var nb := PackedFloat32Array()
		nb.resize(NC)
		for i in range(NC):
			nb[i] = S.base[i] * (1.0 - pl.wt[i]) + newBase[i] * pl.wt[i]
		var keep: Array = []
		var keptPlaces: Dictionary = {}
		for b in S.buildings:
			if absf(SimWrap.sdx(px, b.x)) <= z[1]:
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
		var wsum: float = 0.0
		for ch in newChords:
			wsum += float(P.people[ch[0]])
		ep["nb"] = nb
		ep["keep"] = keep
		ep["keptChords"] = keptChords
		ep["fresh"] = fresh
		ep["remap"] = remap
		ep["dlist"] = dlist
		ep["maxSet"] = maxSet
		ep["wsum"] = wsum
		ep["genB"] = []
		ep["stage"] = 1
		return
	if int(ep.fi) < ep.fresh.size():
		# a fresh place's layout, laid on the blended ground: WorldSettle trims a place's span against S.base, so it is lent for the call
		var saved: PackedFloat32Array = S.base
		S.base = ep.nb
		var g: Dictionary = WorldPlanetWorld.settle(S, P, [ep.fresh[int(ep.fi)]], float(ep.wsum), int(E.n) + 1, ep.dlist.size(), int(ep.maxSet) + 1 + int(ep.fi))
		S.base = saved
		for b in g.buildings:
			ep.genB.append(b)
		for dd in g.dlist:
			ep.dlist.append(dd)
		ep.fi = int(ep.fi) + 1
		ep.si = int(ep.si) + 1
		return
	if ep.has("g2"):   # a gen 2 ring's last two steps: its trees (only where the ring is taken), then its lakes
		if int(ep.g2) == 0:
			ep["trees"] = WorldGround.layTrees(ep.fcols, ep.cols, ep.base, int(ep.sh), pl.wt)
			ep["g2"] = 1
		else:
			ep["lakes"] = WorldLakes.onlyNew(WorldLakes.plan(ep.base, ep.chordsAll, ep.fcols, ep.cols), pl.wt)
			if WorldRivers.enabled():   # window 14: the new ring's rivers, only where the ring is wholly new, cut into its prepared ground
				var rsp: Dictionary = WorldPlanetWorld.specOf(sl.circ)
				if not rsp.is_empty():
					var rv: Array = WorldLakes.onlyNew(WorldRivers.plan(WorldPlanet.make(int(E.seed)), rsp, ep.base, ep.chordsAll, ep.fcols, ep.cols, ep.lakes), pl.wt)
					WorldRivers.carve(ep.base, rv)
					ep["lakes"] = ep.lakes + rv
			ep["trees"] = WorldLakes.dryTrees(ep.trees, ep.lakes, NC)
			ep["ready"] = true
		ep.si = int(ep.si) + 1
		return
	var z2: Array = _zone()
	var px2: float = float(E.next.pc) * SimConst.COL
	var made: Array = []
	for b in ep.genB:
		if absf(SimWrap.sdx(px2, b.x)) > z2[1]:
			made.append(b)
	var chordsAll: Array = ep.keptChords.duplicate()
	for ch in ep.fresh:
		chordsAll.append(ch)
	var cols := PackedByteArray()
	cols.resize(NC)
	for i in range(NC):
		cols[i] = sl.biomes[i] if pl.wt[i] >= 0.5 else S.planetCols[i]
	var nbf: PackedFloat32Array = ep.nb.duplicate()
	WorldPlanetWorld.settleBiomes(cols, nbf, chordsAll)
	WorldPlanetWorld.platform(nbf, chordsAll)
	if sl.fine.size() == NC and S.planetRing.has("fine"):   # a gen 2 ring: the fine biomes blend as the stored ones do, and the ring's trees are laid on them (the swap keeps the old ring's where the ground is kept)
		var fcols := PackedByteArray()
		fcols.resize(NC)
		var oldF: PackedByteArray = S.planetRing.fine
		for i in range(NC):
			fcols[i] = sl.fine[i] if pl.wt[i] >= 0.5 else oldF[i]
		ep["fcols"] = fcols
		ep["g2"] = 0   # the trees and the lakes are the next two steps
	ep["made"] = made
	ep["chordsAll"] = chordsAll
	ep["cols"] = cols
	ep["base"] = nbf
	ep.si = int(ep.si) + 1
	if not ep.has("g2"):
		ep["ready"] = true


## The bearings (signed, degrees) whose ring is read: the angles a swap may use. [] when no turn is decided.
static func warmAngles(S: SimState) -> Array:
	var out: Array = []
	var E = S.epoch
	if E == null or E.next == null:
		return out
	for w in E.warm:
		if _usable(w):
			out.append(float(w.deg))
	return out


## A warm ring a swap may use: read, and its preparation due (data prepTicks ticks after it was read: `ptk` counts them in the state).
static func _usable(w: Dictionary) -> bool:
	return int(w.cols) >= SimConst.NC and int(w.ptk) >= int(data().prepTicks)


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
## s x sin(angle) (Game Design rulings-2026-10-22 5a: at most moveMax, 300 units; 450 from rulings-2026-10-23 ruling 3, at every size). There is NO ring read on this tick (Executive Producer, 2026-10-22: the swap must not hitch): the swap uses the largest
## WARM angle (warmAngles) that keeps that within moveMax, which is the chosen bearing when the pair rest on the pivot. If none does the turn waits (it stays decided; Encounter's cancel drops it at
## the end of the moment). If even minDeg (2) would move the pair's ground more than moveMax (the pair about 12,900 units or more off the pivot at 450) the turn is refused: the pick is dropped, so the director
## asks again at its next send. The moveMax rule wins over "never under 2 degrees".
static func tick(S: SimState, hold: bool = true) -> void:
	var E = S.epoch
	if not _retired.is_empty():
		_sweep(S)
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
		if not _usable(w):
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
	var key: String = _jkey(S, float(nx.bearing))
	var job = _jobs.get(key)
	var sl: WorldPlanet.Slice
	if job != null and job.i >= SimConst.NC and not job.slice.pending:   # read whole (a lazy job's `done` is set by its preparation's ticks: a lost preparation finds the slice whole all the same)
		sl = job.slice
	else:
		coldCount += 1   # a ring read on the swap tick: only for a state carried into a process that never warmed it (the same slice, and a hitch). tick() swaps only on a ring the state counts as read, so this stays 0
		sl = WorldPlanet.sliceRing(seed, ring)
	# the preparation the warm ticks made (or, for what is not ready, the same made now)
	var pl: Dictionary = _plan(S)
	var ep = pl.e.get(key)
	if ep == null:
		ep = _entry()
		pl.e[key] = ep
	if not (bool(ep.ready) and int(ep.sh) >= 0 and int(pl.wtN) >= SimConst.NC):
		unprepCount += 1   # a preparation lost (a state carried into another process): made now, on the same tick, with the same functions
		_prepTo(S, E, pl, ep, sl, int(data().prepTicks) - 1, int(data().prepTicks))
	_retire(S)   # kept for KEEP_TICKS, under this world's id (the swap gives the sim a new one below)
	var NC: int = SimConst.NC
	var COL: float = SimConst.COL
	var px: float = float(nx.pc) * COL
	var z: Array = _zone()
	var Z1: float = z[1]
	var wt: PackedFloat32Array = pl.wt
	# --- the ground and its marks (the base ground is the prepared one: it does not change in a fight)
	for i in range(NC):
		var w: float = wt[i]
		S.deform[i] = S.deform[i] * (1.0 - w)
		S.rubble[i] = S.rubble[i] * (1.0 - w)
		S.scorch[i] = S.scorch[i] * (1.0 - w)
		S.crack[i] = S.crack[i] * (1.0 - w)
		if w >= 0.5 and S.aftermath.size() == NC:
			S.aftermath[i] = 0   # a beam's strip in ground the new ring replaces is gone with it; the zone keeps its own (weight under 0.5, as the trees)
			S.aftermathT[i] = 0
	if S.aftermathJobs.size() > 0:   # a timed aftermath job centred in ground the new ring replaces ends with it
		var keepJ: Array = []
		for j in S.aftermathJobs:
			if wt[posmod(int(j[0]), NC)] < 0.5:
				keepJ.append(j)
		S.aftermathJobs = keepJ
	S.base = ep.base
	# --- the buildings: those inside the zone stay (their districts renumbered); the places the new ring holds that were not kept are the prepared fresh ones
	for b in ep.keep:
		b.district = ep.remap[b.district]
	S.buildings = ep.keep + ep.made
	WorldBiomes.planetCols = ep.cols
	S.planetCols = ep.cols
	if ep.has("fcols"):   # gen 2: the fine biomes, and the trees: the old ring's where the ground is kept, the new ring's where it is new (the same weight as the ground's)
		var kept: Array = []
		for t in S.trees:
			if wt[int(floor(SimWrap.wrap(t.x) / COL)) % NC] < 0.5:
				kept.append(t)
		for t in ep.trees:
			if wt[int(floor(SimWrap.wrap(t.x) / COL)) % NC] >= 0.5:
				kept.append(t)
		S.trees = WorldLakes.dryTrees(kept, ep.lakes, NC)
		WorldBiomes.fineCols = ep.fcols
		S.fineCols = ep.fcols
	S.bindStructures(true)   # Simulation (packed structures): new records for the new arrays, so earlier snapshots' and the plan's keep theirs
	# --- the derived and per-building state
	S.lanes = WorldLanes.build(S, ep.dlist)
	WorldStructures.buildIndex(S)
	var lot := PackedFloat32Array()
	lot.resize(S.buildings.size())
	lot.fill(0.0)
	S.world.lotAcc = lot
	S.popHist.fill(0.0)
	for b in S.buildings:
		S.popHist[WorldCollateral.histBucket(b.x)] += b.popAlive
	var oldWater: PackedFloat32Array = S.water.duplicate()
	var oldLakes: Array = S.planetRing.get("lakes", [])
	WorldWater.init(S)
	var lakesNow: Array = []
	if ep.has("lakes"):   # gen 2: the lakes of the kept core stand as they were (their water as the fight left it), the new ring's lakes on the new ground are planted
		for lk in WorldLakes.onlyKept(oldLakes, wt):
			for k in range(int(lk[3])):
				var lc: int = (int(lk[0]) + k) % NC
				S.water[lc] = oldWater[lc]
			lakesNow.append(lk)
		WorldLakes.apply(S, ep.lakes)
		for lk in ep.lakes:
			lakesNow.append(lk)
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
	if not bool(nx.get("camp", false)):
		E.n = int(E.n) + 1   # a campaign turn is not one of the fight's four
	E.lastT = S.T
	E.drift = nx.drift
	E.ring = spec
	S.planetRing = {"seed": seed, "c": spec.c, "t": spec.t, "cols": spec.cols}   # unhashed: the ring now played on
	if ep.has("fcols"):
		S.planetRing["fine"] = ep.fcols
		S.planetRing["lakes"] = lakesNow
	E.sh = int(ep.sh)   # the ring now played on, as the state hash sees it (WorldPlanet.sliceHash, made a few bytes a warm tick)
	E.chords = ep.chordsAll
	E.dlist = ep.dlist
	E.next = null
	E.warm = []
	var ev := SimFx._ev(S, "arena_turn")
	ev.n = int(E.n)
	ev.x = px
	ev.amount = float(nx.bearing)
	ev.k = float(nx.drift)
