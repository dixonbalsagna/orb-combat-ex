extends SceneTree
## The horde trial (docs/ep/proposals/horde-trial-design.md section 8.1; scratch only): godot --headless --path . --script res://sim/director/tools/horde_check.gd
## T1: the switch off leaves a match as it was; on, five slots, the seats and the places, away bodies parked and inert, two runs one hash.

var fails: int = 0
var checks: int = 0


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  " + what)
	else:
		print("ok    " + what)


func _horde(seed: int = 5, two: bool = false, more: Dictionary = {}) -> SimState:
	var S := SimCore.createSim()
	var su: Dictionary = {"horde": true, "intro": false, "planet": 7, "touch": 2, "planetGen": 3}
	su.merge(more, true)
	SimCore.newMatch(S, seed, {"p1": false, "p2": not two}, su)
	return S


## A scripted pad: moves, taps light, sometimes heavy, sometimes dodges; the same every run.
func _pad(t: int) -> SimIntent:
	var i := SimIntent.new()
	i.mx = 1.0 if (t / 90) % 2 == 0 else -1.0
	i.light = t % 17 == 0
	i.heavy = t % 61 == 0
	i.dodge = t % 97 == 0
	return i


func _run(S: SimState, ticks: int, every: int = 60) -> Array:
	var hs: Array = []
	for t in range(ticks):
		SimCore.step(S, [_pad(t), null, null, null, null])
		S.out.fx.clear()
		S.out.feed.clear()
		if t % every == every - 1:
			hs.append(SimHash.stateHash(S).gameplay)
	return hs


func _t1() -> void:
	print("-- T1: the state, the slots, the hash")
	ok(SimHorde.errors().is_empty(), "the data loads with no error %s" % str(SimHorde.errors()))
	ok(not SimHorde.enabled(), "the data's switch is off")
	# the switch off: a match as it was
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 5, {"p1": false, "p2": true}, {"intro": false, "planet": 7, "touch": 2, "planetGen": 3})
	ok(not S0.hordeOn and S0.horde == null and S0.fighters.size() == 2 and S0.fighters[0].hd == null, "switch off: no horde state, two fighters")
	var dOff: String = SimReplay.dataHash({})
	var dOn: String = SimReplay.dataHash({"horde": true})
	ok(dOff != dOn, "the file is in a replay's data hash only with the horde on")
	# the switch on
	var S := _horde()
	ok(S.hordeOn and S.horde != null and S.fighters.size() == 5, "switch on: the run and five slots (%d)" % S.fighters.size())
	var a = S.fighters[0]
	var seat2 = S.fighters[1]
	ok(a.hd.kind == 0 and a.hd.phase == 2 and not a.out and a.hd.was == 1, "seat 0, a pad: in the fight")
	ok(seat2.hd.kind == 0 and seat2.out, "seat 1, nobody on it: away")
	var parked: bool = true
	for k in range(2, 5):
		var f = S.fighters[k]
		parked = parked and f.hd.kind == 1 and f.out and f.ai != null and absf(f.y - SimHorde.parkBh * SimHorde.BH_UNITS) < 1e-6
	ok(parked and seat2.y == SimHorde.parkBh * SimHorde.BH_UNITS, "every place, and the empty seat, parked %d up" % int(SimHorde.parkBh * SimHorde.BH_UNITS))
	ok(S.horde.mark[0] == 2 and S.horde.mark[2] == 0 and S.horde.lane.size() == 6, "marks and lanes laid")
	ok(not SimCore.ended(S), "not ended at the start")
	var pw: Array = []
	for f in S.fighters:
		pw.append(f.power)
	var h0: Array = _run(S, 900)
	var e = S.fighters[1]
	var still: bool = e.out and e.y == SimHorde.parkBh * SimHorde.BH_UNITS and e.vx == 0.0 and e.power == pw[1]
	ok(still, "the empty seat stays parked, unstepped, through 900 ticks")
	var S2 := _horde()
	var h1: Array = _run(S2, 900)
	ok(h0 == h1, "two runs give one hash (15 readings)")
	var S3 := _horde(6)
	var h2: Array = _run(S3, 120)
	ok(h2[0] != h0[0], "another seed, another hash")
	var hp0: float = e.hp
	SimDamage.hit(S, null, a, e, 50.0, {"kind": "light", "weight": "light", "region": "core"})
	ok(e.hp == hp0, "an away body takes no hit")


## Fields of a against b, walking script variables, into objects two deep; the names in skip are left out.
func _diff(a, b, path: String, skip: Array, depth: int, out: Array) -> void:
	for p in a.get_property_list():
		if not (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or skip.has(p.name):
			continue
		var va = a.get(p.name)
		var vb = b.get(p.name)
		if typeof(va) == TYPE_OBJECT and va != null and typeof(vb) == TYPE_OBJECT and vb != null:
			if depth > 0 and va.get_script() == vb.get_script():
				_diff(va, vb, path + p.name + ".", [], depth - 1, out)
			continue
		if typeof(va) != typeof(vb) or va != vb:
			out.append("%s%s: %s vs %s" % [path, p.name, str(va).left(40), str(vb).left(40)])


## A scripted run: every place in the fight falls `after` ticks after it came in. Returns the readings.
func _scripted(S: SimState, after: int, ticks: int, ref = null, idle: bool = false) -> Dictionary:
	var r := {"maxIn": 0, "size5": true, "refills": 0, "diffs": [], "awayHit": 0, "awayPower": 0, "packTier": 0, "hs": [], "endT": -1, "waves": 0}
	var since: Array = [0, 0, 0, 0, 0]
	var pw: Array = []
	for f in S.fighters:
		pw.append(f.power)
	var skip: Array = ["x", "y", "z", "vx", "vy", "face", "keys", "hd", "out", "ai", "input"]
	for t in range(ticks):
		var outs: Array = []
		for f in S.fighters:
			outs.append(f.out)
		if idle:   # (the backstop row: a pad that never presses, kept on its feet, so only the cap can end the run)
			S.fighters[0].hp = S.fighters[0].maxhp
			S.fighters[0].brink = false
		SimCore.step(S, [null if idle else _pad(t), null, null, null, null])
		for e in S.out.fx:
			if e.type == "damage" and int(e.victim) >= 0 and int(e.victim) < 5 and outs[int(e.victim)]:
				r.awayHit += 1
			if e.type == "cue" and e.kind == "horde_wave":
				r.waves += 1
		S.out.fx.clear()
		S.out.feed.clear()
		var n: int = 0
		for k in range(5):
			var f = S.fighters[k]
			if outs[k] and f.out and f.power != pw[k]:
				r.awayPower += 1
			if k >= 2 and not f.out and f.power > 0.0:
				r.packTier += 1
			pw[k] = f.power
			if k < 2:
				continue
			if not f.out:
				n += 1
				if outs[k]:   # came in this tick: compare with a new match's body of that fighter
					r.refills += 1
					if ref != null and r.diffs.size() < 12:
						SimHorde.fresh(S, k, String(SimHorde.packCfg(f.hd.kind).fighter), f.x, f.y)   # (again, in place: compared at once, before any of the sim's tick has run on it)
						var d: Array = []
						_diff(f, ref, "", skip, 2, d)
						if not d.is_empty():
							r.diffs.append("refill %d: %s" % [r.refills, ", ".join(d.slice(0, 6))])
					since[k] = 0
				else:
					since[k] += 1
					if since[k] >= after and f.hd.phase != 6:
						DirHorde.fell(S, k, 1)
		r.maxIn = maxi(r.maxIn, n)
		r.size5 = r.size5 and S.fighters.size() == 5
		if t % 300 == 299:
			r.hs.append(SimHash.stateHash(S).gameplay)
		if SimCore.ended(S):
			r.endT = t
			break
	return r


func _t2() -> void:
	print("-- T2: falls, refills, the waves, the end")
	var R0 := _horde()
	var ref = R0.fighters[2]   # a new match's fodder: the same fighter as every refill in the trial
	var S := _horde()
	var r: Dictionary = _scripted(S, 30, 20000, ref)
	ok(r.refills >= 200, "200 refills or more (%d)" % r.refills)
	if not r.diffs.is_empty():
		for d in r.diffs:
			print("  " + d)
	ok(r.diffs.is_empty(), "reading 3: a body made fresh equals a new match's body (position, keys, horde state aside)")
	ok(r.maxIn <= 3 and r.size5, "reading 4: never more than 3 places in (%d), the list always 5" % r.maxIn)
	ok(r.awayHit == 0 and r.awayPower == 0, "reading 20: no hit on an away body (%d), no power gained by one (%d)" % [r.awayHit, r.awayPower])
	ok(r.packTier == 0, "reading 20: a pack body's power stays at nothing (%d ticks above)" % r.packTier)
	ok(r.waves == 8 and r.endT > 0 and S.horde.over == 1, "eight waves, then the run ends cleared (waves %d, over %d at tick %d)" % [r.waves, S.horde.over, r.endT])
	ok(S.horde.felled == 621 and S.horde.sent == 621, "621 bodies sent and felled alone (%d, %d)" % [S.horde.sent, S.horde.felled])
	ok(SimCore.ended(S), "the match has ended")
	var S1 := _horde()
	var r1: Dictionary = _scripted(S1, 30, 20000)
	var S2 := _horde()
	var r2: Dictionary = _scripted(S2, 30, 20000)
	ok(r2.hs == r1.hs and r2.endT == r1.endT and r1.hs.size() > 20, "reading 2: two scripted runs, one hash through %d refills (%d readings)" % [r1.refills, r1.hs.size()])
	# two seats in: the counts x 1.5
	var S3 := _horde(5, true)
	var r3: Dictionary = _scripted(S3, 30, 30000)
	var want: int = 0
	for row in SimHorde.data().waves:
		for kk in ["fodder", "bruiser", "speedster"]:
			want += int(floor(float(row[kk]) * float(SimHorde.data().two.countMul) + 0.5))
	ok(S3.horde.sent == want and S3.horde.over == 1, "two seats: %d bodies (each wave's count x the data's two.countMul, rounded) (%d, over %d)" % [want, S3.horde.sent, S3.horde.over])
	# the backstop: nothing falls
	var S4 := _horde()
	var r4: Dictionary = _scripted(S4, 1 << 30, DirHorde.capTicks() + 10, null, true)
	ok(S4.horde.over == 3 and r4.endT >= DirHorde.capTicks() - 30, "nothing falls: the backstop ends the run at 12:00 (over %d at tick %d)" % [S4.horde.over, r4.endT])


## The build Orb plays: the energy model, the dash, the slip and the kick on by setup, flat-out flight at 3,500 (section 8.1).
const PLAYS: Dictionary = {"power": true, "dash": true, "slip": true, "kick": true, "flatOut": 3500.0, "v2": [true, true]}


## The nearest pack body in the fight to slot s, or null.
func _near(S: SimState, s: int):
	var a = S.fighters[s]
	var best = null
	var bd: float = INF
	for k in range(2, 5):
		var M = S.fighters[k]
		if M.out or M.hd.phase == 6:
			continue
		var d: float = DirBands.dist(a, M)
		if d < bd:
			bd = d
			best = M
	return best


## A scripted hunter: flies at the nearest pack body and taps X four times a second inside the lunge's reach; weights by `mix` ("x", "xy", "xyb").
func _hunter(S: SimState, s: int, t: int, mix: String = "x") -> SimIntent:
	var i := SimIntent.new()
	var a = S.fighters[s]
	var M = _near(S, s)
	if M == null:
		return i
	var d: float = DirBands.dist(a, M)
	var dx: float = SimWrap.sdx(a.x, M.x)
	if d > DirHorde.lungeReach(S) * 0.7:
		i.mx = 1.0 if dx > 0.0 else -1.0
		i.my = clampf((M.y - a.y) / 400.0, -1.0, 1.0)
		i.dash = absf(dx) > 1500.0
	if d <= DirHorde.lungeReach(S) and t % 15 == 0:
		var n: int = (t / 15) % 6
		if mix == "xyb" and n == 5:
			i.sig = true
		elif mix != "x" and n % 3 == 2:
			i.heavy = true
		else:
			i.light = true
	return i


## A pad that presses everything in turn: X, Y, B, A, RB with X and Y, the right stick with and without RB, a hold's edge, the guard, the dodge, the charge.
func _everything(t: int) -> SimIntent:
	var i := SimIntent.new()
	i.mx = 1.0 if (t / 120) % 2 == 0 else -1.0
	match t % 26:
		0: i.light = true
		2: i.heavy = true
		4: i.sig = true
		6: i.context = true
		8:
			i.mode = 1
			i.light = true
		10:
			i.mode = 1
			i.heavy = true
		12:
			i.rsStart = true
			i.rsHeld = true
			i.rsDir = 1
		13:
			i.rsRelease = true
			i.rsDir = 1
		15:
			i.rsStart = true
			i.rsHeld = true
			i.rsMask = 2
			i.rsDir = 1
		16:
			i.rsHeld = true
			i.rsMask = 2
			i.rsDir = 1
		17:
			i.rsRelease = true
			i.rsMask = 2
			i.rsDir = 1
		19:
			i.lightHeld = true
			i.upgrade = 1
		21:
			i.guard = true
			i.guardPress = true
		23: i.dodge = true
		25: i.charge = true
	return i


## Readings 14 and 19 over a run: hits on one's own side, exchanges, locked seats, late refusals; and the blows' cues.
func _watch(S: SimState, ticks: int, pad: Callable, two: bool = false) -> Dictionary:
	var r := {"own": 0, "packPack": 0, "ex": 0, "locked": 0, "late": 0, "start": 0, "whiff": 0, "air": 0, "felled0": S.horde.felled, "wave1T": -1, "refused": {}, "seatHits": 0, "self": 0}
	for t in range(ticks):
		var ins: Array = [pad.call(S, 0, t), pad.call(S, 1, t) if two else null, null, null, null]
		SimCore.step(S, ins)
		for e in S.out.fx:
			if e.type == "damage" and int(e.attacker) >= 0 and int(e.victim) >= 0:
				var sa: int = SimHorde.side(S, int(e.attacker))
				var sv: int = SimHorde.side(S, int(e.victim))
				if int(e.attacker) == int(e.victim):
					r.self += 1   # (a fighter's own blast coming back on him, as one-on-one: not a hit on his side)
				elif sa == 0 and sv == 0:
					r.own += 1
					if r.own <= 4:
						print("  own-side hit: tick %d, %d on %d, kind %s, amount %.1f" % [t, int(e.attacker), int(e.victim), String(e.kind), float(e.amount)])
				elif sa == 1 and sv == 1:
					r.packPack += 1
				if sa == 0 and sv == 1:
					r.seatHits += 1
			elif e.type == "cue":
				if e.kind == "horde_blow":
					if e.text == "start":
						r.start += 1
					elif e.text == "whiff":
						r.whiff += 1
					elif e.text == "air":
						r.air += 1
				elif e.kind == "stick_refused" and e.source == "late":
					r.late += 1
				elif e.kind == "press_refused":
					r.refused[e.source] = int(r.refused.get(e.source, 0)) + 1
				elif e.kind == "horde_rest" and r.wave1T < 0:
					r.wave1T = t
		S.out.fx.clear()
		S.out.feed.clear()
		if S.dirS.ex != null:
			r.ex += 1
		for s in range(2):
			if S.fighters[s].state == "locked":
				r.locked += 1
		if r.wave1T >= 0 and ticks > 100000:
			break
	return r


func _t3() -> void:
	print("-- T3: the mark, the player's pack blows, no exchange, the side rule")
	var S := _horde(5, false, PLAYS)
	ok(S.powerOn and S.dashOn and S.kickOn and SimDirStick_on(), "the build Orb plays: the model, the dash, the kick, the right stick on")
	var r: Dictionary = _watch(S, 12000, func(S_, s, t): return _hunter(S_, s, t, "x"))
	print("  X only: blows %d, whiffs %d, at the air %d, felled %d, wave 1 cleared at tick %d" % [r.start, r.whiff, r.air, S.horde.felled, r.wave1T])
	ok(r.wave1T > 0, "a scripted pad clears wave 1 with X (cleared at tick %d)" % r.wave1T)
	ok(r.own == 0 and r.packPack == 0, "reading 14: no hit on one's own side (seat on seat %d, pack on pack %d)" % [r.own, r.packPack])
	ok(r.ex == 0 and r.locked == 0, "reading 19: no exchange (%d ticks), no seat locked (%d ticks)" % [r.ex, r.locked])
	var S2 := _horde(7, false, PLAYS)
	var r2: Dictionary = _watch(S2, 12000, func(S_, s, t): return _hunter(S_, s, t, "xyb"))
	print("  X, Y and B: blows %d, whiffs %d, felled %d, wave %d" % [r2.start, r2.whiff, S2.horde.felled, S2.horde.wave])
	ok(r2.wave1T > 0, "a pad with all three weights clears wave 1 (tick %d)" % r2.wave1T)
	var S3 := _horde(9, true, PLAYS)
	var r3: Dictionary = _watch(S3, 9000, func(S_, s, t): return _everything(t + s * 7), true)
	print("  every button, two pads: refusals %s; blows %d, at the air %d" % [str(r3.refused), r3.start, r3.air])
	ok(r3.ex == 0 and r3.locked == 0 and r3.late == 0, "reading 19, every button and two pads: no exchange (%d), no seat locked (%d), no late refusal (%d)" % [r3.ex, r3.locked, r3.late])
	ok(int(r3.refused.get("horde_sig", 0)) > 0 and int(r3.refused.get("horde_grab", 0)) > 0, "the beam and the grab are refused, said (horde_sig %d, horde_grab %d)" % [int(r3.refused.get("horde_sig", 0)), int(r3.refused.get("horde_grab", 0))])
	ok(r3.own == 0 and r3.packPack == 0, "reading 14 with two pads: no hit on one's own side (seat on seat %d, pack on pack %d; a fighter's own blast on himself %d, as one-on-one)" % [r3.own, r3.packPack, r3.self])


func SimDirStick_on() -> bool:
	return DirStick.on()


## Steps a recorded match: seat 0's hunter, seat 1's pad (a hunter too, once it is in), the pack its own.
func _recStep(rec: SimReplay, t: int) -> void:
	var S: SimState = rec.S
	rec.step([_hunter(S, 0, t, "x"), _hunter(S, 1, t + 7, "x") if S.fighters[1].ai == null else null, null, null, null])
	S.out.fx.clear()
	S.out.feed.clear()


func _t5() -> void:
	print("-- T5: going down and getting up; the second seat joining, leaving and coming back")
	var su: Dictionary = PLAYS.duplicate(true)
	su.merge({"horde": true, "intro": false, "planet": 7, "touch": 2, "planetGen": 3}, true)
	var S := SimCore.createSim()
	var rec: SimReplay = SimReplay.recorder(S, 13, {"p1": false, "p2": true}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	for t in range(600):
		_recStep(rec, t)
	ok(b.out and b.hd.was == 0, "seat 1 empty: away")
	rec.toggle(1)   # a pad joins
	var t0: int = 600
	_recStep(rec, t0)
	ok(not b.out and b.ai == null and b.hd.phase == 2 and b.hd.was == 1 and S.fighters.size() == 5, "reading 15: the second pad's fighter is in the list on the tick after the join")
	var x0: float = b.x
	_recStep(rec, t0 + 1)
	_recStep(rec, t0 + 2)
	ok(b.x != x0 or absf(b.vx) > 0.0, "... and reading its pad (it moves under its own stick)")
	for t in range(t0 + 3, t0 + 600):
		_recStep(rec, t)
	var hp1: float = b.hp
	var ph1: int = b.hd.phase
	rec.toggle(1)   # it leaves
	_recStep(rec, t0 + 600)
	ok(b.out and b.y == SimHorde.parkBh * SimHorde.BH_UNITS and b.hp == hp1, "a leave: away and parked, its body kept, no error")
	for t in range(t0 + 601, t0 + 900):
		_recStep(rec, t)
	rec.toggle(1)   # it comes back
	_recStep(rec, t0 + 900)
	ok(not b.out and b.hp <= hp1 and b.hd.phase == ph1, "reading 15: coming back never raises the body (%.0f, was %.0f) and keeps its phase" % [b.hp, hp1])
	var rp: Dictionary = rec.finish().duplicate(true)   # (the replay ends here: the rows below set state by hand)
	# seat 0 goes down at its last legs; seat 1 plays on; a downed seat takes no hit and reads no input
	a.hp = 0.0
	var downAt: int = -1
	var hitDown: int = 0
	for t in range(t0 + 901, t0 + 4000):
		var inDown: bool = a.hd.phase == 7
		var hpd: float = a.hp
		_recStep(rec, t)
		if inDown and a.hp < hpd:
			hitDown += 1
		if downAt < 0 and a.hd.phase == 7:
			downAt = t
		if downAt >= 0 and t == downAt + 300:
			rec.toggle(0)   # the downed player leaves ...
		if downAt >= 0 and t == downAt + 400:
			rec.toggle(0)   # ... and comes back: still down
			_recStep(rec, t + 1)
			ok(a.hd.phase == 7, "reading 15: leaving and coming back never lifts a downed seat")
			break
	ok(downAt > 0 and S.horde.over == 0, "seat 0 down at its last legs (tick %d); the run goes on with seat 1 up" % downAt)
	ok(hitDown == 0, "reading 20: no hit lands on a downed player (%d)" % hitDown)
	var upAt: int = -1
	var w0: int = S.horde.wave
	for t in range(t0 + 4100, t0 + 30000):
		_recStep(rec, t)
		if a.hd.phase != 7 and upAt < 0:
			upAt = t
			break
	ok(upAt > 0 and a.hp > 0.0 and a.hp <= float(SimHorde.data().down.backBody) + 1e-6, "the downed player gets up when the wave is cleared, with %.0f of the body (%.0f at tick %d)" % [float(SimHorde.data().down.backBody), a.hp, upAt])
	var res: Dictionary = SimReplay.play(rp)
	ok(bool(res.ok), "reading 15: a replay with both seats, a join, a leave and a return reproduces (%s, first bad tick %d, %d toggles)" % [String(res.reason), int(res.firstBadTick), rp.toggles.size()])
	# alone, going down ends the run
	var S2 := _horde(15, false, PLAYS)
	S2.fighters[0].hp = 0.0
	for t in range(4000):
		SimCore.step(S2, [null, null, null, null, null])
		S2.out.fx.clear()
		S2.out.feed.clear()
		if SimCore.ended(S2):
			break
	ok(S2.horde.over == 2 and SimCore.ended(S2), "alone, going down ends the run (over %d)" % S2.horde.over)


func _init() -> void:
	_t1()
	_t2()
	_t3()
	_t5()
	print("HORDE: %d check(s), %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)
