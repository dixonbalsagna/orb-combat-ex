class_name DirEnding
extends RefCounted
## How a match always ends (docs/design/spec-wounds.md 1b-end). A KO only comes from a finisher, and hit points end nothing.
## - A player with no input for idleSec: the wear he takes is idleWearMul times. After pushSec, on the brink he's opened, so his rival's next
##   decisive win is the finisher, unless the rival's idle too. Any input ends it at once. An AI is never idle.
## - The time cap (finishers.json timeCapAt): both go on the brink, Rallies stop, and every decisive win is a finisher (DirExchange.decisive).
## - lastAt: the fighter with less wear gets his finisher, with no contest; level wear with anyone playing breaks by seed. Nobody's played
##   since the cap, and wear level: a no-contest, and a cue.
## Off, no slot is sized and nothing changes.

const E_IDLE: int = 0   # live ticks with no input from him
const E_ADD: int = 1    # the wear the cap put on him: it doesn't count at lastAt
const E_DONE: int = 2   # on the first fighter: 1 the last event has fired, 2 it was a no-contest
const E_N: int = 3

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("ending", {})


static func on() -> bool:
	return bool(cfg().get("enabled", false)) if _force < 0 else _force == 1


static func _b() -> int:
	return DirArc._b() + DirArc.A_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + E_N:
		f.act.dirI.resize(_b() + E_N)
	f.act.dirI[_b() + k] = v


## Anything he's doing: either stick, a button held or pressed.
static func _input(f) -> bool:
	var i = f.input
	return i.mx != 0.0 or i.my != 0.0 or i.light or i.heavy or i.sig or i.lightHeld or i.heavyHeld or i.sigHeld or i.guard or i.dodge or i.sprint or i.power or i.dash or i.charge or i.rsHeld or i.rsStart or i.stanceMask != 0


static func idle(f) -> bool:
	return on() and f.ai == null and _g(f, E_IDLE) >= int(float(cfg().idleSec) * DirData.TICKS_PER_SEC)


## Long enough that the finisher's pushed on him.
static func pushed(f) -> bool:
	return on() and f.ai == null and _g(f, E_IDLE) >= int(float(cfg().pushSec) * DirData.TICKS_PER_SEC)


## SimWounds.addWear's factor.
static func wearMul(f) -> float:
	return float(cfg().idleWearMul) if idle(f) else 1.0


## A share of how well he's doing, for a read that used to be his hit points, which are gone a minute in.
static func standing(f) -> float:
	return SimWounds.vitality(f) if on() else float(f.hp) / maxf(1.0, float(f.maxhp))


static func noContest(S: SimState) -> bool:
	return on() and _g(S.fighters[0], E_DONE) == 2


static func _worn(f) -> int:
	var n: int = 0
	for r in range(f.wear.size()):
		n += int(f.wear[r])
	return n - _g(f, E_ADD)


static func _toBrink(S: SimState, f) -> void:
	if f.brink:
		return
	var add: int = maxi(0, int(f.wd.stageAt[2]) - int(f.wear[SimWounds.CORE]))
	f.wear[SimWounds.CORE] += add
	_s(f, E_ADD, _g(f, E_ADD) + add)
	SimWounds.updateStages(S, f)


## Once a live tick, after the time cap's own check.
static func tick(S: SimState) -> void:
	if not on() or S.game.ko != null:
		return
	var pair: Array = [S.fighters[0], S.fighters[1]]
	for k in [0, 1]:
		var f = pair[k]
		if f.ai != null:
			continue
		if _input(f):
			if _g(f, E_IDLE) != 0:
				_s(f, E_IDLE, 0)
			continue
		_s(f, E_IDLE, _g(f, E_IDLE) + 1)
	for k in [0, 1]:
		var f = pair[k]
		var o = pair[1 - k]
		if pushed(f) and f.brink and not f.brinkOpen and not idle(o):
			DirExchange._openBrink(S, o, f)
	if not S.game.timeCap:
		return
	for f in pair:
		_toBrink(S, f)
	if S.T >= float(cfg().lastAt) and _g(pair[0], E_DONE) == 0:
		_last(S, pair)


## Nobody's played for the time since the cap: two players with no input.
static func _nobody(pair: Array) -> bool:
	var need: int = int((float(cfg().lastAt) - DirData.timeCapAt()) * DirData.TICKS_PER_SEC)
	return pair[0].ai == null and pair[1].ai == null and _g(pair[0], E_IDLE) >= need and _g(pair[1], E_IDLE) >= need


static func _last(S: SimState, pair: Array) -> void:
	var a: int = _worn(pair[0])
	var b: int = _worn(pair[1])
	if a == b and _nobody(pair):
		_s(pair[0], E_DONE, 2)
		SimFx.cue(S, null, "no_contest", "", "")
		SimEvents.feed(S, "NO CONTEST", "nobody's touched anything: straight to the rematch")
		return
	_s(pair[0], E_DONE, 1)
	var first: bool = a < b if a != b else SimRng.keyed(int(S.game.seed), "ending.level", 0) < 0.5
	var W = pair[0] if first else pair[1]
	var L = pair[1] if first else pair[0]
	SimEvents.feed(S, "THE PLANET GIVES WAY", W.name + " has the less wear, and the finisher")
	var ex = S.dirS.ex
	if ex != null and DirExchange.finisherPlanned(ex):
		return   # one's already on its way, and at the cap it can't be survived
	if ex == null:
		ex = DirExchange.startZip(S, W, L, "heavy")
	DirExchange.startFinisher(S, ex, W, L)
