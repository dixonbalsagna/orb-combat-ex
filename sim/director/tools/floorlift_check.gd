extends SceneTree
## The floor of a lake or the sea against the fight's own moves (Game Design rulings 2026-10-30 rows 3, 9 and 11; docs/world/lake-floor.md). With the floor on, a body below his floor rises at most
## wade.below / riseTicks a tick (7.5), and no director line lifts him faster. A lift here is a tick that starts with him below his floor and ends with him no higher than his floor, out of a drop's surfacing and not launched. A move's own
## height is not the floor's and is counted apart (own): a rush at the rival, a bowed rush, or one aimed above his floor, his own flight and a brawl's drift by their velocity, and a launch's last tick, the same on dry land. Each part a PASS or FAIL line:
##   table    a drop and a straight-down launch on the bed at five depths, the case that popped him 16 to 388 a tick; with riseTicks 1 (no limit) the same drop must still pop, so the check can see it
##   moves    each director line that places a body, called with him on the bed of water 60 to 70 deep, and followed; with riseTicks 1 at least one must be over the rate
##   fight    AI matches with both bodies put back on that bed every few ticks, so the brawl's own steps and pulls meet them
##   throw    row 11: the grapple's down throw at shallow, shoulder and sheet: flat on his floor, the same opening, a splash on water, no crater
##   offer    row 12: MARSH SWALLOW at a mud column 37.5 to 75 deep: offered with the floor off, not with it on; at a shallower mud column offered either way
##   godot --headless --path . --script res://sim/director/tools/floorlift_check.gd [-- --matches=6]
## Exit code 1 on any FAIL.

const RINGS: Array = [7, 3, 11, 21, 25, 42]   # the planets searched for a ring with every band of depth
const DEPTHS: Array = [20.4, 45.4, 64.1, 77.2, 100.0]   # the depths the pop was first measured at, on planet 7, touch 1
const NEAR: float = 5.0   # a column within this of the depth asked for
const EPS: float = 1.0e-6
const LIMIT: float = 7.5   # wade.below / riseTicks as shipped; the control runs with riseTicks 1 and must go over it
const REPOSE: int = 14   # the fight: ticks between putting the bodies back on the bed

var fails: int = 0
var planet: int = 7
var touch: int = 1


func ok(c: bool, w: String) -> void:
	print("%s  %s" % ["PASS" if c else "FAIL", w])
	if not c:
		fails += 1


func _floor(on: bool, riseTicks: int = 10) -> void:
	WorldFill.setSurface(on)
	WorldFill.setFloor(on)
	DirInterrupt.data()["water"]["enabled"] = on   # the floor needs both halves of the surfacing rule (row 10)
	DirInterrupt.data()["water"]["riseTicks"] = riseTicks


func _match(p1: bool = false, p2: bool = false, sd: int = 1) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, sd, {"p1": p1, "p2": p2}, {"planet": planet, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false, "v2": [true, true]})
	return S


## The middle of the column of the ring's water nearest to depth deep; NAN when none is within NEAR.
func _column(S: SimState, depth: float) -> float:
	var best: float = NAN
	var off: float = NEAR
	for c in range(SimConst.NC):
		var x: float = (float(c) + 0.5) * SimConst.COL
		var e: float = absf(WorldWater.floorDepth(S, x) - depth)
		if e < off:
			off = e
			best = x
	return best


## The first ring with every band of depth.
func _pickRing() -> bool:
	for sd in RINGS:
		for t in [1, 0, 2]:
			planet = sd
			touch = t
			var S: SimState = _match()
			_floor(true)
			var all: bool = true
			for d in DEPTHS:
				all = all and not is_nan(_column(S, float(d)))
			_floor(false)
			SimCore.dispose(S)
			if all:
				return true
	return false


## The largest lift in n ticks of the full step: {"under": ticks he began below his floor, "max": his largest rise in those, "lift": the largest lift, "at": what it was}. A rise that ends on the actual ground is the ground's, as on dry
## land (he has walked or drifted in depth into a slope), and no lift.
func _track(S: SimState, n: int, into: Dictionary = {}) -> Dictionary:
	var r: Dictionary = into if not into.is_empty() else {"under": 0, "max": 0.0, "lift": 0.0, "at": "", "over": 0, "own": 0.0, "ownAt": ""}
	for t in range(n):
		if S.game.ko != null:
			break
		var pre: Array = []
		for f in S.fighters:
			var q = f.rush
			var own: bool = q != null and (q.tgt != null or q.arc != 0.0 or q.py > WorldWater.floorAt(S, q.px, f.z) + EPS)
			pre.append([f.x, f.y, f.z, f.state, DirWater.under(f), WorldWater.floorAt(S, f.x, f.z), q != null, own, f.vy])
		SimCore.step(S)
		for i in range(S.fighters.size()):
			var f = S.fighters[i]
			var p: Array = pre[i]
			if f.state == "dropped" or f.state == "launched" or DirWater.under(f) or p[4]:
				continue
			if float(p[1]) >= float(p[5]) - EPS:
				continue
			var rise: float = f.y - float(p[1])
			r.under += 1
			r.max = maxf(r.max, rise)
			if f.y <= WorldTerrain.groundY(S, f.x, f.z) + EPS:
				continue
			var at: String = "%s %s at %.0f (moved %.0f), from %.1f to %.1f (floor %.1f, ground %.1f) %s rush, %s" % [f.name, String(f.state), f.x, SimWrap.sdx(float(p[0]), f.x), float(p[1]), f.y, WorldWater.floorAt(S, f.x, f.z), WorldTerrain.groundY(S, f.x, f.z), "on a" if bool(p[6]) else "no", _last(S)]
			if bool(p[7]) or f.state == "down" or ((f.state == "free" or f.state == "locked") and rise <= maxf(f.vy, float(p[8])) * SimConst.DT + 1.0e-3):   # a launch's last tick, ending down off the ground; his own flight or the pair's drift (he keeps the stick, row 9)
				if rise > float(r.own):
					r.own = rise
					r.ownAt = at
				continue
			if rise > float(r.lift) and f.y <= WorldWater.floorAt(S, f.x, f.z) + EPS:
				r.lift = rise
				r.at = at
			if rise > LIMIT + EPS and f.y <= WorldWater.floorAt(S, f.x, f.z) + EPS:
				r.over += 1
	return r


## The exchange running, for the report: its template and tag.
func _last(S: SimState) -> String:
	var ex = S.dirS.ex
	return "no exchange" if ex == null else "exchange %s %s" % [str(ex.tpl), str(ex.tag)]


func _pose(S: SimState, low, other, x: float) -> void:
	for f in S.fighters:
		f.ai = null
		f.rush = null
		f.vx = 0.0
		f.vy = 0.0
		f.z = 0.0
		f.zT = 0.0
		f.state = "free"
		f.stunTicks = 0
	low.x = SimWrap.wrap(x)
	low.y = WorldTerrain.groundY(S, low.x)
	other.x = SimWrap.wrap(x + 60.0)
	other.y = WorldWater.floorAt(S, other.x)


## The table: [drop's largest lift, launch's largest lift] on the bed, band by band.
func _table(riseTicks: int) -> Array:
	var out: Array = []
	for b in DEPTHS:
		var row: Array = []
		for how in ["drop", "launch"]:
			var S: SimState = _match()
			_floor(true, riseTicks)
			var x: float = _column(S, float(b))
			var A = S.fighters[0]
			var D = S.fighters[1]
			_pose(S, D, A, x)
			A.x = SimWrap.wrap(x + 400.0)
			A.y = WorldWater.floorAt(S, A.x)
			if how == "drop":
				SimFighter.drop(S, D, 20)
			else:
				D.y = WorldTerrain.groundY(S, x) + 200.0
				D.state = "locked"
				S.dirS.ex = DirExchange.newEx(A, D, "probe")
				DirLaunch.doLaunch(S, A, D, {"name": "SLAM DOWN", "ux": 0.0, "uy": -1.0}, 2600.0, false)
				S.dirS.ex = null
			var tr: Dictionary = _track(S, 240)
			row.append(float(tr.lift))
			if riseTicks == 10 and float(tr.lift) > LIMIT + EPS:
				print("      %s: %s" % [how, String(tr.at)])
			_floor(false)
			SimCore.dispose(S)
		out.append(row)
	return out


## Each director line that places a body, called with that body on the bed. [name, the body on the bed: "A" or "D", the call: returns false if the move didn't run].
func _moves() -> Array:
	return [
		["pop", "D", func(S, ex, A, D): DirBrawl._pop(S, ex, A, D, 1.0); return D.rush != null],
		["spike", "D", func(S, ex, A, D): DirBrawl._spike(S, ex, A, D); return D.rush != null],
		["thrown apart", "D", func(S, ex, A, D): DirBrawl._thrownApart(S, ex); return D.rush != null],
		["step in", "A", func(S, ex, A, D): var y0: float = A.y; DirBrawl._stepIn(S, ex, A, D, 2); return A.y != y0 or A.x != D.x],
		["heavy recoil", "D", func(S, ex, A, D): return DirRecoil.heavyRecoil(S, ex, A, D)],
		["pop flip", "D", func(S, ex, A, D): return DirRecoil.popFlip(S, D, A)],
		["recoil flip", "D", func(S, ex, A, D):
			if not DirRecoil.heavyRecoil(S, ex, A, D):
				return false
			DirRecoil._flip(S, D)
			return D.rush != null and D.rush.arc != 0.0],
		["knock-back", "D", func(S, ex, A, D): DirLaunch.knock(S, A, D); return D.rush != null or D.state == "launched"],
		["contact", "A", func(S, ex, A, D): D.x = SimWrap.wrap(A.x + 90.0); D.y = WorldWater.floorAt(S, D.x); DirMelee._contact(S, A, D); return true],
		["dodge", "D", func(S, ex, A, D): DirMelee.opDodge(S, ex, null); return true],
		["meet", "T", func(S, ex, A, D): S.dirS.ex = null; DirBands.meet(S, A, D, 1, 0, S.tick); return D.rush != null],
		["zip's way out", "D", func(S, ex, A, D):
			S.dirS.ex = null
			DirZip._size(D)
			DirZip._s(D, DirZip.X0, roundi(D.x * DirZip.FX))
			DirZip._s(D, DirZip.Y0, roundi(D.y * DirZip.FX))
			DirZip._pickExit(S, D, A)
			DirZip._leave(S, D)
			return D.rush != null],
		["a brawl's pull", "D", func(S, ex, A, D): DirBrawl.begin(S, ex, "light"); return true],
	]


## Runs every move at riseTicks: the largest lift over all of them, and how many are over the rate.
func _runMoves(riseTicks: int, show: bool) -> Dictionary:
	var out: Dictionary = {"over": 0, "max": 0.0, "ran": 0, "total": 0}
	DirInterrupt.data()["recoilFlip"]["enabled"] = true
	DirInterrupt.data()["recoilFlip"]["heavy"]["enabled"] = true
	for m in _moves():
		var S: SimState = _match()
		_floor(true, riseTicks)
		var x: float = _column(S, 64.1)
		var A = S.fighters[0]
		var D = S.fighters[1]
		var low = D if String(m[1]) != "A" else A
		_pose(S, low, A if low == D else D, x)
		var ex = DirExchange.newEx(A, D, "probe")
		S.dirS.ex = ex
		A.state = "locked"
		D.state = "locked"
		var y0: float = low.y
		var ran: bool = bool((m[2] as Callable).call(S, ex, A, D))
		var placed: float = low.y - y0   # a line that sets his height at once
		if placed <= LIMIT + EPS or low.y > WorldWater.floorAt(S, low.x, low.z) + EPS:
			placed = 0.0
		var r: Dictionary = _track(S, 40)
		r.lift = maxf(float(r.lift), placed)
		r.over += 1 if placed > 0.0 else 0
		out.total += 1
		out.ran += 1 if ran else 0
		out.over += int(r.over)
		out.max = maxf(out.max, float(r.lift))
		if show:
			ok(ran and int(r.over) == 0, "moves: %s: under his floor %d ticks, largest lift %.2f a tick, limit %.1f%s%s%s" % [String(m[0]), int(r.under), float(r.lift), LIMIT, " (%s)" % String(r.at) if int(r.over) > 0 else "", "; its own height %.2f" % float(r.own) if float(r.own) > LIMIT else "", "" if ran else "; THE MOVE DID NOT RUN"])
		_floor(false)
		SimCore.dispose(S)
	return out


## AI matches with both bodies put back on the bed every REPOSE ticks.
func _fight(matches: int, riseTicks: int) -> Dictionary:
	var r: Dictionary = {"under": 0, "max": 0.0, "lift": 0.0, "at": "", "over": 0, "own": 0.0, "ownAt": "", "ticks": 0, "brawl": 0}
	for m in range(matches):
		var S: SimState = _match(true, true, m + 1)
		_floor(true, riseTicks)
		var x: float = _column(S, 64.1)
		for t in range(240):
			if S.game.ko != null:
				break
			var A = S.fighters[0]
			var D = S.fighters[1]
			for f in S.fighters:
				if f.state != "launched" and f.state != "dropped" and A.rush == null and D.rush == null and not DirWater.under(f):
					f.x = SimWrap.wrap(x + (0.0 if f == A else 50.0))
					f.y = WorldTerrain.groundY(S, f.x)
					f.vx = 0.0
					f.vy = 0.0
			_track(S, REPOSE, r)
			r.ticks += REPOSE
			if S.dirS.ex != null and S.dirS.ex.tpl == DirBrawl.TPL:
				r.brawl += 1
		_floor(false)
		SimCore.dispose(S)
	return r


## Row 11: the down throw at a column about that deep: [his height less his floor, the opening's ticks, splashes, the ground's change].
func _throw(depth: float) -> Array:
	var S: SimState = _match()
	_floor(true)
	var x: float = _column(S, depth)
	var A = S.fighters[0]
	var D = S.fighters[1]
	_pose(S, D, A, x)
	D.y = WorldWater.floorAt(S, x) + 10.0
	var ex = DirExchange.newEx(A, D, "probe")
	S.dirS.ex = ex
	A.state = "locked"
	D.state = "locked"
	DirBrawl.begin(S, ex, "light")
	var g0: float = WorldTerrain.groundY(S, x)
	S.out.fx.clear()
	DirGrapple._throw(S, ex, A, D, 3, "throw")
	var splashes: int = 0
	var opened: int = 0
	for e in S.out.fx:
		if String(e.type) == "splash":
			splashes += 1
	var gap: float = D.y - WorldWater.floorAt(S, D.x)
	var dug: float = absf(WorldTerrain.groundY(S, x) - g0)
	opened = D.stunTicks
	_floor(false)
	SimCore.dispose(S)
	return [gap, opened, splashes, dug]


## Is MARSH SWALLOW offered at x? The body low over the ground, the launch planner's biome candidates on.
func _offered(S: SimState, x: float) -> bool:
	var A = S.fighters[0]
	var D = S.fighters[1]
	_pose(S, D, A, x)
	D.y = WorldTerrain.groundY(S, x) + 2.0
	A.y = D.y
	S.dirS.ex = DirExchange.newEx(A, D, "probe")
	D.state = "locked"
	var seen: bool = false
	for k in DirLaunch.chooseLaunch(S, A, D, 2600.0).all:
		seen = seen or String(k.name) == "MARSH SWALLOW"
	S.dirS.ex = null
	return seen


## Row 12: [deep mud column's depth, offered with the floor off, with it on; shallow column's depth, offered off, on], or [] when no ring has both.
func _offer() -> Array:
	DirLaunch.forceBiome = 1
	var out: Array = []
	for sd in [42, 7, 3, 11, 21, 25, 47]:
		for t in [0, 1, 2, 3]:
			if not out.is_empty():
				continue
			planet = sd
			touch = t
			var S: SimState = _match()
			_floor(true)
			var deep: float = NAN
			var shallow: float = NAN
			for c in range(SimConst.NC):
				var x: float = (float(c) + 0.5) * SimConst.COL
				if WorldContact.lookAt(S, x) != "mud" or WorldTerrain.seaAt(S, x):
					continue
				var d: float = WorldWater.floorDepth(S, x)
				if d >= 37.5 and d < 75.0 and is_nan(deep):
					deep = x
				elif d < 37.5 and is_nan(shallow):
					shallow = x
			if not is_nan(deep) and not is_nan(shallow):
				var on: Array = [_offered(S, deep), _offered(S, shallow)]
				_floor(false)
				out = [WorldWater.floorDepth(S, deep), _offered(S, deep), on[0], WorldWater.floorDepth(S, shallow), _offered(S, shallow), on[1]]
			_floor(false)
			SimCore.dispose(S)
	DirLaunch.forceBiome = -1
	return out


func _init() -> void:
	var matches: int = 6
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--matches="):
			matches = int(a.substr(10))
	ok(_pickRing(), "a ring with every band of depth: planet %d, touch %d" % [planet, touch])
	var rate: float = LIMIT
	var live: Array = _table(10)
	var ctl: Array = _table(1)
	for i in range(DEPTHS.size()):
		var dOk: bool = float(live[i][0]) <= rate + EPS and float(live[i][1]) <= rate + EPS
		ok(dOk, "table: on the bed about %.1f deep: drop's largest lift %.2f, launch's %.2f, limit %.1f; control (riseTicks 1, no limit) %.2f and %.2f" % [float(DEPTHS[i]), float(live[i][0]), float(live[i][1]), rate, float(ctl[i][0]), float(ctl[i][1])])
	ok(float(ctl[1][0]) >= 15.0 and float(ctl[2][0]) >= 50.0, "table: the control sees the pop: a drop about 45.4 deep lifts %.2f in one tick, about 64.1 deep %.2f (first measured at 15.81 and 53.17)" % [float(ctl[1][0]), float(ctl[2][0])])
	var mv: Dictionary = _runMoves(10, true)
	var mc: Dictionary = _runMoves(1, false)
	ok(int(mc.over) > 0, "moves: the control sees it: with riseTicks 1 the largest lift is %.2f a tick, %d ticks over 7.5" % [float(mc.max), int(mc.over)])
	var fg: Dictionary = _fight(matches, 10)
	var fc: Dictionary = _fight(maxi(1, matches / 2), 1)
	ok(int(fg.over) == 0 and int(fg.under) > 0, "fight: %d AI ticks on the bed, %d of them under his floor, %d reposes in a brawl: largest lift %.2f a tick, %d over the limit %.1f%s; a move's own height up to %.2f (%s)" % [int(fg.ticks), int(fg.under), int(fg.brawl), float(fg.lift), int(fg.over), rate, " (%s)" % String(fg.at) if int(fg.over) > 0 else "", float(fg.own), String(fg.ownAt)])
	ok(int(fc.over) > 0, "fight: the control sees it: with riseTicks 1 the largest lift is %.2f a tick (%s)" % [float(fc.lift), String(fc.at)])
	for t in [[20.4, "shallow"], [64.1, "shoulder"], [100.0, "sheet"]]:
		var r: Array = _throw(float(t[0]))
		ok(absf(float(r[0])) < EPS and int(r[1]) > 0 and int(r[2]) > 0 and float(r[3]) == 0.0, "throw: %s: flat on his floor (%.3f off it), open %d ticks, %d splash, the ground moved %.2f" % [String(t[1]), float(r[0]), int(r[1]), int(r[2]), float(r[3])])
	var o: Array = _offer()
	ok(not o.is_empty() and bool(o[1]) and not bool(o[2]) and bool(o[4]) and bool(o[5]), "offer: MARSH SWALLOW %s" % ("no ring with both columns" if o.is_empty() else "at mud %.1f deep: offered %s with the floor off, %s with it on; at mud %.1f deep: %s and %s (planet %d, touch %d)" % [float(o[0]), str(o[1]), str(o[2]), float(o[3]), str(o[4]), str(o[5]), planet, touch]))
	print("FLOORLIFT: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
