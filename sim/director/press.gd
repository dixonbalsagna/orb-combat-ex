class_name DirPress
## A player's press waits at most a beat after an exchange (Game Design's rulings-2026-10-22.md 7a; the press block of
## data/director/interrupts.json). The director's cooldown after an exchange (0.25 to 0.6 s) is the AI's pacing, and it
## keeps it; a player's request is held by it at most capTicks (6) after an exchange ends, setPieceCapTicks (12) after a
## set piece's end (a beam struggle, a clash, a throw, a finisher), whose outro the camera is still telling. The request
## is kept and thrown at the cap, never dropped; its press_ack "queued" carries the tick it is due. A cooldown set or
## raised by anything else (a lost lock, a live form step) holds a player as it holds the AI. Positional rules (the sent
## fighter's first move) are not this wait and stay.
## Only a player's fighter (f.ai null) is written: the AI's records never change, so the AI v AI golden doesn't move.
## State: one f.act.dirI slot after the mash run's (sized only when written); launch anywhere's follow it.

const PR_FREE: int = 0   # S.tick from which the cooldown no longer holds his request, plus 1; 0 none (it holds him as the AI)
const PR_N: int = 1


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("press", {})


static func on() -> bool:
	return int(cfg().get("capTicks", -1)) >= 0


static func _base() -> int:
	return DirMash._base() + DirMash.MS_N


static func _g(f, k: int) -> int:
	var i: int = _base() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirGrapple._size(f)
	if f.act.dirI.size() < _base() + PR_N:
		f.act.dirI.resize(_base() + PR_N)
	f.act.dirI[_base() + k] = v


## The cooldown's ticks still to run, as the step counts them.
static func _coolTicks(S: SimState) -> int:
	return int(ceil(S.dirS.cool * DirData.TICKS_PER_SEC - 0.0001)) if S.dirS.cool > 0.0 else 0


## An exchange ended and the director set its cooldown (DirExchange.endEx): each player in it is held at most the cap.
static func onEnd(S: SimState, ex) -> void:
	if not on():
		return
	var c: Dictionary = cfg()
	var cap: int = int(c.get("setPieceCapTicks", 12)) if _setPiece(S, ex) else int(c.get("capTicks", 6))
	for f in [ex.A, ex.D]:
		if f.ai == null:
			_s(f, PR_FREE, S.tick + mini(cap, _coolTicks(S)) + 1)


## The cooldown was set or raised by something other than an exchange's end (a lost lock, a live form step): a player
## waits it out as the AI does.
static func onCool(S: SimState) -> void:
	if not on():
		return
	for f in S.fighters:
		if f.ai == null and _g(f, PR_FREE) > 0:
			_s(f, PR_FREE, maxi(_g(f, PR_FREE), S.tick + _coolTicks(S) + 1))


## True while the director's cooldown holds A's request. A player's is not held by the match's opening cooldown
## (press.skipOpenCool: no exchange has started yet), and after an exchange at most the cap.
static func held(S: SimState, A) -> bool:
	if S.dirS.cool <= 0.0:
		return false
	if A.ai != null:
		return true
	if S.dirS.exN == 0 and bool(cfg().get("skipOpenCool", false)):
		return false
	if not on():
		return true
	var fr: int = _g(A, PR_FREE)
	return fr == 0 or S.tick + 1 < fr


## True when a fighter's queued request is free of the cooldown (DirExchange._drain goes on for it).
static func anyFree(S: SimState) -> bool:
	for f in S.fighters:
		if not SimAct.peek(f).is_empty() and not held(S, f):
			return true
	return false


## The ticks until the cooldown frees A's request (0: it doesn't hold him).
static func waitTicks(S: SimState, A) -> int:
	if not held(S, A):
		return 0
	var fr: int = _g(A, PR_FREE) if (A.ai == null and on()) else 0
	return (fr - 1 - S.tick) if fr > 0 else _coolTicks(S)


## A set piece's end: a beam struggle (a signature's exchange), a finisher, a clash (a heavy clash's template), a throw
## (the thrown fighter's no-regrab window is running).
static func _setPiece(S: SimState, ex) -> bool:
	if ex.kind == "sig" or ex.tpl == "finisher" or ex.branch == "finisher":
		return true
	for t in cfg().get("setPieceTags", []):
		if String(ex.tag).contains(String(t)):
			return true
	for f in [ex.A, ex.D]:
		if DirGrapple._g(f, DirGrapple.NOGRAB) > S.tick:
			return true
	return false
