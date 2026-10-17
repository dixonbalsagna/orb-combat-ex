extends SceneTree
# A story planet's stored places: the list equals what the generator makes, bit for bit; a load needs no placement.
#   godot --headless --path . --script res://sim/world/tools/planet_store_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func hexd(x: float) -> String:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_double(0, x)
	return b.hex_encode()


func key(P: WorldPlanet.Planet) -> String:
	var s: String = "%d:" % P.n
	for i in range(P.n):
		s += "%s%s%s%d%s%d;" % [hexd(P.px[i]), hexd(P.py[i]), hexd(P.pz[i]), P.kind[i], hexd(P.rad[i]), P.people[i]]
	return s


func _init() -> void:
	ok(WorldPlanet.dataErrors().is_empty(), "planet.json loads clean with its story entry (%s)" % str(WorldPlanet.dataErrors()))
	var st: Dictionary = WorldPlanet.storyFor(7)
	ok(not st.is_empty() and st.name == "Everhold" and st.places.size() == 42, "the story section holds Everhold: seed 7, %d places" % st.places.size())
	ok(WorldPlanet.storyFor(11).is_empty() and WorldPlanet.storyFor(1).is_empty(), "other seeds have no story entry: they are generated")
	WorldPlanet.forget()
	var stored: WorldPlanet.Planet = WorldPlanet.make(7)
	var gen: WorldPlanet.Planet = WorldPlanet.makeGenerated(7)
	ok(key(stored) == key(gen) and stored.n == 42, "the stored places equal the generated ones bit for bit (positions, kinds, radii, people): %d places" % stored.n)
	# the cost: a load of the stored planet against the generator
	WorldPlanet.forget()
	var t0: int = Time.get_ticks_usec()
	WorldPlanet.make(7)
	var tStored: int = Time.get_ticks_usec() - t0
	t0 = Time.get_ticks_usec()
	WorldPlanet.makeGenerated(7)
	var tGen: int = Time.get_ticks_usec() - t0
	print("        stored load %.2f ms, generated %.0f ms" % [tStored / 1000.0, tGen / 1000.0])
	ok(tStored * 20 < tGen, "a stored planet loads at least 20 times faster than a generated one")
	# the slices of the stored planet are the generated planet's slices
	WorldPlanet.forget()
	var Ps: WorldPlanet.Planet = WorldPlanet.make(7)
	var rs: Dictionary = WorldPlanet.pick(Ps, 3)
	var sliceS: WorldPlanet.Slice = WorldPlanet.readSlice(Ps, rs.circle, rs.T)
	var rg: Dictionary = WorldPlanet.pick(gen, 3)
	var sliceG: WorldPlanet.Slice = WorldPlanet.readSlice(gen, rg.circle, rg.T)
	ok(WorldPlanet.sliceHash(sliceS) == WorldPlanet.sliceHash(sliceG) and rs.index == rg.index, "a slice of the stored planet is the generated planet's slice (hash %08x)" % WorldPlanet.sliceHash(sliceS))
	print("PLANETSTORE: %d check(s) failed" % fails)
	quit()
