class_name DirGrapple
## The grapple's director side, slice G1 (docs/director/grapple-director.md; Game Design's rules, docs/design/grapple.md;
## Controls' reads, docs/controls/grapple-input.md). Behind a switch: grapple.enabled.
##  - The catch. In a brawl, A tapped with his line free is a reach for the collar with a tell of catch.tell ticks from
##    the press. A blow that lands on him in the tell stops it. At the tell's end, out of reach (a light's), it misses
##    and he is open catch.whiffOpen ticks; on a rival who is open (staggered, or open after a miss) it is the throw at
##    once; on anyone else it is the clinch, one ahead for the catcher on a rival who guards, winds or charges (a guard
##    or armour doesn't stop a hand on the collar: his wind-up is stopped).
##  - The tech. The caught fighter's A within catch.tech ticks of the landing breaks it: both part. An A of his in the
##    tell is early, and voids it.
##  - The clinch: the grip, from two behind to two ahead (the catcher's way), and a pulse every clinch.pulse ticks from
##    the tie-up, at most clinch.max ticks. A on the pulse (inside clinch.window, sharp inside clinch.sharp; DirPulse)
##    claims it. When its window closes: both claimed, the sharper moves the grip a step his way, and equal sharpness
##    moves nothing; one claimed, he takes the step. A stray (A inside no window, or a second A in one) moves nothing and
##    voids his next pummel. So a masher does as well as a fighter who doesn't press.
##  - Its exits. At two ahead his next pummel is the throw by his stick: down (slammed to the ground and buried
##    throw.bury ticks: an opening), up (throw.upBh up and open throw.upOpen ticks in the air: an opening), or across
##    (throw.acrossBh along the line, a knock-back: the brawl ends). The one two behind throws instead by his own stick
##    with a sharp pummel on that pulse (the reversal). A pummel with the stick away from even or ahead is the push-off:
##    clinch.pushBh apart, the brawl lets go, and the pusher has the first move. At clinch.max both part clinch.partBh,
##    even, and the brawl goes on. A burst, or anything else that ends the brawl, breaks it.
##  - One grab lockout of `lockout` ticks from each attempt, and for both after a clinch that ends with nobody thrown; a
##    thrown fighter can't be grabbed for noRegrab ticks. A press in either is refused, with its cue.
##  - The AI. Its pummels are drawn at the tie-up: its level's pummel share of the pulses, clinch.aiOffsets off the pulse
##    (never sharp). Its tech is drawn as the tell begins, at its share, and pressed no sooner than its reaction time
##    after it and after the landing. It catches a rival who guards, or winds a heavy it has had its reaction time to
##    see, at its catch share, once for each wind-up and each 30 ticks of a guard. At two ahead it throws down.
## G2 (Game Design, 2026-10-17): a tie on a pulse goes to the one nearer it by the tick; at the time the grip's leader
## takes a first move and the brawl lets go; the AI varies its throws by what each hands it and by its care.
## Not in G1: vicious blows (X, Y and B in a clinch are spent, with a cue), the brace, the leader walking the pair, the
## pin, the carry, throws through the planner, the AI's brace and its choice of throw, the perfect catch, and an
## interjection. A latched A's release is no press here: the sim can't see the latch.
## State: the fighter's director integers after DirZip's. A read never sizes them, so with the grapple off nothing moves.
## Numbers: data/director/interrupts.json `grapple`, and the level's brawl.grapple block in data/director/ai.json.

const BASE: int = DirZip.END
const MODE: int = BASE          # 0 none, 1 his catch's tell, 2 in a clinch (on both)
const T0: int = BASE + 1        # S.tick of his catch's press (the tell), then of the tie-up (on both)
const ROLE: int = BASE + 2      # 1 the catcher, 2 the one caught, while a tell or a clinch is on
const GRIP: int = BASE + 3      # his grip, his way: -2 to 2 (on both, opposite)
const PULSE: int = BASE + 4     # the last pulse judged
const CLAIM_K: int = BASE + 5   # the pulse his pummel claimed; 0 none
const CLAIM_OFF: int = BASE + 6 # ... how far off it, in ticks (99: a voided pummel, which claims it and moves nothing)
const CLAIM_Q: int = BASE + 7   # ... and his stick's quarter at the press (DirBrawl._quarter: 1 up, 2 toward, 3 down, 4 away)
const VOID: int = BASE + 8      # 1 when his next pummel (or his tech) is void: a stray, or an early press
const LOCK: int = BASE + 9      # S.tick until which a grab of his is refused (kept across brawls)
const NOGRAB: int = BASE + 10   # S.tick until which he can't be grabbed: he was thrown (kept across brawls)
const PREV: int = BASE + 11     # a player's intent levels on the tick before, for SimPressRead.struggle_press: 1 X, 2 Y, 4 B, 8 A
const AI_P: int = BASE + 12     # the AI: its pummels, 3 bits a pulse from the first: 1 it pummels, then the offset's index (clinch.aiOffsets)
const AI_TECH: int = BASE + 13  # the AI caught: S.tick of its tech; 0 none
const AI_CSAW: int = BASE + 14  # the AI: the rival's wind-up or guard it last weighed a catch against, plus 1
const END: int = BASE + 15


static func cfg() -> Dictionary:
	var d: Dictionary = DirInterrupt.data()
	if not is_same(d, _cfgOf):
		_cfg = d.get("grapple", {})   # the same block every time for the same data (tools edit it in place)
		_cfgOf = d
	return _cfg


static var _cfg: Dictionary = {}
static var _cfgOf = null


static func on() -> bool:
	return DirBrawl.on() and bool(cfg().get("enabled", false))


static func _size(f) -> void:
	if f.act.dirI.size() >= END:
		return
	DirZip._size(f)
	if f.act.dirI.size() < END:
		f.act.dirI.resize(END)


## A read never sizes the integers (their count is in the gameplay hash): a slot never written reads 0.
static func _g(f, k: int) -> int:
	return f.act.dirI[k] if k < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	_size(f)
	f.act.dirI[k] = v


static func _alv() -> Dictionary:
	return DirAI.lv().get("brawl", {}).get("grapple", {})


static func _cue(S: SimState, f, o, name: String, text: String = ""):
	var e = DirBrawl._ev(S, f, name, text)
	e.target = float(S.fighters.find(o))
	return e


# ---------------------------------------------------------------- for the brawl and the interrupts

## True while f is in a catch's tell or a clinch: his presses are the grapple's.
static func holds(f) -> bool:
	return _g(f, MODE) != 0


## True while f's catch is in its tell.
static func telling(f) -> bool:
	return _g(f, MODE) == 1


## For UI, Animation and QA: f's grapple now. Empty when none. mode: "tell" or "clinch"; role: "catcher" or "caught";
## grip: his, his way; pulse: the last judged; t0: the tie-up's S.tick (the tell's press while in the tell).
static func now(S: SimState, f) -> Dictionary:
	if not on() or _g(f, MODE) == 0:
		return {}
	return {"mode": "tell" if _g(f, MODE) == 1 else "clinch", "role": "catcher" if _g(f, ROLE) == 1 else "caught",
		"grip": _g(f, GRIP), "pulse": _g(f, PULSE), "t0": _g(f, T0)}


## The fighters of `order` whose presses DirInterrupt reads: all of them with the grapple off; in a catch or a clinch his
## presses are the grapple's, and only a burst breaks it.
static func freeOf(S: SimState, order: Array) -> Array:
	if not on():
		return order
	return order.filter(func(f): return _g(f, MODE) == 0)


## True when f's A is the grapple's (in a brawl), so the interrupts don't call it an empty press.
static func takesA(S: SimState, f) -> bool:
	return on() and DirBrawl.inBrawl(S, f) and not DirBrawl.quiet(S.dirS.ex)


## An attack press of f's in a brawl (DirBrawl.takes): in a tell or a clinch it is spent. Vicious blows are G2's.
static func takes(S: SimState, f, kind: String) -> bool:
	if not on() or _g(f, MODE) == 0:
		return false
	var a = DirBrawl._ev(S, f, "press_ack", "grapple", DirBrawl._cell(kind))
	a.n = S.tick
	return true


## The brawl is over (DirBrawl.over), and why: a catch or a clinch ends with it, and a clinch so ended starts the lockout for both.
static func over(S: SimState, ex, why: String) -> void:
	if not on() or (_g(ex.A, MODE) == 0 and _g(ex.D, MODE) == 0):
		return
	if _g(ex.A, MODE) == 2:
		_cue(S, ex.A, ex.D, "grapple_end", why)
		_lockBoth(S, ex.A, ex.D)
	_end(S, ex.A, ex.D)


## A blow landed clean on f in his catch's tell (DirBrawl.contact): blows beat grabs.
static func stopped(S: SimState, ex, f) -> void:
	var o = ex.D if f == ex.A else ex.A
	_end(S, f, o)
	_cue(S, f, o, "grapple_catch", "stopped")
	SimEvents.feed(S, f.name + "'S CATCH STOPPED", "a blow landed in its tell")


# ---------------------------------------------------------------- once a tick, from DirBrawl.tick

static func tick(S: SimState, ex) -> void:
	if not on() or DirBrawl.quiet(ex):
		return
	var c: Dictionary = cfg()
	for f in [ex.A, ex.D]:
		var o = ex.D if f == ex.A else ex.A
		if _g(f, MODE) == 0 and _g(o, MODE) != 2 and f.stunTicks <= 0 and f.input.context and not f.input.guard and f.act.mode != 1:
			if _g(o, MODE) == 1:
				_s(f, VOID, 1)   # an A in the rival's tell is early: it voids his tech
				_cue(S, f, o, "grapple_stray", "early")
			else:
				_catch(S, ex, f, o)
	for f in [ex.A, ex.D]:
		if _g(f, MODE) == 1 and S.tick >= _g(f, T0) + int(c.catch.tell):
			_land(S, ex, f, ex.D if f == ex.A else ex.A)
			if S.dirS.ex != ex or ex.branch != "":
				return
	if _g(ex.A, MODE) == 2:
		_clinch(S, ex)
		if S.dirS.ex != ex or ex.branch != "":
			return
	if holds(ex.A) or holds(ex.D):
		for f in [ex.A, ex.D]:
			DirBrawl._s(f, DirBrawl.LAST_AT, S.tick)   # a catch or a clinch is no idle brawl


## f presses A in reach: the catch, unless it is refused.
static func _catch(S: SimState, ex, f, o) -> void:
	var c: Dictionary = cfg()
	if S.tick < _g(f, LOCK):
		_refused(S, f, o, "lockout", _g(f, LOCK))
		return
	if S.tick < _g(o, NOGRAB):
		_refused(S, f, o, "thrown", _g(o, NOGRAB))
		return
	if not DirBrawl._free(S, f):
		_refused(S, f, o, "busy", S.tick)
		return
	var p: int = S.tick - DirBrawl._waited(f)
	_s(f, LOCK, S.tick + int(c.lockout))
	_s(f, MODE, 1)
	_s(f, T0, p)
	_s(f, ROLE, 1)
	_s(o, ROLE, 2)
	_s(f, VOID, 0)
	_s(o, VOID, 0)
	DirBrawl._s(f, DirBrawl.FREE_AT, S.tick + (1 << 24))   # his line is the catch's until it lands
	DirBrawl._s(f, DirBrawl.HELD_P, 0)
	DirBrawl._burstEnd(S, f)
	DirBrawl._s(f, DirBrawl.X_LIVE, 0)
	var land: int = p + int(c.catch.tell)
	var e = _cue(S, f, o, "grapple_catch", "tell")
	e.n = land
	SimEvents.feed(S, f.name + " REACHES FOR " + o.name, "a catch: it lands in " + str(int(c.catch.tell)) + " ticks")
	_s(o, AI_TECH, 0)
	if o.ai != null:
		# Its tech: drawn now, pressed no sooner than its reaction time after the tell began, and after the landing.
		var slot: int = S.fighters.find(o)
		var react: int = int(DirAI.skill().get("reactTicks", 14))
		var lo: int = maxi(p + react, land + 1)
		var hi: int = land + int(c.catch.tech)
		if lo <= hi and SimRng.keyed(int(S.game.seed), "grapple.tech", p * 2 + slot) < float(_alv().get("tech", 0.0)):
			_s(o, AI_TECH, lo + mini(hi - lo, int(floor(SimRng.keyed(int(S.game.seed), "grapple.techAt", p * 2 + slot) * float(hi - lo + 1)))))


static func _refused(S: SimState, f, o, why: String, until: int) -> void:
	var e = _cue(S, f, o, "grapple_refused", why)
	e.n = until


## f's catch lands: a miss, the throw at once, or the clinch.
static func _land(S: SimState, ex, f, o) -> void:
	var c: Dictionary = cfg()
	_s(f, MODE, 0)
	DirBrawl._s(f, DirBrawl.FREE_AT, S.tick)
	var far: float = DirBands.dist(f, o) - float(DirData.contact().offset)
	if far > float(DirBrawl.cfg().give.get("lightReachBh", 0.6)) * DirInterrupt.BH or o.state != "locked":
		DirBrawl._s(f, DirBrawl.OPEN_UNTIL, DirBrawl._now(S) + int(c.catch.whiffOpen))
		_end(S, f, o)
		_cue(S, f, o, "grapple_catch", "miss")
		return
	if o.stunTicks > 0 or DirBrawl._now(S) < DirBrawl._g(o, DirBrawl.OPEN_UNTIL):
		_cue(S, f, o, "grapple_catch", "throw")
		_throw(S, ex, f, o, DirBrawl._quarter(f, o) if f.ai == null else 3, "throw")
		return
	_tieUp(S, ex, f, o)


## The tie-up: the clinch starts, even, or one ahead for the catcher on a rival who guards, winds or charges.
static func _tieUp(S: SimState, ex, f, o) -> void:
	var c: Dictionary = cfg().clinch
	var lead: int = 0
	var winding: bool = DirBrawl._windOn(o) and DirBrawl._g(o, DirBrawl.LINE) != 0
	if o.input.guard or winding or DirBrawl._g(o, DirBrawl.CHG) == 1 or DirBrawl._g(o, DirBrawl.CHG) == 2:
		lead = int(c.leadGuard)
	if winding:
		DirBrawl._wEnd(S, o, DirBrawl._g(o, DirBrawl.KIND), 2)   # armour doesn't stop a hand on the collar
		DirBrawl._s(o, DirBrawl.HOLD_AT, 0)
	DirBrawl._drop(S, ex, o)
	DirBrawl._drop(S, ex, f)
	for g in [f, o]:
		_s(g, MODE, 2)
		_s(g, T0, S.tick)
		_s(g, PULSE, 0)
		_s(g, CLAIM_K, 0)
		_s(g, PREV, _bits(g.input))
		DirBrawl._s(g, DirBrawl.FREE_AT, S.tick + (1 << 24))   # both lines are the clinch's
		DirBrawl._s(g, DirBrawl.HELD_P, 0)
		DirBrawl._burstEnd(S, g)   # a burst running ends with the tie-up
		DirBrawl._s(g, DirBrawl.X_LIVE, 0)
		_aiPlan(S, g)
	_s(f, GRIP, lead)
	_s(o, GRIP, -lead)
	var e = _cue(S, f, o, "grapple_clinch", "start")
	e.k = float(lead)
	e.n = S.tick
	DirCamIntent.clinch(S, f, o, S.tick, int(c.max), int(c.pulse))   # the camera-intent feed: the clinch's clock
	SimEvents.feed(S, "CLINCH", f.name + " ties up " + o.name + (", one ahead" if lead > 0 else ", even"))


## The AI's pummels for this clinch, drawn at the tie-up.
static func _aiPlan(S: SimState, f) -> void:
	if f.ai == null:
		_s(f, AI_P, 0)
		return
	var c: Dictionary = cfg().clinch
	var share: float = float(_alv().get("pummel", 0.0))
	var offs: Array = c.get("aiOffsets", [-4, -3, 3, 4])
	var n: int = int(c.max) / int(c.pulse)
	var slot: int = S.fighters.find(f)
	var bits: int = 0
	for k in range(1, n + 1):
		var key: int = _g(f, T0) * 8 + slot * 4 + k
		if SimRng.keyed(int(S.game.seed), "grapple.pummel", key) < share:
			var oi: int = clampi(int(floor(SimRng.keyed(int(S.game.seed), "grapple.pummelOff", key) * float(offs.size()))), 0, offs.size() - 1)
			bits |= (1 | (oi << 1)) << (3 * (k - 1))
	_s(f, AI_P, bits)


## The AI presses A on this tick: its tech, or a pummel of its plan.
static func _aiPress(S: SimState, f, t0: int) -> bool:
	if _g(f, ROLE) == 2 and _g(f, AI_TECH) > 0 and S.tick == _g(f, AI_TECH):
		_s(f, AI_TECH, 0)
		return true
	var c: Dictionary = cfg().clinch
	var offs: Array = c.get("aiOffsets", [-4, -3, 3, 4])
	var every: int = int(c.pulse)
	var bits: int = _g(f, AI_P)
	for k in range(1, int(c.max) / every + 1):
		var b: int = (bits >> (3 * (k - 1))) & 7
		if (b & 1) != 0 and S.tick == t0 + k * every + int(offs[b >> 1]):
			return true
	return false


## The clinch's tick: the presses, the pulse whose window has closed, and the time.
static func _clinch(S: SimState, ex) -> void:
	var c: Dictionary = cfg().clinch
	var t0: int = _g(ex.A, T0)
	var every: int = int(c.pulse)
	var n: int = int(c.max) / every
	for f in [ex.A, ex.D]:
		var o = ex.D if f == ex.A else ex.A
		var press: bool = false
		var p: int = S.tick
		if f.ai == null:
			press = f.stunTicks <= 0 and SimPressRead.struggle_press(_prevIntent(f), f.input) == "letgo"   # A, on every layout (Controls)
			p = S.tick - DirBrawl._waited(f)
			_s(f, PREV, _bits(f.input))
		else:
			press = _aiPress(S, f, t0)
		if press:
			_pummel(S, ex, f, o, p)
			if _g(ex.A, MODE) != 2 or S.dirS.ex != ex or ex.branch != "":
				return
	var k: int = _g(ex.A, PULSE) + 1
	if k <= n and S.tick >= DirPulse.closes(t0, every, k, int(c.window)):
		_judge(S, ex, k)
		if _g(ex.A, MODE) != 2 or S.dirS.ex != ex or ex.branch != "":
			return
	if S.tick - t0 >= int(c.max):
		var g: int = _g(ex.A, GRIP)
		if g == 0:
			_part(S, ex, ex.A, ex.D, "time", float(c.partBh))   # even: nobody has the first move, and the brawl goes on
		elif bool(c.get("timeThrows", false)):
			var ld = ex.A if g > 0 else ex.D
			_throw(S, ex, ld, ex.D if g > 0 else ex.A, _g(ld, CLAIM_Q), "throw")   # Game Design's 1c (rulings-2026-10-22): the leader throws at the time
		else:
			_timeLead(S, ex, ex.A if g > 0 else ex.D, ex.D if g > 0 else ex.A)


## f presses A in the clinch at tick p: his tech, a claim of the pulse, a voided one, or a stray.
static func _pummel(S: SimState, ex, f, o, p: int) -> void:
	var c: Dictionary = cfg().clinch
	var t0: int = _g(f, T0)
	if _g(f, ROLE) == 2 and _g(f, PULSE) == 0 and p - t0 <= int(cfg().catch.tech):
		if _g(f, VOID) == 1:
			_s(f, VOID, 0)
			var ev = _cue(S, f, o, "grapple_pummel", "void")
			ev.k = float(_g(f, GRIP))
			return
		_part(S, ex, f, o, "tech", float(c.partBh))
		return
	var every: int = int(c.pulse)
	var k: int = DirPulse.of(t0, every, int(c.max) / every, int(c.window), p)
	if k == 0 or k <= _g(f, PULSE) or _g(f, CLAIM_K) == k:
		_s(f, VOID, 1)
		var ev = _cue(S, f, o, "grapple_stray")
		ev.k = float(_g(f, GRIP))
		return
	_s(f, CLAIM_K, k)
	if _g(f, VOID) == 1:
		_s(f, VOID, 0)
		_s(f, CLAIM_OFF, 99)
		var ev = _cue(S, f, o, "grapple_pummel", "void")
		ev.k = float(_g(f, GRIP))
		return
	_s(f, CLAIM_OFF, DirPulse.off(t0, every, k, p))
	_s(f, CLAIM_Q, DirBrawl._quarter(f, o) if f.ai == null else _aiThrowQ(S, f, o, k))   # G2: the AI's throw by what it hands it and its care


## Pulse k's window has closed: the throw, the reversal, the push-off, or the step.
static func _judge(S: SimState, ex, k: int) -> void:
	var c: Dictionary = cfg().clinch
	var A = ex.A
	var D = ex.D
	var win: int = int(c.window)
	var sharp: int = int(c.sharp)
	var top: int = int(c.grip)
	var va: bool = _g(A, CLAIM_K) == k and _g(A, CLAIM_OFF) <= win
	var vd: bool = _g(D, CLAIM_K) == k and _g(D, CLAIM_OFF) <= win
	var sa: bool = va and _g(A, CLAIM_OFF) <= sharp
	var sd: bool = vd and _g(D, CLAIM_OFF) <= sharp
	var ga: int = _g(A, GRIP)
	var catcher = A if _g(A, ROLE) == 1 else D
	var other = D if catcher == A else A
	for g in [A, D]:
		_s(g, PULSE, k)
	var pe = _cue(S, catcher, other, "grapple_pulse")
	pe.k = float(k)
	pe.n = _g(A, T0) + k * int(c.pulse)
	pe.amount = float(_g(catcher, GRIP))
	# The throw: the leader's pummel at two ahead; the one two behind throws instead with a sharp one on the same pulse.
	if absi(ga) >= top:
		var lead = A if ga > 0 else D
		var back = D if lead == A else A
		if (va if lead == A else vd):
			if (sd if back == D else sa):
				_throw(S, ex, back, lead, _g(back, CLAIM_Q), "reversal")
			else:
				_throw(S, ex, lead, back, _g(lead, CLAIM_Q), "throw")
			return
	# The push-off: a pummel with the stick away, from even or ahead.
	for f in [A, D]:
		if (va if f == A else vd) and _g(f, CLAIM_Q) == 4 and _g(f, GRIP) >= 0:
			_pushOff(S, ex, f, D if f == A else A)
			return
	var step: int = 0
	if va and vd:
		var oa: int = _g(A, CLAIM_OFF)
		var od: int = _g(D, CLAIM_OFF)
		step = 0 if oa == od else (1 if oa < od else -1)   # G2: the one nearer the pulse by the tick takes the step
	elif va:
		step = 1
	elif vd:
		step = -1
	if step != 0:
		ga = clampi(ga + step, -top, top)
		_s(A, GRIP, ga)
		_s(D, GRIP, -ga)
	for f in [A, D]:
		if (va if f == A else vd):
			var e = _cue(S, f, D if f == A else A, "grapple_pummel", "sharp" if (sa if f == A else sd) else "step")
			e.k = float(_g(f, GRIP))
			e.amount = float(_g(f, CLAIM_OFF))
	for g in [A, D]:
		_s(g, CLAIM_K, 0)


## f throws o by the stick's quarter q: down, up, or across. how: throw, or reversal.
static func _throw(S: SimState, ex, f, o, q: int, how: String) -> void:
	var c: Dictionary = cfg()
	var tc: Dictionary = c.throw
	_end(S, f, o)
	_s(o, NOGRAB, S.tick + int(c.noRegrab))
	if not _throwHit(S, ex, f, o):
		return   # the throw's blow ended the exchange (a KO, a broken region's set piece)
	var bh: float = DirInterrupt.BH
	if q == 3 or q == 1:
		var gy: float = WorldWater.floorAt(S, o.x, DirBrawl._gz())   # Game Design rulings 2026-10-30 row 11: the floor, for the height test and the placement
		var ticks: int = int(tc.upOpen)
		var text: String = "thrown_up"
		if q == 3:
			text = "thrown_down"
			if o.y - gy <= float(tc.upBh) * bh:
				o.y = DirWater.held(S, o, SimFighter.floorFor(S, o, o.x, DirBrawl._gz()), DirBrawl._gz())   # slammed into the ground: the bury; on the floor of a lake or the sea, flat on it for the same opening
				ticks = int(tc.bury)
				if WorldFill.floorOn() and WorldWater.floorDepth(S, o.x) > 0.0:
					SimFx.splash(S, o.x, o.y, 14, o.z)   # a splash, no crater (the throw digs none)
			else:
				o.y -= float(tc.upBh) * bh   # high in the air: thrown down, open in the air
		else:
			o.y += float(tc.upBh) * bh
		_cue(S, f, o, "grapple_end", "reversal" if how == "reversal" else text)
		SimEvents.feed(S, f.name + (" REVERSES AND THROWS " if how == "reversal" else " THROWS ") + o.name, ("down: buried" if q == 3 else "up") + ", open for " + str(ticks) + " ticks")
		DirBrawl._stagger(S, ex, f, o, ticks, text, true)   # an opening: B is the launcher
		return
	_cue(S, f, o, "grapple_end", "reversal" if how == "reversal" else "throw_across")
	SimEvents.feed(S, f.name + (" REVERSES AND THROWS " if how == "reversal" else " THROWS ") + o.name, "across")
	DirBrawl._knock(S, ex, f, o, float(tc.acrossBh), q)   # a plain send along the line (away: past him); the brawl ends


## G2: the time with a leader: both part clinch.partBh, the leader takes the first move (clinch.timeFirstMove ticks
## before the other may start an approach), and the brawl lets go. The lockout starts for both: nobody was thrown.
static func _timeLead(S: SimState, ex, lead, back) -> void:
	var c: Dictionary = cfg()
	_end(S, lead, back)
	_lockBoth(S, lead, back)
	_apart(lead, back, float(c.clinch.partBh))
	DirBrawl._s(back, DirBrawl.MOVE_AT, S.tick + int(c.clinch.get("timeFirstMove", 20)))
	_cue(S, lead, back, "grapple_end", "time_lead")
	SimEvents.feed(S, "CLINCH ENDS", "time: " + lead.name + " won the grip, and the first move is his")
	DirBrawl.end(S, ex, "clinch_time")


## G2: the AI's throw, should this pummel be its throw: down (the bury: an opening on the ground), up (open in the air)
## or across (sent along the line: the brawl ends). Down and up hand it a launch, so they weigh half while it lacks the
## launcher's ki. Across is weighed by its care against the people where he would land: the hero (care above 0) away
## from them, the Anti-hero (below 0) towards them. A keyed draw by the tie-up, the pulse and the slot.
static func _aiThrowQ(S: SimState, f, o, k: int) -> int:
	var tw: Dictionary = cfg().throw.get("ai", {})
	if tw.is_empty():
		return 3
	var cash: float = 1.0 if f.ki >= float(DirBrawl.cfg().launcher.ki) else 0.5
	var wd: float = float(tw.down) * cash
	var wu: float = float(tw.up) * cash
	var side: float = 1.0 if SimWrap.sdx(f.x, o.x) >= 0.0 else -1.0
	var land: float = SimWrap.wrap(o.x + side * float(cfg().throw.acrossBh) * DirInterrupt.BH)
	var pop: float = clampf(float(WorldStructures.popNear(S, land, float(tw.get("popR", 3.0)) * DirInterrupt.BH)) / maxf(0.001, WorldStructures.popNearRef(S)), 0.0, 1.0)
	var wa: float = maxf(0.05, float(tw.across) * (1.0 + (-float(f.care)) * float(tw.get("careW", 1.0)) * pop))
	var x: float = SimRng.keyed(int(S.game.seed), "grapple.throw", _g(f, T0) * 8 + k * 2 + S.fighters.find(f)) * (wd + wu + wa)
	if x < wd:
		return 3
	if x < wd + wu:
		return 1
	return 2


## The throw's blow (Game Design, 2026-10-18 1c): worth throw.worth brawl lights, as a heavy, before what the throw
## hands the brawl (the bury, the opening in the air, the send across with its landing). False when it ended the exchange.
static func _throwHit(S: SimState, ex, f, o) -> bool:
	var w: float = float(cfg().throw.get("worth", 0.0))
	if w <= 0.0:
		return true
	var c: Dictionary = DirBrawl.cfg()
	var o2 := {"class": "heavy", "stop": float(int(c.hitstop.heavy)) / DirData.TICKS_PER_SEC, "big": true, "kb": float(c.recoil),
		"ignoreStance": true, "noParry": true, "weighed": true, "throw": true}
	DirMelee.weigh(S, o2, "heavy")   # hit-stop by weight: a throw is a heavy's
	DirMelee.strike(S, ex, f, o, w * DirBrawl._unit(), o2)
	if S.dirS.ex != ex or ex.cancel or ex.branch != "" or S.game.ko != null:
		return false
	if DirBrawl._setPiece(ex):
		DirBrawl.over(S, ex, "break")   # the throw broke a region: the break plays in this exchange
		return false
	return true


## f pushes off: both apart, the brawl lets go, and he has the first move.
static func _pushOff(S: SimState, ex, f, o) -> void:
	var c: Dictionary = cfg()
	_end(S, f, o)
	_lockBoth(S, f, o)
	_apart(f, o, float(c.clinch.pushBh))
	DirBrawl._s(o, DirBrawl.MOVE_AT, S.tick + int(c.clinch.pushFirstMove))
	_cue(S, f, o, "grapple_end", "push_off")
	SimEvents.feed(S, f.name + " PUSHES OFF", "both apart, and the first move is his")
	DirBrawl.end(S, ex, "push_off")


## Both part, even (the time, the tech), and the brawl goes on.
static func _part(S: SimState, ex, f, o, why: String, bh: float) -> void:
	_end(S, f, o)
	_lockBoth(S, f, o)
	_apart(f, o, bh)
	_cue(S, f, o, "grapple_end", why)
	SimEvents.feed(S, "CLINCH ENDS", why + ": both part")


static func _lockBoth(S: SimState, f, o) -> void:
	for g in [f, o]:
		_s(g, LOCK, maxi(_g(g, LOCK), S.tick + int(cfg().lockout)))


## The two are set bh body heights past striking distance along the line, each moving half.
static func _apart(f, o, bh: float) -> void:
	var d: float = SimWrap.sdx(f.x, o.x)
	var side: float = 1.0 if d >= 0.0 else -1.0
	var more: float = maxf(0.0, float(DirData.contact().offset) + bh * DirInterrupt.BH - absf(d)) * 0.5
	f.x = SimWrap.wrap(f.x - side * more)
	o.x = SimWrap.wrap(o.x + side * more)


## Nothing of a catch or a clinch is left on either, and both lines are free.
static func _end(S: SimState, f, o) -> void:
	for g in [f, o]:
		if _g(g, MODE) == 0 and _g(g, ROLE) == 0:
			continue
		_s(g, MODE, 0)
		_s(g, ROLE, 0)
		_s(g, CLAIM_K, 0)
		_s(g, VOID, 0)
		_s(g, AI_P, 0)
		_s(g, AI_TECH, 0)
		DirBrawl._s(g, DirBrawl.FREE_AT, mini(DirBrawl._g(g, DirBrawl.FREE_AT), S.tick))


static func _bits(i: SimIntent) -> int:
	return (1 if i.lightHeld else 0) | (2 if i.heavyHeld else 0) | (4 if i.sigHeld else 0) | (8 if i.contextHeld else 0)


static func _prevIntent(f) -> SimIntent:
	var b: int = _g(f, PREV)
	var pv := SimIntent.new()
	pv.lightHeld = (b & 1) != 0
	pv.heavyHeld = (b & 2) != 0
	pv.sigHeld = (b & 4) != 0
	pv.contextHeld = (b & 8) != 0
	return pv


# ---------------------------------------------------------------- the AI's catch, from DirBrawl.aiInput

## True when the AI's brawl input is the grapple's on this tick: in a tell or a clinch it presses nothing else, and a
## catch it decides now is written as its press of A.
static func aiInput(S: SimState, ex, f, o, i: SimIntent) -> bool:
	if not on():
		return false
	if _g(f, MODE) != 0:
		return true   # its tell, or the clinch: its pummels and its tech are drawn
	if _g(o, MODE) != 0 or f.stunTicks > 0 or not DirBrawl._free(S, f) or S.tick < _g(f, LOCK) or S.tick < _g(o, NOGRAB):
		return false
	var key: int = 0
	if DirBrawl._windOn(o) and DirBrawl._g(o, DirBrawl.FLAV) != 2 and DirBrawl._g(o, DirBrawl.KIND) == DirBrawl.BIG:
		if DirBrawl._now(S) - DirBrawl._g(o, DirBrawl.HOLD_AT) < int(DirAI.skill().get("reactTicks", 14)):
			return false
		key = DirBrawl._g(o, DirBrawl.HOLD_AT) * 2 + 1
	elif o.input.guard:
		key = (S.tick / 30) * 2
	else:
		return false
	if _g(f, AI_CSAW) == key + 1:
		return false
	_s(f, AI_CSAW, key + 1)
	if SimRng.keyed(int(S.game.seed), "grapple.catch", key * 2 + S.fighters.find(f)) >= float(_alv().get("catch", 0.0)):
		return false
	i.context = true
	return true
