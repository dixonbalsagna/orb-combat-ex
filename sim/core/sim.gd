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
static func dispose(S: SimState, keepWorld: bool = false) -> void:
	for f in S.fighters:
		f.launchBy = null
		f.rush = null
	S.game.ko = null
	S.game.clash = null
	S.dirS.ex = null
	S.beams.clear()
	if not keepWorld:
		WorldEpoch.release(S)   # World's derived data for this sim (the calm turn's ring jobs and preparations, and the worlds it left) lives in static dictionaries; a restored state keeps its own (NetSnapshot.restore)


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
	var j := beginMatch(S, seed, ai, setup)
	while not j.step():
		pass


## A match's start in pieces (docs/architecture/match-start.md; Performance's phone freeze, 2026-10-26): a host steps one
## piece a frame and draws its loading screen between them. The pieces are newMatch's own work in its own order, cut at
## its seams: the head (with a planet's world, or the first piece of WorldTerrain's); the world (WorldTerrain's GenJob:
## the ground in slices, the smoothing, a settlement a piece, the rest); the fighters; the setups, a few a piece; the
## intro; the mood. newMatch is this job run to its end, so the state is the same however it is stepped. Each piece binds
## the match's statics first (the arena's length, a planet's biome columns, its generation), so another sim stepping
## between two pieces does not change it. A setup refused (SimPlanetLoad.strict, a gen 2 planet not made) is a job done at
## once that touched nothing.
static func beginMatch(S: SimState, seed: int, ai: Dictionary = {}, setup: Dictionary = {}) -> MatchJob:
	var j := MatchJob.new()
	j.S = S
	j.seed = seed
	j.ai = ai
	j.setup = setup
	if SimPlanetLoad.strict and not SimPlanetLoad.mayStart(setup):   # the game's host loads a gen 2 planet first (SimPlanetLoad): never made cold in a match's start
		SimPlanetLoad.refused += 1
		if not FighterData.quiet:
			push_error("SimCore.newMatch: planet %d (gen %d) is not made: load it first (SimPlanetLoad)" % [int(setup.planet), SimPlanetLoad.genOf(setup)])
		j.refused = true
		j.done = true
	return j


class MatchJob extends RefCounted:
	const AFTER_WORLD: int = 8   # the pieces after the world's (for progress)
	var S: SimState
	var seed: int = 0
	var ai: Dictionary = {}
	var setup: Dictionary = {}
	var phase: int = 0
	var gj = null                # World's GenJob, while the world is made
	var planetCols := PackedByteArray()
	var fineCols := PackedByteArray()
	var gen: int = 0
	var pieces: int = 0
	var done: bool = false
	var refused: bool = false

	## One piece; true when the match has started (or was refused).
	func step() -> bool:
		if done:
			return true
		pieces += 1
		if phase > 0:   # the match's statics, as the head set them (another sim may have stepped since)
			SimConst.setArena(S.arenaCols)
			WorldBiomes.planetCols = planetCols
			WorldBiomes.fineCols = fineCols
			WorldClimate.curGen = gen
		match phase:
			0:
				SimCore._mHead(self)
			1:
				if WorldTerrain.genStep(S, gj):
					gj = null
					phase = 2
			2:
				SimCore._mFighters(self)
			3:
				SimCore._mSetupsA(self)
			4:
				SimCore._mSetupsB(self)
			5:
				SimCore._mSetupsC(self)
			6:
				SimIntro.setup(S, setup) # the intro phase, when the setup asks for it
				phase = 7
			7:
				DirData.dataHash()   # the director's data, parsed once a process in a piece of its own (else the first live tick pays it: DirInterrupt.on); it changes no state
				phase = 8
			8:
				SimCore._mEnd(self)
		SimState.sealFresh()   # the world's generation records, sealed piece by piece (snapshots share them)
		planetCols = WorldBiomes.planetCols   # what this match's pieces have set, bound again at the next
		fineCols = WorldBiomes.fineCols
		gen = WorldClimate.curGen
		return done

	## How far the start is, 0 to 1, for a loading screen: the pieces done over an estimate of them all (the head, the
	## ground's slices, the smoothing, a piece a settlement, the lanes, the rest, and the pieces after the world).
	func progress() -> float:
		if done:
			return 1.0
		var est: int = 1 + int(ceil(float(SimConst.PLANET_NC) / float(WorldTerrain.HEIGHT_SLICE))) + 3 + WorldSettle.data().get("settlements", []).size() + AFTER_WORLD
		return clampf(float(pieces) / float(maxi(est, pieces + 1)), 0.0, 0.99)


static func _mHead(J: MatchJob) -> void:
	var S: SimState = J.S
	var setup: Dictionary = J.setup
	if setup.has("aiLevel"):   # the computer's level for this match, the start menu's choice (UI): a level of data/director/ai.json. The file's own level is "" (as a match with no key runs), so a match at it is the same as ever; the replay header names the level by the same rule (SimReplay.dataHash: DirAI.levelOf)
		DirAI.level = DirAI.levelOf(setup)
	S.game.seed = float(J.seed & 0xFFFFFFFF)
	S.rng = SimRng.new(J.seed & 0xFFFFFFFF)
	S.arenaCols = _arenaCols(setup)   # the arena's length in columns (World: a ring of the planet's; needs a planet), else the planet's 4,800
	SimConst.setArena(S.arenaCols)
	WorldBiomes.planetCols = PackedByteArray()
	WorldBiomes.fineCols = PackedByteArray()
	WorldClimate.useGen(0)   # the data's generation unless the setup names one (WorldPlanetWorld.gen)
	S.planetRing = {}   # World: the planet match's ring (planet_world.gd sets it)
	S.epoch = null   # World's calm-moment turn (world/epoch.gd): a planet match with it on sets it
	J.phase = 2
	if not (setup.has("planet") and WorldPlanetWorld.gen(S, setup)):   # a setup with a planet reads its world from the slice; without one, today's world
		J.gj = WorldTerrain.genBegin(S)   # in pieces (WorldTerrain.genStep): genWorld's work in genWorld's order
		J.phase = 1


static func _mFighters(J: MatchJob) -> void:
	var S: SimState = J.S
	var ai: Dictionary = J.ai
	var setup: Dictionary = J.setup
	S.fineCols = WorldBiomes.fineCols
	S.planetGen = WorldClimate.curGen
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
	J.phase = 3


static func _mSetupsA(J: MatchJob) -> void:
	var S: SimState = J.S
	var setup: Dictionary = J.setup
	SimAct.setup(S, setup)   # I2a: each fighter's action state
	S.cata = null   # no catastrophe yet (the tier-5 window sets it up from the stage's ceiling)
	S.depthOn = setup.get("depth", SimDepth.enabled()) == true   # fighters in depth: the data's switch (data/combat/depth.json), or the setup's own for this match
	S.brakeOn = setup.get("brake", SimBrake.enabled()) == true   # the air brake: the data's switch (data/fight/brake.json), or the setup's own for this match
	SimBrake.setup(S)   # each fighter's brake state while the brake is on
	J.phase = 4


static func _mSetupsB(J: MatchJob) -> void:
	var S: SimState = J.S
	var setup: Dictionary = J.setup
	S.formsOn = setup.get("forms", SimForms.enabled()) == true   # forms: the data's switch (data/fight/forms.json), or the setup's own for this match
	SimForms.setup(S)   # each fighter's form state while forms are on, and his own steps when his data has them
	SimBoons.apply(S, setup)   # the run's rare boons (the setup's "boons"): none in versus
	S.flightOn = setup.get("flight", SimFlight.enabled()) == true   # the launch's curve: the data's switch (data/fight/flight.json), or the setup's own
	SimFlight.setup(S)   # each fighter's flight state while the curve is on
	J.phase = 5


static func _mSetupsC(J: MatchJob) -> void:
	var S: SimState = J.S
	var setup: Dictionary = J.setup
	S.hitstopOn = setup.get("hitstop", SimHitstop.enabled()) == true   # hit-stop by weight: the data's switch (data/fight/hitstop.json), or the setup's own
	SimHitstop.setup(S)   # the freeze budget while it is on
	S.ricOn = setup.get("ricochet", SimRicochet.enabled()) == true   # the ricochet's glance: the data's switch (data/fight/ricochet.json), or the setup's own
	WorldTerrain.initRows(S)   # T: the depth rows exist only when depth is on
	SimPause.reset(S)        # Q10: the pause bank
	SimShots.reset(S)        # no shots in flight
	J.phase = 6


static func _mEnd(J: MatchJob) -> void:
	var S: SimState = J.S
	SimMood.reset(S)   # M1: the mood, the act and each fighter's style
	S.out.feed.clear()
	S.out.fx.clear()
	S.tick = 0
	S.dt = 0.0
	S.bindStructures()   # the world's buildings and trees: their per-tick fields into the state's arrays (snapshots share the records)
	J.done = true


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
	var live: bool = _step(S, inputs)
	S.bindCheck()   # a tick that replaced the buildings or the trees (a world's tool) binds them again; the calm turn binds its own
	SimState.sealFresh()   # the generation records this tick made (the calm turn's) are sealed before a snapshot can share them
	return live


static func _step(S: SimState, inputs) -> bool:
	if SimConst.NC != S.arenaCols or WorldBiomes.worldId != S.worldId:   # the arena's length and a planet's biomes are statics: a match takes its own again, whatever another match has built since (two sims alive in one process)
		SimConst.setArena(S.arenaCols)
		WorldBiomes.planetCols = S.planetCols
		WorldBiomes.fineCols = S.fineCols
		WorldClimate.curGen = S.planetGen
		WorldBiomes.worldId = S.worldId
	var dtReal: float = SimConst.DT
	var dt: float = dtReal * S.game.ts
	S.dt = dt
	S.tick += 1
	if SimIntro.tick(S, inputs):   # the intro phase: pre-clock ticks; the sim holds as in a pause, and only a skip press is read
		SimFx.tickMark(S, dt, false)   # ... but effects run at full speed (not a pause's tenth), so the landing's dust and debris settle
		return false
	if SimPause.frozenTick(S):   # Q10: a pausing set piece is a run of frozen ticks, ahead of the hit-stop
		if S.epoch != null:
			WorldEpoch.tick(S, false)   # the calm turn's warm runs under a pause too: no hold, so it only reads
		SimFx.tickMark(S, dt, true)
		return false
	if S.dirS.stop > 0.0:
		S.dirS.stop -= dtReal
		if S.hitstopOn:
			SimHitstop.frozen(S)   # the freeze budget counts every frozen tick of a hit-stop
		if S.epoch != null:
			WorldEpoch.tick(S, false)   # ... and the calm turn's warm, as under a pause
		SimFx.tickMark(S, dt, true)
		return false
	S.T += dt
	if S.epoch != null:
		WorldEpoch.tick(S, DirCalm.hold(S))   # the calm-moment turn: swap when decided, held (Encounter's DirCalm.hold) and calm
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
