extends SceneTree
const Lib = preload("res://sim/world/tools/planet_lib.gd")
func _init() -> void:
	var P = Lib.new()
	var u := Vector3(0.3, 0.5, 0.2).normalized()
	var n := Vector3(0.1, -0.4, 0.9).normalized()
	var v: Vector3 = n.cross(u).normalized()
	var best: float = 1.0e9
	for rep in range(5):
		var t0: int = Time.get_ticks_usec()
		var hs := PackedFloat32Array()
		hs.resize(4800)
		for i in range(4800):
			var p: Vector3 = P.rot(u, v, float(i) * 32.0 / P.R)
			var h: float = P.elev(p) + (P.fbm(p, 1500.0, 3, P.seed + 777) - 0.5) * 300.0
			hs[i] = h
			P.biome(p, h)
		best = minf(best, float(Time.get_ticks_usec() - t0) / 1000.0)
	print("strip 4800 columns (height + detail + biome), best of 5: %.0f ms" % best)
	quit()
