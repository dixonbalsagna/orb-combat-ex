extends SceneTree
# The beam struggle's meeting point (World, sim/world/struggle_meet.gd, data/biomes/craters.json struggleMeet; docs/world/struggle-meet.md; Game Design's block in docs/design/power-scale.md; Legal RL-232, RL-242, RL-243, RL-246):
# off, nothing moves; on, the sizes are Game Design's table (by each beam's stage), the bowl is dug once under the point and what stands in it falls by falling off from the centre, a barred landmark stands, an air burst shatters
# tower glass and fells nothing, a scorch ending digs nothing, a ring wears the buildings inside it and finishes none, and the same setup gives the same state twice.
#   godot --headless --path . --script res://sim/world/tools/struggle_meet_check.gd -- [--planet=7] [--touch=1] [--png=<dir>]   (--png draws the three sizes as side-on strips)
var fails: int = 0
var pngDir: String = ""


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _match(planet: int, touch: int) -> SimState:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	for i in range(30):
		SimCore.step(S)
	return S


func _level(S: SimState, tier: int, power: float) -> void:
	for f in S.fighters:
		f.tier = tier
		f.power = power


## The centre of the densest cluster of standing towers-and-houses within radius r: [x, z, count].
func _cluster(S: SimState, r: float) -> Array:
	var best: int = -1
	var bn: int = -1
	for i in range(mini(S.buildings.size(), S.bFirst if S.bFirst > 0 else S.buildings.size())):
		var a = S.buildings[i]
		if not a.alive:
			continue
		var n: int = 0
		for j in WorldStructures.near(S, a.x, r):
			var b = S.buildings[j]
			if b.alive and SimDetMath.hypot(SimWrap.sdx(a.x, b.x), float(b.z) - float(a.z)) <= r:
				n += 1
		if n > bn:
			bn = n
			best = i
	return [float(S.buildings[best].x), float(S.buildings[best].z), bn]


func _ev(S: SimState, x: float, z: float, how: String, run: float, stageA: int, countA: int, stageD: int, countD: int, sigA: bool, height: float) -> Dictionary:
	var g: float = WorldTerrain.groundY(S, x)
	return {"x": x, "y": g + height, "z": z, "how": how, "run": run, "lowY": g + height, "a": {"slot": 0, "stage": stageA, "count": countA, "sig": sigA}, "d": {"slot": 1, "stage": stageD, "count": countD, "sig": false}}


func _hp(S: SimState) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	for b in S.buildings:
		out.append(float(b.hp) if b.alive else 0.0)
	return out


## How far a building's near face is from a blast at (x, z), as WorldStructures.damageArea reads it (in plan with depth on, along the line without).
func _ringEdge(S: SimState, b, x: float, z: float) -> float:
	var d: float = maxf(0.0, absf(SimWrap.sdx(x, b.x)) - b.w * 0.5)
	if S.depthOn:
		return SimDetMath.hypot(d, maxf(0.0, absf(z - float(b.z)) - b.d * 0.5))
	return d if WorldStructures.dz(b) <= WorldStructures.Z_REACH else 1e9


func _pop(S: SimState) -> float:
	var t: float = 0.0
	for b in S.buildings:
		t += float(b.popAlive)
	return t


func _hash(S: SimState) -> String:
	return str(SimHash.stateHash(S).gameplay)


## A side-on strip about the point: the ground before (grey) and after (white), the buildings as boxes (standing blue, windows out pale, fallen red outline), the crater's lip and the glass radius.
func _still(S0: SimState, hp0: PackedFloat64Array, S: SimState, x: float, z: float, r: float, r0: float, path: String) -> void:
	var W: int = 1000
	var H: int = 380
	var half: float = maxf(r0, 300.0) * 1.35
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.93, 0.94, 0.96))
	var g0: float = WorldTerrain.groundY(S0, x)
	var scale: float = float(W) / (2.0 * half)
	var base: float = 250.0
	for px in range(W):
		var wx: float = x - half + float(px) / scale
		var y0: float = WorldTerrain.groundY(S0, wx) - g0
		var y1: float = WorldTerrain.groundY(S, wx) - g0
		for yy in range(int(base - y0 * scale), H):
			if yy >= 0:
				img.set_pixel(px, yy, Color(0.62, 0.62, 0.64))
		var ye: int = int(base - y1 * scale)
		for yy in range(maxi(0, ye - 1), mini(H, ye + 1)):
			img.set_pixel(px, yy, Color(0.1, 0.1, 0.1))
	for i in range(S.buildings.size()):
		var b = S.buildings[i]
		var dx: float = SimWrap.sdx(x, b.x)
		if absf(dx) - b.w * 0.5 > half or absf(float(b.z) - z) > 700.0 or hp0[i] <= 0.0:
			continue
		var gy: float = WorldTerrain.groundY(S0, b.x) - g0   # the plane's ground at his x (his own row's ground differs a little: a diagram)
		var x0: int = int((dx - b.w * 0.5 + half) * scale)
		var x1: int = int((dx + b.w * 0.5 + half) * scale)
		var top: int = int(base - (gy + float(b.h)) * scale)
		var bot: int = int(base - gy * scale)
		var col := Color(0.33, 0.45, 0.72)
		var edge := false
		if not b.alive:
			col = Color(0.8, 0.25, 0.2)
			edge = true
		elif b.hp < hp0[i] - 0.5:
			col = Color(0.66, 0.78, 0.92)
		for yy in range(maxi(0, top), mini(H, bot)):
			for xx in range(maxi(0, x0), mini(W, x1 + 1)):
				var onEdge: bool = yy == maxi(0, top) or xx == maxi(0, x0) or xx == mini(W - 1, x1)
				if edge and not onEdge:
					continue
				img.set_pixel(xx, yy, col)
	for rr in [[r, Color(0.9, 0.5, 0.0)], [r0, Color(0.3, 0.7, 0.3)]]:
		for sgn in [-1.0, 1.0]:
			var xx: int = int((sgn * float(rr[0]) + half) * scale)
			if xx >= 0 and xx < W:
				for yy in range(0, H, 3):
					img.set_pixel(xx, yy, rr[1])
	img.save_png(path)


func _init() -> void:
	var planet: int = 7
	var touch: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
		elif a.begins_with("--png="):
			pngDir = a.substr(6)
	var d: Dictionary = WorldCraters.data()
	var keep: Dictionary = d.get("struggleMeet", {}).duplicate(true)
	ok(WorldStruggleMeet.errors().is_empty(), "the block is whole: " + str(WorldStruggleMeet.errors()))
	ok(not bool(keep.get("enabled", true)) and not WorldStruggleMeet.on(), "off in the data as shipped (struggleMeet.enabled false)")
	var S := _match(planet, touch)
	var spot: Array = _cluster(S, 450.0)
	var x: float = float(spot[0])
	var z: float = float(spot[1])
	ok(int(spot[2]) >= 3, "the start has a cluster to stage in (%d buildings within 450)" % int(spot[2]))
	# off: nothing is done, byte for byte
	var h0: String = _hash(S)
	var cr0: int = S.craters.size()
	var r_off: Dictionary = WorldStruggleMeet.meet(S, _ev(S, x, z, "detonate", 5.0, 6, 6, 6, 6, true, 0.0))
	var r_ring: Dictionary = WorldStruggleMeet.ring(S, _ev(S, x, z, "detonate", 5.0, 6, 6, 6, 6, true, 0.0), 0.5)
	ok(not bool(r_off.on) and float(r_ring.r) == 0.0 and S.craters.size() == cr0 and _hash(S) == h0, "off: meet() and ring() do nothing and the state hash is as it was")
	d["struggleMeet"]["enabled"] = true
	ok(WorldStruggleMeet.on(), "on with the switch")
	# the table: Game Design's sizes by each beam's stage (docs/design/power-scale.md), through the fighters' own energies
	var rows: Array = [
		# [label, tier, power, stage, count, time, detonation, overwhelm after 1 s, sig time, sig detonation]
		["base, stage 1 of 2 each", 1, 0.0, 1, 2, 178.0, 251.0, 80.0, 533.0, 754.0],
		["base, both full", 1, 0.0, 2, 2, 251.0, 356.0, 112.0, 754.0, 1067.0],
		["tier 3 at 65%, stage 3 of 5", 3, 65.0, 3, 5, 447.0, 632.0, 200.0, 1341.0, 1896.0],
		["tier 3 at 65%, both full", 3, 65.0, 5, 5, 577.0, 816.0, 258.0, 1731.0, 2448.0],
		["maximum, stage 2 of 6", 4, 100.0, 2, 6, 508.0, 719.0, 227.0, 1524.0, 2156.0],
		["maximum, both full", 4, 100.0, 6, 6, 880.0, 1245.0, 394.0, 2640.0, 3734.0],
	]
	var tableOk: bool = true
	for row in rows:
		_level(S, int(row[1]), float(row[2]))
		var ea: float = WorldStruggleMeet.beamEnergy(S, 0, int(row[3]), int(row[4]))
		var ed: float = WorldStruggleMeet.beamEnergy(S, 1, int(row[3]), int(row[4]))
		var got: Array = [
			WorldStruggleMeet.plan(ea, ed, false, "time", 5.0, 0.0).r, WorldStruggleMeet.plan(ea, ed, false, "detonate", 5.0, 0.0).r,
			WorldStruggleMeet.plan(ea, ed, false, "overwhelmed", 1.0, 0.0).r, WorldStruggleMeet.plan(ea, ed, true, "time", 5.0, 0.0).r, WorldStruggleMeet.plan(ea, ed, true, "detonate", 5.0, 0.0).r]
		for k in range(5):
			var want: float = float(row[5 + k])
			if absf(float(got[k]) - want) > maxf(2.0, want * 0.012):
				tableOk = false
				print("      %s: column %d is %.1f, the table says %.0f" % [row[0], k, float(got[k]), want])
	ok(tableOk, "the sizes are the table's, by stage (6 rows, time / detonation / overwhelm after 1 s / with a signature, to a unit or 1.2%)")
	var pb: Dictionary = WorldStruggleMeet.plan(2.47, 2.47, false, "overwhelmed", 1.0, 0.0)
	ok(pb.kind == "scorch" and float(pb.dug) < float(keep.minE), "a base overwhelm after 1 s is a scorch only (dug %.2f under minE %.2f)" % [float(pb.dug), float(keep.minE)])
	var plow: Dictionary = WorldStruggleMeet.plan(4.94, 4.94, false, "detonate", 5.0, 0.0)
	var pmid: Dictionary = WorldStruggleMeet.plan(4.94, 4.94, false, "detonate", 5.0, float(plow.reach) * 0.5)
	var pair: Dictionary = WorldStruggleMeet.plan(4.94, 4.94, false, "detonate", 5.0, float(plow.reach) * 1.2)
	ok(absf(float(pmid.dug) - float(plow.dug) * 0.5) < 1e-9 and pair.kind == "air" and float(pair.dug) == 0.0 and float(pair.r0) == float(plow.r0), "the height cuts the energy by 1 - height / (2 x the radius): half at half the reach, an air burst past it, the glass radius unchanged")
	ok(float(WorldStruggleMeet.plan(60.5, 60.5, true, "detonate", 5.0, 0.0).r) <= WorldCrater.radiusOf(WorldCrater.SPECIAL_E_MULT * 121.0, true) + 1.0, "the biggest (two full signatures at maximum, detonating) is no bigger than a signature's own hit at the top")
	# three sizes in the world, with the stills
	var sizes: Array = [
		["small", 1, 0.0, "time", 5.0, 2, 2, false],
		["mid", 3, 65.0, "detonate", 5.0, 5, 5, false],
		["max", 4, 100.0, "detonate", 5.0, 6, 6, true],
	]
	var hashes: Array = []
	var radii: Array = []
	for sz in sizes:
		var W := _match(planet, touch)
		_level(W, int(sz[1]), float(sz[2]))
		var sp: Array = _cluster(W, 450.0)
		var px: float = float(sp[0])
		var pz: float = float(sp[1])
		# a barred landmark standing near the point, in the bowl
		var barred: int = 0
		var lm: Array = WorldSettle.data().get("landmarks", [])
		for k in range(lm.size()):
			if WorldSettle.noTarget(k + 1):
				barred = k + 1
				break
		var spared: int = -1
		for j in WorldStructures.near(W, px, 200.0):
			var b = W.buildings[j]
			if b.alive and absf(SimWrap.sdx(px, b.x)) > 20.0 and absf(float(b.z) - pz) < 60.0:
				spared = int(j)
				break
		if spared >= 0 and barred > 0:
			W.buildings[spared].landmark = barred
		var Wb := _match(planet, touch)   # the same ground before, for the strip
		var hp0: PackedFloat64Array = _hp(W)
		var ev: Dictionary = _ev(W, px, pz, String(sz[3]), float(sz[4]), int(sz[5]), int(sz[6]), int(sz[5]), int(sz[6]), bool(sz[7]), 0.0)
		var res: Dictionary = WorldStruggleMeet.meet(W, ev)
		var p: Dictionary = WorldStruggleMeet.plan(WorldStruggleMeet.beamEnergy(W, 0, int(sz[5]), int(sz[6])), WorldStruggleMeet.beamEnergy(W, 1, int(sz[5]), int(sz[6])), bool(sz[7]), String(sz[3]), float(sz[4]), 0.0)
		var rec = res.rec
		ok(res.kind == "bowl" and rec != null, "%s: a bowl is dug (kind %s)" % [sz[0], res.kind])
		if rec != null:
			ok(absf(float(rec.r) - float(p.r)) < 1.0, "%s: radius %.0f units, the model's %.0f" % [sz[0], float(rec.r), float(p.r)])
			radii.append(float(rec.r))
		var dead: int = 0
		var wrongSide: int = 0
		var untouched: int = 0
		var glassed: int = 0
		var towersIn: int = 0
		for i in range(W.buildings.size()):
			var b = W.buildings[i]
			var dd: float = SimDetMath.hypot(SimWrap.sdx(px, b.x), float(b.z) - pz)
			if hp0[i] <= 0.0:
				continue
			if not b.alive:
				dead += 1
				if dd > float(p.r):
					wrongSide += 1
			elif dd > float(p.r0) and b.hp < hp0[i] - 0.5:
				wrongSide += 1
			elif dd > float(p.r0):
				untouched += 1
			if b.alive and dd <= float(p.r0) and b.kind == "tower" and b.landmark == 0:
				towersIn += 1
				if WorldStructures.stage(b) >= 1:
					glassed += 1
		ok(dead > 0 or int(sp[2]) < 3, "%s: what stands in the bowl falls (%d down)" % [sz[0], dead])
		ok(wrongSide == 0, "%s: nothing falls past the lip and nothing is touched outside the glass radius (%d wrong, %d untouched beyond)" % [sz[0], wrongSide, untouched])
		ok(glassed == towersIn, "%s: every standing tower within the glass radius has its windows out (%d of %d)" % [sz[0], glassed, towersIn])
		if spared >= 0 and barred > 0:
			ok(W.buildings[spared].alive and absf(float(W.buildings[spared].hp) - hp0[spared]) < 0.01, "%s: a barred landmark in the bowl stands with its hit points (RL-242, RL-243)" % sz[0])
		hashes.append(_hash(W))
		if pngDir != "" and rec != null:
			DirAccess.make_dir_recursive_absolute(pngDir)
			_still(Wb, hp0, W, px, pz, float(rec.r), float(p.r0), "%s/struggle-meet-%s.png" % [pngDir, sz[0]])
		SimCore.dispose(W)
		SimCore.dispose(Wb)
	ok(radii.size() == 3 and radii[0] < radii[1] and radii[1] < radii[2], "the three sizes are in order (%s)" % str(radii))
	# an air burst: windows out, nothing falls, no bowl
	var A := _match(planet, touch)
	_level(A, 4, 100.0)
	var sp2: Array = _cluster(A, 450.0)
	var ax: float = float(sp2[0])
	var az: float = float(sp2[1])
	var pop0: float = _pop(A)
	var hpA: PackedFloat64Array = _hp(A)
	var crA: int = A.craters.size()
	var pA: Dictionary = WorldStruggleMeet.plan(WorldStruggleMeet.beamEnergy(A, 0, 6, 6), WorldStruggleMeet.beamEnergy(A, 1, 6, 6), true, "detonate", 5.0, 0.0)
	var airEv: Dictionary = _ev(A, ax, az, "detonate", 5.0, 6, 6, 6, 6, true, float(pA.reach) * 1.5)
	airEv.a.erase("stage")
	airEv.a.erase("count")
	airEv.d.erase("stage")
	airEv.d.erase("count")   # a side that does not say its stage spends all its energy (the top stage)
	var airRes: Dictionary = WorldStruggleMeet.meet(A, airEv)
	ok(absf(float(airRes.glassR) - float(pA.r0)) < 1e-6, "an event with no stage or count is the top stage of one (radius %.0f)" % float(airRes.glassR))
	var deadA: int = 0
	for i in range(A.buildings.size()):
		if hpA[i] > 0.0 and not A.buildings[i].alive:
			deadA += 1
	ok(airRes.kind == "air" and A.craters.size() == crA and deadA == 0, "an air burst: no bowl, nothing falls (%s, %d craters added, %d down)" % [airRes.kind, A.craters.size() - crA, deadA])
	ok(int(airRes.glass) > 0, "an air burst at the top: the towers' glass goes out to the radius (%d towers, radius %.0f)" % [int(airRes.glass), float(airRes.glassR)])
	ok(absf(_pop(A) - pop0) < 1e-6, "glass counts no one: the people in buildings are as they were")
	SimCore.dispose(A)
	# a scorch ending: a mark, no bowl
	var Bs := _match(planet, touch)
	_level(Bs, 1, 0.0)
	var sp3: Array = _cluster(Bs, 450.0)
	var crB: int = Bs.craters.size()
	var scRes: Dictionary = WorldStruggleMeet.meet(Bs, _ev(Bs, float(sp3[0]), float(sp3[1]), "overwhelmed", 1.0, 1, 2, 1, 2, false, 0.0))
	ok(scRes.kind == "scorch" and Bs.craters.size() == crB, "a short overwhelm at base: a scorch, no crater record (%s)" % scRes.kind)
	SimCore.dispose(Bs)
	# the ring, during
	var R0 := _match(planet, touch)
	_level(R0, 3, 65.0)
	var sp4: Array = _cluster(R0, 300.0)
	var rx: float = float(sp4[0])
	var rz: float = float(sp4[1])
	for f in R0.fighters:
		f.z = rz
	var ringBase: PackedFloat64Array = _hp(R0)
	var rev: Dictionary = _ev(R0, rx, rz, "time", 0.0, 3, 5, 3, 5, false, 60.0)
	var r1: Dictionary = WorldStruggleMeet.ring(R0, rev, 0.0)
	var bh: float = float(keep.wave.bodyHeight)
	ok(absf(float(r1.r) - float(keep.during.ringFromBh) * bh) < 1e-6, "the first ring is %.0f body height across (%.0f units)" % [float(keep.during.ringFromBh), float(r1.r)])
	var hpOne: PackedFloat64Array = _hp(R0)
	var finishedOne: int = 0
	var strayOne: int = 0
	var wornOne: int = 0
	for i in range(R0.buildings.size()):
		var b1 = R0.buildings[i]
		if ringBase[i] > 0.0 and not b1.alive:
			finishedOne += 1
		if hpOne[i] < ringBase[i] - 0.01:
			wornOne += 1
			if _ringEdge(R0, b1, rx, rz) > float(r1.r) + 0.5:
				strayOne += 1
	ok(strayOne == 0 and finishedOne == 0, "the first ring wears what is inside it (%d worn), nothing outside (%d), and finishes no standing building (%d fell)" % [wornOne, strayOne, finishedOne])
	var r3: Dictionary = WorldStruggleMeet.ring(R0, rev, 1.0)
	ok(absf(float(r3.r) - float(keep.during.ringToBh) * bh) < 1e-6, "the last ring is %.0f body heights (%.0f units)" % [float(keep.during.ringToBh), float(r3.r)])
	var hpTwo: PackedFloat64Array = _hp(R0)
	var cues: int = 0
	for e in R0.out.fx:
		if String(e.type) == "cue" and String(e.kind) == "struggle_ring":
			cues += 1
	ok(cues == 2, "each ring is a cue struggle_ring for VFX (%d)" % cues)
	var stray: int = 0
	var hurt: int = 0
	for i in range(R0.buildings.size()):
		if hpTwo[i] < ringBase[i] - 0.01:
			hurt += 1
			if _ringEdge(R0, R0.buildings[i], rx, rz) > float(r3.r) + 0.5:
				stray += 1
	ok(hurt >= wornOne and stray == 0, "the wider ring wears what is inside it and nothing outside (%d worn, %d outside)" % [hurt, stray])
	var lossOne: float = 0.0
	var lossTwo: float = 0.0
	for i in range(R0.buildings.size()):
		lossOne += ringBase[i] - hpOne[i]
		lossTwo += ringBase[i] - hpTwo[i]
	ok(lossTwo >= lossOne, "the wider ring wears at least as much (%.0f then %.0f hp in all)" % [lossOne, lossTwo])
	ok(R0.craters.size() == 0, "the struggle digs nothing while it runs (perPulse 0)")
	SimCore.dispose(R0)
	ok(WorldStruggleMeet.ringDue(-1, 100) and not WorldStruggleMeet.ringDue(100, 100 + 119) and WorldStruggleMeet.ringDue(100, 100 + 120), "at most one ring every %.0f s (the gap, in ticks)" % float(keep.during.ringMinGapSec))
	# the same setup twice
	var T := _match(planet, touch)
	_level(T, 4, 100.0)
	var spT: Array = _cluster(T, 450.0)
	WorldStruggleMeet.meet(T, _ev(T, float(spT[0]), float(spT[1]), "detonate", 5.0, 6, 6, 6, 6, true, 0.0))
	var hT: String = _hash(T)
	SimCore.dispose(T)
	var U := _match(planet, touch)
	_level(U, 4, 100.0)
	var spU: Array = _cluster(U, 450.0)
	WorldStruggleMeet.meet(U, _ev(U, float(spU[0]), float(spU[1]), "detonate", 5.0, 6, 6, 6, 6, true, 0.0))
	ok(hT == _hash(U), "the same setup gives the same state twice")
	SimCore.dispose(U)
	d["struggleMeet"]["enabled"] = false
	SimCore.dispose(S)
	print("STRUGGLEMEET: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
