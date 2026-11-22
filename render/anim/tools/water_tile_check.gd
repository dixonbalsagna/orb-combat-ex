extends SceneTree
## The stance on water on the globe ground (Animation, docs/animation/water-tile-check.md; the EP's brief of 2026-11-20). On the globe ground a match is a planet slice and the sim's S.water is all zero (the sea lives in the tile
## field), so `anim_check`'s water-stance row, which picks its water out of S.water, runs on the strip ground. This check reads the planet's ring instead: at 240 places round it (every 640 units) the sim's floor
## (`WorldWater.floorAt`, the water floor on) against the tile field's drawn ground and water (`RenderTileField.height_at`, `water_top`), the fighter's feet taken as the shared placement lifts them (`lift`). The tiles are asked for as
## the camera asks in play: levels 3 and 4 at each place and 64 units either side (the first cut asked only for levels 1 and 2, 128-unit nodes, and read a steep lot ramp and a lake bed too coarsely: Rendering, 2026-11-20). Four kinds of place:
##   sea     the sim says sea and its floor is the sea's level (0): the feet are on the drawn water, within TOL (gate);
##   wade    the sim says dry but the tiles draw water over its ground (an inland depression below sea level, a shallow, a lake the sim has no level for): the feet are in it, under the drawn surface by less than wade.below
##           and never above it by more than TOL (gate: a body is never waist-deep or more where the rule says he wades, and never hovers over it);
##   dry     no drawn water: the feet are on the drawn ground, within TOL (gate);
##   lake    the sim says sea but its floor is a lake's level (not 0): the feet against the drawn lake surface, within TOL (gate under `--strict`, a finding without it).
## And the shore rows: along the whole ring at 16-unit steps, wherever the sim's water begins (`seaAt` flips), the depth of the first wet column over its ground must be under SHORE_TOL, two body heights (a lake's surface cannot
## sit above its shore: World's shore-level fault, measured at x 23,992 to 24,008 and two more edges on the GW1a stack). A finding without `--shore`, a gate with it.
## GW2 PINS (the EP's ruling of 2026-11-21: the lake group is out of GW1b): the lake rows, the shallow-lake places and the shore rows hold only with World's lake group in (`lake-places` with `lakeMax` and Rendering's
## `water-everywhere`, which draws every lake at the sim's level) and World's open shore-level fault fixed. Without them the sim holds lake levels the tile field draws no water for, and a body stands up to 684 units over a drawn lake bed.
## So by default those three lines are PINS: printed, counted, and not gates, and the check passes on GW1b without the lake group (and with it). `--lakes` makes the lake and shallow-lake lines gates (GW2, once the lake group lands);
## `--shore` makes the shore line one (World's fault); `--gw2` is both; `--strict` is `--lakes` (the name Rendering and the EP have used).
##   shallow the sim says dry but its floor stands the body above the ground (the water floor's wade lift, the bed to half the depth) while the tiles draw no water there: the same fault at a lake's margin (a `dry` place of the first cuts).
## Headless: no picture. Run with --path . --script. `--verbose`: every place beyond the tolerance.
const TOL: float = 6.0
const STEP: float = 640.0
const N: int = 240
const SIDE: float = 64.0
const SHORE_STEP: float = 16.0
const SHORE_TOL: float = 150.0   # two body heights: the wade line plus a steep bank's step in one scan step (the sea's own steep coasts read 75 to 78)

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var lakes_gate: bool = args.has("--lakes") or args.has("--strict") or args.has("--gw2")
	var shore_gate: bool = args.has("--shore") or args.has("--gw2")
	var verbose: bool = args.has("--verbose")
	WorldClimate.useGen(RenderTileGround.gen)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 4, {}, {"planet": RenderLook.TILE_PLANET, "touch": 3, "planetGen": RenderTileGround.gen, "intro": false})
	WorldFill.setFloor(true)
	var wade_below: float = WorldFill.wadeBelow()
	var fd := RenderTileField.new()
	fd.begin(S)
	while not fd.boot(100000):
		pass
	while not fd.boot_near(100000):
		pass
	var kinds := {"sea": [], "wade": [], "dry": [], "lake": [], "shallow": []}
	var water_cells := 0
	for i in range(SimConst.NC):
		if S.water[i] >= WorldWater.MIN_DEPTH:
			water_cells += 1
	var unloaded := 0
	for k in range(N):
		var x: float = float(k) * STEP
		# the tiles as the camera asks for them in play: levels 3 and 4 at the place and 64 either side, asked again each frame until they are all there
		var keys: Array = []
		for off in [-SIDE, 0.0, SIDE]:
			var dq: Vector3 = fd.dir_at(x + float(off), 0.0, S.frame)
			for L in [3, 4]:
				keys.append(RenderTileField.key_at(dq, L))
		var g2 := 0
		while g2 < 400:
			var left := 0
			for kk in keys:
				if not fd.has(int(kk)):
					fd.want(int(kk), 0.0)
					left += 1
			if left == 0:
				break
			fd.fill(300000)
			g2 += 1
		for kk in keys:
			if not fd.has(int(kk)):
				unloaded += 1
		fd.keep_off(x, 80)
		var d: Vector3 = fd.dir_at(x, 0.0, S.frame)
		var fl: float = WorldWater.floorAt(S, x)
		var gs: float = WorldTerrain.groundY(S, x)
		var h: float = fd.height_at(d)
		var wt: float = fd.water_top(d)
		var wet: bool = wt > -1.0e8
		var top: float = wt if wet else h
		var feet: float = fl + fd.lift(x, fl, 0.0)
		var sea: bool = WorldTerrain.seaAt(S, x)
		var kind: String = "dry"
		if sea and absf(fl) < 0.01:
			kind = "sea"
		elif sea:
			kind = "lake"
		elif wet and wt > h + 1.0:
			kind = "wade"
		elif fl - gs > TOL:
			kind = "shallow"
		(kinds[kind] as Array).append({"x": x, "gap": feet - top, "under": top - feet, "fl": fl, "g": gs, "wt": wt})
		if verbose and absf(feet - top) > TOL:
			print("  %s x %.0f: ground %.1f, the sim's floor %.1f, drawn ground %.1f, drawn water %s, feet %.1f, gap %.1f" % [kind, x, gs, fl, h, ("%.1f" % wt) if wet else "none", feet, feet - top])
	var fails: int = 0
	print("water on the globe ground: planet %d gen %d, %d places, %d cells of S.water (all zero: the sea is in the tile field); tiles of levels 3 and 4 asked at each place and %d either side%s" % [RenderLook.TILE_PLANET, RenderTileGround.gen, N, water_cells, int(SIDE), (" (%d not loaded)" % unloaded) if unloaded > 0 else ""])
	for kind in ["sea", "dry"]:
		var worst: float = 0.0
		var bad: int = 0
		for e in kinds[kind]:
			worst = maxf(worst, absf(float(e.gap)))
			if absf(float(e.gap)) > TOL:
				bad += 1
		var ok: bool = bad == 0
		if not ok:
			fails += 1
		print("%s %s: %d places, the feet are %.1f from the drawn %s at worst (%d over %.0f)" % ["ok  " if ok else "FAIL", kind, (kinds[kind] as Array).size(), worst, "water" if kind == "sea" else "ground", bad, TOL])
	var deepest: float = 0.0
	var over: int = 0
	for e in kinds["wade"]:
		deepest = maxf(deepest, float(e.under))
		if float(e.under) >= wade_below or float(e.under) < -TOL:
			over += 1
	var wok: bool = over == 0
	if not wok:
		fails += 1
	print("%s wade: %d places where the tiles draw water over what the sim calls dry ground, the feet under the surface by %.1f at most (wade.below %.0f; %d out of range)" % ["ok  " if wok else "FAIL", (kinds["wade"] as Array).size(), deepest, wade_below, over])
	var lbad: int = 0
	var lup: float = 0.0
	var ldown: float = 0.0
	var lkinds: Array = []
	for kk in ["lake", "shallow"]:
		var bad2: int = 0
		var up2: float = 0.0
		var down2: float = 0.0
		for e in kinds[kk]:
			if absf(float(e.gap)) > TOL:
				bad2 += 1
			up2 = maxf(up2, float(e.gap))
			down2 = minf(down2, float(e.gap))
		lbad += bad2
		lup = maxf(lup, up2)
		ldown = minf(ldown, down2)
		print("%s %s: %d places%s, the feet are %d beyond %.0f of the drawn %s; up to %.1f above it and %.1f below" % [("FAIL" if lakes_gate else "PIN GW2") if bad2 > 0 else "ok     ", kk, (kinds[kk] as Array).size(), " where the sim holds a lake's level" if kk == "lake" else " where the water floor lifts him over ground the tiles draw dry", bad2, TOL, "lake surface" if kk == "lake" else "ground", up2, -down2])
	if lakes_gate and lbad > 0:
		fails += 1
	# the shore rows
	var n_shore := 0
	var sbad := 0
	var sworst := 0.0
	var prev_sea: bool = WorldTerrain.seaAt(S, 0.0)
	var prev_x := 0.0
	var steps: int = int(float(SimConst.NC) * SimConst.COL / SHORE_STEP)
	for k in range(1, steps):
		var x2: float = float(k) * SHORE_STEP
		var sea2: bool = WorldTerrain.seaAt(S, x2)
		if sea2 != prev_sea:
			var wx: float = x2 if sea2 else prev_x
			var depth: float = WorldWater.floorAt(S, wx) - WorldTerrain.groundY(S, wx)
			n_shore += 1
			sworst = maxf(sworst, depth)
			if depth >= SHORE_TOL:
				sbad += 1
				if verbose:
					print("  shore x %.0f: the first wet column x %.0f has ground %.1f under a floor at %.1f (%.1f deep)" % [x2, wx, WorldTerrain.groundY(S, wx), WorldWater.floorAt(S, wx), depth])
		prev_sea = sea2
		prev_x = x2
	print("%s shore: %d places round the ring where the sim's water begins, the first wet column is %.1f deep at worst (SHORE_TOL %.0f; %d at or over)" % [("FAIL" if shore_gate else "PIN GW2") if sbad > 0 else "ok     ", n_shore, sworst, SHORE_TOL, sbad])
	if shore_gate and sbad > 0:
		fails += 1
	print("water tile check %s" % ("passed" if fails == 0 else "FAILED"))
	quit(1 if fails > 0 else 0)
