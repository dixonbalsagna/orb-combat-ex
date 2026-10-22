class_name SimCore
## The state object and the fixed-step tick: the twin of sim.js (createSim, newMatch, step, toggleAI).
## The GDScript core has one math mode, 'det' (detmath.gd): the JS core's 'native' mode uses V8's Math.sin and friends,
## which no other runtime reproduces, so parity with the prototype stays a JS-only check.


static func createSim(opts: Dictionary = {}) -> SimState:
	var fxRng: String = opts.get("fxRng", "shared")
	if fxRng != "shared":
		push_error("fxRng must be 'shared' (the only mode so far), got " + fxRng)
	var math: String = opts.get("math", "det")
	if math != "det":
		push_error("the GDScript core only has math 'det', got " + math)
	var S := SimState.new()
	S.opts = {"fxRng": fxRng, "math": math}
	S.rng = SimRng.new(7)          # the prototype's stream before its first newMatch
	S.base.resize(SimConst.NC)
	S.deform.resize(SimConst.NC)
	return S


## Break the references between a match's objects so GDScript's reference counting can free them. Fighters can point at
## each other (launchBy, rush.tgt), which is a cycle that JS's garbage collector frees and RefCounted never does.
## newMatch calls this on the outgoing match; a host that drops a sim calls it too.
static func dispose(S: SimState) -> void:
	for f in S.fighters:
		f.launchBy = null
		f.rush = null
	S.game.ko = null
	S.game.clash = null
	S.dirS.ex = null
	S.beams.clear()


## ai is {"p1": bool, "p2": bool}; a missing entry keeps the previous fighter's setting, or true with no fighters yet.
## With more than two slots, "p3" to "p5" say whether those bodies are the AI's; a missing one is false: he stands idle.
## setup (D1a; the replay header's `setup`): {"slots": [id, id]} picks any two fighters the data has, from the roster
## or the bench (default: the roster's first two; slots that are not such fighters play the default, with an error). Up
## to SimRoster.MAX_BODIES slots make a match of one versus many: slot 0 is the one, and slots 2 and up stand beyond the
## second (docs/director/one-v-many.md, stage 1),
## "names": [name, name] renames them (the mirror arms), "flip": true swaps the spawn sides. {} is the default match.
## Fight lanes: "depth": true makes depth physical for this match (S.depthOn).
## The air brake: "brake": true turns it on for this match (S.brakeOn).
## Forms: "forms": true turns on the Protagonist's five steps and the slingshot for this match (S.formsOn).
## The intro phase: "intro": true plays the entrance before the clock; "intro": "skip" (the default) applies its effects at
## once; "intro": false starts flat, as matches did before.
## I2a: "v2": [bool, bool] marks the slots whose intents are v2 (the stance follows the held fields), and "assists":
## [[names], [names]] the Simple layout's assists per slot (SimAct.ASSISTS).
static func newMatch(S: SimState, seed: int, ai: Dictionary = {}, setup: Dictionary = {}) -> void:
	S.game.seed = float(seed & 0xFFFFFFFF)
	S.rng = SimRng.new(seed & 0xFFFFFFFF)
	S.arenaCols = _arenaCols(setup)   # the arena's length in columns (World: a ring of the planet's; needs a planet), else the planet's 4,800
	SimConst.setArena(S.arenaCols)
	WorldBiomes.planetCols = PackedByteArray()
	if not (setup.has("planet") and WorldPlanetWorld.gen(S, setup)):   # a setup with a planet reads its world from the slice; without one, today's world
		WorldTerrain.genWorld(S)
	S.planetCols = WorldBiomes.planetCols   # the statics a world sets belong to this match: step takes them again when another match has built since
	S.worldId = WorldBiomes.claim()
	S.contactOn = WorldContact.enabled()   # World's ground contact (world/contact.gd): a copy of the data's switch
	var p1ai: bool = bool(ai["p1"]) if ai.has("p1") and ai["p1"] != null else (S.fighters[0].ai != null if S.fighters.size() > 0 else true)
	var p2ai: bool = bool(ai["p2"]) if ai.has("p2") and ai["p2"] != null else (S.fighters[1].ai != null if S.fighters.size() > 1 else true)
	dispose(S)
	var slots: Array = setup.get("slots", FighterData.order().slice(0, 2))
	if not SimRoster.slotsOk(slots):
		# slots that are not 2 to MAX_BODIES fighters the data has (the roster's or the bench's): the default pairing plays
		if not FighterData.quiet:
			push_error("SimCore.newMatch: the setup's slots %s are not 2 to %d fighters the data has; the default pairing plays" % [str(slots), SimRoster.MAX_BODIES])
		slots = FighterData.order().slice(0, 2)
	var start_x: float = SimConst.START_X
	if setup.get("start", "") == "crossing":   # a demo start astride a crossing of the city (World: lanes.json demo_start); default off
		start_x = WorldLanes.demoStartX(S, SimConst.START_GAP, SimConst.START_X)
	if setup.has("planet"):
		start_x = float(WorldPlanet.touchCol()) * SimConst.COL - SimConst.START_GAP * 0.5   # astride the touch-down
	var x0: float = start_x
	var x1: float = start_x + SimConst.START_GAP
	var flip: bool = setup.get("flip", false)
	S.fighters = [SimRoster.createFighter(FighterData.def(slots[0]), x1 if flip else x0, "p1", p1ai), SimRoster.createFighter(FighterData.def(slots[1]), x0 if flip else x1, "p2", p2ai)]
	# the bodies past the pair (one versus many): beyond the second, away from the first, facing back at him
	var away: float = -1.0 if flip else 1.0
	for k in range(2, slots.size()):
		var gx: float = SimWrap.wrap(S.fighters[1].x + away * SimRoster.GUARD_SPACING * float(k - 1))
		var key: String = "p%d" % (k + 1)
		S.fighters.append(SimRoster.createFighter(FighterData.def(slots[k]), gx, key, ai.get(key, false) == true))
	if setup.has("names"):
		for k in range(mini(setup.names.size(), S.fighters.size())):
			S.fighters[k].name = setup.names[k]
	for k in range(S.fighters.size()):
		S.fighters[k].y = 60.0
		S.fighters[k].face = (-1.0 if flip else 1.0) if k == 0 else (1.0 if flip else -1.0)
		S.fighters[k].stance = 0.0
	S.beams.clear()
	S.T = 0.0
	S.game.ko = null
	S.game.koT = 0.0
	S.game.ts = 1.0
	S.game.clash = null
	S.dirS.ex = null
	S.dirS.cool = 0.6
	S.dirS.stop = 0.0
	S.dirS.lastLaunch = ""
	S.dirS.lastLaunch2 = ""
	S.dirS.sinceBrunt = 0.0   # B2: the pity counter and the last brunt belong to a match
	S.dirS.lastBrunt = -1.0
	S.dirS.exN = 0
	S.dirS.biomeT = PackedFloat64Array()   # location variety (granted line): the director sizes it on the first tick
	S.dirS.craterT = PackedFloat64Array()   # Encounter's slice (a) (granted line)
	S.dirS.lineSin = 0.0   # D1: the director's line, carry, wait and sidestep belong to a match
	S.dirS.lineSide = 0
	S.dirS.carryZ = 0.0
	S.dirS.homeWait = 0
	S.dirS.sideT = 0
	S.dirS.sideWay = 0
	SimAct.setup(S, setup)   # I2a: each fighter's action state
	S.cata = null   # no catastrophe yet (the tier-5 window sets it up from the stage's ceiling)
	S.depthOn = setup.get("depth", SimDepth.enabled()) == true   # fighters in depth: the data's switch (data/combat/depth.json), or the setup's own for this match
	S.brakeOn = setup.get("brake", SimBrake.enabled()) == true   # the air brake: the data's switch (data/fight/brake.json), or the setup's own for this match
	SimBrake.setup(S)   # each fighter's brake state while the brake is on
	S.formsOn = setup.get("forms", SimForms.enabled()) == true   # forms: the data's switch (data/fight/forms.json), or the setup's own for this match
	SimForms.setup(S)   # each fighter's form state while forms are on, and his own steps when his data has them
	S.flightOn = setup.get("flight", SimFlight.enabled()) == true   # the launch's curve: the data's switch (data/fight/flight.json), or the setup's own
	SimFlight.setup(S)   # each fighter's flight state while the curve is on
	S.hitstopOn = setup.get("hitstop", SimHitstop.enabled()) == true   # hit-stop by weight: the data's switch (data/fight/hitstop.json), or the setup's own
	SimHitstop.setup(S)   # the freeze budget while it is on
	WorldTerrain.initRows(S)   # T: the depth rows exist only when depth is on
	SimPause.reset(S)        # Q10: the pause bank
	SimShots.reset(S)        # no shots in flight
	SimIntro.setup(S, setup) # the intro phase, when the setup asks for it
	SimMood.reset(S)   # M1: the mood, the act and each fighter's style
	S.out.feed.clear()
	S.out.fx.clear()
	S.tick = 0
	S.dt = 0.0


## The arena's columns from the setup, guarded: setup.arena {"cols": n, "side": 1 or -1} with a setup.planet, n a whole number from 600 to 4,800 and a multiple of 8 (the ground's largest stride: Rendering's chunks and copies; a ring a fight fits in); anything else is the planet's own 4,800, with an error (World: docs/world/shifting-arena-design.md section 3).
static func _arenaCols(setup: Dictionary) -> int:
	var arena = setup.get("arena", null)
	if arena == null:
		return SimConst.PLANET_NC
	var n = arena.get("cols", null) if arena is Dictionary else null
	var ok: bool = setup.has("planet") and (n is int or n is float) and float(n) == floorf(float(n)) and float(n) >= 600.0 and float(n) <= float(SimConst.PLANET_NC) and int(n) % 8 == 0
	if not ok:
		if not FighterData.quiet:
			push_error("SimCore.newMatch: setup.arena %s needs a planet and cols a whole number from 600 to %d, a multiple of 8; the planet's own arena plays" % [str(arena), SimConst.PLANET_NC])
		return SimConst.PLANET_NC
	return int(n)


## One fixed step (sim.js step). inputs is [intent or null, ...] a slot, or null (AI fighters ignore it; a slot past the
## list's end has none). Returns
## false during hit-stop (no input consumed; the host keeps its key presses for the next tick), true otherwise.
static func step(S: SimState, inputs = null) -> bool:
	if SimConst.NC != S.arenaCols or WorldBiomes.worldId != S.worldId:   # the arena's length and a planet's biomes are statics: a match takes its own again, whatever another match has built since (two sims alive in one process)
		SimConst.setArena(S.arenaCols)
		WorldBiomes.planetCols = S.planetCols
		WorldBiomes.worldId = S.worldId
	var dtReal: float = SimConst.DT
	var dt: float = dtReal * S.game.ts
	S.dt = dt
	S.tick += 1
	if SimIntro.tick(S, inputs):   # the intro phase: pre-clock ticks; the sim holds as in a pause, and only a skip press is read
		SimFx.tickMark(S, dt, false)   # ... but effects run at full speed (not a pause's tenth), so the landing's dust and debris settle
		return false
	if SimPause.frozenTick(S):   # Q10: a pausing set piece is a run of frozen ticks, ahead of the hit-stop
		SimFx.tickMark(S, dt, true)
		return false
	if S.dirS.stop > 0.0:
		S.dirS.stop -= dtReal
		if S.hitstopOn:
			SimHitstop.frozen(S)   # the freeze budget counts every frozen tick of a hit-stop
		SimFx.tickMark(S, dt, true)
		return false
	S.T += dt
	if S.hitstopOn:
		SimHitstop.live(S)   # ... over the last minute of fight
	SimPause.liveTick(S)   # Q10: the pause bank accrues on match time
	if S.game.ko != null:
		S.game.koT += dt
		if S.game.koT > 2.2:
			S.game.ts = 1.0
	var ord: Array = [0, 1] if S.rng.next() < 0.5 else [1, 0]
	for k in range(2, S.fighters.size()):   # the bodies past the pair, after it, in slot order: one draw a tick, as with two
		ord.append(k)
	for k in ord:
		SimControl.control(S, S.fighters[k], inputs[k] if inputs != null and k < inputs.size() else null)
	for f in S.fighters:
		SimFighter.stepFighter(S, f, dt)
	DirExchange.dirUpdate(S, dt)
	DirBeam.beamStep(S, dt)
	SimShots.step(S, dt)   # energy blasts in flight: they move, trade, and meet fighters and the ground
	WorldWater.step(S)
	SimMood.tick(S)   # M1: reads this tick's events; writes only its own state and events
	if S.cata != null and S.cata.ashLeft > 0:
		SimCata.tick(S)   # the catastrophe's ash rises (a blast cloud started it)
	if S.formsOn:
		SimForms.events(S)   # forms: the Trial fill reads this tick's events (the opponent's forms, his blows, the opponent's commitments)
	WorldCollateral.tick(S)
	SimFx.tickMark(S, dt, false)
	if S.game.clash != null:
		var c = S.game.clash
		var p: float = SimMathx.jclamp((S.T - c.t0) / c.dur, 0.0, 1.0)
		var mid: float = c.mid if c.mid >= 0.0 else 0.5 + (1.0 if c.aw else -1.0) * 0.35 * p   # a struggle's meeting point, else the old clash's glide
		var ax: float = c.A.x
		var dx: float = SimWrap.sdx(ax, c.D.x)
		var sx: float = SimWrap.wrap(ax + dx * mid)
		var sz: float = c.A.z + (c.D.z - c.A.z) * mid
		SimFx.spark(S, sx, (c.A.y + (c.D.y - c.A.y) * mid) + 38.0, 3, "#ffffff", 700.0, sz)
		SimFx.shake(S, 7.0, sx, sz)
	return true


static func toggleAI(S: SimState, idx: int) -> void:
	var f = S.fighters[idx]
	f.ai = null if f.ai != null else SimState.AiState.new()
