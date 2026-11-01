extends SceneTree
## A field world's line and the turntable, end to end (docs/architecture/field-ground.md; World's own checks cover the field itself):
##   godot --headless --path . --script res://sim/core/tools/frame_check.gd [-- --negative-control]
## Off a field world nothing exists; the frame is the slice's line; a read's level comes from its reader; a swing turns only the ground, follows the law and is deterministic across two runs and across
## rollbacks with no node read on a re-run; frameAt is where the line ends up; poses come back from the plan at any frame; a crater in the store stays on the planet through a swing.
## --negative-control: each break must be caught.

var fails: int = 0
var checks: int = 0


func ok(c: bool, s: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  " + s)


func setup3(seed: int = 7) -> Dictionary:
	return {"planet": seed, "touch": 1, "planetGen": 3, "intro": false}


func start3(seed: int = 7) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": true, "p2": true}, setup3(seed))
	return S


func fieldOf(S: SimState):
	return WorldField.of(WorldPlanet.make(S.frame.seed))


func step(S: SimState, n: int) -> void:
	for t in range(n):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()


func _init() -> void:
	if "--negative-control" in OS.get_cmdline_user_args():
		_negative()
		print("frame_check negative control: %d of %d breaks caught" % [checks - fails, checks])
		print("PASS" if fails == 0 else "FAILED")
		quit(0 if fails == 0 else 1)
		return
	_off()
	_frameMath()
	_match()
	_swing()
	_rollback()
	_poses()
	_store()
	_bases()
	_ceilAndRush()
	_lay()
	_bothWays()
	_waterHold()
	_aimFollow()
	_layNearCheck()
	_key()
	print("frame_check: %d checks, %d failed" % [checks, fails])
	print("PASS" if fails == 0 else "FAILED")
	quit(0 if fails == 0 else 1)


func _off() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": true, "p2": true})
	ok(S.frame == null and S.swing == null and S.bX.is_empty(), "off: no frame, no swing, no poses")
	ok(not SimSwing.ask(S, {"deg": 30.0}), "off: a swing is refused")
	step(S, 60)
	ok(SimField.cur == null, "off: nothing reads the field")
	SimCore.dispose(S)
	var H := SimCore.createSim()
	SimCore.newMatch(H, 5, {"p1": true, "p2": true}, {"planet": 7, "touch": 1, "planetGen": 3, "arena": {"cols": 2400}, "intro": false})
	ok(H.frame == null, "a ring that isn't a great circle has no frame: S.base is its ground")
	step(H, 30)
	SimCore.dispose(H)


func _frameMath() -> void:
	var S := start3()
	var fr = S.frame
	ok(absf(fr.px * fr.px + fr.py * fr.py + fr.pz * fr.pz - 1.0) < 1e-12 and absf(fr.px * fr.tx + fr.py * fr.ty + fr.pz * fr.tz) < 1e-12, "frame: unit and square")
	SimField.placeAt(S, fr.x0 + 2345.0, -678.0)
	SimField.strip(S, SimField.ox, SimField.oy, SimField.oz)
	ok(absf(SimField.sx - SimWrap.wrap(fr.x0 + 2345.0)) < 1e-6 and absf(SimField.sz + 678.0) < 1e-6, "frame: strip undoes placeAt")
	# the line is the slice's: at rest the read through the frame is the laid column, but where a place or a river edits it
	var same: int = 0
	var worst: float = 0.0
	var n: int = 0
	for i in range(0, SimConst.NC, 7):
		var d: float = absf(SimField.col(S, i) - S.base[i])
		n += 1
		if d < 0.01:
			same += 1
		worst = maxf(worst, d)
	print("frame: the read against the laid strip: %d of %d the same, worst %.1f" % [same, n, worst])
	ok(float(same) / float(n) > 0.7, "frame: most columns are the laid strip's (%d of %d)" % [same, n])
	var x: float = S.fighters[0].x
	var before: float = WorldTerrain.groundY(S, x)
	SimField.far()
	var coarse: float = WorldTerrain.groundY(S, x)
	SimField.near()
	ok(WorldTerrain.groundY(S, x) == before, "level: a far read leaves a near read alone")
	ok(is_finite(coarse), "level: the bake reads")
	ok(WorldTerrain.baseAt(S, 1200) == SimField.col(S, 1200), "baseAt reads the line")
	SimCore.dispose(S)


func _run(mode: int, ticks: int) -> Dictionary:
	var S := start3()
	var log_ := []
	var swings: int = 0
	var worstMs: int = 0
	for t in range(ticks):
		if mode == 1 and t % 300 == 120:
			if SimSwing.ask(S, {"deg": 40.0 if (t / 300) % 2 == 0 else -40.0, "rate": 60.0, "cause": "launch"}):
				swings += 1
		step(S, 1)
		if t % 120 == 0:
			log_.append(SimHash.stateHash(S).gameplay)
	var r := {"hash": SimHash.stateHash(S).gameplay, "log": log_, "swings": swings, "frame": [S.frame.px, S.frame.py, S.frame.pz, S.frame.tx, S.frame.ty, S.frame.tz, S.frame.x0]}
	SimCore.dispose(S)
	return r


func _match() -> void:
	var a: Dictionary = _run(0, 600)
	var b: Dictionary = _run(0, 600)
	ok(a.hash == b.hash, "match: two runs, the same state")
	var S := SimCore.createSim()
	var rec := SimReplay.recorder(S, 77, {"p1": true, "p2": true}, setup3())
	for t in range(400):
		rec.step(null)
		S.out.fx.clear()
		S.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(S)
	var r: Dictionary = SimReplay.play(rp)
	ok(r.ok, "replay: a field match plays back (%s at %d)" % [r.reason, r.firstBadTick])
	var bad: Dictionary = rp.duplicate(true)
	bad.setup.planet = 3
	ok(SimReplay.play(bad).reason == "data", "replay: another planet's field is refused as data")


func _swing() -> void:
	var a: Dictionary = _run(1, 1200)
	var b: Dictionary = _run(1, 1200)
	ok(a.swings >= 3, "swing: asked (%d)" % a.swings)
	print("frame_check digest %s" % a.hash)   # two processes, or native and web, print the same
	ok(a.hash == b.hash and a.log == b.log, "swing: two runs, the same state tick by tick")
	var plain: Dictionary = _run(0, 1200)
	ok(a.frame != plain.frame, "swing: the line turned")
	# the law, on a staged pair: the frame turns by the rate, the fighters don't move for it, and the bearing is reached
	var S := start3()
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f1.x = f0.x + 150.0
	f0.y = 3000.0   # both in the air: only the governor and the size ceiling
	f1.y = 3000.0
	var fr0 = S.frame.copy()
	ok(SimSwing.ask(S, {"deg": 30.0, "rate": 60.0, "cause": "launch"}), "swing: an ask runs")
	var view := SimFxView.new()
	view.consume(S, S.out.fx)   # the view passes the swing's events: an unknown one prints "consume: unknown event" (the runner fails on it)
	S.out.fx.clear()
	var ahead = SimSwing.frameAt(S, 100000)
	var rateMax: float = 0.0
	var stepMax: float = 0.0
	var last: float = 0.0
	var t: int = 0
	var moved: bool = false
	while S.swing.active and t < 2000:
		var x0: float = f0.x
		SimSwing.tick(S)
		rateMax = maxf(rateMax, S.swing.rate)
		stepMax = maxf(stepMax, absf(S.swing.rate - last))
		last = S.swing.rate
		moved = moved or f0.x != x0
		S.tick += 1
		t += 1
	ok(not moved, "swing: a tick doesn't move a fighter")
	ok(not S.swing.active and rateMax <= 60.0 + 1e-9, "swing: rests, under the governor (%.1f)" % rateMax)
	ok(stepMax <= 9.0 + 1e-6, "swing: the rate only eases (the most a tick changes it: %.2f; a 10-tick smoothstep way out from 60 is at most 9)" % stepMax)
	ok(absf(S.swing.left) == 0.0, "swing: nothing left at rest")
	ok(absf(S.frame.px * S.frame.px + S.frame.py * S.frame.py + S.frame.pz * S.frame.pz - 1.0) < 1e-12, "swing: still on the sphere")
	var n0: Array = [fr0.ty * fr0.pz - fr0.tz * fr0.py, fr0.tz * fr0.px - fr0.tx * fr0.pz, fr0.tx * fr0.py - fr0.ty * fr0.px]
	var fe = S.frame
	var cosT: float = n0[0] * (fe.ty * fe.pz - fe.tz * fe.py) + n0[1] * (fe.tz * fe.px - fe.tx * fe.pz) + n0[2] * (fe.tx * fe.py - fe.ty * fe.px)   # the angle between the two great circles' axes: where x0 stands doesn't change it
	print("swing: 30 asked, turned %.2f in %d ticks; peak %.1f" % [acos(clampf(cosT, -1.0, 1.0)) * 180.0 / 3.14159265, t, rateMax])
	ok(absf(acos(clampf(cosT, -1.0, 1.0)) * 180.0 / 3.14159265 - 30.0) < 1e-6, "swing: exactly the bearing asked")
	var gap: float = absf(ahead.tx - S.frame.tx) + absf(ahead.ty - S.frame.ty) + absf(ahead.tz - S.frame.tz)
	ok(gap < 1e-9, "frameAt: the asked curve's end is where a free swing ends (gap %.12f)" % gap)
	# frozen, it isn't turning, whatever its numbers say
	var S9 := start3()
	for f in S9.fighters:
		f.y = 3000.0
	SimSwing.ask(S9, {"deg": 30.0, "cause": "launch"})
	ok(SimSwing.movingNow(S9), "movingNow: running")
	S9.dirS.stop = 0.5
	ok(not SimSwing.movingNow(S9), "movingNow: not in a hit-stop")
	S9.dirS.stop = 0.0
	SimCore.dispose(S9)
	# the sign: above 0 turns the heading toward the camera, heading x point
	var S0 := start3()
	var f1a = S0.frame.copy()
	for f in S0.fighters:
		f.y = 3000.0
	SimSwing.ask(S0, {"deg": 10.0, "rate": 60.0, "cause": "launch", "pivotX": S0.frame.x0})
	ok(S0.swing.left == 10.0, "swing: left is signed as asked")
	for k in range(4):
		SimSwing.tick(S0)
		S0.tick += 1
	var sdx0: float = f1a.ty * f1a.pz - f1a.tz * f1a.py
	var sdy0: float = f1a.tz * f1a.px - f1a.tx * f1a.pz
	var sdz0: float = f1a.tx * f1a.py - f1a.ty * f1a.px
	ok(S0.frame.tx * sdx0 + S0.frame.ty * sdy0 + S0.frame.tz * sdz0 > 0.0, "swing: a positive deg turns the heading toward heading x point")
	ok(S0.swing.left > 0.0 and S0.swing.left < 10.0, "swing: left falls toward 0 with its sign")
	SimCore.dispose(S0)
	var S4 := start3()
	for f in S4.fighters:
		f.y = 3000.0
	SimSwing.ask(S4, {"deg": -10.0, "rate": 60.0, "cause": "launch"})
	SimSwing.tick(S4)
	ok(S4.swing.left < 0.0, "swing: a negative ask's left is negative")
	SimCore.dispose(S4)
	# Game Design's small class: a blow's 15 degrees at the governor, 45 ticks; without, 28
	var S5 := start3()
	for f in S5.fighters:
		f.y = 3000.0
	SimSwing.ask(S5, {"deg": 15.0, "cause": "small", "blow": true})
	ok(absf(S5.swing.ticks - 45.0) < 1e-9, "small: a blow's 15 degrees take 45 ticks (%.2f)" % S5.swing.ticks)
	SimSwing.ask(S5, {"deg": 15.0, "cause": "small"})
	ok(absf(S5.swing.ticks - 28.125) < 1e-9, "small: 15 degrees without a blow take 28 ticks (%.2f)" % S5.swing.ticks)
	SimSwing.ask(S5, {"deg": 90.0, "cause": "launch"})
	for k in range(30):
		SimSwing.tick(S5)
		S5.tick += 1
	var r5: float = S5.swing.rate
	SimSwing.rest(S5, 12)
	ok(r5 > 50.0, "rest: from a running rate (%.1f)" % r5)
	ok(S5.swing.active, "rest: still running")
	var t5: int = 0
	while S5.swing.active and t5 < 100:
		SimSwing.tick(S5)
		S5.tick += 1
		t5 += 1
	ok(t5 == 12 or t5 == 13, "rest: at rest in the ticks asked (%d)" % t5)
	# a reversal eases: the rate never jumps, and it passes through rest before the new way
	var S6 := start3()
	for f in S6.fighters:
		f.y = 3000.0
	SimSwing.ask(S6, {"deg": 60.0, "cause": "launch"})
	for k in range(30):
		SimSwing.tick(S6)
		S6.tick += 1
	ok(S6.swing.rate > 50.0, "reversal: running first (%.1f)" % S6.swing.rate)
	ok(SimSwing.ask(S6, {"deg": -20.0, "cause": "launch"}), "reversal: asked")
	var step6: float = 0.0
	var last6: float = S6.swing.rate * S6.swing.way
	var rested: bool = false
	var t6: int = 0
	while t6 < 400 and (S6.swing.active or not rested):
		SimSwing.tick(S6)
		S6.tick += 1
		t6 += 1
		var now6: float = S6.swing.rate * S6.swing.way
		step6 = maxf(step6, absf(now6 - last6))
		rested = rested or S6.swing.rate == 0.0 or (last6 > 0.0 and S6.swing.way < 0.0)
		last6 = now6
	ok(step6 <= 9.0 + 1e-6, "reversal: the signed rate never jumps (the most in a tick: %.2f)" % step6)
	ok(S6.swing.way < 0.0 and not S6.swing.active, "reversal: it ran the new way to rest")
	# a higher cause on a running swing, the same way: its ramp starts from the rate it's at
	SimSwing.ask(S6, {"deg": 40.0, "cause": "brawl"})
	for k in range(40):
		SimSwing.tick(S6)
		S6.tick += 1
	var r6: float = S6.swing.rate
	SimSwing.ask(S6, {"deg": 60.0, "cause": "launch"})
	SimSwing.tick(S6)
	S6.tick += 1
	ok(absf(S6.swing.rate - r6) < 1.0, "a swing taken over the same way: no jump (%.2f to %.2f)" % [r6, S6.swing.rate])
	var a6 = SimSwing.frameAt(S6, 100000)
	var e6: int = 0
	while S6.swing.active and e6 < 2000:
		SimSwing.tick(S6)
		S6.tick += 1
		e6 += 1
	var g6: float = absf(a6.tx - S6.frame.tx) + absf(a6.ty - S6.frame.ty) + absf(a6.tz - S6.frame.tz)
	ok(g6 < 1e-9, "frameAt: from a running rate too (gap %.12f)" % g6)
	SimCore.dispose(S6)
	# the motion setting: off refuses, slow caps, the strongest of two wins
	var S7 := SimCore.createSim()
	var su7: Dictionary = setup3()
	su7["swing"] = "off"
	SimCore.newMatch(S7, 77, {"p1": true, "p2": true}, su7)
	ok(S7.swing.motion == "off" and not SimSwing.ask(S7, {"deg": 30.0, "cause": "launch"}), "motion: off refuses every swing")
	su7["swing"] = "slow"
	SimCore.newMatch(S7, 77, {"p1": true, "p2": true}, su7)
	for f in S7.fighters:
		f.y = 3000.0
	SimSwing.ask(S7, {"deg": 60.0, "cause": "launch"})
	var r7: float = 0.0
	for k in range(60):
		SimSwing.tick(S7)
		S7.tick += 1
		r7 = maxf(r7, S7.swing.rate)
	ok(r7 > 29.0 and r7 <= 30.0 + 1e-9, "motion: slow caps at 30 (%.2f)" % r7)
	ok(SimSwing.strongest("full", "slow") == "slow" and SimSwing.strongest("slow", "off") == "off" and SimSwing.strongest("full", "full") == "full", "motion: the strongest of two")
	SimCore.dispose(S7)
	# restBy gives way: a 180 asked with 1.75 s of flight turns what fits
	SimSwing.ask(S5, {"deg": 180.0, "cause": "launch", "restBy": 105})
	ok(absf(S5.swing.deg - SimSwing.mostFor(1.75)) < 1e-9 and S5.swing.ticks <= 105.0 + 1e-9, "restBy: the angle gives way (%.2f in %.1f ticks)" % [S5.swing.deg, S5.swing.ticks])
	var fr5 = S5.frame.copy()
	var want5: float = S5.swing.deg
	var e5: int = 0
	while S5.swing.active and e5 < 400:
		SimSwing.tick(S5)
		S5.tick += 1
		e5 += 1
	var c5: float = (fr5.ty * fr5.pz - fr5.tz * fr5.py) * (S5.frame.ty * S5.frame.pz - S5.frame.tz * S5.frame.py) + (fr5.tz * fr5.px - fr5.tx * fr5.pz) * (S5.frame.tz * S5.frame.px - S5.frame.tx * S5.frame.pz) + (fr5.tx * fr5.py - fr5.ty * fr5.px) * (S5.frame.tx * S5.frame.py - S5.frame.ty * S5.frame.px)
	var got5: float = acos(clampf(c5, -1.0, 1.0)) * 180.0 / 3.14159265
	ok(e5 <= 105 and e5 >= 100, "restBy: at rest by the tick asked (%d of 105)" % e5)
	ok(absf(got5 - want5) < 1e-6, "restBy: a plan that ends on its tick isn't cancelled: it turns all of it (%.3f of %.3f)" % [got5, want5])
	SimCore.dispose(S5)
	SimCore.dispose(S)
	# a standing pair far apart: the limit slows it
	var S2 := start3()
	S2.fighters[1].x = S2.fighters[0].x + 6000.0
	for f in S2.fighters:
		f.y = WorldTerrain.groundY(S2, f.x, f.z)
	SimSwing.ask(S2, {"deg": 30.0, "rate": 60.0, "cause": "chase"})
	var peak2: float = 0.0
	for k in range(60):
		SimSwing.tick(S2)
		S2.tick += 1
		peak2 = maxf(peak2, S2.swing.rate)
		for f in S2.fighters:
			f.y = WorldTerrain.groundY(S2, f.x, f.z)
	ok(peak2 <= 75.0 / 3000.0 * 180.0 / 3.14159265 + 1e-6 and peak2 > 0.0, "swing: the standing limit (%.3f deg/s at 3000)" % peak2)
	var clamped0: int = S2.swing.clamps
	ok(clamped0 >= 0, "swing: clamps count")
	S2.beams.append(SimState.Beam.new())
	ok(not SimSwing.ask(S2, {"deg": 10.0, "rate": 60.0}), "swing: refused in a beam")
	for k in range(40):
		SimSwing.tick(S2)
		S2.tick += 1
	ok(not S2.swing.active, "swing: a beam rests a running one")
	S2.beams.clear()
	SimCore.dispose(S2)
	# a fighter coming down mid-swing: the law at once, no ease (Game Design 11)
	var S3 := start3()
	var g0 = S3.fighters[0]
	var g1 = S3.fighters[1]
	g1.x = g0.x + 8000.0
	g0.y = 4000.0
	g1.y = 4000.0
	SimSwing.ask(S3, {"deg": 90.0, "rate": 60.0, "cause": "launch"})
	for k in range(40):
		SimSwing.tick(S3)
		S3.tick += 1
	var high: float = S3.swing.rate
	g0.y = WorldTerrain.groundY(S3, g0.x)
	g1.y = WorldTerrain.groundY(S3, g1.x)
	SimSwing.tick(S3)
	print("swing: an early landing: %.1f to %.2f deg/s in one tick" % [high, S3.swing.rate])
	ok(S3.swing.rate <= 75.0 / 4000.0 * 180.0 / 3.14159265 + 1e-6 and S3.swing.clamps >= 1, "swing: an early landing clamps at once")
	SimCore.dispose(S3)


func _rollback() -> void:
	var S := start3()
	step(S, 240)
	ok(SimSwing.ask(S, {"deg": 60.0, "rate": 60.0, "cause": "launch"}), "rollback: a swing runs")
	step(S, 10)
	var snap: NetSnapshot = NetSnapshot.take(S)
	var fwd: Array = []
	for t in range(21):
		step(S, 1)
		fwd.append(SimHash.stateHash(S).gameplay)
	var F = fieldOf(S)
	var r0: int = F.reads + F.subReads
	for rep in range(3):
		NetSnapshot.restore(S, snap)
		for t in range(21):
			step(S, 1)
			ok(SimHash.stateHash(S).gameplay == fwd[t], "rollback: re-run %d, tick %d, the same state" % [rep, t])
	ok(F.reads + F.subReads == r0, "rollback: a re-run reads no node (%d)" % (F.reads + F.subReads - r0))
	SimCore.dispose(S)


func _poses() -> void:
	var S := start3()
	# World's buildings: bound by their planet points, each pose at the first frame is the plan's
	var worstX: float = 0.0
	var worstZ: float = 0.0
	ok(S.bDir.size() == S.buildings.size() * 3 and S.bX.size() == S.buildings.size(), "poses: every building of the match has its point (%d)" % S.buildings.size())
	for i in range(S.buildings.size()):
		worstX = maxf(worstX, absf(SimWrap.sdx(S.bX[i], S.buildings[i].g.x)))
		worstZ = maxf(worstZ, absf(S.bZ[i] - S.buildings[i].g.z))
	print("poses: at the first frame, against the laid plan: worst x %.3f, z %.3f" % [worstX, worstZ])
	ok(worstX < 2.0 and worstZ < 2.0, "poses: a building stands where it was laid (worst x %.3f, z %.3f)" % [worstX, worstZ])
	var bs: Array = []
	for k in range(2):
		var b := SimState.Building.new()
		b.x = S.fighters[0].x + 900.0 * float(k + 1)
		b.z = -300.0
		b.w = 100.0; b.d = 100.0; b.h = 200.0; b.maxhp = 100.0; b.hp = 100.0; b.floors = 3; b.fmask = 7; b.kind = "tower"; b.alive = true
		bs.append(b)
	S.buildings = bs
	S.bDir = PackedFloat64Array()
	WorldStructures.buildIndex(S)
	S.bindStructures()
	var b0 = S.buildings[0]
	var x0: float = bs[0].g.x
	ok(S.bX.size() == 2 and absf(b0.x - x0) < 1e-6 and absf(b0.z + 300.0) < 1e-6, "poses: at the first frame, the plan (%.3f, %.3f)" % [b0.x, b0.z])
	for f in S.fighters:
		f.y = 3000.0
	SimSwing.ask(S, {"deg": 30.0, "rate": 60.0, "cause": "launch"})
	var t: int = 0
	while S.swing.active and t < 2000:
		SimSwing.tick(S)
		S.tick += 1
		t += 1
	ok(absf(b0.z + 300.0) > 50.0, "poses: a swing moved a building's depth (%.1f)" % b0.z)
	ok(b0.g.z == -300.0, "poses: the plan didn't change")
	ok(b0.idx == 0 and S.buildings[1].idx == 1, "poses: slots don't move")
	var found: bool = false
	for i in WorldStructures.near(S, b0.x, 50.0):
		found = found or i == 0
	ok(found, "poses: the index finds it where it now is")
	var inc: Array = S.bIdx.map(func(q): return Array(q))
	WorldStructures.buildIndex(S)
	ok(inc == S.bIdx.map(func(q): return Array(q)), "poses: the moved index is the whole rebuild's, bucket by bucket")
	# the planet point is fixed: its direction is the same read through the frame now
	SimField.placeAt(S, b0.x, b0.z)
	var dq: float = absf(SimField.ox - S.bDir[0]) + absf(SimField.oy - S.bDir[1]) + absf(SimField.oz - S.bDir[2])
	ok(dq < 1e-9, "poses: a pose is its planet point through the frame (%.12f)" % dq)
	# a building swinging into reach is found by its planet point, and a sent body far from the pivot poses what it meets
	var S8 := start3()
	var bs8: Array = []
	var fx0: float = S8.fighters[0].x
	var b8 := SimState.Building.new()
	b8.x = SimWrap.wrap(fx0 + 12000.0)
	b8.z = -300.0
	b8.w = 100.0; b8.d = 100.0; b8.h = 200.0; b8.maxhp = 100.0; b8.hp = 100.0; b8.floors = 3; b8.fmask = 7; b8.kind = "tower"; b8.alive = true
	bs8.append(b8)
	S8.buildings = bs8
	S8.bDir = PackedFloat64Array()
	S8.bX = PackedFloat64Array()
	WorldStructures.buildIndex(S8)
	S8.bindStructures()
	S8.fighters[0].y = 6000.0
	S8.fighters[1].x = SimWrap.wrap(fx0 + 150.0)
	S8.fighters[1].y = 6000.0
	var bb8 = S8.buildings[0]
	var x80: float = bb8.x
	SimSwing.ask(S8, {"deg": 40.0, "cause": "launch", "pivotX": fx0})
	for k in range(10):
		SimSwing.tick(S8)
		S8.tick += 1
	ok(bb8.x == x80, "reach: a building 12,000 from the pivot and the pair isn't posed mid-swing")
	S8.fighters[1].x = SimWrap.wrap(bb8.x + 800.0)   # the sent body arrives near it, far from the pivot
	for k in range(9):
		SimSwing.tick(S8)
		S8.tick += 1
	SimField.placeAt(S8, bb8.x, bb8.z)
	var dq8: float = absf(SimField.ox - S8.bDir[0]) + absf(SimField.oy - S8.bDir[1]) + absf(SimField.oz - S8.bDir[2])
	ok(bb8.x != x80 and dq8 < 1e-9, "reach: a sent body far from the pivot poses the building it's near (%.12f)" % dq8)
	SimCore.dispose(S8)
	var snap: NetSnapshot = NetSnapshot.take(S)
	var x1: float = b0.x
	SimSwing.ask(S, {"deg": 20.0, "rate": 60.0, "cause": "launch"})
	t = 0
	while S.swing.active and t < 2000:
		SimSwing.tick(S)
		S.tick += 1
		t += 1
	ok(b0.x != x1, "poses: a second swing moved it")
	NetSnapshot.restore(S, snap)
	ok(S.buildings[0].x == x1, "poses: a restore brings the pose back")
	SimCore.dispose(S)


## A building's base is its own point's ground, its pad's, and a swing doesn't move it.
func _bases() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": true, "p2": true}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	var worst: float = 0.0
	var off: int = 0
	var n: int = mini(S.buildings.size(), 200)
	var b0: Array = []
	for i in range(n):
		b0.append(WorldStructures.baseY(S, S.buildings[i]))
	var lineOff: int = 0
	for i in range(n):
		var line: float = -1.0e9
		var b = S.buildings[i]
		line = WorldTerrain.groundY(S, b.x)
		if absf(line - float(b0[i])) > 50.0:
			lineOff += 1
	print("bases: %d of %d buildings stand more than 50 units from the line's ground under them" % [lineOff, n])
	for f in S.fighters:
		f.y = 6000.0
	SimSwing.ask(S, {"deg": 30.0, "cause": "launch"})
	var t: int = 0
	while S.swing.active and t < 400:
		SimSwing.tick(S)
		S.tick += 1
		t += 1
	for i in range(n):
		var d: float = absf(WorldStructures.baseY(S, S.buildings[i]) - float(b0[i]))
		worst = maxf(worst, d)
		if d > 0.001:
			off += 1
	ok(off == 0, "bases: a swing doesn't move a building's base (%d off, worst %.3f)" % [off, worst])
	var snap: NetSnapshot = NetSnapshot.take(S)
	var i0: int = n / 2
	var b1 = S.buildings[i0]
	var before: float = WorldStructures.baseY(S, b1)
	SimField.placeAt(S, b1.x, b1.z)
	ok(WorldStore.add(S, S.bDir[i0 * 3], S.bDir[i0 * 3 + 1], S.bDir[i0 * 3 + 2], 300.0, 60.0, 0.0, 1.0, 0, 0, 0.0, 0) >= 0, "bases: a crater at its foot")
	ok(WorldStructures.baseY(S, b1) < before - 10.0, "bases: a crater under a building lowers its base (%.1f to %.1f)" % [before, WorldStructures.baseY(S, b1)])
	NetSnapshot.restore(S, snap)
	ok(WorldStructures.baseY(S, b1) == before, "bases: and a restore brings it back")
	SimCore.dispose(S)


## A rush rides over the ground, and the stretch's ceiling holds over a real fight's every column, ground and sea.
func _ceilAndRush() -> void:
	var off := SimCore.createSim()
	SimCore.newMatch(off, 5, {"p1": true, "p2": true})
	ok(SimField.groundCeilAt(off, 100) == INF, "ceil: infinity off a field world")
	SimCore.dispose(off)
	for row in [[3, 2, 22], [7, 2, 11]]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, row[2], {"p1": true, "p2": true}, {"planet": row[0], "touch": row[1], "planetGen": 3, "intro": false})
		var under: int = 0
		var bad: int = 0
		var margin: float = 1.0e18
		var n: int = int(SimField.data().ceilCols)
		var t0: int = Time.get_ticks_usec()
		SimField.groundCeilAt(S, 1000)
		var us: int = Time.get_ticks_usec() - t0
		for t in range(3600):
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
			for f in S.fighters:
				if f.rush != null and f.y < WorldTerrain.groundY(S, f.x, f.z) - 1.0:
					under += 1
			if t % 400 == 399:
				var c0: int = 0
				while c0 < SimConst.NC:
					var c: float = SimField.groundCeilAt(S, c0 + 17)
					SimField.far()
					for k in range(0, n, 3):
						var x: float = float(c0 + k) * SimConst.COL + 11.0
						var g: float = WorldTerrain.groundY(S, x)
						var sea: float = WorldWater.seaTop(S, x)
						var flo: float = WorldWater.floorAt(S, x)
						var top: float = maxf(maxf(g, flo), sea if sea != WorldWater.NO_SEA else g)
						margin = minf(margin, c - top)
						if top > c:
							bad += 1
					SimField.near()
					c0 += n * 3
			if S.game.ko != null:
				break
		print("ceil: planet %d, about %d us a call; the closest a read came under it: %.2f" % [row[0], us, margin])
		ok(bad == 0, "ceil: no far ground, floor or sea over its stretch's bound (%d, closest %.2f)" % [bad, margin])
		ok(under == 0, "rush: never under the ground on a field world (%d ticks)" % under)
		SimCore.dispose(S)
	# a plan's pass: a building near is posed in the plan's frame and put back after; a building far keeps its pose
	var P := start3()
	for f in P.fighters:
		f.y = 3000.0
	var bs: Array = []
	var fx0: float = P.fighters[0].x
	for dx in [900.0, 30000.0]:
		var b := SimState.Building.new()
		b.x = SimWrap.wrap(fx0 + dx)
		b.z = -300.0
		b.w = 100.0; b.d = 100.0; b.h = 200.0; b.maxhp = 100.0; b.hp = 100.0; b.floors = 3; b.fmask = 7; b.kind = "tower"; b.alive = true
		bs.append(b)
	P.buildings = bs
	P.bX = PackedFloat64Array()
	WorldStructures.buildIndex(P)
	P.bindStructures()
	var nearB = P.buildings[0]
	var farB = P.buildings[1]
	var x0: float = nearB.z
	var xf: float = farB.z
	SimSwing.ask(P, {"deg": 30.0, "cause": "launch", "pivotX": fx0})
	var was = P.frame
	P.frame = SimSwing.frameAt(P, 1000)
	var list: PackedInt32Array = SimSwing.posesNear(P, fx0)
	ok(list.size() == 1 and list[0] == 0, "plan: the near building, not the far (%d)" % list.size())
	ok(nearB.z != x0 and farB.z == xf, "plan: it's posed in the plan's frame, and the far one keeps its pose")
	P.frame = was
	SimSwing.posesOf(P, list)
	ok(absf(nearB.z - x0) < 1e-6, "plan: and it's put back when the frame comes back (%.6f)" % (nearB.z - x0))
	SimCore.dispose(P)


## Camera's case: the same swing each way on the same ground takes the same ticks, a standing fighter stays on his floor down as well as up, and the rate holds to the law on the way out.
func _bothWays() -> void:
	var ticks_: Array = []
	for way in [40.0, -40.0, 40.0, -40.0]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 77, {"p1": false, "p2": false}, {"planet": 7, "touch": 1, "planetGen": 3, "intro": false})
		for t in range(5):
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
		var a = S.fighters[0]
		var b = S.fighters[1]
		SimSwing.ask(S, {"deg": way, "cause": "launch"})
		var n: int = 0
		var off: float = 0.0
		var over: float = 0.0
		while S.swing.active and n < 3000:
			var lim: float = SimSwing._limit(S, SimSwing._pivot(S))
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
			n += 1
			off = maxf(off, absf(a.y - SimFighter.floorFor(S, a, a.x, a.z)))
			off = maxf(off, absf(b.y - SimFighter.floorFor(S, b, b.x, b.z)))
			over = maxf(over, S.swing.rate - lim)
		ticks_.append(n)
		ok(off <= 1.0, "both ways: %+d: standing, he stays on his floor (%.2f off)" % [int(way), off])
		ok(over <= 0.01, "both ways: %+d: the rate holds to the law at each tick (%.4f deg/s over at most)" % [int(way), over])
		SimCore.dispose(S)
	print("both ways: %s ticks" % str(ticks_))
	ok(ticks_[0] == ticks_[1] and ticks_[1] == ticks_[2] and ticks_[2] == ticks_[3], "both ways: the same ticks each way (%s)" % str(ticks_))


## Water's flow waits while the line turns and for `waterWarm` ticks after, and as long again when a window opens wide. Then it flows. The wait is in the state, and it doesn't depend on what the cache holds.
func _waterHold() -> void:
	var W: int = int(ceil(121.0 / float(SimSwing.data().waterWarmCols)))   # the window below has 121 columns
	var hashes: Array = []
	for run in range(2):
		var S := start3()
		var stepN := func(n: int) -> void:
			for t in range(n):
				SimCore.step(S)
				S.out.fx.clear()
				S.out.feed.clear()
		for f in S.fighters:
			f.y = 3000.0
		var c: int = int(S.fighters[0].x / SimConst.COL)
		while WorldTerrain.baseAt(S, c) < WorldWater.SEA_LEVEL + 100.0:
			c = (c + 16) % SimConst.NC
		for k in range(-20, 21):
			S.deform[c + k] = -WorldTerrain.baseAt(S, c + k) - 500.0   # a hole for it to flow into
		S.water[c] = 4000.0
		S.waterWin.append([c, 60, 0, 0])
		var w0: PackedFloat32Array = S.water.duplicate()
		stepN.call(W)
		ok(S.water == w0, "water hold: a wide new window waits %d ticks" % W)
		ok(S.swing.waterWarm == 0, "water hold: its wait is done (%d)" % S.swing.waterWarm)
		stepN.call(WorldWater.STEP_TICKS + 1)
		ok(S.water != w0, "water hold: then it flows")
		SimSwing.ask(S, {"deg": 30.0, "cause": "launch"})
		var w1: PackedFloat32Array = S.water.duplicate()
		var same: bool = true
		var n: int = 0
		var worst: int = 0
		var F = SimField._F
		while S.swing.active and n < 800:
			stepN.call(1)
			same = same and S.water == w1
			n += 1
		ok(n > 0 and n < 800 and same, "water hold: no flow in the %d ticks the line turns" % n)
		ok(S.swing.waterWarm > 0, "water hold: at rest the columns are read before it flows (%d)" % S.swing.waterWarm)
		var left: int = int(ceil(float(S.swing.waterWarm) / float(SimSwing.data().waterWarmCols)))
		for t in range(left):
			var r0: int = F.reads + F.subReads
			stepN.call(1)
			worst = maxi(worst, F.reads + F.subReads - r0)
			same = same and S.water == w1
		ok(same, "water hold: no flow in the %d ticks it reads" % left)
		if run == 0:
			print("water hold: %d ticks turning, worst reads in a tick of the warm-up %d" % [n, worst])
		var r1: int = F.reads + F.subReads
		stepN.call(WorldWater.STEP_TICKS + 1)
		ok(S.water != w1, "water hold: after the rest it flows again")
		ok(F.reads + F.subReads - r1 <= 40, "water hold: the flow step finds its columns read (%d new)" % (F.reads + F.subReads - r1))
		hashes.append(SimHash.stateHash(S).gameplay)
		var h0: String = SimHash.stateHash(S).gameplay
		S.swing.waterWarm += 1
		ok(SimHash.stateHash(S).gameplay != h0, "water hold: the wait is in the hash")
		SimCore.dispose(S)
	ok(hashes[0] == hashes[1], "water hold: a warm cache gives the same state as a colder one")


## A flight aimed at a building meets its face in depth, though a swing moved it in flight.
func _aimFollow() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": true, "p2": true}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	var f = S.fighters[0]
	for g in S.fighters:
		g.y = 3000.0
	var best: int = -1
	for i in range(S.buildings.size()):
		var d: float = absf(SimWrap.sdx(f.x, S.buildings[i].x))
		if S.buildings[i].alive and d > 800.0 and d < 6000.0 and (best < 0 or d < absf(SimWrap.sdx(f.x, S.buildings[best].x))):
			best = i
	ok(best >= 0, "aim: a building to aim at")
	if best < 0:
		return
	var b = S.buildings[best]
	var dir: float = signf(SimWrap.sdx(f.x, b.x))
	f.state = "launched"
	f.vx = dir
	f.aimB = best
	f.aimX0 = f.x
	f.aimZ0 = f.z
	f.aimZ1 = WorldBrunt.faceZ(b)
	f.aimD = absf(SimWrap.sdx(f.x, b.x - dir * b.w * 0.5))
	var z1: float = f.aimZ1
	SimSwing.ask(S, {"deg": 30.0, "cause": "launch", "pivotX": f.x})
	var at: int = 0
	var arrived: bool = false
	while at < 300 and not arrived:
		SimSwing.tick(S)
		S.tick += 1
		at += 1
		var edge: float = SimWrap.wrap(b.x - dir * b.w * 0.5)
		var togo: float = SimWrap.sdx(f.x, edge) * dir
		f.x = SimWrap.wrap(f.x + dir * clampf(togo, 0.0, 30.0))
		WorldBrunt.stepZ(S, f, 1.0 / 60.0)
		arrived = togo <= 30.0
	var moved: float = absf(WorldBrunt.faceZ(b) - z1)
	ok(arrived and moved > 50.0, "aim: the swing moved its face in depth (%.0f units, %d ticks)" % [moved, at])
	ok(absf(f.z - WorldBrunt.faceZ(b)) < 1.0, "aim: the body meets its face in depth (%.1f off)" % absf(f.z - WorldBrunt.faceZ(b)))
	SimCore.dispose(S)


## While the line turns, a scar near the pair keeps to its record under the line: on the last moving tick the strip already says what the rest would lay.
func _layNearCheck() -> void:
	var S := start3()
	for f in S.fighters:
		f.y = 3000.0
	var fx: float = S.fighters[0].x
	S.fighters[1].x = fx
	for k in range(-12, 13):
		SimField.pointAt(S, fx + 480.0 + float(k) * 16.0)
		WorldStore.addScorch(S, [SimField.ox, SimField.oy, SimField.oz], 60.0, 10.0, 0.9, 0.0, 0)
	var fr0 = S.frame
	WorldStore.layScorch(S, func(xx: float) -> Array:
		SimField.pointIn(fr0, xx)
		return [SimField.ox, SimField.oy, SimField.oz])
	SimSwing.ask(S, {"deg": 12.0, "cause": "launch", "pivotX": fx})
	var cost: int = 0
	var worst: int = 0
	var n: int = 0
	var wrong: int = 0
	var was: int = 0
	var ridden: PackedFloat32Array = S.scorch.duplicate()
	while S.swing.active and n < 400:
		var t0: int = Time.get_ticks_usec()
		SimSwing.tick(S)
		var dt: int = Time.get_ticks_usec() - t0
		cost += dt
		worst = maxi(worst, dt)
		S.tick += 1
		n += 1
		if S.swing.active and S.swing.left < 0.3:
			wrong = 0
			was = 0
			var c0: int = int(floor(SimWrap.wrap(fx) / SimConst.COL))
			for q in range(-int(SimSwing.data().layNearCols), int(SimSwing.data().layNearCols) + 1):
				var c: int = posmod(c0 + q, SimConst.NC)
				SimField.pointIn(S.frame, (float(c) + 0.5) * SimConst.COL)
				var tv: float = WorldStore.scorchAt(S, SimField.ox, SimField.oy, SimField.oz)[0]
				if absf(S.scorch[c] - tv) > 0.3:
					wrong += 1
				if absf(ridden[c] - tv) > 0.3:
					was += 1
	print("lay near: %d ticks, mean %d us a tick, worst %d us; wrong columns at the end %d, %d if it had ridden" % [n, cost / maxi(n, 1), worst, wrong, was])
	ok(S.swing.layNearOn, "lay near: a scar near the pair turns it on")
	ok(wrong <= 2, "lay near: the marks near the pair keep to the records (%d columns off)" % wrong)
	ok(was >= 3, "lay near: the test has something to catch (%d columns would be off)" % was)
	var hb: String = SimHash.stateHash(S).gameplay
	S.swing.layN += 1
	ok(SimHash.stateHash(S).gameplay != hb, "lay near: its place is in the hash")
	SimCore.dispose(S)
	var S2 := start3()
	for f in S2.fighters:
		f.y = 3000.0
	SimSwing.ask(S2, {"deg": 12.0, "cause": "launch"})
	SimSwing.tick(S2)
	ok(not S2.swing.layNearOn, "lay near: off with no marks")
	SimCore.dispose(S2)


## After a rest the strip's marks come from the store, a slice a tick, to exactly what World's lay functions give; a snapshot in the middle comes out the same.
func _lay() -> void:
	var S := start3()
	for f in S.fighters:
		f.y = 3000.0
	var x: float = S.fighters[0].x - 400.0   # through the pivot, so some of it is still on the line after the turn
	SimField.pointAt(S, x)
	var ax: float = SimField.ox
	var ay: float = SimField.oy
	var az: float = SimField.oz
	SimField.pointAt(S, x + 800.0)
	ok(WorldStore.addCrack(S, [ax, ay, az], [SimField.ox, SimField.oy, SimField.oz], 0.9, 40.0, 0.0, 0) >= 0, "lay: a crack in the store")
	ok(S.swing.layK == -1, "lay: nothing running before a rest")
	SimSwing.ask(S, {"deg": 30.0, "cause": "launch", "pivotX": S.fighters[0].x})
	var t: int = 0
	while S.swing.active and t < 400:
		SimSwing.tick(S)
		S.tick += 1
		t += 1
	ok(S.swing.layK == 0, "lay: a rest starts it (%d)" % S.swing.layK)
	for k in range(5):
		SimSwing.tick(S)
		S.tick += 1
	var snap: NetSnapshot = NetSnapshot.take(S)
	var h0: String = SimHash.stateHash(S).gameplay
	var slices: int = 5
	var t0: int = Time.get_ticks_usec()
	var worst: int = 0
	while S.swing.layK >= 0 and slices < 200:
		var t1: int = Time.get_ticks_usec()
		SimSwing.tick(S)
		worst = maxi(worst, Time.get_ticks_usec() - t1)
		S.tick += 1
		slices += 1
	print("lay: %d ticks to the whole ring; worst slice %d us" % [slices, worst])
	ok(slices <= 49, "lay: done in the ticks the data says (%d)" % slices)
	var ours: PackedFloat32Array = S.crack.duplicate()
	var oursS: PackedFloat32Array = S.scorch.duplicate()
	var h1: String = SimHash.stateHash(S).gameplay
	var fr = S.frame
	var pointOf := func(xx: float) -> Array:
		SimField.pointIn(fr, xx)
		return [SimField.ox, SimField.oy, SimField.oz]
	t0 = Time.get_ticks_usec()
	WorldStore.layCracks(S, pointOf)
	WorldStore.layScorch(S, pointOf)
	print("lay: World's whole lay in one tick, for the record: %d us" % (Time.get_ticks_usec() - t0))
	ok(S.crack == ours and S.scorch == oursS, "lay: the same as World's lay functions, every column")
	var nz: int = 0
	for v in ours:
		if v > 0.0:
			nz += 1
	ok(nz > 0, "lay: the crack is on the strip somewhere (%d columns)" % nz)
	NetSnapshot.restore(S, snap)
	ok(SimHash.stateHash(S).gameplay == h0 and S.swing.layK > 0, "lay: a snapshot in the middle comes back")
	var g: int = 0
	while S.swing.layK >= 0 and g < 200:
		SimSwing.tick(S)
		S.tick += 1
		g += 1
	ok(S.crack == ours and S.scorch == oursS, "lay: and finishes the same")
	SimCore.dispose(S)


func _store() -> void:
	var S := start3()
	var x: float = S.fighters[0].x + 500.0
	var g0: float = WorldTerrain.groundY(S, x)
	var h0: String = SimHash.stateHash(S).gameplay
	SimField.pointAt(S, x)
	var q: Array = [SimField.ox, SimField.oy, SimField.oz]
	var snap: NetSnapshot = NetSnapshot.take(S)
	ok(WorldStore.add(S, q[0], q[1], q[2], 300.0, 100.0, 0.0, 1.0, 0, 0, 0.0, 0) >= 0, "store: a crater goes in")
	var g1: float = WorldTerrain.groundY(S, x)
	ok(g1 < g0 - 50.0, "store: the read sees it at once (%.1f to %.1f)" % [g0, g1])
	ok(SimHash.stateHash(S).gameplay != h0, "store: the hash sees it")
	# a real dig on a field world: into the store at the frame's point, nothing in the strip
	var x2: float = SimWrap.wrap(x + 3000.0)
	var c2: int = int(x2 / SimConst.COL)
	var d0: float = S.deform[c2]
	var g2: float = WorldTerrain.groundY(S, x2)
	WorldCrater.dig(S, x2, 8.0, S.fighters[0], "impact")
	ok(S.storeN == 2 and S.deform[c2] == d0, "store: a dig is a record, and the strip isn't written (%d, %.2f)" % [S.storeN, S.deform[c2] - d0])
	var g3: float = WorldTerrain.groundY(S, x2)
	ok(g3 < g2 - 1.0, "store: a dig lowers the ground it was dug on (%.1f to %.1f)" % [g2, g3])
	SimField.pointAt(S, x2)
	ok(absf(S.store[WorldStore.STRIDE + 1] - SimField.ox) < 1e-9 and absf(S.store[WorldStore.STRIDE + 2] - SimField.oy) < 1e-9, "store: at the line's point through the frame")
	var n2: int = S.storeN
	WorldCrater.deepen(S, x2, S.fighters[0], 1.5)
	var g4: float = WorldTerrain.groundY(S, x2)
	ok(S.storeN == n2 + 1 and S.deform[c2] == d0 and g4 < g3 - 0.5, "store: a follow-up deepens by a record, not the strip (%.1f to %.1f)" % [g3, g4])
	for f in S.fighters:
		f.y = 3000.0
	SimSwing.ask(S, {"deg": 40.0, "rate": 60.0, "cause": "launch", "pivotX": S.fighters[0].x})
	var t: int = 0
	while S.swing.active and t < 2000:
		SimSwing.tick(S)
		S.tick += 1
		t += 1
	# the crater stayed on the planet: read at its own direction, whatever the line
	SimField.strip(S, q[0], q[1], q[2])
	ok(absf(SimField.sz) > 100.0, "store: the crater is off the line now (%.1f)" % SimField.sz)
	var away: float = WorldTerrain.groundY(S, x)
	print("store: at its old x after the swing %.1f; field there alone %.1f" % [away, SimField.col(S, int(x / SimConst.COL))])
	NetSnapshot.restore(S, snap)
	ok(S.storeN == 0 and WorldTerrain.groundY(S, x) == g0, "store: a restore truncates it, and the read follows")
	SimCore.dispose(S)


func _key() -> void:
	ok(SimField.keyHash(7) == SimField.keyHash(7) and SimField.keyHash(7) != SimField.keyHash(3), "key: stable, and differs by planet")
	# a node this machine holds wrong: a stale cache's. The key must see it
	var k0: String = SimField.keyHash(7)
	var P = WorldPlanet.make(7)
	var F = WorldField.of(P)
	var hit: Array = []
	for n in range(8):
		var f: int = int(SimRng.keyed(7, "field-f", n) * 6.0)
		var i: int = int(SimRng.keyed(7, "field-i", n) * float(WorldField.cells()))
		var j: int = int(SimRng.keyed(7, "field-j", n) * float(WorldField.cells()))
		if i % WorldField.bakeStride() == 0 and j % WorldField.bakeStride() == 0:
			i += 1
		var idx: int = WorldField.ensure(F, f, i, j)
		hit.append([idx, F.h[idx]])
		F.h[idx] = F.h[idx] + 1.0
	SimField._keyOf.clear()
	ok(SimField.keyHash(7) != k0, "key: a held node that isn't the function's changes it")
	for e in hit:
		F.h[e[0]] = e[1]
	SimField._keyOf.clear()
	ok(SimField.keyHash(7) == k0, "key: and back")
	# a far read on the stride: exact on it, between its neighbours off it, and a plan's line reads an eighth of the columns
	var S := start3()
	var far0: Array = []
	SimField.far()
	var c8: float = SimField.col(S, 800)
	var c16: float = SimField.col(S, 808)
	var c4: float = SimField.col(S, 804)
	var w: float = WorldField.heightBake(P, 0.0, 0.0, 1.0)
	SimField.near()
	ok(absf(c4 - 0.5 * (c8 + c16)) < 1e-9, "far: between two stride columns, their line")
	ok(is_finite(w), "far: the bake reads")
	SimCore.dispose(S)


## Each break must be caught: the checks above can see it.
func _negative() -> void:
	var S := start3()
	var x: float = S.fighters[0].x
	var found: bool = false
	for k in range(200):
		var xx: float = x + 37.0 * float(k)
		var near_: float = WorldTerrain.groundY(S, xx)
		SimField.far()
		var far_: float = WorldTerrain.groundY(S, xx)
		SimField.near()
		if absf(near_ - far_) > 1.0:
			found = true
			break
	ok(found, "break 1: the two levels differ, so a read by what's ready would give another ground")
	var h: String = SimHash.stateHash(S).gameplay
	S.frame.tx += 1e-9
	ok(SimHash.stateHash(S).gameplay != h, "break 2: a frame off by a little changes the hash")
	S.frame.tx -= 1e-9
	SimSwing.ask(S, {"deg": 30.0, "rate": 60.0, "cause": "launch"})
	var snap: NetSnapshot = NetSnapshot.take(S)
	for t in range(5):
		SimSwing.tick(S)
		S.tick += 1
	ok(S.swing.rate > 0.0, "break 3: the rate moved")
	NetSnapshot.restore(S, snap)
	ok(S.swing.rate == 0.0 and S.swing.tau == 0.0, "break 3: a snapshot keeps the swing's own copy")
	if S.swing.active:
		SimSwing.rest(S, 1)
		SimSwing.tick(S)
	# a stale memo would show: a frame one bit off must not read the old column
	var c0: float = SimField.col(S, 1234)
	SimSwing._applyTurn(S.frame, S.frame.x0, 20.0)
	var fresh: float = SimField.col(S, 1234)
	ok(fresh != c0, "break 4: a frame that turned reads its own columns (%.2f, %.2f)" % [c0, fresh])
	SimCore.dispose(S)
