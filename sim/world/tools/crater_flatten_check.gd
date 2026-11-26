extends SceneTree
# A crater is cut on a level floor (World, A1 clipping F-RENDER-03; sim/world/store.gd, data/biomes/craters.json globe.flatten; docs/world/crater-flatten.md). From the repo root:
#   godot --headless --path . --script res://sim/world/tools/crater_flatten_check.gd -- [--negative-control]
# Orb's 16:46 play (9 November): a crater 1,992 across on uneven ground crossed three hills, because a crater is added on top of the terrain. Proves, on a hilly place of planet 7: with the switch off the bowl has
# humps (the bug, so the check is not vacuous); with it on, no hump inside 0.9 of the radius, the floor is the ground at the centre less the bowl's profile (within a unit), the ground beyond the fade (1.45 radii)
# is exactly what it was, the store (and so the state's hash) is not changed by the switch, and a peer that never read the ground before the dig reads the same columns as one that did. --negative-control keeps
# the switch off: the no-hump checks must fail.
var fails: int = 0
var negative: bool = false
const FIELD: Dictionary = {"intro": false, "planet": 7, "touch": 1, "planetGen": 3}


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func _mk() -> SimState:
	WorldClimate.useGen(3)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": false, "p2": false}, FIELD)
	for t in range(5):
		SimCore.step(S)
	return S


func _ground(S: SimState, p: Array) -> float:
	return WorldStore._fieldH(S, p[0], p[1], p[2]) + WorldStore.heightDelta(S, p[0], p[1], p[2])


## The ground along one bearing through q, from -1.6 r to +1.6 r every 8 units (two half lines): [offsets, heights].
func _line(S: SimState, q: Array, b: Array, bi: int, r: float) -> Array:
	var offs: Array = []
	var hs: Array = []
	var d: float = -1.6 * r
	while d <= 1.6 * r:
		var p: Array = q if d == 0.0 else WorldGlobe.pointAt(q, b, bi if d > 0.0 else (bi + 4) % 8, absf(d))
		offs.append(d)
		hs.append(_ground(S, p))
		d += 8.0
	return [offs, hs]


## Humps: a local top inside 0.9 r standing more than 10 over the lower of the two hollows beside it (the lowest point each side, inside 0.9 r).
func _humps(offs: Array, hs: Array, r: float) -> int:
	var idx: Array = []
	for i in range(offs.size()):
		if absf(offs[i]) <= 0.9 * r:
			idx.append(i)
	var n: int = 0
	for a in range(1, idx.size() - 1):
		var i: int = idx[a]
		if hs[i] > hs[idx[a - 1]] and hs[i] >= hs[idx[a + 1]]:
			var lo_l: float = 1.0e30
			for c in range(0, a):
				lo_l = minf(lo_l, hs[idx[c]])
			var lo_r: float = 1.0e30
			for c in range(a + 1, idx.size()):
				lo_r = minf(lo_r, hs[idx[c]])
			if hs[i] - maxf(lo_l, lo_r) > 10.0 and hs[i] - minf(lo_l, lo_r) > 10.0:
				n += 1
	return n


## Hilly places on the match's line (up to `want` of them, at least 3,000 apart): 1,600 units either side stay over 60, and the ground varies by 260 or more in 4,000.
func _hilly(S: SimState, want: int) -> Array:
	var found: Array = []
	var nc: float = float(SimConst.NC) * SimConst.COL
	var step: float = 200.0
	var n: int = int(nc / step)
	var hs: Array = []
	for i in range(n):
		SimField.pointAt(S, float(i) * step)
		var p: Array = [SimField.ox, SimField.oy, SimField.oz]
		hs.append(WorldStore._fieldH(S, p[0], p[1], p[2]))
	for i in range(10, n - 10):
		var lo: float = 1.0e30
		var hi: float = -1.0e30
		for j in range(-10, 11):
			lo = minf(lo, hs[i + j])
			hi = maxf(hi, hs[i + j])
		if lo > 60.0 and hi - lo >= 260.0 and hi < 2500.0 and (found.is_empty() or float(i) * step - float(found[found.size() - 1]) > 3000.0):
			found.append(float(i) * step)
			if found.size() >= want:
				break
	return found


func _dig(S: SimState, x: float, flat: bool):
	WorldCraters.setFlatten(flat)
	return WorldCrater.dig(S, x, 17.2, S.fighters[0], "impact", 0.0, 1.0, true)   # a special: x9 energy, a radius of about 1,990


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 0, true)
	var S0 := _mk()
	var cands: Array = _hilly(S0, 12)
	ok(cands.size() >= 3, "hilly places are found on the line (%d)" % cands.size())
	var x: float = -1.0
	var results: Dictionary = {}
	for xc in cands:   # the first place where the bowl, switch off, has humps: Orb's crater had three
		x = xc
		results = _measure(x)
		if results[false].humps > 0:
			break
	print("humps in a bowl of radius %.0f at x %.0f (4 lines): switch off %d, on %d; the floor's deviation from the centre's ground less the profile: off %.1f, on %.2f" % [results[false].r, x, results[false].humps, results[true].humps, results[false].dev, results[true].dev])
	ok(results[false].humps > 0, "with the switch off the bowl has humps (%d): the bug, and the check can see it" % results[false].humps)
	ok(results[true].humps == 0, "with the switch on no hump stands inside 0.9 of the radius (%d)" % results[true].humps)
	ok(results[true].dev < 3.0, "the floor is the centre's ground less the bowl's profile, within 3 units (%.2f; the line's chord against the arc)" % results[true].dev)
	ok(results[false].hash == results[true].hash, "the switch is a read, not a record: the store's hash is the same on and off")
	_peers(x)
	WorldCraters.setFlatten(false)
	print("CRATERFLATTEN: %d check(s) failed%s" % [fails, " (negative control)" if negative else ""])
	quit(0)


func _measure(x: float) -> Dictionary:
	var results: Dictionary = {}
	for flat in [false, true]:
		var S := _mk()
		var rec = _dig(S, x, flat and not negative)
		var q: Array = WorldStore.centreOf(S, 0)
		var r: float = rec.r
		var b: Array = WorldGlobe.basis(q)
		var humps: int = 0
		var maxdev: float = 0.0
		var fc: float = WorldStore._fieldH(S, q[0], q[1], q[2])
		for bi in range(4):
			var ln: Array = _line(S, q, b, bi, r)
			humps += _humps(ln[0], ln[1], r)
			for i in range(ln[0].size()):
				var u: float = absf(ln[0][i]) / r
				if u <= 0.9:
					maxdev = maxf(maxdev, absf(ln[1][i] - (fc + WorldCrater.profile(u, rec.depth, rec.rim))))
		results[flat] = {"humps": humps, "dev": maxdev, "hash": S.storeHash, "r": r, "fc": fc}
		SimCore.dispose(S)
	return results


## Beyond the fade the ground is what it is with the switch off, and a peer that read the ground before the dig reads the same columns as one that did not.
func _peers(x: float) -> void:
	var A := _mk()
	var C := _mk()
	var B := _mk()
	WorldCraters.setFlatten(false)
	SimField._fresh(A)
	var c0: int = int(floor(SimWrap.wrap(x) / SimConst.COL))
	var farOff: Array = []
	var before := PackedFloat64Array()
	for i in range(c0 - 400, c0 + 401):
		before.append(SimField.col(A, posmod(i, SimConst.NC)))
	_dig(A, x, true)
	_dig(C, x, true)
	_dig(B, x, false)
	SimField._fresh(A)
	SimField._fresh(C)
	SimField._fresh(B)
	var bad: int = 0
	var farBad: int = 0
	var rr: float = 1992.0
	for k in range(before.size()):
		var i: int = posmod(c0 - 400 + k, SimConst.NC)
		var ga: float = SimField.col(A, i)
		var gc: float = SimField.col(C, i)
		if ga != gc:
			bad += 1
		if absf(float(i - c0)) * SimConst.COL > 1.45 * rr * 1.03 and ga != SimField.col(B, i):
			farBad += 1
	ok(bad == 0, "a peer that read the ground before the dig and one that did not read the same %d columns" % before.size())
	ok(farBad == 0, "beyond the fade (1.45 radii and a margin for the line's arc) the ground is what it is with the switch off (%d columns differ)" % farBad)
