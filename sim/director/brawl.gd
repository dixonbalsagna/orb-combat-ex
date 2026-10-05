class_name DirBrawl
## The brawl, slice B1 (docs/director/brawl-plan.md sections 2 to 4; docs/design/melee-press-feel.md sections 1 to 3 and
## 5 to 7). In the close band a light or a heavy against a rival who stands or guards starts a brawl in place of a
## planned exchange. It is one exchange (its template id is TPL) that both fighters are in: each has his own strike line
## (one blow on its way, one held press), and every attack press is one blow.
##  - A light lands contactTicks after the press. Lights tapped minGap to maxGap ticks apart are a flurry: a blow lasts
##    one tap gap and its damage goes with the gap (flurry.mul), so a faster flurry is not a stronger one.
##  - The run and the close (the spec's section 3): his run goes up one for each light or flurry blow he lands and
##    down one for each that lands on him; a heavy on him clears it, and so do runLapseTicks without landing. At a
##    run of runToClose his next landed light staggers the rival in place: decisive, at half a set-up. A blow on a
##    staggered fighter adds nothing to the run. A trade (both landing inside the lapse) cannot pass tradeMaxTicks:
##    at the limit it breaks for a lead of more than levelWithin, and a level trade is a seeded draw in which the
##    last closer of this brawl has `momentum` (section 9d); that fighter's next landed blow is the close.
##  - A heavy winds up windupTicks and lands landTicks later. Held past its wind-up it lands heldLandTicks after the
##    release, fully charged at heldFullTicks. Thrown after enderAfter landed blows of his string it is the ender: a
##    knock-back, or a launch when a launch is earned (held to full; flow). A lone heavy staggers; held to full with the
##    stick it launches. On a guard a heavy staggers the blocker in place, and nothing moves a blocker.
##  - It holds while they are within breakBh. It ends on a knock-back or a launch, when one of them leaves (a dodge or
##    a boost with the stick away, at the dodge-cancel's price), bursts, perfect-blocks or reverses, after idleTicks
##    with no attack from either, or when a set piece takes it over (a break, a finisher, a signature).
## A blow is one `strike` beat of the exchange, announced when it is thrown, so the renderers read it as they read a
## strike; its args carry the beat fields (style, grade, k, n, closing, charge, hand, ender, piece) and `brawl`.
## The exchange's kind is the weight of the blow that is landing, as the core reads it.
## Clocks: a fighter's taps, his line and the AI's choices count S.tick, which runs through a hit-stop, so a flurry
## keeps its tap rate; a blow's wind-up, a reel and a hold count live ticks, as every beat does.
## Not in B1: skill strikes and the beat point (B2); the set guard, the lift and the juggle, blows that stop a wind-up
## (B3); struggles (B4); the stick's damped walk. Flow is neither earned nor lost by a press inside a brawl until B2.
## State: the fighter's director integers after the alchemy's. Numbers: data/director/interrupts.json `brawl`, and the
## level's `brawl` block in data/director/ai.json.

const TPL: String = "brawl"
const BASE: int = DirAlchemy.SIZE
const LINE: int = BASE          # 0 idle, 1 a blow on its way, 2 a heavy held past its wind-up
const KIND: int = BASE + 1      # the blow on his line: LIGHT, FLURRY, HEAVY
const CONTACT: int = BASE + 2   # the live tick it lands
const FREE_AT: int = BASE + 3   # S.tick from which his line is free again
const REEL_AT: int = BASE + 4   # the live tick his reel ends
const HELD_P: int = BASE + 5    # a press he could not throw at once: its weight plus 1; 0 none
const HELD_AT: int = BASE + 6   # ... and its own tick
const LAST_TAP: int = BASE + 7  # the tick of his last light press; 0 none
const TAP_GAP: int = BASE + 8   # the ticks between his last two light presses, held to the flurry's range; 0: not a flurry
const STR_ON: int = BASE + 9    # 1 while his string runs
const STRING_N: int = BASE + 10 # landed blows of his string
const LAND_AT: int = BASE + 11  # S.tick of his last blow thrown or landed (the string's lapse)
const RUN: int = BASE + 12      # his run against the rival: up one for each light or flurry blow he lands, down for each that lands on him
const BLOWS: int = BASE + 13    # blows he has thrown in this brawl
const HOLD_AT: int = BASE + 14  # the live tick his heavy's press went down; 0 none
const LAST_AT: int = BASE + 15  # S.tick of his last attack press in this brawl
const GUT: int = BASE + 16      # 1 when his last blow went to the gut (Combat's sequence rule: no two gut blows running)
const AI_NEXT: int = BASE + 17  # the AI: S.tick of its next choice
const AI_LEFT: int = BASE + 18  # ... the lights left in its string; -1 after a guard: its next choice is an attack
const AI_CLOSE: int = BASE + 19 # ... 1 while its string still has its closing heavy to weigh
const AI_GUARD: int = BASE + 20 # ... S.tick its guard ends
const AI_HOLD: int = BASE + 21  # ... the live tick until which it holds its heavy's button
const STR_K: int = BASE + 22   # blows he has thrown in his string
const PB_AT: int = BASE + 23   # the AI: S.tick of the last light of the rival's it weighed a perfect block against
const REV_AT: int = BASE + 24  # ... and S.tick it last weighed a reversal
const CHG_N: int = BASE + 25   # the number of the exchange his far charge's arrival started (its first blow's worth)
const ANSWERED: int = BASE + 26 # 1 once the AI rival has answered his running string (melee-press-feel.md section 9c)
const AI_ANS_AT: int = BASE + 27 # the AI: S.tick its answer comes (its reaction time after the blow that called for it); 0 none
const LL_AT: int = BASE + 28    # S.tick his last light or flurry blow landed; 0 none
const AI_AFTER: int = BASE + 29 # the AI: 1 when a close has landed on it and its answer, a heavy as its stagger ends, is still to weigh
const TRADE_T0: int = BASE + 30 # on the exchange's attacker, for both: S.tick the running trade began; 0 when none is on
const TRADE_WIN: int = BASE + 31 # ... and whose next landed blow closes a trade that reached its limit: his slot plus 1; 0 none
const LAST_CLOSER: int = BASE + 32 # on the exchange's attacker, for both: who made the last close in this brawl, 1 the attacker, 2 the other; 0 nobody yet
const SAFE_UNTIL: int = BASE + 33 # S.tick until which he cannot be closed on again (closeGuardTicks after he recovers from a close); -1 while that close's stagger lasts
const END: int = BASE + 34
const LIGHT: int = 0
const FLURRY: int = 1
const HEAVY: int = 2
const KINDS: Array = ["light", "flurry", "heavy"]

## True while tick() runs: a blow thrown there is scheduled on a clock that already holds this tick. Not state.
static var _inTick: bool = false


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("brawl", {})


static func on() -> bool:
	return DirInterrupt.on() and cfg().get("enabled", false)


static func _size(f) -> void:
	DirAlchemy._size(f)
	if f.act.dirI.size() < END:
		f.act.dirI.resize(END)


static func _g(f, k: int) -> int:
	_size(f)
	return f.act.dirI[k]


static func _s(f, k: int, v: int) -> void:
	_size(f)
	f.act.dirI[k] = v


## The live clock in ticks (it stops in a hit-stop, as the exchange's clock does).
static func _now(S: SimState) -> int:
	return int(round(S.T * DirData.TICKS_PER_SEC))


## True when ex is a brawl.
static func isBrawl(ex) -> bool:
	return ex != null and ex.tpl == TPL


## True while a brawl is the running exchange and f is in it.
static func inBrawl(S: SimState, f) -> bool:
	var ex = S.dirS.ex
	return isBrawl(ex) and (f == ex.A or f == ex.D)


## For QA's scripts: f has a blow on his line, or his line is not free yet (a blow's end, a reel, a stagger).
static func busy(S: SimState, f) -> bool:
	return inBrawl(S, f) and not _free(S, f)


## For QA's scripts: the S.tick f's blow on its way lands, counted as the director counts it, or -1. (B2 adds his beat point.)
static func beatAt(S: SimState, f) -> int:
	if not inBrawl(S, f) or _g(f, LINE) != 1:
		return -1
	return S.tick + maxi(0, _g(f, CONTACT) - _now(S))


static func _free(S: SimState, f) -> bool:
	return _g(f, LINE) == 0 and S.tick >= _g(f, FREE_AT) and _now(S) >= _g(f, REEL_AT) and f.stunTicks <= 0


## An event for QA, Animation and VFX with no line in the core: a cue named `name`. The caller sets its other fields.
static func _ev(S: SimState, f, name: String, text: String = ""):
	SimFx.cue(S, f, name, text, "")
	return S.out.fx[S.out.fx.size() - 1]


## The ticks a press that arrives now waited in a freeze (Controls' rule): a player's is his intent's; the AI presses on a live tick.
static func _waited(f) -> int:
	return clampi(f.input.waited, 0, 15) if f.ai == null else 0


# ---------------------------------------------------------------- the start and the end

## Whether the exchange being started (DirExchange._start) is a brawl: a light or a heavy with no opening to spend,
## that is not the buried follow-up, a meeting or a charge's arrival, against a rival who stood free and holds the
## press or the guard stance. Everything else keeps its template: those are set pieces.
static func starts(S: SimState, ex, kind: String, opn: int, fu: bool, dState: String) -> bool:
	if not on() or kind == "sig" or opn != 0 or fu or dState != "free":
		return false
	if DirExchange.planDefStance >= 0 or DirExchange.planMeet or DirExchange.planCharge or DirData.contact().is_empty():
		return false
	return ex.D.stance <= 1.0 and ex.D.rush == null and DirBands.band(ex.A, ex.D) == DirBands.CLOSE


## The brawl begins with A's press (DirExchange._start, in place of the plan). An attacker who arrived by a lunge
## wound his heavy up on the way.
static func begin(S: SimState, ex, kind: String) -> void:
	var c: Dictionary = cfg()
	ex.tpl = TPL
	ex.branch = ""
	ex.tag = "BRAWL"
	ex.loser = -1
	for f in [ex.A, ex.D]:
		_size(f)
		for k in range(BASE, END):
			f.act.dirI[k] = 0
	SimAct.clear(ex.D)   # no request waits in a brawl: a press is a blow, or it is spent
	# Both are held from now: the speed either had as it began is gone (a rival locked while flying would drift out of reach).
	for f in [ex.A, ex.D]:
		f.vx = 0.0
		f.vy = 0.0
	var e = _ev(S, ex.A, "brawl_start")
	e.target = float(S.fighters.find(ex.D))
	e.n = ex.n
	e.amount = DirBands.dist(ex.A, ex.D)
	SimEvents.feed(S, "BRAWL", ex.A.name + " and " + ex.D.name + " in reach: every press is a blow")
	var weight: int = SimAct.HEAVY if kind == "heavy" else SimAct.LIGHT
	var p: int = DirExchange.planTick if DirExchange.planTick >= 0 else S.tick - _waited(ex.A)
	_s(ex.A, LAST_AT, S.tick)
	if weight == SimAct.LIGHT:
		_s(ex.A, LAST_TAP, p)
	var lead: int = _throw(S, ex.A, weight, p, true, DirExchange.engaging)
	# He steps in to striking distance as the blow comes (the strike itself would place him there in one tick).
	var ct: Dictionary = DirData.contact()
	if absf(SimWrap.sdx(ex.A.x, ex.D.x)) > float(ct.reach) or absf(ex.A.y - ex.D.y) > DirMelee.HEIGHT_TOL:
		var r := SimState.Rush.new()
		r.tgt = ex.D
		r.off = DirMelee.sideOff(ex.A, ex.D, float(ct.offset), "own")
		r.end = S.T + float(mini(lead, int(c.stepInTicks))) * SimConst.DT
		ex.A.rush = r
		SimFx.rush(S, ex.A, ex.D, S.tick + mini(lead, int(c.stepInTicks)))


## The brawl is over, and why: knockback, launch, apart, idle, left, burst, perfect_block, reversal, break, finisher,
## signature. The event goes out once; the lines stop. A set piece that took it over plays on in the same exchange.
static func over(S: SimState, ex, why: String) -> void:
	if not isBrawl(ex) or ex.branch != "":
		return
	ex.branch = why
	var e = _ev(S, ex.A, "brawl_end", why)
	e.n = ex.n
	e.amount = float(int(round(ex.t * DirData.TICKS_PER_SEC)))
	e.x = float(_g(ex.A, BLOWS))
	e.y = float(_g(ex.D, BLOWS))
	for f in [ex.A, ex.D]:
		_s(f, LINE, 0)
		_s(f, HELD_P, 0)
		_strEnd(f)
	SimEvents.feed(S, "BRAWL ENDS", why + ": " + str(_g(ex.A, BLOWS)) + " and " + str(_g(ex.D, BLOWS)) + " blows in " + str(int(e.amount)) + " ticks")


## ... and the exchange ends with it, now.
static func end(S: SimState, ex, why: String) -> void:
	if S.dirS.ex != ex:
		return
	over(S, ex, why)
	for b in ex.beats:
		b.done = true
	var slide = ex.A.rush   # the exchange's end drops its attacker's move: a knock-back's slide is kept, whoever was sent
	DirExchange.endEx(S, ex)
	if slide != null and slide.tgt == null and (why == "knockback" or why == "launch"):
		ex.A.rush = slide


## The pause after a brawl (DirExchange.endEx): none, except after a launch or a set piece (melee-press-feel.md 2b).
static func coolAfter(ex) -> float:
	return DirExchange.cooldownAfter(ex) if (ex.branch == "launch" or ex.branch == "break" or ex.branch == "finisher") else 0.0


## True while the brawl keeps the exchange alive with no beat pending (DirExchange.dirUpdate).
static func holds(S: SimState, ex) -> bool:
	return isBrawl(ex) and ex.branch == "" and not ex.cancel and S.game.ko == null


## A set piece has taken the exchange over: a finisher, or a pending beat that is not a brawl's blow (a break launch).
static func _setPiece(ex) -> bool:
	for b in ex.beats:
		if not b.done and not (b.op == "strike" and b.args != null and b.args.get("brawl", false)):
			return true
	return DirExchange.finisherPlanned(ex)


## True when o is a shooter to f (melee-press-feel.md section 9d, ruling 5): he has fired in the last
## shooter.firedTicks and has landed no melee blow on f in the last shooter.noMeleeTicks.
static func shooter(S: SimState, f, o) -> bool:
	var sh: Dictionary = cfg().get("shooter", {})
	if sh.is_empty() or not on() or not DirBlast.on():
		return false
	return S.tick - DirInterrupt.gi(o, DirInterrupt.BLAST_AT) <= int(sh.firedTicks) and S.tick - DirInterrupt.gi(f, DirInterrupt.HIT_AT) > int(sh.noMeleeTicks)


## What a heavy shot is worth while the brawl is on (ruling 5): its kind's damage times the brawl's scale times
## shotHeavyMul, as a heavy blow is. DirBlast multiplies by this where it reads the kind's damage. Bolts keep their value.
static func shotScale() -> float:
	return float(cfg().damageMul) * float(cfg().shotHeavyMul) if (on() and cfg().has("shotHeavyMul")) else 1.0


## The AI's reversal in a brawl (DirInterrupt.onBlock): it weighs one on a block at most once in aiReversalEveryTicks.
static func revDue(S: SimState, f) -> bool:
	if S.tick - _g(f, REV_AT) < int(cfg().aiReversalEveryTicks):
		return false
	_s(f, REV_AT, S.tick)
	return true


## Which of the exchange's interrupts a brawl allows (DirData.allows).
static func allows(name: String) -> bool:
	return (cfg().get("interrupts", []) as Array).has(name)


static func _strEnd(f) -> void:
	_s(f, STR_ON, 0)
	_s(f, ANSWERED, 0)
	_s(f, STR_K, 0)
	_s(f, STRING_N, 0)
	_s(f, RUN, 0)
	DirInterrupt.si(f, DirInterrupt.LANDED, 0)


# ---------------------------------------------------------------- what a blow outside a brawl is worth

## A's far charge arrived and started exchange ex from its template (DirExchange._start).
static func noteCharge(A, ex) -> void:
	_s(A, CHG_N, ex.n)


## A blow is worth its form wherever it is thrown (melee-press-feel.md section 9b). While the brawl is on, a strike
## of a planned exchange does: a light-class blow, a brawl light's share of its damage (damageMul); a heavy-class
## blow (the class heavy, or the data heavy's damage), a brawl heavy's (damageMul times heavyMul); a chain link's
## blow, one brawl light. The exchange's first damaging blow is worth more where it answers something: a riposte's
## light, the answering blow of a dodge template whatever its button, and a light charge's arrival are worth a skill
## strike (skillMul brawl lights); a heavy charge's arrival is a heavy held to full. Signatures, finishers and the
## blow on a buried rival keep their damage. b: the beat; dmg: its damage as planned.
static func worth(S: SimState, ex, b, dmg: float) -> float:
	if not on() or isBrawl(ex) or ex.kind == "sig" or dmg <= 0.0 or ex.tpl == DirBury.TPL or DirExchange.finisherPlanned(ex):
		return dmg
	var c: Dictionary = cfg()
	var lightB: float = float(c.light.damage)
	var heavyB: float = float(c.heavy.damage)
	var scale: float = float(c.damageMul)
	if b.op == "chainStrike":
		return lightB * scale   # a link is a pressed light: the stream
	var cls: String = String(b.args.o.get("class", "")) if (b.args != null and b.args.get("o") is Dictionary) else ""
	var heavy: bool = cls == "heavy" or dmg >= 0.9 * heavyB
	var first: bool = true
	for x in ex.beats:
		if x != b and x.done and (x.op == "chainStrike" or (x.op == "strike" and x.args != null and float(x.args.get("dmg", 0.0)) > 0.0)):
			first = false
			break
	var mine: bool = b.args != null and String(b.args.get("a", "A")) == "A"
	var charge: bool = first and mine and _g(ex.A, CHG_N) == ex.n
	if first and ex.tpl == "dodge":
		return dmg * (lightB / heavyB if heavy else 1.0) * scale * float(c.skillMul)   # the one answering blow, whatever its button
	if first and not heavy and (charge or ex.tag == "RIPOSTE"):
		return dmg * scale * float(c.skillMul)
	if charge:
		return dmg * scale * float(c.heavyMul) * float(c.heldMul)
	return dmg * scale * (float(c.heavyMul) if heavy else 1.0)


# ---------------------------------------------------------------- a press

## An attack press of f's (DirExchange.requestAttack, and the layout's hold edge). True when the brawl took it.
static func takes(S: SimState, f, kind: String) -> bool:
	if not inBrawl(S, f):
		return false
	var ex = S.dirS.ex
	if ex.branch != "" or ex.cancel or _setPiece(ex):
		return true   # a set piece is playing: the press is spent
	if kind == "sig":
		# The signature is its own exchange: the brawl gives way when it can start, and the request then starts it.
		if not _free(S, f) or (not SimFighter.sigFree(f) and (f.ki < 45.0 or S.T < f.sigReadyT)):
			var a = _ev(S, f, "press_ack", "refused")
			a.n = S.tick
			return true
		end(S, ex, "signature")
		return false
	if f.act.mode == 1:
		# B1 is the martial stance. A press with the energy family held is not a brawl blow, as it was no blow inside an
		# exchange: it is spent, and says so. What the energy stance does in reach comes with the stances (B6).
		var en = _ev(S, f, "press_ack", "energy")
		en.n = S.tick
		return true
	press(S, f, SimAct.HEAVY if kind == "heavy" else SimAct.LIGHT)
	return true


## One press: a blow at once if his line is free, else held for heldPressTicks (the latest only).
static func press(S: SimState, f, weight: int) -> void:
	var c: Dictionary = cfg()
	var p: int = S.tick - _waited(f)
	_s(f, LAST_AT, S.tick)
	if weight == SimAct.LIGHT:
		var last: int = _g(f, LAST_TAP)
		var gap: int = p - last
		_s(f, TAP_GAP, clampi(gap, int(c.flurry.minGap), int(c.flurry.maxGap)) if (last > 0 and gap <= int(c.flurry.maxGap)) else 0)
		_s(f, LAST_TAP, p)
		if _g(f, TAP_GAP) > 0 and _g(f, LINE) == 0 and _g(f, KIND) != HEAVY:
			_s(f, FREE_AT, mini(_g(f, FREE_AT), last + _g(f, TAP_GAP)))   # the flurry follows the taps: the blow before lasts one tap gap
	elif _g(f, LINE) == 0 and _g(f, KIND) != HEAVY:
		_s(f, FREE_AT, mini(_g(f, FREE_AT), _g(f, LAND_AT) + int(c.light.recover)))   # after a light his line is free for a heavy light.recover after its contact
	if not _free(S, f):
		_s(f, HELD_P, weight + 1)
		_s(f, HELD_AT, p)
		var a = _ev(S, f, "press_ack", "held")
		a.n = p
		return
	_throw(S, f, weight, p, false, false)


## f throws the blow his press asked for. paid: the heavy's ki was paid as the exchange started. arrived: he came by a
## lunge, so a heavy only has to land. Returns the live ticks to its contact.
static func _throw(S: SimState, f, weight: int, p: int, paid: bool, arrived: bool) -> int:
	var ex = S.dirS.ex
	var c: Dictionary = cfg()
	var now: int = _now(S)
	var o = ex.D if f == ex.A else ex.A
	var role: String = "A" if f == ex.A else "D"
	if weight == SimAct.HEAVY and not paid:
		if f.ki < float(c.heavy.ki):
			weight = SimAct.LIGHT   # no ki for a heavy: it is a light, as outside a brawl
		else:
			f.ki -= float(c.heavy.ki)
	var kind: int = HEAVY if weight == SimAct.HEAVY else (FLURRY if _g(f, TAP_GAP) > 0 else LIGHT)
	# A new string of his: an exchange number of its own, for the keyed draws and the brink chapter's "a later exchange".
	if _g(f, STR_ON) == 0:
		_s(f, STR_ON, 1)
		_s(f, STR_K, 0)
		_s(f, STRING_N, 0)
		DirInterrupt.si(f, DirInterrupt.LANDED, 0)
		if _g(f, BLOWS) + _g(o, BLOWS) > 0:
			_newString(S, ex)
	var lead: int
	var length: int
	var dmg: float
	var stop: int
	if kind == HEAVY:
		lead = int(c.heavy.landTicks) + (0 if arrived else int(c.heavy.windupTicks))
		length = 1 << 20   # his line frees a recovery after the contact (contact)
		dmg = float(c.heavy.damage) * float(c.damageMul) * float(c.heavyMul)   # a heavy, an ender: heavyMul brawl heavies
		stop = int(c.hitstop.heavy)
		_s(f, HOLD_AT, 0 if arrived else now)
	else:
		lead = int(c.light.contactTicks)
		length = _g(f, TAP_GAP) if kind == FLURRY else int(c.light.blowTicks)
		dmg = float(c.light.damage) * float(c.damageMul) * (_flurryMul(_g(f, TAP_GAP)) if kind == FLURRY else 1.0)
		stop = int(c.hitstop.light)
		_s(f, HOLD_AT, 0)
	# The press behind the blow, for the launch's earners: its weight, its stick and its intent. Its rhythm is the brawl's own.
	var pp: int = DirAlchemy.last(S, f)
	pp = (pp & ~(3 << 8)) if (pp >= 0 and (pp & 1) == weight) else weight
	DirInterrupt.si(f, DirInterrupt.PHRASE_P, pp)
	var k: int = _g(f, STR_K) + 1   # its place among the blows of his string
	_s(f, STR_K, k)
	var ender: bool = kind == HEAVY and _g(f, STRING_N) >= int(c.enderAfter)
	var o2 := {"class": "heavy" if kind == HEAVY else "blow", "stop": float(stop) / DirData.TICKS_PER_SEC, "big": kind == HEAVY, "kb": float(c.recoil)}
	# The AI weighs a perfect block against a light at most once in aiPerfectEveryTicks (a fresh guard press cannot be
	# mashed), and against every heavy.
	if kind != HEAVY:
		if S.tick - _g(o, PB_AT) < int(c.aiPerfectEveryTicks):
			o2["weighed"] = true
		else:
			_s(o, PB_AT, S.tick)
	var args := {"a": role, "d": "D" if role == "A" else "A", "dmg": dmg, "o": o2, "brawl": true, "bk": kind,
		"style": "heavy" if kind == HEAVY else "speed", "grade": "none", "k": k, "n": k, "closing": kind != HEAVY and _closes(S, ex, f),
		"charge": 0.0, "hand": "r" if (k % 2) == 1 else "l", "ender": ender}
	var piece: String = _piece(S, f, weight, ((pp >> 2) & 3) == 2, ender)
	if piece != "":
		args["piece"] = piece
	# Two light blows that land within tradeTicks of each other are a trade: both land (melee-press-feel.md section 7).
	# Each beat says so, and names the other's piece, so the pair can be staged as one move.
	if kind != HEAVY and _g(o, LINE) == 1 and _g(o, KIND) != HEAVY and absi(_g(o, CONTACT) - (now + lead)) <= int(c.tradeTicks):
		for b in ex.beats:
			if not b.done and b.op == "strike" and b.args != null and b.args.get("brawl", false) and String(b.args.a) != role:
				b.args["trade"] = true
				b.args["tradeWith"] = piece
				args["trade"] = true
				args["tradeWith"] = String(b.args.get("piece", ""))
		var tr = _ev(S, f, "trade")
		tr.target = float(S.fighters.find(o))
		tr.n = S.tick + lead
	DirExchange.schedule(ex, ex.t + (float(lead + (0 if _inTick else 1)) - 0.25) / DirData.TICKS_PER_SEC, "strike", args)
	_s(f, LINE, 1)
	_s(f, KIND, kind)
	_s(f, CONTACT, now + lead)
	_s(f, FREE_AT, maxi(S.tick + 1, p + length))
	_s(f, LAND_AT, S.tick)
	_s(f, HELD_P, 0)
	_s(f, BLOWS, _g(f, BLOWS) + 1)
	var e = _ev(S, f, "blow", KINDS[kind])
	e.target = float(S.fighters.find(o))
	e.n = S.tick + lead
	e.amount = float(p)
	e.dur = float(lead)
	return lead


## A string starts inside a running brawl: the exchange takes a new number, the brink's and the wounds' marks are
## taken again, and the blows that have landed are dropped from its list.
static func _newString(S: SimState, ex) -> void:
	S.dirS.exN += 1
	ex.n = S.dirS.exN
	ex.startBrink = 0
	for s in range(S.fighters.size()):
		if S.fighters[s].brink:
			ex.startBrink |= 1 << s
	SimWounds.onExchangeStart(S, ex)
	DirAlchemy.markFlow(ex.A)
	DirAlchemy.markFlow(ex.D)
	var keep: Array = []
	for b in ex.beats:
		if not b.done:
			keep.append(b)
	ex.beats = keep


## A flurry blow's share of a light, by its tap gap: flurry.mul's points, straight lines between them.
static func _flurryMul(gap: int) -> float:
	var pts: Array = cfg().flurry.mul
	var g: float = float(gap)
	if g <= float(pts[0][0]):
		return float(pts[0][1])
	for i in range(1, pts.size()):
		if g <= float(pts[i][0]):
			var x0: float = float(pts[i - 1][0])
			var x1: float = float(pts[i][0])
			return float(pts[i - 1][1]) + (float(pts[i][1]) - float(pts[i - 1][1])) * (g - x0) / maxf(0.001, x1 - x0)
	return float(pts[pts.size() - 1][1])


## The piece for his blow, from Combat's pools. Combat's sequence rules that the pieces' data can say are hard rules
## here: never one of his last two pieces (DirRecipe.pick, so never three of one running), and no two blows running to
## the gut.
static func _piece(S: SimState, f, weight: int, toward: bool, ender: bool) -> String:
	if not DirRecipe.on():
		return ""
	var pool: String = ("power.last" if ender else "combo.accent") if weight == SimAct.HEAVY else ("blur.toward" if toward else "blur.base")
	var pieces = DirRecipe.rec().get("pieces", {})
	var id: String = ""
	var p1: int = f.act.dirI[DirAlchemy.PIECE_1]
	var p2: int = f.act.dirI[DirAlchemy.PIECE_2]
	for salt in range(6):
		f.act.dirI[DirAlchemy.PIECE_1] = p1
		f.act.dirI[DirAlchemy.PIECE_2] = p2
		id = DirRecipe.pick(S, f, pool, _g(f, BLOWS) * 8 + salt)
		var pc = pieces.get(id) if pieces is Dictionary else null
		var gut: bool = pc is Dictionary and String(pc.get("target", "")) == "gut"
		if not (gut and _g(f, GUT) == 1):
			_s(f, GUT, 1 if gut else 0)
			return id
	_s(f, GUT, 0)
	return id


# ---------------------------------------------------------------- the run and the trade (melee-press-feel.md section 3)

## True when f's next light or flurry blow that lands is the close: his run is at runToClose, or a trade that reached
## its limit broke his way. Never while the rival is still in a close's stagger, or inside closeGuardTicks of his
## recovery from it (section 9d): f's run still counts then, and a run of runToClose closes on his first blow after it.
static func _closes(S: SimState, ex, f) -> bool:
	var o = ex.D if f == ex.A else ex.A
	if _g(o, SAFE_UNTIL) < 0 or S.tick < _g(o, SAFE_UNTIL):
		return false
	return _g(f, RUN) >= int(cfg().flurry.runToClose) or _g(ex.A, TRADE_WIN) == (1 if f == ex.A else 2)


## The trade's clock starts again: after a close, a stagger, a real answer, and when the trade stops.
static func _tradeReset(ex) -> void:
	_s(ex.A, TRADE_T0, 0)
	_s(ex.A, TRADE_WIN, 0)


## Once a live tick: a run lapses runLapseTicks after his last landed blow. A trade is on while both have landed a
## light or a flurry blow inside that time; it cannot pass tradeMaxTicks without a close. At the limit it breaks, on
## the first live tick at or after it (a hit-stop holds the sim, and so the break): a lead of more than levelWithin
## takes the close, and runs within it are a level trade, settled by a seeded draw in which the fighter who made the
## last close in this brawl has `momentum`; when nobody has closed yet the odds are even (melee-press-feel.md section
## 9d, ruling 3). His next landed blow is the close.
static func _tradeTick(S: SimState, ex) -> void:
	var fl: Dictionary = cfg().flurry
	var lapse: int = int(fl.runLapseTicks)
	var on: bool = true
	for f in [ex.A, ex.D]:
		var fresh: bool = _g(f, LL_AT) > 0 and S.tick - _g(f, LL_AT) <= lapse
		if not fresh:
			on = false
			_s(f, RUN, 0)
	if not on:
		if _g(ex.A, TRADE_T0) != 0 or _g(ex.A, TRADE_WIN) != 0:
			_tradeReset(ex)
		return
	if _g(ex.A, TRADE_T0) == 0:
		_tradeReset(ex)
		_s(ex.A, TRADE_T0, S.tick)
		return
	if _g(ex.A, TRADE_WIN) != 0 or S.tick - _g(ex.A, TRADE_T0) < int(fl.tradeMaxTicks):
		return
	var w: int = 0
	var last: int = _g(ex.A, LAST_CLOSER)
	var how: String = "lead"
	if absi(_g(ex.A, RUN) - _g(ex.D, RUN)) > int(fl.levelWithin):
		w = 1 if _g(ex.A, RUN) > _g(ex.D, RUN) else 2
	else:
		how = "draw"
		var pA: float = 0.5 if last == 0 else (float(fl.momentum) if last == 1 else 1.0 - float(fl.momentum))
		w = 1 if SimRng.keyed(int(S.game.seed), "brawl.trade", S.dirS.exN * 4096 + (_g(ex.A, TRADE_T0) & 4095)) < pA else 2
	_s(ex.A, TRADE_WIN, w)
	var who = ex.A if w == 1 else ex.D
	var e = _ev(S, who, "trade_break")
	e.target = float(S.fighters.find(ex.D if w == 1 else ex.A))
	e.n = S.tick - _g(ex.A, TRADE_T0)
	# For QA: the limit; the two runs at the break, his and the rival's; how it was settled (lead or draw); and who made
	# the last close in this brawl (0 nobody yet, 1 he did, 2 the rival did: a draw with 2 is momentum changing hands).
	e.amount = float(int(fl.tradeMaxTicks))
	e.x = float(_g(who, RUN))
	e.y = float(_g(ex.D if w == 1 else ex.A, RUN))
	e.text = how
	e.k = 0.0 if last == 0 else (1.0 if last == w else 2.0)
	SimEvents.feed(S, "THE TRADE BREAKS", who.name + "'s next blow that lands closes it, after " + str(S.tick - _g(ex.A, TRADE_T0)) + " ticks")


# ---------------------------------------------------------------- a blow lands

## The brawl's strike beat runs (DirExchange.runBeat): the blow lands, and the line, the string and the close follow.
static func contact(S: SimState, ex, b) -> void:
	var a = b.args
	var f = ex.A if a.a == "A" else ex.D
	var o = ex.D if a.a == "A" else ex.A
	var c: Dictionary = cfg()
	var kind: int = int(a.bk)
	_s(f, LINE, 0)
	_s(f, HOLD_AT, 0)
	_s(f, LAND_AT, S.tick)
	if kind == HEAVY:
		_s(f, FREE_AT, S.tick + int(c.heavy.recover))   # his line is free this long after a heavy that lands (its follow-through is animation)
	if ex.branch != "" or f.stunTicks > 0 or f.state != "locked" or o.state != "locked":
		if kind == HEAVY:
			_s(f, FREE_AT, S.tick + int(c.heavy.recoverWhiff))   # a heavy that met nothing: the punish
		return   # he was staggered, or one of them was sent off, before it landed: the blow is lost
	# A blow lands only inside the strike's placement limit (contact.reach times placementReaches): past it, it meets nothing.
	var ct: Dictionary = DirData.contact()
	var lim: float = float(ct.reach) * float(ct.placementReaches)
	if absf(SimWrap.sdx(f.x, o.x)) > lim or absf(f.y - o.y) > lim:
		if kind == HEAVY:
			_s(f, FREE_AT, S.tick + int(c.heavy.recoverWhiff))
		SimEvents.feed(S, "OUT OF REACH", f.name + "'s blow meets nothing")
		return
	ex.kind = "heavy" if kind == HEAVY else "light"   # the core reads the exchange's kind as the blow's weight
	ex.sA = ex.A.stance
	ex.sD = ex.D.stance
	if o.stance == 1.0 and _g(o, LINE) != 0:
		# A fighter with a blow of his own on its way is not guarding, whatever he holds.
		if o == ex.A:
			ex.sA = 0.0
		else:
			ex.sD = 0.0
	var landed0: int = DirInterrupt.gi(f, DirInterrupt.LANDED)
	DirMelee.strike(S, ex, f, o, float(a.dmg), a.o)
	f.ambush = false   # an ambush is its first blow
	if S.dirS.ex != ex or ex.cancel or ex.branch != "" or S.game.ko != null:
		return   # a perfect block took the exchange over
	if _setPiece(ex):
		over(S, ex, "break")   # the blow broke a limb: the break launch plays in this exchange
		return
	if DirInterrupt.gi(f, DirInterrupt.LANDED) == landed0:
		# Blocked: it chips, and no run changes. A heavy on a guard staggers the blocker in place (the set guard and its
		# 40 ticks down are B3).
		if kind == HEAVY:
			o.stunTicks = maxi(o.stunTicks, int(c.heavy.staggerTicks))
			_drop(S, ex, o)
			_tradeReset(ex)
			var gb = _ev(S, o, "guard_break")
			gb.target = float(S.fighters.find(f))
			gb.n = int(c.heavy.staggerTicks)
			SimEvents.feed(S, f.name + " BREAKS THE GUARD", o.name + " staggers in place for " + str(int(c.heavy.staggerTicks)) + " ticks")
		return
	_s(f, STRING_N, _g(f, STRING_N) + 1)
	if kind == HEAVY:
		_s(o, RUN, 0)   # a real answer clears his run, and the trade's clock starts again
		_tradeReset(ex)
		_heavyLanded(S, ex, f, o, a)
		return
	# A light or a flurry blow. The run (melee-press-feel.md section 3): his goes up one and the rival's comes down by
	# replyTakes, never below 0. At a run of runToClose, or when a trade that reached its limit broke his way, this blow
	# is the close. Otherwise the rival reels, and his next blow waits for the reel's end.
	var closing: bool = _closes(S, ex, f)
	_s(f, LL_AT, S.tick)
	if not closing:
		if o.stunTicks <= 0 or bool(c.flurry.staggeredAddsRun):
			_s(f, RUN, _g(f, RUN) + 1)   # a blow on a staggered fighter does its damage and adds nothing to the run: a close does not start the next lead
		_s(o, RUN, maxi(0, _g(o, RUN) - int(c.flurry.replyTakes)))
		_reel(S, o, int(c.flurry.reelTicks))
		return
	# The flurry's close: a stagger in place, decisive at half a set-up. The brawl stays together; his run is spent, the
	# rival's is cleared, his string is closed, and the trade's clock starts again.
	_s(f, RUN, 0)
	_s(o, RUN, 0)
	_tradeReset(ex)
	_s(ex.A, LAST_CLOSER, 1 if f == ex.A else 2)   # the momentum of a level trade is his
	_s(o, SAFE_UNTIL, -1)   # no second close on him until closeGuardTicks after he recovers from this one
	if o.ai != null:
		_s(o, AI_AFTER, 1)   # its answer to being closed on: a heavy as its stagger ends, at its level's rate
	o.stunTicks = maxi(o.stunTicks, int(c.flurry.staggerTicks))
	_drop(S, ex, o)
	_strEnd(f)
	var st = _ev(S, o, "stagger", "flurry")
	st.target = float(S.fighters.find(f))
	st.n = int(c.flurry.staggerTicks)
	SimEvents.feed(S, f.name + " FLURRY CLOSES", o.name + " staggers in place for " + str(int(c.flurry.staggerTicks)) + " ticks")
	DirExchange.decisive(S, ex, f, o, "knockback", "blurPlain")
	if _setPiece(ex):
		over(S, ex, "finisher")


## A heavy landed clean. The ender knocks back, or launches when a launch is earned (DirLaunch.earned: held to full,
## or his flow). A lone heavy staggers in place; held to full with the stick it launches.
static func _heavyLanded(S: SimState, ex, f, o, a) -> void:
	var c: Dictionary = cfg()
	var pp: int = DirInterrupt.gi(f, DirInterrupt.PHRASE_P)
	var full: bool = float(a.get("charge", 0.0)) >= 1.0
	if bool(a.ender) or (full and (pp & DirAlchemy.INTENT) != 0):
		DirMelee.launchBeat(S, ex, f, o, float(c.heavy.force), false, null)
		if S.dirS.ex != ex:
			return
		if _setPiece(ex):
			over(S, ex, "finisher")   # the win finishes him: the finisher plays in this exchange
			return
		end(S, ex, "launch" if DirInterrupt.gi(ex.A, DirInterrupt.LAST_END) == DirInterrupt.END_LAUNCH else "knockback")
		return
	o.stunTicks = maxi(o.stunTicks, int(c.heavy.staggerTicks))
	_drop(S, ex, o)
	var st = _ev(S, o, "stagger", "heavy")
	st.target = float(S.fighters.find(f))
	st.n = int(c.heavy.staggerTicks)


## f reels for `ticks`: his next blow waits for the reel's end (a press in it is held). A blow already on its way
## lands on time, so two blows that meet both land, in order.
static func _reel(S: SimState, f, ticks: int) -> void:
	_s(f, REEL_AT, maxi(_g(f, REEL_AT), _now(S) + ticks))


## f was staggered: his blow on its way is lost, and his string is over.
static func _drop(S: SimState, ex, f) -> void:
	var role: String = "A" if f == ex.A else "D"
	for b in ex.beats:
		if not b.done and b.op == "strike" and b.args != null and b.args.get("brawl", false) and String(b.args.a) == role:
			b.done = true
	_s(f, LINE, 0)
	_s(f, HOLD_AT, 0)
	_s(f, HELD_P, 0)
	_s(f, FREE_AT, mini(_g(f, FREE_AT), S.tick))
	_strEnd(f)


# ---------------------------------------------------------------- once a live tick

## Before the exchange's beats (DirExchange.dirUpdate): what ends the brawl, held heavies, held presses, the magnet.
static func tick(S: SimState, ex) -> void:
	if not isBrawl(ex) or ex.branch != "":
		return
	if ex.cancel:
		over(S, ex, "interrupt")
		return
	if _setPiece(ex):
		over(S, ex, "finisher")
		return
	var c: Dictionary = cfg()
	var now: int = _now(S)
	_inTick = true
	for f in [ex.A, ex.D]:
		var o = ex.D if f == ex.A else ex.A
		if f.state != "locked" or o.state != "locked":
			_inTick = false
			end(S, ex, "apart")
			return
		if not SimAct.peek(f).is_empty():
			SimAct.clear(f)
		if _g(f, SAFE_UNTIL) < 0 and f.stunTicks <= 0:
			_s(f, SAFE_UNTIL, S.tick + int(c.flurry.closeGuardTicks))   # he has recovered from a close: he cannot be closed on again for this long
		# A boost with the stick away leaves, at the dodge-cancel's price and by its rules (a dodge tap is DirInterrupt's).
		if ex.t > SimConst.DT * 1.5 and f.input.sprint and f.stunTicks <= 0 and f.input.mx * SimMathx.jsign(SimWrap.sdx(f.x, o.x)) < -SimAct.awayDead and DirInterrupt.dodgeCancel(S, ex, f):
			_inTick = false
			return
		# A heavy still held as its wind-up ends waits for the release; it is let go, or lets go at heldMaxTicks.
		if _g(f, LINE) == 1 and _g(f, KIND) == HEAVY and _g(f, HOLD_AT) > 0 and now - _g(f, HOLD_AT) == int(c.heavy.windupTicks) and f.input.heavyHeld:
			_hold(S, ex, f, true)
		elif _g(f, LINE) == 2 and (not f.input.heavyHeld or now - _g(f, HOLD_AT) >= int(c.heavy.heldMaxTicks)):
			_hold(S, ex, f, false)
		# A held press is thrown as his line frees, or lapses.
		var hp: int = _g(f, HELD_P)
		if hp != 0:
			if S.tick - _g(f, HELD_AT) > int(c.heldPressTicks):
				_s(f, HELD_P, 0)
				var a = _ev(S, f, "press_ack", "lapsed")
				a.n = _g(f, HELD_AT)
			elif _free(S, f):
				_throw(S, f, hp - 1, _g(f, HELD_AT), false, false)
		# His string is over when nothing of his was thrown or landed for a while.
		if _g(f, STR_ON) == 1 and _g(f, LINE) == 0 and S.tick - _g(f, LAND_AT) > int(c.stringLapseTicks):
			_strEnd(f)
	_inTick = false
	_tradeTick(S, ex)
	# The magnet: they are held at striking distance, at one height. Past breakBh it lets go.
	var d: float = SimWrap.sdx(ex.A.x, ex.D.x)
	if DirBands.dist(ex.A, ex.D) > float(c.breakBh) * DirInterrupt.BH:
		end(S, ex, "apart")
		return
	var ct: Dictionary = DirData.contact()
	var pull: float = float(c.pullBhPerSec) * DirInterrupt.BH * SimConst.DT * 0.5
	if ex.A.rush == null and ex.D.rush == null:
		if absf(d) > float(ct.offset):
			var px: float = minf((absf(d) - float(ct.offset)) * 0.5, pull)
			ex.A.x = SimWrap.wrap(ex.A.x + SimMathx.jsign(d) * px)
			ex.D.x = SimWrap.wrap(ex.D.x - SimMathx.jsign(d) * px)
		var dy: float = ex.D.y - ex.A.y
		if absf(dy) > 1.0:
			var py: float = minf(absf(dy) * 0.5, pull)
			ex.A.y = maxf(WorldTerrain.groundY(S, ex.A.x), ex.A.y + SimMathx.jsign(dy) * py)
			ex.D.y = maxf(WorldTerrain.groundY(S, ex.D.x), ex.D.y - SimMathx.jsign(dy) * py)
	if S.tick - maxi(_g(ex.A, LAST_AT), _g(ex.D, LAST_AT)) > int(c.idleTicks) and _g(ex.A, LINE) == 0 and _g(ex.D, LINE) == 0:
		end(S, ex, "idle")


## His heavy is held past its wind-up (start), or let go: it lands heldLandTicks after the release, charged by the hold.
static func _hold(S: SimState, ex, f, start: bool) -> void:
	var c: Dictionary = cfg()
	var role: String = "A" if f == ex.A else "D"
	var now: int = _now(S)
	for b in ex.beats:
		if b.done or b.op != "strike" or b.args == null or not b.args.get("brawl", false) or String(b.args.a) != role:
			continue
		if start:
			b.t = ex.t + 3600.0   # it waits for the release
			_s(f, LINE, 2)
			_s(f, CONTACT, now + (1 << 20))
			return
		var w: int = int(c.heavy.windupTicks)
		var charge: float = clampf(float(now - _g(f, HOLD_AT) - w) / maxf(1.0, float(int(c.heavy.heldFullTicks) - w)), 0.0, 1.0)
		b.args["charge"] = charge
		if charge >= 1.0:
			b.args["dmg"] = float(b.args.dmg) * float(c.heldMul)   # held to full
		b.t = ex.t + (float(int(c.heavy.heldLandTicks)) - 0.25) / DirData.TICKS_PER_SEC
		if charge >= 1.0:
			DirInterrupt.si(f, DirInterrupt.PHRASE_P, DirInterrupt.gi(f, DirInterrupt.PHRASE_P) | (DirAlchemy.HELD << 8))   # a held heavy: a launch's earner
		_s(f, LINE, 1)
		_s(f, CONTACT, now + int(c.heavy.heldLandTicks))
		var e = _ev(S, f, "blow", "release")
		e.n = S.tick + int(c.heavy.heldLandTicks)
		e.amount = float(S.tick)
		e.dur = float(int(c.heavy.heldLandTicks))
		e.x = charge
		return


# ---------------------------------------------------------------- the AI in a brawl (B1: the simplest that holds its commitments)

## The AI's input in a brawl (DirAI.aiInput). It chooses when its last choice has played out, not on a timer: a
## string of lights at its level's tap gap, closed by a heavy at its ender share; or a guard for a drawn time, after
## which it must attack; a heavy against a rival who is guarding, at its level's guard-break rate; its signature as outside.
## Into a running flurry it throws its closing heavy only at its level's rashHeavy. It answers a paced string by its
## answerBy-th landed blow with a guard, and attacks into a gap (section 9c; the parry, the push and the burst come later).
## A close that landed on it is answered with a heavy as its stagger ends, at heavyAfterClose. Against a shooter it
## takes its level's vsShooter numbers: no guard, and seldom the ender that would knock him back to his range.
## It writes real presses and holds, as a player does. It does not leave a brawl (B5).
static func aiInput(S: SimState, f) -> void:
	var ex = S.dirS.ex
	var i: SimIntent = f.input
	var c: Dictionary = cfg()
	var lv: Dictionary = DirAI.lv()
	var bl: Dictionary = lv.get("brawl", {})
	var o = ex.D if f == ex.A else ex.A
	f.ai.st = 0.0
	if ex.branch != "" or ex.cancel or f.stunTicks > 0:
		return
	if _now(S) < _g(f, AI_HOLD):
		i.heavyHeld = true
	# Its answer to being closed on (section 9d, ruling 4): a heavy as its stagger ends, at its level's heavyAfterClose.
	# The closer's blows on it while it staggered added nothing to his run, so his fresh run has to race the wind-up.
	if _g(f, AI_AFTER) == 1:
		_s(f, AI_AFTER, 0)
		if _g(f, LINE) == 0 and S.rng.next() < float(bl.get("heavyAfterClose", 0.0)):
			_s(f, AI_GUARD, 0)
			_s(f, AI_LEFT, 0)
			_s(f, AI_CLOSE, 0)
			_aiHeavy(S, f, lv, false)
			return
	# Against a shooter (ruling 5) its guard share and its ender share are its level's vsShooter numbers.
	var vs: Dictionary = lv.get("vsShooter", {}) if shooter(S, f, o) else {}
	var flurried: bool = _g(o, TAP_GAP) > 0 and S.tick - _g(o, LAST_TAP) <= int(c.flurry.maxGap) and o.stunTicks <= 0 and o.stance != 1.0
	# Section 9c: it answers a string by its answerBy-th landed blow, and doesn't stand and take the next. The answer B1
	# has is the guard: after its reaction time it drops what it was doing and guards for guardMaxTicks, then it must
	# attack. A flurry is not a string to answer: against mashing it does what it does anyway.
	var by: int = int(bl.get("answerBy", 0))
	if by > 0 and _g(o, STRING_N) >= by and _g(o, ANSWERED) == 0 and not flurried:
		_s(o, ANSWERED, 1)
		_s(f, AI_ANS_AT, S.tick + int(DirAI.skill().get("reactTicks", 14)))
	if _g(f, AI_ANS_AT) > 0 and S.tick >= _g(f, AI_ANS_AT):
		_s(f, AI_ANS_AT, 0)
		_s(f, AI_GUARD, S.tick + int(bl.get("guardMaxTicks", 28)))
		_s(f, AI_LEFT, -1)
		_s(f, AI_CLOSE, 0)
	if S.tick < _g(f, AI_GUARD):
		# Its own string goes into a gap: when he has thrown nothing for attackIntoGap ticks, the guard comes down.
		var into: int = int(bl.get("attackIntoGap", 0))
		if into > 0 and _g(o, LINE) == 0 and S.tick - _g(o, LAND_AT) >= into:
			_s(f, AI_GUARD, 0)
		else:
			i.guard = true
			f.ai.st = 1.0
			return
	if S.tick < _g(f, AI_NEXT):
		return
	var gap: int = int(bl.get("tapGap", 10))
	var left: int = _g(f, AI_LEFT)
	# A heavy thrown into a running flurry is stopped by the flurry's close (and from B3 by three blows): it is a mistake, made at rashHeavy.
	if left > 0:
		# The next light of its string, on its cadence whatever its line is doing, as a player taps: one it cannot
		# throw at once is held, so its string is a flurry at its tap gap.
		i.light = true
		_s(f, AI_LEFT, left - 1)
		_s(f, AI_NEXT, S.tick + gap)
		return
	if _g(f, LINE) != 0:
		return   # a new choice waits for its blow to land
	if _g(f, AI_CLOSE) == 1:
		_s(f, AI_CLOSE, 0)
		if _g(f, STRING_N) >= int(c.enderAfter) and (not flurried or S.rng.next() < float(bl.get("rashHeavy", 0.0))) and S.rng.next() < float(vs.get("enderShare", bl.get("enderShare", 0.5))):
			_aiHeavy(S, f, lv, true)
			return
	# A new choice.
	if SimFighter.sigFree(f) or (f.ki >= 50.0 and S.T >= f.sigReadyT and S.rng.next() < float(DirAI.skill().sigPick)):
		i.sig = true
		_s(f, AI_NEXT, S.tick + gap)
		return
	if o.stance == 1.0 and S.rng.next() < float(lv.get("breakGuard", 0.0)):
		_aiHeavy(S, f, lv, true)
		return
	if left == 0 and S.rng.next() < float(vs.get("guardShare", bl.get("guardShare", 0.3))):
		var g: Array = bl.get("guardTicks", [20, 60])
		_s(f, AI_GUARD, S.tick + int(S.rng.range_(float(g[0]), float(g[1]) + 0.999)))
		_s(f, AI_LEFT, -1)   # after a guard it must attack
		i.guard = true
		f.ai.st = 1.0
		return
	var n: Array = bl.get("string", [3, 5])
	_s(f, AI_LEFT, int(S.rng.range_(float(n[0]), float(n[1]) + 0.999)) - 1)
	_s(f, AI_CLOSE, 1)
	_s(f, AI_NEXT, S.tick + gap)
	i.light = true


## Its heavy: tapped, or (hold) held to the full charge at its level's rate.
static func _aiHeavy(S: SimState, f, lv: Dictionary, hold: bool) -> void:
	var c: Dictionary = cfg()
	f.input.heavy = true
	f.input.heavyHeld = true
	if hold and S.rng.next() < float(lv.get("heldHeavy", 0.0)) * float(lv.get("earnerUse", 1.0)):
		_s(f, AI_HOLD, _now(S) + int(c.heavy.heldFullTicks) + 1)
	_s(f, AI_NEXT, S.tick + int(c.heavy.windupTicks))
