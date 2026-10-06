class_name DirZip
extends RefCounted
## The zip, slice Z1 (docs/design/melee-press-feel.md section 2c; docs/director/brawl-plan.md sections 7 and 7.10).
## LT with X or Y in the mid band: he pays at the press, holds a tell, goes in, strikes once and comes out again.
##  - The tell and the way in run with no exchange. The rival stays free: he can move, guard, fire, or press an
##    answer where he stands (takes). A shot stops a zip strike on the way in; a zip heavy shrugs off a weak one.
##  - The ticks in reach run inside the brawl's lines with no brawl announced (DirBrawl.beginQuiet, ex.tag "ZIP"):
##    his one blow is a brawl strike beat with `zip`, so the guard, the perfect block and its riposte, the damage and
##    the beat Animation reads are the brawl's own. He has no guard there, and his presses are spent.
##  - A blow of the rival's that lands on him there catches him: the brawl is announced and goes on. A well-timed
##    answer cancels his blow: a heavy knocks him back, a tech strike staggers him and the brawl goes on.
##  - Otherwise he leaves reachAfter ticks after his blow, to the exit the stick picked on the tick it landed: back
##    to where he started with no stick, else the stick's bearing round the rival at Game Design's distance. The way
##    out is a rush, bowed over the rival or the ground when the straight line would cross them. No strike reaches
##    him on it; a shot drops him.
## The read (read) is the truth for the body; the cues are edges: zip_light / zip_heavy, zip_out, zip_end.
## State: integers after DirBrawl's, per fighter. Nothing shared.

const BH: float = 75.0
const LT: int = 8               # the stance mask's LT bit (docs/controls/lunge-control.md B6.1)
const FX: float = 16.0          # positions are kept as integers, sixteenths of a unit

const BASE: int = DirBrawl.END
const PH: int = BASE            # 0 none, 1 the tell, 2 the way in, 3 in reach, 4 the way out
const LEFT: int = BASE + 1      # live ticks left in the phase (in reach: left after his blow)
const LEN: int = BASE + 2       # the phase's length in live ticks
const KIND: int = BASE + 3      # 1 the zip strike, 2 the zip heavy
const READ: int = BASE + 4      # the reading: 0 speed, 1 tech, 2 heavy (held)
const PRESS: int = BASE + 5     # S.tick of the press that began it
const TELL: int = BASE + 6      # the plan, in ticks: the tell, ...
const WAYIN: int = BASE + 7     # ... the way in, ...
const RB: int = BASE + 8        # ... in reach before his blow, ...
const RA: int = BASE + 9        # ... in reach after it, ...
const WAYOUT: int = BASE + 10   # ... and the way out (the default until his blow lands, then the real one)
const X0: int = BASE + 11       # where he started (sixteenths)
const Y0: int = BASE + 12
const D0: int = BASE + 13       # his distance from the rival then (sixteenths)
const SIDE: int = BASE + 14     # the side of the rival he started on: 1 his right, -1 his left
const EXIT: int = BASE + 15     # 0 not known yet, 1 home, 2 far, 3 point
const EX_X: int = BASE + 16     # the exit point (sixteenths), once known
const EX_Y: int = BASE + 17
const PASS: int = BASE + 18     # the way out: 0 straight, 1 over (a bow), 2 round (straight past the rival at his height), 3 under (a bow beneath him)
const STATE: int = BASE + 19    # in reach: 0 his blow is to come, 1 it is resolved and he leaves, 2 he is caught or countered, 3 his blow is cancelled and the counter is on its way
const ARR: int = BASE + 20      # S.tick he arrived (the counter's mark)
const HOLD: int = BASE + 21     # the tell: 1 while the held reading's extra ticks run
const ANS_W: int = BASE + 22    # on the rival of a zipper: the answer he pressed before the arrival, 0 none, 1 a light, 2 a heavy
const ANS_AT: int = BASE + 23   # ... and the S.tick of that press
const ARR_L: int = BASE + 24   # the live tick he arrived (the read counts live ticks)
const ANS_LAST: int = BASE + 25  # on the rival: the S.tick of his last attack press since the zip began (a press soon after another is a mash)
const ANS_MASH: int = BASE + 26  # ... 1 when the answer he pressed before the arrival was one of a mash
const AI_ANS: int = BASE + 27    # on the AI rival of a zipper: its answer, 0 none, 1 guard, 2 dodge, 3 a light (the tech counter), 4 a heavy, 9 spent
const AI_AT: int = BASE + 28     # ... and the S.tick it acts
const AI_EXIT: int = BASE + 29   # the AI zipper's exit: 0 back, 1 the far side, 2 above, 3 away
const RING: int = BASE + 30     # SimAim's sample ring for the exit: 37 integers
const RING_N: int = 37
const END: int = RING + RING_N

const PHASES: Array = ["", "tell", "in", "reach", "out"]
const READS: Array = ["speed", "tech", "heavy"]
const EXITS: Array = ["", "home", "far", "point"]
const PASSES: Array = ["", "over", "round", "under"]


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("zip", {})


static func on() -> bool:
	return DirBrawl.on() and cfg().get("enabled", false)


static func _size(f) -> void:
	DirBrawl._size(f)
	if f.act.dirI.size() < END:
		f.act.dirI.resize(END)


static func _g(f, k: int) -> int:
	_size(f)
	return f.act.dirI[k]


static func _s(f, k: int, v: int) -> void:
	_size(f)
	f.act.dirI[k] = v


static func _cue(S: SimState, f, name: String, text: String = ""):
	SimFx.cue(S, f, name, text, "")
	return S.out.fx[S.out.fx.size() - 1]


## True while f is zipping, from his press to the end of his way out (or to the catch).
static func zipping(f) -> bool:
	return _g(f, PH) != 0


## True on his way out: no strike reaches him there.
static func untouchable(f) -> bool:
	return _g(f, PH) == 4


## The fighter whose zip is aimed at d and has not arrived yet, or null.
static func aimedAt(S: SimState, d):
	for f in S.fighters:
		if f != d and (_g(f, PH) == 1 or _g(f, PH) == 2):
			return f
	return null


## The zip's own exchange: the ticks in reach before anybody is caught.
static func _mine(S: SimState, f) -> bool:
	var ex = S.dirS.ex
	return ex != null and DirBrawl.quiet(ex) and ex.A == f


# ---------------------------------------------------------------- a press

## An attack press (DirExchange.requestAttack, after the brawl's). True when the zip took it.
##  - A zipper's own press is spent (a second zip pressed inside the first comes with the chains).
##  - The rival of a zipper who has not arrived presses his answer where he stands: it is kept for the arrival, and
##    never starts a lunge of his own. The energy family is not kept: his shot is his answer.
##  - LT held in the mid band, free to act, with the ki: the zip starts. Without the ki the press is the plain lunge.
static func takes(S: SimState, A, kind: String) -> bool:
	if not on() or kind == "sig":
		return false
	if zipping(A):
		_cue(S, A, "press_ack", "zip").n = S.tick
		return true
	var Z = aimedAt(S, A)
	if Z != null:
		if A.act.mode == 1 or A.state != "free" or A.stunTicks > 0:
			return false
		var w: int = 2 if kind == "heavy" else 1
		if w == 2 and A.ki < float(DirBrawl.cfg().heavy.ki):
			w = 1
		if w == 2 and _g(A, ANS_W) != 2:
			A.ki -= float(DirBrawl.cfg().heavy.ki)   # a heavy is paid for as it is pressed, as in a brawl
		var pp: int = S.tick - DirBrawl._waited(A)
		var mash: bool = _g(A, ANS_LAST) > 0 and pp - _g(A, ANS_LAST) <= int(DirBrawl.cfg().flurry.maxGap)
		_s(A, ANS_LAST, pp)
		if w >= _g(A, ANS_W):
			_s(A, ANS_W, w)
			_s(A, ANS_AT, pp)
			_s(A, ANS_MASH, 1 if mash else 0)
		_cue(S, A, "press_ack", "answer").n = S.tick
		return true
	if (A.input.stanceMask & LT) == 0:
		return false
	var D = SimRoster.opp(S, A)
	var c: Dictionary = cfg()
	var d: float = DirBands.dist(A, D) / BH
	if d < float(c.band.minBh) or d > float(c.band.maxBh):
		return false   # in reach the same buttons are the step strike and its family; further out, the piloted charge
	if S.dirS.ex != null or S.game.ko != null or (A.state != "free" and A.state != "charging") or A.stunTicks > 0 or DirBands.pending(A) \
			or D.hidden or D.state == "launched" or D.state == "down" or D.state == "dropped" or zipping(D) or DirBury.safe(S, D):
		_cue(S, A, "press_ack", "zip_refused").n = S.tick
		return true
	var heavy: bool = kind == "heavy"
	if A.ki < float((c.heavy if heavy else c.strike).ki):
		_cue(S, A, "press_ack", "zip_no_ki").n = S.tick
		return false
	start(S, A, D, heavy, S.tick - DirBrawl._waited(A))
	return true


## The zip starts: the price is paid, and the tell begins where he stands.
static func start(S: SimState, A, D, heavy: bool, p: int) -> void:
	var c: Dictionary = cfg()
	var k: Dictionary = c.heavy if heavy else c.strike
	_size(A)
	for i in range(PH, END):
		if i != ANS_W and i != ANS_AT and i != AI_EXIT:
			A.act.dirI[i] = 0
	A.ki -= float(k.ki)
	var d: float = DirBands.dist(A, D)
	_s(A, KIND, 2 if heavy else 1)
	_s(A, PRESS, p)
	_s(A, TELL, int(k.tellTicks))
	# Pressed inside the rival's own tell (his lunge or charge is on its way), it is the tech reading from here: he flies
	# in on the floor, and the rival's blow misses (his approach is dropped as the zip arrives).
	var read0: bool = DirBands.pending(D)
	_s(A, READ, 1 if read0 else 0)
	_s(A, WAYIN, _inTicks(k, d / BH, read0))
	_s(A, RB, int(k.reachBefore))
	_s(A, RA, int(k.reachAfter))
	_s(A, WAYOUT, int(k.outTicks))
	_s(A, X0, roundi(A.x * FX))
	_s(A, Y0, roundi(A.y * FX))
	_s(A, D0, roundi(d * FX))
	_s(A, SIDE, 1 if SimWrap.sdx(D.x, A.x) >= 0.0 else -1)
	_s(A, PH, 1)
	_s(A, LEN, int(k.tellTicks))
	_s(A, LEFT, int(k.tellTicks))
	_s(D, ANS_W, 0)
	_s(D, ANS_LAST, 0)
	DirBands.endTaunt(S, A, false, "cut")
	# The dodge that becomes a zip (Controls B6.3): LT's press was a dodge at once. A face press soon after, when he was
	# not threatened, takes the dodge back: the zip starts from where he stands.
	if S.tick - A.act.dodgeTick <= int(c.dodgeConvertTicks) and not _threatened(S, A, D):
		A.act.dodgeTick = -1000000
	A.state = "free"
	A.hideT = 0.0
	A.rush = null
	A.breathT = S.T   # an attack of his own, from its tell: his second breath waits again (as DirBands.begin)
	A.vx = 0.0
	A.vy = 0.0
	A.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(A.x, D.x)), A.face)
	var e = _cue(S, A, "zip_heavy" if heavy else "zip_light", "zip")
	e.target = float(S.fighters.find(D))
	e.amount = float(int(k.tellTicks))
	e.n = _g(A, WAYIN)
	e.dur = float(int(k.tellTicks) + _g(A, WAYIN) + int(k.reachBefore) + int(k.reachAfter) + int(k.outTicks))
	e.x = float(int(k.reachBefore))   # the ticks in reach before his blow and after it, as planned (the speed reading's)
	e.y = float(int(k.reachAfter))
	SimFx.rush(S, A, D, S.tick + int(k.tellTicks) + _g(A, WAYIN))
	seen(S, D, A, int(k.tellTicks) + _g(A, WAYIN))
	SimEvents.feed(S, A.name + (" ZIP HEAVY" if heavy else " ZIP STRIKE"), SimMathx.jstr(SimMathx.jround(d / BH)) + " bh; " + SimMathx.jstr(float(k.ki)) + " ki; a tell of " + str(int(k.tellTicks)) + " ticks, then " + str(_g(A, WAYIN)) + " in")


## He was threatened when he pressed LT: an approach or a shot was coming at him, or he was just hit.
static func _threatened(S: SimState, f, o) -> bool:
	return DirBands.pending(o) or zipping(o) or DirBlast.incoming(S, f) or S.tick - DirInterrupt.gi(f, DirInterrupt.HIT_AT) <= int(DirInterrupt.data().burst.threatTicks)


## The ticks of the way in: the table's range by distance, never under Legal's floor (max(floor.minTicks, the
## distance in bh over floor.bhPerTick, rounded up)). A tech zip flies in on the floor.
static func _inTicks(k: Dictionary, dBh: float, tech: bool) -> int:
	var c: Dictionary = cfg()
	var fl: int = _floor(dBh)
	if tech:
		return fl
	var lo: int = int(k.inTicks[0])
	var hi: int = int(k.inTicks[1])
	var t: float = clampf((dBh - float(c.band.minBh)) / maxf(0.001, float(c.band.maxBh) - float(c.band.minBh)), 0.0, 1.0)
	return maxi(lo + roundi(t * float(hi - lo)), fl)


## Legal's floor on travel (RL-076), for a path of dBh body heights.
static func _floor(dBh: float) -> int:
	var c: Dictionary = cfg()
	return maxi(int(c.floor.minTicks), int(ceil(dBh / float(c.floor.bhPerTick))))


# ---------------------------------------------------------------- once a live tick

## Before the exchange's beats (DirExchange.dirUpdate, after the approaches).
static func tick(S: SimState) -> void:
	if not on():
		return
	for f in S.fighters:
		var ph: int = _g(f, PH)
		if ph == 0:
			continue
		_feed(f)
		if ph == 1:
			_tell(S, f)
		elif ph == 2:
			_wayIn(S, f)
		elif ph == 3:
			_reach(S, f)
		else:
			_wayOut(S, f)


## The stick, once a live tick, into the exit's ring (SimAim: the direction held for 3 of the last 12 ticks wins).
static func _feed(f) -> void:
	var ring: Array = []
	ring.resize(RING_N)
	for i in range(RING_N):
		ring[i] = f.act.dirI[RING + i]
	SimAim.push_sample(ring, f.input.mx, f.input.my)
	for i in range(RING_N):
		f.act.dirI[RING + i] = int(ring[i])


static func _ring(f) -> Array:
	var ring: Array = []
	ring.resize(RING_N)
	for i in range(RING_N):
		ring[i] = _g(f, RING + i)
	return ring


## The tell: he holds still. With his button kept down past it the held reading's extra ticks run: let go early, he
## goes at once in the speed reading; held through them, it is the held reading.
static func _tell(S: SimState, f) -> void:
	var c: Dictionary = cfg()
	var D = SimRoster.opp(S, f)
	if S.game.ko != null or S.dirS.ex != null or f.state != "free" or f.stunTicks > 0:
		_end(S, f, "stopped")
		return
	f.vx = 0.0
	f.vy = 0.0
	f.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(f.x, D.x)), f.face)
	var heavy: bool = _g(f, KIND) == 2
	var k: Dictionary = c.heavy if heavy else c.strike
	var down: bool = f.input.heavyHeld if heavy else f.input.lightHeld
	var left: int = _g(f, LEFT) - 1
	if _g(f, HOLD) == 1 and not down:
		left = 0   # let go inside the extra ticks: he goes now, in the speed reading
		_s(f, HOLD, 0)
		_s(f, TELL, _g(f, LEN) - _g(f, LEFT) + 1)
		_s(f, LEN, _g(f, TELL))
	elif left <= 0 and _g(f, HOLD) == 0 and down and _g(f, READ) == 0:
		_s(f, HOLD, 1)
		left = int(k.heldTicks)
		_s(f, LEN, _g(f, LEN) + left)
		_s(f, TELL, _g(f, LEN))
	elif left <= 0 and _g(f, HOLD) == 1:
		_s(f, HOLD, 0)
		_s(f, READ, 2)
		if not heavy:
			_s(f, RB, int(k.heldReachBefore))
	_s(f, LEFT, left)
	if left > 0:
		return
	# The way in. A starter pressed on the beat of a blow is the tech reading from here: it flies in on the floor.
	if _g(f, READ) == 0 and _zipRead(S, f, SimPressRead.NO_BEAT) == "tech":
		_s(f, READ, 1)
	var n: int = _inTicks(k, DirBands.dist(f, D) / BH, _g(f, READ) == 1)
	_s(f, WAYIN, n)
	_s(f, PH, 2)
	_s(f, LEN, n)
	_s(f, LEFT, n)
	# He flies to striking distance, on his own side: his blow needs no step when it comes.
	var r := SimState.Rush.new()
	r.tgt = D
	r.off = DirMelee.sideOff(f, D, float(DirData.contact().offset), "own")
	r.end = S.T + float(n) * SimConst.DT
	f.rush = r


## Controls' reading of the zip's presses: plain, speed, tech or heavy.
static func _zipRead(S: SimState, f, arrival: int) -> String:
	return SimPressRead.zip_read(DirAlchemy.logOf(f), S.tick, _g(f, PRESS), arrival)


## The way in: his end point follows the rival, as a lunge's does. Out of the mid band by its end, he is outrun.
static func _wayIn(S: SimState, f) -> void:
	var c: Dictionary = cfg()
	var D = SimRoster.opp(S, f)
	if S.game.ko != null or S.dirS.ex != null or f.state != "free" or f.stunTicks > 0 or (f.rush == null and _g(f, LEFT) > 2):
		_end(S, f, "stopped")   # (the rush itself ends a tick before the count does, as a lunge's does)
		return
	var left: int = _g(f, LEFT) - 1
	_s(f, LEFT, left)
	if left > 0 and f.rush != null:
		# Outrun: the rival has left the mid band, measured from where the zip began. (The rush itself always arrives.)
		if SimDetMath.hypot(SimWrap.sdx(float(_g(f, X0)) / FX, D.x), D.y - float(_g(f, Y0)) / FX) > float(c.band.maxBh) * BH or D.hidden:
			_end(S, f, "outrun")
			return
		var lead: float = D.vx * SimConst.DT if (S.fighters[0] == f and D.rush == null and D.state == "free") else 0.0
		var side: float = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(D.x, f.x)), SimMathx.jsign(f.rush.off))
		f.rush.off = side * maxf(float(DirData.contact().offset), float(DirData.contact().get("minSeparation", 45.0))) + lead
		return
	_arrive(S, f, D)


## He is at the rival: the ticks in reach begin. They run on the brawl's lines with no brawl announced. An answer the
## rival pressed before now is resolved against the arrival, which is the counter's mark.
static func _arrive(S: SimState, f, D) -> void:
	var c: Dictionary = cfg()
	var heavy: bool = _g(f, KIND) == 2
	f.rush = null
	if (D.state != "free" and D.state != "charging") or D.hidden or untouchable(D) or DirBands.dist(f, D) > float(DirBands.data().closeBh) * BH * 1.5:
		_end(S, f, "outrun")
		return
	if DirBands.pending(D):
		DirBands.drop(S, D, f.name + "'s zip arrives")
	var ex = DirExchange.startZip(S, f, D, "heavy" if heavy else "light")
	DirBrawl.beginQuiet(S, ex)
	_s(f, PH, 3)
	_s(f, STATE, 0)
	_s(f, ARR, S.tick)
	_s(f, ARR_L, DirBrawl._now(S))
	_s(f, LEN, _g(f, RB) + _g(f, RA))
	_s(f, LEFT, _g(f, RA))
	if _g(f, READ) == 0 and _zipRead(S, f, S.tick) == "tech":
		_s(f, READ, 1)   # a second press on the arrival: the tech blow, and the floor on the way out
	var bc: Dictionary = DirBrawl.cfg()
	var rd: int = _g(f, READ)
	var mul: float = float(c.mul[["speed", "tech", "held"][rd]])
	var dmg: float = (float(bc.heavy.damage) * float(bc.heavyMul) if heavy else float(bc.light.damage) * float(bc.skillMul)) * float(bc.damageMul) * mul
	var rb: int = _g(f, RB)
	# The rival's answer, pressed where he stood before the arrival. A heavy that lands inside its window cancels the
	# zip's blow: it lands in full and knocks him back.
	var aw: int = _g(D, ANS_W)
	var at: int = _g(D, ANS_AT)
	_s(D, ANS_W, 0)
	var hdmg: float = float(bc.heavy.damage) * float(bc.damageMul) * float(bc.heavyMul)
	var mark: int = at + int(bc.heavy.windupTicks)   # a heavy is timed by the end of its wind-up
	var land: int = mark + int(bc.heavy.landTicks)
	var cancelled: bool = aw == 2 and mark >= S.tick - int(c.counter.heavyBefore) and mark <= S.tick + rb
	if cancelled:
		DirBrawl.blowAt(S, ex, D, DirBrawl.HEAVY, maxi(1, land - S.tick), hdmg, {"counter": "heavy", "sure": true, "ender": true})
	else:
		DirBrawl.blowAt(S, ex, f, DirBrawl.HEAVY if heavy else DirBrawl.LIGHT, rb, dmg, {"zip": true, "style": READS[rd], "read": rd})
		if aw == 1 and S.tick - at <= int(c.counter.techBefore):
			_s(D, ANS_LAST, at - 1 if _g(D, ANS_MASH) == 1 else 0)   # (markAnswer reads a press soon after another as a mash)
			DirBrawl._throw(S, D, SimAct.LIGHT, at, false, false)   # inside the window: markAnswer makes it the tech counter
		elif aw == 2 and mark > S.tick + rb:
			DirBrawl.blowAt(S, ex, D, DirBrawl.HEAVY, land - S.tick, hdmg, {})   # too late to counter: it lands after his blow, and catches him if he is still there
		elif aw == 2:
			# Too early: it met nothing, and he is in its recovery as the zip lands.
			DirBrawl._s(D, DirBrawl.FREE_AT, land + int(bc.heavy.recoverWhiff))
			SimEvents.feed(S, D.name + " TOO EARLY", "his heavy met nothing before the zip arrived")
	SimFx.attack(S, f, D, "heavy" if heavy else "light", DirExchange.STN[int(D.stance)], ex.tag, false)
	SimEvents.feed(S, f.name + " ZIP ARRIVES", "in reach; his blow lands in " + str(rb) + " ticks" + (" (cancelled by the answer)" if cancelled else ""))


## The rival's blow, pressed in the ticks in reach (DirBrawl._throw): a single light pressed from counter.techBefore
## ticks before the arrival until the zipper's blow lands is the tech counter. It is worth a skill strike times
## counter.mul. A flurry blow or a heavy pressed there is not a counter: landing on him, it catches him.
static func markAnswer(S: SimState, ex, f, kind: int, p: int, args: Dictionary) -> void:
	var z = ex.A
	var last: int = _g(f, ANS_LAST)
	_s(f, ANS_LAST, p)
	if last > 0 and p - last <= int(DirBrawl.cfg().flurry.maxGap):
		return   # one of a mash: a speed blow, which catches him and cancels nothing
	if kind != DirBrawl.LIGHT or _g(z, STATE) != 0 or DirBrawl._g(z, DirBrawl.LINE) != 1 or p < _g(z, ARR) - int(cfg().counter.techBefore):
		return
	var bc: Dictionary = DirBrawl.cfg()
	args["counter"] = "tech"
	args["sure"] = true
	DirBrawl._drop(S, ex, z)   # the zipper's blow is cancelled as the tech strike is pressed; he staggers when it lands
	_s(z, STATE, 3)
	args["dmg"] = float(bc.light.damage) * float(bc.damageMul) * float(bc.skillMul) * float(cfg().counter.mul)


## His blow is about to land (DirBrawl.contact). A second press within the classifier's beat of his own arrival makes it
## the tech blow: it is a timed strike, so he keeps the way in he flew and leaves on the floor.
static func beforeBlow(S: SimState, ex, f, a) -> void:
	if _g(f, READ) != 0 or _zipRead(S, f, _g(f, ARR)) != "tech":
		return
	var c: Dictionary = cfg()
	_s(f, READ, 1)
	a["dmg"] = float(a.dmg) * float(c.mul.tech) / float(c.mul.speed)
	a["style"] = "tech"
	a["read"] = 1


## In reach. His blow resolves in DirBrawl.contact (onBlow). After it he stays for reachAfter ticks, then leaves.
## If the exchange ended under him (the rival left, a knock-back, a set piece), he leaves at once when he can.
static func _reach(S: SimState, f) -> void:
	if _g(f, STATE) == 2:
		_s(f, PH, 0)   # caught or countered: he is in a brawl, and the zip is over
		return
	if not _mine(S, f):
		if S.game.ko == null and S.dirS.ex == null and f.state == "free" and f.stunTicks <= 0:
			if _g(f, EXIT) == 0:
				_pickExit(S, f, SimRoster.opp(S, f))
			_leave(S, f)
		else:
			_end(S, f, "stopped")
		return
	if _g(f, STATE) != 1:
		return
	var left: int = _g(f, LEFT) - 1
	_s(f, LEFT, left)
	var o = S.dirS.ex.D
	if left <= 0 and DirBrawl._g(o, DirBrawl.LINE) == 1 and DirBrawl._g(o, DirBrawl.CONTACT) <= DirBrawl._now(S) + 1:
		return   # a blow of the rival's lands on this last tick: it lands first
	if left <= 0:
		DirBrawl.end(S, S.dirS.ex, "zip")
		_leave(S, f)


## His blow resolved (DirBrawl.contact). how: 0 blocked, 1 landed, 2 turned by a perfect block.
##  - Landed, a zip strike reels the rival by its reading. A zip heavy staggers him by its reading; held, it knocks
##    him back, which is decisive.
##  - Blocked, a zip strike chips; a zip heavy staggers the blocker in place.
##  - Turned, he is countered: the blocker has his riposte, and the brawl goes on.
## The exit is read here, on the tick the blow lands.
static func onBlow(S: SimState, ex, f, o, a, how: int) -> void:
	var c: Dictionary = cfg()
	var bc: Dictionary = DirBrawl.cfg()
	if how == 2:
		_caught(S, ex, f, "countered")
		return
	var heavy: bool = _g(f, KIND) == 2
	var rd: int = _g(f, READ)
	_pickExit(S, f, o)
	_s(f, STATE, 1)
	_s(f, LEFT, _g(f, RA))
	if how == 0:
		if heavy:
			o.stunTicks = maxi(o.stunTicks, int(bc.heavy.staggerTicks))
			DirBrawl._drop(S, ex, o)
			var gb = _cue(S, o, "guard_break")
			gb.target = float(S.fighters.find(f))
			gb.n = int(bc.heavy.staggerTicks)
		return
	if not heavy:
		DirBrawl._reel(S, o, int(c.reel[["speed", "tech", "held"][rd]]))
		return
	if rd == 2:
		# The held zip heavy: a knock-back. The exchange ends with it, and he leaves from where he stands.
		DirMelee.launchBeat(S, ex, f, o, float(bc.heavy.force), false, null)
		if S.dirS.ex == ex and not DirBrawl._setPiece(ex):
			DirBrawl.end(S, ex, "zip")
		return
	var n: int = int(c.stagger["tech" if rd == 1 else "speed"])
	o.stunTicks = maxi(o.stunTicks, n)
	DirBrawl._drop(S, ex, o)
	var st = _cue(S, o, "stagger", "zip")
	st.target = float(S.fighters.find(f))
	st.n = n


## The rival's blow landed on him in reach (DirBrawl.contact). A counter (args.counter) cancels his blow: a heavy's
## knock-back follows from the blow itself; a tech strike staggers him counter.staggerTicks. Any other blow catches
## him: his own blow, if still to come, is thrown as his reel ends.
static func onHit(S: SimState, ex, z, by, a) -> void:
	var counter: String = String(a.get("counter", ""))
	if counter == "heavy" and _g(z, STATE) == 1:
		counter = ""   # his blow had landed: this one catches him
	if counter == "":
		if _g(z, STATE) == 0 and DirBrawl._g(z, DirBrawl.LINE) == 1:
			# His own blow is still to come: it is pushed back by his reel, and lands as a blow of the brawl.
			var reel: int = int(DirBrawl.cfg().flurry.reelTicks)
			for b in ex.beats:
				if not b.done and b.op == "strike" and b.args != null and b.args.get("zip", false):
					b.args.erase("zip")
					b.t += float(reel) / DirData.TICKS_PER_SEC
			DirBrawl._s(z, DirBrawl.CONTACT, DirBrawl._g(z, DirBrawl.CONTACT) + reel)
		_caught(S, ex, z, "caught")
		return
	DirBrawl._drop(S, ex, z)
	if counter == "heavy":
		_caught(S, ex, z, "countered", false)   # the knock-back follows from the blow itself (DirBrawl._heavyLanded)
		return
	if counter == "tech":
		var n: int = int(cfg().counter.staggerTicks)
		z.stunTicks = maxi(z.stunTicks, n)
		var st = _cue(S, z, "stagger", "counter")
		st.target = float(S.fighters.find(by))
		st.n = n
	_caught(S, ex, z, "countered")


## He is caught or countered: the zip is over where he stands, and the brawl is announced with the rival as its starter.
static func _caught(S: SimState, ex, z, why: String, brawl: bool = true) -> void:
	if _g(z, STATE) == 2:
		return
	_s(z, STATE, 2)
	_s(z, PH, 0)
	var e = _cue(S, z, "zip_end", why)
	e.target = float(S.fighters.find(ex.D))
	if brawl:
		DirBrawl.announce(S, ex, ex.D, why)
	SimEvents.feed(S, z.name + (" IS CAUGHT" if why == "caught" else " IS COUNTERED"), "the zip ends in reach" + (", and a brawl starts round him" if brawl else ": the heavy knocks him back"))


# ---------------------------------------------------------------- the exit

## The exit point, read on the tick his blow lands (melee-press-feel.md section 2c). No stick: back to where he
## started. Otherwise the stick's own bearing round the rival, at the start distance plus exit.awayBh times (1 - the
## angle off straight away over 90 degrees), capped at exit.capBh. A point inside the ground or a building slides
## round the circle toward his start bearing in exit.slideDeg steps, the shorter way and upward on a tie; with none
## clear he goes home. The way out bows over the rival, or the ground, when the straight line would cross them.
static func _pickExit(S: SimState, f, o) -> void:
	var c: Dictionary = cfg()
	var x0: float = float(_g(f, X0)) / FX
	var y0: float = float(_g(f, Y0)) / FX
	var d0: float = float(_g(f, D0)) / FX / BH
	var rd: Dictionary = SimAim.read_exit(_ring(f))
	var kind: int = 1
	var ex: float = x0
	var ey: float = y0
	var clear: float = float(c.exit.clearBh) * BH
	if int(rd.sector) != SimAim.NONE:
		var ang: int = SimAim.angle_off_away_deg(float(rd.x), float(rd.y), _g(f, SIDE))
		var dist: float = SimAim.exit_distance(d0, ang, float(c.exit.awayBh), float(c.exit.capBh)) * BH
		var b0: int = SimAim.bearing_deg(float(rd.x), float(rd.y))
		var home: int = SimAim.bearing_deg(SimWrap.sdx(o.x, x0), y0 - o.y)
		var diff: int = ((home - b0 + 540) % 360) - 180   # the shorter way round to his start bearing, -180 to 179
		var step: int = int(c.exit.slideDeg) * (1 if diff > 0 else -1)
		if diff == -180:
			step = int(c.exit.slideDeg) * (1 if b0 < 180 else -1) * (1 if b0 <= 90 or b0 >= 270 else -1)   # a tie: the way that passes over him
		kind = 2 if ang >= 180 - int(c.towardDeg) else 3
		var found: bool = false
		var b: int = b0
		for i in range(int(c.exit.probes)):
			var rad: float = float(b) * PI / 180.0
			ex = SimWrap.wrap(o.x + dist * SimDetMath.cos(rad))
			ey = o.y + dist * SimDetMath.sin(rad)
			if not WorldStructures.blockedAt(S, ex, ey + clear, 0.0, clear):   # on the ground is clear; under it, or within clearBh of a building, is not
				found = true
				break
			if absi(((home - b + 540) % 360) - 180) < int(c.exit.slideDeg):
				break   # round to his start bearing with nothing clear
			b = (b + step + 360) % 360
		if not found:
			kind = 1
			ex = x0
			ey = y0
	if kind == 1:
		ey = maxf(ey, WorldTerrain.groundY(S, ex))   # where he started may have been filled in since: he ends on it
	_s(f, EXIT, kind)
	_s(f, EX_X, roundi(ex * FX))
	_s(f, EX_Y, roundi(ey * FX))
	# The way out's ticks: the table's, growing with the path; a tech zip leaves on the floor. Never under the floor.
	var path: float = SimDetMath.hypot(SimWrap.sdx(f.x, ex), ey - f.y) / BH
	var n: int = _g(f, WAYOUT)
	if path > float(c.out.freeBh):
		n += int(ceil((path - float(c.out.freeBh)) / float(c.out.bhPerTick)))
	n = mini(n, int(c.out.maxTicks))
	if _g(f, READ) == 1:
		n = _floor(path)
	n = maxi(n, _floor(path))
	_s(f, WAYOUT, n)
	# Over, under or straight. The way out passes the rival when its straight line comes within three quarters of the
	# bow's height of him.
	var bx: float = SimWrap.sdx(f.x, ex)
	var by: float = ey - f.y
	var rx: float = SimWrap.sdx(f.x, o.x)
	var ry: float = o.y - f.y
	var u: float = clampf((rx * bx + ry * by) / maxf(1.0, bx * bx + by * by), 0.0, 1.0)
	var cross: bool = SimDetMath.hypot(rx - u * bx, ry - u * by) < 0.75 * float(c.bowBh) * BH and u > 0.0 and u < 1.0
	# It goes over him by default, and under him when the stick points down and there is bowBh of clear room beneath him.
	var under: bool = cross and int(rd.sector) != SimAim.NONE and int(rd.y) < -48 and not WorldStructures.blockedAt(S, o.x, o.y - float(c.bowBh) * BH, 0.0, 0.0)
	_s(f, PASS, (3 if under else 1) if cross else 0)
	var e = _cue(S, f, "zip_out", EXITS[kind])
	e.target = float(S.fighters.find(o))
	e.x = ex
	e.y = ey
	e.n = n
	e.amount = float(_g(f, RB))   # the ticks he was in reach before his blow, and stays after it; k is the reading (0 speed, 1 tech, 2 held)
	e.dur = float(_g(f, RA))
	e.k = float(_g(f, READ))


## The way out starts: a rush to the exit point. It bows over the rival for a far-side exit, and over the ground or a
## building when the straight line would cross one; the bow is raised until the path is clear, and with none clear
## he passes round at his own height (the rush itself is held by the ground).
static func _leave(S: SimState, f) -> void:
	var c: Dictionary = cfg()
	var ex: float = float(_g(f, EX_X)) / FX
	var ey: float = float(_g(f, EX_Y)) / FX
	var n: int = _g(f, WAYOUT)
	var r := SimState.Rush.new()
	r.px = ex
	r.py = ey
	r.pz = f.z
	r.end = S.T + float(n) * SimConst.DT
	f.state = "free"
	f.vx = 0.0
	f.vy = 0.0
	f.rush = r
	var up: float = 1.0 if SimWrap.sdx(f.x, ex) >= 0.0 else -1.0   # above 0 bows to the mover's left: up when he travels toward +x
	if absf(SimWrap.sdx(f.x, ex)) < 1.0:
		up = 1.0 if ey < f.y else -1.0   # a way out straight up or down: the bow goes to one side
	var bow: float = float(c.bowBh) * BH
	var pass_: int = _g(f, PASS)
	if pass_ == 3:
		up = -up   # under him
	var tries: Array = [0.0, 1.0, 2.0, 3.0] if pass_ == 0 else ([1.0] if pass_ == 3 else [1.0, 2.0, 3.0])
	var ok: bool = false
	for m in tries:
		r.arc = up * bow * float(m)
		ok = true
		for i in range(1, 8):
			var p: PackedFloat64Array = SimFighter.rushAt(S, f, float(i) / 8.0)
			if WorldStructures.blockedAt(S, p[0], p[1] + 0.5 * BH, 0.0, 0.0):   # his middle: a bump under his feet is no obstacle
				ok = false
				break
		if ok:
			if float(m) > 0.0 and pass_ != 3:
				pass_ = 1
			break
	if not ok:
		r.arc = 0.0
		pass_ = 2 if pass_ != 0 else 0
	_s(f, PASS, pass_)
	_s(f, PH, 4)
	_s(f, LEN, n)
	_s(f, LEFT, n)
	SimFx.rush(S, f, SimRoster.opp(S, f), S.tick + n)


## The way out. No strike reaches him (untouchable); a shot drops him (shot). He is done when he is there.
static func _wayOut(S: SimState, f) -> void:
	if S.game.ko != null or f.state != "free" or f.stunTicks > 0:
		_end(S, f, "stopped")
		return
	var left: int = _g(f, LEFT) - 1
	_s(f, LEFT, left)
	if left <= 0 or f.rush == null:
		_end(S, f, "done")


## The zip is over, and why: done, stopped, outrun, shot, down. (caught and countered are _caught's.)
static func _end(S: SimState, f, why: String) -> void:
	var ph: int = _g(f, PH)
	_s(f, PH, 0)
	_s(f, HOLD, 0)
	if why != "done" and why != "down" and (ph == 1 or ph == 2 or ph == 4):
		f.rush = null
	if _mine(S, f):
		DirBrawl.end(S, S.dirS.ex, "zip")
	var e = _cue(S, f, "zip_end", why)
	e.target = float(S.fighters.find(SimRoster.opp(S, f)))
	e.n = ph
	if why != "done":
		SimEvents.feed(S, f.name + " ZIP ENDS", why)


# ---------------------------------------------------------------- shots

## A shot hit f (DirBlast.hit, before its damage). The outcome the shot's event should carry, or "" when f's zip has
## nothing to say. On the way in a zip strike is stopped by any shot; a zip heavy shrugs off a weak one (as a heavy
## charge does) and is stopped by the rest. On the way out a shot drops him: out of control for knockdownTicks, with
## no landing damage (SimFighter.drop).
static func shot(S: SimState, f, sh) -> String:
	var ph: int = _g(f, PH)
	if ph == 0 or ph == 3:
		return ""
	if ph == 4:
		var vx: float = f.vx
		var vy: float = f.vy
		_end(S, f, "down")
		f.rush = null
		SimFighter.drop(S, f, int(cfg().knockdownTicks), vx, vy)
		return "stop"
	if _g(f, KIND) == 2 and sh.power <= float(DirBlast.data().charge.shrugPower):
		return "shrug"
	_end(S, f, "shot")
	return "stop"


# ---------------------------------------------------------------- the read

## The truth for the body (docs/animation/zip.md sections 9 and 12): empty when f is not zipping.
static func read(S: SimState, f) -> Dictionary:
	var ph: int = _g(f, PH)
	if ph == 0:
		return {}
	var heavy: bool = _g(f, KIND) == 2
	var inReach: bool = ph == 3
	var n: int = _g(f, LEN) - _g(f, LEFT)
	var blow: int = 0
	if inReach:
		# In reach the phase is the ticks before his blow and the ticks after it: n counts across both.
		n = DirBrawl._now(S) - _g(f, ARR_L) if _g(f, STATE) == 0 else _g(f, RB) + (_g(f, RA) - _g(f, LEFT))
		blow = 0 if _g(f, STATE) == 0 else 1
	var ek: int = _g(f, EXIT)
	return {
		"reading": READS[_g(f, READ)], "btn": "y" if heavy else "x",
		"phase": PHASES[ph], "n": n, "len": _g(f, LEN),
		"tell": _g(f, TELL), "in": _g(f, WAYIN), "hits": 1, "hd": _g(f, RB) + _g(f, RA), "out": _g(f, WAYOUT), "lift": 0,
		"blow": blow,
		"via": "" if ek == 0 else ("back" if ek == 1 else "run"), "pass": PASSES[_g(f, PASS)], "entry_in": "", "entry_out": "",
		"dist_bh": float(_g(f, D0)) / FX / BH,
		"exit": EXITS[ek], "x": float(_g(f, EX_X)) / FX, "y": float(_g(f, EX_Y)) / FX,
	}


# ---------------------------------------------------------------- the AI

## An AI attack beat in the mid band (DirAI.aiInput): it zips at its level's zipShare when it has the ki to spare and the
## rival is not pressing, with
## the heavy at zipHeavyShare. It writes the press a player makes: LT held with X or Y. Its exit is back, or at
## zipExit another: the far side, above, or away.
static func aiUse(S: SimState, f, o, i: SimIntent) -> bool:
	if not on() or i.mode != 0 or zipping(f) or zipping(o) or S.dirS.ex != null:
		return false
	var c: Dictionary = cfg()
	var lv: Dictionary = DirAI.lv()
	var d: float = DirBands.dist(f, o) / BH
	# It keeps half the away distance in hand: from the edge of the band a rival who drifts away outruns it.
	if d < float(c.band.minBh) or d > float(c.band.maxBh) - 0.5 * float(c.exit.awayBh) or f.ki < float(c.strike.ki) + 10.0:
		return false
	# Not at a rival who is pressing: his blows catch a zipper in reach. He is pressing while his last attack press is
	# inside the brawl's string lapse.
	if S.T - o.lastAtkT < float(int(DirBrawl.cfg().stringLapseTicks)) / DirData.TICKS_PER_SEC:
		return false
	if S.rng.next() >= float(lv.get("zipShare", 0.0)):
		return false
	var heavy: bool = f.ki >= float(c.heavy.ki) + 10.0 and S.rng.next() < float(lv.get("zipHeavyShare", 0.0))
	i.heavy = heavy
	i.light = not heavy
	i.stanceMask |= LT
	var ex: int = 0
	if S.rng.next() < float(lv.get("zipExit", 0.0)):
		ex = 1 + int(S.rng.next() * 3.0) % 3
	_s(f, AI_EXIT, ex)
	return true


## The AI's own zip, each tick: it keeps LT down and holds the stick for its exit.
static func aiZipping(S: SimState, f, i: SimIntent) -> void:
	var o = SimRoster.opp(S, f)
	var toward: float = SimMathx.jsign(SimWrap.sdx(f.x, o.x))
	i.stanceMask |= LT
	i.mx = 0.0
	i.my = 0.0
	var ex: int = _g(f, AI_EXIT)
	if ex == 1:
		i.mx = toward
	elif ex == 2:
		i.my = 1.0
	elif ex == 3:
		i.mx = -toward


## A zip is coming at the AI fighter D, n ticks from its arrival (start). One draw, when it has its reaction time:
## the counter at zipCounter (against a zip heavy, a heavy whose wind-up ends in its window; else a light pressed
## two ticks before the arrival), the dodge on the arrival at zipDodge, else the guard at the rate it guards any approach (approachReact).
static func seen(S: SimState, D, Z, n: int) -> void:
	_s(D, AI_ANS, 0)
	if D.ai == null:
		return
	var c: Dictionary = cfg()
	var lv: Dictionary = DirAI.lv()
	var rt: int = int(DirAI.skill().get("reactTicks", 14))
	var u: float = S.rng.next()
	var zc: float = float(lv.get("zipCounter", 0.0))
	var zd: float = float(lv.get("zipDodge", 0.0))
	var g: float = float((lv.get("approachReact", [0.0]) as Array)[0])   # the guard, at the rate it guards any approach
	var rb: int = _g(Z, RB)
	if u < zc:
		var mark: int = rt + int(DirBrawl.cfg().heavy.windupTicks)
		if _g(Z, KIND) == 2 and mark >= n - int(c.counter.heavyBefore) and mark <= n + rb and D.ki >= float(DirBrawl.cfg().heavy.ki):
			_s(D, AI_ANS, 4)
			_s(D, AI_AT, S.tick + rt)
		else:
			_s(D, AI_ANS, 3)
			_s(D, AI_AT, S.tick + maxi(rt, n - 2))
	elif u < zc + zd:
		_s(D, AI_ANS, 2)
		_s(D, AI_AT, S.tick + maxi(rt, n + maxi(0, rb - 6)))
	elif u < zc + zd + g:
		_s(D, AI_ANS, 1)
		_s(D, AI_AT, S.tick + rt)


## The AI's answer this tick, outside an exchange (DirAI.aiInput): 0 nothing, 1 it guards, 2 it dodges, 3 it presses
## a light, 4 a heavy. A press is returned once.
static func aiAnswer(S: SimState, f, o) -> int:
	var a: int = _g(f, AI_ANS)
	if a == 0 or a == 9:
		return 0
	if not zipping(o):
		_s(f, AI_ANS, 0)
		return 0
	if S.tick < _g(f, AI_AT):
		return 0
	if a >= 2:
		_s(f, AI_ANS, 9)
	return a


## The AI rival in a zip's ticks in reach (DirBrawl.aiInput): it holds its guard if that was its answer, makes the
## answer whose tick has come (the light, the dodge away), and once the zipper's blow has resolved it punishes him at
## its level's zipPunish: a light, which catches him if it lands before he leaves.
static func aiReach(S: SimState, ex, f, i: SimIntent) -> void:
	var z = ex.A
	var a: int = _g(f, AI_ANS)
	f.ai.st = 0.0
	if f.stunTicks > 0:
		return
	if a == 1 and _g(z, STATE) == 0:
		i.guard = true
		f.ai.st = 1.0
		return
	if (a == 2 or a == 3) and S.tick >= _g(f, AI_AT) and _g(z, STATE) == 0:
		_s(f, AI_ANS, 9)
		if a == 3:
			i.light = true
		else:
			i.dodge = true
			i.sprint = true
			i.mx = -SimMathx.jsign(SimWrap.sdx(f.x, z.x))
		return
	if _g(z, STATE) == 1 and a != 8:
		_s(f, AI_ANS, 8)
		if S.rng.next() < float(DirAI.lv().get("zipPunish", 0.0)):
			i.light = true
