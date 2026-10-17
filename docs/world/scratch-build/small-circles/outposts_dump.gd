extends SceneTree
# Where three research outposts could stand on planet 7 (a shelf station, an inland station, a floe station) and a 3,000-unit window round each. Prototype.
#   godot --headless --path . --script res://sim/world/tools/outposts_dump.gd -- <out.json>
var P


func nb(p: Array, east: Array, north: Array, d: float, a: float) -> Array:
	# the point d units from p toward bearing a
	var ang: float = d / P.R
	var co: float = SimDetMath.cos(ang)
	var si: float = SimDetMath.sin(ang)
	var ca: float = SimDetMath.cos(a)
	var sa: float = SimDetMath.sin(a)
	var dir: Array = [east[0] * ca + north[0] * sa, east[1] * ca + north[1] * sa, east[2] * ca + north[2] * sa]
	return [p[0] * co + dir[0] * si, p[1] * co + dir[1] * si, p[2] * co + dir[2] * si]


func frame(p: Array) -> Array:
	var ref: Array = [0.0, 1.0, 0.0] if absf(p[1]) < 0.95 else [1.0, 0.0, 0.0]
	var e: Array = WorldPlanet._unit(WorldPlanet._cross(ref, p))
	var n: Array = WorldPlanet._cross(p, e)
	return [e, n]


func read(p: Array) -> Array:
	WorldPlanet.surfAt(P, p[0], p[1], p[2])
	return [P.outH, P.outB]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	P = WorldPlanet.make(7)
	var rr := SimRng.new(321)
	var out := {}
	var found: Array = []
	for kind in ["shelf", "inland", "floe"]:
		var best = null
		var bs: float = -1.0e9
		for k in range(1500):
			var z: float
			if kind == "shelf":
				z = -(0.86 + 0.08 * rr.next())
			elif kind == "inland":
				z = -(0.965 + 0.035 * rr.next())
			else:
				z = 0.9 + 0.1 * rr.next()
			var a: float = rr.range_(0.0, 2.0 * PI)
			var q: float = sqrt(1.0 - z * z)
			var p: Array = [q * SimDetMath.cos(a), z, q * SimDetMath.sin(a)]
			var r0: Array = read(p)
			var sc: float = -1.0e9
			if kind == "shelf":
				if r0[1] == 5 and absf(r0[0] - 36.0) < 7.0:
					# on the shelf, with the sea within 2,500 units on one side and the dome on the other
					var fr: Array = frame(p)
					var sea: bool = false
					var dome: bool = false
					for ang in [0.0, PI / 2.0, PI, 3.0 * PI / 2.0]:
						var s1: Array = read(nb(p, fr[0], fr[1], 2500.0, ang))
						if s1[1] == 0:
							sea = true
						if s1[1] == 5 and s1[0] > 150.0:
							dome = true
					if sea and dome:
						sc = rr.next()
			elif kind == "inland":
				if r0[1] == 5 and r0[0] > 1300.0:
					var fr2: Array = frame(p)
					var rock: float = 1.0e9
					for ang in [0.0, PI / 3.0, 2.0 * PI / 3.0, PI, 4.0 * PI / 3.0, 5.0 * PI / 3.0]:
						for d in [600.0, 1500.0, 2500.0]:
							if read(nb(p, fr2[0], fr2[1], d, ang))[1] == 4:
								rock = minf(rock, d)
					if rock < 1.0e8:
						sc = 3000.0 - rock + rr.next()
			else:
				if r0[1] == 6 and r0[0] > 15.0 and r0[0] < 45.0:
					var fr3: Array = frame(p)
					var inside: int = 0
					for ang in [0.0, PI / 4.0, PI / 2.0, 3.0 * PI / 4.0, PI, 5.0 * PI / 4.0, 3.0 * PI / 2.0, 7.0 * PI / 4.0]:
						if read(nb(p, fr3[0], fr3[1], 700.0, ang))[1] == 6:
							inside += 1
					if inside >= 8:
						sc = float(inside) + rr.next()
			if sc > bs:
				bs = sc
				best = p
		if best == null:
			continue
		var fr4: Array = frame(best)
		var win: Array = []
		for k in range(1000):
			var d2: float = (float(k) - 500.0) * 3.0
			var pw: Array = nb(best, fr4[0], fr4[1], absf(d2), 0.0 if d2 >= 0.0 else PI)
			var rw: Array = read(pw)
			win.append([snappedf(rw[0], 1.0), rw[1]])
		var rb: Array = read(best)
		out[kind] = {"v": best, "h": rb[0], "b": rb[1], "win": win}
		print("%s: y %.3f, height %.0f, biome %d" % [kind, best[1], rb[0], rb[1]])
	var f := FileAccess.open(args[0], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit()
