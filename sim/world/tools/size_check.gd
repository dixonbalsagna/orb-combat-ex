extends SceneTree
# The planet sizes (World, A1; sim/world/size.gd, data/biomes/sizes.json; docs/world/planet-sizes.md). From the repo root:
#   godot --headless --path . --script res://sim/world/tools/size_check.gd -- [--negative-control]
# Proves, for each of the five sizes (tiny, small, medium, big, huge; the held ones through WorldPlanetSize.heldOverride) on planet 7: the match is bound to the size (the planet's columns, the arena, the radius), plays on a field world (a frame, fighters on finite
# ground, the arena wrapping at the planet's round), and plays 600 ticks; the same setup twice has the same match hash; medium named is byte for byte medium unnamed; a size nobody offers is refused to medium; a
# crater dug at one place on the biggest planet is not read at the place half way round (the store's grid does not alias across a big planet); and the data's own rules hold (a size's columns, its ring, its bake).
# Prints each size's start time and tick cost: those are void as measurements on a shared machine (Performance reads them in a quiet window). --negative-control makes the grid's key offset the medium's 64 on a big
# planet: the aliasing check must then fail.
var fails: int = 0
var negative: bool = false


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func _setup(nm: String, planet: int = 7, touch: int = 1) -> Dictionary:
	return {"intro": false, "planet": planet, "touch": touch, "planetGen": 3, "planetSize": nm}


func _match(setup: Dictionary, ticks: int) -> SimState:
	WorldClimate.useGen(3)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, setup)
	for t in range(ticks):
		SimCore.step(S)
	return S


## A path that is not a game file: a tool or a test may set WorldPlanetSize.heldOverride, nothing else may.
func _outside(p: String) -> bool:
	return not p.contains("/tools/") and not p.contains("/tests/") and not p.ends_with("sim/world/size.gd")


func _scan(dir: String, hits: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var n: String = d.get_next()
	while n != "":
		if d.current_is_dir():
			if not n.begins_with(".") and not (dir == "res://" and ["docs", "homework", "prototype", "research", "art", "audit", "localization", "data"].has(n)):
				_scan(dir.path_join(n), hits)
		elif n.ends_with(".gd"):
			var p: String = dir.path_join(n)
			if _outside(p) and FileAccess.get_file_as_string(p).contains("heldOverride"):
				hits.append(p)
		n = d.get_next()


## The held sizes (tiny, small, huge and colossal as the data ships: offered false) are not reachable, and un-hiding one moves nothing else. Runs first, before any row sets heldOverride.
func _held_rows() -> void:
	print("held sizes are unreachable")
	var quiet0: bool = FighterData.quiet
	FighterData.quiet = true   # nameOf's error is the point of these rows: it is counted (heldHits), not printed
	var held: Array = ["tiny", "small", "big", "huge", "colossal"]
	var hits0: int = WorldPlanetSize.heldHits
	var allMedium: bool = true
	for nm in held:
		if WorldPlanetSize.nameOf(_setup(nm)) != "medium" or WorldPlanetSize.colsOf(_setup(nm)) != 4800 or not WorldPlanetSize.isHeld(_setup(nm)):
			allMedium = false
	ok(allMedium and WorldPlanetSize.heldHits == hits0 + 10, "as shipped, a setup naming tiny, small, big, huge or colossal plays medium (4,800 columns), and each of the %d asks was refused with an error (counted: %d)" % [10, WorldPlanetSize.heldHits - hits0])
	var Sh1 := _match(_setup("small"), 120)
	var Sm1 := _match(_setup("medium"), 120)
	ok(Sh1.planetNC == 4800 and SimHash.stateHash(Sh1).gameplay == SimHash.stateHash(Sm1).gameplay, "a match that names small, as shipped, is the medium match byte for byte (planetNC %d, hash at tick 120)" % Sh1.planetNC)
	SimCore.dispose(Sh1)
	SimCore.dispose(Sm1)
	ok(not WorldPlanetSize.isHeld(_setup("medium")) and WorldPlanetSize.isHeld(_setup("big")) and not WorldPlanetSize.isHeld({"planet": 7}) and not WorldPlanetSize.isHeld({"planetSize": "small"}), "medium, a setup that names no size and a setup with no planet are not held, and big is")
	print("a replay that names a held size")
	WorldPlanetSize.heldOverride = true   # the way in, for the recording only
	var su: Dictionary = _setup("small")
	var Sr := _match(su, 60)
	var h60: String = str(SimHash.stateHash(Sr).gameplay)
	for t in range(60):
		SimCore.step(Sr)
	var h120: String = str(SimHash.stateHash(Sr).gameplay)
	SimCore.dispose(Sr)
	var rp: Dictionary = SimReplay.header(5, su, {"p1": false, "p2": false}, 120)
	rp.checkpoints = [[60, h60]]
	rp.final = h120
	var opened: Dictionary = SimReplay.play(rp)
	ok(bool(opened.ok), "control: with the way in open the replay of 120 ticks at small plays back faithfully (so a failure below is the hold's)")
	WorldPlanetSize.heldOverride = false
	var hits1: int = WorldPlanetSize.heldHits
	var res: Dictionary = SimReplay.play(rp)
	ok(WorldPlanetSize.heldHits > hits1 and not bool(res.ok) and ["checkpoint", "final", "data"].has(String(res.reason)), "as shipped, the same replay is NOT a quiet success: the error is raised (held asks +%d) and SimReplay.play fails it (reason %s, first bad tick %d)" % [WorldPlanetSize.heldHits - hits1, str(res.reason), int(res.firstBadTick)])
	print("  note: SimReplay.refusal(header only) for that replay (made at small with the way in open, checked as shipped): '%s'" % SimReplay.refusal(rp))
	WorldPlanetSize.heldOverride = true
	var rp3: Dictionary = SimReplay.header(5, su, {"p1": false, "p2": false}, 30)   # an unfinished one: under a second, no checkpoint, no final hash, made at small
	WorldPlanetSize.heldOverride = false
	var res3: Dictionary = SimReplay.play(rp3)
	print("  note: the same, 30 ticks with no checkpoint and no final hash: SimReplay.play ok %s, reason '%s' (with ok true only the error says so; refusing a held size at the header is WorldPlanetSize.isHeld(setup), a later item for UI and Simulation)" % [str(res3.ok), str(res3.reason)])
	var rp2: Dictionary = SimReplay.header(5, su, {"p1": false, "p2": false}, 30)   # made while small is held: the match that ran was medium
	var res2: Dictionary = SimReplay.play(rp2)
	print("  note: a replay made while small is held records the match that ran (medium): SimReplay.play ok %s (faithful to what ran; the error is raised)" % str(res2.ok))
	print("nothing draws a size")
	var mode0: String = WorldDefault.mode()
	var rnd0: bool = WorldDefault.K_RANDOM
	WorldDefault.setForTest("planet", true)   # the quick match's draw, on
	var named: int = 0
	var planets: Dictionary = {}
	for sd in range(2000):
		var pp: Dictionary = WorldDefault.part(sd, false)
		var ap: Dictionary = WorldDefault.apply({}, sd, false)
		planets[int(pp.get("planet", -1))] = true
		if pp.has("planetSize") or ap.has("planetSize"):
			named += 1
	WorldDefault.setForTest(mode0, rnd0)
	ok(named == 0 and planets.size() > 3, "the quick match's draw (WorldDefault.part and apply, 2,000 seeds, %d different planets) never names a size: a match with no size is medium" % planets.size())
	ok(_outside("res://render/core/main.gd") and _outside("res://ui/hud/ui_hud.gd") and not _outside("res://sim/world/tools/size_check.gd") and not _outside("res://render/camera/tests/split_sweep.gd") and not _outside("res://sim/world/size.gd"), "control: the scan's rule calls a game file outside and a tool, a test or size.gd itself not")
	var hits: Array = []
	for top in ["sim", "render", "ui", "net", "audio", "qa", "tools"]:
		_scan("res://" + top, hits)
	ok(hits.is_empty(), "nothing outside a tools or tests folder sets WorldPlanetSize.heldOverride (%s)" % str(hits))
	print("un-hiding a size moves nothing else")
	var Mh0 := _match(_setup("medium"), 120)
	var hm0: String = str(SimHash.stateHash(Mh0).gameplay)
	SimCore.dispose(Mh0)
	var tbl0: String = JSON.stringify(WorldPlanetSize.hashData())
	var raw0: String = JSON.stringify(WorldPlanetSize.data())
	var dh0: String = SimReplay.dataHash(_setup("medium"))
	var dhm0: String = SimReplay.dataHash({"intro": false, "planet": 7, "touch": 1, "planetGen": 3})
	for nm in ["tiny", "small", "big", "huge"]:
		WorldPlanetSize.data().sizes[nm].offered = true
	var flipped: bool = WorldPlanetSize.names(true).size() == 5 and WorldPlanetSize.nameOf(_setup("small")) == "small" and WorldPlanetSize.colsOf(_setup("small")) == 2560 and WorldPlanetSize.nameOf(_setup("big")) == "big" and WorldPlanetSize.colsOf(_setup("big")) == 9600 and not WorldPlanetSize.isHeld(_setup("small")) and not WorldPlanetSize.isHeld(_setup("big"))
	var Mh1 := _match(_setup("medium"), 120)
	var hm1: String = str(SimHash.stateHash(Mh1).gameplay)
	SimCore.dispose(Mh1)
	ok(flipped, "flipping tiny, small, big and huge to offered in memory (the one data edit each) makes small play as small (2,560 columns) and big as big (9,600) without the way in, and the menu's list five")
	ok(hm1 == hm0 and JSON.stringify(WorldPlanetSize.hashData()) == tbl0 and SimReplay.dataHash(_setup("medium")) == dh0 and SimReplay.dataHash({"intro": false, "planet": 7, "touch": 1, "planetGen": 3}) == dhm0, "the flip moves no hash: a medium match's state hash at tick 120, the size table as a data hash reads it (hashData), and the replay data hash of a setup naming medium and of a setup naming no size are unchanged")
	ok(JSON.stringify(WorldPlanetSize.data()) != raw0, "control: the raw table does differ after the flip (so hashData, which leaves offered out, is what keeps the hash still)")
	for nm in ["tiny", "small", "big", "huge"]:
		WorldPlanetSize.data().sizes[nm].offered = false
	FighterData.quiet = quiet0


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	print("data")
	ok(WorldPlanetSize.dataErrors().is_empty(), "sizes.json loads clean (%s)" % str(WorldPlanetSize.dataErrors()))
	var offered: Array = WorldPlanetSize.names(true)
	var all5: Array = ["tiny", "small", "medium", "big", "huge"]
	ok(offered == ["medium"], "as shipped, only medium is offered; tiny, small, big, huge and colossal are held (%s)" % str(offered))
	ok(WorldPlanetSize.names().size() == 6 and WorldPlanetSize.names().slice(0, 5) == all5 and WorldPlanetSize.names()[5] == "colossal", "the data has the five sizes smallest first, and the sixth, colossal, which is data that is off")
	ok(WorldPlanetSize.colsOf({"planet": 7, "planetSize": "medium"}) == 4800 and WorldPlanetSize.colsOf({"planet": 7}) == 4800 and WorldPlanetSize.colsOf({"planetSize": "huge"}) == 4800, "medium is 4,800; no size, or no planet to size, is medium")
	_held_rows()
	WorldPlanetSize.heldOverride = true   # from here the check plays every size the data has but colossal (the held ones too: the way in is the tests')
	print("every size the data has but colossal plays")
	var hashes: Dictionary = {}
	for nm in all5:
		var cols: int = WorldPlanetSize.colsOf({"planet": 7, "planetSize": nm})
		var t0: int = Time.get_ticks_usec()
		var S := _match(_setup(nm), 600)
		var secs: float = float(Time.get_ticks_usec() - t0) / 1.0e6
		var f0 = S.fighters[0]
		var f1 = S.fighters[1]
		var R: float = float(cols) * SimConst.COL / (2.0 * SimMathx.PI)
		var bound: bool = S.planetNC == cols and SimConst.PLANET_NC == cols and S.arenaCols == cols and SimConst.NC == cols and absf(SimField.R - R) < 1.0e-6
		var fine: bool = S.tick >= 600 and S.frame != null and is_finite(f0.x) and is_finite(f0.y) and is_finite(f1.x) and is_finite(f1.y) and f0.x >= 0.0 and f0.x < SimConst.W and f0.y > -400.0 and f0.y < 30000.0
		ok(bound, "%s: the match is bound to %d columns round, an arena of the same, a radius of %.0f" % [nm, cols, R])
		ok(fine, "%s: a field world, fighters on finite ground, 600 ticks played (start and 600 ticks %.1f s, shared machine: void as a measurement)" % [nm, secs])
		hashes[nm] = SimHash.stateHash(S).gameplay
		SimCore.dispose(S)
	print("the same setup twice")
	for nm in ["tiny", "big"]:
		var S2 := _match(_setup(nm), 600)
		ok(SimHash.stateHash(S2).gameplay == hashes[nm], "%s: the same setup plays the same match (hash at tick 600)" % nm)
		SimCore.dispose(S2)
	print("medium")
	var Sm := _match({"intro": false, "planet": 7, "touch": 1, "planetGen": 3}, 120)
	var Sn := _match(_setup("medium"), 120)
	ok(SimHash.stateHash(Sm).gameplay == SimHash.stateHash(Sn).gameplay, "medium named plays byte for byte the match medium unnamed plays (hash at tick 120)")
	SimCore.dispose(Sm)
	SimCore.dispose(Sn)
	var Sx := _match(_setup("enormous"), 30)
	ok(Sx.planetNC == 4800, "a size the data does not have plays medium")
	SimCore.dispose(Sx)
	print("the host's loader (strict) makes a planet at its size")
	SimConst.setPlanet(SimConst.PLANET_NC_MEDIUM)
	SimPlanetLoad.strict = true
	var su: Dictionary = _setup("big", 12, 2)
	WorldPlanet.forget()
	ok(not SimPlanetLoad.mayStart(su) and SimConst.PLANET_NC == 4800, "a big planet that is not made is not ready, and asking leaves the host's static (4,800) as it was")
	var job = SimPlanetLoad.beginFor(su)
	ok(job != null and SimConst.PLANET_NC == 4800, "beginning its load leaves the static as it was")
	job.finishNow()
	ok(job.done and SimConst.PLANET_NC == 4800 and SimPlanetLoad.mayStart(su), "the load, run to its end at the planet's own size, makes it ready (and the static is still 4,800)")
	var Sl := SimCore.createSim()
	SimCore.newMatch(Sl, 5, {"p1": false, "p2": false}, su)
	ok(SimPlanetLoad.refused == 0 and Sl.planetNC == 9600 and Sl.frame != null, "a strict match on it starts (planetNC %d, a frame, none refused)" % Sl.planetNC)
	SimCore.dispose(Sl)
	SimPlanetLoad.strict = false
	print("a big planet's store")
	var Sh := _match(_setup("huge"), 5)
	if negative:
		WorldStore._koff = 64
		WorldStore._koffNC = SimConst.PLANET_NC
	var f = Sh.fighters[0]
	var xa: float = SimWrap.wrap(f.x + 900.0)
	var xb: float = SimWrap.wrap(xa + SimConst.W * 0.5)   # half way round the planet's great circle
	var ra = WorldCrater.dig(Sh, xa, 8.0, f, "impact")
	var rb = WorldCrater.dig(Sh, xb, 8.0, f, "impact")
	ok(ra != null and rb != null and Sh.storeN == 2, "a crater dug here and one half way round the huge planet are two records")
	if Sh.storeN == 2:
		var qa: Array = WorldStore.centreOf(Sh, 0)
		var qb: Array = WorldStore.centreOf(Sh, 1)
		ok(WorldStore.at(Sh, qa[0], qa[1], qa[2]).size() == 1 and WorldStore.at(Sh, qb[0], qb[1], qb[2]).size() == 1, "each place's box lists its own record only (no aliasing across the planet)")
		ok(absf(WorldStore.heightDelta(Sh, qa[0], qa[1], qa[2]) + ra.depth) < 1.0e-6 and absf(WorldStore.heightDelta(Sh, qb[0], qb[1], qb[2]) + rb.depth) < 1.0e-6, "each centre reads its own bowl's depth")
	# the keys of two boxes the huge planet has, (0, 33, 0) and (1, -95, 0): with the medium's offset of 64 they are the same key (a record in one would be read at the other)
	ok(WorldStore._key(0, 33, 0) != WorldStore._key(1, -95, 0) and WorldStore._key(95, -95, 95) != WorldStore._key(-95, 95, -95), "two boxes of the huge planet that a 64 offset would give one key have two (offset %d)" % WorldStore._koff)
	SimCore.dispose(Sh)
	print("SIZES: %d check(s) failed%s" % [fails, " (negative control)" if negative else ""])
	quit(0)
