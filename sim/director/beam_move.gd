class_name DirBeamMove
## The stick beam as its own move (docs/director/beams-own-move-plan.md step 1; Game Design's beams-third-play.md section 2,
## playable-build.md section 2, beam-answers-2.md section 1). Behind data/director/interrupts.json beamPlays.front.ownMove (off),
## on the stick (switches.rightStick) with the stationary beam (front.stationary):
##  - RB and the stick is the charge, and nothing else: no exchange runs, so nobody is locked while he charges. It's armoured from
##    its first tick (stick.json armour.beamFromTicks) and never fires by itself.
##  - Its stages: the count, 2 + round(4 x level) with power-scale.md's level (tier and power), is taken as the charge starts. Stage s
##    comes at stageTicks[s-1] live ticks held, and never higher than his energy affords. At the top he pays topDrainPerSec, and steps
##    down a stage when he can't. Each change is the cue stick_stage (text the stage, k the stage, n the count; "capped" when what he
##    can pay stops it).
##  - The release pays its stage's price and starts the beam's exchange at once, with no signature wait and no 45: a brawl he's in
##    gives way then (DirBrawl.end). It fires once its target has been free to act freeTicks (0.3 s, beams-third-play.md section 3);
##    till then the lit hand holds, up to maxWaitTicks, and says "soon" as it starts waiting. A release that can't fire says why:
##    stick_refused "beam" with "ki" or "late".
##  - Its hit does dmgUnit x dmgMul[s-1] (DirBeam.opBeamImpact), and the beam lasts lastsSec[s-1] past its arrival (DirBeamPlay.fire).
##  - While the stick holds a charge, a beam's or a plain strike's, his energy doesn't refill, from the press to the release
##    (refillHeld, read by SimFighter through SimDir; Game Design, playable-build.md section 2).
## A release before stage 1 is the quick, as DirStick has it. State: integers after DirOutside's on f.act.dirI.

const M_FREE: int = 0    # the live tick he was last not free to act, plus 1 (on every fighter, while this is on)
const M_COUNT: int = 1   # the hold's stage count, taken as it started; 0 no hold
const M_STAGE: int = 2   # the stage it's at; plus CAPPED once what he can pay has stopped it
const M_PEND: int = 3    # a release waiting for its target to be free: its stage; 0 none
const M_PAT: int = 4     # the live tick of that release, plus 1
const M_HELD: int = 5    # the live ticks it was held
const M_FIRED: int = 6   # the stage of the beam he's fired, for its hit and its life; 0 none
const M_AIT: int = 7     # the computer's hold: the stage it lets go at; 0 none
const M_N: int = 8
const CAPPED: int = 64

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on
static var _strikeForce: int = -1   # tools: the plain hold's stages, as _force
static var _aiForce: int = -1       # tools: the computer through this move, as _force


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirBeamPlay.frontCfg().get("ownMove", {})


static func on() -> bool:
	return DirStick.on() and DirBeamPlay.stationary() and (bool(cfg().get("enabled", false)) if _force < 0 else _force == 1)


static func _b() -> int:
	return DirOutside._b() + DirOutside.O_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + M_N:
		f.act.dirI.resize(_b() + M_N)
	f.act.dirI[_b() + k] = v


## power-scale.md's level: 0.8 of it from his tier, 0.2 from his power, 0 at base with none to 1 at the top with all.
static func level(f) -> float:
	return clampf(0.8 * (float(f.tier) - 1.0) / 3.0 + 0.2 * float(f.power) / 100.0, 0.0, 1.0)


## The stages a hold of his can reach: 2 at base, 6 at the top.
static func stageCount(f) -> int:
	return clampi(2 + int(SimMathx.jround(4.0 * level(f))), 2, 6)


## Once a live tick, first in DirStick.tick: who is free to act, for the gate.
static func stamp(S: SimState) -> void:
	if not on():
		return
	var now: int = DirBrawl._now(S)
	for f in S.fighters:
		if DirStick._cant(S, f):
			_s(f, M_FREE, now + 1)


## True when f has been free to act for freeTicks.
static func freeLong(S: SimState, f) -> bool:
	return DirBrawl._now(S) - (_g(f, M_FREE) - 1) >= int(cfg().freeTicks)


## The charge starts (DirStick._start): its stage count is taken now.
static func began(S: SimState, f) -> void:
	if not on():
		return
	_s(f, M_COUNT, stageCount(f))
	_s(f, M_STAGE, 0)
	_s(f, M_PEND, 0)


## The hold goes on (DirStick.tick, each live tick): the stage it's reached, what it can pay, the top's price.
static func holding(S: SimState, f, held: int, dt: float) -> void:
	var c: Dictionary = cfg()
	if _g(f, M_COUNT) <= 0:
		began(S, f)
	_climb(S, f, held, dt, c.stageTicks, c.price, float(c.topDrainPerSec))


## The ladder, for a beam's hold or a plain one: stage by the clock (ticks), no higher than he can pay (prices), the top's price (drain a second).
static func _climb(S: SimState, f, held: int, dt: float, ticks: Array, prices: Array, drain: float) -> void:
	var n: int = _g(f, M_COUNT)
	if n <= 0:
		return
	var clock: int = 0
	while clock < n and held >= int(ticks[clock]):
		clock += 1
	if clock == n and held > int(ticks[n - 1]) and f.ki >= float(prices[n - 1]):
		f.ki = maxf(0.0, f.ki - drain * dt)   # holding at the top costs: he pays for each tick of it
	var st: int = clock
	while st > 0 and f.ki < float(prices[st - 1]):
		st -= 1
	var was: int = _g(f, M_STAGE)
	var capped: bool = st < clock
	if st != (was & (CAPPED - 1)) or (capped and (was & CAPPED) == 0):
		_s(f, M_STAGE, st | (CAPPED if capped else 0))
		SimFx.cue(S, f, "stick_stage", str(st), "capped" if capped and (was & CAPPED) == 0 else "")
		var e = S.out.fx[S.out.fx.size() - 1]
		e.k = float(st)
		e.n = n


## The stage the hold is at.
static func stage(f) -> int:
	return _g(f, M_STAGE) & (CAPPED - 1)


# ---- the computer through this move (beams-own-move-plan.md step 3; beams-third-play.md section 2) ---------------------------

static func setAiForce(v: int) -> void:
	_aiForce = v


## The computer's beams, its signature included, go through the same hold and release as a player's (ownMove.ai): nobody is locked
## while it charges, and the gate holds its fire. It lets go at its level's share of its stage count (ownMove.aiStage).
static func aiOn() -> bool:
	return on() and (bool(cfg().get("ai", false)) if _aiForce < 0 else _aiForce == 1)


## Where the computer chose its signature (DirAI.aiInput, DirBrawl's choice): with this on it starts a beam's hold instead, and True is
## returned; the press isn't made.
static func aiStart(S: SimState, f, i) -> bool:
	if not aiOn() or f.ai == null or DirStick._g(f, DirStick.ST_ON) != 0:
		return false
	var lvName: String = DirAI.level if DirAI.level != "" else String(DirAI.skill().get("level", "medium"))
	var n: int = stageCount(f)
	var share: float = float(cfg().get("aiStage", {}).get(lvName, 1.0))
	_s(f, M_AIT, clampi(int(SimMathx.jround(float(n) * share)), 1, n))
	_aiStick(S, f, i)
	i.rsStart = true
	return true


## Each tick of the computer's hold (first in DirAI.aiInput): the stick held toward its rival until its stage is there, or it can go no
## higher, then let go. True while it's busy with it, a release waiting on the gate included.
static func aiHolding(S: SimState, f, i) -> bool:
	var t: int = _g(f, M_AIT)
	if t == 0:
		return false
	if DirStick._g(f, DirStick.ST_ON) != 3:
		_s(f, M_AIT, 0)   # fired, refused or lost: it's free again
		return false
	if pending(f):
		return true
	var st: int = stage(f)
	var top: int = _g(f, M_COUNT)
	if st >= t or st >= top or (_g(f, M_STAGE) & CAPPED) != 0:
		i.rsRelease = true
		i.rsMask = DirStick.RB
		i.stanceMask |= DirStick.RB
		return true
	_aiStick(S, f, i)
	return true


static func _aiStick(S: SimState, f, i) -> void:
	var o = DirBrawl.rivalOf(S, f)
	i.rsHeld = true
	i.rsMask = DirStick.RB
	i.stanceMask |= DirStick.RB
	i.rsDir = SimStrikeRead.RIGHT if SimWrap.sdx(f.x, o.x) >= 0.0 else SimStrikeRead.LEFT


# ---- the plain hold's stages (beams-own-move-plan.md step 2; stick.json strikeStages) -------------------------------------

static func setStrikeForce(v: int) -> void:
	_strikeForce = v


static func strikeCfg() -> Dictionary:
	return DirStick.cfg().get("strikeStages", {})


## The right stick's plain hold climbs the same ladder (beam-answers-2.md section 1): its count by power, the same clock, no time limit,
## topDrainPerSec at the top. Its blow's damage and stun stop growing at levelCap (stage 3): the stages past it are the swat's and the punch's.
static func strikeOn() -> bool:
	return DirStick.on() and (bool(strikeCfg().get("enabled", false)) if _strikeForce < 0 else _strikeForce == 1)


## A plain hold's request (DirStick._go): its count is taken now.
static func strikeBegan(S: SimState, f) -> void:
	if not strikeOn():
		return
	_s(f, M_COUNT, stageCount(f))
	_s(f, M_STAGE, 0)


## Each live tick he holds it, from the request.
static func strikeHolding(S: SimState, f, held: int, dt: float) -> void:
	var c: Dictionary = strikeCfg()
	_climb(S, f, held, dt, c.stageTicks, _strikePrices(), float(c.topDrainPerSec))


## A stage's price for a plain blow: its level's own (stick.json levels, over the quick's), the cap's past it.
static func _strikePrices() -> Array:
	var lv: Array = DirStick.cfg().levels
	var cap: int = int(strikeCfg().levelCap)
	var out: Array = []
	for s in range(1, 7):
		out.append(float(lv[mini(s, cap)].ki) - float(lv[0].ki))
	return out


## The level its blow lands at: the stage, up to levelCap.
static func strikeLevel(f) -> int:
	return mini(stage(f), int(strikeCfg().levelCap))


## The release (DirStick.tick). False before stage 1: that's the quick, DirStick's own. True when this move takes it: it fires now,
## or waits for its target to be free.
static func released(S: SimState, f, held: int) -> bool:
	var st: int = stage(f)
	if st <= 0:
		if _g(f, M_COUNT) > 0 and held >= int(cfg().stageTicks[0]):
			SimFx.cue(S, f, "stick_refused", "beam", "ki")   # it reached a stage he couldn't pay for: no beam, and it says so
			lost(f)
			return true
		lost(f)
		return false
	_s(f, M_PEND, st)
	_s(f, M_PAT, DirBrawl._now(S) + 1)
	_s(f, M_HELD, held)
	if not freeLong(S, DirBrawl.rivalOf(S, f)):
		SimFx.cue(S, f, "stick_refused", "beam", "soon")   # his target hasn't been free 0.3 s: the lit hand holds, and UI says why (hud-spec section 84)
	return true


## True while a release of his waits for its target.
static func pending(f) -> bool:
	return _g(f, M_PEND) != 0


## A waiting release, each live tick: it fires when it can. True when it's over, fired or refused (DirStick clears the hold).
static func tryFire(S: SimState, f) -> bool:
	var st: int = _g(f, M_PEND)
	if st <= 0:
		return true
	var D = DirBrawl.rivalOf(S, f)
	if DirBrawl._now(S) - (_g(f, M_PAT) - 1) > int(cfg().maxWaitTicks):
		SimFx.cue(S, f, "stick_refused", "beam", "late")   # his target was never free long enough
		f.beamCharge = null
		lost(f)
		return true
	if S.game.ko != null or not freeLong(S, D):
		return false   # the lit hand holds a little longer
	if f.ki < float(cfg().price[st - 1]):
		SimFx.cue(S, f, "stick_refused", "beam", "ki")
		f.beamCharge = null
		lost(f)
		return true
	var ex = DirBrawl.exOf(S)
	if ex != null:
		if DirBrawl.isBrawl(ex) and ex.branch == "" and not ex.cancel and (ex.A == f or ex.D == f) and not DirBrawl._setPiece(ex):
			DirBrawl.end(S, ex, "beam")   # point blank: the brawl gives way now, at the release, not as the charge began
		else:
			return false   # something else is playing: the lit hand waits for it
	DirExchange.ownBeam = true
	var r: int = DirExchange.startBeam(S, f)
	DirExchange.ownBeam = false
	if r != DirExchange.STARTED:
		return false
	f.ki = maxf(0.0, f.ki - float(cfg().price[st - 1]))   # its stage's price, paid as it goes
	if f.ai != null:
		f.sigReadyT = S.T + DirBeam.sigCooldown(f)   # the computer's pacing reads its signature wait: its own choice, not the move's
	_s(f, M_FIRED, st)
	var held: int = _g(f, M_HELD)
	_s(f, M_PEND, 0)
	_s(f, M_COUNT, 0)
	_s(f, M_STAGE, 0)
	SimFx.cue(S, f, "beam_stage", str(st), "")
	DirBeamPlay.fromStick(S, f, held)   # the hold was its charge: it fires after releaseTell
	return true


## The hold is over without a beam: lost, cancelled or refused.
static func lost(f) -> void:
	if _g(f, M_COUNT) != 0 or _g(f, M_PEND) != 0 or _g(f, M_STAGE) != 0:
		_s(f, M_COUNT, 0)
		_s(f, M_STAGE, 0)
		_s(f, M_PEND, 0)


## The stage of the beam A fired, while its exchange plays; 0 for any other beam.
static func fired(A) -> int:
	return _g(A, M_FIRED) if on() else 0


## Its hit (DirBeam.opBeamImpact): the stage's share of the signature's, or base when it isn't this move's.
static func hitDamage(A, base: float) -> float:
	var st: int = fired(A)
	if st <= 0:
		return base
	return float(cfg().dmgUnit) * float(cfg().dmgMul[st - 1]) * base / 230.0


## How long its beam lasts past its arrival (DirBeamPlay.fire); -1 when it isn't this move's.
static func lasts(A) -> float:
	var st: int = fired(A)
	return float(cfg().lastsSec[st - 1]) if st > 0 else -1.0


## True while f's stick holds a charge, a beam's or a plain strike's: his energy doesn't refill (SimFighter's regen, through SimDir.refillHeld),
## from the press to the release. A beam let go and waiting on the gate refills again.
static func refillHeld(f) -> bool:
	if not on() or not f.input.rsHeld:
		return false
	return DirStick._g(f, DirStick.ST_ON) != 0 or DirStick._g(f, DirStick.ST_PEND) != 0


## Its exchange is over (DirBeamPlay.onEnd).
static func onEnd(S: SimState, ex) -> void:
	if _g(ex.A, M_FIRED) != 0:
		_s(ex.A, M_FIRED, 0)
