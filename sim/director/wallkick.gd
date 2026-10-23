class_name DirWallKick
## The wall kick (Game Design's rulings-2026-10-22.md 2b and 5c; docs/design/fight-feel.md section 3), on the wall contact
## World has today: a sent body meeting a building's face that holds (WorldBrunt.hit, the wall slam). Behind
## data/director/interrupts.json wallKick.enabled (false: nothing runs, no slot is written, no cue is sent).
##  - A dodge tap in the last beforeTicks live ticks before he meets the face arms it (the AI: its level's wallKick share,
##    one keyed draw a send, tapping 2 ticks out, never sooner than its reaction time after the send).
##  - At the contact, World asks atWall: if it is armed and he meets the face at minIntoWall or more into it (below that
##    is Combat's plant, not built), the kick takes the contact and replaces the slam's stagger (5c). World halves the
##    slam's damage, skips the hold, the rebound and the stagger, and ends the journey (journey_end kind "kick"); the face
##    takes its hit as ever. The kick turned the slam into his own exit, so the rival's first move after a wall slam
##    (brawl.firstMove) is void.
##  - He kicks off toward his stick at keep of his arrival speed (the stick neutral or into the face: straight off it; the
##    AI: at the rival), a push of pushTicks live ticks in which his presses wait; then he has control again, in free
##    flight, carrying the push's speed. If the push is toward the rival (within towardDot of the way to him), his first
##    blow within rushBlowTicks of the push's start is a rush blow, as the recoil flip's counter-rush is: an approach with
##    no crouch, no return and no first-move lock, at recoilFlip.counterRush's speed (DirBands.begin). The AI presses it
##    on its level's brawl.recoil.counter share, recoilFlip.aiCounterTicks after the push. Into open air, plain free
##    flight.
## The cue: SimFx.cue kind "wall_kick", text "rush" (toward the rival) or "push", target the rival's slot, x and y where
## he leaves the face, n the tick the push ends, dur its ticks, amount his kick's speed.
## State: f.act.dirI slots after the calm turn's (DirCalm, 7b), after the press wait's, the mash run's and the recoil
## flips' (sized only when the switch is on).

const WK_ARM: int = 0     # the launch number it is armed for, plus 1; 0 none
const WK_SEEN: int = 1    # the launch number the AI has drawn for, plus 1
const WK_PLAN: int = 2    # the AI's draw for that send: 1 it kicks
const WK_SENT: int = 3    # the live tick that send was first seen
const WK_PUSH: int = 4    # 1 while his push runs (its rush); 0 none
const WK_VX: int = 5      # the push's velocity (units a second), carried into his free flight at its end
const WK_VY: int = 6
const WK_CR: int = 7      # live ticks left in which his next blow is a rush blow; 0 none
const WK_AIC: int = 8     # the AI's press: live ticks until it presses, plus 1; 0 none
const WK_N: int = 9


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("wallKick", {})


static func on() -> bool:
	return DirInterrupt.on() and bool(cfg().get("enabled", false))


static func _base() -> int:
	return DirCalm._base() + DirCalm.CM_N   # after the calm turn's rest record (7b), which follows the press wait's and the mash run's


static func _g(f, k: int) -> int:
	var i: int = _base() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirGrapple._size(f)
	if f.act.dirI.size() < _base() + WK_N:
		f.act.dirI.resize(_base() + WK_N)
	f.act.dirI[_base() + k] = v


## Once a live tick (DirExchange.dirUpdate): a sent body aimed at a building that holds, within beforeTicks of its face,
## is armed by a dodge tap (the AI's by its draw); a push that has ended hands him his flight; the rush blow's window and
## the AI's press count down.
static func tick(S: SimState) -> void:
	if not on() or S.game.ko != null:
		return
	var c: Dictionary = cfg()
	for f in S.fighters:
		if f.act.dirI.size() >= _base() + WK_N:
			if _g(f, WK_PUSH) == 1 and (f.rush == null or f.state != "free"):
				_s(f, WK_PUSH, 0)
				if f.state == "free" and f.rush == null:
					f.vx = float(_g(f, WK_VX))   # the push is over: control again, in free flight at the push's speed
					f.vy = float(_g(f, WK_VY))
			if _g(f, WK_CR) > 0:
				_s(f, WK_CR, _g(f, WK_CR) - 1 if f.state == "free" else 0)
			if _g(f, WK_AIC) > 1:
				_s(f, WK_AIC, _g(f, WK_AIC) - 1)
		if not f.act.v2 or f.state != "launched" or f.aimB < 0 or f.aimB >= S.buildings.size() or f.launchSpecial:
			continue
		var b = S.buildings[f.aimB]
		var dx: float = SimWrap.sdx(f.x, b.x)
		if not b.alive or dx * f.vx <= 0.0 or f.vx == 0.0:
			continue
		if f.ai != null and _g(f, WK_SEEN) != f.launchN + 1:
			_s(f, WK_SEEN, f.launchN + 1)
			_s(f, WK_SENT, S.tick)
			var share: float = float(DirAI.lv().get("wallKick", 0.0))
			_s(f, WK_PLAN, 1 if SimRng.keyed(int(S.game.seed), "wallkick.ai", f.launchN * 4 + S.fighters.find(f)) < share else 0)
		if _g(f, WK_ARM) == f.launchN + 1:
			continue
		var ticks: float = maxf(0.0, absf(dx) - b.w * 0.5) / (absf(f.vx) * SimConst.DT)
		if ticks > float(c.beforeTicks):
			continue
		var tap: bool = f.ai == null and f.input.dodge and f.stunTicks <= 0
		if f.ai != null:
			tap = _g(f, WK_PLAN) == 1 and ticks <= 2.0 and S.tick - _g(f, WK_SENT) >= int(DirAI.skill().get("reactTicks", 14))
		if tap:
			_s(f, WK_ARM, f.launchN + 1)


## World's wall contact (WorldBrunt.hit, a face that holds), before its damage: true when the kick takes it. Sets his
## push; World halves the slam and ends the journey.
static func atWall(S: SimState, f, b, edge: float, dir: float, spN: float) -> bool:
	if not on() or _g(f, WK_ARM) != f.launchN + 1:
		return false
	var c: Dictionary = cfg()
	if absf(f.vx / f.launchT) < float(c.minIntoWall):
		return false   # under the line: Combat's plant (not built), so the wall slam as ever
	_s(f, WK_ARM, 0)
	var o = SimRoster.opp(S, f)
	var sp: float = float(c.keep) * spN
	f.x = SimWrap.wrap(edge - dir * 18.0)   # off the face, where the rebound would have put him
	# The way to the rival, and his push: toward his stick; neutral or into the face, straight off it; the AI at the rival.
	var tx: float = SimWrap.sdx(f.x, o.x)
	var ty: float = o.y - f.y
	var tl: float = maxf(SimDetMath.hypot(tx, ty), 1.0)
	var ux: float = f.input.mx
	var uy: float = f.input.my
	if f.ai != null:
		ux = tx / tl
		uy = ty / tl
	var ul: float = SimDetMath.hypot(ux, uy)
	if ul <= SimAct.awayDead or ux * dir > 0.0 and absf(ux) >= absf(uy):
		ux = -dir
		uy = 0.0
		ul = 1.0
	ux /= ul
	uy /= ul
	var toward: bool = (ux * tx + uy * ty) / tl >= float(c.get("towardDot", 0.5))
	var n: int = int(c.get("pushTicks", 8))
	var T: float = float(n) * SimConst.DT
	var r := SimState.Rush.new()
	r.px = SimWrap.wrap(f.x + ux * sp * T)
	r.py = maxf(f.y + uy * sp * T, WorldTerrain.groundY(S, r.px))
	r.pz = f.z
	r.end = S.T + T
	f.rush = r
	f.vx = 0.0
	f.vy = 0.0
	_s(f, WK_PUSH, 1)
	_s(f, WK_VX, int(round(ux * sp)))
	_s(f, WK_VY, int(round(uy * sp)))
	_s(f, WK_CR, int(c.get("rushBlowTicks", 20)) if toward else 0)
	_s(f, WK_AIC, 0)
	if toward and f.ai != null and SimRng.keyed(int(S.game.seed), "wallkick.counter", S.tick * 4 + S.fighters.find(f)) < float(DirRecoil._ai().get("counter", 0.0)):
		var at: Array = DirRecoil.cfg().get("aiCounterTicks", [2, 8])
		var t: int = int(at[0]) + int(SimRng.keyed(int(S.game.seed), "wallkick.counterAt", S.tick * 4 + S.fighters.find(f)) * float(int(at[1]) - int(at[0]) + 1))
		_s(f, WK_AIC, mini(n + t, int(c.get("rushBlowTicks", 20))) + 1)
	DirBrawl.recoilFree(f)   # the rival's first move after a wall slam is void: the kick is his own exit
	f.face = SimDamage.jor(SimMathx.jsign(tx), f.face)
	SimFx.cue(S, f, "wall_kick", "rush" if toward else "push", "")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(o))
	e.x = f.x
	e.y = f.y
	e.n = S.tick + n
	e.dur = float(n)
	e.amount = sp
	SimEvents.feed(S, f.name + " WALL KICK", "off the face at " + str(int(sp)) + " u/s " + ("toward " + o.name + ": a blow within " + str(int(c.get("rushBlowTicks", 20))) + " ticks is a rush blow" if toward else "into open air") + "; the slam's damage is halved, no stagger")
	return true


## While his push runs: his presses wait for its end (DirExchange._start, DirBands.farPressNow).
static func pushing(S: SimState, f) -> bool:
	return on() and _g(f, WK_PUSH) == 1 and f.rush != null


## True while his next blow would be a rush blow (DirBands.farPressNow: from the far band it flies in, not a taunt).
static func due(S: SimState, f) -> bool:
	return on() and _g(f, WK_CR) > 0


## His press starts an approach (DirBands.begin): true when it is the rush blow, which spends it.
static func rushBlow(S: SimState, f) -> bool:
	if not on() or _g(f, WK_CR) <= 0:
		return false
	_s(f, WK_CR, 0)
	_s(f, WK_AIC, 0)
	SimFx.cue(S, f, "counter_rush", "wall_kick", "")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(SimRoster.opp(S, f)))
	SimEvents.feed(S, f.name + " RUSH BLOW", "off his wall kick: no crouch, no return, the first move his")
	return true


## The AI's rush blow press: 1 a light, 0 none (DirAI.aiInput).
static func aiPress(S: SimState, f) -> int:
	if not on() or f.ai == null or _g(f, WK_AIC) != 1 or _g(f, WK_CR) <= 0:
		return 0
	return 1


## The share of the slam he takes when the kick took the contact (World's).
static func damageMul() -> float:
	return float(cfg().get("damageMul", 0.5))
