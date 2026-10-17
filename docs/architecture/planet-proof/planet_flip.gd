extends SceneTree
# Scratch (Simulation): full slices read twice, float64 scalars and World's Vector3 prototype, counting the columns whose
# biome differs (a desync in a lockstep) and the largest height difference. Usage: ... --script res://zplanet/planet_flip.gd -- <circles>
const P64 = preload("res://zplanet/p64lib.gd")
const Lib = preload("res://zplanet/planet_lib.gd")


func _init() -> void:
	var n: int = int(OS.get_cmdline_user_args()[0])
	var A = P64.new()
	var P = Lib.new()
	var cols: int = 0
	var flips: int = 0
	var worst: float = 0.0
	var near: int = 0
	var slicesHit: int = 0
	for j in range(100, 100 + n):
		var c: Dictionary = A.circle(j)
		var T3 := Vector3(c.T[0], c.T[1], c.T[2])
		var C3 := Vector3(c.C[0], c.C[1], c.C[2])
		var v3: Vector3 = T3.cross(C3).normalized().cross(T3)
		var hit: bool = false
		for i in range(4800):
			var p: Array = A.point(c, i)
			var h: float = A.elev(p[0], p[1], p[2])
			var b: int = A.biome(p[0], p[1], p[2], h)
			var q: Vector3 = P.rot(T3, v3, (32.0 * float(i)) / A.R)
			var h3: float = P.elev(q)
			var b3: int = P.biome(q, h3)
			cols += 1
			worst = maxf(worst, absf(h - h3))
			if absf(h) < 0.003 or absf(h - 3200.0) < 0.003:
				near += 1
			if b != b3:
				flips += 1
				hit = true
		if hit:
			slicesHit += 1
	print("%d slices, %d columns: %d columns change biome under Vector3 (%d slices with at least one); %d columns within 0.003 units of the sea or mountain line; largest height difference %.6f units" % [n, cols, flips, slicesHit, near, worst])
	quit()
