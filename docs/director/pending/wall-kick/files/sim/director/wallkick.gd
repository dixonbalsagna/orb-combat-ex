class_name DirWallKick
## The wall kick (Game Design's rulings-2026-10-22.md 2b; docs/design/fight-feel.md section 3), on the wall contact World
## has today: a sent body meeting a building's face that holds (WorldBrunt.hit, the wall slam). Behind
## data/director/interrupts.json wallKick.enabled (false: nothing runs, no slot is written, no cue is sent).
##  - A dodge tap in the last beforeTicks live ticks before he meets the face arms it (the AI: its level's wallKick share,
##    one keyed draw a send, tapping 2 ticks out, never sooner than its reaction time after the send).
##  - At the contact, World asks atWall: if it is armed and he meets the face at minIntoWall or more into it (below that
##    is Combat's plant, not built), the kick takes the contact. World halves the slam's damage, skips the hold, the
##    rebound and the stagger, and ends the journey (journey_end kind "kick"); the face takes its hit as ever.
##  - He kicks off at keep of his arrival speed: with the stick neutral, into the wall or toward the rival, as a rush back
##    to striking distance of the rival (rushTicks bound its time), so he arrives to strike; with the stick any other
##    way, as a push along it.
##  - After a wall slam he is staggered at once, so no press of his can come in the ticks after it: "4 ticks either
##    side" is the 4 before, until Game Design rules on the after side.
## The cue: SimFx.cue kind "wall_kick", text "rush" or "push", target the rival's slot, x and y where he leaves the face,
## n the tick he arrives (a rush) or 0, dur its ticks, amount his kick's speed.
## State: f.act.dirI slots after the recoil flips' (sized only when the switch is on).

const WK_ARM: int = 0     # the launch number it is armed for, plus 1; 0 none
const WK_SEEN: int = 1    # the launch number the AI has drawn for, plus 1
const WK_PLAN: int = 2    # the AI's draw for that send: 1 it kicks
const WK_SENT: int = 3    # the live tick that send was first seen
const WK_N: int = 4


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("wallKick", {})


static func on() -> bool:
	return DirInterrupt.on() and bool(cfg().get("enabled", false))


static func _base() -> int:
	return DirRecoil._base() + DirRecoil.RC_N


static func _g(f, k: int) -> int:
	var i: int = _base() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirGrapple._size(f)
	if f.act.dirI.size() < _base() + WK_N:
		f.act.dirI.resize(_base() + WK_N)
	f.act.dirI[_base() + k] = v


## Once a live tick (DirExchange.dirUpdate): a sent body aimed at a building that holds, within beforeTicks of its face,
## is armed by a dodge tap (the AI's by its draw).
static func tick(S: SimState) -> void:
	if not on() or S.game.ko != null:
		return
	var c: Dictionary = cfg()
	for f in S.fighters:
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
## kick-off; World halves the slam and ends the journey.
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
	var mx: float = f.input.mx
	var my: float = f.input.my
	var ml: float = SimDetMath.hypot(mx, my)
	var toward: float = SimMathx.jsign(SimWrap.sdx(f.x, o.x))
	var rush: bool = ml <= SimAct.awayDead or mx * dir > 0.0 or (absf(mx) >= absf(my) and mx * toward > 0.0)
	var n: int = 0
	if rush:
		var r := SimState.Rush.new()
		r.tgt = o
		r.off = DirBands._endOff(S, o, SimMathx.jsign(SimWrap.sdx(o.x, f.x)) if SimWrap.sdx(o.x, f.x) != 0.0 else -toward)
		var d: float = maxf(0.0, DirBands.dist(f, o) - float(DirBands.data().engageBh) * DirInterrupt.BH)
		n = clampi(int(ceil(d / maxf(sp, 1.0) * DirData.TICKS_PER_SEC)), int(c.rushTicks[0]), int(c.rushTicks[1]))
		r.end = S.T + float(n) * SimConst.DT
		if S.depthOn:
			r.offZ = DirBrawl.arriveOff(S, o, r.off)
		f.rush = r
		f.vx = 0.0
		f.vy = 0.0
	else:
		f.rush = null
		f.vx = mx / ml * sp   # a plain velocity: World's journey end sets his traversal factor to 1
		f.vy = my / ml * sp
	f.face = SimDamage.jor(toward, f.face)
	SimFx.cue(S, f, "wall_kick", "rush" if rush else "push", "")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(o))
	e.x = f.x
	e.y = f.y
	e.n = (S.tick + n) if rush else 0
	e.dur = float(n)
	e.amount = sp
	SimEvents.feed(S, f.name + " WALL KICK", "off the face at " + str(int(sp)) + " u/s " + ("back at " + o.name + ", " + str(n) + " ticks" if rush else "along his stick") + "; the slam's damage is halved")
	return true


## The share of the slam he takes when the kick took the contact (World's).
static func damageMul() -> float:
	return float(cfg().get("damageMul", 0.5))
