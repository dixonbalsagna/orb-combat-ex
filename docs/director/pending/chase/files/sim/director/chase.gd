class_name DirChase
## The AI's chase of a launch it threw (Game Design's rulings-2026-10-22.md 5d; docs/design/fight-feel.md section 1, the
## glide: the attacker can chase or zip). Behind data/director/ai.json chase.enabled (false: nothing runs, no slot is
## written, no cue is sent).
##  - At a send of its own (the rival launched by it, not a set piece's), the AI draws once (keyed) against its level's
##    chaseShare, times skyMul when the send goes up into open sky (a juggle: rising faster than it travels, no building
##    over him), and only with the zip's ki (it does not pay it: the chase is free flight; a zip at the arrival pays as
##    ever). It starts no sooner than its reaction time after the send.
##  - The chase: dashed free flight straight at the sent body, for as long as he is launched (at most maxTicks). The
##    approach cap of 4d lifts for it (DirAI._capApproach), since the camera rides with it. It ends when he lands,
##    is caught, or the AI is not free.
## The cue: SimFx.cue kind "chase", text "start" or "end", target the sent fighter's slot, n his launch number.
## State: f.act.dirI slots after the wall kick's (sized only when the switch is on).

const CH_SEEN: int = 0    # the rival's launch number it has drawn for, plus 1
const CH_AT: int = 1      # the live tick it may start (its reaction time after the send), plus 1; 0 no chase drawn
const CH_ON: int = 2      # the live tick its chase started, plus 1; 0 none
const CH_N: int = 3


static func cfg() -> Dictionary:
	return DirAI.skill().get("chase", {})


static func on() -> bool:
	return bool(cfg().get("enabled", false))


static func _base() -> int:
	return DirWallKick._base() + DirWallKick.WK_N


static func _g(f, k: int) -> int:
	var i: int = _base() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirGrapple._size(f)
	if f.act.dirI.size() < _base() + CH_N:
		f.act.dirI.resize(_base() + CH_N)
	f.act.dirI[_base() + k] = v


## The AI's stick each tick (DirAI.aiInput, before the approach cap): true while it chases, with the stick set.
static func steer(S: SimState, f, o, i: SimIntent) -> bool:
	if not on() or f.ai == null or o == null:
		return false
	var mine: bool = o.state == "launched" and o.launchBy == f and not o.launchSpecial
	if not mine:
		if _g(f, CH_ON) > 0:
			_end(S, f, o)
		return false
	if _g(f, CH_SEEN) != o.launchN + 1:
		_s(f, CH_SEEN, o.launchN + 1)
		_s(f, CH_AT, 0)
		_s(f, CH_ON, 0)
		var sh: float = float(DirAI.lv().get("chaseShare", 0.0))
		if _sky(S, o):
			sh *= float(cfg().get("skyMul", 1.0))
		var zipKi: float = float(DirZip.cfg().get("strike", {}).get("ki", 20.0))
		if f.ki >= zipKi and SimRng.keyed(int(S.game.seed), "chase.ai", o.launchN * 4 + S.fighters.find(f)) < sh:
			_s(f, CH_AT, S.tick + int(DirAI.skill().get("reactTicks", 14)) + 1)
	if _g(f, CH_ON) == 0:
		if _g(f, CH_AT) == 0 or S.tick + 1 < _g(f, CH_AT) or f.state != "free" or f.rush != null:
			return false
		_s(f, CH_ON, S.tick + 1)
		_cue(S, f, o, "start")
		SimEvents.feed(S, f.name + " CHASES", "after " + o.name + "'s flight: dashed, the approach cap lifted")
	if f.state != "free" or f.rush != null or S.tick + 1 - _g(f, CH_ON) > int(cfg().get("maxTicks", 90)):
		_end(S, f, o)
		return false
	var dx: float = SimWrap.sdx(f.x, o.x)
	var dy: float = o.y - f.y
	var l: float = maxf(SimDetMath.hypot(dx, dy), 1.0)
	i.mx = dx / l
	i.my = dy / l
	i.dash = true
	return true


## The send goes up into open sky: he rises faster than he travels, and no building stands over him.
static func _sky(S: SimState, o) -> bool:
	if o.vy <= absf(o.vx):
		return false
	for b in S.buildings:
		if b.alive and absf(SimWrap.sdx(o.x, b.x)) <= b.w * 0.5 and b.h + WorldTerrain.groundY(S, b.x) > o.y:
			return false
	return true


static func _end(S: SimState, f, o) -> void:
	_s(f, CH_ON, 0)
	_s(f, CH_AT, 0)
	_cue(S, f, o, "end")


static func _cue(S: SimState, f, o, text: String) -> void:
	SimFx.cue(S, f, "chase", text, "")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(o))
	e.n = o.launchN
