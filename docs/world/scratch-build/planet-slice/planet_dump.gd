extends SceneTree
# World, paper-only prototype: generate a planet, pick slices the constructive way, count what they hold, dump JSON for the diagrams.
#   godot --headless --path . --script res://sim/world/tools/planet_dump.gd -- <out.json> [seed]
const Lib = preload("res://sim/world/tools/planet_lib.gd")
var P
var places: Array = []   # {kind, v: Vector3, r}
var NC: int = 8
var NT: int = 28
var RC: float = 8000.0
var RT: float = 3000.0


func place_all() -> void:
	var r := SimRng.new(P.seed * 31 + 1)
	var spec := [["city", NC, RC, 80], ["town", NT, RT, 40]]
	for sp in spec:
		for k in range(int(sp[1])):
			var best = null
			var bs: float = -1.0e9
			for c in range(int(sp[3])):
				var p: Vector3 = P.randunit(r)
				var h: float = P.elev(p)
				if h < 60.0 or h > 1800.0:
					continue
				var dmin: float = 1.0e9
				for o in places:
					dmin = minf(dmin, P.arc(p, o.v) - o.r - float(sp[2]))
				if dmin < 400.0:
					continue
				var sc: float = dmin * 0.001 - absf(h - 300.0) * 0.002 + r.next()
				if sc > bs:
					bs = sc
					best = p
			if best != null:
				places.append({"kind": sp[0], "v": best, "r": sp[2]})


## What the great circle with normal nn, starting at q (a point on it), holds. Returns a dictionary.
func read_slice(nn: Vector3, q: Vector3, samples: int, with_profile: bool) -> Dictionary:
	var u: Vector3 = (q - nn * q.dot(nn)).normalized()
	var v: Vector3 = nn.cross(u).normalized()
	var held: Array = []
	var cities: int = 0
	var towns: int = 0
	var settled: float = 0.0
	for i in range(places.size()):
		var o = places[i]
		var d: float = P.R * asin(clampf(nn.dot(o.v), -1.0, 1.0))
		var reach: float = 0.6 * o.r if o.kind == "city" else 0.7 * o.r
		if absf(d) < reach:
			var s: float = P.R * atan2(o.v.dot(v), o.v.dot(u))
			if s < 0.0:
				s += P.L
			var half: float = sqrt(maxf(0.0, o.r * o.r - d * d))
			held.append({"i": i, "kind": o.kind, "s": s, "d": d, "half": half})
			settled += 2.0 * half
			if o.kind == "city":
				cities += 1
			else:
				towns += 1
	var seen := [0, 0, 0, 0, 0]
	var prof: Array = []
	var cnt: int = samples
	for k in range(cnt):
		var p: Vector3 = P.rot(u, v, float(k) / float(cnt) * 2.0 * PI)
		var h: float = P.elev(p)
		var b: int = P.biome(p, h)
		seen[b] += 1
		if with_profile:
			prof.append([snappedf(h, 1.0), b])
	var kinds: int = 0
	for s in seen:
		if float(s) / float(cnt) >= 0.08:
			kinds += 1
	return {"cities": cities, "towns": towns, "biomes": kinds, "land": 1.0 - float(seen[0]) / float(cnt), "settled": settled / P.L, "held": held, "profile": prof, "seen": seen}


func meets(r: Dictionary) -> bool:
	return r.cities >= 2 and r.towns >= 3 and r.biomes >= 3 and r.land >= 0.5


## A touch-down point: the candidates are the great circles through it and each city, and a few of random bearing. The first that meets the minimum, in a seeded order.
func pick(touch: Vector3, rr: SimRng, quick: int) -> Dictionary:
	var cand: Array = []
	for o in places:
		if o.kind == "city":
			var nn: Vector3 = touch.cross(o.v)
			if nn.length() > 0.15:
				cand.append(nn.normalized())
	for k in range(4):
		var t: Vector3 = P.randunit(rr)
		var nn2: Vector3 = touch.cross(t)
		if nn2.length() > 0.3:
			cand.append(nn2.normalized())
	# a seeded shuffle
	for i in range(cand.size() - 1, 0, -1):
		var j: int = int(rr.next() * float(i + 1))
		var tmp = cand[i]
		cand[i] = cand[j]
		cand[j] = tmp
	var tried: int = 0
	for nn3 in cand:
		tried += 1
		var res: Dictionary = read_slice(nn3, touch, quick, false)
		if meets(res):
			res["tried"] = tried
			res["n"] = nn3
			return res
	return {"tried": tried, "n": Vector3.ZERO, "cities": 0}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "planet.json"
	P = Lib.new()
	if args.size() > 1:
		P.seed = int(args[1])
	if args.size() > 4:
		NC = int(args[2])
		NT = int(args[3])
		RC = float(args[4])
		RT = RC * 0.375
	var t0: int = Time.get_ticks_usec()
	place_all()
	var nc: int = 0
	for o in places:
		if o.kind == "city":
			nc += 1
	print("places: %d cities, %d towns (%.0f ms)" % [nc, places.size() - nc, float(Time.get_ticks_usec() - t0) / 1000.0])
	# the grid for the map: 5 degree cells
	var grid: Array = []
	for j in range(36):
		var row: Array = []
		var la: float = (-87.5 + 5.0 * float(j)) * PI / 180.0
		for i in range(72):
			var lo: float = (-177.5 + 5.0 * float(i)) * PI / 180.0
			var p := Vector3(cos(la) * cos(lo), sin(la), cos(la) * sin(lo))
			row.append(P.biome(p, P.elev(p)))
		grid.append(row)
	# slices from random touch-downs
	var rr := SimRng.new(2026)
	var N: int = 300
	var okq: int = 0
	var tried_sum: int = 0
	var fall: int = 0
	var acc := {"cities": 0.0, "towns": 0.0, "biomes": 0.0, "land": 0.0, "settled": 0.0}
	var t1: int = Time.get_ticks_usec()
	var good: Array = []
	for t in range(N):
		var touch: Vector3 = P.randunit(rr)
		var h: float = P.elev(touch)
		if h < 0.0:
			t -= 0   # an ocean touch-down is allowed here; the note asks whether it should be
		var res: Dictionary = pick(touch, rr, 96)
		tried_sum += int(res.tried)
		if res.cities >= 2:
			okq += 1
			for k in acc:
				acc[k] += float(res[k])
			if good.size() < 6:
				good.append({"touch": [touch.x, touch.y, touch.z], "n": [res.n.x, res.n.y, res.n.z], "cities": res.cities, "towns": res.towns})
		else:
			fall += 1
	var t2: int = Time.get_ticks_usec()
	print("touch-downs %d: a slice meeting the minimum found for %.0f%% (candidates tried a touch-down: %.1f); accepted arenas hold %.1f cities, %.1f towns, %.1f biomes, land %.0f%%, settled %.0f%% of the length" % [N, 100.0 * float(okq) / float(N), float(tried_sum) / float(N), acc.cities / okq, acc.towns / okq, acc.biomes / okq, 100.0 * acc.land / okq, 100.0 * acc.settled / okq])
	print("pick cost: %.1f ms a touch-down" % (float(t2 - t1) / 1000.0 / float(N)))
	# two example slices in full for the diagrams
	var ex: Array = []
	var rr2 := SimRng.new(5)
	for k in range(2):
		var touch2: Vector3 = P.randunit(rr2)
		var tries: int = 0
		while tries < 60:
			tries += 1
			touch2 = P.randunit(rr2)
			if P.elev(touch2) < 100.0:
				continue
			var res2: Dictionary = pick(touch2, rr2, 96)
			if res2.cities >= 2 and res2.n != Vector3.ZERO:
				var full: Dictionary = read_slice(res2.n, touch2, 600, true)
				full["touch"] = [touch2.x, touch2.y, touch2.z]
				full["n"] = [res2.n.x, res2.n.y, res2.n.z]
				full["tried"] = res2.tried
				ex.append(full)
				break
	var pl: Array = []
	for o in places:
		pl.append({"kind": o.kind, "v": [o.v.x, o.v.y, o.v.z], "r": o.r})
	var js := JSON.stringify({"seed": P.seed, "R": P.R, "L": P.L, "grid": grid, "places": pl, "slices": ex, "stats": {"N": N, "ok": okq, "tried": tried_sum, "fallback": fall}})
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(js)
	f.close()
	print("wrote %s (%d bytes)" % [out_path, js.length()])
	quit()
