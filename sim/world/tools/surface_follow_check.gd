extends SceneTree
# The contact surface on a field world follows the line (World, sim/world/contact.gd _fcol; docs/world/pending/contact-surf-derive): the surface class and the gen 2/3 ground numbers of a column are read through the
# frame, memoised on SimField's serial, so a swing changes them, a recomputed read gives the same, and no process-wide table is read. On any other world the table is built at match build.
#   godot --headless --path . --script res://sim/world/tools/surface_follow_check.gd
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _codes(S: SimState) -> PackedInt32Array:
	var a := PackedInt32Array()
	a.resize(SimConst.NC)
	for c in range(SimConst.NC):
		a[c] = int(WorldContact._fcol(S, c)[0])
	return a


func _init() -> void:
	for planet in [7, 12]:
		WorldClimate.useGen(3)
		var S := SimCore.createSim()
		SimCore.newMatch(S, 77, {"p1": false, "p2": false}, {"planet": planet, "touch": 1, "planetGen": 3, "intro": false})
		SimCore.step(S)
		ok(S.frame != null, "planet %d is a field world" % planet)
		var before := _codes(S)
		# a place's ground (village and city, the paved biomes) comes from the platform records, as the first ring's chords stamp it
		var town_pc: int = 0
		var both: int = 0
		var extra: int = 0
		for c in range(SimConst.NC):
			var in_pc: bool = WorldBiomes.planetCols[c] >= 7
			var in_f: bool = WorldContact._townAt(S, c) > 0
			if in_pc:
				town_pc += 1
				if in_f:
					both += 1
			elif in_f:
				extra += 1
		ok(town_pc > 0 and both * 10 >= town_pc * 9, "planet %d: the platforms give %d of the %d columns the first ring's chords stamp as a place's ground (%d more)" % [planet, both, town_pc, extra])
		var f = S.fighters[0]
		SimSwing.ask(S, {"deg": 40.0, "cause": "launch", "pivotX": SimWrap.wrap(f.x + 9000.0)})
		var n: int = 0
		while S.swing.active and n < 600:
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
			n += 1
		var after := _codes(S)
		WorldContact._fm.clear()
		WorldContact._fserial = -1
		var again := _codes(S)
		var moved: int = 0
		var impure: int = 0
		for c in range(SimConst.NC):
			if before[c] != after[c]:
				moved += 1
			if after[c] != again[c]:
				impure += 1
		ok(moved > 0, "planet %d: a 40 degree swing changes the surface class of %d of %d columns" % [planet, moved, SimConst.NC])
		ok(impure == 0, "planet %d: a recomputed read gives the same classes (%d differ)" % [planet, impure])
		var x: float = f.x
		ok(WorldContact.surfaceAt(S, x) == WorldContact.SURF_NAMES[int(WorldContact._fcol(S, WorldContact._colOf(x))[0]) & 3] or WorldContact.surfaceAt(S, x) in ["rubble", "paving", "glaze", "ember", "crust"], "surfaceAt reads the same column through the frame")
		SimCore.dispose(S)
	# a world with no frame: the table is built at match build, from its own columns
	WorldClimate.useGen(2)
	var H := SimCore.createSim()
	SimCore.newMatch(H, 5, {}, {"intro": false})
	ok(H.frame == null and WorldContact._colSurfKey == WorldBiomes.worldId, "a world with no frame has its table built at match build")
	SimCore.dispose(H)
	print("SURFFOLLOW: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
