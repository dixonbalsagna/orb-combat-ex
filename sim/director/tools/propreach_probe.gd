extends SceneTree
## Prop-reach (docs/ep/cloud-briefs/encounter-prop-reach.md item 1; World's W6 report, NEEDS 1): PROP SMASH's plan and
## World's flight agree. Gen 2 planets are searched for spots where PROP SMASH is offered, the target posed on the ground
## and in the air, with Combat's biome switch on (DirLaunch.forceBiome, tools only). Each spot is launched with the
## planner's own PROP SMASH plan (DirLaunch.doLaunch, as World's flighthooks probe does when the launch beat picks
## another candidate), and the flight is followed to its end. Each part a PASS or FAIL line:
##   reach   every launch breaks its plan's prop and he stops at it: none ends short of it, none passes over its top.
##           The real flight is compared with the planner's predicted path (DirLaunch._propFlight, frozen ticks skipped);
##           one that leaves that path before the prop is counted apart, with where and why (World's ground changed
##           under him: the prediction, like WorldContact.journey, does not see the ground the flight itself changes)
##   base    the same with the row's aimFm left out, so only the row's own force is tried
##   aimed   how many of reach's plans needed more than the row's own force, and the largest it took; and at how many
##           of the poses searched PROP SMASH is offered, with aimFm and without
##   godot --headless --path . --script res://sim/director/tools/propreach_probe.gd [-- --spots=48]
## Exit code 1 on any FAIL.

const SEEDS: Array = [7, 3, 11, 25, 1, 2, 5, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79]
const HEIGHTS: Array = [2.0, 50.0]   # the target's height above the ground as it is launched: a brawl on the ground, and one just above it
const SPACE: int = 20                # columns between two spots on a planet
const PER_PLANET: int = 4            # spots kept a planet, so they come from many
const SCAN: int = 12                 # planets searched in full (the first six seeds, both touches), for the offer counts
const FLY: int = 900                 # ticks a launch is followed at most

var fails: int = 0
var maxSpots: int = 48


func ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		fails += 1


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--spots="):
			maxSpots = int(a.substr(8))
	DirLaunch.forceBiome = 1
	WorldContact.hookLogOn = true
	var reach: Dictionary = _part()
	ok(reach.n > 0 and reach.short == 0 and reach.over == 0 and reach.broke + reach.left == reach.n and reach.stopOk == reach.broke, "reach: %s" % _says(reach))
	var row: Dictionary = DirLaunch.biome().get("candidates", {}).get("PROP SMASH", {})
	var keep = row.get("aimFm", null)
	row.erase("aimFm")
	var base: Dictionary = _part()
	if keep != null:
		row["aimFm"] = keep
	ok(base.n > 0 and base.short == 0 and base.over == 0 and base.broke + base.left == base.n and base.stopOk == base.broke, "base: with the row's own force only, %s" % _says(base))
	print("PASS  aimed: %d of %d plans took more than the row's own force (the largest x%.2f); PROP SMASH is offered at %d of %d poses searched with aimFm, %d without" % [reach.aimed, reach.n, reach.maxFm, reach.posesOn, reach.poses, base.posesOn])
	for k in ["shown", "shownAim", "shownLeft"]:
		if reach[k] != "":
			print("      " + reach[k])
	DirLaunch.forceBiome = -1
	WorldContact.hookLogOn = false
	print("propreach probe " + ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


func _says(r: Dictionary) -> String:
	return "PROP SMASH in %d launches on %d planets broke its prop %d times and stopped him at it %d times; on the predicted path %d ended short of the prop and %d passed over its top; %d left the predicted path before the prop (the ground changed under the flight, which the prediction does not see: NEEDS FROM EP)" % [r.n, r.planets, r.broke, r.stopOk, r.short, r.over, r.left]


func _setup(sd: int, touch: int) -> Dictionary:
	return {"planet": sd, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}


func _pose(S: SimState, x: float, sg: float, h: float) -> void:
	var A = S.fighters[0]
	var D = S.fighters[1]
	for f in S.fighters:
		f.ai = null
		f.rush = null
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	var g: float = WorldTerrain.groundY(S, x)
	D.x = SimWrap.wrap(x)
	D.y = (WorldWater.seaTop(S, x) + 40.0) if WorldTerrain.seaAt(S, x) else g + h
	A.x = SimWrap.wrap(x - sg * 200.0)
	A.y = D.y
	A.face = sg
	D.face = -sg


func _force() -> float:
	return float(DirBrawl.cfg().get("heavy", {}).get("force", 1.0))


func _offered(S: SimState) -> bool:
	var c: Array = []
	DirLaunch._biomeCands(S, S.fighters[0], S.fighters[1], c, false, not DirData.contact().is_empty(), _force() * SimForms.launchMul(S, S.fighters[0]))
	return c.any(func(k): return String(k.name) == "PROP SMASH")


## The spots, then each launched: {"n", "planets", "poses", "posesOn", "broke", "stopOk", "short", "over", "aimed", "maxFm",
## "shown", "shownAim"}. The first SCAN planets are searched at every pose for the offer counts; spots are kept from
## every planet, PER_PLANET a planet, until there are maxSpots.
func _part() -> Dictionary:
	var spots: Array = []
	var poses: int = 0
	var posesOn: int = 0
	var planets: int = 0
	var i: int = 0
	for sd in SEEDS:
		for touch in [0, 1]:
			i += 1
			var full: bool = i <= SCAN
			if spots.size() >= maxSpots and not full:
				break
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, _setup(sd, touch))
			var last: int = -999
			var kept: int = 0
			for col in range(0, SimConst.NC, 4):
				if not full and (kept >= PER_PLANET or spots.size() >= maxSpots):
					break
				var x: float = (float(col) + 0.5) * SimConst.COL
				for sg in [1.0, -1.0]:
					for h in HEIGHTS:
						_pose(S, x, sg, h)
						var on: bool = _offered(S)
						if full:
							poses += 1
							posesOn += 1 if on else 0
						if on and col - last >= SPACE and kept < PER_PLANET and spots.size() < maxSpots:
							spots.append([sd, touch, x, sg, h])
							last = col
							kept += 1
			planets += 1 if kept > 0 else 0
			SimCore.dispose(S)
	var r := {"n": 0, "planets": planets, "poses": poses, "posesOn": posesOn, "broke": 0, "stopOk": 0, "short": 0, "over": 0, "left": 0, "aimed": 0, "maxFm": 1.0, "shown": "", "shownAim": "", "shownLeft": ""}
	for sp in spots:
		var p: Dictionary = _play(sp)
		if p.is_empty():
			continue
		r.n += 1
		var fm: float = float(p.plan.get("fm", 1.0))
		if fm > 1.0:
			r.aimed += 1
			r.maxFm = maxf(r.maxFm, fm)
		var e: Array = p.log.filter(func(x): return x.k == "prop")
		if e.is_empty() and not p.left.is_empty():
			r.left += 1   # the flight left the planner's path before the prop: the ground changed under him
			if r.shownLeft == "":
				r.shownLeft = "planet %d touch %d at x %.0f: he left the predicted path at x %.0f, y %.1f (predicted %.0f, %.1f; that tick: %s), %.0f short of the %s, then %s" % [
					int(sp[0]), int(sp[1]), float(sp[2]), float(p.left.x), float(p.left.y), float(p.left.px), float(p.left.py), String(p.left.kinds), float(p.left.short), String(p.plan.prop),
					"passed %.0f over its top" % float(p.log.filter(func(x): return x.k == "prop_over")[0].over) if p.log.any(func(x): return x.k == "prop_over") else "ended short of it"]
			continue
		if e.is_empty():
			if p.log.any(func(x): return x.k == "prop_over"):
				r.over += 1
			else:
				r.short += 1
			continue
		r.broke += 1
		if absf(SimWrap.sdx(float(e[0].x), float(e[0].stopX))) <= WorldContact.PROP_STOP + 1.0e-6 and absf(SimWrap.sdx(float(e[0].x), float(p.plan.land))) <= 0.01:
			r.stopOk += 1
		var k: String = "shownAim" if fm > 1.0 else "shown"
		if r[k] == "":
			r[k] = "planet %d at x %.0f (%s): a %s %.0f ahead broke at speed %.0f with force x%.2f; he stopped at %.0f, %.1f damage" % [
				int(sp[0]), float(sp[2]), "on the ground" if float(sp[4]) < 10.0 else "%.0f above it" % float(sp[4]), String(e[0].kind),
				absf(SimWrap.sdx(float(sp[2]), float(e[0].x))), float(e[0].speed), fm, float(e[0].stopX), float(e[0].dmg)]
	return r


## One spot launched with the planner's PROP SMASH plan and followed to its end: {"plan", "log"}, or {} when the plan is
## not offered there.
func _play(sp: Array) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, _setup(int(sp[0]), int(sp[1])))
	_pose(S, float(sp[2]), float(sp[3]), float(sp[4]))
	var A = S.fighters[0]
	var D = S.fighters[1]
	S.out.fx.clear()
	S.out.feed.clear()
	WorldContact.hookLog.clear()
	var ex = DirExchange.newEx(A, D, "probe")
	S.dirS.ex = ex
	D.state = "locked"
	var used: Dictionary = {}
	for k in DirLaunch.chooseLaunch(S, A, D, _force()).all:
		if String(k.name) == "PROP SMASH":
			used = k
	if used.is_empty():
		SimCore.dispose(S)
		return {}
	# The planner's predicted path for the plan's prop, to tell a flight that left it (World's ground changed under him)
	# from a prediction that was wrong.
	var pq: Dictionary = DirLaunch.biome().candidates["PROP SMASH"]
	var reach: float = float(pq.reachBh) * DirLaunch.BH
	var props: Array = DirLaunch._propTargets(S, D, DirLaunch._propsNear(S, D.x - reach, D.x + reach), pq.props, A.face, reach).filter(func(q): return absf(float(q.x) - float(used.land)) < 0.01)
	var rec: Array = []
	DirLaunch._propFlight(S, A, D, float(used.ux), float(used.uy), _force() * float(used.get("fm", 1.0)) * SimForms.launchMul(S, A), props, rec)
	DirLaunch.doLaunch(S, A, D, used, _force())
	var n: int = D.launchN
	var i: int = 0
	var left: Dictionary = {}
	for t in range(FLY):
		if D.state != "launched":
			break
		SimCore.step(S)
		var frozen: bool = false
		var kinds: PackedStringArray = []
		for e in S.out.fx:
			if String(e.type) == "tick":
				frozen = frozen or e.frozen
			elif String(e.type) != "particle":
				kinds.append(String(e.type))
		if not frozen and left.is_empty() and i < rec.size() and not WorldContact.hookLog.any(func(e): return int(e.n) == n and e.k == "prop"):
			if absf(SimWrap.sdx(D.x, float(rec[i][0]))) > 1.0 or absf(D.y - float(rec[i][1])) > 1.0:
				left = {"x": D.x, "y": D.y, "px": float(rec[i][0]), "py": float(rec[i][1]), "kinds": ", ".join(kinds), "short": SimWrap.sdx(D.x, float(used.land)) * A.face}
			i += 1
		S.out.fx.clear()
		S.out.feed.clear()
	var out := {"plan": used, "log": WorldContact.hookLog.filter(func(e): return int(e.n) == n), "left": left}
	SimCore.dispose(S)
	return out
