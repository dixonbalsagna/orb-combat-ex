extends SceneTree
# A digest of what the planet's read returns, to the last bit of the float64 (window 20: a faster read must be this same read): surfAt at 24,000 seeded points of the sphere and along rings, per planet and generation,
# as FNV-1a over the bytes of the heights (float64), the biomes and the fine biomes. Compare before and after a change to the noise or to a landform: every line must be identical.
#   godot --headless --path . --script res://sim/world/tools/read_digest.gd [-- --gens=1,2 --seeds=7,3,11,25]
func fnv(h: int, bytes: PackedByteArray) -> int:
	for i in range(bytes.size()):
		h = SimRng.imul((h ^ bytes[i]) & 0xFFFFFFFF, 0x01000193)
	return h


func _init() -> void:
	var gens: Array = [1, 2]
	var seeds: Array = [7, 3, 11, 25]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--gens="):
			gens = Array(a.substr(7).split(",")).map(func(v): return int(v))
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(v): return int(v))
	for gen in gens:
		WorldClimate.useGen(gen)
		for sd in seeds:
			var P := WorldPlanet.make(sd)
			var r := SimRng.new(4242 + sd)
			var hh := PackedFloat64Array()
			var bb := PackedByteArray()
			var ff := PackedByteArray()
			for k in range(24000):
				var q: Array
				if k < 12000:
					q = WorldPlanet._randUnit(r)
				else:   # a ring's columns in order, a few rings: what a ring read feeds the noise
					var cols: int = 1200
					var ringNo: int = (k - 12000) / cols
					var T: Array = WorldPlanet.unitFromDraws(0.11 + 0.07 * float(ringNo), 0.5 + 0.03 * float(ringNo))
					var spec: Dictionary = WorldRingPick.roundSpec(T, cols, 0.4 + float(ringNo))
					var ring: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
					var ang: float = float((k - 12000) % cols) * SimConst.COL / (P.R * float(ring.st))
					q = WorldRingPick.ringPoint(ring, ang)
				WorldPlanet.surfAt(P, q[0], q[1], q[2])
				hh.append(P.outH)
				bb.append(P.outB)
				ff.append(P.outF + 1)
			var h: int = 0x811c9dc5
			h = fnv(h, hh.to_byte_array())
			h = fnv(h, bb)
			h = fnv(h, ff)
			print("g%d seed %d: digest %d over %d points" % [gen, sd, h, hh.size()])
	quit()
