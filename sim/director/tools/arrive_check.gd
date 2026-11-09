extends SceneTree
## The arrival (bands.arrive, off; docs/director/pending/arrive/; Game Design overnight-2026-11-08.md (c)): LT's high speed eases into
## striking distance (engageBh) over the last 1.5 bh, never through it.
##   godot --headless --path . --script res://sim/director/tools/arrive_check.gd
## The fighter flies at flat-out speed from the first tick (his speed raised to the energy model's 5,000 a second at close range: what
## Simulation's dash with no distance ramp gives), LT held, the stick toward a rival standing still, from 600, 1,500 and 3,000 apart.
## - on: he never comes closer than the mark (engageBh) and never passes him; he reaches the mark; no tick moves him more than 3 bh
##   (RL-076); the last 1.5 bh take at least 4 ticks
## - on: with the dash let go (plain flight), and flying away (both at his own speed), nothing changes (the same path as off)
## - off (the negative control): at that speed he flies through the mark
## The slip (Simulation's power.json dash.slip, by the setup's "slip"; the model, the dash and the kick on, as the builds play them):
## a tapped LT, let go before tick 6, from 400 apart (5.3 bh, Controls' row where a tap passed him), the rival standing still.
## - on: a tap of 1 to 5 ticks with the stick let go with it never comes inside the mark, and never passes him
## - on: with the stick held toward him, he crosses the mark no faster than his own flight (the stick's, as from a standstill)
## - far from him (3,000 apart), taps and holds, and a dash held all the way at 400, move exactly as with the slip's carry unread
## - the slip on, plain flight toward him (no LT), straight and on the diagonal, moves as with the carry unread
## - the slip off, a tap moves as with the carry unread
## - the negative control (the carry unread): a tap passes inside the mark
## The slip's hold (arrive.slipHoldTicks 13): near him a tap is a step to the mark and a beat there, as today's 13-tick lunge.
## - at 400 apart, a press of 1 to 12 with the stick held 60 ticks travels no further than today's (the slip off, a 13-tick dash)
## - a tap of 1 to 5 with the stick let go with it never comes inside the mark
## - slipHoldTicks 0 (the negative control): a press of 1 with the stick held travels further than today's
## Ends on the verdict line.

var failed: int = 0
const FAST: float = 5000.0


func _init() -> void:
	var c: Dictionary = DirBands.data()
	var a0 = c.get("arrive", {}).duplicate()
	if not c.has("arrive"):
		c["arrive"] = {}
	c.arrive["enabled"] = true
	var mark: float = float(c.engageBh) * DirBands.BH
	var rows: Array = []
	for gap in [600.0, 1500.0, 3000.0]:
		rows.append(_fly(gap, true, true))
	var plainOn: Dictionary = _fly(1500.0, false, false)
	var awayOn: Dictionary = _fly(1500.0, true, false, -1.0)
	c.arrive["enabled"] = false
	var offFast: Dictionary = _fly(1500.0, true, true)
	var plainOff: Dictionary = _fly(1500.0, false, false)
	var awayOff: Dictionary = _fly(1500.0, true, false, -1.0)
	c["arrive"] = a0
	for r in rows + [plainOn, awayOn, offFast, plainOff, awayOff]:
		print("      %s: closest %.1f (mark %.1f), passed %s, at the mark by tick %d, the biggest step %.1f, ticks in the last 1.5 bh %d" % [r.name, r.closest, mark, str(r.passed), r.atMark, r.maxStep, r.easeTicks])
	var ok: bool = true
	for r in rows:
		ok = ok and r.closest >= mark - 1.0 and not r.passed and r.atMark >= 0
	_expect(ok, "on: from 600, 1,500 and 3,000 he reaches the mark and never comes closer or passes him")
	var steps: bool = true
	for r in rows:
		steps = steps and r.maxStep <= 3.0 * DirBands.BH and r.easeTicks >= 4
	_expect(steps, "on: no tick moves him more than 3 bh, and the last 1.5 bh take at least 4 ticks (RL-076)")
	_expect(plainOn.track == plainOff.track and awayOn.track == awayOff.track, "on: plain flight (no dash) and flying away are untouched")
	_expect(offFast.closest < mark - 20.0 or offFast.passed, "negative control, off: at that speed he flies through the mark (closest %.1f, passed %s)" % [offFast.closest, str(offFast.passed)])
	_slipRows(mark)
	print("ARRIVE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


const SLIP: Dictionary = {"intro": false, "planet": 7, "touch": 3, "planetGen": 3, "power": true, "dash": true, "kick": true, "slip": true, "travel": 1.5}


## The slip's rows (the arrival on throughout).
func _slipRows(mark: float) -> void:
	var c: Dictionary = DirBands.data()
	var a0 = c.get("arrive", {}).duplicate()
	c.arrive["enabled"] = true
	var pure: Array = []
	var held: Array = []
	var crossOk: bool = true
	for k in range(1, 6):
		pure.append(_tap(SLIP, 400.0, k, false))
		var h: Dictionary = _tap(SLIP, 400.0, k, true)
		DirBands.blindSlip = true
		var hb: Dictionary = _tap(SLIP, 400.0, k, true)
		DirBands.blindSlip = false
		held.append("tap %d: %.2f bh (unread %.2f)" % [k, h.travel / DirBands.BH, hb.travel / DirBands.BH])
		crossOk = crossOk and h.crossV <= h.plain + 1.0
		print("      slip, a tap of %d at 400 with the stick held 60 ticks: crosses the mark at %.0f a second (his own flight %.0f; unread %.0f)" % [k, h.crossV, h.plain, hb.crossV])
	var alone: Dictionary = _tap(SLIP, 400.0, 0, true)
	print("      slip, travelled in 60 ticks at 400 apart, the stick held (bh): %s; the stick alone %.2f" % ["; ".join(held), alone.travel / DirBands.BH])
	var ok: bool = true
	for r in pure:
		print("      slip, a tap of %d at 400 with the stick let go with it: closest %.1f (mark %.1f), passed %s, leap %.2f bh" % [r.k, r.closest, mark, str(r.passed), r.travel / DirBands.BH])
		ok = ok and r.closest >= mark - 1.0 and not r.passed
	_expect(ok, "slip on: a tap of 1 to 5 ticks with the stick let go never comes inside the mark or passes him")
	_expect(crossOk, "slip on: with the stick held toward him, he crosses the mark no faster than his own flight")
	var same: bool = true
	for k in [1, 2, 5, 6, 60]:
		var a: Dictionary = _tap(SLIP, 3000.0, k, true)
		DirBands.blindSlip = true
		var b: Dictionary = _tap(SLIP, 3000.0, k, true)
		DirBands.blindSlip = false
		same = same and a.track == b.track
	var h60: Dictionary = _tap(SLIP, 400.0, 60, true)
	DirBands.blindSlip = true
	var h60b: Dictionary = _tap(SLIP, 400.0, 60, true)
	DirBands.blindSlip = false
	_expect(same and h60.track == h60b.track, "far from him (3,000 apart) taps of 1, 2, 5 and holds of 6, 60, and a dash held all the way at 400, move as with the carry unread")
	var plainSame: bool = true
	for dg in [false, true]:
		var p: Dictionary = _tap(SLIP, 400.0, 0, true, dg)
		DirBands.blindSlip = true
		var pb: Dictionary = _tap(SLIP, 400.0, 0, true, dg)
		DirBands.blindSlip = false
		plainSame = plainSame and p.track == pb.track
	_expect(plainSame, "the slip on: plain flight toward him (no LT), straight and on the diagonal, moves as with the carry unread")
	var off: Dictionary = SLIP.duplicate()
	off["slip"] = false
	var so: Dictionary = _tap(off, 400.0, 2, false)
	DirBands.blindSlip = true
	var sob: Dictionary = _tap(off, 400.0, 2, false)
	var neg: Dictionary = _tap(SLIP, 400.0, 1, false)
	DirBands.blindSlip = false
	_expect(so.track == sob.track, "the slip off: a tap moves as with the carry unread")
	_expect(neg.closest < mark - 20.0 or neg.passed, "negative control, the carry unread: a tap of 1 passes inside the mark (closest %.1f, passed %s)" % [neg.closest, str(neg.passed)])
	_holdRows(mark)
	c["arrive"] = a0


## The slip's hold's rows (the arrival on, slipHoldTicks 13 unless the row says).
func _holdRows(mark: float) -> void:
	var c: Dictionary = DirBands.data()
	var h0 = c.arrive.get("slipHoldTicks", 0)
	c.arrive["slipHoldTicks"] = 13
	var off: Dictionary = SLIP.duplicate()
	off["slip"] = false
	var today: Dictionary = _tap(off, 400.0, 13, true)
	var line := PackedStringArray()
	var noWorse: bool = true
	for k in range(1, 13):
		var r: Dictionary = _tap(SLIP, 400.0, k, true)
		line.append("%d: %.2f" % [k, r.travel / DirBands.BH])
		noWorse = noWorse and r.travel <= today.travel + 0.75
	print("      hold 13, travelled in 60 ticks at 400 apart, the stick held (bh): %s; today (a 13-tick dash, the slip off) %.2f" % ["; ".join(line), today.travel / DirBands.BH])
	_expect(noWorse, "hold 13: at 400 apart a press of 1 to 12 with the stick held travels no further than today's 13-tick dash (%.2f bh, within 0.01 bh)" % (today.travel / DirBands.BH))
	var ok: bool = true
	for k in range(1, 6):
		var p: Dictionary = _tap(SLIP, 400.0, k, false)
		print("      hold 13, a tap of %d at 400 with the stick let go with it: closest %.1f (mark %.1f), passed %s" % [k, p.closest, mark, str(p.passed)])
		ok = ok and p.closest >= mark - 1.0 and not p.passed
	_expect(ok, "hold 13: a tap of 1 to 5 with the stick let go never comes inside the mark or passes him")
	c.arrive["slipHoldTicks"] = 0
	var neg: Dictionary = _tap(SLIP, 400.0, 1, true)
	_expect(neg.travel > today.travel + 0.75, "negative control, hold 0: a press of 1 with the stick held travels further than today's (%.2f bh against %.2f)" % [neg.travel / DirBands.BH, today.travel / DirBands.BH])
	c.arrive["slipHoldTicks"] = h0


## A tap of k ticks of LT (0: none; 60: held all the way) from gap apart, the stick toward him with it (and held for 60 ticks if
## holdStick; up as well on the diagonal), the rival held still: closest, passed, travel, his speed on the tick he first comes inside
## the mark.
func _tap(su: Dictionary, gap: float, k: int, holdStick: bool, diag: bool = false) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": false, "p2": false}, su)
	var f = S.fighters[0]
	var o = S.fighters[1]
	f.x = SimWrap.wrap(o.x - gap)
	f.y = 6000.0
	o.y = 6000.0
	f.vx = 0.0
	f.vy = 0.0
	var ox: float = o.x
	var x0: float = f.x
	var mark: float = float(DirBands.data().engageBh) * DirBands.BH
	var out := {"k": k, "closest": 1e9, "passed": false, "travel": 0.0, "crossV": 0.0, "plain": SimFighter.flightSpeed(S, f, false), "track": PackedStringArray()}
	for t in range(60):
		var i := SimIntent.new()
		i.mx = 1.0 if (holdStick or t < k) else 0.0
		i.my = i.mx if diag else 0.0
		i.dash = t < k
		o.x = ox
		o.y = 6000.0
		o.vx = 0.0
		o.vy = 0.0
		SimCore.step(S, [i, null])
		S.out.fx.clear()
		S.out.feed.clear()
		var dx: float = SimWrap.sdx(f.x, o.x)
		var d: float = absf(dx)
		if out.crossV == 0.0 and d < mark - 0.5:
			out.crossV = maxf(SimDetMath.hypot(f.vx, f.vy), 0.001)
		out.closest = minf(out.closest, d)
		if dx < 0.0:
			out.passed = true
		out.track.append("%.3f,%.3f" % [SimWrap.sdx(x0, f.x), f.y])
	out.travel = absf(SimWrap.sdx(x0, f.x))
	SimCore.dispose(S)
	return out


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fly(gap: float, dash: bool, fast: bool, toward: float = 1.0) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var A = S.fighters[0]
	var D = S.fighters[1]
	for f in S.fighters:
		f.ai = null
		f.hp = 100000.0
	for _k in range(3):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
	A.y = WorldTerrain.groundY(S, A.x, A.z) + 600.0
	D.x = SimWrap.wrap(A.x + gap)
	D.y = A.y
	A.vx = 0.0
	A.vy = 0.0
	if fast:
		A.spd *= FAST / maxf(1.0, SimFighter.flightSpeed(S, A, true))   # flat out at close range from the first tick (Simulation's no-ramp dash)
	var mark: float = float(DirBands.data().engageBh) * DirBands.BH
	var ease: float = float(DirBands.data().get("arrive", {}).get("easeBh", 1.5)) * DirBands.BH
	var side0: float = SimMathx.jsign(SimWrap.sdx(A.x, D.x))
	var out := {"name": "%s from %.0f, %s%s" % ["dash" if dash else "plain", gap, "toward" if toward > 0.0 else "away", "" if DirBands.arriveOn() else ", off"], "closest": 1e9, "passed": false, "atMark": -1, "maxStep": 0.0, "easeTicks": 0, "track": PackedStringArray()}
	var x0: float = A.x
	for t in range(240):
		var i := SimIntent.new()
		i.mx = toward * SimMathx.jsign(SimWrap.sdx(A.x, D.x))
		i.dash = dash
		i.sprint = dash
		var before: float = A.x
		var dPrev: float = absf(SimWrap.sdx(A.x, D.x))
		SimCore.step(S, [i, SimIntent.new()])
		S.out.fx.clear()
		S.out.feed.clear()
		var step: float = absf(SimWrap.sdx(before, A.x))
		out.maxStep = maxf(out.maxStep, step)
		var d: float = absf(SimWrap.sdx(A.x, D.x))
		out.closest = minf(out.closest, d)
		if SimMathx.jsign(SimWrap.sdx(A.x, D.x)) != side0:
			out.passed = true
		if out.atMark < 0 and d <= mark + 2.0:
			out.atMark = t
		if dPrev <= mark + ease and d > mark + 1.0 and step > 0.01:
			out.easeTicks += 1
		if t % 10 == 0:
			out.track.append("%.2f" % SimWrap.sdx(x0, A.x))
		if S.dirS.ex != null:
			break
	SimCore.dispose(S)
	return out
