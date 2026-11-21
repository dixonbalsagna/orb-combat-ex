extends SceneTree
## Scratch: what PROP SMASH's aim costs per plan on gen 2. Poses as propreach_probe's, every 4th column, both ways, ground and low air.
##   godot --headless --path . --script res://plan_cost.gd -- <seeds> [--mode=0] [--rep=3]
## Times are min of rep calls (a load-proof floor) in microseconds.

const SEEDS: Array = [7, 3, 11, 25, 1, 2, 5, 13, 17, 19, 23, 31]
const HEIGHTS: Array = [2.0, 50.0]


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


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var ns: int = int(args[0]) if args.size() > 0 else 6
	var rep := 3
	for s in args:
		if s.begins_with("--mode="):
			DirLaunch.dbgMode = int(s.substr(7))
		elif s.begins_with("--rep="):
			rep = int(s.substr(6))
		elif s.begins_with("--budget="):
			DirLaunch.dbgBudget = int(s.substr(9))
	DirLaunch.forceBiome = 1
	var force: float = float(DirBrawl.cfg().get("heavy", {}).get("force", 1.0))
	var r := {"mode": DirLaunch.dbgMode, "budget": DirLaunch.dbgBudget, "poses": 0, "called": 0, "offered": 0, "hitFm": {}, "ticks": [], "flights": [], "us": [], "usAll": [], "hitTicks": [], "missTicks": [], "offeredKeys": []}
	for k in range(ns):
		var sd: int = int(SEEDS[k])
		for touch in [0, 1]:
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, _setup(sd, touch))
			for col in range(0, SimConst.NC, 4):
				var x: float = (float(col) + 0.5) * SimConst.COL
				for sg in [1.0, -1.0]:
					for h in HEIGHTS:
						_pose(S, x, sg, h)
						r.poses += 1
						var pf: float = force * SimForms.launchMul(S, S.fighters[0])
						var c: Array = []
						DirLaunch.dbgTicks = 0
						DirLaunch.dbgFlights = 0
						DirLaunch.dbgHitT = 0
						var t0: int = Time.get_ticks_usec()
						DirLaunch._biomeCands(S, S.fighters[0], S.fighters[1], c, false, not DirData.contact().is_empty(), pf)
						var best: int = Time.get_ticks_usec() - t0
						var ticks: int = DirLaunch.dbgTicks
						if DirLaunch.dbgFlights == 0:
							continue
						r.called += 1
						for _q in range(rep - 1):
							c = []
							t0 = Time.get_ticks_usec()
							DirLaunch._biomeCands(S, S.fighters[0], S.fighters[1], c, false, not DirData.contact().is_empty(), pf)
							best = mini(best, Time.get_ticks_usec() - t0)
						var bestC: int = 1 << 40
						for _q2 in range(rep):
							_pose(S, x, sg, h)
							t0 = Time.get_ticks_usec()
							DirLaunch.chooseLaunch(S, S.fighters[0], S.fighters[1], force)
							bestC = mini(bestC, Time.get_ticks_usec() - t0)
						(r.usAll as Array).append(bestC)
						(r.ticks as Array).append(ticks)
						(r.flights as Array).append(DirLaunch.dbgFlights)
						(r.us as Array).append(best)
						var pk: Array = c.filter(func(q): return String(q.name) == "PROP SMASH")
						if pk.size() > 0:
							r.offered += 1
							var fm: String = str(pk[0].fm)
							r.hitFm[fm] = int(r.hitFm.get(fm, 0)) + 1
							(r.hitTicks as Array).append(DirLaunch.dbgHitT)
							(r.offeredKeys as Array).append("%d/%d/%d/%d/%d/%s/%s" % [sd, touch, col, int(sg), int(h), pk[0].prop, fm])
						else:
							(r.missTicks as Array).append(ticks)
			SimCore.dispose(S)
	for k in ["ticks", "flights", "us", "usAll", "hitTicks", "missTicks"]:
		var a: Array = r[k]
		a.sort()
		var n: int = a.size()
		r[k] = {"n": n, "p50": a[n / 2] if n > 0 else 0, "p90": a[n * 9 / 10] if n > 0 else 0, "p99": a[n * 99 / 100] if n > 0 else 0, "max": a[n - 1] if n > 0 else 0}
	print("COST " + JSON.stringify(r))
	quit()
