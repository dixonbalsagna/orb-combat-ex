# ---------------------------------------------------------------- control: the centre, the walk-out, the double hit (slice C1)

## His free-flight speed in the neutral stance, in units a second. The core's read carries the stance he holds, and a
## guard's slowing of the nudge is the brawl's own number (nudge.guard), so his stance is set aside for the read.
static func _flySpeed(S: SimState, f) -> float:
    var st: float = f.stance
    f.stance = 0.0
    var sp: float = SimFighter.flightSpeed(S, f, false)
    f.stance = st
    return sp


## The point midway between the two.
static func _mid(ex) -> PackedFloat64Array:
    return PackedFloat64Array([SimWrap.wrap(ex.A.x + SimWrap.sdx(ex.A.x, ex.D.x) * 0.5), (ex.A.y + ex.D.y) * 0.5])


## For Camera, Animation and UI: the brawl's centre. x, y: the point midway between the two. vx, vy: the speed the pair
## moves at on the next tick, in units a second. part: the live ticks running for which both have held away (the
## walk-out comes at partTicks). double: the live ticks until a double hit's two blows land, or -1 when none is on its
## way. Empty when ex is not a running brawl.
static func centre(S: SimState, ex) -> Dictionary:
    if not isBrawl(ex) or ex.branch != "":
        return {}
    var m: PackedFloat64Array = _mid(ex)
    var keep: float = SimFighter.lockedKeep(SimConst.DT)
    var dbl: int = _g(ex.A, DBL_AT)
    return {"x": m[0], "y": m[1], "vx": (ex.A.vx + ex.D.vx) * 0.5 * keep, "vy": (ex.A.vy + ex.D.vy) * 0.5 * keep,
        "part": _g(ex.A, PART_N), "double": (maxi(0, dbl - _now(S)) if dbl > 0 else -1)}


## True while a double hit's two blows are on their way: nothing either fighter presses counts until they land.
static func doubling(ex) -> bool:
    return isBrawl(ex) and ex.branch == "" and _g(ex.A, DBL_AT) > 0


## The button's cell for a press_ack: x a light, y a heavy, b a signature.
static func _cell(kind: String) -> String:
    return "b" if kind == "sig" else ("y" if kind == "heavy" else "x")


## True when the pair's middle at (x, y) is inside a standing building's box. The ground is never the answer here: the
## core holds a fighter on it, so a brawl slides along the ground and up a ridge by itself.
static func _walled(S: SimState, x: float, y: float) -> bool:
    var yy: float = maxf(y + 0.5 * DirInterrupt.BH, WorldTerrain.groundY(S, x) + 0.01)
    return WorldStructures.blockedAt(S, x, yy, 0.0, 0.0)


## The brawl's movement, once a live tick (brawl-second-pass.md section 1). Each stick goes through Controls' ramp
## and moves the centre at nudgeMul of his own free-flight speed, less while he guards; a staggered fighter has no
## stick. The two add up, so two who agree go twice as fast and two who oppose cancel. The centre's own speed follows
## the sticks by at most a full nudge over nudgeRampTicks, up and down. The speed the brawl began with is added,
## fading over carryTicks. The whole is never more than maxStepBh in a tick. A building's face stops it, and the part
## of the step along the face carries on. The core moves a locked fighter by his own velocity on its next step, after
## its damping (SimFighter.lockedKeep): so both are given the centre's velocity over what the damping keeps.
static func _move(S: SimState, ex) -> void:
    var c: Dictionary = cfg()
    var A = ex.A
    var D = ex.D
    var dt: float = SimConst.DT
    var live: bool = not quiet(ex) and _g(A, DBL_AT) == 0
    var tx: float = 0.0
    var ty: float = 0.0
    var top: float = 0.0
    for f in [A, D]:
        var rx: int = 0
        var ry: int = 0
        if live and f.stunTicks <= 0:
            var st: PackedFloat64Array = stick(ex, f)
            rx = SimAim.nudge_units(st[0])
            ry = SimAim.nudge_units(st[1])
        var nx: int = SimAim.nudge_ramp(_g(f, NUDGE_X), rx)
        var ny: int = SimAim.nudge_ramp(_g(f, NUDGE_Y), ry)
        _s(f, NUDGE_X, nx)
        _s(f, NUDGE_Y, ny)
        var sp: float = float(c.nudgeMul) * _flySpeed(S, f)
        top = maxf(top, sp)
        var ux: float = float(nx) / 127.0
        var uy: float = float(ny) / 127.0
        var ul: float = SimDetMath.hypot(ux, uy)
        if ul > 1.0:
            ux /= ul
            uy /= ul
        if f.stance == 1.0 and _g(f, LINE) == 0:
            sp *= float(c.nudge.guard)   # he guards
        tx += ux * sp
        ty += uy * sp
    var acc: float = top / maxf(1.0, float(int(c.nudgeRampTicks)))
    var vx: float = float(_g(A, CEN_VX)) / 16.0
    var vy: float = float(_g(A, CEN_VY)) / 16.0
    vx += clampf(tx - vx, -acc, acc)
    vy += clampf(ty - vy, -acc, acc)
    var wx: float = vx
    var wy: float = vy
    var cn: int = _g(A, CARRY_N)
    if cn > 0:
        var share: float = float(cn) / maxf(1.0, float(int(c.carryTicks)))
        wx += float(_g(A, CARRY_X)) / 16.0 * share
        wy += float(_g(A, CARRY_Y)) / 16.0 * share
        _s(A, CARRY_N, cn - 1)
    var cap: float = float(c.maxStepBh) * DirInterrupt.BH / dt
    var wl: float = SimDetMath.hypot(wx, wy)
    if wl > cap:
        wx *= cap / wl
        wy *= cap / wl
    if A.rush != null or D.rush != null:
        wx = 0.0   # a step in is still carrying one of them: the pair moves once he has arrived
        wy = 0.0
    elif wx != 0.0 or wy != 0.0:
        # A step may not bring the pair's middle within nudge.clearBh of a face, looking along the step. A pair already
        # inside a building's box moves freely, so it can come out. Nothing here damages a building.
        var m: PackedFloat64Array = _mid(ex)
        var cl: float = float(c.nudge.clearBh) * DirInterrupt.BH
        var sl: float = SimDetMath.hypot(wx, wy)
        if not _walled(S, m[0], m[1]) and _walled(S, SimWrap.wrap(m[0] + wx * dt + wx / sl * cl), m[1] + wy * dt + wy / sl * cl):
            var okx: bool = wx != 0.0 and not _walled(S, SimWrap.wrap(m[0] + wx * dt + SimMathx.jsign(wx) * cl), m[1])
            var oky: bool = wy != 0.0 and not _walled(S, m[0], m[1] + wy * dt + SimMathx.jsign(wy) * cl)
            if okx and (not oky or absf(wx) >= absf(wy)):
                wy = 0.0
                vy = 0.0
            elif oky:
                wx = 0.0
                vx = 0.0
            else:
                wx = 0.0
                wy = 0.0
                vx = 0.0
                vy = 0.0
    # On a slope the ground lifts a fighter who walks into it. The whole step, the lift included, keeps to the cap: the
    # step across is halved until it does, and a face too steep for that stops it (a nudge upward goes over).
    if wx != 0.0:
        var fit: bool = false
        for _k in range(5):
            var lift: float = 0.0
            for f in [A, D]:
                lift = maxf(lift, WorldTerrain.groundY(S, SimWrap.wrap(f.x + wx * dt)) - (f.y + wy * dt))
            if lift <= 0.0 or SimDetMath.hypot(wx * dt, wy * dt + lift) <= cap * dt:
                fit = true
                break
            wx *= 0.5
        if not fit:
            wx = 0.0
    _s(A, CEN_VX, int(round(vx * 16.0)))
    _s(A, CEN_VY, int(round(vy * 16.0)))
    _s(A, MOVE_X, int(round(wx * 16.0)))
    _s(A, MOVE_Y, int(round(wy * 16.0)))
    carryOn(ex)


## Both fighters are given the pair's velocity, over what the core's damping keeps. Once a tick from _move, and again
## after each blow (DirExchange.runBeat): a strike places its attacker and stops him, and the pair's drift carries on.
static func carryOn(ex) -> void:
    if not isBrawl(ex) or ex.branch != "" or ex.A.state != "locked" or ex.D.state != "locked":
        return
    var keep: float = SimFighter.lockedKeep(SimConst.DT)
    for f in [ex.A, ex.D]:
        f.vx = float(_g(ex.A, MOVE_X)) / 16.0 / keep
        f.vy = float(_g(ex.A, MOVE_Y)) / 16.0 / keep


## True on a tick both hold away (brawl-second-pass.md section 1): each stick within partDeg of straight away from
## the rival, with no blow of his on its way or kept, no attack button down, and neither reeling nor staggered. A
## guard doesn't stop it: backing off behind a guard is the ordinary way to part.
static func _parting(S: SimState, ex) -> bool:
    for f in [ex.A, ex.D]:
        var o = ex.D if f == ex.A else ex.A
        var i: SimIntent = f.input
        if f.stunTicks > 0 or _g(f, LINE) != 0 or _g(f, HELD_P) != 0 or _now(S) < _g(f, REEL_AT):
            return false
        if i.light or i.heavy or i.lightHeld or i.heavyHeld:
            return false
        if not _away(ex, f, o):
            return false
    return true


## The stick the brawl's movement reads from f. A player's is his own. The AI's is the nudge it holds: it is kept out
## of its intent, where a stick also leans its blows and tilts its launches, so a nudge moves the centre and nothing else.
static func stick(ex, f) -> PackedFloat64Array:
    if f.ai == null:
        return PackedFloat64Array([f.input.mx, f.input.my])
    var o = ex.D if f == ex.A else ex.A
    var side: float = 1.0 if SimWrap.sdx(f.x, o.x) >= 0.0 else -1.0   # toward the rival
    if _g(f, AI_PART) > 0:
        return PackedFloat64Array([-side, 0.0])
    var n: int = _g(f, AI_NUDGE)
    return PackedFloat64Array([side if n == 1 else (-side if n == 2 else (1.0 if n == 3 else (-1.0 if n == 4 else 0.0))), 0.0])


## True when f offers to part from the rival o. A player: his stick past the dead zone, within partDeg of straight
## away. The AI: only when it has chosen to walk out (_aiPart). The ground it gives as it guards moves the centre and
## is no offer, or two AIs that guarded together would part by accident.
static func _away(ex, f, o) -> bool:
    if f.ai != null:
        return _g(f, AI_PART) > 0
    if SimDetMath.hypot(f.input.mx, f.input.my) <= SimAct.awayDead:
        return false
    return SimAim.angle_off_away_deg(f.input.mx, f.input.my, 1 if SimWrap.sdx(o.x, f.x) >= 0.0 else -1) <= int(cfg().partDeg)


## The double hit (brawl-second-pass.md section 7): a trade still level at doubleTicks. Both lines are cleared and
## each throws one blow, worth a skill strike, that can't be blocked, turned or dodged. The two land on the same tick,
## double.windupTicks from now. The cue goes out now, ahead of the contact, and the mood takes its units on this tick:
## so from here no press, dodge, burst or reversal of either fighter counts until they land (doubling).
static func _double(S: SimState, ex) -> void:
    var c: Dictionary = cfg()
    var lead: int = int(c.double.windupTicks)
    var dmg: float = float(c.light.damage) * float(c.damageMul) * float(c.skillMul)
    var held: int = S.tick - _g(ex.A, TRADE_T0)
    for f in [ex.A, ex.D]:
        _drop(S, ex, f)
        _s(f, REEL_AT, 0)
        _s(f, RUN, 0)
        _s(f, RIP_UNTIL, 0)
    _tradeReset(ex)
    var was: bool = _inTick
    _inTick = true
    for f in [ex.A, ex.D]:
        blowAt(S, ex, f, LIGHT, lead, dmg, {"double": true, "sure": true, "style": "tech"})
    _inTick = was
    _s(ex.A, DBL_AT, _now(S) + lead)
    _s(ex.A, DBL_N, 0)
    _s(ex.A, PART_N, 0)
    var m: PackedFloat64Array = _mid(ex)
    var e = _ev(S, ex.A, "double_hit", "both")
    e.target = float(S.fighters.find(ex.D))
    e.n = S.tick + lead
    e.amount = float(lead)
    e.dur = float(held)
    e.x = m[0]
    e.y = m[1]
    e.k = 3.0   # who is hit, by bits: 1 the cue's fighter, 2 its target. Both, always.
    SimEvents.feed(S, "DOUBLE HIT", ex.A.name + " and " + ex.D.name + " land together after " + str(held) + " ticks of a level trade")


## The double hit has landed: both are thrown back double.throwBh from the centre, opposite ways, over
## double.throwTicks, each upright (a slide on the ground, a drift in the air). Nobody won a decisive exchange, and
## the throw costs no wear of its own. The brawl ends.
static func _thrownApart(S: SimState, ex) -> void:
    var c: Dictionary = cfg()
    var m: PackedFloat64Array = _mid(ex)
    var dist: float = float(c.double.throwBh) * DirInterrupt.BH
    var ticks: int = int(c.double.throwTicks)
    var within: float = float(DirLaunch.data().knockBack.groundWithinBh) * DirInterrupt.BH
    var sA: float = 1.0 if SimWrap.sdx(ex.D.x, ex.A.x) >= 0.0 else -1.0   # the attacker's side of the rival
    var held: int = int(ceil(maxf(0.0, S.dirS.stop) * DirData.TICKS_PER_SEC))   # the blow's hit-stop holds the slide's start
    _s(ex.A, DBL_AT, 0)
    for f in [ex.A, ex.D]:
        var r := SimState.Rush.new()
        r.px = SimWrap.wrap(m[0] + (sA if f == ex.A else -sA) * dist)
        var g: float = WorldTerrain.groundY(S, r.px)
        var ground: bool = f.y - WorldTerrain.groundY(S, f.x) <= within and not WorldTerrain.seaAt(S, r.px)
        r.py = g if ground else maxf(f.y, g)
        r.end = S.T + float(ticks) * SimConst.DT
        f.rush = r
        f.vx = 0.0
        f.vy = 0.0
        SimFx.knockback(S, f, null, "slideShort" if ground else "drift", absf(SimWrap.sdx(f.x, r.px)), S.tick + ticks + held)
    end(S, ex, "double")


## The AI's nudge for the choice it has just made (attack: a string or a heavy; otherwise a guard). At its level's
## nudgeShare it holds one until its next choice. A fighter who cares for people, or feeds on them (his `care`), takes
## the brawl away from the more peopled side, or toward it. Otherwise it presses forward as it attacks and gives
## ground as it guards.
static func _aiNudge(S: SimState, ex, f, attack: bool) -> void:
    var bl: Dictionary = DirAI.lv().get("brawl", {})
    if SimRng.keyed(int(S.game.seed), "brawl.nudge", S.tick * 2 + (0 if f == ex.A else 1)) >= float(bl.get("nudgeShare", 0.0)):
        _s(f, AI_NUDGE, 0)
        return
    if f.care != 0.0:
        var r: float = DirLaunch.CARE_R
        var right: float = WorldStructures.popNear(S, SimWrap.wrap(f.x + r), r)
        var left: float = WorldStructures.popNear(S, SimWrap.wrap(f.x - r), r)
        if right != left:
            var people: int = 3 if right > left else 4
            _s(f, AI_NUDGE, people if f.care < 0.0 else 7 - people)
            return
    _s(f, AI_NUDGE, 1 if attack else 2)


## The AI's walk-out. The first time in a brawl that the rival offers to part, it weighs once, at its level's walkOut,
## whether to hold away too and let the brawl go. Returns true while it is walking out: it presses nothing then, until
## the brawl ends, the rival's stick comes back, or twice partTicks have gone. After that it stays for this brawl, so
## a rival can't draw again by moving his stick.
static func _aiPart(S: SimState, ex, f, o, bl: Dictionary) -> bool:
    var p: int = _g(f, AI_PART)
    var offered: bool = o.stunTicks <= 0 and _away(ex, o, f)
    if p == 0 and offered and _g(f, LINE) == 0:   # it weighs when it has no blow of its own on the way
        var yes: bool = SimRng.keyed(int(S.game.seed), "brawl.walk", S.tick * 2 + (0 if f == ex.A else 1)) < float(bl.get("walkOut", 0.0))
        p = S.tick + 2 * int(cfg().partTicks) if yes else -1
    elif p > 0 and (S.tick > p or not offered):
        p = -1   # it didn't come off: back to the fight
    _s(f, AI_PART, p)
    return p > 0


