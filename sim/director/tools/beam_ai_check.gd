extends SceneTree
## The computer through the stick beam's own move (DirBeamMove ownMove.ai; docs/director/beams-own-move-plan.md step 3):
##   godot --headless --path . --script res://sim/director/tools/beam_ai_check.gd
## A computer fighter against an idle player, until its first beam: with the move on it charges as a hold (no exchange, its rival free),
## lets go at its level's stage, pays that stage, and its beam's exchange starts at the release; its pacing keeps its signature wait.
## Off, its signature is the old request: the exchange starts at once and locks its rival through the charge.
## Ends on the verdict line.

var failed: int = 0
const CAP: int = 9000


func _init() -> void:
	DirStick.setForce(1)
	DirBeamPlay.setFrontForce(1)
	DirBeamMove.setForce(1)
	DirBeamMove.setAiForce(1)
	_on()
	DirBeamMove.setAiForce(0)
	_off()
	DirBeamMove.setAiForce(-1)
	DirBeamMove.setForce(-1)
	DirBeamPlay.setFrontForce(-1)
	DirStick.setForce(-1)
	print("BEAM AI: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _match(seed: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": true, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.hp = 100000.0
	S.fighters[1].ai = null
	S.fighters[0].ki = 100.0
	return S


func _on() -> void:
	var S := _match(7)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var chargeAt: int = -1
	var lockedInCharge: int = 0
	var exInCharge: int = 0
	var startAt: int = -1
	var paid: float = -1.0
	var kiBefore: float = 0.0
	var stageAt: int = 0
	var fired: bool = false
	for t in range(CAP):
		var was3: bool = DirStick._g(A, DirStick.ST_ON) == 3
		kiBefore = A.ki
		var st0: int = DirBeamMove.stage(A)
		SimCore.step(S, [null, SimIntent.new()])
		for e in S.out.fx:
			if e.type == "cue" and e.kind == "beam_fire" and int(e.actor) == 0 and startAt >= 0:
				fired = true
		S.out.fx.clear()
		S.out.feed.clear()
		var is3: bool = DirStick._g(A, DirStick.ST_ON) == 3
		if is3 and chargeAt < 0:
			chargeAt = S.tick
		if is3 and not DirBeamMove.pending(A):
			if S.dirS.ex != null and S.dirS.ex.kind == "sig" and S.dirS.ex.A == A:
				exInCharge += 1
			if D.state == "locked":
				lockedInCharge += 1
		if chargeAt >= 0 and startAt < 0 and S.dirS.ex != null and S.dirS.ex.kind == "sig" and S.dirS.ex.A == A:
			startAt = S.tick
			stageAt = st0
			paid = kiBefore - A.ki
		if fired:
			break
	var price: float = float(DirBeamMove.cfg().price[maxi(0, stageAt - 1)]) if stageAt > 0 else -1.0
	print("      on: charged at %d, its exchange at %d (stage %d, paid %.1f against %.1f), fired %s, wait %.1f" % [chargeAt, startAt, stageAt, paid, price, str(fired), A.sigReadyT])
	_expect(chargeAt > 0 and startAt > chargeAt, "the computer's beam starts as a hold, and its exchange comes at the release (%d ticks later)" % (startAt - chargeAt))
	_expect(exInCharge == 0 and lockedInCharge == 0, "nobody is locked while it charges (%d ticks in an exchange, %d its rival locked)" % [exInCharge, lockedInCharge])
	_expect(stageAt >= 1 and absf(paid - price) < 0.2 and fired, "it lets go at a stage, pays that stage (%.1f), and fires" % paid)
	_expect(A.sigReadyT > S.T, "its pacing keeps its signature wait (ready at %.1f)" % A.sigReadyT)
	SimCore.dispose(S)


func _off() -> void:
	var S := _match(7)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var startAt: int = -1
	var holds: int = 0
	var lockedFor: int = 0
	for t in range(CAP):
		SimCore.step(S, [null, SimIntent.new()])
		S.out.fx.clear()
		S.out.feed.clear()
		if DirStick._g(A, DirStick.ST_ON) == 3:
			holds += 1
		var sig: bool = S.dirS.ex != null and S.dirS.ex.kind == "sig" and S.dirS.ex.A == A
		if sig and startAt < 0:
			startAt = S.tick
		if sig and D.state == "locked":
			lockedFor += 1
		if startAt >= 0 and not sig:
			break
	_expect(startAt > 0 and holds == 0 and lockedFor > 0, "off, the computer's signature is the old request: no hold, its exchange locks its rival (%d ticks)" % lockedFor)
	SimCore.dispose(S)
