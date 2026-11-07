extends SceneTree
# The street's axes against the fight's line (World, sim/world/structures.gd streetAxis; docs/world/street-axis.md): for Encounter's turn on impact, the signed sine of the across-street axis (lineSin) and the along-street axis
# (alongSin) to the line at a building, and which side of the line the street lies. At the start every front-street building lies on the line (a street along it); with the frame turned by an angle phi the sines are the
# street's turn, equal to a second way of reading it (the street's own two points carried into the strip, SimField.stripIn); a pure read: no hash moves, no scratch changes; a world with no frame answers as a street along the line.
#   godot --headless --path . --script res://sim/world/tools/street_axis_check.gd -- [--planet=7] [--touch=3]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


## The second reading: an axis of the lot as a direction in the strip (two points of the planet either side of the building along it, carried by SimField.stripIn), as a signed sine to the line: the direction's depth over
## its length. mode 1 turns it to face along the line (square to it: toward the camera); mode 0 turns it toward the street's side (side from the building's own depth in the strip: behind, away from the camera).
func _strip_sine(fr, q: Array, ax: Array, mode: int) -> float:
	var e: float = 0.02   # a step of about 500 units: the strip's own arc functions are approximations, and a short step drowns in them
	SimField.stripIn(fr, q[0], q[1], q[2])
	var zq: float = SimField.sz
	var side: int = 0 if absf(zq) <= 1.0 else (1 if zq > 0.0 else -1)
	var p0: Array = [q[0] - e * ax[0], q[1] - e * ax[1], q[2] - e * ax[2]]
	var p1: Array = [q[0] + e * ax[0], q[1] + e * ax[1], q[2] + e * ax[2]]
	p0 = _unit(p0)   # back on the sphere: off it a point reads a different depth
	p1 = _unit(p1)
	SimField.stripIn(fr, p0[0], p0[1], p0[2])
	var x0: float = SimField.sx
	var z0: float = SimField.sz
	SimField.stripIn(fr, p1[0], p1[1], p1[2])
	var dx: float = SimWrap.sdx(x0, SimField.sx) * cos(zq / SimField.R)   # a unit of x is shorter at depth
	var dz: float = SimField.sz - z0
	var l: float = sqrt(dx * dx + dz * dz)
	var sn: float = dz / l
	if mode == 1:
		if dx < -1.0e-5 * l or (absf(dx) <= 1.0e-5 * l and sn < 0.0):
			sn = -sn
	elif (side < 0 and sn > 0.0) or (side >= 0 and sn < 0.0):
		sn = -sn
	return sn


func _unit(v: Array) -> Array:
	var l: float = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
	return [v[0] / l, v[1] / l, v[2] / l]


## The line turned about its point by phi: the tangent t' = t cos + n sin, the point the same.
func _turned(fr, phi: float):
	var nx: float = fr.ty * fr.pz - fr.tz * fr.py
	var ny: float = fr.tz * fr.px - fr.tx * fr.pz
	var nz: float = fr.tx * fr.py - fr.ty * fr.px
	var f2 = fr.copy()
	f2.tx = fr.tx * cos(phi) + nx * sin(phi)
	f2.ty = fr.ty * cos(phi) + ny * sin(phi)
	f2.tz = fr.tz * cos(phi) + nz * sin(phi)
	return f2


## The same lot streetAxis holds him in, found again here from the records.
func _lot_of(S: SimState, bi: int):
	var R: float = SimField.R
	var best = null
	var bs: float = 1.0e30
	for rec in S.fieldRecs:
		if rec.k != "lot":
			continue
		var d: Array = [(S.bDir[bi * 3] - rec.c[0]) * R, (S.bDir[bi * 3 + 1] - rec.c[1]) * R, (S.bDir[bi * 3 + 2] - rec.c[2]) * R]
		var al: float = absf(d[0] * rec.t[0] + d[1] * rec.t[1] + d[2] * rec.t[2])
		var ac: float = absf(d[0] * rec.s[0] + d[1] * rec.s[1] + d[2] * rec.s[2])
		if al > float(rec.hl) + 40.0 or ac > float(rec.hd) + 40.0:
			continue
		var share: float = maxf(al / maxf(float(rec.hl), 1.0), ac / maxf(float(rec.hd), 1.0))
		if share < bs:
			bs = share
			best = rec
	return best


func _init() -> void:
	var planet: int = 7
	var touch: int = 3
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 4, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	for i in range(30):
		SimCore.step(S, null)
	var n: int = mini(S.buildings.size(), S.bDir.size() / 3)
	var row1: int = 0
	var found1: int = 0
	var worst_along: float = 0.0
	var worst_line: float = 1.0
	var sides_ok: bool = true
	var rows_found: Dictionary = {}
	for bi in range(n):
		var b = S.buildings[bi]
		var r: Dictionary = WorldStructures.streetAxis(S, bi)
		var zb: float = float(b.z)
		var want: int = 0 if absf(zb) <= 1.0 else (1 if zb > 0.0 else -1)
		if int(r.side) != want and absf(absf(zb) - 1.0) > 0.5:
			sides_ok = false
		if bool(r.found):
			rows_found[int(b.row)] = int(rows_found.get(int(b.row), 0)) + 1
		if int(b.row) == 1 and b.alive:
			row1 += 1
			if bool(r.found):
				found1 += 1
				worst_along = maxf(worst_along, absf(float(r.alongSin)))
				worst_line = minf(worst_line, absf(float(r.lineSin)))
	ok(row1 >= 40 and found1 >= int(0.85 * float(row1)), "front-street buildings find their lot (%d of %d)" % [found1, row1])
	ok(worst_along < 0.02 and worst_line > 0.99, "at the start a front street runs along the line: alongSin under 0.02 (worst %.4f), lineSin over 0.99 (worst %.4f)" % [worst_along, worst_line])
	var behind_ok: bool = true
	var behind_n: int = 0
	for bi in range(n):
		var rr: Dictionary = WorldStructures.streetAxis(S, bi)
		if bool(rr.found) and int(rr.side) != 0 and S.buildings[bi].alive:
			behind_n += 1
			if absf(float(rr.lineSin) - float(rr.side)) > 0.3 or absf(float(rr.alongSin)) > 0.35:
				behind_ok = false
	ok(behind_n >= 20 and behind_ok, "streets behind or in front of the line (%d buildings): lineSin points toward the street (its sign is the side) and they run near the line's own direction" % behind_n)
	ok(sides_ok, "side is the sign of the building's depth (0 on the line, 1 toward the camera, -1 behind); lots found by row: %s" % str(rows_found))
	# the turned frame against the strip reading
	var fr0 = S.frame
	var worst_err: float = 0.0
	var tested: int = 0
	var seen_sign: Dictionary = {}
	for phi in [0.0, 0.3, -0.7, 1.2]:
		S.frame = _turned(fr0, phi)
		var step: int = maxi(n / 40, 1)
		for bi in range(0, n, step):
			var b = S.buildings[bi]
			if not b.alive:
				continue
			var r: Dictionary = WorldStructures.streetAxis(S, bi)
			if not bool(r.found):
				continue
			var lot = _lot_of(S, bi)
			var q: Array = [S.bDir[bi * 3], S.bDir[bi * 3 + 1], S.bDir[bi * 3 + 2]]
			var e1: float = absf(float(r.lineSin) - _strip_sine(S.frame, q, lot.s, 0))
			var e2: float = absf(float(r.alongSin) - _strip_sine(S.frame, q, lot.t, 1))
			worst_err = maxf(worst_err, maxf(e1, e2))
			tested += 1
			if phi != 0.0 and absf(float(r.alongSin)) > 0.1:
				seen_sign[phi] = (1 if float(r.alongSin) > 0.0 else -1)
	S.frame = fr0
	ok(tested >= 100 and worst_err < 0.01, "turned by 0, 0.3, -0.7 and 1.2 rad the sines equal the strip reading of the street's own axes (%d reads, worst difference %.5f)" % [tested, worst_err])
	ok(seen_sign.get(0.3, 0) == -seen_sign.get(-0.7, 0) and seen_sign.get(0.3, 0) != 0, "the sign follows the turn: a street turned one way reads positive, the other way negative (%s)" % str(seen_sign))
	# a pure read
	var h0: String = str(SimHash.stateHash(S).gameplay)
	SimField.sx = 1.5
	SimField.sz = 2.5
	SimField.ox = 0.25
	var a1: Dictionary = WorldStructures.streetAxis(S, 30)
	var a2: Dictionary = WorldStructures.streetAxis(S, 30)
	ok(h0 == str(SimHash.stateHash(S).gameplay) and SimField.sx == 1.5 and SimField.sz == 2.5 and SimField.ox == 0.25, "a pure read: no hash moves and SimField's scratch is as it was")
	ok(a1.hash() == a2.hash(), "the same state answers the same")
	# no frame, no lot, a bad index
	var P := SimCore.createSim()
	SimCore.newMatch(P, 1, {}, {"intro": false})
	var rp: Dictionary = WorldStructures.streetAxis(P, 5)
	ok(not bool(rp.found) and float(rp.lineSin) == 1.0 and float(rp.alongSin) == 0.0, "a world with no frame answers as a street along the line (found %s)" % str(rp.found))
	var rb: Dictionary = WorldStructures.streetAxis(S, -1)
	var rc: Dictionary = WorldStructures.streetAxis(S, 100000)
	ok(not bool(rb.found) and not bool(rc.found), "a building that is not there answers found false")
	SimCore.dispose(P)
	SimCore.dispose(S)
	print("STREETAXIS: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
