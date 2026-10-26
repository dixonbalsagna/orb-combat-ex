extends SceneTree
# Water v2 (docs/world/water-v2.md, data/biomes/water.json, off by default): holes the fight digs fill with water where water would plausibly come from; the skim stays; shallow water is waded; the three payoffs.
#   godot --headless --path . --script res://sim/world/tools/fill_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func evs(S: SimState, type: String) -> Array:
	var out: Array = []
	for e in S.out.fx:
		if e.type == type:
			out.append(e)
	return out


## A flat world: sea on columns 0 to 299 (the sea floor at -300), a plain at 30 from there on; the fine biome of every column `fine` (a gen 2 world), or none (the hand-made biomes).
func world(fine: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var nc: int = SimConst.NC
	S.base.fill(30.0)
	for i in range(300):
		S.base[i] = -300.0
	S.deform.fill(0.0)
	S.rubble.fill(0.0)
	S.scorch.fill(0.0)
	S.buildings.clear()
	S.trees.clear()
	S.craters.clear()
	WorldWater.init(S)
	if fine >= 0:
		var pc := PackedByteArray()
		pc.resize(nc)
		pc.fill(1)
		var fc := PackedByteArray()
		fc.resize(nc)
		fc.fill(fine)
		WorldBiomes.planetCols = pc
		WorldBiomes.fineCols = fc
		WorldBiomes.worldId = WorldBiomes.claim()
		S.worldId = WorldBiomes.worldId
	S.fighters[0].x = 40000.0
	S.fighters[1].x = 41000.0
	return S


## A hole dug as a fight digs one: columns c0 +- half lowered by `depth`, then the water module told, as the crater and the beam code tell it.
func dig(S: SimState, c0: int, half: int, depth: float) -> void:
	for k in range(-half, half + 1):
		S.deform[c0 + k] = -depth * (1.0 - absf(float(k)) / float(half + 1) * 0.3)
	WorldWater.touched(S, c0, half + 4, 30.0 - depth)


func settle(S: SimState, steps: int) -> int:
	var n: int = 0
	while n < steps and not S.waterWin.is_empty():
		for t in range(WorldWater.STEP_TICKS):
			WorldWater.step(S)
		n += 1
	return n


func wetCols(S: SimState, lo: int, hi: int) -> int:
	var c: int = 0
	for i in range(lo, hi + 1):
		if S.water[i] >= WorldWater.MIN_DEPTH:
			c += 1
	return c


func _init() -> void:
	ok(WorldFill.dataErrors().is_empty(), "water.json is clean (%s)" % str(WorldFill.dataErrors()))
	ok(not WorldFill.on(), "the switch (data/biomes/water.json enabled) is off in the data")
	WorldFill.on()
	# --- off: a hole on the plain by the sea stays dry, as it always did, and no window opens
	WorldFill.K_ON = false
	var S0: SimState = world(-1)
	dig(S0, 330, 6, 50.0)
	var n0: int = settle(S0, 400)
	ok(wetCols(S0, 320, 340) == 0 and S0.waterWin.is_empty() and evs(S0, "water_fill").is_empty(), "off: a trench dug by the sea on higher ground stays dry and opens no window (the no-inland-flooding rule)")
	# --- on: the same hole fills from the sea, behind a front, to sea level
	WorldFill.K_ON = true
	var S1: SimState = world(-1)
	dig(S1, 330, 6, 50.0)
	var hasWin: bool = S1.waterWin.size() == 1 and S1.waterWin[0].size() > 4
	var cue: Array = evs(S1, "water_fill")
	ok(hasWin and cue.size() == 1 and cue[0].cause == "sea" and cue[0].spd > 0.0 and cue[0].k > 0.0, "on: the same trench opens a fill window and one water_fill cue (cause %s, front %.0f units/s, rate %.0f/s, %d columns)" % [cue[0].cause if cue.size() > 0 else "-", cue[0].spd if cue.size() > 0 else 0.0, cue[0].k if cue.size() > 0 else 0.0, int(cue[0].n) if cue.size() > 0 else 0])
	var peek: int = 0
	var frontOk: bool = true
	var firstFar: int = -1
	while not S1.waterWin.is_empty() and peek < 400:
		for t in range(WorldWater.STEP_TICKS):
			WorldWater.step(S1)
		peek += 1
		if peek == 10:
			# the front runs from the source (the sea's edge at column 299): at step 3 the near columns are wet and the far ones are not
			frontOk = S1.water[324] >= WorldWater.MIN_DEPTH or S1.water[325] >= WorldWater.MIN_DEPTH or S1.water[326] >= WorldWater.MIN_DEPTH
			if S1.water[336] >= WorldWater.MIN_DEPTH:
				firstFar = 336
	var lvl: float = S1.base[330] + S1.deform[330] + S1.water[330]
	ok(wetCols(S1, 320, 340) >= 9 and absf(lvl) < 0.5, "on: the trench is wet (%d columns) with its surface at the sea's level (%.2f) and the window closed after %d steps" % [wetCols(S1, 320, 340), lvl, peek])
	ok(frontOk and firstFar < 0, "the fill is a front from the source: at step 10 the near end is wet and the far end is not yet")
	ok(S1.world.casualties == 0.0 and S1.craters.size() == 0, "the fill does no damage and makes no casualty (Game Design row 17)")
	# --- a dry biome far from water stays dry; a wetland seeps
	var S2: SimState = world(WorldClimate.F_DESERT)
	dig(S2, 4000, 6, 50.0)
	settle(S2, 400)
	ok(wetCols(S2, 3980, 4020) == 0 and S2.waterWin.is_empty(), "a hole in a desert far from water stays dry")
	var S3: SimState = world(WorldClimate.F_WETLAND)
	dig(S3, 4000, 6, 50.0)
	var wasWin: int = S3.waterWin.size()
	var c3: Array = evs(S3, "water_fill")
	settle(S3, 400)
	var l3: float = S3.base[4000] + S3.deform[4000] + S3.water[4000]
	ok(wasWin == 1 and c3.size() == 1 and c3[0].cause == "table" and absf(l3 - (30.0 - 6.0)) < 0.5, "a hole in a wetland far from water seeps full to its table (surface %.1f, the ground's 30 less 6), cue cause %s with no front" % [l3, c3[0].cause if c3.size() > 0 else "-"])
	var S4: SimState = world(WorldClimate.F_JUNGLE)
	dig(S4, 4000, 6, 20.0)
	settle(S4, 400)
	ok(wetCols(S4, 3980, 4020) == 0, "a jungle hole shallower than its water table (45) stays dry")
	# --- the skim: a scar dug along the plain, flooded, is skimmable; dry it is not
	var skims: Array = []
	for state in [false, true]:
		WorldFill.K_ON = state
		var Ss: SimState = world(-1)
		for i in range(305, 405):
			Ss.deform[i] = -50.0
		WorldWater.touched(Ss, 355, 54, -20.0)
		settle(Ss, 600)
		var b: WorldContact.Body = WorldContact.launchBody(305.5 * SimConst.COL, 8.0, 2200.0, -60.0, 1.0, 2.0)
		var jr: Dictionary = WorldContact.journey(Ss, b)
		var sk: int = 0
		for c in jr.contacts:
			if c.kind == "skim":
				sk += 1
		skims.append(sk)
	WorldFill.K_ON = true
	ok(skims[0] == 0 and skims[1] >= 3 and skims[1] <= 6, "a send along a dug scar: dry it skims %d times, flooded %d (the sea's rules: at most 6, 85%% kept each)" % [skims[0], skims[1]])
	# --- shallow water is waded: no drag, no sink
	var drag: Array = []
	for wade in [0.0, 75.0]:
		WorldFill.K_WADE = wade
		var Sw: SimState = world(-1)
		for i in range(305, 405):
			Sw.deform[i] = -50.0
		WorldWater.touched(Sw, 355, 54, -20.0)
		settle(Sw, 600)
		var b2: WorldContact.Body = WorldContact.launchBody(305.5 * SimConst.COL, 4.0, 400.0, -30.0, 1.0, 2.0)   # slow: below the skim speed
		var j2: Dictionary = WorldContact.journey(Sw, b2)
		drag.append(float(j2.dist))
	WorldFill.K_WADE = 75.0
	ok(drag[1] > drag[0] * 1.3, "a slow body through a shallow fill is waded, not dragged to a stop: %.0f units (%.0f with nothing counted as shallow, where the sea's drag stops it)" % [drag[1], drag[0]])
	# --- the crater wave: a slam into standing water pushes whatever is at the surface outward
	var Sv: SimState = world(-1)
	Sv.base[400] = Sv.base[400]
	for i in range(380, 421):
		Sv.deform[i] = -80.0
		Sv.water[i] = 100.0   # a flooded crater (it filled earlier)
	var surface: float = Sv.base[400] + Sv.deform[400] + Sv.water[400]
	Sv.fighters[0].x = 400.0 * SimConst.COL + 200.0
	Sv.fighters[0].y = surface + 10.0
	var x0: float = Sv.fighters[0].x
	WorldFill.slam(Sv, 400.0 * SimConst.COL, 20.0)
	var waves: Array = evs(Sv, "water_wave")
	var guard: int = 0
	while not Sv.waterWin.is_empty() and guard < 50:
		for t in range(WorldWater.STEP_TICKS):
			WorldWater.step(Sv)
		guard += 1
	var pushed: float = Sv.fighters[0].x - x0
	ok(waves.size() == 1 and pushed > 60.0 and pushed < 90.0, "a slam into a flooded crater throws one ring wave (water_wave) and pushes a fighter at the surface %.0f units outward, over %d steps" % [pushed, guard])
	var Sd: SimState = world(-1)
	for i in range(380, 421):
		Sd.deform[i] = -80.0
	Sd.fighters[0].y = 5000.0
	var xf: float = Sd.fighters[0].x
	WorldFill.slam(Sd, 400.0 * SimConst.COL, 20.0)
	ok(Sd.waterWin.is_empty() and evs(Sd, "water_wave").is_empty(), "a slam into a dry crater throws no wave")
	# --- fire: a fill that reaches scorched ground puts it out (the event the steam hangs on)
	var Sf: SimState = world(-1)
	for i in range(318, 326):
		Sf.scorch[i] = 0.8
	dig(Sf, 322, 6, 50.0)
	settle(Sf, 400)
	ok(evs(Sf, "water_douse").size() == 1, "a fill reaching a scorched line emits one water_douse (the sim keeps no fire; the steam is the renderer's)")
	# --- cost: a step with four fill windows against today's worst (eight flow windows), and nothing when none is open
	var Sc: SimState = world(-1)
	for k in range(4):
		var c0: int = 1000 + k * 300
		Sc.waterWin.append([c0, 120, 0, 0, 1, 0, c0, 0.0, 40.0, c0, 0])
		for i in range(c0 - 6, c0 + 7):
			Sc.deform[i] = -60.0
	Sc.waterTick = 1.0
	var t0: int = Time.get_ticks_usec()
	var reps: int = 50
	for r in range(reps):
		for w in Sc.waterWin:
			w[2] = 0
			w[3] = 0
		Sc.waterTick = 1.0
		WorldWater.step(Sc)
	var fillUs: float = float(Time.get_ticks_usec() - t0) / float(reps)
	var Sg: SimState = world(-1)
	Sg.waterWin.clear()
	for k in range(8):
		Sg.waterWin.append([2000 + k * 600, 240, 0, 0])
	t0 = Time.get_ticks_usec()
	for r in range(reps):
		for w in Sg.waterWin:
			w[2] = 0
			w[3] = 0
		Sg.waterTick = 1.0
		WorldWater.step(Sg)
	var flowUs: float = float(Time.get_ticks_usec() - t0) / float(reps)
	var Sn: SimState = world(-1)
	t0 = Time.get_ticks_usec()
	for r in range(20000):
		WorldWater.step(Sn)
	var idleUs: float = float(Time.get_ticks_usec() - t0) / 20000.0
	print("  (a water step: four fill windows %.0f us, today's worst, eight flow windows, %.0f us; no window open %.2f us a tick)" % [fillUs, flowUs, idleUs])
	ok(fillUs < flowUs and idleUs < 2.0, "the cost: four open fills cost %.0f us a step against today's worst of %.0f, and a tick with nothing open costs %.2f us" % [fillUs, flowUs, idleUs])
	WorldFill.K_ON = false
	print("FILL: %d check(s) failed" % fails)
	quit()
