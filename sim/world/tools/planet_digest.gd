extends SceneTree
# A fingerprint of what a planet is: its places, its climate grid, its flow field and the slice of a touch-down's ring, for planets of both generations (rivers on for gen 2's second line). Compare the lines before
# and after a change to the generation: they must be identical, line for line.
#   godot --headless --path . --script res://sim/world/tools/planet_digest.gd
func fnv(b: PackedByteArray) -> int:
	var h: int = 2166136261
	for x in b:
		h = ((h ^ x) * 16777619) & 0xFFFFFFFF
	return h


func digest(seed: int, gen: int, rivers: bool) -> String:
	WorldClimate.useGen(gen)
	WorldRivers.setOn(rivers)
	WorldPlanet.forget()
	var P := WorldPlanet.make(seed)
	var pb := PackedByteArray()
	pb.append_array(P.kind)
	pb.append_array(P.px.to_byte_array())
	pb.append_array(P.py.to_byte_array())
	pb.append_array(P.pz.to_byte_array())
	pb.append_array(P.rad.to_byte_array())
	var s: String = "gen %d seed %d rivers %s: %d places %d" % [gen, seed, str(rivers), P.n, fnv(pb)]
	if gen >= 2:
		s += " grid %d" % fnv(P.grid.adv.to_byte_array())
		s += " ht %d" % fnv(P.grid.ht.to_byte_array())
		if rivers:
			var F: WorldRivers.Flow = WorldRivers.flowOf(P)
			var fb := PackedByteArray()
			fb.append_array(F.recv.to_byte_array())
			fb.append_array(F.flow.to_byte_array())
			fb.append_array(F.order.to_byte_array())
			s += " flow %d" % fnv(fb)
	SimConst.setArena(2400)
	for touch in [1, 2]:
		var sl: WorldPlanet.Slice = WorldPlanet.sliceFor(seed, touch)
		if sl == null:
			s += " slice%d null" % touch
		else:
			var sb := PackedByteArray()
			sb.append_array(sl.heights.to_byte_array())
			sb.append_array(sl.biomes)
			sb.append_array(sl.fine)
			s += " slice%d %d held %d" % [touch, fnv(sb), sl.held.size()]
	return s


func _init() -> void:
	for seed in [7, 13]:
		print(digest(seed, 1, false))
		print(digest(seed, 2, false))
		print(digest(seed, 2, true))
	WorldRivers.setOn(false)
	quit()
