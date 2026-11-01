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
##  - Bare at every level: any blow that lands on his wind-up ends it, and the charge is lost.
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
const ST_BUF: int = 18   # a press waiting for him to be able to act: its direction, plus (the mask + 1) x 8; 0 none
const ST_BAT: int = 19   # the live tick it was made, plus 1
const ST_SOFT: int = 20   # a light has landed on this flick: it still lands, at softWorth, with no stun (lightStops false)
const ST_GUARD: int = 21  # this flick is on the guard layer: his guard holds through its wind-up and drops for its recovery (lightStops false)
const ST_N: int = 22

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
		var o = SimRoster.opp(S, f)
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
	if pend == 0 or int(args.get("bk", 0)) != DirBrawl.MEDIUM or args.has("energy"):
		return lead
	_s(f, ST_PEND, 0)
	var c: Dictionary = cfg()
	var lv: Dictionary = c.levels[0]
	var dir: int = pend & 7
	var mask: int = (pend >> 3) - 1
	args["stick"] = dir
	args["stickMask"] = mask
	args["stickL"] = 0
	var dr: Dictionary = _dirRow(S, f, dir, 0)
	args["stickReach"] = float(lv.reachBh) * float(dr.get("reachMul", 1.0))
	args["dmg"] = float(lv.worth) * DirBrawl._unit()
	args["wind"] = true
	o2["stick"] = true
	var more: float = float(lv.ki) - float(DirBrawl.cfg().medium.ki)
	if more > 0.0:
		f.ki = maxf(0.0, f.ki - more)
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
	var trade: bool = DirBrawl._g(o, DirBrawl.LINE) == 1 and DirBrawl._g(o, DirBrawl.CONTACT) == now
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


static func _start(S: SimState, f, i) -> void:
	var dir: int = relative(S, f, int(i.rsDir))
	var mask: int = int(i.rsMask)
	if (mask & RB) != 0:
		if dir == TOWARD and DirBeamPlay.stickAnswer(S, f):
			return   # a beam's coming: in its window it fires at once and the fronts meet; in its charge it fires as he fires
		_s(f, ST_ON, 3)   # the energy layer's stick is the beam: it fires on the release
		_s(f, ST_AT, DirBrawl._now(S) + 1)
		SimFx.cue(S, f, "stick_start", NAMES[dir], str(mask))
		return
	if _cant(S, f):
		if int(cfg().bufferTicks) <= 0:
			SimFx.cue(S, f, "stick_refused", NAMES[dir], str(mask))   # no press is silent (docs/design/pad-first-press.md)
			return
		if _g(f, ST_BUF) != 0:
			SimFx.cue(S, f, "stick_refused", NAMES[_g(f, ST_BUF) & 7], "replaced")
		_s(f, ST_BUF, dir | ((mask + 1) << 3))   # the newest only
		_s(f, ST_BAT, DirBrawl._now(S) + 1)
		return
	_go(S, f, dir, mask)


## The request goes in.
static func _go(S: SimState, f, dir: int, mask: int) -> void:
	if f.ki < float(DirBrawl.cfg().medium.ki):
		SimFx.cue(S, f, "stick_refused", NAMES[dir], "ki")   # the press would throw a lighter blow: it never becomes another
		return
	if _g(f, ST_PEND) != 0:
		SimFx.cue(S, f, "stick_refused", NAMES[_g(f, ST_PEND) & 7], "replaced")   # the newest only: the one it replaces is told
	_s(f, ST_RL, 0)
	_s(f, ST_PEND, dir | ((mask + 1) << 3))
	_s(f, ST_PAT, DirBrawl._now(S) + 1)
	_s(f, ST_AT, DirBrawl._now(S) + 1)
	DirExchange.requestAttack(S, f, "heavy")


## A press he couldn't act on: it goes on his first tick free inside bufferTicks; past that it's refused, said once.
static func _waiting(S: SimState, f) -> void:
	var b: int = _g(f, ST_BUF)
	if b == 0:
		return
	if not _cant(S, f):
		_s(f, ST_BUF, 0)
		_go(S, f, b & 7, (b >> 3) - 1)
	elif DirBrawl._now(S) - (_g(f, ST_BAT) - 1) >= int(cfg().bufferTicks):
		_s(f, ST_BUF, 0)
		SimFx.cue(S, f, "stick_refused", NAMES[b & 7], str((b >> 3) - 1))


## True when this press can't become a blow: he's been sent, a long stun holds him, or a planned exchange or set piece is playing with no
## window of his open. It's told at once, and nothing's left to fire later.
static func _cant(S: SimState, f) -> bool:
	if f.state == "launched" or f.state == "down" or f.state == "dropped" or f.stunTicks > 0:
		return true
	var ex = S.dirS.ex
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
	var dir: int = int(b.args.stick)
	var dr: Dictionary = _dirRow(S, f, dir, l)
	b.args["dmg"] = float(lv.worth) * DirBrawl._unit()
	b.args["stickReach"] = float(lv.reachBh) * float(dr.get("reachMul", 1.0))
	if l > 0:
		var p: String = chargedPiece(S, f, dir)
		if p != "":
			b.args["piece"] = p
	b.t = ex.t + dt * 0.75   # it lands on the next live tick
	DirBrawl._s(f, DirBrawl.CONTACT, DirBrawl._now(S) + 1)
	_clear(f)
	SimFx.cue(S, f, "stick_release", NAMES[dir], str(l))


## Once a live tick, last in the director's update. The stick's edges keep through a hit-stop (Controls' rsLag), so a live tick
## takes them.
static func tick(S: SimState, dt: float) -> void:
	if dt <= 0.0 or not on():
		return
	for f in S.fighters:
		var i = f.input
		_carry(S, f)
		if i.rsCancel:
			_cancel(S, f)
		if i.rsStart:
			_start(S, f, i)
		else:
			_waiting(S, f)
		if i.rsRelease and (_g(f, ST_PEND) != 0 or _g(f, ST_ON) == 1):
			_s(f, ST_RL, int(i.rsLevel) + 1)   # the edge is one tick: the blow's level is kept for when its wind-up ends
		var pat: int = _g(f, ST_PAT)
		if _g(f, ST_PEND) != 0 and DirBrawl._now(S) - (pat - 1) > int(cfg().pendTicks) and not DirBands.pending(f):
			_s(f, ST_PEND, 0)   # no blow came of it, and it doesn't become some other blow: what it asked for goes too
			SimAct.clear(f)
			if (DirBrawl._g(f, DirBrawl.HELD_P) & 7) == 2:
				DirBrawl._s(f, DirBrawl.HELD_P, 0)
			SimFx.cue(S, f, "stick_refused", "", "late")
		if _g(f, ST_ON) == 0:
			continue
		if _g(f, ST_ON) == 3:
			if i.rsRelease or not i.rsHeld:
				_beamGo(S, f, int(i.rsLevel) if i.rsRelease else int(_reader().level_at(DirBrawl._now(S) - (_g(f, ST_AT) - 1), true)))
			continue
		var ex = S.dirS.ex
		var b = _beat(ex, f)
		if b == null or DirBrawl._g(f, DirBrawl.LINE) == 0:
			_clear(f)   # a blow ended it, or the exchange did
			continue
		var c: Dictionary = cfg()
		var since: int = DirBrawl._now(S) - (_g(f, ST_AT) - 1)
		var kept: int = _g(f, ST_RL)
		var due: bool = b.t <= ex.t + dt * 1.25
		if kept > 1 and due:
			_release(S, ex, f, b, kept - 1)
		elif _g(f, ST_ON) == 2 and (i.rsRelease or not i.rsHeld or since >= int(c.autoGoTicks)):
			_release(S, ex, f, b, int(i.rsLevel) if i.rsRelease else int(_reader().level_at(since)))
		elif i.rsHeld and not i.rsRelease and kept == 0 and due:
			_s(f, ST_ON, 2)
			b.t += dt   # still out as its wind-up ends: the blow waits for the release
			DirBrawl._s(f, DirBrawl.CONTACT, DirBrawl._g(f, DirBrawl.CONTACT) + 1)
		if _g(f, ST_ON) == 2 and since == int(_reader().dwell):
			SimFx.cue(S, f, "stick_charge", NAMES[int(b.args.stick)], "")   # a charge from here (level 0 until the first rung)


static var firing: bool = false   # not state: true for one call


## A first cut of the beam on the stick, on what plays today: a quick is the heavy blast, in place of the snap-beam; a charge
## is the beam B holds now, fired at him at its own price. The snap-beam, the aim latched at the settle and the sweep are next.
static func _beamGo(S: SimState, f, lvl: int) -> void:
	_clear(f)
	SimFx.cue(S, f, "stick_release", "beam", str(lvl))
	if lvl <= 0:
		DirBlast.press(S, f, SimAct.SIG)
	else:
		firing = true   # it's the stick's beam, and not a press of B
		DirExchange.requestAttack(S, f, "sig")
		firing = false


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
	var ex = S.dirS.ex
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
	var ex = S.dirS.ex
	return S.game.clash != null or (ex != null and (f == ex.A or f == ex.D) and (ex.tpl == "finisher" or ex.branch == "finisher"))
