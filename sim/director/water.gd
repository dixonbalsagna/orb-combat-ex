class_name DirWater
## A fighter dropped into water surfaces (Game Design's rulings-2026-10-26 row 6, on 23b item 7): a drop
## (SimFighter.drop, the zip's knock-down) that takes him under the water's surface brings him up to it within
## water.surfaceTicks (30) live ticks of going under, whatever he presses, rising over the last riseTicks. He counts as
## landed when he surfaces (a rally's end reads it: under()). A launched body is World's (its surfacing rule in
## WorldContact.moveAir); a fighter who goes under by his own choice is never brought up. The water is World's:
## WorldWater.surfaceAt (the sea, lakes, rivers, a filled trench), and water that is waded (WorldFill.wading) is not under.
## Behind data/director/interrupts.json water.enabled (false): off, nothing is written. State: two f.act.dirI slots after
## the chase's, sized only when written.

const WT_IN: int = 0     # the live tick his drop took him under, plus 1; 0 none
const WT_UP: int = 1     # 1 while he rises to the surface
const WT_N: int = 2
const DRY: float = -1.0e9


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("water", {})


static func on(S: SimState) -> bool:
	return DirInterrupt.on() and bool(cfg().get("enabled", false))


static func _base() -> int:
	if _baseAt < 0:
		_baseAt = DirChase._base() + DirChase.CH_N
	return _baseAt   # a constant: the chain is walked once


static var _baseAt: int = -1


static func _g(f, k: int) -> int:
	var i: int = _base() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	var b: int = _base()
	if f.act.dirI.size() < b + WT_N:   # sized: every part before this one is (it follows DirGrapple.END)
		DirGrapple._size(f)
		if f.act.dirI.size() < b + WT_N:
			f.act.dirI.resize(b + WT_N)
	f.act.dirI[b + k] = v


## The water's surface at x (World's), or DRY where there is none or it is waded.
static func top(S: SimState, x: float) -> float:
	var w: float = WorldWater.surfaceAt(S, x)
	if w <= DRY * 0.5 or WorldFill.wading(S, x):
		return DRY
	return w


## True while f is under after a drop, or rising from it: not landed yet.
static func under(f) -> bool:
	return _g(f, WT_IN) > 0 or _g(f, WT_UP) == 1


## Each live tick (DirExchange.dirUpdate): a drop under the water is brought up within surfaceTicks.
static func tick(S: SimState) -> void:
	if not on(S):
		return
	var c: Dictionary = cfg()
	var now: int = DirBrawl._now(S)
	for f in S.fighters:
		if _g(f, WT_UP) == 1:
			if f.rush == null:
				_landed(S, f)   # he is at the surface
			continue
		var wi: int = _g(f, WT_IN)
		if wi == 0 and f.state != "dropped":
			continue   # in no drop, and not dropping: the water is not read
		var w: float = top(S, f.x)
		var below: bool = w > DRY and f.y < w
		if wi == 0:
			if f.state == "dropped" and below:
				_s(f, WT_IN, now + 1)   # his drop has taken him under
			continue
		if f.state == "launched" or f.state == "down":
			_s(f, WT_IN, 0)   # something else took him (a send): not a drop's any more
		elif not below:
			_landed(S, f)   # he came up by himself, or out of the water
		elif now - (wi - 1) >= int(c.get("surfaceTicks", 30)) - int(c.get("riseTicks", 10)):
			_surface(S, f, w, int(c.get("riseTicks", 10)))


## f is brought up to the water's surface w over `ticks`, whatever he presses: his drop ends here.
static func _surface(S: SimState, f, w: float, ticks: int) -> void:
	SimFighter.dropEnd(S, f, "water")   # (nothing if the drop's ticks already ran out: he was free in the water)
	var r := SimState.Rush.new()
	r.px = f.x
	r.py = w
	r.pz = f.z
	r.end = S.T + float(maxi(1, ticks)) * SimConst.DT
	f.rush = r
	f.vx = 0.0
	f.vy = 0.0
	_s(f, WT_UP, 1)
	SimFx.cue(S, f, "water", "surface", "")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.n = S.tick + maxi(1, ticks)
	e.y = w


## He has surfaced: landed (the cue "surfaced").
static func _landed(S: SimState, f) -> void:
	_s(f, WT_UP, 0)
	_s(f, WT_IN, 0)
	SimFx.cue(S, f, "water", "surfaced", "")
