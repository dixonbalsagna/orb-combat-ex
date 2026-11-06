extends SceneTree
## A sure blow and contact.reach (QA's 10.reach; DirBrawl.sureWaits). A real brawl is run to, then the rival is put out of
## reach and a sure blow thrown: it waits, closes and lands in reach; a rival held out of reach makes it meet nothing; and
## with give.sureWaitTicks 0 it lands from too far, which is the fault this check would catch.
##   godot --headless --path . --script res://sim/director/tools/sure_reach_check.gd

var failed: int = 0


func _init() -> void:
	var rc: float = float(DirData.contact().reach)
	var most: int = int(DirBrawl.cfg().give.sureWaitTicks)
	var r: Dictionary = _case(60.0, false)
	_expect(int(r.hits) == 1 and float(r.dx) <= rc, "out of reach, it lands in reach (%d hit at %.1f, reach %.1f)" % [int(r.hits), float(r.dx), rc])
	_expect(int(r.waited) >= 1 and int(r.waited) <= most, "it waited %d tick(s)" % int(r.waited))
	r = _case(60.0, true)
	_expect(int(r.hits) == 0, "a rival held out of reach: it meets nothing (%d hits, waited %d)" % [int(r.hits), int(r.waited)])
	r = _case(0.0, false)
	_expect(int(r.hits) == 1 and int(r.waited) == 0, "in reach, it doesn't wait (waited %d, %d hit)" % [int(r.waited), int(r.hits)])
	DirBrawl.cfg().give.sureWaitTicks = 0
	r = _case(60.0, false)
	DirBrawl.cfg().give.sureWaitTicks = most
	_expect(int(r.hits) == 1 and float(r.dx) > rc, "negative control, no wait: it lands from too far (%.1f), so this check can see the fault" % float(r.dx))
	print("sure_reach_check: %s" % ("passed" if failed == 0 else "FAILED (%d)" % failed))
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## Plays seed 1 to a brawl with both fighters locked and no blow on the way, puts D gap units past striking distance, and
## throws A's sure blow with a lead of one tick. Returns the damaging hits on D, the distance at the first, and the waits.
func _case(gap: float, hold: bool) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": true, "p2": true}, {})
	var ex = null
	var found := false
	while S.tick < 20000 and not found:
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		ex = S.dirS.ex
		found = ex != null and DirBrawl.isBrawl(ex) and ex.branch == "" and ex.A.state == "locked" and ex.D.state == "locked" and ex.A.stunTicks == 0 and ex.D.stunTicks == 0 and _noStrike(ex)
	var out := {"hits": 0, "dx": 0.0, "waited": 0}
	if not found:
		_expect(false, "no brawl to test in")
		return out
	var f = ex.A
	var o = ex.D
	var off: float = float(DirData.contact().offset) + gap
	var side: float = SimMathx.jsign(SimWrap.sdx(f.x, o.x))
	o.x = SimWrap.wrap(f.x + side * off)
	o.y = f.y
	DirBrawl.blowAt(S, ex, f, DirBrawl.LIGHT, 1, 1.0, {"sure": true})
	var arg = null
	for b in ex.beats:
		if not b.done and b.op == "strike" and b.args != null and bool(b.args.get("sure", false)):
			arg = b.args
	var slot: int = S.fighters.find(o)
	var me: int = S.fighters.find(f)
	for _k in range(24):
		if hold:
			o.x = SimWrap.wrap(f.x + side * off)
		SimCore.step(S)
		for e in S.out.fx:
			if e.type == "damage" and e.number and e.amount > 0.0 and int(e.victim) == slot and int(e.attacker) == me:
				out.hits += 1
				if int(out.hits) == 1:
					out.dx = absf(SimWrap.sdx(f.x, o.x))
		S.out.fx.clear()
		S.out.feed.clear()
		if S.dirS.ex != ex or int(out.hits) > 0:
			break
	if arg != null:
		out.waited = int(arg.get("waited", 0))
	SimCore.dispose(S)
	return out


func _noStrike(ex) -> bool:
	for b in ex.beats:
		if not b.done and b.op == "strike":
			return false
	return true
