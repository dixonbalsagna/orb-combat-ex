class_name DirStick
## The right stick's strike in the director (docs/design/right-hand-attacks-rulings.md section 2; Controls' second word:
## docs/controls/right-hand-attacks.md section 1). The stick's own class of blow: a flick is the quick strike, a hold charges
## it through three levels, and it stuns and puts him where it was aimed. It never sends him; B does that. Behind
## data/input/timing.json switches.rightStick (false): with it off nothing here runs and no slot is sized.
##  - One line through the brawl: a request is a Y press (DirExchange.requestAttack) that leaves a note here, so reach, the
##    lunge, the guard, a perfect block, a trade and a miss are all the brawl's own. DirBrawl._throw asks overlay for the
##    blow's numbers, and DirBrawl.contact hands a clean hit to landed.
##  - A flick and a hold share one wind-up, dwell less settle from the request (timing.json's strike: Game Design's 10). A stick
##    still out as it ends holds the blow back, a tick at a time, until the release or autoGoTicks. Past dwell it's a charge,
##    with the ladder Controls' reader has.
##  - Bare at every level: any blow that lands on his wind-up ends it, and the charge is lost. With armour.enabled (power-scale.md section 2),
##    past the quick flick a hold has B's armour, a beam's on the stick too: a light never stops it, and does lightMul of its damage. A medium
##    stops it before mediumUntilTicks. A heavy, a beam or a grab stops it. A dodge makes it miss, and he's open for missOpenTicks.
## State: integers after DirSwing's on f.act.dirI.

const PATH: String = "res://data/director/stick.json"

const ST_ON: int = 0     # 0 none, 1 winding, 2 charging, 3 a beam charging
const ST_AT: int = 1     # the live tick of the request, plus 1
const ST_DIR: int = 2    # 1 up, 2 down, 3 toward, 4 away
const ST_PEND: int = 3   # a request waiting for its blow: its direction, plus (the mask + 1) x 8; 0 none
const ST_PAT: int = 4    # the live tick that request was made, plus 1
const ST_STUN: int = 5   # on the one hit: 1 once he has been stick-stunned in this string
const ST_CT: int = 6     # the carry: live ticks left
const ST_CX: int = 7     # ... the x to go, x 16
const ST_CY: int = 8     # ... the height to go, x 16
const ST_Q0: int = 9     # the last quick strike's live tick, plus 1, by direction 1 to 4
const ST_Q1: int = 13    # the one before it
const ST_RL: int = 17    # a release before the wind-up ended (a long lunge, a request still waiting): its level, plus 1
const ST_BUF: int = 18   # a press waiting for him to be able to act: its direction, plus (the mask + 1) x 8, plus SWEPT; 0 none
const ST_BAT: int = 19   # the live tick it was made, plus 1
const ST_SOFT: int = 20   # a light has landed on this flick: it still lands, at softWorth, with no stun (lightStops false)
const ST_GUARD: int = 21  # this flick is on the guard layer: his guard holds through its wind-up and drops for its recovery (lightStops false)
const ST_N: int = 22
const SWEPT: int = 4096  # on ST_BUF: a hold a planned exchange swept up, waiting for his first free tick (pendFollow)
const RAW: int = 1024    # on ST_BUF (flickKeep): its direction is the stick's own, read relative to the rival when it goes
const RECOV: int = 2048  # on ST_BUF (flickKeep): made while he was launched, down or dropped, so it must be young when he's free
const LUNGE: int = 8192  # on ST_PEND: this request asked for the light lunge from the middle band (lungeLight)
const RL_SWEPT: int = 16  # on ST_RL: this strike is that swept hold, so its level counts from its own request

const UP: int = 1
const DOWN: int = 2
const TOWARD: int = 3
const AWAY: int = 4
const NAMES: Array = ["", "up", "down", "toward", "away"]
const LB: int = 1
const RB: int = 2
const LT: int = 8

static var _d = null
static var _text: String = ""
static var _force: int = -1   # tools: -1 Controls' switch, 0 off, 1 on
static var _rd = null         # Controls' reader, for its numbers and its ladder; holds no one's stick
static var _armourForce: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func _ensure() -> void:
	if _d == null:
		_text = FileAccess.get_file_as_string(PATH)
		_d = JSON.parse_string(_text)
		if not (_d is Dictionary):
			_d = {}


static func cfg() -> Dictionary:
	_ensure()
	return _d


static func dataText() -> String:
	_ensure()
	return _text


static func on() -> bool:
	return SimInputData.right_stick_on() if _force < 0 else _force == 1


## Tools: force the switch. -1 goes back to Controls'.
static func setForce(v: int) -> void:
	_force = v


static func _reader():
	if _rd == null:
		_rd = SimStrikeRead.new()
	return _rd


## The wind-up, live ticks from the request. A blow lands at the later of its end and the stick's return; a stick still out at the
## dwell is a charge (rule-of-cool-map.md section 5).
static func _wind() -> int:
	return int(cfg().windTicks)


static func _b() -> int:
	return DirSwing._b() + DirSwing.W_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	if f.act.dirI.size() < _b() + ST_N:
		DirPlane._size(f)
		f.act.dirI.resize(_b() + ST_N)
	f.act.dirI[_b() + k] = v


## The stick's screen direction as his: left and right by which side his rival is on, and none is toward.
static func relative(S: SimState, f, rsDir: int) -> int:
	if rsDir == SimStrikeRead.UP:
		return UP
	if rsDir == SimStrikeRead.DOWN:
		return DOWN
	if rsDir == SimStrikeRead.LEFT or rsDir == SimStrikeRead.RIGHT:
		var o = DirBrawl.rivalOf(S, f)
		var right: bool = SimWrap.sdx(f.x, o.x) >= 0.0
		return TOWARD if (rsDir == SimStrikeRead.RIGHT) == right else AWAY
	return TOWARD


# ---- the blow, by way of the brawl -------------------------------------------------------------------------------

## DirBrawl._throw, once its args are built: a request waiting makes this blow the stick's. Returns the live ticks to its
## contact.
static func overlay(S: SimState, f, o, args: Dictionary, o2: Dictionary, lead: int, close: int) -> int:
	if not on():
		return lead
	var pend: int = _g(f, ST_PEND)
	var light: bool = (pend & LUNGE) != 0 and int(args.get("bk", 0)) == DirBrawl.LIGHT   # a light lunge's arrival (lungeLight)
	if pend == 0 or (int(args.get("bk", 0)) != DirBrawl.MEDIUM and not light) or args.has("energy"):
		return lead
	_s(f, ST_PEND, 0)
	var c: Dictionary = cfg()
	var lv: Dictionary = c.levels[0]
	var dir: int = pend & 7
	var mask: int = ((pend >> 3) & 511) - 1
	args["stick"] = dir
	args["stickMask"] = mask
	args["stickL"] = 0
	var dr: Dictionary = _dirRow(S, f, dir, 0)
	args["stickReach"] = float(lv.reachBh) * float(dr.get("reachMul", 1.0))
	if not light:
		args["dmg"] = float(lv.worth) * DirBrawl._unit()   # (the medium's keys in their old order)
		args["wind"] = true
	o2["stick"] = true
	var more: float = float(lv.ki) - (0.0 if light else float(DirBrawl.cfg().medium.ki))
	if more > 0.0:
		f.ki = maxf(0.0, f.ki - more)
	if light:
		# Thrown as a light: the light's own time and worth, with the stick's direction, its stun and its carry (landed) and its cues.
		_s(f, ST_ON, 1)
		_s(f, ST_DIR, dir)
		_s(f, ST_SOFT, 0)
		_s(f, ST_GUARD, 1 if (mask & LB) != 0 else 0)
		SimFx.cue(S, f, "stick_start", NAMES[dir], str(mask))
		return lead
	var wind: int = _wind()
	DirBrawl._s(f, DirBrawl.HOLD_AT, DirBrawl._now(S) + close)
	DirBrawl._s(f, DirBrawl.CHG, 3)   # the medium's own button doesn't decide it: the stick does, below
	_s(f, ST_ON, 1)
	_s(f, ST_DIR, dir)
	_s(f, ST_SOFT, 0)
	_s(f, ST_GUARD, 1 if (mask & LB) != 0 else 0)
	SimFx.cue(S, f, "stick_start", NAMES[dir], str(mask))
	return wind + close


## His direction's row at this level (Combat's data/combat/stick.json directions): what makes the four play differently. {} with no table.
static func _dirRow(S: SimState, f, dir: int, lvl: int) -> Dictionary:
	var t = DirRecipe.rec().get("stickDirections", {})
	var dn: String = NAMES[dir]
	if lvl == 0 and dir == DOWN and float(f.y) - SimFighter.floorFor(S, f, f.x, f.z) > float(cfg().airAbove):
		dn = "downAir"
	return t.get(dn, {}).get("quick" if lvl == 0 else "charged", {})


## His piece, by the lane the mask chose and the direction (Combat's stick.json; docs/combat/pending/stick). "" for none.
static func piece(S: SimState, f, args: Dictionary) -> String:
	var dir: int = int(args.stick)
	var mask: int = int(args.get("stickMask", 0))
	var lane: String = "guard" if (mask & LB) != 0 else ("move" if (mask & LT) != 0 else "quick")
	var dn: String = NAMES[dir]
	if lane == "quick" and dir == DOWN and float(f.y) - SimFighter.floorFor(S, f, f.x, f.z) > float(cfg().airAbove):
		dn = "downAir"
	return DirBrawl._cellPiece(S, f, "", "stick." + lane + "." + dn, "")


## His charged piece at the release (levels 1 to 3 share one, played bigger).
static func chargedPiece(S: SimState, f, dir: int) -> String:
	# The quick's piece, drawn at the throw, was never played: it comes off his last two and the gut's memory.
	f.act.dirI[DirAlchemy.PIECE_1] = f.act.dirI[DirAlchemy.PIECE_2]
	DirBrawl._s(f, DirBrawl.GUT, DirBrawl._g(f, DirBrawl.GUT) >> 1)
	return DirBrawl._cellPiece(S, f, "", "stick.charged." + NAMES[dir], "")


static func setArmourForce(v: int) -> void:
	_armourForce = v


static func armourOn() -> bool:
	return on() and (bool(cfg().get("armour", {}).get("enabled", false)) if _armourForce < 0 else _armourForce == 1)


## True while he holds the stick for a strike or a beam: a flight strike isn't read (DirZip).
static func holding(f) -> bool:
	return on() and _g(f, ST_ON) != 0


## True when his stick strike, pressed and still held, has charged by now (past the quick flick's dwell): it counters a flight strike.
static func chargedAt(S: SimState, f) -> bool:
	return on() and _g(f, ST_PEND) != 0 and f.input.rsHeld and heldFor(S, f) >= int(_reader().dwell)


## The charge is spent on a flight strike's counter: nothing is left to throw.
static func spendCharge(f) -> void:
	_s(f, ST_PEND, 0)
	_clear(f)


## How long this hold has run, in live ticks.
static func heldFor(S: SimState, o) -> int:
	return DirBrawl._now(S) - (_g(o, ST_AT) - 1)


## True while he's holding a charge past the quick flick, a strike's or a beam's.
static func armoured(S: SimState, o) -> bool:
	var st: int = _g(o, ST_ON)
	if st == 3 and DirBeamMove.on():
		return heldFor(S, o) >= int(cfg().armour.get("beamFromTicks", 0))   # the beam's own move: its hold is armoured from its first tick, armour's switch or not (playable-build.md section 2)
	if not armourOn():
		return false
	return (st == 2 or st == 3) and heldFor(S, o) >= int(cfg().armour.fromTicks)


## ... and a medium no longer stops it.
static func mediumHolds(S: SimState, o) -> bool:
	return heldFor(S, o) >= int(cfg().armour.mediumUntilTicks)


## What's left of his flying speed: past the quick flick, holding a beam, he barely moves, with no dash (SimFighter.flightSpeed, by SimDir).
## 1 otherwise. A kite's hold isn't a charge, so it keeps his speed.
static func holdMove(S: SimState, f) -> float:
	if DirBeamMove.pending(f):
		return 1.0   # let go and waiting on the gate: he moves again
	if not on() or _g(f, ST_ON) != 3 or f.beamCharge == null or not DirBeamPlay.stationary() or heldFor(S, f) < int(DirBeamPlay.frontCfg().holdFromTicks):
		return 1.0
	return float(DirBeamPlay.frontCfg().holdMove)


static func _holdLost(S: SimState, f) -> void:
	_clear(f)
	DirBeamMove.lost(f)
	f.beamCharge = null
	SimFx.cue(S, f, "stick_refused", "beam", "taken")


## A blow its armour didn't take has landed on him (DirBrawl.contact): a beam's hold is lost.
static func holdHit(S: SimState, o) -> void:
	if on() and _g(o, ST_ON) == 3 and DirBeamPlay.stationary():
		_holdLost(S, o)


## A charged strike met nothing (DirBrawl.contact): a dodge or a step back has made it miss, and he's open.
static func missed(S: SimState, f, a: Dictionary) -> void:
	if armourOn() and int(a.get("stickL", 0)) > 0:
		var open: int = int(cfg().armour.missOpenTicks)
		DirBrawl._s(f, DirBrawl.FREE_AT, S.tick + open)
		DirBrawl._s(f, DirBrawl.OPEN_UNTIL, DirBrawl._now(S) + open)


## True while a blow landing on him ends what he's winding: the stick's strike is bare. With lightStops false a quick flick isn't ended by a
## light, only softened (lightOn); a charged one still is (docs/design/stick-lands.md).
static func bare(f) -> bool:
	if not on():
		return false
	return _g(f, ST_ON) == 2 or (_g(f, ST_ON) == 1 and lightStops())


static func lightStops() -> bool:
	return bool(cfg().get("lightStops", true))


## A light has landed on o (DirBrawl.contact): a quick flick he's winding takes it and goes on, for less, with no stun.
static func lightOn(ex, o) -> void:
	if not on() or lightStops() or _g(o, ST_ON) != 1 or guardHolds(o):
		return   # (a guard holding through the wind-up blocks it)
	_s(o, ST_SOFT, 1)
	var b = _beat(ex, o)
	if b != null:
		b.args["dmg"] = float(cfg().softWorth) * DirBrawl._unit()


## His guard holds through this flick's wind-up.
static func guardHolds(o) -> bool:
	return on() and not lightStops() and _g(o, ST_ON) == 1 and _g(o, ST_GUARD) == 1


## ... and drops for its recovery.
static func guardDrops(S: SimState, o) -> bool:
	if not on() or lightStops() or _g(o, ST_GUARD) == 0 or _g(o, ST_ON) != 0:
		return false
	if S.tick >= DirBrawl._g(o, DirBrawl.FREE_AT):
		_s(o, ST_GUARD, 0)
		return false
	return true


## A new string of the striker's: the one he's hitting can be stick-stunned once more.
static func newString(o) -> void:
	if on() and _g(o, ST_STUN) != 0:
		_s(o, ST_STUN, 0)


## The stick's reach in body heights, for DirBrawl._reachOf.
static func reach(a: Dictionary) -> float:
	return float(a.get("stickReach", 0.5))


## A blow has ended the stick strike o was winding (DirBrawl.contact): said, as UI's "Hit".
static func stopped(S: SimState, o) -> void:
	if not on() or o.ai != null or not bool(DirExchange.pressCfg().get("refusedCue", false)):
		return
	var st: int = _g(o, ST_ON)
	if st == 1 or st == 2:
		SimFx.cue(S, o, "stick_refused", NAMES[_g(o, ST_DIR)], "hit")


## A clean hit (DirBrawl.contact, past a guard, a perfect block, armour and a miss).
static func landed(S: SimState, ex, f, o, a: Dictionary) -> void:
	var c: Dictionary = cfg()
	var lvl: int = int(a.get("stickL", 0))
	var dir: int = int(a.stick)
	var lv: Dictionary = c.levels[lvl]
	var dr: Dictionary = _dirRow(S, f, dir, lvl)
	var stun: int = int(round(float(lv.stun) * float(dr.get("stunMul", 1.0))))
	var now: int = DirBrawl._now(S)
	DirBrawl._s(f, DirBrawl.LAST_AT, S.tick)   # he acted: a level 3's hold doesn't run out the brawl's idle clock
	_steal(S, f, o, a, lvl)   # first: the stun that follows breaks his run
	_flickRun(S, f, o, lvl)
	var trade: bool = DirBrawl._g(o, DirBrawl.LINE) == 1 and DirBrawl._g(o, DirBrawl.CONTACT) == now
	if fullSendOn() and not trade:
		if bool(a.get("top", false)):
			_fullSend(S, ex, f, o, dir)
			return
		if lvl == 0 and dir == DOWN and _airborne(S, o):
			SimFx.cue(S, f, "slam_hint", NAMES[dir], "")   # a quick down flick on a foe in the air: UI's once-only "Hold to slam" (the combat-variety packet)
	var stuns: bool = not trade and _g(o, ST_STUN) == 0 and not (lvl == 0 and _g(f, ST_SOFT) == 1)
	if lvl == 0 and _g(f, ST_GUARD) == 1 and not lightStops():
		stun = int(c.guardStun)
	if lvl == 0:
		var t1: int = _g(f, ST_Q0 + dir - 1)
		var t2: int = _g(f, ST_Q1 + dir - 1)
		var win: int = int(float(c.repeatSec) * DirData.TICKS_PER_SEC)
		if t2 > 0 and now - (t2 - 1) <= win and t1 > 0:
			stuns = false   # the third quick strike of one direction inside 3 s still hits, and doesn't stun
		_s(f, ST_Q1 + dir - 1, t1)
		_s(f, ST_Q0 + dir - 1, now + 1)
	DirBrawl._s(f, DirBrawl.FREE_AT, S.tick + int(c.quickRecover if lvl == 0 else c.chargeRecover))
	if stuns:
		_s(o, ST_STUN, 1)
		DirBrawl._stagger(S, ex, f, o, stun, "stick", lvl == 3)   # level 3 sets up the send: an opening, as a wound is
		if lvl == 3 and dir == UP:
			DirArc.bank(S, f, o, stun)
	elif not lightStops():
		DirBrawl._reel(S, o, int(c.softReel))   # it lands with no stun: he doesn't shrug it off and close, and yours doesn't grow
		DirBrawl._s(o, DirBrawl.RUN, maxi(0, DirBrawl._g(o, DirBrawl.RUN) - int(c.softRunOff) * DirBrawl.RUN_U))
	var carry: float = minf(float(lv.carryBh) * float(dr.get("carryMul", 1.0)) + float(dr.get("carryAddBh", 0.0)), float(DirRecipe.rec().get("stickDirections", {}).get("carryMaxBh", 99.0))) * DirInterrupt.BH
	if carry > 0.0:
		var side: float = signf(SimWrap.sdx(f.x, o.x))
		var dx: float = 0.0
		var dy: float = 0.0
		if dir == TOWARD:
			carry = minf(carry, (float(DirBrawl.cfg().breakBh) - 0.25) * DirInterrupt.BH - absf(SimWrap.sdx(f.x, o.x)))   # it never sends him: the brawl holds
		match dir:
			UP:
				dy = carry
			DOWN:
				dy = -carry
			TOWARD:
				dx = carry * side
			AWAY:
				dx = -carry * side   # he turns him past: the far side of his attacker
		_s(o, ST_CT, int(c.carryTicks))
		_s(o, ST_CX, int(round(dx * 16.0)))
		_s(o, ST_CY, int(round(dy * 16.0)))
	if int(a.get("stickMask", 0)) == 0:
		DirPhrase.read(S, f, o, "stick", "flick" if lvl == 0 else "hold", NAMES[dir])   # its piece is his class's, unchanged: the phrase only moves on
	var e = DirBrawl._ev(S, f, "stick_hit", NAMES[dir], str(lvl))
	e.target = float(S.fighters.find(o))
	e.n = stun if stuns else 0


## A landed flick counts in its striker's run as a light does (flickRun.enabled; Game Design, stick-lands.md, 2026-11-02): flickRun.points,
## on top of the steal. As a light's, it doesn't add on a staggered rival unless the brawl's flurry says so.
static func _flickRun(S: SimState, f, o, lvl: int) -> void:
	var c: Dictionary = cfg().get("flickRun", {})
	if not bool(c.get("enabled", false)) or lvl != 0:
		return
	DirBrawl._s(f, DirBrawl.LAND_AT, S.tick)   # his string goes on, as a light's landing keeps it: else its lapse spends the run
	if o.stunTicks <= 0 or bool(DirBrawl.cfg().flurry.get("staggeredAddsRun", false)):
		DirBrawl._s(f, DirBrawl.RUN, DirBrawl._g(f, DirBrawl.RUN) + int(round(float(c.points) * float(DirBrawl.RUN_U))))


## The stick steals his run (steal.enabled, for QA's arm; stick-lands.md): a quick flick from no stance that lands clean takes his run to 0, and
## yours rises by what was taken, at most steal.max; he stumbles reelBase + reelPer for each point. Never the AI's, so a beginner mashing
## against the computer is never stolen from. A steal takes his run, so he's only stolen from once a run.
static func _steal(S: SimState, f, o, a: Dictionary, lvl: int) -> void:
	var c: Dictionary = cfg().get("steal", {})
	if not bool(c.get("enabled", false)) or lvl != 0 or int(a.get("stickMask", 0)) != 0 or f.ai != null:
		return
	var taken: int = mini(DirBrawl._g(o, DirBrawl.RUN) / DirBrawl.RUN_U, int(c.max))
	if taken <= 0:
		return
	DirBrawl._s(o, DirBrawl.RUN, 0)
	DirBrawl._s(f, DirBrawl.RUN, DirBrawl._g(f, DirBrawl.RUN) + taken * DirBrawl.RUN_U)
	DirBrawl._reel(S, o, int(c.reelBase) + int(c.reelPer) * taken)
	var e = DirBrawl._ev(S, f, "stick_steal", str(taken))
	e.target = float(S.fighters.find(o))


# ---- the tick -----------------------------------------------------------------------------------------------------

static func _beat(ex, f):
	if ex == null:
		return null
	var role: String = "A" if f == ex.A else "D"
	for b in ex.beats:
		if not b.done and b.op == "strike" and b.args != null and b.args.has("stick") and String(b.args.a) == role:
			return b
	return null


static func _clear(f) -> void:
	_s(f, ST_ON, 0)
	_s(f, ST_RL, 0)
	DirBeamMove.lost(f)   # (its ladder goes with it)


static func _start(S: SimState, f, i) -> void:
	if DirBeam.inClash(S, f) and DirBeam.pushModeOf(S, f) == "stick":
		return   # in a beam struggle his stick pushes (DirBeam.clashTick reads it): no strike and no beam starts
	var dir: int = relative(S, f, int(i.rsDir))
	var mask: int = int(i.rsMask)
	if (mask & RB) != 0:
		if dir == TOWARD and DirBeamPlay.stickAnswer(S, f):
			var told: bool = false
			for k in range(S.out.fx.size() - 1, -1, -1):
				var e = S.out.fx[k]
				if String(e.type) == "cue" and String(e.kind) == "answer_refused" and int(e.actor) == S.fighters.find(f):
					told = true
					break
			if told:
				SimFx.cue(S, f, "stick_refused", NAMES[dir], "ki")   # it can't pay: the pad's knock and UI's word
			else:
				SimFx.cue(S, f, "stick_start", NAMES[dir], str(mask))   # answered: the hub hears it was, and doesn't knock "no answer"
			return   # a beam's coming: in its window it fires at once and the fronts meet; in its charge it fires as he fires
		_s(f, ST_ON, 3)   # the energy layer's stick is the beam: it fires on the release
		_s(f, ST_AT, DirBrawl._now(S) + 1)
		DirBeamMove.began(S, f)   # its own move: the stage count is taken now
		if DirBeamPlay.stationary() and (mask & LT) == 0:
			f.beamCharge = S.T   # the hold is the charge, and shows (the kite's isn't one: power-scale.md, the last section)
		SimFx.cue(S, f, "stick_start", NAMES[dir], str(mask))
		return
	if _cant(S, f):
		if keepOn() and _showing(S, f):
			SimFx.cue(S, f, "stick_refused", NAMES[dir], "set_piece")   # the show: a blow out of it would be stale (gauntlet-plan.md section 5, ruling 1)
			return
		if int(cfg().bufferTicks) <= 0 and not keepOn():
			SimFx.cue(S, f, "stick_refused", NAMES[dir], DirExchange.cantWhy(S, f))   # no press is silent (docs/design/pad-first-press.md), and it says why
			return
		if keepOn():
			_s(f, ST_BUF, (int(i.rsDir) & 7) | ((mask + 1) << 3) | RAW | (RECOV if _recovering(f) else 0))   # held quietly, the newest only (ruling 1)
		else:
			_s(f, ST_BUF, dir | ((mask + 1) << 3))   # the newest only: what becomes of it answers the burst (it goes, or it's refused once, with why)
		_s(f, ST_BAT, DirBrawl._now(S) + 1)
		return
	_go(S, f, dir, mask)


## The request goes in.
static func _go(S: SimState, f, dir: int, mask: int, quiet: bool = false) -> void:
	if DirChaseTap.refuses(S, f):
		if not quiet:
			SimFx.cue(S, f, "stick_refused", NAMES[dir], "chase")   # it can't reach him in the air, and it never sends
		return
	if f.ki < float(DirBrawl.cfg().medium.ki):
		if not quiet:
			SimFx.cue(S, f, "stick_refused", NAMES[dir], "ki")   # the press would throw a lighter blow: it never becomes another
		return
	_s(f, ST_RL, 0)   # (a request still on its way gives way to the newest, which answers for both: no knock for the one it replaces)
	var lunge: bool = _lungeLight(S, f)
	_s(f, ST_PEND, dir | ((mask + 1) << 3) | (LUNGE if lunge else 0))
	_s(f, ST_PAT, DirBrawl._now(S) + 1)
	_s(f, ST_AT, DirBrawl._now(S) + 1)
	DirBeamMove.strikeBegan(S, f)   # the plain hold's ladder: its count is taken now
	asking = true
	askRefused = false
	DirExchange.requestAttack(S, f, "light" if lunge else "heavy")   # from the middle band with lungeLight, the light lunge: it lands as a light
	asking = false
	if askRefused:
		askRefused = false
		_s(f, ST_PEND, 0)
		if not quiet:
			SimFx.cue(S, f, "stick_refused", NAMES[dir], "not_yours")   # the first move is his rival's: told now and once (DirBrawl.moveRefused stays quiet for the stick)
		return


## lungeLight (stick.json, off; docs/ep/proposals/controller-vision.md section 5): a quick strike asked for from the middle band, out of
## any exchange, asks for the light lunge rather than the heavy one, and lands as a light on arrival. Up close and in a brawl it's the
## stick's own blow as before.
static func _lungeLight(S: SimState, f) -> bool:
	if not on() or not bool(cfg().get("lungeLight", {}).get("enabled", false)) or f.act.mode == 1 or DirBrawl.exOf(S) != null:
		return false
	return DirBands.band(f, DirBrawl.rivalOf(S, f)) == DirBands.MID


## A press he couldn't act on: it goes on his first tick free inside bufferTicks; past that it's refused, said once.
static func _waiting(S: SimState, f) -> void:
	var b: int = _g(f, ST_BUF)
	if b == 0:
		return
	var swept: bool = (b & SWEPT) != 0
	var age: int = DirBrawl._now(S) - (_g(f, ST_BAT) - 1)
	var d: int = relative(S, f, b & 7) if (b & RAW) != 0 else b & 7   # (a held flick's direction is read now, relative to the rival)
	if keepOn() and _showing(S, f):
		_s(f, ST_BUF, 0)
		if not swept:
			SimFx.cue(S, f, "stick_refused", NAMES[d], "set_piece")   # a set piece began while it was held: not held through the show (ruling 1)
		return
	if not _cant(S, f) and not (swept and _planned(S, f)):
		_s(f, ST_BUF, 0)
		if (b & RECOV) != 0 and age > int(cfg().flickKeep.get("recoverTicks", 20)):
			SimFx.cue(S, f, "stick_refused", NAMES[d], "recovering")   # made early in his flight: too old to be his first blow out (ruling 1)
			return
		if not swept or f.input.rsHeld:
			_go(S, f, d, ((b >> 3) & 511) - 1, swept and not keepOn())   # (a swept hold goes only if he's still holding it, and quietly: its press was told; with flickKeep it wasn't)
			if swept:
				_s(f, ST_RL, _g(f, ST_RL) | RL_SWEPT)
		elif keepOn():
			_go(S, f, d, ((b >> 3) & 511) - 1)   # flickKeep: a flick the answer swept up while still out, let go by now, goes as a flick
	elif age >= (int(cfg().pendFollow.maxTicks) if swept else _bufTicks()):
		_s(f, ST_BUF, 0)
		if not swept or keepOn():
			SimFx.cue(S, f, "stick_refused", NAMES[d], DirExchange.cantWhy(S, f))   # what still holds him


## A planned exchange holds him, window or no window: a swept hold waits for the end of it, his first free tick.
static func _planned(S: SimState, f) -> bool:
	var ex = DirBrawl.exOf(S)
	return ex != null and not DirBrawl.isBrawl(ex) and (ex.A == f or ex.D == f)


## True when this press can't become a blow: he's been sent, a long stun holds him, or a planned exchange or set piece is playing with no
## window of his open. It's told at once, and nothing's left to fire later.
static func _cant(S: SimState, f) -> bool:
	if f.state == "launched" or f.state == "down" or f.state == "dropped" or f.stunTicks > 0:
		return true
	var ex = DirBrawl.exOf(S)
	if ex == null or ex.ext != null:
		return false
	return not DirBrawl.isBrawl(ex) or ex.branch != "" or DirBrawl._setPiece(ex)


## Moves him over the carry's ticks (DirStance's blows use it too).
static func carry(f, dx: float, dy: float) -> void:
	_s(f, ST_CT, int(cfg().carryTicks))
	_s(f, ST_CX, int(round(dx * 16.0)))
	_s(f, ST_CY, int(round(dy * 16.0)))


## True while a stick strike is moving him: it's an authored move, so an "away" can take him past his attacker.
static func carrying(f) -> bool:
	return on() and _g(f, ST_CT) > 0


## flickKeep (stick.json, off; Game Design's rulings, docs/design/gauntlet-plan.md section 5): a flick that can't start now is held, the
## newest only, quietly, and becomes his first blow out, its direction read then. Stunned, reeling or in a planned exchange with no window of
## his open (a chain window of his own counts as free): up to pendFollow.maxTicks. Launched, down or dropped: it must be at most
## flickKeep.recoverTicks old when he's free, or it's refused "recovering". A set piece (a finisher, the KO, a set piece in a brawl, a beam
## struggle): refused at once, "set_piece". One a planned exchange of his rival's took is held the same way, never told "answered".
## Off, bufferTicks and "answered" as before.
static func keepOn() -> bool:
	return on() and bool(cfg().get("flickKeep", {}).get("enabled", false))


## A set piece is playing: the show, which holds no flick (ruling 1).
static func _showing(S: SimState, f) -> bool:
	if S.game.ko != null or DirBeam.inClash(S, f):
		return true
	var ex = DirBrawl.exOf(S)
	return ex != null and (DirExchange.finisherPlanned(ex) or (DirBrawl.isBrawl(ex) and DirBrawl._setPiece(ex)))


## Launched, knocked down or dropped: recovering.
static func _recovering(f) -> bool:
	return f.state == "launched" or f.state == "down" or f.state == "dropped"


## How long a press he couldn't act on waits for him.
static func _bufTicks() -> int:
	return maxi(int(cfg().bufferTicks), int(cfg().pendFollow.maxTicks)) if keepOn() else int(cfg().bufferTicks)


static var asking: bool = false       # not state: true while _go asks for its request (DirBrawl.moveRefused then stays quiet)
static var askRefused: bool = false   # not state: ... and the first move refused it


## fullSend (stick.json, off; Game Design, docs/design/slam-and-pace.md section 1): a stick strike held to his top stage (with the plain
## hold's stages, his stage at its count; without them, level 3) sends when it lands, not as a trade, in the family of its direction, at
## a full B's share: down on a foe in the air the slam, down on a foe on the ground the down send from where he stands (World's embed
## pounds him in), up skyward, toward across, away across (behind him once the turning send exists). It's the brawl's own send kept to
## the family's sends (DirBrawl._send), and the brawl ends with it. A quick flick or a hold short of the top never sends.
static func fullSendOn() -> bool:
	return on() and bool(cfg().get("fullSend", {}).get("enabled", false))


## Held to his top stage, at the release.
static func _atTop(f, l: int) -> bool:
	if DirBeamMove.strikeOn():
		var n: int = DirBeamMove._g(f, DirBeamMove.M_COUNT)
		return n > 0 and DirBeamMove.stage(f) >= n
	return l >= 3


## In the air: more than fullSend.airBh body heights over the ground under him.
static func _airborne(S: SimState, o) -> bool:
	return o.y - WorldTerrain.groundY(S, o.x, o.z) > float(cfg().get("fullSend", {}).get("airBh", 1.0)) * DirInterrupt.BH


static func _fullSend(S: SimState, ex, f, o, dir: int) -> void:
	var c: Dictionary = cfg().fullSend
	var aim: int = 3
	var sends: String = "down"
	match dir:
		UP:
			aim = 1
			sends = "up"
		TOWARD:
			aim = 2
			sends = "across"
		AWAY:
			aim = 4
			sends = "across"   # (acrossBehind waits for the turning send)
	var fam: String = String(c.get("families", {}).get(NAMES[dir], ""))
	if dir == DOWN and not _airborne(S, o):
		fam = String(c.get("downOnGround", "bury"))
	SimFx.cue(S, f, "stick_full_send", NAMES[dir], fam)
	DirBrawl._send(S, ex, f, o, aim, "the stick's full hold", float(c.get("share", 1.0)), {"sends": sends, "share": "fullB"})


static func pendFollow() -> bool:
	return on() and bool(cfg().get("pendFollow", {}).get("enabled", false))


## pendFollow: a request still on its way keeps the stick's blow waiting with it, and one his rival answered is told at once (QA's meteor
## bot found both said "late"). While his request is queued it waits, up to pendFollow.maxTicks. True when this tick is handled, so the
## usual lapse doesn't run.
static func _followed(S: SimState, f, pat: int) -> bool:
	var ex = DirBrawl.exOf(S)
	if ex != null and not DirBrawl.isBrawl(ex) and (ex.A == f or ex.D == f):
		var pend: int = _g(f, ST_PEND)
		_s(f, ST_PEND, 0)
		if (_g(f, ST_RL) & RL_SWEPT) != 0:
			return true   # the swept hold's own go, answered again: its press was told once, and it's over
		if keepOn():
			if f.input.rsHeld:
				sweep(S, f, pend)   # a hold: the charge on his first free tick, as ever (a flick let go by then goes as a flick)
			else:
				_s(f, ST_BUF, pend & 511)   # flickKeep: kept, and it goes on his first free tick (it's told then, by what it does)
				_s(f, ST_BAT, DirBrawl._now(S) + 1)
			return true
		SimFx.cue(S, f, "stick_refused", NAMES[pend & 7], "answered")   # a planned exchange took the request: his rival's answer, not lateness
		if f.input.rsHeld:
			sweep(S, f, pend)
		return true
	if DirBrawl._now(S) - (pat - 1) > int(cfg().pendFollow.maxTicks):
		return false
	return not f.act.queue.is_empty()


## A hold a planned exchange swept up (Game Design, 2026-11-02): it becomes the charge on his first free tick, counting from then, with
## nothing banked. It waits in the buffer up to pendFollow.maxTicks.
static func sweep(S: SimState, f, pend: int) -> void:
	_s(f, ST_BUF, (pend & 511) | SWEPT)
	_s(f, ST_BAT, DirBrawl._now(S) + 1)


## The level of a release: the stick's own; for a swept hold, no more than he's held since its request went in, on his first free tick.
static func _relLevel(S: SimState, f, i) -> int:
	var l: int = int(i.rsLevel)
	if (_g(f, ST_RL) & RL_SWEPT) != 0:
		l = mini(l, int(_reader().level_at(DirBrawl._now(S) - (_g(f, ST_AT) - 1))))
	return l


## The level a plain hold's release lands at: the ladder's stage up to its cap with the stages on, else the stick's own.
static func _strikeLvl(S: SimState, f, i) -> int:
	return DirBeamMove.strikeLevel(f) if DirBeamMove.strikeOn() else _relLevel(S, f, i)


## True while a request of his is waiting for its blow.
static func pending(f) -> bool:
	return on() and _g(f, ST_PEND) != 0


## The level he's reached, cut to what he can pay.
static func _payable(f, lvl: int) -> int:
	var c: Dictionary = cfg()
	var l: int = lvl
	while l > 0 and f.ki < float(c.levels[l].ki) - float(c.levels[0].ki):
		l -= 1
	return l


static func _release(S: SimState, ex, f, b, lvl: int) -> void:
	var c: Dictionary = cfg()
	var dt: float = SimConst.DT
	var l: int = _payable(f, lvl)
	f.ki = maxf(0.0, f.ki - (float(c.levels[l].ki) - float(c.levels[0].ki)))
	var lv: Dictionary = c.levels[l]
	b.args["stickL"] = l
	b.args["top"] = _atTop(f, l)   # held to his top stage: with fullSend it sends (slam-and-pace.md section 1)
	var dir: int = int(b.args.stick)
	var dr: Dictionary = _dirRow(S, f, dir, l)
	b.args["dmg"] = float(lv.worth) * DirBrawl._unit()
	b.args["stickReach"] = float(lv.reachBh) * float(dr.get("reachMul", 1.0))
	if l > 0:
		var p: String = chargedPiece(S, f, dir)
		if p != "":
			b.args["piece"] = p
	var cc: Dictionary = DirBrawl.cfg().get("chargeClose", {})
	var bh: float = float(cc.get("fullBh", 0.0)) if l >= 3 else (float(cc.get("firstBh", 0.0)) if l == 2 else 0.0)
	var o = ex.D if f == ex.A else ex.A
	var lead: int = DirBrawl.closeIn(S, f, o, bh, 1)   # (press-decides.md section 2: from stage 2 a hold closes the gap too)
	if lead > 1:
		b.args["stickReach"] = maxf(float(b.args.stickReach), bh)
	b.t = ex.t + dt * (float(lead) - 0.25)   # it lands on the next live tick, or as it arrives
	DirBrawl._s(f, DirBrawl.CONTACT, DirBrawl._now(S) + lead)
	_clear(f)
	SimFx.cue(S, f, "stick_release", NAMES[dir], str(l))


## Once a live tick, last in the director's update. The stick's edges keep through a hit-stop (Controls' rsLag), so a live tick
## takes them.
static func tick(S: SimState, dt: float) -> void:
	if dt <= 0.0 or not on():
		return
	DirBeamMove.stamp(S)
	for f in S.fighters:
		var i = f.input
		_carry(S, f)
		if i.rsCancel:
			_cancel(S, f)
		if i.rsStart:
			_start(S, f, i)
		else:
			_waiting(S, f)
		if DirBeamMove.strikeOn() and i.rsHeld and not i.rsRelease and (_g(f, ST_PEND) != 0 or _g(f, ST_ON) == 1 or _g(f, ST_ON) == 2):
			DirBeamMove.strikeHolding(S, f, DirBrawl._now(S) - (_g(f, ST_AT) - 1), dt)   # the plain hold climbs the ladder from its request
		if i.rsRelease and (_g(f, ST_PEND) != 0 or _g(f, ST_ON) == 1):
			_s(f, ST_RL, (_g(f, ST_RL) & RL_SWEPT) | (_strikeLvl(S, f, i) + 1))   # the edge is one tick: the blow's level is kept for when its wind-up ends
		var pat: int = _g(f, ST_PAT)
		if _g(f, ST_PEND) != 0 and pendFollow() and _followed(S, f, pat):
			pass
		elif _g(f, ST_PEND) != 0 and DirBrawl._now(S) - (pat - 1) > int(cfg().pendTicks) and not DirBands.pending(f):
			_s(f, ST_PEND, 0)   # no blow came of it, and it doesn't become some other blow: what it asked for goes too
			SimAct.clear(f)
			if (DirBrawl._g(f, DirBrawl.HELD_P) & 7) == 2:
				DirBrawl._s(f, DirBrawl.HELD_P, 0)
			SimFx.cue(S, f, "stick_refused", "", "late")
		if _g(f, ST_ON) == 0:
			continue
		if _g(f, ST_ON) == 3:
			DirBeamAim.holding(S, f, i)
			if DirBeamPlay.stationary() and (f.state == "launched" or f.state == "down" or f.state == "dropped" or f.stunTicks > 0):
				_holdLost(S, f)   # something took him
				continue
			if DirBeamMove.on() and not (DirBeamPlay.stationary() and f.beamCharge == null):   # (the kite's hold isn't a charge: no stages, and its release is the quick blast)
				if DirBeamMove.pending(f):
					if DirBeamMove.tryFire(S, f):
						_clear(f)   # it fired, or it was refused and said why
					continue
				DirBeamMove.holding(S, f, heldFor(S, f), dt)
				if i.rsRelease or not i.rsHeld:
					DirBeamAim.thrown(f, i)
					if not DirBeamMove.released(S, f, heldFor(S, f)):
						_beamGo(S, f, 0, heldFor(S, f))   # before its first stage: the quick, as it was
					elif DirBeamMove.tryFire(S, f):
						_clear(f)
					elif not DirBeamMove.pending(f):
						_clear(f)
				continue
			if i.rsRelease or not i.rsHeld:
				DirBeamAim.thrown(f, i)
				_beamGo(S, f, 0 if (DirBeamPlay.stationary() and f.beamCharge == null) else (int(i.rsLevel) if i.rsRelease else int(_reader().level_at(DirBrawl._now(S) - (_g(f, ST_AT) - 1), true))), DirBrawl._now(S) - (_g(f, ST_AT) - 1))
			continue
		var ex = DirBrawl.exOf(S)
		var b = _beat(ex, f)
		if b == null or DirBrawl._g(f, DirBrawl.LINE) == 0:
			if armoured(S, f) and ex == null and DirBrawl.rivalOf(S, f).act.dodgeTick >= S.tick - 2:
				missed(S, f, {"stickL": 1})   # he dodged out from under it
				SimFx.cue(S, f, "stick_refused", NAMES[_g(f, ST_DIR)], "dodged")
			_clear(f)   # a blow ended it, or the exchange did
			continue
		var c: Dictionary = cfg()
		var since: int = DirBrawl._now(S) - (_g(f, ST_AT) - 1)
		var kept: int = _g(f, ST_RL) & 15   # (the swept mark aside)
		var due: bool = b.t <= ex.t + dt * 1.25
		if kept > 1 and due:
			_release(S, ex, f, b, kept - 1)
		elif _g(f, ST_ON) == 2 and (i.rsRelease or not i.rsHeld or (since >= int(c.autoGoTicks) and not DirBeamMove.strikeOn())):   # with the stages a held charge never goes by itself
			_release(S, ex, f, b, _strikeLvl(S, f, i) if (i.rsRelease or DirBeamMove.strikeOn()) else int(_reader().level_at(since)))
		elif i.rsHeld and not i.rsRelease and kept == 0 and due:
			_s(f, ST_ON, 2)
			b.t += dt   # still out as its wind-up ends: the blow waits for the release
			DirBrawl._s(f, DirBrawl.CONTACT, DirBrawl._g(f, DirBrawl.CONTACT) + 1)
		if _g(f, ST_ON) == 2 and since == int(_reader().dwell):
			SimFx.cue(S, f, "stick_charge", NAMES[int(b.args.stick)], "")   # a charge from here (level 0 until the first rung)


static var firing: bool = false   # not state: true for one call


## A first cut of the beam on the stick, on what plays today: a quick is the heavy blast, in place of the snap-beam; a charge
## is the beam B holds now, fired at him at its own price. The snap-beam, the aim latched at the settle and the sweep are next.
static func _beamGo(S: SimState, f, lvl: int, held: int) -> void:
	_clear(f)
	SimFx.cue(S, f, "stick_release", "beam", str(lvl))
	if lvl <= 0:
		f.beamCharge = null
		if not DirBlast.press(S, f, SimAct.HEAVY) and DirBlast.on() and bool(DirExchange.pressCfg().get("refusedCue", false)):   # the quick is the heavy blast, standing in for the snap-beam (right-hand-attacks-rulings.md section 2)
			SimFx.cue(S, f, "stick_refused", "beam", "close")   # in an exchange he's in, a blast can't go: "Too close" (beams-third-play.md section 2)
	else:
		firing = true   # it's the stick's beam, and not a press of B
		DirExchange.requestAttack(S, f, "sig")
		firing = false
		DirBeamPlay.fromStick(S, f, held)


## The left hand's cancel: a guard press or a dodge ends a started charge, and it's lost.
static func _cancel(S: SimState, f) -> void:
	if _g(f, ST_PEND) != 0:
		SimFx.cue(S, f, "stick_refused", NAMES[_g(f, ST_PEND) & 7], "cancel")
	_s(f, ST_PEND, 0)
	if _g(f, ST_BUF) != 0:
		SimFx.cue(S, f, "stick_refused", NAMES[_g(f, ST_BUF) & 7], "cancel")
		_s(f, ST_BUF, 0)
	if _g(f, ST_ON) == 0:
		return
	if _g(f, ST_ON) == 3 and DirBeamPlay.stationary():
		f.beamCharge = null   # the hold was the charge, and it's dropped
		DirBeamMove.lost(f)
	var ex = DirBrawl.exOf(S)
	if ex != null and DirBrawl._g(f, DirBrawl.LINE) != 0:
		DirBrawl._wEnd(S, f, DirBrawl.MEDIUM, 3)
		DirBrawl._drop(S, ex, f)
	_clear(f)


## The carry: he goes where it was aimed, eased, and stays in reach.
static func _carry(S: SimState, o) -> void:
	var n: int = _g(o, ST_CT)
	if n <= 0:
		return
	var dx: float = float(_g(o, ST_CX)) / 16.0
	var dy: float = float(_g(o, ST_CY)) / 16.0
	var sx: float = dx / float(n)
	var sy: float = dy / float(n)
	o.x = SimWrap.wrap(o.x + sx)
	o.y = maxf(float(o.y) + sy, SimFighter.floorFor(S, o, o.x, o.z))
	_s(o, ST_CX, int(round((dx - sx) * 16.0)))
	_s(o, ST_CY, int(round((dy - sy) * 16.0)))
	_s(o, ST_CT, n - 1)


## In a struggle: a beam clash or the finisher's contest, for the host's hub.set_struggle(slot, on) each tick.
static func inStruggle(S: SimState, f) -> bool:
	var ex = DirBrawl.exOf(S)
	return S.game.clash != null or (ex != null and (f == ex.A or f == ex.D) and (ex.tpl == "finisher" or ex.branch == "finisher"))
