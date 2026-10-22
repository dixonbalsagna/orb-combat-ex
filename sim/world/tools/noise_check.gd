extends SceneTree
# The planet's value noise against its reference (the lattice hashed corner by corner, no memo):
#   godot --headless --path . --script res://sim/world/tools/noise_check.gd
# WorldPlanet._vn keeps the corners of the cell it read last at each seed and hashes the shared parts once; both are exact, so every answer must match the reference bit for bit, in any order.
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func ref(x: float, y: float, z: float, s: int) -> float:
	var fx: float = floor(x)
	var fy: float = floor(y)
	var fz: float = floor(z)
	var ix: int = int(fx)
	var iy: int = int(fy)
	var iz: int = int(fz)
	var tx: float = x - fx
	var ty: float = y - fy
	var tz: float = z - fz
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	tz = tz * tz * (3.0 - 2.0 * tz)
	var c000: float = WorldPlanet._lat(ix, iy, iz, s)
	var c100: float = WorldPlanet._lat(ix + 1, iy, iz, s)
	var c010: float = WorldPlanet._lat(ix, iy + 1, iz, s)
	var c110: float = WorldPlanet._lat(ix + 1, iy + 1, iz, s)
	var c001: float = WorldPlanet._lat(ix, iy, iz + 1, s)
	var c101: float = WorldPlanet._lat(ix + 1, iy, iz + 1, s)
	var c011: float = WorldPlanet._lat(ix, iy + 1, iz + 1, s)
	var c111: float = WorldPlanet._lat(ix + 1, iy + 1, iz + 1, s)
	var a: float = c000 + (c100 - c000) * tx
	var b: float = c010 + (c110 - c010) * tx
	var c: float = c001 + (c101 - c001) * tx
	var d: float = c011 + (c111 - c011) * tx
	var e: float = a + (b - a) * ty
	var f: float = c + (d - c) * ty
	return e + (f - e) * tz


func _init() -> void:
	var rng := SimRng.new(1234)
	var bad: int = 0
	var n: int = 0
	var seeds: Array = [0, 1, 7, 12345, 4294967295, 4294967296 + 5, 99999999]
	# random points, any order, positive and negative, small and large
	for t in range(60000):
		var s: int = seeds[int(rng.next() * seeds.size())] + 101 * int(rng.next() * 4)
		var span: float = [3.0, 60.0, 4000.0, 1.0e6][int(rng.next() * 4)]
		var x: float = (rng.next() - 0.5) * span
		var y: float = (rng.next() - 0.5) * span
		var z: float = (rng.next() - 0.5) * span
		n += 1
		if WorldPlanet._vn(x, y, z, s) != ref(x, y, z, s):
			bad += 1
	ok(bad == 0, "random points, seeds and scales (%d points): _vn is the reference's number" % n)
	# a walk, as a ring read goes: small steps along a line, then the same walk again, then backwards
	bad = 0
	n = 0
	for pass_ in range(3):
		for i in range(6000):
			var j: int = i if pass_ != 2 else 6000 - i
			var x: float = -40.0 + float(j) * 0.0137
			var y: float = 9.3 - float(j) * 0.0071
			var z: float = float(j) * 0.0093
			for s in [5, 106, 207]:
				n += 1
				if WorldPlanet._vn(x, y, z, s) != ref(x, y, z, s):
					bad += 1
	ok(bad == 0, "a walk along a line, again, and back (%d reads, three seeds interleaved): the same" % n)
	# more seeds than the memo holds: it starts over and stays exact
	bad = 0
	for s in range(5000):
		var x: float = float(s) * 0.37
		if WorldPlanet._vn(x, 1.5, 2.5, s) != ref(x, 1.5, 2.5, s) or WorldPlanet._vn(x + 0.01, 1.5, 2.5, s) != ref(x + 0.01, 1.5, 2.5, s):
			bad += 1
	ok(bad == 0, "5,000 seeds (more than the memo's slots): exact across the restart")
	# the fbm built on it, against a reference fbm
	bad = 0
	for t in range(4000):
		var x: float = (rng.next() - 0.5) * 3.0
		var y: float = (rng.next() - 0.5) * 3.0
		var z: float = (rng.next() - 0.5) * 3.0
		var sum: float = 0.0
		var amp: float = 0.5
		var tot: float = 0.0
		var k: float = 6371.0 / 1500.0
		for o in range(3):
			sum += amp * ref(x * k, y * k, z * k, 77 + o * 101)
			tot += amp
			amp *= 0.5
			k *= 2.0
		if WorldPlanet._fbm(6371.0, x, y, z, 1500.0, 3, 77) != sum / tot:
			bad += 1
	ok(bad == 0, "3 octaves of it (_fbm, 4000 points): the same")
	print("NOISE: %d check(s) failed" % fails)
	quit()
