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
	print("ARRIVE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


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
