extends SceneTree
# Screen-sized windows (3,000 units, 3 units a column) along the meridian example, at many distances from each pole.
#   godot --headless --path . --script res://sim/world/tools/planet2_windows.gd -- <planet2.json> <out.json> [seed]
const Lib = preload("res://sim/world/tools/planet2_lib.gd")
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var d = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var P = Lib.new()
	P.seed = int(d["seed"])
	var sl = null
	for e in d["slices"]:
		if e["name"] == "meridian":
			sl = e
	var T := Vector3(sl["touch"][0], sl["touch"][1], sl["touch"][2])
	var n := Vector3(sl["n"][0], sl["n"][1], sl["n"][2])
	var u: Vector3 = (T - n * T.dot(n)).normalized()
	var v: Vector3 = n.cross(u).normalized()
	var out := {}
	for pn in [["N", 1.0, [3000, 5000, 7000, 9000, 10500, 11500, 12500, 13500, 14500]], ["S", -1.0, [3000, 6000, 9000, 9500, 10000, 10500, 11000, 11500, 12500]]]:
		var Y := Vector3(0, pn[1], 0)
		var a0: float = atan2(Y.dot(v), Y.dot(u))
		var wins: Array = []
		for off in pn[2]:
			var wz: Array = []
			for k in range(1000):
				var s2: float = float(off) + (float(k) - 500.0) * 3.0
				var pz: Vector3 = P.rot(u, v, a0 + s2 / P.R)
				var sf: Array = P.surf(pz)
				wz.append([snappedf(sf[0], 1.0), P.biome(pz, sf[0])])
			wins.append({"off": off, "p": wz})
		out[pn[0]] = wins
	# a berg: scan meridians out of the north pole for a column of sea ice taller than 100 units, 9,000 to 15,000 units from the pole
	var found: bool = false
	for lon in range(0, 360, 5):
		if found:
			break
		var lr: float = float(lon) * PI / 180.0
		var e := Vector3(cos(lr), 0.0, sin(lr))
		var ss_: float = 9000.0
		while ss_ < 15000.0 and not found:
			var pz: Vector3 = P.rot(Vector3(0, 1, 0), e, ss_ / P.R)
			var sf: Array = P.surf(pz)
			if int(P.biome(pz, sf[0])) == 6 and sf[0] > 110.0:
				var wz: Array = []
				for k in range(1000):
					var p3: Vector3 = P.rot(Vector3(0, 1, 0), e, (ss_ + (float(k) - 500.0) * 3.0) / P.R)
					var s3: Array = P.surf(p3)
					wz.append([snappedf(s3[0], 1.0), P.biome(p3, s3[0])])
				out["B"] = [{"off": ss_, "p": wz, "lon": lon}]
				found = true
			ss_ += 6.0
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("wrote windows")
	quit()
