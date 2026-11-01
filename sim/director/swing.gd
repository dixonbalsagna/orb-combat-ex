class_name DirSwing
## The choreographer's swing (docs/world/ring-any-angle/encounter.md section 2, game-design.md sections 2, 10, 11, 13). The
## world turns behind the fighters; nothing in the fight changes. One decision, one score, against "stay" at 0: every kind
## of swing is offered at its own moment, and a swing to nothing isn't taken. The director asks and scores; SimSwing runs the
## turn and enforces the rate law. Behind data/director/swing.json enabled (false), and only on a field world (S.frame): off
## either, nothing here runs and no slot is sized.
##  - Two score functions, so the lint can tell them apart (Legal's RL-213, RL-215). _timing: whether and when; it may read
##    the named scalars in TENSION behind tension.enabled, and they move a swing earlier or later and are paid for in
##    recency. _direction: where to; it reads places, standing buildings and terrain, a fighter's care, and the hero's anguish.
##  - The nudge (section 13) is its own class, with its own scorer that reads structures only and is the same for everyone
##    (RL-216).
##  - It never starts from a press, so it can't be a dodge.
##  - The place list stands in for World's (encounter.md section 3): the planet's cities and towns plus terrain read along a
##    few bearings, with a place's standing buildings a number by kind. Wear, streets, faces and homes come with World's.
## Signs are the core's: a turn above 0 takes the heading toward the camera, heading x point.
## State: integers after the plane's on the first fighter's f.act.dirI. A decision and its plan share one call stack, so _plan
## and _was hold nothing across a tick.

const PATH: String = "res://data/director/swing.json"
const TENSION: Array = ["f.anguish", "f.menace", "S.mood.v"]   # the scalars timing may read (RL-215), by name

const W_LAST: int = 0     # the live tick of the last big swing, plus 1
const W_JOLT: int = 1     # ... of the last small one
const W_CAUSE: int = 2    # index in CAUSES, plus 1
const W_SIZE: int = 3     # its size in degrees
const W_SIDE: int = 4     # its sign
const W_PLACE: int = 5    # the place it went to, plus 1
const W_SCORE: int = 6    # its score x 64, what a new ask has to beat
const W_FULL: int = 7     # its size x 4096
const W_PAID: int = 8     # the tension a swing spent, x 1024, paid back in recency
const W_NCAUSE: int = 9   # the cause of what's running: index in CAUSES, plus 1
const N_ON: int = 10      # a nudge: 0 none, else its place plus 1
const N_STICK: int = 11   # the stick he holds: (mx + 128) * 512 + (my + 128) * 2 + dash
const N_SINCE: int = 12   # the live tick he took hold of it, plus 1
const N_SPENT: int = 13   # degrees x 4096 turned for this place
const N_WIN: int = 14     # the live tick the 10 s window began, plus 1
const N_WDEG: int = 15    # degrees x 4096 turned in it
const N_OFF0: int = 16    # places off the list for this flight: ids 0 to 30
const N_OFF1: int = 17    # ... 31 to 61
const N_LEAD: int = 18    # a nudge's lead: live ticks until it starts
const N_DEG: int = 19     # ... and its size x 4096
const W_PDEG: int = 20    # a launch's ask, waiting for its hit-stop to end: its size x 4096, 0 for none
const W_PPV: int = 21     # ... its pivot x 16
const W_PBY: int = 22     # ... its restBy
const W_SENDS: int = 23   # sends into a building in this town (game-design.md section 15)
const W_SENT: int = 24    # the live tick of the last one, plus 1
const W_N: int = 25

const CAUSES: Array = ["launch", "chase", "flee", "form", "brawl", "story", "jolt", "nudge"]

static var _d = null
static var _text: String = ""
static var _force: int = -1    # tools: -1 the data's switch, 0 off, 1 on
static var _plan = null        # the pick between atLaunch and atSend, in one call stack
static var _was = null         # the frame, while a plan reads the line a swing ends on
static var _posed := PackedInt32Array()   # the buildings that plan posed, to put back
static var everyPlace: bool = false       # tools: the planet's places, built or not, to test a turn against any of them
static var _builtKey: String = ""         # _builtPlaces' memo, by the world: a pure read of it, so it holds nothing the state does
static var _builtMemo := PackedByteArray()


static func _ensure() -> void:
	if _d == null:
		_text = FileAccess.get_file_as_string(PATH)
		_d = JSON.parse_string(_text)
		if not (_d is Dictionary):
			_d = {}


static func cfg() -> Dictionary:
	_ensure()
	return _d


static func dataText() -> String:
	_ensure()
	return _text


static func enabled() -> bool:
	_ensure()
	return bool(_d.get("enabled", false)) if _force < 0 else _force == 1


## Tools: force the switch. -1 goes back to the data's.
static func setForce(v: int) -> void:
	_force = v


## A field world, the switch on. Nothing else has a line to turn.
static func on(S: SimState) -> bool:
	return enabled() and S.frame != null and not SimStage.halts(S)


static func _b() -> int:
	return DirPlane._base() + DirPlane.PL_N


static func _g(S: SimState, k: int) -> int:
	var d: PackedInt32Array = S.fighters[0].act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(S: SimState, k: int, v: int) -> void:
	var f = S.fighters[0]
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + W_N:
		f.act.dirI.resize(_b() + W_N)
	f.act.dirI[_b() + k] = v


# ---- rest ------------------------------------------------------------------------------------------------

## Why a swing can't run now ("" when it can): a beam and its tell, a struggle, a finisher, a KO, the intro, a grab's set
## piece, a tower chain (section 2; encounter.md section 2). A hit-stop is no live tick, so nothing runs in one.
static func restRule(S: SimState) -> String:
	if S.game.ko != null:
		return "ko"
	if S.intro.left > 0:
		return "intro"
	if S.game.clash != null:
		return "struggle"
	if DirArc.flying(S):
		return "meteor"
	var ex = S.dirS.ex
	if ex != null:
		if ex.kind == "sig":
			return "beam"
		if ex.tpl == "finisher" or ex.branch == "finisher" or DirExchange.finisherPlanned(ex):
			return "finisher"
		if DirBrawl.isBrawl(ex) and DirBrawl._setPiece(ex):
			return "set piece"
	for f in S.fighters:
		if DirGrapple.holds(f):
			return "grab"
		if f.interior != null:
			return "tower"
	return ""


# ---- the place list (World's, when it lands) ---------------------------------------------------------------

static func _planet(S: SimState):
	return SimField._planet(S.frame.seed, S.frame.gen)


## The line at x: the point M, the way along the line T, and N toward the camera.
static func _frame(S: SimState, x: float) -> Dictionary:
	var fr = S.frame
	var a: float = SimWrap.sdx(fr.x0, x) / SimField.R
	var co: float = SimDetMath.cos(a)
	var si: float = SimDetMath.sin(a)
	var M: Array = [fr.px * co + fr.tx * si, fr.py * co + fr.ty * si, fr.pz * co + fr.tz * si]
	var T: Array = [fr.tx * co - fr.px * si, fr.ty * co - fr.py * si, fr.tz * co - fr.pz * si]
	return {"M": M, "T": T, "N": [T[1] * M[2] - T[2] * M[1], T[2] * M[0] - T[0] * M[2], T[0] * M[1] - T[1] * M[0]]}


## Each place within maxD of the point: its id, kind, distance, bearing from the line's forward way (degrees, (-180, 180]),
## toward the camera positive. There is no people field here, on purpose.
static func places(S: SimState, P, fr: Dictionary, maxD: float) -> Array:
	var out: Array = []
	var M: Array = fr.M
	var T: Array = fr.T
	var N: Array = fr.N
	var built: PackedByteArray = _builtPlaces(S, P)
	for i in range(P.n):
		if built[i] == 0 and not everyPlace:
			continue   # a place the match laid no buildings at is empty ground
		var q0: float = P.px[i]
		var q1: float = P.py[i]
		var q2: float = P.pz[i]
		var cm: float = q0 * M[0] + q1 * M[1] + q2 * M[2]
		var d: float = WorldPlanet.acosf(clampf(cm, -1.0, 1.0)) * SimField.R
		if d > maxD or d < 1.0:
			continue
		var phi: float = WorldPlanet.atan2f(q0 * N[0] + q1 * N[1] + q2 * N[2], q0 * T[0] + q1 * T[1] + q2 * T[2]) * 180.0 / SimMathx.PI
		out.append({"id": i, "kind": "city" if P.kind[i] == WorldPlanet.KIND_CITY else "town", "d": d, "phi": phi})
	return out


## Which places have any building laid near them, once a world: buildings don't move on the planet, so this holds for the match.
static func _builtPlaces(S: SimState, P) -> PackedByteArray:
	var key: String = str(S.frame.seed) + ":" + str(S.bDir.size()) + ":" + (str(S.bDir[0]) if S.bDir.size() > 0 else "")
	if key == _builtKey:
		return _builtMemo
	var out := PackedByteArray()
	out.resize(P.n)
	var least: float = SimDetMath.cos(float(cfg().buildings.placeNear) / SimField.R)
	for i in range(P.n):
		for b in range(S.bDir.size() / 3):
			if P.px[i] * S.bDir[b * 3] + P.py[i] * S.bDir[b * 3 + 1] + P.pz[i] * S.bDir[b * 3 + 2] >= least:
				out[i] = 1
				break
	_builtKey = key
	_builtMemo = out
	return out


## Each standing building within maxD of the point that may be aimed at: its distance, its bearing as places reads one, its
## index. Standing is all it reads (RL-213).
static func _standing(S: SimState, fr: Dictionary, maxD: float) -> Array:
	var out: Array = []
	if S.bDir.size() != S.buildings.size() * 3:
		return out
	var M: Array = fr.M
	var T: Array = fr.T
	var N: Array = fr.N
	var least: float = SimDetMath.cos(minf(maxD / SimField.R, SimMathx.PI))
	for i in range(S.buildings.size()):
		var b = S.buildings[i]
		if not b.alive or WorldSettle.noTarget(b.landmark):
			continue
		var q0: float = S.bDir[i * 3]
		var q1: float = S.bDir[i * 3 + 1]
		var q2: float = S.bDir[i * 3 + 2]
		var cm: float = q0 * M[0] + q1 * M[1] + q2 * M[2]
		if cm < least:
			continue
		var d: float = WorldPlanet.acosf(clampf(cm, -1.0, 1.0)) * SimField.R
		if d < WorldBrunt.BR_MIN:
			continue
		out.append([d, WorldPlanet.atan2f(q0 * N[0] + q1 * N[1] + q2 * N[2], q0 * T[0] + q1 * T[1] + q2 * T[2]) * 180.0 / SimMathx.PI, i])
	return out


## How many of the buildings stand within band of a line turned by turn, either way along it.
static func _onLine(near: Array, turn: float, band: float) -> int:
	var n: int = 0
	for e in near:
		if float(e[0]) * absf(SimDetMath.sin((float(e[1]) - turn) * SimMathx.PI / 180.0)) <= band:
			n += 1
	return n


## A point d units along the bearing phi from the frame's point.
static func _along(fr: Dictionary, phi: float, d: float) -> Array:
	var a: float = d / SimField.R
	var ca: float = SimDetMath.cos(a)
	var sa: float = SimDetMath.sin(a)
	var r: float = phi * SimMathx.PI / 180.0
	var cp: float = SimDetMath.cos(r)
	var sp: float = SimDetMath.sin(r)
	var M: Array = fr.M
	var T: Array = fr.T
	var N: Array = fr.N
	return [M[0] * ca + (T[0] * cp + N[0] * sp) * sa, M[1] * ca + (T[1] * cp + N[1] * sp) * sa, M[2] * ca + (T[2] * cp + N[2] * sp) * sa]


## The class of terrain at a point, by height only.
static func _terrain(P, q: Array, c: Dictionary) -> String:
	var h: float = WorldField.heightBake(P, q[0], q[1], q[2])
	if h >= float(c.highAt):
		return "high"
	if h >= float(c.ridgeAt):
		return "ridge"
	return "open" if h > 0.0 else "water"


## The bearing's turn for a line whose way `side` should meet phi: on the far side of the pivot it's the reverse way.
static func _turnFor(phi: float, side: int) -> float:
	var t: float = phi if side > 0 else phi - 180.0
	while t > 180.0:
		t -= 360.0
	while t <= -180.0:
		t += 360.0
	return t


## Who an ask's candidates are: places and terrain the line can be turned onto within cap degrees, side: the way he'll fly.
static func candidates(S: SimState, pv: float, side: int, cap: float, reach: float) -> Array:
	var c: Dictionary = cfg()
	var P = _planet(S)
	var fr: Dictionary = _frame(S, pv)
	var out: Array = []
	var minDeg: float = float(c.minDeg)
	var kinds: Dictionary = c.get("kindScore", {})
	for pl in places(S, P, fr, reach * float(c.fit.window)):
		var t: float = _turnFor(float(pl.phi), side)
		if absf(t) > cap or absf(t) < minDeg:
			continue
		out.append({"turn": t, "id": int(pl.id), "kind": String(pl.kind), "d": float(pl.d), "far": float(pl.phi) < 0.0, "b": float(c.placeBuildings.get(pl.kind, 0.0)), "k": float(kinds.get(pl.kind, 0.0))})
	var cl: Dictionary = c.get("terrain", {})
	for b in cl.get("bearings", []):
		var t: float = float(b)
		if absf(t) > cap:
			continue
		var q: Array = _along(fr, t if side > 0 else t - 180.0, reach)
		var cls: String = _terrain(P, q, cl)
		var k: float = float(kinds.get(cls, 0.0))
		if k > 0.0:
			out.append({"turn": t, "id": -1, "kind": cls, "d": reach, "far": (t < 0.0) == (side > 0), "b": 0.0, "k": k})
	# The standing buildings (section 15): the nearest of a bearing's bucket is a place to bring onto the line, and a line that
	# keeps none leaves a town the fight is in.
	var bc: Dictionary = c.buildings
	var st: Array = _standing(S, fr, reach * float(c.fit.window))
	var nearBy: int = 0
	var keep: Array = []
	var buckets: Dictionary = {}
	for e in st:
		if float(e[0]) <= float(bc.townNear):
			nearBy += 1
		if float(e[0]) <= float(bc.keepNear):
			keep.append(e)
		var t: float = _turnFor(float(e[1]), side)
		if absf(t) > cap or absf(t) < minDeg:
			continue
		var k: int = int(floor((t + 180.0) / float(bc.bucketDeg)))
		if not buckets.has(k) or float(e[0]) < float(buckets[k][0]):
			buckets[k] = [e[0], t, e[1]]
	var keys: Array = buckets.keys()
	keys.sort()
	for k in keys:
		var e: Array = buckets[k]
		out.append({"turn": float(e[1]), "id": -1, "kind": "building", "d": float(e[0]), "far": float(e[2]) < 0.0, "b": float(c.placeBuildings.get("town", 0.0)), "k": float(kinds.get("building", 0.0)), "bld": true})
	# A town is laid along the line it was met on, so a turn in it loses what no longer stands near the line (section 15).
	var base: int = _onLine(keep, 0.0, float(bc.band)) if nearBy >= int(bc.townCount) else 0
	if base > 0 and _g(S, W_SENDS) < int(bc.sends):
		for cn in out:
			cn["lost"] = 1.0 - minf(1.0, float(_onLine(keep, float(cn.turn), float(bc.band))) / float(base))
	return out


# ---- the two scores -------------------------------------------------------------------------------------

## Whether and when (RL-215's first column). A beat's weight, the fight's state, and recency.
static func _timing(S: SimState, cause: String, A, D) -> Dictionary:
	var c: Dictionary = cfg().get("timing", {})
	var s: float = float(c.get("moment", {}).get(cause, 0.0))
	var parts: Array = [["moment", s]]
	var now: int = DirBrawl._now(S)
	var last: int = _g(S, W_LAST)
	var tn: float = _tension(S, A, D)
	if last > 0:
		var tau: float = float(c.recencySec) * (1.0 + float(_g(S, W_PAID)) / 1024.0)
		var since: float = float(now - (last - 1)) / DirData.TICKS_PER_SEC
		var rec: float = -float(c.recency) * SimDetMath.exp(-since / tau)
		s += rec
		parts.append(["recent", rec])
	if A != null and D != null:
		var low: float = minf(float(A.tier), float(D.tier))
		var tv: float = float(c.tierW) * (low - 1.0)
		var behind: float = SimWounds.vitality(D) - SimWounds.vitality(A)
		var cb: float = float(c.comebackW) * maxf(0.0, behind)
		if tv != 0.0:
			s += tv
			parts.append(["tier", tv])
		if cb != 0.0:
			s += cb
			parts.append(["comeback", cb])
	if tn != 0.0:
		var tt: float = float(c.tensionW) * tn
		s += tt
		parts.append(["tension", tt])
	return {"s": s, "parts": parts, "tn": tn}


## The named scalars, behind their own switch (RL-215 is open until QA's batch passes). 0 with it off.
static func _tension(S: SimState, A, D) -> float:
	if not bool(cfg().get("tension", {}).get("enabled", false)) or A == null or D == null:
		return 0.0
	return clampf((maxf(float(A.anguish), float(D.anguish)) + maxf(float(A.menace), float(D.menace))) / 200.0 + float(S.mood.v) / 3600.0, 0.0, 1.0)


## Where to (RL-215's second column). Fit, the place, personality in standing buildings, the hero's anguish, variety, lean,
## the far side of the plane, tall land coming round in front. Nothing here reads the moment's tension.
static func _direction(S: SimState, cand: Dictionary, A, side: int, reach: float, fitDeg: float, P, fr: Dictionary) -> Dictionary:
	var c: Dictionary = cfg()
	var sc: Dictionary = c.get("direction", {})
	var parts: Array = []
	var bld: bool = cand.has("bld")
	var fitD: float = 1.0 if bld else clampf(1.0 - absf(float(cand.d) - reach) / maxf(1.0, reach * float(c.fit.window)), 0.0, 1.0)   # a flight stops at the building it meets
	var fitA: float = clampf(fitDeg / maxf(1.0, absf(float(cand.turn))), 0.0, 1.0)
	var arrive: float = (float(sc.arriveBuilding) if bld else (float(sc.arrive) if int(cand.id) >= 0 else float(sc.arriveTerrain))) * fitD * fitA + float(cand.k)
	parts.append(["arrive", arrive])
	var s: float = arrive
	var bc: Dictionary = c.buildings
	var lost: float = float(cand.get("lost", 0.0))
	if lost > 0.0:
		var lv: float = float(cand.get("leaveW", bc.leave)) * lost
		s -= lv
		parts.append(["leaves", -lv])
	if not bld and int(cand.id) < 0:
		# Long with no send, standing buildings and places count for more against open ground. It comes off the ground's, not onto
		# theirs, so nothing new clears stay's 0 and no swing is added (section 15).
		var sent: int = _g(S, W_SENT)
		var dry: float = float(DirBrawl._now(S) - maxi(0, sent - 1)) / DirData.TICKS_PER_SEC - float(bc.drySec)
		if dry > 0.0:
			var dt: float = -float(bc.dry) * minf(1.0, dry / float(bc.dryRampSec))
			s += dt
			parts.append(["dry", dt])
	if A != null:
		var b: float = float(cand.b) / float(sc.buildingRef)
		var pers: float = -float(A.care) * float(sc.care) * b
		if float(A.care) > 0.0:
			pers -= float(sc.anguish) * clampf(float(A.anguish) / 100.0, 0.0, 1.0) * b
		if pers != 0.0:
			s += pers
			parts.append(["personality", pers])
	var v: float = 0.0
	var turn: float = absf(float(cand.turn))
	if _g(S, W_LAST) > 0:
		if absf(turn - float(_g(S, W_SIZE))) <= 15.0:
			v -= float(sc.sameSize)
		if signf(float(cand.turn)) == float(_g(S, W_SIDE)):
			v -= float(sc.sameSide)
		if int(cand.id) >= 0 and _g(S, W_PLACE) == int(cand.id) + 1:
			v -= float(sc.samePlace)
	v += float(sc.biome) * _biomeRoom(S, String(cand.kind))
	if v != 0.0:
		s += v
		parts.append(["variety", v])
	if A != null and float(cand.turn) * float(A.face) > 0.0:
		var ln: float = float(sc.lean)
		s += ln
		parts.append(["lean", ln])
	if bool(cand.far):
		var bh: float = float(sc.behind)
		s += bh
		parts.append(["behind", bh])
	if P != null:
		var tall: float = _tallAhead(S, P, fr, float(cand.turn))
		if tall > 0.0:
			var tl: float = -float(sc.tall) * tall
			s += tl
			parts.append(["tall", tl])
	return {"s": s, "parts": parts}


## That biome's room: its planet share against its time share of this fight, -1 to 1. A place's kind stands for its biome.
static func _biomeRoom(S: SimState, kind: String) -> float:
	var m: Dictionary = cfg().get("kindBiome", {})
	var b: String = String(m.get(kind, ""))
	var i: int = DirLocation.BIOMES.find(b)
	var t = S.dirS.biomeT
	if i < 0 or t == null or i >= t.size():
		return 0.0
	var total: float = 0.0
	for v in t:
		total += float(v)
	if total <= 0.0:
		return 0.0
	return clampf(1.0 / float(DirLocation.BIOMES.size()) - float(t[i]) / total, -1.0, 1.0)


## How much a turn would bring tall land round in front of the plane: land over the line within the bound, on the near
## side once turned (Camera, camera.md section 5). 0 to 1, height only.
static func _tallAhead(_S: SimState, P, fr: Dictionary, turn: float) -> float:
	var c: Dictionary = cfg().get("tall", {})
	var over: int = 0
	var ds: Array = c.get("samples", [])
	for d in ds:
		var q: Array = _along(fr, turn + 90.0, float(d))
		if WorldField.heightBake(P, q[0], q[1], q[2]) >= float(c.height):
			over += 1
	return float(over) / float(maxi(1, ds.size()))


# ---- deciding -----------------------------------------------------------------------------------------

static func _n(v: float) -> String:
	return "%.1f" % v


static func _sign(v: float) -> String:
	return "+" if v >= 0.0 else ""


static func _line(c: Dictionary) -> String:
	var bits: PackedStringArray = []
	for p in c.parts:
		bits.append(String(p[0]) + " " + _n(float(p[1])))
	return " + ".join(bits)


## One ask's scored candidates, best first. The score's whole: timing plus direction. Pure, for the check.
static func scored(S: SimState, cause: String, A, D, pv: float, side: int, cap: float, reach: float, fitDeg: float) -> Array:
	var tm: Dictionary = _timing(S, cause, A, D)
	var P = _planet(S)
	var fr: Dictionary = _frame(S, pv)
	var out: Array = []
	for cn in candidates(S, pv, side, cap, reach):
		if cause == "launch":
			cn["leaveW"] = float(cfg().buildings.leaveLaunch)   # section 15: landing impacts are what swings lose, so that launch lands in town
		var dr: Dictionary = _direction(S, cn, A, side, reach, fitDeg, P, fr)
		var e: Dictionary = cn.duplicate()
		e["s"] = float(tm.s) + float(dr.s)
		e["dir"] = float(dr.s)
		e["parts"] = (dr.parts as Array) + (tm.parts as Array)
		e["tn"] = tm.tn
		out.append(e)
	out.sort_custom(func(a, b): return float(a.s) > float(b.s) or (float(a.s) == float(b.s) and absf(float(a.turn)) < absf(float(b.turn))))
	return out


## The ask's feed line, taken or not, in the launch planner's format, top three including stay.
static func _explain(S: SimState, cause: String, list: Array, took: bool, pivotName: String, restsBy: int) -> void:
	var txt: String = ""
	if list.is_empty():
		txt = "nothing in reach; stay 0"
	else:
		var top: Dictionary = list[0]
		txt = _sign(float(top.turn)) + str(int(round(float(top.turn)))) + " deg to " + String(top.kind) + " " + _n(float(top.s)) + " = " + _line(top)
		if list.size() > 1:
			txt += "; next " + _sign(float(list[1].turn)) + str(int(round(float(list[1].turn)))) + " " + String(list[1].kind) + " " + _n(float(list[1].s))
		txt += "; stay 0"
		if took:
			txt += "; pivot " + pivotName + ("; rests by " + str(restsBy) if restsBy > 0 else "")
		else:
			txt += "; not taken"
	SimEvents.feed(S, "SWING " + cause, txt)


## Whether a new ask with this score may replace what's running: above what's left of its score, less a reversal term that
## grows with how far it would turn back.
static func _beats(S: SimState, score: float, turn: float) -> bool:
	var sw = S.swing
	if not sw.active:
		return true
	var full: float = absf(float(_g(S, W_FULL)) / 4096.0)
	var was: float = float(_g(S, W_SCORE)) / 64.0
	var rev: float = float(cfg().get("direction", {}).get("reversal", 0.0)) * (1.0 if signf(turn) != signf(float(sw.left)) else 0.0)
	return score > was * (absf(float(sw.left)) / maxf(1.0, full)) + rev


## Commit a pick. False if the core won't run one now (a beam in the air). With "later", the ask waits for the live tick: restBy
## counts the sim's ticks and the swing's clock only the live ones, so an ask with a hit-stop ahead of it would be out of time.
static func _take(S: SimState, cause: String, A, top: Dictionary, spec: Dictionary, pivotName: String) -> bool:
	if spec.has("later"):
		_s(S, W_PDEG, int(round(float(spec.deg) * 4096.0)))
		_s(S, W_PPV, int(round(float(spec.pivotX) * 16.0)))
		_s(S, W_PBY, int(spec.restBy))
	elif not SimSwing.ask(S, spec):
		return false
	var now: int = DirBrawl._now(S)
	_s(S, W_LAST, now + 1)
	_s(S, W_CAUSE, CAUSES.find(cause) + 1)
	_s(S, W_NCAUSE, CAUSES.find(cause) + 1)
	_s(S, W_SIZE, int(round(absf(float(spec.deg)))))
	_s(S, W_SIDE, int(signf(float(spec.deg))))
	_s(S, W_PLACE, int(top.get("id", -1)) + 1)
	_s(S, W_SCORE, int(round(float(top.s) * 64.0)))
	_s(S, W_FULL, int(round(float(spec.deg) * 4096.0)))
	_s(S, W_PAID, int(round(float(top.get("tn", 0.0)) * 1024.0)))
	if float(top.get("lost", 0.0)) >= 0.5:
		_s(S, W_SENDS, 0)   # a new town, when it finds one, starts its count again
	_cue(S, A, cause, String(top.get("kind", "")) + ("#" + str(int(top.id)) if int(top.get("id", -1)) >= 0 else ""), float(spec.deg), int(spec.get("restBy", 0)), float(spec.get("pivotX", SimSwing._pivot(S))), pivotName)
	return true


## The director's half of the core's swing_start: where it's going, and why, for the feed and the camera's intent.
static func _cue(S: SimState, A, cause: String, text: String, deg: float, rest: int, pv: float, _pivotName: String) -> void:
	SimFx.cue(S, A, "swing_place", text, cause)
	var e = S.out.fx[S.out.fx.size() - 1]
	e.amount = deg
	e.n = S.tick + int(round(float(SimClock.left(S)) * DirData.TICKS_PER_SEC)) + rest if rest > 0 else 0
	e.x = pv


## A rest already running: it has no ramp in, and asking again would only move its clock.
static func _resting(sw) -> bool:
	return sw.kind == SimSwing.RAMPED and sw.rampIn == 0.0


## The plan reads the line a swing ends on, and every building where that line puts it, with the bake (the reader's rule).
## planOff puts it all back: nothing the state keeps changes between the two, and they share one call stack.
static func _planOn(S: SimState, fr, x: float) -> void:
	_was = S.frame
	S.frame = fr
	SimField.far()
	_posed = SimSwing.posesNear(S, x)


static func _planOff(S: SimState) -> void:
	if _was == null:
		return
	S.frame = _was
	_was = null
	SimField.near()
	SimSwing.posesOf(S, _posed)


# ---- the moments that offer a candidate ---------------------------------------------------------------------

## The ticks a landing's rest comes before contact (game-design.md section 9), in seconds.
static func _restSec() -> float:
	return float(cfg().restTicks) / DirData.TICKS_PER_SEC


## A launch's pick, or null, with its feed line.
static func _launchPick(S: SimState, A, D, force: float):
	var c: Dictionary = cfg()
	var t: float = force * float(c.fit.secPerForce)
	var reach: float = force * float(c.fit.reachPerForce)
	var cap: float = minf(float(c.maxDeg), SimSwing.mostFor(t - _restSec(), "launch"))
	if cap < float(c.bigMin):
		_explain(S, "launch", [], false, "", 0)
		return null
	var side: int = 1 if float(A.face) >= 0.0 else -1
	for e in _standing(S, _frame(S, float(A.x)), reach):
		if absf(_turnFor(float(e[1]), side)) < float(c.minDeg):
			SimEvents.feed(S, "SWING launch", "a building on the line; stay 0")
			return null
	var list: Array = scored(S, "launch", A, D, float(A.x), side, cap, reach, cap)
	var took: bool = not list.is_empty() and float(list[0].s) > 0.0 and _beats(S, float(list[0].s), float(list[0].turn))
	_explain(S, "launch", list, took, "launcher", 0)
	return {"top": list[0], "t": t, "pv": float(A.x)} if took else null


## A launch, before chooseLaunch (DirMelee.launchBeat, chase's catch): pick the line; the plan runs on it. With no pick and a
## swing running, the plan runs on the line that one ends on.
static func atLaunch(S: SimState, A, D, force: float) -> void:
	_plan = null
	if not on(S):
		return
	if restRule(S) == "" and _flyingByChoice(S) == null and force >= float(cfg().fit.minForce):
		_plan = _launchPick(S, A, D, force)
	if _plan != null:
		var fr = S.frame.copy()
		SimSwing._applyTurn(fr, float(_plan.pv), float(_plan.top.turn))
		_planOn(S, fr, float(D.x))
	elif S.swing.active:
		_planOn(S, SimSwing.frameAt(S, int(ceil(float(S.swing.ticks) - float(S.swing.tau)))), float(D.x))


## The plan is made. A knock-back or no flight sends him nowhere: the pick is dropped.
static func atPlanned(S: SimState, best: Dictionary) -> void:
	_planOff(S)
	if _plan == null:
		return
	if String(best.get("name", "")) == "KNOCK BACK" or not (best.get("p") is Dictionary):
		_plan = null


## The send: the core starts it as the hit-stop ends, and it's at rest before contact, by the plan's own time.
static func atSend(S: SimState, A, D, best: Dictionary) -> void:
	if on(S) and String(best.get("name", "")) == "BUILDING SMASH":
		_s(S, W_SENDS, _g(S, W_SENDS) + 1)
		_s(S, W_SENT, DirBrawl._now(S) + 1)
	if _plan == null:
		if on(S) and String(best.get("name", "")) != "KNOCK BACK":
			atBlow(S, A, D, 1.0)   # no big swing here: the world jolts round the launcher
		return
	var pl: Dictionary = _plan
	_plan = null
	var c: Dictionary = cfg()
	var p = best.get("p")
	var t: float = float(p.get("t", pl.t)) if p is Dictionary else float(pl.t)
	var top: Dictionary = pl.top
	var deg: float = float(top.turn)
	var fit: float = SimSwing.mostFor(t - _restSec(), "launch")
	if absf(deg) > fit:
		deg = signf(deg) * fit   # what fits: the part that doesn't is lateral miss at the place
	if absf(deg) < float(c.minDeg):
		atBlow(S, A, D, 1.0)
		return
	var restBy: int = int(round(t * DirData.TICKS_PER_SEC)) - int(c.restTicks)
	_take(S, "launch", A, top, {"deg": deg, "cause": "launch", "pivotX": float(pl.pv), "restBy": maxi(1, restBy), "later": true}, "launcher")


## A chase (DirChase._begin): the hero leads to empty ground, the villain hunts toward buildings. In the air both, so small
## later corrections are fine; the rate law slows it for anyone standing.
static func atChase(S: SimState, A, D) -> void:
	_offer(S, "chase", A, D, float(cfg().chase.sec), float(cfg().chase.reach), false)


## A form's pause (DirExchange._transforms): nothing moves, so it's the easiest place.
static func atPause(S: SimState, A) -> void:
	var c: Dictionary = cfg()
	if not on(S):
		return
	_offer(S, "form", A, SimRoster.opp(S, A), float(c.form.sec), float(c.form.reach), false)


## The core's cause and its rate for one of ours: a flight an AI chose runs as a chase.
static func _coreCause(cause: String) -> String:
	return "chase" if cause == "flee" else cause


static func _offer(S: SimState, cause: String, A, D, t: float, reach: float, fixed: bool) -> bool:
	if not on(S) or restRule(S) != "" or _flyingByChoice(S) != null:
		return false
	var c: Dictionary = cfg()
	var core: String = _coreCause(cause)
	var cap: float = minf(float(c.causeMax.get(cause, c.maxDeg)), SimSwing.mostFor(t, core))
	var pv: float = SimSwing._pivot(S)
	var side: int = 1 if float(A.face) >= 0.0 else -1
	var list: Array = scored(S, cause, A, D, pv, side, cap, reach, cap)
	var took: bool = not list.is_empty() and float(list[0].s) > 0.0 and _beats(S, float(list[0].s), float(list[0].turn))
	_explain(S, cause, list, took, "fighter" if fixed else "pair", 0)
	if not took:
		return false
	var spec: Dictionary = {"deg": float(list[0].turn), "cause": core}
	if fixed:
		spec["pivotX"] = pv
	return _take(S, cause, A, list[0], spec, "pair")


## A heavy landing (a charged blow, a launcher, a knock-back; never a light or a medium): the small class (section 10). Its
## sign is the score's, its size the blow's weight, 0 to 1. It starts on the hit-stop's release.
static func atBlow(S: SimState, A, D, weight: float) -> void:
	if not on(S) or restRule(S) != "" or _flyingByChoice(S) != null or S.swing.active:
		return
	var c: Dictionary = cfg()
	var j: Dictionary = c.jolt
	var now: int = DirBrawl._now(S)
	var last: int = _g(S, W_JOLT)
	var since: float = float(now - (last - 1)) / DirData.TICKS_PER_SEC if last > 0 else 1.0e9
	if since < float(j.minSec):
		return   # a rule, not a score: it protects the flash limit
	var w: float = clampf(weight, 0.0, 1.0)
	var size: float = float(j.minDeg) + (float(j.maxDeg) - float(j.minDeg)) * w
	var score: float = float(j.base) + float(j.weightW) * w - (float(j.recency) * SimDetMath.exp(-since / float(j.recencySec)) if last > 0 else 0.0)
	var pv: float = float(A.x)
	var d: float = absf(SimWrap.sdx(A.x, D.x))
	var allow: float = float(c.sweep.smallStanding) if SimSwing._standing(S, D) else float(c.sweep.smallAirborne)
	if d > 1.0:
		size = minf(size, allow / d * 180.0 / SimMathx.PI)
	if size < float(j.leastDeg) or score <= 0.0:
		SimEvents.feed(S, "SWING jolt", "score " + _n(score) + ", " + _n(size) + " deg; stay 0; not taken")
		return
	var sgn: float = _joltSign(S, A, D, pv)
	var deg: float = sgn * size
	if not SimSwing.ask(S, {"deg": deg, "cause": "small", "blow": true, "pivotX": pv}):
		return
	_s(S, W_JOLT, now + 1)
	_s(S, W_NCAUSE, CAUSES.find("jolt") + 1)
	_s(S, W_FULL, int(round(deg * 4096.0)))
	_s(S, W_SCORE, int(round(score * 64.0)))
	SimEvents.feed(S, "SWING jolt", _sign(deg) + _n(deg) + " deg " + _n(score) + "; stay 0; pivot launcher")
	_cue(S, A, "jolt", "", deg, 0, pv, "launcher")


## Which way a jolt leans: toward what the swing's direction score likes best in its window, else the way he was pushing.
static func _joltSign(S: SimState, A, _D, pv: float) -> float:
	var c: Dictionary = cfg()
	var side: int = 1 if float(A.face) >= 0.0 else -1
	var fr: Dictionary = _frame(S, pv)
	var best: float = -INF
	var sg: float = float(side)
	for cn in candidates(S, pv, side, float(c.jolt.leanDeg), float(c.jolt.leanReach)):
		var s: float = float(_direction(S, cn, A, side, float(c.jolt.leanReach), absf(float(cn.turn)), null, fr).s)
		if s > best:
			best = s
			sg = signf(float(cn.turn))
	return sg


# ---- the slow brawl swing, and an AI's flight ---------------------------------------------------------------

## A brawl: about once a second. Jolts come first (section 10); it's behind its own switch.
static func _brawlTick(S: SimState) -> void:
	var c: Dictionary = cfg().get("brawl", {})
	if not bool(c.get("enabled", false)):
		return
	var ex = S.dirS.ex
	var now: int = DirBrawl._now(S)
	if ex == null or not DirBrawl.isBrawl(ex):
		return
	if S.swing.active:
		if now % int(c.tallEvery) == 0 and CAUSES[maxi(0, _g(S, W_NCAUSE) - 1)] == "brawl" and not _resting(S.swing):
			if _tallAhead(S, _planet(S), _frame(S, SimSwing._pivot(S)), 0.0) > 0.0:
				SimSwing.rest(S, int(cfg().restOut))   # a state rule: it rests rather than bring tall land round in front (section 9)
		return
	if now % int(c.every) != 0:
		return
	_offer(S, "brawl", ex.A, ex.D, float(c.sec), float(c.reach), false)


## An AI flying flat out with no human holding a direction: its flight may swing at a chase's rate (section 13's last row).
static func _fleeTick(S: SimState) -> void:
	var c: Dictionary = cfg().get("flee", {})
	if not bool(c.get("enabled", false)) or S.swing.active or DirBrawl._now(S) % int(c.every) != 0:
		return
	for f in S.fighters:
		if f.ai != null and _flat(S, f) and absf(SimWrap.sdx(f.x, SimRoster.opp(S, f).x)) > float(c.minGap):
			_offer(S, "flee", f, SimRoster.opp(S, f), float(c.sec), float(c.reach), false)
			return


# ---- the nudge (section 13) ------------------------------------------------------------------------------

## He's flat out, by choice, and his rival out of reach.
static func _flat(S: SimState, f) -> bool:
	if f.state != "free" or not f.input.dash or absf(float(f.input.mx)) < 0.5:
		return false
	return absf(float(f.vx)) >= float(cfg().nudge.flatShare) * SimFighter.flightSpeed(S, f, true)


static func _stickWord(f) -> int:
	return (int(round(float(f.input.mx) * 127.0)) + 128) * 512 + (int(round(float(f.input.my) * 127.0)) + 128) * 2 + (1 if f.input.dash else 0)


static func _stickMoved(f, was: int) -> bool:
	var dz: float = float(cfg().nudge.deadZone) * 127.0
	var mx: int = was / 512 - 128
	var my: int = ((was % 512) >> 1) - 128
	return absf(float(f.input.mx) * 127.0 - float(mx)) > dz or absf(float(f.input.my) * 127.0 - float(my)) > dz or (was & 1 == 1) != f.input.dash


## The human holding a flat-out flight, for a whole steadySec: while one is, the only swing allowed is the nudge.
static func _flyingByChoice(S: SimState):
	if not bool(cfg().get("nudge", {}).get("enabled", false)):
		return null
	var ni: int = _g(S, N_SINCE)
	if ni <= 0:
		return null
	if DirBrawl._now(S) - (ni - 1) < int(float(cfg().nudge.steadySec) * DirData.TICKS_PER_SEC):
		return null
	for f in S.fighters:
		if f.ai == null and _flat(S, f):
			return f
	return null


## Which fighter the nudge reads: a human flying flat out, or an AI if no human is.
static func _flyer(S: SimState):
	var who = null
	for f in S.fighters:
		if _flat(S, f) and absf(SimWrap.sdx(f.x, SimRoster.opp(S, f).x)) > float(cfg().nudge.rivalBeyond):
			if f.ai == null:
				return f
			who = f
	return who


## The nudge's own score: structures and terrain only, the same pull for every fighter and mode (RL-216). Best first. Each
## within limitDeg of his heading, between nearD and farD ahead. Pure, for the check.
static func nudgeList(S: SimState, x: float, heading: int) -> Array:
	var c: Dictionary = cfg().nudge
	var P = _planet(S)
	var fr: Dictionary = _frame(S, x)
	var out: Array = []
	for pl in places(S, P, fr, float(c.farD)):
		if float(pl.d) < float(c.nearD):
			continue
		var t: float = _turnFor(float(pl.phi), heading)
		if absf(t) > float(c.limitDeg) or _isOff(S, int(pl.id)):
			continue
		var s: float = float(cfg().placeBuildings.get(pl.kind, 0.0)) / float(cfg().direction.buildingRef) - absf(t) * float(c.deg)
		out.append({"id": int(pl.id), "kind": String(pl.kind), "turn": t, "d": float(pl.d), "s": s})
	out.sort_custom(func(a, b): return float(a.s) > float(b.s) or (float(a.s) == float(b.s) and int(a.id) < int(b.id)))
	return out


static func _isOff(S: SimState, id: int) -> bool:
	var k: int = N_OFF0 + id / 31
	return k <= N_OFF1 and (_g(S, k) >> (id % 31)) & 1 == 1


static func _setOff(S: SimState, id: int) -> void:
	var k: int = N_OFF0 + id / 31
	if k <= N_OFF1:
		_s(S, k, _g(S, k) | (1 << (id % 31)))


static func _nudgeEnd(S: SimState, offList: bool) -> void:
	var on_: int = _g(S, N_ON)
	if on_ > 0:
		if offList:
			_setOff(S, on_ - 1)
		_s(S, N_ON, 0)
		_s(S, N_SPENT, 0)
		_s(S, N_LEAD, 0)


## Once a live tick.
static func _nudgeTick(S: SimState) -> void:
	var c: Dictionary = cfg().get("nudge", {})
	if not bool(c.get("enabled", false)):
		return
	var now: int = DirBrawl._now(S)
	var f = _flyer(S)
	if f == null:
		if _g(S, N_SINCE) != 0:
			_s(S, N_SINCE, 0)
			_s(S, N_OFF0, 0)   # the flight is over: the list starts again
			_s(S, N_OFF1, 0)
		if _g(S, N_ON) > 0:
			SimSwing.rest(S, 1)   # at 3 degrees a second the stop can't be seen
			_nudgeEnd(S, false)
		return
	var word: int = _g(S, N_STICK)
	if _g(S, N_SINCE) == 0 or _stickMoved(f, word):
		_s(S, N_STICK, _stickWord(f))
		_s(S, N_SINCE, now + 1)
		if _g(S, N_ON) > 0:
			SimSwing.rest(S, 1)   # any change to what he's holding ends it on this tick, and that place is off the list
			_nudgeEnd(S, true)
		return
	if now - (_g(S, N_SINCE) - 1) < int(float(c.steadySec) * DirData.TICKS_PER_SEC):
		return
	if _g(S, N_WIN) == 0 or now - (_g(S, N_WIN) - 1) >= int(float(c.windowSec) * DirData.TICKS_PER_SEC):
		_s(S, N_WIN, now + 1)
		_s(S, N_WDEG, 0)
	var heading: int = 1 if float(f.vx) >= 0.0 else -1
	var lead: int = _g(S, N_LEAD)
	if lead > 0:
		_s(S, N_LEAD, lead - 1)
		if lead == 1 and not SimSwing.ask(S, {"deg": float(_g(S, N_DEG)) / 4096.0, "rate": float(c.rate), "cause": "small"}):
			_nudgeEnd(S, false)
		return
	if _g(S, N_ON) > 0:
		var rd: int = int(round(float(S.swing.rate) * SimConst.DT * 4096.0))
		_s(S, N_SPENT, _g(S, N_SPENT) + rd)
		_s(S, N_WDEG, _g(S, N_WDEG) + rd)
		if not S.swing.active:
			_nudgeEnd(S, true)
		elif now % int(c.every) == 0:
			var still: bool = false
			for e in nudgeList(S, float(f.x), heading):
				if int(e.id) == _g(S, N_ON) - 1:
					still = absf(float(e.turn)) <= float(c.giveUpDeg) and float(e.d) >= float(c.closeD)
					break
			if not still or float(_g(S, N_WDEG)) / 4096.0 >= float(c.windowDeg):
				SimSwing.rest(S, int(cfg().restOut))
				_nudgeEnd(S, true)
		return
	if S.swing.active:
		if _flyingByChoice(S) != null and not _resting(S.swing):
			SimSwing.rest(S, int(cfg().restOut))   # a swing running when he takes control eases out
		return
	if now % int(c.every) != 0 or restRule(S) != "":
		return
	var list: Array = nudgeList(S, float(f.x), heading)
	if list.is_empty():
		return
	var top: Dictionary = list[0]
	var room: float = float(c.windowDeg) - float(_g(S, N_WDEG)) / 4096.0
	var deg: float = signf(float(top.turn)) * minf(minf(absf(float(top.turn)), float(c.placeDeg)), room)
	if absf(deg) < float(c.leastDeg):
		return
	_s(S, N_ON, int(top.id) + 1)
	_s(S, N_SPENT, 0)
	_s(S, W_NCAUSE, CAUSES.find("nudge") + 1)
	_s(S, W_FULL, int(round(deg * 4096.0)))
	_s(S, W_SCORE, 0)
	var o = SimRoster.opp(S, f)
	var pv: float = float(o.x) if SimSwing._standing(S, o) else SimWrap.wrap(f.x + 0.5 * SimWrap.sdx(f.x, o.x))
	_s(S, N_DEG, int(round(deg * 4096.0)))
	_s(S, N_LEAD, maxi(1, int(c.leadTicks)))
	SimEvents.feed(S, "SWING nudge", _sign(deg) + _n(deg) + " deg to " + String(top.kind) + "; " + ("silent" if absf(deg) < float(c.lineFrom) else "a line may play"))
	SimFx.cue(S, f, "swing_nudge", String(top.kind), "silent" if absf(deg) < float(c.lineFrom) else "line")
	var e2 = S.out.fx[S.out.fx.size() - 1]
	e2.amount = deg
	e2.x = pv


# ---- the tick -------------------------------------------------------------------------------------------

## Once a live tick, last in the director's update.
static func tick(S: SimState, dt: float) -> void:
	if dt <= 0.0 or not on(S):
		return
	var sw = S.swing
	var waiting: int = _g(S, W_PDEG)
	if waiting != 0:
		_s(S, W_PDEG, 0)
		SimSwing.ask(S, {"deg": float(waiting) / 4096.0, "cause": "launch", "pivotX": float(_g(S, W_PPV)) / 16.0, "restBy": _g(S, W_PBY)})
	if sw.active and not _resting(sw):
		var ex = S.dirS.ex
		if restRule(S) != "" or int(sw.age) >= int(cfg().stallTicks):   # (a swing the law has all but stopped lets the next one come)
			SimSwing.rest(S, int(cfg().restOut))
		elif ex != null and DirBrawl.isBrawl(ex) and sw.cause != "small" and sw.cause != "brawl" and float(sw.rate) > float(SimSwing.data().causes.brawl.peak):
			SimSwing.ask(S, {"deg": float(sw.left), "cause": "brawl"})   # a swing the pair has caught up with comes down to a brawl's rate
	_nudgeTick(S)
	_fleeTick(S)
	_brawlTick(S)
