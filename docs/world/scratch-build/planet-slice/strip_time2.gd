extends SceneTree
const Lib = preload("res://sim/world/tools/planet2_lib.gd")
func run(P, u: Vector3, v: Vector3, label: String) -> void:
	var best: float = 1.0e9
	for rep in range(3):
		var t0: int = Time.get_ticks_usec()
		var hs := PackedFloat32Array()
		hs.resize(4800)
		for i in range(4800):
			var p: Vector3 = P.rot(u, v, float(i) * 32.0 / P.R)
			var sf: Array = P.surf(p)
			hs[i] = sf[0] + (P.fbm(p, 1500.0, 3, P.seed + 777) - 0.5) * 300.0
			P.biome(p, sf[0])
		best = minf(best, float(Time.get_ticks_usec() - t0) / 1000.0)
	print("%s: 4800 columns, best of 3: %.0f ms" % [label, best])
func _init() -> void:
	var P = Lib.new()
	run(P, Vector3(1, 0, 0), Vector3(0, 0, 1), "equator (no ice)")
	run(P, Vector3(1, 0, 0), Vector3(0, 1, 0), "through both poles")
	quit()
