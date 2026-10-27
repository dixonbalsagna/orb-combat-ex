class_name DirRecoil
## Recoil flips (Game Design's rulings-2026-10-19.md 2a; docs/design/fight-feel.md section 2; Combat's
## docs/combat/choreography-feel.md sections 1 and 6), behind data/director/interrupts.json recoilFlip.enabled (false:
## nothing here runs, no slot is written and no cue is sent).
##  - A knock-back (DirLaunch.knock) opens his window: a dodge tap in its first windowTicks live ticks backflips him out
##    of it. The flip ends his slide where he is (the skid's journey through World's recoilEnd, an upright slide or a
##    drift by dropping its rush) and carries him flipBh further back, bowed, over flipTicks: he lands set.
##  - His next blow within counterTicks of the landing is a counter-rush: an approach with no crouch, no return and no
##    first-move lock, at counterRush's speed (DirBands.begin), so it lands as the lunge's arrival blow. While he is in
##    the air his presses wait (DirExchange._start).
##  - Free: no ki and no cooldown. A press outside the window does nothing.
##  - With no press, a knock-back on the ground over flourishOverBh still ends in Animation's flourish: the recoil cue
##    says so at the knock, with no counter-rush.
##  - The AI flips on its level's brawl.recoil.flip share of its chances (one keyed draw at the knock, the tap at a keyed
##    tick inside the window), and follows a flip with a counter-rush on brawl.recoil.counter of them.
## The cue (SimFx.cue kind "recoil", Combat's section 6): text "flip" or "flourish", source the exit (skip, handspring,
## tuck, backflip), target the striker's slot, x and y where it starts, amount where it lands (x), n the landing tick,
## dur its ticks, k 1 on the ground and 0 in the air.
## State: f.act.dirI slots past launch anywhere's (sized only when the switch is on, so the hashed count never moves
## with it off).

const BH: float = 75.0
const RC_LEFT: int = 0    # live ticks left in his window to flip out of a knock-back; 0 none
const RC_KIND: int = 1    # the knock-back: 1 the skid (a journey), 2 the upright slide, 3 the drift in the air
const RC_LN: int = 2      # the skid's launch number, so a later send is never flipped out of
const RC_AI: int = 3      # the AI's tap: live ticks until it taps, plus 1; 0 none
const RC_AIR: int = 4     # live ticks left in the flip; 0 none
const RC_CR: int = 5      # live ticks left in which his next blow is a counter-rush; 0 none
const RC_AIC: int = 6     # the AI's counter press: live ticks until it presses, plus 1; 0 none
const RC_DIST: int = 7    # the knock-back's distance, in units
const RC_BSL: int = 8     # live ticks left in a heavy's recoil slide inside a brawl (Game Design's 1a); 0 none
const RC_N: int = 9
const EXITS: Array = ["skip", "handspring", "tuck", "backflip"]


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("recoilFlip", {})


static func on() -> bool:
	return DirInterrupt.on() and (bool(cfg().get("enabled", false)) or DirRally.on())   # (on with the rally: 23d)


static func _base() -> int:
	return DirBrawl._laBase() + DirBrawl.LA_N


static func _g(f, k: int) -> int:
	var i: int = _base() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirGrapple._size(f)
	if f.act.dirI.size() < _base() + RC_N:
		f.act.dirI.resize(_base() + RC_N)
	f.act.dirI[_base() + k] = v


## The AI level's shares (data/director/ai.json brawl.recoil).
static func _ai() -> Dictionary:
	return DirAI.lv().get("brawl", {}).get("recoil", {})


## A knock-back has just been sent (DirLaunch.knock): tgt's window opens. kind: 1 the skid, 2 the upright slide, 3 the
## drift. dist: its length in units; endTick: when it is reckoned to end.
static func knocked(S: SimState, att, tgt, dist: float, kind: int, endTick: int) -> void:
	if not on() or tgt == null or not tgt.act.v2:
		return
	var c: Dictionary = cfg()
	_s(tgt, RC_LEFT, int(c.windowTicks))
	_s(tgt, RC_KIND, kind)
	_s(tgt, RC_LN, tgt.launchN)
	_s(tgt, RC_DIST, int(dist))
	_s(tgt, RC_AIR, 0)
	_s(tgt, RC_CR, 0)
	_s(tgt, RC_AIC, 0)
	_s(tgt, RC_AI, 0)
	var slot: int = S.fighters.find(tgt)
	if tgt.ai != null and SimRng.keyed(int(S.game.seed), "recoil.flip", S.tick * 4 + slot) < float(_ai().get("flip", 0.0)):
		var at: Array = c.aiTapTicks
		var t: int = int(at[0]) + int(SimRng.keyed(int(S.game.seed), "recoil.tap", S.tick * 4 + slot) * float(int(at[1]) - int(at[0]) + 1))
		_s(tgt, RC_AI, mini(t, int(c.windowTicks)) + 1)
	# With no press, a long knock-back on the ground ends in the flourish (Animation's): said now, for Camera to frame
	# the landing and for the body to be posed for it. A flip, if he taps, sends its own cue and replaces it.
	if kind != 3 and dist > float(c.flourishOverBh) * BH:
		_cue(S, tgt, att, "flourish", "backflip", tgt.x, tgt.y, SimWrap.wrap(tgt.x + _away(att, tgt) * dist), endTick, endTick - S.tick, true)


## Once a live tick, from dirUpdate: the windows count down, the AI taps and presses, a player's dodge tap flips him.
static func tick(S: SimState) -> void:
	if not on() or S.game.ko != null:
		return
	for f in S.fighters:
		if not f.act.v2 or f.act.dirI.size() < _base() + RC_N:
			continue
		var air: int = _g(f, RC_AIR)
		if air > 0:
			if f.state == "launched" or f.state == "down" or f.state == "dropped":
				_s(f, RC_AIR, 0)   # sent again in the air: no landing set, no counter-rush
			else:
				_s(f, RC_AIR, air - 1)
				if air == 1:
					_land(S, f)
		var cr: int = _g(f, RC_CR)
		if cr > 0:
			_s(f, RC_CR, cr - 1)
		var aic: int = _g(f, RC_AIC)
		if aic > 0:
			_s(f, RC_AIC, aic - 1)
		var bsl: int = _g(f, RC_BSL)
		if bsl > 0:
			_s(f, RC_BSL, bsl - 1)
			if bsl == 1:
				DirBrawl._reel(S, f, int(cfg().get("heavy", {}).get("reelTicks", 6)))   # 1a: no flip, so he reels at the slide's end
		var left: int = _g(f, RC_LEFT)
		if left <= 0:
			continue
		_s(f, RC_LEFT, left - 1)
		var ai: int = _g(f, RC_AI)
		if ai > 0:
			_s(f, RC_AI, ai - 1)
		var tap: bool = (f.ai == null and f.input.dodge and f.stunTicks <= 0) or (f.ai != null and ai == 1)
		if tap:
			_flip(S, f)


## Game Design's 1a (rulings-2026-10-22): a tapped heavy that lands clean in a brawl (DirBrawl._bigLanded) recoils him
## heavy.bh body heights as a slide of heavy.ticks, in place of its stagger in place. His blow on its way is lost, as a
## stagger loses it. It opens the flip's window (kind 4: a slide inside the brawl, which holds: its pull rests while he
## slides, and brings them back after). With no flip he reels heavy.reelTicks at its end. A wall behind him shortens it.
## The recoil cue, text "exit", says so (Combat's exit by weight: a heavy's backflip, fitted to the slide).
static func heavyRecoil(S: SimState, ex, f, o) -> bool:
	var h: Dictionary = cfg().get("heavy", {})
	if not on() or not bool(h.get("enabled", false)) or not o.act.v2:
		return false
	var dist: float = float(h.get("bh", 1.5)) * BH
	var ticks: int = int(h.get("ticks", 8))
	var dir: float = _away(f, o)
	var g: float = WorldTerrain.groundY(S, o.x)
	var ground: bool = o.y - g <= float(DirLaunch.data().knockBack.groundWithinBh) * BH and not WorldTerrain.seaAt(S, o.x)
	var so := Callable(WorldContact, "slideObstacle")
	if ground and so.is_valid():
		var ob = so.call(S, o.x, o.z, dir, dist)
		if ob is Dictionary and ob.get("hit", false):
			dist = maxf(0.0, float(ob.d) - DirLaunch.BUMP_SHORT)   # a wall behind him: the slide stops short of it
	DirBrawl._drop(S, ex, o)
	var r := SimState.Rush.new()
	r.px = SimWrap.wrap(o.x + dir * dist)
	var g2: float = WorldTerrain.groundY(S, r.px)
	r.py = g2 if ground else maxf(o.y, g2)
	r.pz = o.z
	r.end = S.T + float(ticks) * SimConst.DT
	o.rush = r
	knocked(S, f, o, dist, 4, S.tick + ticks)
	_s(o, RC_BSL, ticks)
	_cue(S, o, f, "exit", "backflip", o.x, o.y, r.px, S.tick + ticks, ticks, ground)
	SimEvents.feed(S, o.name + " RECOILS", "a clean heavy sends him back " + str(snappedf(dist / BH, 0.1)) + " bh over " + str(ticks) + " ticks: a dodge tap flips him out")
	return true


## Game Design's 23c 11: a teched pop landing (DirBrawl._popTick) is a recoil flip: the same backflip away from o,
## landing set where it ends, and the counter-rush within counterTicks after it. Inside the brawl (kind 4, locked).
## False with recoil flips off: then the tech is the tech alone.
static func popFlip(S: SimState, f, o) -> bool:
	if not on() or not f.act.v2:
		return false
	var c: Dictionary = cfg()
	var dir: float = _away(o, f)
	var ticks: int = int(c.flipTicks)
	var travel: float = float(c.flipBh) * BH
	var base: float = f.rush.py if f.rush != null else f.y
	var so := Callable(WorldContact, "slideObstacle")
	if so.is_valid():
		var ob = so.call(S, f.x, f.z, dir, travel)
		if ob is Dictionary and ob.get("hit", false):
			travel = maxf(0.0, float(ob.d) - DirLaunch.BUMP_SHORT)
	var r := SimState.Rush.new()
	r.px = SimWrap.wrap(f.x + dir * travel)
	r.py = maxf(base, WorldTerrain.groundY(S, r.px))
	r.pz = f.z
	r.end = S.T + float(ticks) * SimConst.DT
	r.arc = float(c.arcBh) * BH * dir
	f.rush = r
	f.vx = 0.0
	f.vy = 0.0
	f.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(f.x, o.x)), f.face)
	DirBrawl.recoilFree(f)
	_s(f, RC_LEFT, 0)
	_s(f, RC_AI, 0)
	_s(f, RC_KIND, 4)
	_s(f, RC_AIR, ticks)
	_cue(S, f, o, "flip", "backflip", f.x, f.y, r.px, S.tick + ticks, ticks, true)
	SimEvents.feed(S, f.name + " RECOIL FLIP", "out of the pop's landing: he lands set in " + str(ticks) + ", and his next blow within " + str(int(c.counterTicks)) + " is a counter-rush")
	return true


## While he is in the air of his flip: his presses wait for the landing.
static func flipping(S: SimState, f) -> bool:
	return on() and _g(f, RC_AIR) > 0


## True while his next blow would be a counter-rush (DirBands.farPressNow: from the far band it flies in, not a taunt).
static func due(S: SimState, f) -> bool:
	return on() and _g(f, RC_CR) > 0


## His press starts an approach (DirBands.begin): true when it is the counter-rush, which spends it.
static func counter(S: SimState, f) -> bool:
	if not on() or _g(f, RC_CR) <= 0:
		return false
	_s(f, RC_CR, 0)
	_s(f, RC_AIC, 0)
	DirRally.markCounter(S, f)   # 23d 10: the turn, if it lands on the chaser in the air
	var e = _ev(S, f, "counter_rush")
	e.target = float(S.fighters.find(SimRoster.opp(S, f)))
	SimEvents.feed(S, f.name + " COUNTER-RUSH", "out of his recoil flip: no crouch, no return, the first move his")
	return true


## The AI's counter press: 1 a light, 0 none (DirAI.aiInput).
static func aiPress(S: SimState, f) -> int:
	if not on() or f.ai == null or _g(f, RC_AIC) != 1 or _g(f, RC_CR) <= 0:
		return 0
	return 1


static func _away(att, tgt) -> float:
	return SimDamage.jor(SimMathx.jsign(SimWrap.sdx(att.x, tgt.x)), -tgt.face)


## The flip: his knock-back ends where he is, and he is carried flipBh further back, bowed, over flipTicks.
static func _flip(S: SimState, f) -> void:
	var c: Dictionary = cfg()
	var o = SimRoster.opp(S, f)
	var kind: int = _g(f, RC_KIND)
	var dir: float = _away(o, f)
	if kind == 1:
		if f.state != "launched" or f.launchN != _g(f, RC_LN):
			_s(f, RC_LEFT, 0)
			return   # the skid is over, or a later send has taken him: nothing to flip out of
		if f.vx != 0.0:
			dir = SimMathx.jsign(f.vx)
		if not _endSkid(S, f):
			return   # World's recoilEnd is not in yet: a skid can't be cut short (an upright slide and a drift still flip)
	else:
		if (f.state != "free" and not (kind == 4 and f.state == "locked")) or f.rush == null or f.rush.tgt != null:
			_s(f, RC_LEFT, 0)
			return   # his slide or drift has ended, or an approach has taken its place
		dir = SimMathx.jsign(SimWrap.sdx(f.x, f.rush.px)) if SimWrap.sdx(f.x, f.rush.px) != 0.0 else dir
		DirInterrupt.si(f, DirInterrupt.BUMP_AT, 0)   # the slide ends here, short of the obstacle it was to bump
	_s(f, RC_LEFT, 0)
	_s(f, RC_AI, 0)
	var g: float = WorldTerrain.groundY(S, f.x)
	var ground: bool = kind != 3 and f.y - g <= float(DirLaunch.data().knockBack.groundWithinBh) * BH and not WorldTerrain.seaAt(S, f.x)
	var travel: float = float(c.flipBh) * BH
	var so := Callable(WorldContact, "slideObstacle")
	if ground and so.is_valid():
		var ob = so.call(S, f.x, f.z, dir, travel)
		if ob is Dictionary and ob.get("hit", false):
			travel = maxf(0.0, float(ob.d) - DirLaunch.BUMP_SHORT)   # a wall behind him: he lands short of it (its ricochet is section 3's)
	var ticks: int = int(c.flipTicks)
	var r := SimState.Rush.new()
	r.px = SimWrap.wrap(f.x + dir * travel)
	var g2: float = WorldTerrain.groundY(S, r.px)
	r.py = g2 if ground else maxf(f.y, g2)
	r.pz = f.z
	r.end = S.T + float(ticks) * SimConst.DT
	r.arc = float(c.arcBh) * BH * dir   # bowed up whichever way he goes (Rush.arc bows to the mover's left)
	f.rush = r
	f.vx = 0.0
	f.vy = 0.0
	if kind != 4:
		f.state = "free"   # (out of a heavy's recoil in a brawl he stays in it)
	_s(f, RC_BSL, 0)   # a flip out of a heavy's recoil: no reel at its end
	f.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(f.x, o.x)), f.face)
	DirBrawl.recoilFree(f)   # no first-move lock and no return: the counter-rush is his
	_s(f, RC_AIR, ticks)
	_cue(S, f, o, "flip", "backflip" if ground else "tuck", f.x, f.y, r.px, S.tick + ticks, ticks, ground)
	SimEvents.feed(S, f.name + " RECOIL FLIP", "out of the knock-back after " + str(int(cfg().windowTicks) - _g(f, RC_LEFT)) + " ticks: he lands set in " + str(ticks) + ", and his next blow within " + str(int(c.counterTicks)) + " is a counter-rush")


## The skid is a journey: World ends it where he is (recoilEnd, its journey_end kind "recoil"), as the brake's control
## does. False when World's function is not in yet. With ground contact off, the brake's own control ends the flight.
static func _endSkid(S: SimState, f) -> bool:
	if S.contactOn:
		var re := Callable(WorldContact, "recoilEnd")
		if not re.is_valid():
			return false
		re.call(S, f)
	else:
		SimBrake.controlBack(S, f)   # Simulation's: control back where he is
	return f.state == "free"


## 23d item 9 (DirRally._landing): a rally's body lands, and his window opens as a knock-back skid's does (kind 1: a
## dodge tap in its first windowTicks flips him out of the journey), once a journey, with no flourish.
static func landed(S: SimState, att, tgt) -> void:
	if not on() or (_g(tgt, RC_KIND) == 1 and _g(tgt, RC_LN) == tgt.launchN):
		return
	knocked(S, att, tgt, 0.0, 1, S.tick)


## He lands set: his counter-rush window opens, and the AI draws its press.
static func _land(S: SimState, f) -> void:
	var c: Dictionary = cfg()
	_s(f, RC_CR, int(c.counterTicks))
	if f.ai != null and SimRng.keyed(int(S.game.seed), "recoil.counter", S.tick * 4 + S.fighters.find(f)) < DirRally.counterShare(S, f, float(_ai().get("counter", 0.0))):   # (in a rally its rally.counter: 10-26 item 37)
		var at: Array = c.aiCounterTicks
		var t: int = int(at[0]) + int(SimRng.keyed(int(S.game.seed), "recoil.counterAt", S.tick * 4 + S.fighters.find(f)) * float(int(at[1]) - int(at[0]) + 1))
		_s(f, RC_AIC, mini(t, int(c.counterTicks)) + 1)


static func _cue(S: SimState, f, by, text: String, exit: String, x: float, y: float, to: float, land: int, ticks: int, ground: bool) -> void:
	SimFx.cue(S, f, "recoil", text, exit)
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(by)) if by != null else -1.0
	e.x = x
	e.y = y
	e.amount = to
	e.n = land
	e.dur = float(ticks)
	e.k = 1.0 if ground else 0.0


static func _ev(S: SimState, f, name: String):
	SimFx.cue(S, f, name, "", "")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.n = S.tick
	return e
