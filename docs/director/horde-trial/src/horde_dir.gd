class_name DirHorde
extends RefCounted
## The horde, the director's side (docs/ep/proposals/horde-trial-design.md sections 3 and 6.4; Game Design's rulings docs/design/horde-trial.md).
## The run: the waves, the refills, the falls, the end. No exchange in a horde match: the pack is fought outside it.
## No draw from the match's stream: keyed draws only, each with its own key (the count of bodies sent, or the run's tick and the place).
## A fighter's mark is read through DirBrawl.rivalOf, never by the counted spelling. Scratch only (the trial); nothing lands.

const WEIGHT: Array = ["", "light", "medium", "heavy"]


static func on(S: SimState) -> bool:
	return S.hordeOn


static func _c() -> Dictionary:
	return SimHorde.data()


static func capTicks() -> int:
	return int(round(float(_c().cap.seconds) / SimConst.DT))


## Seats with a pad on them (the computer flag off).
static func pads(S: SimState) -> int:
	var n: int = 0
	for k in range(SimHorde.seats):
		if S.fighters[k].ai == null:
			n += 1
	return n


static func _left(R) -> int:
	return R.mix[0] + R.mix[1] + R.mix[2]


## Once a live tick, from DirExchange.dirUpdate, beside DirOutside.tick.
static func tick(S: SimState, dt: float) -> void:
	if dt <= 0.0 or not S.hordeOn or S.horde.over != 0:
		return
	_seats(S)
	_run(S)
	if S.horde.over != 0:
		return
	_marks(S)
	for k in range(S.fighters.size()):
		var f = S.fighters[k]
		var h = f.hd
		if f.out or h.phase == 7:
			continue
		if h.kind == 0:
			if f.act.dodgeTick != h.dg:   # a new dodge tap: clean when no other tap came in the again-time before it
				h.dgOk = 1 if f.act.dodgeTick - h.dg > int(_c().play.dodgeAgainTicks) else 0
				h.dg = f.act.dodgeTick
			if h.at != 0 and (h.t > 0 or f.rush != null) and (f.input.dodge or f.input.guardPress):
				h.at = 0   # the player's own lunge, called off by a dodge or a guard press: at once, at no cost
				h.buf = 0
				h.t = 0
				f.rush = null
				SimFx.cue(S, f, "horde_blow", "off", "")
				continue
			if h.at != 0 and h.t > 0 and S.tick >= h.t:
				_fly(S, f)   # the lunge's wind-up is over: the flight to the body
		else:
			f.power = 0.0   # a pack body's power stays at nothing: no tier, no form, no stronger blow
			if h.phase == 1 and f.rush == null:
				h.phase = 2   # arrived, 4 bh out: in the fight, free to wind up after the settle
				h.ready = S.tick + int(_c().play.settleTicks)
		if h.at != 0 and S.tick >= h.at:
			if h.kind == 0:
				_land(S, f)   # a player's pack blow
			else:
				_strike(S, f)   # a pack body's
		elif h.kind != 0 and h.phase == 6 and f.state != "launched" and f.rush == null:
			_away(S, k, "sent")   # a sent body has landed: its place goes away
		elif h.kind != 0 and (h.phase == 4 or h.phase == 5) and S.tick >= h.t:
			h.phase = 2   # open or reeling, over: back to the crowd, free to wind up when a lane is
			h.ready = S.tick


## A seat's computer flag flipped by the host (a pad joined or left, SimCore.toggleAI). A pad taking a seat for the first time in the run gets a
## fresh body 40 bh from the other seat; one coming back gets the seat as it was left (its body and its phase: in the fight, or down), beside the
## other seat. It is the player's from that tick: nothing flies it in. A seat let go goes away, its phase and body kept.
static func _seats(S: SimState) -> void:
	for s in range(SimHorde.seats):
		var P = S.fighters[s]
		var h = P.hd
		if P.ai == null and P.out:
			var Q = null
			for q in range(SimHorde.seats):
				if q != s and not S.fighters[q].out:
					Q = S.fighters[q]
			var side: float = -1.0 if s < SimHorde.seats - 1 else 1.0
			var x: float = SimWrap.wrap(Q.x + side * float(_c().respawn.spawnBh) * DirBands.BH) if Q != null else P.x
			var y: float = Q.y if Q != null else maxf(60.0, SimFighter.floorFor(S, P, P.x, 0.0))
			if h.was == 0:
				SimHorde.fresh(S, s, String(P.id), x, y)
				h.phase = 2
				h.was = 1
			else:
				P.x = x
				P.y = y
				P.vx = 0.0
				P.vy = 0.0
			P.out = false
			S.horde.mark[s] = _nearestPack(S, P)
			SimFx.cue(S, P, "horde_join", "fresh" if h.taken == 0 and h.downs == 0 else "back", "")
		elif P.ai != null and not P.out:
			P.out = true   # let go: away, its phase and body kept; every wind-up at it spoiled
			h.at = 0
			h.buf = 0
			h.t = 0
			for k in range(SimHorde.seats, S.fighters.size()):
				var f = S.fighters[k]
				if not f.out and S.horde.mark[k] == s and f.hd.phase == 3:
					_spoil(S, f)
			SimHorde.park(P)
			SimFx.cue(S, P, "horde_leave", "", "")


## The run's clock, the wave, the refills, the backstop.
static func _run(S: SimState) -> void:
	var R = S.horde
	R.t += 1
	if R.t >= capTicks():
		_end(S, 3)
		return
	if R.rest > 0:
		R.rest -= 1
		if R.rest == 0:
			_wave(S)
		return
	for k in range(SimHorde.seats, S.fighters.size()):
		var f = S.fighters[k]
		if f.out and f.hd.t > 0 and S.tick >= f.hd.t and _left(R) > 0:
			_refill(S, k)


## The next wave starts: its count (x the two-player count with both seats in), the three places staggered in.
static func _wave(S: SimState) -> void:
	var R = S.horde
	R.wave += 1
	var row: Dictionary = _c().waves[R.wave - 1]
	var m: float = float(_c().two.countMul) if pads(S) >= 2 else 1.0
	R.mix = PackedInt32Array([int(floor(float(row.fodder) * m + 0.5)), int(floor(float(row.bruiser) * m + 0.5)), int(floor(float(row.speedster) * m + 0.5))])
	R.up = _left(R)
	for i in range(SimHorde.places):
		var f = S.fighters[SimHorde.seats + i]
		if f.out:
			f.hd.t = S.tick + i * SimHorde.staggerTicks
	SimFx.cue(S, null, "horde_wave", str(R.wave), str(R.up))


## An away place comes in: the kind by a keyed draw over what the wave has left, the side by another, made fresh 40 bh from its mark.
static func _refill(S: SimState, k: int) -> void:
	var R = S.horde
	var f = S.fighters[k]
	var r: float = SimRng.keyed(int(S.game.seed), "horde.kind", R.sent) * float(_left(R))
	var kind: int = 3
	var acc: float = 0.0
	for i in range(3):
		acc += float(R.mix[i])
		if r < acc:
			kind = i + 1
			break
	R.mix[kind - 1] -= 1
	var side: float = -1.0 if SimRng.keyed(int(S.game.seed), "horde.side", R.sent) < 0.5 else 1.0
	var p: int = _markFor(S)
	var P = S.fighters[p]
	var c: Dictionary = SimHorde.packCfg(kind)
	SimHorde.fresh(S, k, String(c.fighter), SimWrap.wrap(P.x + side * float(_c().respawn.spawnBh) * DirBands.BH), P.y)
	f.out = false
	SimHorde.clearBody(f.hd)
	f.hd.kind = kind
	f.hd.phase = 1
	f.hd.worth = float(c.worth) * (float(_c().pack.twoPlayers.toughMul) if pads(S) >= 2 else 1.0)   # with two players the pack is tougher (Game Design, 2026-11-15)
	f.face = -side
	R.mark[k] = p
	R.sent += 1
	_enter(S, f, P)
	SimFx.cue(S, f, "horde_arrive", SimHorde.KINDS[kind], String(P.keys))


## A place's mark when it arrives: the seated player with fewer pack bodies on them; on a tie, the one whose latest pack blow was due longest ago
## (three places over two seats always leave one with two: a tie to the lower slot kept the pack 2 to 1 on seat 0 for the whole run), then the lower slot.
static func _markFor(S: SimState) -> int:
	var best: int = 0
	var bn: int = 1 << 20
	var bd: int = 1 << 30
	for s in range(SimHorde.seats):
		var P = S.fighters[s]
		if P.out or P.hd.phase == 7:
			continue
		var n: int = 0
		for k in range(SimHorde.seats, S.fighters.size()):
			if not S.fighters[k].out and S.horde.mark[k] == s:
				n += 1
		if n < bn or (n == bn and P.hd.due < bd):
			bn = n
			bd = P.hd.due
			best = s
	return best


## Tests only (T2's stand-in for the blows): the body in slot k falls to a blow of weight w.
static func fell(S: SimState, k: int, w: int = 1) -> void:
	_fell(S, null, S.fighters[k], w)


## A pack body's toughness is spent: counted once. A light drops it where it stands (away at once); a medium sends it 1 bh; a heavy launches it
## for real, by the launch the knock-out's fallback uses (damage.gd ko). A sent body goes away when it lands, and is never picked or counted again.
static func _fell(S: SimState, A, M, w: int) -> void:
	var R = S.horde
	var k: int = S.fighters.find(M)
	if M.out or M.hd.phase == 6:
		return
	R.felled += 1
	R.up -= 1
	_spoil(S, M)
	if w <= 1 or A == null:
		_away(S, k, "dropped")
	elif w == 2:
		M.hd.phase = 6
		var r := SimState.Rush.new()
		r.px = SimWrap.wrap(M.x + A.face * float(_c().blow.sendBh.medium) * DirBands.BH)
		r.py = M.y
		r.pz = M.z
		r.end = S.T + 6.0 * SimConst.DT
		M.rush = r
		SimFx.cue(S, M, "horde_fall", "sent", SimHorde.KINDS[M.hd.kind])
	else:
		M.hd.phase = 6
		M.rush = null
		SimDir.doLaunch(S, A, M, {"ux": A.face * 0.9, "uy": 0.5}, SimPower.sendForce(S, A, 1800.0, "koFallback"))
		SimFx.cue(S, M, "horde_fall", "launched", SimHorde.KINDS[M.hd.kind])
	if R.up <= 0:
		_cleared(S)


## A place goes away: its wind-up spoiled, parked straight up, out; it refills after respawn.ticks while the wave has bodies to send.
static func _away(S: SimState, k: int, how: String) -> void:
	var f = S.fighters[k]
	_spoil(S, f)
	SimFx.cue(S, f, "horde_fall", how, SimHorde.KINDS[f.hd.kind])
	f.out = true
	f.hd.phase = 0
	f.hd.t = S.tick + int(_c().respawn.ticks)
	SimHorde.park(f)


## A winding body's blow is over (it came due, or was spoiled): its lane is free again after the gap.
static func _spoil(S: SimState, f) -> void:
	if f.hd.ln >= 0:
		S.horde.lane[S.horde.mark[S.fighters.find(f)] * SimHorde.places + f.hd.ln] = S.tick + gapTicks(S)
		f.hd.ln = -1
	f.hd.at = 0
	if f.hd.phase == 3:
		f.hd.phase = 2   # (back to the crowd; a blow that spoiled it sets the reel after)


## The wave's last body is down: the last wave ends the run; any other starts the breather.
static func _cleared(S: SimState) -> void:
	var R = S.horde
	if R.wave >= _c().waves.size():
		_end(S, 1)
		return
	R.rest = int(_c().rest.ticks)
	var back: float = float(_c().rest.backBody)
	for s in range(SimHorde.seats):
		var P = S.fighters[s]
		if P.out:
			continue
		if P.hd.phase == 7 and bool(_c().down.backAtWaveEnd):
			P.hd.phase = 2   # a downed partner gets up with down.backBody of the body
			P.hp = minf(P.maxhp, float(_c().down.backBody))
			SimFx.cue(S, P, "horde_up", "", "")
		elif back > 0.0:
			P.hp = minf(P.maxhp, P.hp + back)
	SimFx.cue(S, null, "horde_rest", str(R.wave), "")


## The run ends: 1 every wave cleared, 2 every player down, 3 the backstop.
static func _end(S: SimState, which: int) -> void:
	S.horde.over = which
	SimFx.cue(S, null, "horde_over", ["", "cleared", "down", "time"][which], "")


## The brawl's numbers, read where they live (interrupts.json brawl and bands.lunge; templates.json contact): no new number for the player's side.
static func _lead(w: int) -> int:
	var b: Dictionary = DirBrawl.cfg()
	return int(b.light.contactTicks) if w == 1 else (int(b.medium.windupTicks) if w == 2 else int(b.heavy.windupTicks))


static func _lungeCfg() -> Dictionary:
	return DirBands.data().lunge


static func _lungeWind(w: int) -> int:
	return int(_lungeCfg().windupTicks.light) if w == 1 else int(_lungeCfg().windupTicks.heavy)


static func _lungeSpeed(S: SimState) -> float:
	return maxf(float(_lungeCfg().speed), S.powerFlat if S.powerOn else 0.0)   # the faster of the lunge's and flat out (Game Design, 14 November ruling 1)


## The lunge's reach: its most ticks at its speed (1,333 units at base).
static func lungeReach(S: SimState) -> float:
	return _lungeSpeed(S) * float(_lungeCfg().maxTicks) * SimConst.DT


static func _offset() -> float:
	return float(DirData.contact().offset)


static func _worth(w: int) -> float:
	return float(_c().blow.worth[WEIGHT[w]])


## DirExchange._request, after the Driver's line: a seat's press is a pack blow, never a request. True when the horde took it.
static func takes(S: SimState, A, kind: String) -> bool:
	if not S.hordeOn:
		return false
	var h = A.hd
	if h.kind != 0:
		return true   # a pack body never asks for an exchange
	var big: bool = DirBrawl.isB(A, kind)   # B with no stance held is the heavy
	if kind != "sig" and A.act.mode == 1:
		if not DirBlast.press(S, A, DirExchange.KIND.find(kind)):   # RB with X or Y: the blast's own press; it starts no exchange
			DirExchange.refused(S, A, DirExchange.cantWhy(S, A))
		return true
	if kind == "sig" and not big:
		DirExchange.refused(S, A, "horde_sig")   # the beam is refused in the trial, said (A3's beam in space replaces this)
		return true
	if A.state != "free":
		DirExchange.refused(S, A, DirExchange.cantWhy(S, A))
		return true
	var w: int = 3 if big else (2 if kind == "heavy" else 1)   # X light; Y (the request "heavy") the brawl's medium; B the heavy
	if h.at != 0:
		h.buf = w   # a blow is on its way: this press is kept, one deep (a second replaces it)
		return true
	_throw(S, A, w)
	return true


static func _throw(S: SimState, A, w: int) -> void:
	var k: int = _pick(S, A)
	if k < 0:
		SimFx.cue(S, A, "horde_blow", "air", "")   # nobody inside the lunge's reach: a swing at the air, said
		return
	S.horde.mark[S.fighters.find(A)] = k
	var M = S.fighters[k]
	var d: float = DirBands.dist(A, M)
	var lead: int = _lead(w)
	A.hd.t = S.tick   # in reach: the step in at once, following the body, timed to land on the weight's own tick (a circling body moves 560 units in a medium's 12)
	if d > _offset() * 1.5:
		var fl: int = clampi(int(ceil(d / (_lungeSpeed(S) * SimConst.DT))), int(_lungeCfg().minTicks), int(_lungeCfg().maxTicks))
		A.hd.t = S.tick + _lungeWind(w)   # the lunge's wind-up, then the flight (_fly)
		lead = _lungeWind(w) + fl
	A.hd.at = S.tick + lead
	A.hd.w = w
	SimFx.cue(S, A, "horde_blow", "start", String(M.keys))


## The lunge's flight: a rush to beside its mark, on the side it came from, timed to land on the blow's tick.
static func _fly(S: SimState, A) -> void:
	var h = A.hd
	h.t = 0
	var M = DirBrawl.rivalOf(S, A)
	if M.out or M.hd.phase == 6:
		return
	var r := SimState.Rush.new()
	r.tgt = M
	r.off = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(M.x, A.x)), -A.face) * _offset()
	r.end = S.T + float(maxi(1, h.at - S.tick)) * SimConst.DT
	A.rush = r
	A.vx = 0.0
	A.vy = 0.0


## The nearest body of the pack inside the lunge's reach, on the stick's side when the stick is held.
static func _pick(S: SimState, A) -> int:
	var best: int = -1
	var bd: float = INF
	var r: float = lungeReach(S)
	for k in range(SimHorde.seats, S.fighters.size()):
		var M = S.fighters[k]
		if M.out or M.hd.phase == 6:
			continue   # an away place, or a body already sent flying
		var d: float = DirBands.dist(A, M)
		if d > r:
			continue
		if absf(A.heldMx) > 0.5 and SimWrap.sdx(A.x, M.x) * A.heldMx < 0.0:
			d += r   # behind the stick: only when nobody is on the stick's side
		if d < bd:
			bd = d
			best = k
	return best


## A player's pack blow lands.
static func _land(S: SimState, A) -> void:
	var h = A.hd
	var M = DirBrawl.rivalOf(S, A)   # the mark
	var w: int = h.w
	h.at = 0
	h.t = 0
	A.rush = null
	var tol: float = maxf(float(DirData.contact().reach), _offset() * 1.5) + SimDetMath.hypot(M.vx, M.vy) * SimConst.DT   # (a seat steps before the pack: its step-in ends where the body was, and the body has moved one tick since)
	if M.out or M.hd.kind == 0 or M.hd.phase == 6 or DirBands.dist(A, M) > tol:
		SimFx.cue(S, A, "horde_blow", "whiff", "")
	else:
		A.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(A.x, M.x)), A.face)
		SimDamage.hit(S, null, A, M, float(DirBrawl.cfg().light.damage) * _worth(w), {"kind": WEIGHT[w], "weight": WEIGHT[w], "region": "core"})
		_spoil(S, M)   # any blow spoils its wind-up
		M.hd.worth -= _worth(w)
		if M.hd.worth <= 0.0:
			_fell(S, A, M, w)
		else:
			M.hd.phase = 5
			M.hd.t = S.tick + int(_c().hold[WEIGHT[w]]) + int(_c().play.reelTicks)
			M.vx = 0.0
			M.vy = 0.0
			M.rush = null
	if h.buf != 0:   # the kept press: the string's next
		var nw: int = h.buf
		h.buf = 0
		_throw(S, A, nw)


## Every mark names a body in the fight, or the first slot of the other side. A seat's moves to the nearest body in the fight only when its body
## falls; a place's when its player goes down or leaves, or flies past the leash, never during its own wind-up.
static func _marks(S: SimState) -> void:
	var R = S.horde
	for k in range(S.fighters.size()):
		var f = S.fighters[k]
		if f.out:
			continue
		var M = S.fighters[R.mark[k]]
		if f.hd.kind == 0:
			if M.out or M.hd.phase == 6:
				R.mark[k] = _nearestPack(S, f)
		elif f.hd.phase != 3 and (M.out or M.hd.phase == 7):
			R.mark[k] = _markFor(S)
		elif f.hd.phase != 3 and DirBands.dist(f, M) > float(_c().play.leashBh) * DirBands.BH:
			R.mark[k] = _nearestSeat(S, f, R.mark[k])   # past the leash: the nearer seat that is up (by count it could pick the farther, and flip back the next tick: the body hung between two seats far apart)


## The nearest seat that is up to f, or `keep` when none is nearer than it.
static func _nearestSeat(S: SimState, f, keep: int) -> int:
	var best: int = keep
	var bd: float = DirBands.dist(f, S.fighters[keep]) if not S.fighters[keep].out and S.fighters[keep].hd.phase != 7 else INF
	for s in range(SimHorde.seats):
		var P = S.fighters[s]
		if P.out or P.hd.phase == 7:
			continue
		var d: float = DirBands.dist(f, P)
		if d < bd:
			bd = d
			best = s
	return best


static func _nearestPack(S: SimState, f) -> int:
	var best: int = SimHorde.seats
	var bd: float = INF
	for k in range(SimHorde.seats, S.fighters.size()):
		var M = S.fighters[k]
		if M.out or M.hd.phase == 6:
			continue
		var d: float = DirBands.dist(f, M)
		if d < bd:
			bd = d
			best = k
	return best


## The match's one level (DirAI.level, else ai.json's), read for the lanes and the gap only. Tells never shorten with it.
static func level() -> String:
	var lv: String = DirAI.level if DirAI.level != "" else String(DirAI.skill().level)
	return lv if _c().play.perPlayer.has(lv) else "medium"


static func perPlayer() -> int:
	return int(_c().play.perPlayer[level()])


static func gapTicks(S: SimState) -> int:
	var g: int = int(_c().play.gapTicks[level()])
	return int(round(float(g) * float(_c().pack.twoPlayers.gapMul))) if pads(S) >= 2 else g   # with two players the gap is shorter: 90 at medium (Game Design, 2026-11-15)


static func blockTicks() -> int:
	return int(DirInterrupt.data().perfectBlock.windows.blow)   # the game's window for a blow (8)


const CIRCLE_RATE: float = 1.5   # radians a second: never standing still (a turn in about four seconds)


static func _crowdR() -> float:
	return 0.5 * (float(_c().play.crowdBh[0]) + float(_c().play.crowdBh[1])) * DirBands.BH   # across, the middle of 2 to 4 bh


static func _crowdY() -> float:
	return float(_c().play.crowdBh[0]) * DirBands.BH   # up and down, 2 bh


## A lane at seat P that is free now, or -1 (S.horde.lane holds, for each seat, `places` ticks: the tick a lane is free from, -1 while a wind-up holds it).
static func _lane(S: SimState, P) -> int:
	var b: int = S.fighters.find(P) * SimHorde.places
	for i in range(perPlayer()):
		if S.horde.lane[b + i] >= 0 and S.horde.lane[b + i] <= S.tick:
			return i
	return -1


static func _mayWind(S: SimState, f, P, d: float) -> bool:
	return not P.out and P.hd.phase == 2 and S.tick >= f.hd.ready and d <= float(_c().play.seenBh) * DirBands.BH


## The entrance: a rush straight at its mark at respawn.speedMul of flat-out flight, ending 4 bh out on its own side (16 ticks from 40 bh at 3,500).
static func _enter(S: SimState, f, P) -> void:
	var outer: float = float(_c().play.crowdBh[1]) * DirBands.BH
	var d: float = maxf(0.0, DirBands.dist(f, P) - outer)
	var sp: float = float(_c().respawn.speedMul) * SimFighter.flightSpeed(S, f, true)
	var r := SimState.Rush.new()
	r.tgt = P
	r.off = SimMathx.jsign(SimWrap.sdx(P.x, f.x)) * outer
	r.end = S.T + float(maxi(1, int(ceil(d / (sp * SimConst.DT))))) * SimConst.DT
	f.rush = r


## A pack body's blow comes due.
static func _strike(S: SimState, f) -> void:
	var P = DirBrawl.rivalOf(S, f)   # its mark: a seat
	_spoil(S, f)
	f.hd.phase = 4
	f.hd.t = S.tick + int(_c().play.openTicks)
	var c: Dictionary = SimHorde.packCfg(f.hd.kind)
	if P.out or P.hd.kind != 0 or P.hd.phase == 7:
		SimFx.cue(S, f, "horde_pack", "miss", String(P.keys))
		return
	var dodged: bool = S.tick - P.act.dodgeTick < SimAct.dodgeWindow and P.hd.dgOk == 1   # a clean tap only
	if DirBands.dist(f, P) > float(c.blow.reachBh) * DirBands.BH or dodged:
		SimFx.cue(S, f, "horde_pack", "dodged" if dodged else "miss", String(P.keys))
		return
	var guard: bool = P.act.guardSince >= 0
	if guard and S.tick - P.act.guardSince <= blockTicks() and S.tick >= DirInterrupt.gi(P, DirInterrupt.PB_LOCK):   # the game's window for a blow and its lockout
		SimFx.cue(S, P, "horde_pack", "blocked", String(f.keys))
		if f.hd.kind == 1:
			_fell(S, P, f, 1)   # the strong block: fodder falls
		else:
			f.hd.phase = 5   # a grunt reels
			f.hd.t = S.tick + int(_c().play.perfectReelTicks)
		return
	var last: bool = P.hp <= 0.0 or P.brink   # on their last legs before this blow
	var key: int = S.horde.t * SimHorde.places + (S.fighters.find(f) - SimHorde.seats)   # one blow a place a tick at most, so no two draws share a key
	var region: String = SimWounds.REGIONS[int(SimRng.keyed(int(S.game.seed), "horde.region", key) * 4.0) % 4]
	SimDamage.hit(S, null, f, P, float(c.blow.damage), {"kind": "light", "weight": "light", "region": region})   # the ordinary hit, stance rule and all
	if guard:
		f.hd.t += int(c.guarded.reboundTicks)
		SimFx.cue(S, P, "horde_pack", "guarded", String(f.keys))
		return
	P.hd.taken += 1
	P.hd.at = 0   # the flinch: the blow the player was throwing is spoiled. No stun, no gate
	P.hd.t = 0
	P.rush = null
	var nb: int = P.hd.buf
	P.hd.buf = 0
	SimFx.cue(S, P, "horde_pack", "hit", String(f.keys))
	if last and bool(_c().down.onLastBlow):
		_down(S, P)
	elif nb != 0:
		_throw(S, P, nb)   # their next press is untouched: a press kept behind the spoiled blow is thrown now, never lost unsaid


## A seat goes down: not launched, not away; its blow and kept press dropped, every wind-up at it spoiled. With no pad's seat still up, the run ends.
static func _down(S: SimState, P) -> void:
	var h = P.hd
	h.phase = 7
	h.downs += 1
	h.at = 0
	h.buf = 0
	h.t = 0
	P.rush = null
	var p: int = S.fighters.find(P)
	for k in range(SimHorde.seats, S.fighters.size()):
		var f = S.fighters[k]
		if not f.out and S.horde.mark[k] == p and f.hd.phase == 3:
			_spoil(S, f)
	SimFx.cue(S, P, "horde_down", "", "")
	for s in range(SimHorde.seats):
		var Q = S.fighters[s]
		if Q.ai == null and not Q.out and Q.hd.phase != 7:
			return
	_end(S, 2)


## DirAI.aiInput's first question: in a horde match the opponent's computer is never used. A pack body's own play; an empty seat presses nothing.
static func aiInput(S: SimState, f, i) -> bool:
	if not S.hordeOn:
		return false
	var h = f.hd
	if f.out or h.kind == 0 or h.phase == 1 or h.phase >= 4 or S.horde.over != 0:
		return true   # away, an empty seat, arriving (its entrance flies it), open, reeling or sent, or the run is over: nothing is pressed
	var P = DirBrawl.rivalOf(S, f)
	var c: Dictionary = SimHorde.packCfg(h.kind)
	var sm: float = float(c.speedMul)
	var dx: float = SimWrap.sdx(f.x, P.x)
	var dy: float = P.y - f.y
	var d: float = DirBands.dist(f, P)
	i.dash = true
	if h.phase == 3:   # winding up: the step in, straight at the mark, to inside its reach
		if d > float(c.blow.reachBh) * DirBands.BH * 0.6:
			i.mx = SimMathx.jsign(dx) * sm
			i.my = clampf(dy / 200.0, -1.0, 1.0) * sm
		return true
	# in the fight: circle the mark, a third of a turn apart by place, at its own flying speed
	var ph: float = S.T * CIRCLE_RATE + 6.283185307179586 * float(S.fighters.find(f) - SimHorde.seats) / float(SimHorde.places)
	var cx: float = SimWrap.sdx(f.x, P.x + _crowdR() * SimDetMath.sin(ph))
	var cy: float = P.y + _crowdY() * SimDetMath.cos(ph) - f.y
	i.mx = SimMathx.jsign(cx) * sm if absf(cx) > 20.0 else 0.0
	i.my = SimMathx.jsign(cy) * sm if absf(cy) > 20.0 else 0.0
	var ln: int = _lane(S, P) if _mayWind(S, f, P, d) else -1
	if ln >= 0:
		h.phase = 3
		h.ln = ln
		var p: int = S.fighters.find(P)
		S.horde.lane[p * SimHorde.places + ln] = -1   # the lane is taken until this blow is over
		var behind: bool = dx * P.face > 0.0   # the mark faces away from this body
		var wu: int = maxi(int(c.blow.windup), int(_c().play.behindWindupMin) if behind else 0)
		h.at = maxi(S.tick + wu, P.hd.due + int(_c().play.spacingTicks))   # never within the spacing of another pack blow on this player
		P.hd.due = h.at
		SimFx.cue(S, f, "horde_wind", String(P.keys), "behind" if behind else "")
	return true
