class_name DirBrawl
## The brawl (docs/director/brawl-plan.md; docs/design/melee-press-feel.md sections 1 to 3 and 5 to 7;
## docs/design/brawl-second-pass.md; as built: docs/director/brawl-c1.md and brawl-c2.md). In the close band a light or a heavy against a rival who stands or guards starts a brawl in place of a
## planned exchange. It is one exchange (its template id is TPL) that both fighters are in: each has his own strike line
## (one blow on its way, one held press), and every attack press is one blow.
##  - A light lands contactTicks after the press. Lights tapped minGap to maxGap ticks apart are a flurry: a blow lasts
##    one tap gap and its damage goes with the gap (flurry.mul), so a faster flurry is not a stronger one.
##  - The run and the close (the spec's section 3): his run goes up one for each light or flurry blow he lands and
##    down one for each that lands on him; a heavy on him clears it, and so do runLapseTicks without landing. At a
##    run of runToClose his next landed light staggers the rival in place: decisive, at half a set-up. A blow on a
##    staggered fighter adds nothing to the run. A trade (both landing inside the lapse) that reaches tradeMaxTicks
##    breaks for a lead of more than levelWithin, then or on the tick one appears, and that fighter's next landed
##    blow is the close. A trade still level at doubleTicks is the double hit: both land, both are thrown back, and
##    nobody wins (docs/design/brawl-second-pass.md section 7).
##  - Control (slice C1, brawl-second-pass.md section 1): the pair has a centre, and both sticks move it, each at
##    nudgeMul of his free-flight speed. The speed the brawl began with carries on for carryTicks. A building's face
##    stops it and it slides along. Both sticks held away for partTicks is the walk-out.
##  - Three strengths on three buttons (slices C2a and C2t, brawl-second-pass.md sections 2 and 3). X is the light. Y
##    is the medium: a wind-up of 12 live ticks, worth 2.5 lights, a reel of 6. B, with no stance held, is the heavy:
##    28 ticks, worth 6, armoured (a light does half and changes nothing; a medium ends it until tick 20), and a
##    clean one staggers him in place. A wound blow lands at its wind-up's end when its button is up. Still down, it
##    waits: a medium goes by itself at 16, and a heavy charges from 32, is full at 44 with its flash, lands 4 after
##    he lets go and by itself at 70, worth 8 to 10. Charged, it knocks him back; at full it launches him. Each
##    strength has its flurry, and any strength closes at a run of runToClose. A held X is the burst.
##  - The launcher: a B thrown while a stagger of launcher.minStagger or more lasts winds 14 ticks, always lands,
##    is worth 3 and launches, aimed by the stick's quarter. The stagger is held until it lands.
##  - Giving ground (section 1): while one winds or charges, the other, hands down, moves alone on his stick, up to
##    give.leashBh past striking distance; the winder may follow. A wound blow has a reach, read as it lands; out of
##    it, it misses, and he is open for its recoverWhiff. A press from a gap closes it over ticks as part of the
##    blow, which lands that much later, and no fighter of a brawl moves more than give.closeMaxBh in a tick.
##  - Energy in reach (section 5b): with the energy family held, X is the point-blank bolt and Y the blast. To the
##    core each is a shot, so a guard takes it by the blocked shot's rule. A clean blast knocks him back 4 bh.
##  - On a guard a medium chips double and a heavy staggers the blocker in place (the set guard and the fresh one
##    are C2b's), and nothing moves a blocker.
##  - It holds while they are within breakBh. It ends on a knock-back or a launch, on the double hit, when both walk
##    out, when one of them leaves (a dodge or
##    a boost with the stick away, at the dodge-cancel's price), bursts, perfect-blocks or reverses, after idleTicks
##    with no attack from either, or when a set piece takes it over (a break, a finisher, a signature).
## A blow is one `strike` beat of the exchange, announced when it is thrown, so the renderers read it as they read a
## strike; its args carry the beat fields (style, grade, k, n, closing, charge, hand, ender, piece) and `brawl`.
## The exchange's kind is the weight of the blow that is landing, as the core reads it.
## Clocks: a fighter's taps, his line and the AI's choices count S.tick, which runs through a hit-stop, so a flurry
## keeps its tap rate; a blow's wind-up, a reel and a hold count live ticks, as every beat does.
## Not yet: the charged medium, the just release, the fresh and the set guard, the wrench, the shove and the lift
## (C2b); skill strikes and the beat point; struggles. Flow is neither earned nor lost by a press inside a brawl.
## State: the fighter's director integers after the alchemy's. Numbers: data/director/interrupts.json `brawl`, and the
## level's `brawl` block in data/director/ai.json.

const TPL: String = "brawl"
const BASE: int = DirAlchemy.SIZE
const LINE: int = BASE          # 0 idle, 1 a blow on its way, 2 a heavy held past its wind-up
const KIND: int = BASE + 1      # the blow on his line: LIGHT, FLURRY, MEDIUM, BIG
const CONTACT: int = BASE + 2   # the live tick it lands
const FREE_AT: int = BASE + 3   # S.tick from which his line is free again
const REEL_AT: int = BASE + 4   # the live tick his reel ends
const HELD_P: int = BASE + 5    # a press he could not throw at once: its strength plus 1, 8 more when it came already wound, 16 more with the energy family held; 0 none
const HELD_AT: int = BASE + 6   # ... and its own tick
const LAST_TAP: int = BASE + 7  # the tick of his last light press; 0 none
const TAP_GAP: int = BASE + 8   # the ticks between his last two light presses, held to the flurry's range; 0: not a flurry
const STR_ON: int = BASE + 9    # 1 while his string runs
const STRING_N: int = BASE + 10 # landed blows of his string
const LAND_AT: int = BASE + 11  # S.tick of his last blow thrown or landed (the string's lapse)
const RUN: int = BASE + 12      # his run against the rival, in quarters of a point (RUN_U): up a point for each blow he lands (half for a burst's, flurry.runBy.medium for a medium), down by the same for each that lands on him
const BLOWS: int = BASE + 13    # blows he has thrown in this brawl
const HOLD_AT: int = BASE + 14  # the live tick his heavy's press went down; 0 none
const LAST_AT: int = BASE + 15  # S.tick of his last attack press in this brawl
const GUT: int = BASE + 16      # bit 1: his last pick went to the gut (Legal's rule: no two blows running to the gut); bit 2: the pick before it did, for a blow that is lost before it lands
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
const DBL_AT: int = BASE + 32   # on the exchange's attacker, for both: the live tick the double hit's two blows land; 0 none
const SAFE_UNTIL: int = BASE + 33 # S.tick until which he cannot be closed on again (closeGuardTicks after he recovers from a close); -1 while that close's stagger lasts
const RIP_UNTIL: int = BASE + 34 # S.tick until which his next attack press is the riposte of his perfect block (section 9f); 0 none
const RIP_KIND: int = BASE + 35  # ... 1: the blow he turned was a light; 2: a heavy or an ender, so a heavy riposte separates them
const AI_RIP: int = BASE + 36    # the AI: 1 while it has its riposte to throw
const NUDGE_X: int = BASE + 37   # his stick's nudge after Controls' ramp, in 1/127 units, by axis (SimAim.nudge_ramp keeps it)
const NUDGE_Y: int = BASE + 38
const CEN_VX: int = BASE + 39    # on the exchange's attacker, for both: the centre's velocity from the two sticks, in sixteenths of a unit a second
const CEN_VY: int = BASE + 40
const CARRY_X: int = BASE + 41   # ... the speed the brawl began with, in the same units
const CARRY_Y: int = BASE + 42
const CARRY_N: int = BASE + 43   # ... and the live ticks of it left
const PART_N: int = BASE + 44    # ... the live ticks running for which both have held away (the walk-out)
const DBL_N: int = BASE + 45     # ... how many of the double hit's two blows have landed
const AI_NUDGE: int = BASE + 46  # the AI: the nudge it holds: 0 none, 1 toward the rival, 2 away from him, 3 the +x way, 4 the -x way
const AI_PART: int = BASE + 47   # the AI: S.tick until which it holds away to walk out; -1: it weighed a walk-out in this brawl and stays; 0: not weighed yet
const MOVE_X: int = BASE + 48    # on the exchange's attacker, for both: the velocity the pair was given this tick, in sixteenths of a unit a second
const MOVE_Y: int = BASE + 49
const M_TAP: int = BASE + 50     # the tick of his last medium press; 0 none (the medium flurry's gap)
const B_TAP: int = BASE + 51     # ... and of his last heavy press
const CHG: int = BASE + 52       # his wound blow past its wind-up: 0 no; 1 a heavy charging; 2 ... and its flash is out; 3 let go, on its way
const BURST_N: int = BASE + 53   # the blows of his burst thrown so far, the press's own light counted; 0 when none runs
const BURST_AT: int = BASE + 54  # ... and the live tick of the press that began it
const BIG_REQ: int = BASE + 55   # the tick of his last B press made out of reach: the blow his lunge arrives with is the heavy
const X_LIVE: int = BASE + 56    # the live tick of his last light press in this brawl; 0 none (the burst's clock)
const AI_SAW: int = BASE + 57    # the AI: the rival's wind-up it has weighed an answer to (its HOLD_AT)
const AI_DIG: int = BASE + 58    # the AI: the trade it weighed digging in to (its TRADE_T0), plus 1 << 30 when it dug in
const AI_BURST: int = BASE + 59  # the AI: S.tick until which it holds X for a burst
const CLOSE_N: int = BASE + 60     # the live ticks left of his step in: a press from a gap closes it over ticks, as part of the blow
const OPEN_UNTIL: int = BASE + 61  # the live tick until which he is open after a miss: no guard, no giving ground
const LC_UNTIL: int = BASE + 62    # not 0 while his tap of B is the launcher: S.tick the stagger that opened it was due to end
const FLAV: int = BASE + 63        # the blow on his line: 0 a fist's, 1 an energy art in reach (its family is read at the press and kept), 2 the launcher
const GAVE: int = BASE + 64        # 1 once he has given ground against the wind-up the rival has on
const AI_GIVE: int = BASE + 65     # the AI: 1 while it gives ground, 2 while it follows a rival who does
const AI_GSAW: int = BASE + 66     # ... the rival's wind-up it weighed giving ground against (its HOLD_AT), plus 1 << 30 when it does
const AI_FSAW: int = BASE + 67     # ... its own wind-up it weighed following for, plus 1 << 30 when it does
const FLASH_AT: int = BASE + 68    # on both: S.tick of the last energy blow in reach that took the full flash (kept across brawls)
const AI_LSAW: int = BASE + 69     # the AI: 1 while it means to throw the launcher in the window it has
const PMOVE_X: int = BASE + 70     # on the exchange's attacker, for both: the velocity the pair was given on the tick before, which the core has just moved them by
const PMOVE_Y: int = BASE + 71
const OWN: int = BASE + 72         # what he has moved alone on this tick, in sixteenths of a unit (the closing rule's count)
const ARR_AT: int = BASE + 73      # S.tick the brawl began with his press
const ARR_MV: int = BASE + 74      # ... and what he had moved on that tick before it began, in sixteenths of a unit (1 << 20: a lunge carried him)
const LAST_X: int = BASE + 75      # where the director last left him, in sixteenths of a unit, and S.tick of it: what the core moves him by on the next tick is read against it
const LAST_Y: int = BASE + 76
const LAST_T: int = BASE + 77
const LAUNCH_AT: int = BASE + 78   # the live tick he was last launched, by anything (kept across brawls): the launcher rests on him from it
const LC_PING: int = BASE + 79     # 1 when his opening was announced (launcher_open): a launch was ready
const PRE: int = BASE + 80         # what his wound blow has stepped through its reach before the contact, in sixteenths of a unit
const TELL_N: int = BASE + 81      # the number of the signature exchange whose tell he is moving in
const TELL_MV: int = BASE + 82     # ... and how far he has moved in it, in sixteenths of a unit
const AI_GAP: int = BASE + 83     # the AI: the tap gap of the string it is throwing (drawn between tapGap and tapGapMax); 0 before its first
const GAPV: int = BASE + 84       # on a fighter who winds: the gap his blow must reach, in sixteenths of a unit, counted from the tick its wind-up began
const GAPV_ON: int = BASE + 85    # ... 1 once that count has begun
const MATCH_DBL: int = BASE + 86   # the double hits of this match so far (kept across brawls, on both): the AI digs in to digInMax of them
const MATCH_DBL_AT: int = BASE + 87   # the live tick of the last one (kept across brawls): the AI does not dig in within digInRestS of it
const LAST2: int = BASE + 88      # his last two blows thrown in this brawl, newest in the low 3 bits: 0 none, else the kind plus 1
const AI_MEDS: int = BASE + 89    # the AI: 1 while its string is mediums (against a rival whose last two blows were heavies)
const FLOOR: int = BASE + 90      # his held X: 0 none; 1 an X press still down, its burst to come or running; 2 at the floor pace (its burst is spent)
const FLOOR_AT: int = BASE + 91   # S.tick of its next press at that pace
const FLOOR_T: int = BASE + 92    # the live tick X was last seen down, or he was staggered and it could not be read
const BOLT_N: int = BASE + 93     # point-blank bolts he has thrown running in his string; 0 when his last blow was no bolt
const BOLT_RUN: int = BASE + 94   # the run his mashed bolts follow, plus 1 (the recipes' reach.runs); 0 none
const BOLT_I: int = BASE + 95     # ... and his place in it
const SENT: int = BASE + 96       # 1 while he is sent (launched, knocked back, down) and not yet free (kept across brawls)
const MOVE_AT: int = BASE + 97    # S.tick from which he may start an approach again: the first move is the rival's until then (kept across brawls)
const RET_N: int = BASE + 98      # 1 while he is returning from a send: free again, his first blow back still to come (bands.return)
const RET_AT: int = BASE + 99     # the live tick he came free after the send
const LC_LATE: int = BASE + 100    # 1 while the launcher on his line was thrown after the stagger: he can answer it
const END: int = BASE + 101
const RUN_U: int = 4   # the run is counted in quarters of a point
const HEAVY2: int = ((3 + 1) << 3) | (3 + 1)   # LAST2 when both were heavies (BIG)
const LIGHT: int = 0
const FLURRY: int = 1
const MEDIUM: int = 2   # Y: a wound blow of 12 ticks (the heavy strikes before the three strengths)
const BIG: int = 3      # B: the heavy, a wound blow of 28 ticks, armoured
const KINDS: Array = ["light", "flurry", "medium", "heavy"]
const STRENGTH: Array = ["light", "light", "medium", "heavy"]   # a blow's strength by its kind: the text of its cue

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


## A read never sizes the integers (their count is in the gameplay hash): a slot that was never written reads 0.
static func _g(f, k: int) -> int:
	return f.act.dirI[k] if k < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	_size(f)
	f.act.dirI[k] = v


## The live clock in ticks (it stops in a hit-stop, as the exchange's clock does).
static func _now(S: SimState) -> int:
	return int(round(S.T * DirData.TICKS_PER_SEC))


## True while a blow of a double hit is still to land.
static func _doubleLeft(ex) -> bool:
	for b in ex.beats:
		if not b.done and b.op == "strike" and b.args != null and bool(b.args.get("double", false)):
			return true
	return false


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
## source: for a press_ack, the button's cell (x, y, a or b), which the HUD marks.
static func _ev(S: SimState, f, name: String, text: String = "", source: String = ""):
	SimFx.cue(S, f, name, text, source)
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
	var big: bool = kind == "heavy" and bigLunge(ex.A, DirExchange.planTick if DirExchange.planTick >= 0 else S.tick)   # his press was B: the heavy
	ex.tpl = TPL
	ex.branch = ""
	ex.tag = "BRAWL"
	ex.loser = -1
	_reset(ex)
	if S.depthOn:
		_lineStart(S, ex)
	SimAct.clear(ex.D)   # no request waits in a brawl: a press is a blow, or it is spent
	# The brawl keeps the speed it began with (brawl-second-pass.md section 1): carryShare of the two velocities added,
	# which is half the closing speed when one of them stood, carries on as the centre's drift and fades over carryTicks.
	# An attacker who came in by a lunge was carried by the director, so his speed is his own flight speed along his line.
	var cx: float = 0.0
	var cy: float = 0.0
	for f in [ex.A, ex.D]:
		var fx: float = f.vx
		var fy: float = f.vy
		if f == ex.A and (DirExchange.engaging or f.rush != null):
			var lx: float = SimWrap.sdx(f.x, ex.D.x)
			var ly: float = ex.D.y - f.y
			var ll: float = SimDetMath.hypot(lx, ly)
			var sp: float = _flySpeed(S, f)
			fx = lx / ll * sp if ll > 0.0 else 0.0
			fy = ly / ll * sp if ll > 0.0 else 0.0
		cx += fx
		cy += fy
	_s(ex.A, CARRY_X, int(round(cx * float(c.carryShare) * 16.0)))
	_s(ex.A, CARRY_Y, int(round(cy * float(c.carryShare) * 16.0)))
	_s(ex.A, CARRY_N, int(c.carryTicks))
	# Both are held from now, and the pair moves as its centre does (_move).
	var pre: float = SimDetMath.hypot(ex.A.vx, ex.A.vy) * SimConst.DT   # what his own flight may have moved him on this tick already
	for f in [ex.A, ex.D]:
		f.vx = 0.0
		f.vy = 0.0
	var e = _ev(S, ex.A, "brawl_start")
	e.target = float(S.fighters.find(ex.D))
	e.n = ex.n
	e.amount = DirBands.dist(ex.A, ex.D)
	SimEvents.feed(S, "BRAWL", ex.A.name + " and " + ex.D.name + " in reach: every press is a blow")
	var st: int = (2 if big else 1) if kind == "heavy" else 0   # the strength of the blow that starts it
	var p: int = DirExchange.planTick if DirExchange.planTick >= 0 else S.tick - _waited(ex.A)
	_s(ex.A, LAST_AT, S.tick)
	if st == 0:
		_s(ex.A, LAST_TAP, p)
	# He steps in to striking distance as the blow comes, over ticks and never more than give.closeMaxBh in one: the
	# closing rule (_throw). No rush carries him.
	var carried: bool = DirExchange.engaging or ex.A.rush != null   # a lunge, or a rush of the director, brought him in
	ex.A.rush = null
	# What he has moved on this tick already counts against his first step in: his own flight, or a lunge, which
	# leaves no room for one (the step in begins on the next tick).
	_s(ex.A, ARR_AT, S.tick)
	_s(ex.A, ARR_MV, (1 << 20) if carried else int(ceil(pre * 16.0)))
	_throw(S, ex.A, st, p, true, DirExchange.engaging)
	if _g(ex.A, CLOSE_N) > 0:
		SimFx.rush(S, ex.A, ex.D, S.tick + _g(ex.A, CLOSE_N))


## True while ex is a zip's ticks in reach: the brawl's lines with no brawl announced (DirZip).
static func quiet(ex) -> bool:
	return isBrawl(ex) and ex.tag == "ZIP" and ex.branch == ""


## A zip's ticks in reach begin (DirZip._arrive, on the exchange DirExchange.startZip made): both fighters have a
## line, as in a brawl, and no brawl is announced. ex.tag is "ZIP" until the zipper is caught or countered.
static func beginQuiet(S: SimState, ex) -> void:
	ex.tpl = TPL
	ex.branch = ""
	ex.tag = "ZIP"
	ex.loser = -1
	_reset(ex)
	if S.depthOn:
		_lineStart(S, ex)
	for f in [ex.A, ex.D]:
		SimAct.clear(f)
		f.vx = 0.0
		f.vy = 0.0
		_s(f, LAST_AT, S.tick)


## The zipper was caught or countered (DirZip): the brawl is announced now, with `starter` as the fighter who began it.
static func announce(S: SimState, ex, starter, why: String) -> void:
	ex.tag = "BRAWL"
	var e = _ev(S, starter, "brawl_start", why)
	e.target = float(S.fighters.find(ex.D if starter == ex.A else ex.A))
	e.n = ex.n
	e.amount = DirBands.dist(ex.A, ex.D)
	SimEvents.feed(S, "BRAWL", ex.A.name + " and " + ex.D.name + " in reach: every press is a blow")


## The weight a brawl blow names for hit-stop by weight (rulings-2026-10-19b 4a): a bolt a light's and a blast a
## medium's; the double hit a heavy's (it held a heavy's stop); a heavy, a medium; the close a launch's (the table's
## "a launch or a close"); a mashed, flurry, burst or held-pace light a mashed light's (5b: "mash or burst light"); a
## tapped light a light's.
static func weightOf(a: Dictionary) -> String:
	if a.has("energy"):
		return "medium" if String(a.energy) == "blast" else "light"
	if bool(a.get("double", false)):
		return "heavy"
	var bk: int = int(a.get("bk", LIGHT))
	if bk == BIG:
		return "heavy"
	if bk == MEDIUM:
		return "medium"
	if bool(a.get("closing", false)):
		return "launch"
	if bk == FLURRY or bool(a.get("floor", false)) or bool(a.get("burst", false)):
		return "light_mash"
	return "light"


## A blow put on f's line by rule and not by a press (a zip's blow; the heavy a rival pressed before the zipper
## arrived): it lands `lead` live ticks from now, worth dmg. extra's keys go on the beat (zip, style, counter, sure,
## ender). A sure blow can't be blocked.
static func blowAt(S: SimState, ex, f, kind: int, lead: int, dmg: float, extra: Dictionary) -> void:
	var c: Dictionary = cfg()
	var o = ex.D if f == ex.A else ex.A
	var role: String = "A" if f == ex.A else "D"
	var weight: int = SimAct.HEAVY if _wound(kind) else SimAct.LIGHT
	DirInterrupt.si(f, DirInterrupt.PHRASE_P, weight)
	if _g(f, STR_ON) == 0:
		_s(f, STR_ON, 1)
		_s(f, STR_K, 0)
		_s(f, STRING_N, 0)
		DirInterrupt.si(f, DirInterrupt.LANDED, 0)
	var k: int = _g(f, STR_K) + 1
	_s(f, STR_K, k)
	var o2 := {"class": "heavy" if _wound(kind) else "blow", "stop": float(int(c.hitstop.heavy if kind == BIG else (c.hitstop.medium if kind == MEDIUM else c.hitstop.light))) / DirData.TICKS_PER_SEC, "big": _wound(kind), "kb": float(c.recoil)}
	if bool(extra.get("sure", false)):
		o2["ignoreStance"] = true
		o2["noParry"] = true
		o2["weighed"] = true
	if bool(extra.get("double", false)):
		o2["stop"] = float(int(c.hitstop.heavy)) / DirData.TICKS_PER_SEC   # the double hit's two blows hold the clock as a heavy does
		o2["region"] = "head"   # ... and each lands on the head (the core's named region)
	var args := {"a": role, "d": "D" if role == "A" else "A", "dmg": dmg, "o": o2, "brawl": true, "bk": kind,
		"strength": STRENGTH[kind], "flurry": false,
		"grade": "none", "k": k, "n": k, "closing": false, "charge": 0.0,
		"hand": "r" if (k % 2) == 1 else "l", "ender": false}
	for key in extra:
		args[key] = extra[key]
	# The piece, by the blow's cell: a burst's blow by the class of the gap before it (the recipes' burst.slots). A zip's
	# blow and the double hit's have no cell, and keep the pool of their strength. Any other takes its strength's cell.
	var cell: String = ""
	if extra.has("burst"):
		var slots = DirRecipe.rec().get("burst", {}).get("slots", []) if DirRecipe.on() else []
		var bn: int = int(extra.burst) - 1
		if slots is Array and bn >= 0 and bn < slots.size():
			cell = {"fast": "burstFast", "mid": "burstMid", "slow": "burstSlow"}.get(String(slots[bn]), "")
	elif not bool(extra.get("zip", false)) and not bool(extra.get("double", false)):
		cell = "heavy" if kind == BIG else ("medium" if kind == MEDIUM else "light")   # a pressed blow thrown by rule: its strength's cell
	_s(f, BOLT_N, 0)
	var piece: String = _piece(S, f, 2 if kind == BIG else (1 if kind == MEDIUM else 0), false, cell)
	if piece != "":
		args["piece"] = piece
	DirExchange.schedule(ex, ex.t + (float(lead + (0 if _inTick else 1)) - 0.25) / DirData.TICKS_PER_SEC, "strike", args)
	_s(f, LINE, 1)
	_s(f, KIND, kind)
	_s(f, CONTACT, _now(S) + lead)
	_s(f, HOLD_AT, 0)
	_s(f, FREE_AT, S.tick + (1 << 20) if _wound(kind) else S.tick + lead + 1)
	_s(f, LAND_AT, S.tick)
	_s(f, HELD_P, 0)
	_s(f, BLOWS, _g(f, BLOWS) + 1)
	var e = _ev(S, f, "blow", STRENGTH[kind], "zip" if bool(extra.get("zip", false)) else "")   # source zip: a zipper's blow, announced as he arrives
	e.target = float(S.fighters.find(o))
	e.n = S.tick + lead
	e.amount = float(S.tick)
	e.dur = float(lead)


## The brawl is over, and why: knockback, launch, apart, idle, left, burst, perfect_block, reversal, break, finisher,
## signature, walk (both held away), double (the double hit). The event goes out once; the lines stop. A set piece that took it over plays on in the same exchange.
static func over(S: SimState, ex, why: String) -> void:
	if not isBrawl(ex) or ex.branch != "":
		return
	DirGrapple.over(S, ex, why)   # a catch or a clinch ends with the brawl
	var said: bool = ex.tag != "ZIP"   # a zip's ticks in reach were never announced as a brawl: nothing ends
	ex.branch = why
	if why != "walk":
		for f in [ex.A, ex.D]:
			if f.state == "locked":
				f.vx = 0.0   # the pair's drift ends with the brawl; two who walk out keep theirs
				f.vy = 0.0
	if said:
		var e = _ev(S, ex.A, "brawl_end", why)
		e.n = ex.n
		e.amount = float(int(round(ex.t * DirData.TICKS_PER_SEC)))
		e.x = float(_g(ex.A, BLOWS))
		e.y = float(_g(ex.D, BLOWS))
	for f in [ex.A, ex.D]:
		if _windOn(f):
			_wEnd(S, f, _g(f, KIND), 3)   # his wind-up ends with the brawl
		_s(f, LINE, 0)
		_s(f, HELD_P, 0)
		_s(f, HOLD_AT, 0)
		_s(f, CLOSE_N, 0)
		_s(f, FLAV, 0)
		_s(f, AI_GIVE, 0)
		_lcClose(S, f, "lapsed")
		_strEnd(f)
	if said:
		SimEvents.feed(S, "BRAWL ENDS", why + ": " + str(_g(ex.A, BLOWS)) + " and " + str(_g(ex.D, BLOWS)) + " blows in " + str(int(round(ex.t * DirData.TICKS_PER_SEC))) + " ticks")


## ... and the exchange ends with it, now.
static func end(S: SimState, ex, why: String) -> void:
	if S.dirS.ex != ex:
		return
	over(S, ex, why)
	for b in ex.beats:
		b.done = true
	var slide = ex.A.rush   # the exchange's end drops its attacker's move: a knock-back's slide is kept, whoever was sent
	DirExchange.endEx(S, ex)
	if slide != null and slide.tgt == null and (why == "knockback" or why == "launch" or why == "double"):
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


## A perfect block inside the brawl (DirInterrupt.perfectBlock; section 9f). a's blow is turned: his string is closed,
## his run is cleared and he staggers in place. d has the riposte: his next attack pressed within riposteTicks.
## launch: the turned blow was a heavy or an ender, so a heavy riposte separates them. The brawl goes on.
static func perfectBlocked(S: SimState, ex, a, d, o: Dictionary, launch: bool) -> void:
	var c: Dictionary = cfg()
	var n: int = int(c.perfectBlock.staggerTicks)
	o["turned"] = true
	if not (DirRally.pbDazes(a) and DirRally.daze(S, ex, d, a, "perfect_block")):   # 23d 1 (10-26 items 23, 25): a perfect block that turns a charged blow or an ender dazes the one it turned; a launcher keeps its reversal
		a.stunTicks = maxi(a.stunTicks, n)
	_drop(S, ex, a)
	_tradeReset(ex)
	_s(d, RIP_UNTIL, S.tick + int(c.riposteTicks))
	_s(d, RIP_KIND, 2 if launch else 1)
	_s(ex.A, LAST_AT, S.tick)   # the idle clock starts again
	_s(ex.D, LAST_AT, S.tick)
	var st = _ev(S, a, "stagger", "perfect_block")
	st.target = float(S.fighters.find(d))
	st.n = n
	_lcOpen(S, ex, d, a, n, "perfect_block")   # an opening: his B in this stagger always lands
	if d.ai != null and S.rng.next() < float(DirAI.lv().riposte):
		_s(d, AI_RIP, 1)


## A reversal inside the brawl (DirInterrupt.reversal; section 9f). att's string is closed, his run is cleared and he
## staggers in place. f's blow lands for certain reversal.contactTicks after the press, as a medium, in place:
## it doesn't knock back and it doesn't launch. The brawl goes on.
static func reversed(S: SimState, ex, f, att) -> void:
	var c: Dictionary = cfg()
	var rv: Dictionary = c.reversal
	var n: int = int(rv.staggerTicks)
	var lead: int = int(rv.contactTicks)
	att.stunTicks = maxi(att.stunTicks, n)
	_drop(S, ex, att)
	_drop(S, ex, f)
	_tradeReset(ex)
	var st = _ev(S, att, "stagger", "reversal")
	st.target = float(S.fighters.find(f))
	st.n = n
	var role: String = "A" if f == ex.A else "D"
	DirInterrupt.si(f, DirInterrupt.PHRASE_P, SimAct.HEAVY)
	_s(f, STR_ON, 1)
	_s(f, STR_K, 1)
	var args := {"a": role, "d": "D" if role == "A" else "A", "dmg": float(c.medium.worth) * _unit(), "strength": "medium", "flurry": false,
		"o": {"class": "heavy", "stop": float(int(c.hitstop.medium)) / DirData.TICKS_PER_SEC, "big": true, "kb": float(c.recoil), "ignoreStance": true, "noParry": true, "weighed": true},
		"brawl": true, "bk": MEDIUM, "grade": "none", "k": 1, "n": 1, "closing": false, "charge": 0.0, "hand": "r", "ender": false,
		"sure": true, "reversal": true}
	var piece: String = _piece(S, f, 1, false, "reversal")
	if piece != "":
		args["piece"] = piece
	DirExchange.schedule(ex, ex.t + (float(lead + (0 if _inTick else 1)) - 0.25) / DirData.TICKS_PER_SEC, "strike", args)
	_s(f, LINE, 1)
	_s(f, KIND, MEDIUM)
	_s(f, CONTACT, _now(S) + lead)
	_s(f, HOLD_AT, 0)
	_s(f, FREE_AT, S.tick + (1 << 20))
	_s(f, LAND_AT, S.tick)
	_s(f, BLOWS, _g(f, BLOWS) + 1)
	_s(ex.A, LAST_AT, S.tick)   # the idle clock starts again
	_s(ex.D, LAST_AT, S.tick)
	if f.ai != null:
		_s(f, AI_GUARD, 0)
		_s(f, AI_LEFT, 0)
		_s(f, AI_RIP, 0)
		_s(f, AI_NEXT, S.tick + lead)
	var e = _ev(S, f, "blow", STRENGTH[MEDIUM])
	e.target = float(S.fighters.find(att))
	e.n = S.tick + lead
	e.amount = float(S.tick)
	e.dur = float(lead)


## True when f's rival has a blow on its way that f can't block or dodge: a riposte, or a reversal's heavy.
static func sureAgainst(ex, f) -> bool:
	var role: String = "D" if f == ex.A else "A"
	for b in ex.beats:
		if not b.done and b.op == "strike" and b.args != null and b.args.get("sure", false) and String(b.args.a) == role:
			return true
	return false


## Which of the exchange's interrupts a brawl allows (DirData.allows).
static func allows(name: String) -> bool:
	return (cfg().get("interrupts", []) as Array).has(name)


static func _strEnd(f) -> void:
	_s(f, STR_ON, 0)
	_s(f, BOLT_N, 0)
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
## strike (skillMul brawl lights); a heavy charge's arrival is worth what the lunge's is. Signatures, finishers and the
## blow on a buried rival keep their damage. b: the beat; dmg: its damage as planned.
static func worth(S: SimState, ex, b, dmg: float) -> float:
	if not on() or isBrawl(ex) or ex.kind == "sig" or dmg <= 0.0 or ex.tpl == DirBury.TPL or DirExchange.finisherPlanned(ex):
		return dmg
	var c: Dictionary = cfg()
	var lightB: float = float(c.light.damage)
	var heavyB: float = float(c.plannedHeavyDamage)   # the data heavy's damage: what marks a planned strike as heavy-class
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
		return dmg * scale * float(c.heavyMul)   # a far heavy charge arrives as the lunge does, a medium in worth, until the charged medium exists
	return dmg * scale * (float(c.heavyMul) if heavy else 1.0)


# ---------------------------------------------------------------- a press

## An attack press of f's (DirExchange.requestAttack, and the layout's hold edge). True when the brawl took it.
static func takes(S: SimState, f, kind: String) -> bool:
	if not inBrawl(S, f):
		return false
	var ex = S.dirS.ex
	if ex.branch != "" or ex.cancel or _setPiece(ex):
		return true   # a set piece is playing: the press is spent
	if DirGrapple.takes(S, f, kind):
		return true   # a catch's tell or a clinch: X, Y and B are spent (vicious blows are G2's)
	if _g(ex.A, DBL_AT) > 0:
		var da = _ev(S, f, "press_ack", "double", _cell(kind))   # the double hit is on its way: a press is spent
		da.n = S.tick
		return true
	if quiet(ex) and f == ex.A:
		var za = _ev(S, f, "press_ack", "zip", _cell(kind))   # a zipper in reach: his one blow is on its way, and a press is spent
		za.n = S.tick
		return true
	var b: bool = isB(f, kind)
	if kind == "sig" and not b:
		# A stance's signature is its own exchange: the brawl gives way when it can start, and the request then starts it.
		if not _free(S, f) or (not SimFighter.sigFree(f) and (f.ki < 45.0 or S.T < f.sigReadyT)):
			var a = _ev(S, f, "press_ack", "refused", "b")
			a.n = S.tick
			return true
		end(S, ex, "signature")
		return false
	press(S, f, 2 if b else (1 if kind == "heavy" else 0), f.act.mode == 1 and not b)   # with the energy family held, X and Y are the energy arts in reach
	return true


## One press: a blow at once if his line is free, else held for heldPressTicks (the latest only). st: 0 X the light,
## 1 Y the medium, 2 B the heavy.
static func press(S: SimState, f, st: int, energy: bool = false) -> void:
	var c: Dictionary = cfg()
	var p: int = S.tick - _waited(f)
	_s(f, LAST_AT, S.tick)
	f.lastAtkT = S.T   # (the core marks it for a light and a medium; B's edge is the signature's)
	_burstEnd(S, f)   # any press replaces a burst, and a hold at its floor pace
	_s(f, X_LIVE, 0)
	_hold(S, f, st == 0 and not energy)
	if st == 0:
		var last: int = _g(f, LAST_TAP)
		var gap: int = p - last
		_s(f, TAP_GAP, clampi(gap, int(c.flurry.minGap), int(c.flurry.maxGap)) if (last > 0 and gap <= int(c.flurry.maxGap)) else 0)
		_s(f, LAST_TAP, p)
		if _g(f, TAP_GAP) > 0 and _g(f, LINE) == 0 and not _wound(_g(f, KIND)):
			_s(f, FREE_AT, mini(_g(f, FREE_AT), last + _g(f, TAP_GAP)))   # the flurry follows the taps: the blow before lasts one tap gap
	elif _g(f, LINE) == 0 and not _wound(_g(f, KIND)):
		_s(f, FREE_AT, mini(_g(f, FREE_AT), _g(f, LAND_AT) + int(c.light.recover)))   # after a light his line is free for a wound blow light.recover after its contact
	# A wound press whose button is already up on its edge was wound by its hold (the Simple layout's Attack).
	var already: bool = st > 0 and f.ai == null and not _down(f, BIG if st == 2 else MEDIUM)
	# A fresh edge on a button whose blow is still winding or held means "released, then pressed" (Controls,
	# docs/controls/windup-read.md section 1): the old blow resolves as a tap, or as its charge's release. A latched
	# button sends no edge for its release, so this never touches one.
	if st > 0 and _g(f, LINE) != 0 and _g(f, KIND) == (BIG if st == 2 else MEDIUM) and _g(f, HOLD_AT) > 0 and _g(f, CHG) != 3:
		if _g(f, LINE) == 1:
			_s(f, CHG, 3)   # it lands on its tick, whatever the button does now
		else:
			_windTick(S, S.dirS.ex, f, _g(f, KIND), _now(S), true)
	# A B kept for the launcher goes before a light pressed after it: mashing on after the B doesn't lose the launch
	# (brawl-second-pass.md section 3, the route to teach). His line free, the B is thrown now and the light is kept
	# behind it; not free yet, the light is dropped, and says so.
	if st == 0 and (_g(f, HELD_P) & 7) == 3 and (_g(f, LC_UNTIL) > 0 or (anywhere() and _linked(S, f, _g(f, HELD_AT)))):
		if _free(S, f):
			_throw(S, f, 2, _g(f, HELD_AT), false, false, (_g(f, HELD_P) & 8) != 0)
		else:
			var la = _ev(S, f, "press_ack", "lapsed", "x")
			la.n = p
			return
	if not _free(S, f):
		_s(f, HELD_P, (st + 1) | (8 if already else 0) | (16 if energy else 0))
		_s(f, HELD_AT, p)
		var a = _ev(S, f, "press_ack", "held", _cellOf(st))
		a.n = p
		return
	_throw(S, f, st, p, false, false, already, energy)


## f throws the blow his press asked for. st: 0 light, 1 medium, 2 heavy. paid: its ki was paid as the exchange
## started. arrived: he came by a lunge, and its wind-up counted from the press. energy: the energy family was held at
## the press, so X is the point-blank bolt and Y the blast. Returns the live ticks to its contact.
## A wound blow (a medium, a heavy, the blast, the launcher) is announced here with its landing tick: one press, one
## blow. Its wind-up is live ticks. A press whose button is already up when it arrives was wound by its hold (the
## Simple layout's Attack), and lands woundLandTicks later.
## The closing rule (brawl-second-pass.md section 1): a press from a gap closes it as part of the blow, which lands
## give.closeTicksPerBh later for each body height, and never more than give.closeMaxTicks later. A wound blow's
## wind-up begins when the gap is closed.
## The launcher (section 3): a B thrown while the rival's stagger holds its window open winds for
## launcher.windupTicks, always lands, and launches.
static func _throw(S: SimState, f, st: int, p: int, paid: bool, arrived: bool, already: bool = false, energy: bool = false, floor: bool = false) -> int:
	var ex = S.dirS.ex
	var c: Dictionary = cfg()
	var now: int = _now(S)
	var o = ex.D if f == ex.A else ex.A
	var role: String = "A" if f == ex.A else "D"
	var er: Dictionary = c.energy.reach
	if st == 0 and not energy and _g(f, FLOOR) == 2:
		floor = true   # his hold is at its floor pace: the light that starts or goes on with a brawl is the floor's (a real press has set the hold again before it comes here)
	if energy and (st == 2 or paid):
		energy = false   # B with the energy family held is the beam, and never comes here
	if energy:
		var ep: float = float((er.blast if st == 1 else er.bolt).ki)
		if f.ki < ep:
			energy = false   # no ki for it: the fist's blow on that button
		else:
			f.ki -= ep
			paid = true
	var lcOpen: bool = _g(f, LC_UNTIL) > 0 and (o.stunTicks > 0 or S.tick <= _g(f, LC_UNTIL))   # an opening: the window around the close
	var any: bool = anywhere()   # launch anywhere (the thirteenth round), behind its switch
	var lau: bool = st == 2 and not paid and (lcOpen or DirRally.dazed(S, o) or (any and _linked(S, f, p))) and not (any and _bMash(f, p)) and f.ki >= float(c.launcher.ki)
	var safety: int = _safety(S, f, o) if (lau and any) else 0   # 1 sure, 2 hard to answer, 3 answerable
	if st > 0 and not paid:
		# A press he can't pay for throws the strongest blow he can pay for (brawl-second-pass.md section 8): a B becomes
		# a medium, and with nothing a Y or a B becomes a light. It has no cue of its own: the blow's cue says what he threw.
		var price: float = float(c.launcher.ki) if lau else float((c.heavy if st == 2 else c.medium).ki)
		if st == 2 and f.ki < price:
			st = 1
			lau = false
			price = float(c.medium.ki)
		if f.ki < price:
			st = 0
		else:
			f.ki -= price
	var weight: int = SimAct.LIGHT if st == 0 else SimAct.HEAVY
	var kind: int = BIG if st == 2 else (MEDIUM if st == 1 else (FLURRY if _g(f, TAP_GAP) > 0 else LIGHT))
	var wound: bool = st > 0
	# The riposte (section 9f): his next attack pressed within riposteTicks of his perfect block. It can't be blocked
	# or dodged. A light is worth a skill strike; a medium is a medium. Neither separates them.
	var rip: int = _g(f, RIP_KIND) if (_g(f, RIP_UNTIL) > 0 and p <= _g(f, RIP_UNTIL)) else 0
	_s(f, RIP_UNTIL, 0)
	_s(f, RIP_KIND, 0)
	if rip > 0 and kind == FLURRY:
		kind = LIGHT
	if st == 2 or energy:
		rip = 0   # B after a perfect block is the launcher, and a shot is no riposte
	_s(f, LAST2, ((_g(f, LAST2) & 7) << 3) | (kind + 1))   # his last two blows, for the AI's answer to a run of heavies
	# A new string of his: an exchange number of its own, for the keyed draws and the brink chapter's "a later exchange".
	if _g(f, STR_ON) == 0:
		_s(f, STR_ON, 1)
		_s(f, STR_K, 0)
		_s(f, STRING_N, 0)
		DirInterrupt.si(f, DirInterrupt.LANDED, 0)
		if _g(f, BLOWS) + _g(o, BLOWS) > 0:
			_newString(S, ex)
	var d: int = _closeTicks(f, o)   # the gap it closes on the way: it lands this much later
	if d > 0 and DirRecoil.counter(S, f):
		d = 0   # out of his recoil flip (Game Design's 1a): the counter-rush closes the gap at once
	var gapBh: float = maxf(0.0, (_gapDist(f, o) - float(DirData.contact().reach)) / DirInterrupt.BH)
	var lead: int
	var length: int
	var worth: float
	var stop: int
	var inFl: bool = kind == FLURRY
	var held: bool = false   # a wound blow whose button decides it at the wind-up's end
	if wound:
		var w: Dictionary = _wcfg(kind)
		var slot: int = B_TAP if st == 2 else M_TAP
		var last: int = _g(f, slot)
		var gapW: int = p - last
		inFl = last > 0 and gapW <= int(w.gap[1])
		_s(f, slot, p)
		var wind: int = int(er.blast.windupTicks) if energy else (int(c.launcher.windupTicks) if lau else int(w.windupTicks))
		if arrived:
			lead = maxi(int(c.woundLandTicks), wind - (S.tick - p))
		elif already:
			lead = int(c.woundLandTicks)
		else:
			lead = wind
		length = 1 << 20   # his line frees a recovery after the contact (contact)
		worth = float(w.worth)
		if energy:
			worth = float(er.blast.worth)
		elif lau:
			if any:
				worth = float(la().get("worth", c.launcher.worth)) * _power(S, f, o, safety)   # launch anywhere: the launching blow's worth is anywhere.worth x power (9a: 5, where window 1's launcher is 3)
			else:
				worth = float(c.launcher.worth) if launcherRest(S, o) == 0 else float(c.heavy.worth)   # a resting launcher is the hammer: a full heavy on the launcher's wind-up
		elif st == 1 and inFl:
			worth = clampf(float(w.rate) * float(gapW), float(w.rate) * float(w.gap[0]), float(w.worth))   # a medium flurry's blow, by its gap
		stop = int(c.hitstop.heavy if st == 2 else c.hitstop.medium)
		held = not already
		_s(f, HOLD_AT, (now + d - (wind - lead)) if held else 0)   # its wind-up counts from when the gap is closed
		_s(f, CHG, 0)
	else:
		lead = int(er.bolt.contactTicks) if energy else int(c.light.contactTicks)
		length = _g(f, TAP_GAP) if kind == FLURRY else int(c.light.blowTicks)
		worth = (_flurryMul(_g(f, TAP_GAP)) if kind == FLURRY else 1.0) * (float(er.bolt.worth) if energy else 1.0)
		if floor:
			worth = float(c.burst.rate) * float(int(c.burst.floorGap))   # the hold's price: the burst's rate for each tick of its gap, where a mash has the flurry's
		stop = int(c.hitstop.light)
		_s(f, HOLD_AT, 0)
		_s(f, X_LIVE, now if (f.input.lightHeld and rip == 0 and not energy and not floor) else 0)   # still down: it may become the burst (a held bolt is its tap; a new burst needs a new press)
	lead += d
	if returning(S, f):
		# His first blow back from a send has a tell: the defender has a window to strike first, to guard or to perfect-block.
		var rw: int = int(_rcfg().get("firstWindTicks", 10))
		lead += rw
		_s(f, RET_N, 0)
		var rwe = _ev(S, f, "windup", "return", _cellOf(st))
		rwe.target = float(S.fighters.find(o))
		rwe.n = S.tick + lead
		rwe.dur = float(rw)
	_s(f, CLOSE_N, d)
	_s(f, PRE, 0)
	_s(f, GAPV_ON, 0)
	if wound:
		_s(o, GAVE, 0)   # the rival has not given ground against this wind-up yet
	_s(f, FLAV, 1 if energy else (2 if lau else 0))
	_s(f, LC_LATE, 1 if (lau and o.stunTicks <= 0) else 0)   # thrown after the stagger: he can answer it
	if lau and any:
		_ls(f, LA_LAU1, 1)   # his first launcher of the match is thrown (10-26 item 19)
	var dmg: float = worth * _unit()
	# The press behind the blow, for the launch's earners: its weight, its stick and its intent. Its rhythm is the brawl's own.
	var pp: int = DirAlchemy.last(S, f)
	pp = (pp & ~(3 << 8)) if (pp >= 0 and (pp & 1) == weight) else weight
	DirInterrupt.si(f, DirInterrupt.PHRASE_P, pp)
	var k: int = _g(f, STR_K) + 1   # its place among the blows of his string
	_s(f, STR_K, k)
	if rip > 0 and not wound:
		dmg = _unit() * float(c.skillMul)
	if rip > 0:
		dmg += _unit() * float(SimForms.followBonus(S, f))   # forms: a Trial form's perfect follow-up is worth more (0 otherwise)
	var o2 := {"class": "heavy" if wound else "blow", "stop": float(stop) / DirData.TICKS_PER_SEC, "big": wound, "kb": float(c.recoil)}
	# The AI weighs a perfect block against a light or a medium at most once in aiPerfectEveryTicks (a fresh guard
	# press cannot be mashed), and against every heavy.
	if kind != BIG:
		if S.tick - _g(o, PB_AT) < int(c.aiPerfectEveryTicks):
			o2["weighed"] = true
		else:
			_s(o, PB_AT, S.tick)
	var called: String = ("blast" if st == 1 else "bolt") if energy else String(STRENGTH[kind])
	var args := {"a": role, "d": "D" if role == "A" else "A", "dmg": dmg, "o": o2, "brawl": true, "bk": kind,
		"strength": STRENGTH[kind], "flurry": inFl,
		"grade": "none", "k": k, "n": k, "closing": _closes(S, ex, f),
		"charge": 0.0, "hand": "r" if (k % 2) == 1 else "l", "ender": false, "wind": held}
	if floor:
		args["floor"] = true   # a blow of a held X's floor pace
	if energy:
		args["energy"] = called
	args["close"] = d   # the ticks its closing adds, and the gap it closes, in body heights
	args["gap"] = snappedf(gapBh, 0.01)
	if lau:
		args["launcher"] = true
		args["ready"] = any or launcherRest(S, o) == 0   # a launch when one is ready on him; while the launcher rests, the hammer (launch anywhere: always ready)
		if not args["ready"]:
			args["hammer"] = true   # it always lands, it staggers him in place, and the brawl goes on
		if any:
			args["safety"] = safety
			_ls(f, LA_SAFE, safety)
			_ls(f, LA_LHIT, 0)
			_ls(f, LA_LHIT_AT, 0)
			args["power"] = _power(S, f, o, safety)   # string x state x timing; wounds at its landing, freshness at its send
			if safety != 1:
				o2["weighed"] = true   # the AI cannot react to a launcher in time: it answers only by a guess made at the landing before it (_laAnswerPlan)
		args["aim"] = _quarter(f, o)   # the stick's quarter, read once, at the press
	if rip > 0 or (lau and o.stunTicks > 0):   # a launcher inside the stagger always lands; after it, he can answer it
		args["sure"] = true
		o2["noParry"] = true
		o2["weighed"] = true
	if rip > 0:
		o2["ignoreStance"] = true
		args["riposte"] = true
		var rp = _ev(S, f, "riposte", "medium" if wound else "light")
		rp.target = float(S.fighters.find(o))
		rp.n = S.tick + lead
	if quiet(ex) and f == ex.D:
		DirZip.markAnswer(S, ex, f, kind, p, args)
	# The piece, by the blow's cell (docs/combat/brawl-hook.md). A bolt that follows a bolt in his string is the next
	# of his run, with its arm; the launcher's is one that sends where his stick's quarter says.
	var toward: bool = ((pp >> 2) & 3) == 2
	var bolt: bool = energy and st == 0
	var cell: String = "launcher" if lau else (("blast" if st == 1 else "bolt") if energy else ("heavy" if st == 2 else ("medium" if st == 1 else ("burstFloor" if floor else ("lightToward" if toward else ("flurry" if kind == FLURRY else "light"))))))
	var piece: String = _boltRun(S, f, args) if (bolt and _g(f, BOLT_N) >= 1) else ""
	if piece == "":
		piece = _piece(S, f, st, toward, cell, _sendOf(int(args.get("aim", 0))) if lau else "")
	_s(f, BOLT_N, (_g(f, BOLT_N) + 1) if bolt else 0)
	if lau and any:
		var ep: String = _ender(S, f, int(args.get("aim", 0)))
		if ep != "":
			piece = ep   # Combat's enders: the launch that follows his last blow's family and path
			var rc: Dictionary = _enders().get("rechamber", {})
			if not rc.is_empty() and _enderStep >= int(rc.get("fromStep", 3)):
				lead += int(rc.get("ticks", 0))   # the re-chamber's tell: a launch that doesn't follow his last blow's path winds longer, so the reset reads
				if _g(f, HOLD_AT) > 0:
					_s(f, HOLD_AT, _g(f, HOLD_AT) + int(rc.get("ticks", 0)))   # ... and its wind-up counts from the reset
	if piece != "":
		args["piece"] = piece
		if any:
			_ls(f, LA_FP, _famPath(piece))
	# Two light blows that land within tradeTicks of each other are a trade: both land (melee-press-feel.md section 7).
	# Each beat says so, and names the other's piece, so the pair can be staged as one move.
	if not wound and _g(o, LINE) == 1 and not _wound(_g(o, KIND)) and absi(_g(o, CONTACT) - (now + lead)) <= int(c.tradeTicks):
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
	DirCamIntent.blow(S, f, o, args, S.tick + lead)   # the camera-intent feed: a close or a launcher, known at its throw
	_s(f, LINE, 1)
	_s(f, KIND, kind)
	_s(f, CONTACT, now + lead)
	_s(f, FREE_AT, maxi(S.tick + 1, p + length))
	_s(f, LAND_AT, S.tick)
	_s(f, HELD_P, 0)
	_s(f, BLOWS, _g(f, BLOWS) + 1)
	var e = _ev(S, f, "blow", called, "lunge" if arrived else "")   # source lunge: thrown on the tick he arrived by a lunge
	e.target = float(S.fighters.find(o))
	e.n = S.tick + lead
	e.amount = float(p)
	e.dur = float(lead)
	e.k = 1.0 if inFl else 0.0
	if lau and (safety == 1 or not any):
		o.stunTicks = maxi(o.stunTicks, lead + 2)   # the stagger holds until it lands (launch anywhere: only a sure launcher's, so one that isn't sure can be answered)
	if lau:
		_lcClose(S, f, "used")
	if energy:
		var en = _ev(S, f, "energy_reach", called)
		en.target = float(S.fighters.find(o))
		en.n = S.tick + lead
		en.dur = float(lead - d)   # its own time; the landing tick less this is what the closing took
		en.x = f.input.mx
		en.y = f.input.my
	if held:
		var wu = _ev(S, f, "windup", "start", _cellOf(st))
		wu.target = float(S.fighters.find(o))
		wu.n = S.tick + lead
		wu.dur = float(lead - d)   # the wind-up alone: the landing tick less this is what the closing took
		wu.k = 1.0 if lau else 0.0
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


## The piece for his blow, from Combat's pools, by its strength. Combat's sequence rules that the pieces' data can
## say are hard rules here: never one of his last two pieces (DirRecipe.pick, so never three of one running), and no
## two blows running to the gut. The repeat rules count the whole string, whatever the button.
static func _piece(S: SimState, f, st: int, toward: bool, cell: String = "", want: String = "") -> String:
	if not DirRecipe.on():
		return ""
	var pool: String = "power.last" if st == 2 else ("combo.accent" if st == 1 else ("blur.toward" if toward else "blur.base"))
	var named = DirRecipe.rec().get("brawl", {})   # Combat's recipes: the pool each cell draws on
	if cell != "" and named is Dictionary and named.has(cell):
		return _cellPiece(S, f, cell, String(named[cell]), want)
	return _cellPiece(S, f, "", pool, "")   # no cell (a zip's blow, the double hit's), or recipes with no brawl block: the pool of its strength, under the same rules


## A cell's piece, by the recipes' fallback (docs/combat/brawl-hook.md parts 5 and 6). The steps, in order: a piece of
## the cell's pool that is not one of his last two; one of his last two again, the older first; a piece of the pool
## one strength down (fallback.lower), the same two ways. No two blows running go to the gut, at any step: the pool
## is asked for one that does not, where six blind tries were made before. want: the send a launcher's piece must
## have. A send nobody has is the stick's wish and not a rule: it is dropped before a press goes without a piece.
static func _cellPiece(S: SimState, f, cell: String, pool: String, want: String) -> String:
	var was: int = _g(f, GUT) & 1
	var noGut: bool = was == 1
	var salt: int = _g(f, BLOWS) * 8
	var lower: String = String(DirRecipe.rec().get("fallback", {}).get("lower", {}).get(cell, ""))
	var id: String = ""
	for w in ([want, ""] if want != "" else [""]):
		for p in ([pool, lower] if lower != "" else [pool]):
			id = DirRecipe.pickWhere(S, f, p, salt, noGut, w, false)
			if id == "":
				id = DirRecipe.pickWhere(S, f, p, salt, noGut, w, true)
			if id != "":
				break
		if id != "":
			break
	if id == "":
		return ""   # no piece: his sequence stands as it was
	DirRecipe.took(f, id)
	_s(f, GUT, (1 if DirRecipe.toGut(id) else 0) | (was << 1))
	return id


## The send a launcher's piece must have for the stick's quarter (the recipes' launcher.aim: up, down, toward as
## across, away as turned). "" with no stick: the launch planner picks the send then, after the piece is thrown.
static func _sendOf(quarter: int) -> String:
	if quarter <= 0 or quarter > 4:
		return ""
	var aim = DirRecipe.rec().get("launcher", {}).get("aim", {}) if DirRecipe.on() else {}
	return String(aim.get(["up", "toward", "down", "away"][quarter - 1], "")) if aim is Dictionary else ""


## A bolt that follows a bolt in his string (docs/combat/brawl-hook.md part 4): the next piece of one of his runs,
## with the arm that throws it, and never the pool's. The run is drawn when the mash starts, and entered just past
## the bolt he has thrown, so the order Legal passed is kept from the first. "" when the recipes have no runs.
static func _boltRun(S: SimState, f, args: Dictionary) -> String:
	var runs = DirRecipe.rec().get("reach", {}).get("runs", {}).get(DirRecipe.poolKey(f)) if DirRecipe.on() else null
	if not (runs is Array) or runs.is_empty():
		return ""
	if _g(f, BOLT_N) == 1 or _g(f, BOLT_RUN) <= 0 or _g(f, BOLT_RUN) > runs.size():
		var r: int = mini(runs.size() - 1, int(SimRng.keyed(int(S.game.seed), "brawl.boltRun", S.dirS.exN * 4096 + _g(f, BLOWS)) * float(runs.size())))
		var first: Array = runs[r].blows
		var i0: int = 0
		for i in range(first.size()):
			if (String(first[i]).hash() & 0x7fffffff) == f.act.dirI[DirAlchemy.PIECE_1]:
				i0 = i + 1
				break
		_s(f, BOLT_RUN, r + 1)
		_s(f, BOLT_I, i0)
	var row = runs[_g(f, BOLT_RUN) - 1]
	var blows: Array = row.blows
	if blows.is_empty():
		return ""
	var at: int = _g(f, BOLT_I) % blows.size()
	_s(f, BOLT_I, (at + 1) % blows.size())
	var id: String = String(blows[at])
	var arms = row.get("arms", [])
	if arms is Array and at < arms.size():
		args["hand"] = "r" if String(arms[at]) == "lead" else "l"   # lead and free are which arm: Animation mirrors the piece for the free one
	DirRecipe.took(f, id)
	_s(f, GUT, (1 if DirRecipe.toGut(id) else 0) | ((_g(f, GUT) & 1) << 1))
	return id


## His wound blow on its way takes a new piece from a cell (a blow that has become a charge: its piece was chosen
## at the press, before anyone knew the button would stay down).
static func _repiece(S: SimState, ex, f, st: int, cell: String) -> void:
	var named = DirRecipe.rec().get("brawl", {}) if DirRecipe.on() else {}
	if not (named is Dictionary) or not named.has(cell):
		return
	var role: String = "A" if f == ex.A else "D"
	for b in ex.beats:
		if not b.done and b.op == "strike" and b.args != null and b.args.get("brawl", false) and String(b.args.a) == role:
			_s(f, GUT, 3 if (_g(f, GUT) & 3) != 0 else 0)   # the piece chosen at the press was wound and not thrown: the new one is not to the gut if it, or the one before it, was
			var id: String = _piece(S, f, st, false, cell)
			if id != "":
				b.args["piece"] = id
			return


# ---------------------------------------------------------------- the run and the trade (melee-press-feel.md section 3)

## True when f's next light or flurry blow that lands is the close: his run is at runToClose, or a trade that reached
## its limit broke his way. Never while the rival is still in a close's stagger, or inside closeGuardTicks of his
## recovery from it (section 9d): f's run still counts then, and a run of runToClose closes on his first blow after it.
static func _closes(S: SimState, ex, f) -> bool:
	var o = ex.D if f == ex.A else ex.A
	if _g(o, SAFE_UNTIL) < 0 or S.tick < _g(o, SAFE_UNTIL):
		return false
	return _g(f, RUN) >= RUN_U * int(cfg().flurry.runToClose) or _g(ex.A, TRADE_WIN) == (1 if f == ex.A else 2)


## The trade's clock starts again: after a close, a stagger, a real answer, and when the trade stops.
static func _tradeReset(ex) -> void:
	_s(ex.A, TRADE_T0, 0)
	_s(ex.A, TRADE_WIN, 0)


## Once a live tick: a run lapses runLapseTicks after his last landed blow. A trade is on while both have landed a
## light or a flurry blow inside that time; it cannot pass tradeMaxTicks without a close. At the limit it breaks, on
## the first live tick at or after it (a hit-stop holds the sim, and so the break): a lead of more than levelWithin
## takes the close, at the limit or on the tick one appears after it, and his next landed blow is the close. Runs
## within levelWithin are a level trade, and it goes on. Still level at doubleTicks, it is the double hit
## (brawl-second-pass.md section 7). The seeded draw and its momentum are withdrawn.
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
	var t: int = S.tick - _g(ex.A, TRADE_T0)
	if _g(ex.A, TRADE_WIN) != 0 or _g(ex.A, DBL_AT) != 0 or t < int(fl.tradeMaxTicks):
		return
	if absi(_g(ex.A, RUN) - _g(ex.D, RUN)) <= RUN_U * int(fl.levelWithin):
		if t >= int(fl.doubleTicks) and not quiet(ex) and ex.A.stunTicks <= 0 and ex.D.stunTicks <= 0 and ex.A.rush == null and ex.D.rush == null:
			_double(S, ex)
		return
	var w: int = 1 if _g(ex.A, RUN) > _g(ex.D, RUN) else 2
	_s(ex.A, TRADE_WIN, w)
	var who = ex.A if w == 1 else ex.D
	var e = _ev(S, who, "trade_break", "lead")
	e.target = float(S.fighters.find(ex.D if w == 1 else ex.A))
	e.n = t
	# For QA: the limit; and the two runs at the break, his and the rival's. A break is always for a lead now.
	e.amount = float(int(fl.tradeMaxTicks))
	e.x = float(_g(who, RUN)) / float(RUN_U)
	e.y = float(_g(ex.D if w == 1 else ex.A, RUN)) / float(RUN_U)
	SimEvents.feed(S, "THE TRADE BREAKS", who.name + "'s next blow that lands closes it, after " + str(t) + " ticks")


# ---------------------------------------------------------------- a blow lands

## A blow of the brawl lands (DirExchange.runBeat, in place of the planned strike): the reach, read as it lands; the
## strike; then what it did. A wound blow has a reach past striking distance (medium.reachBh, heavy.reachBh, and up to
## heavy.charge.reachBh as a charge fills); out of it, it misses, and he is open for its recoverWhiff. A blow that
## lands places its attacker by at most give.closeMaxBh. Then: a heavy's armour, a guard, the run, the close, the
## reel, the stagger, the launcher's and the full charge's launch, the charge's and the blast's knock-back.
static func contact(S: SimState, ex, b) -> void:
	var a = b.args
	var f = ex.A if a.a == "A" else ex.D
	var o = ex.D if a.a == "A" else ex.A
	var c: Dictionary = cfg()
	var kind: int = int(a.bk)
	var wound: bool = _wound(kind)
	var now: int = _now(S)
	var wind: bool = bool(a.get("wind", false))
	var energy: String = String(a.get("energy", ""))
	_s(f, LINE, 0)
	_s(f, HOLD_AT, 0)
	_s(f, CHG, 0)
	_s(f, FLAV, 0)
	_s(f, CLOSE_N, 0)
	_s(f, LAND_AT, S.tick)
	if wound:
		_s(f, FREE_AT, S.tick + int(_wcfg(kind).recover))   # his line is free this long after a wound blow that lands (its follow-through is animation)
	if ex.branch != "" or (f.stunTicks > 0 and not bool(a.get("double", false))) or f.state != "locked" or o.state != "locked":
		if wound:
			_s(f, FREE_AT, S.tick + int(_wcfg(kind).recoverWhiff))   # a wound blow that met nothing: the punish
			if wind:
				_wEnd(S, f, kind, 3)
		if energy != "":
			_eLand(S, ex, f, o, energy, "miss")
		if bool(a.get("double", false)) and ex.branch == "" and _setPiece(ex):
			over(S, ex, "break")   # the double hit's other blow broke a region and this one is lost: the break plays
		return   # he was staggered, or one of them was sent off, before it landed: the blow is lost
	var special: bool = bool(a.get("double", false)) or bool(a.get("sure", false)) or bool(a.get("zip", false))
	# The reach, read as it lands. A blow by rule (the double hit's, a sure one, a zip's) keeps the strike's own limit.
	var ct: Dictionary = DirData.contact()
	var far: float = (absf(SimWrap.sdx(f.x, o.x)) if (_lg(o, LA_POP_UNTIL) > S.tick or _lg(f, LA_POP_UNTIL) > S.tick) else DirBands.dist(f, o)) - float(ct.offset) + (0.0 if special else float(_g(f, PRE)) / 16.0)   # past striking distance, with what its own step through its reach has covered added back
	if _g(f, GAPV_ON) == 1 and wound and not special:
		far = float(_g(f, GAPV)) / 16.0   # a blow with a wind-up: the gap as counted since it began (tick, _giveStep)
	_s(f, PRE, 0)
	_s(f, GAPV_ON, 0)
	var reach: float = (float(ct.reach) * float(ct.placementReaches) - float(ct.offset)) if special else (_reachOf(a, kind) - float(c.give.edgeBh)) * DirInterrupt.BH
	if far > reach:   # the very edge of a reach (give.edgeBh) doesn't connect
		_miss(S, ex, f, o, kind, wind, energy)
		return
	_stepIn(S, ex, f, o, 1)   # he is placed for the contact, and never further than a closing step
	var zipOnly: bool = bool(a.get("zip", false)) and not bool(a.get("sure", false)) and not bool(a.get("double", false))
	if (not special or zipOnly) and absf(SimWrap.sdx(f.x, o.x)) > float(ct.reach):
		# Placed, the two still stand beyond the strike's reach: it meets nothing. No damaging strike of a brawl lands
		# from beyond contact.reach of horizontal distance, whatever its own reach said before the step. A zip's blow
		# keeps to it too: its exit is then read as for a blow that did not land.
		_miss(S, ex, f, o, kind, wind, energy, true)
		if zipOnly and S.dirS.ex == ex and ex.branch == "" and not _setPiece(ex):
			DirZip.onBlow(S, ex, f, o, a, 0)
		return
	if wind:
		_wEnd(S, f, kind, 1)
	a.o["placed"] = true
	ex.kind = "heavy" if kind == BIG else ("medium" if kind == MEDIUM else "light")   # the core reads the exchange's kind as the blow's weight
	ex.sA = 0.0 if quiet(ex) else ex.A.stance   # a zipper has no guard in reach
	ex.sD = ex.D.stance
	if o.stance == 1.0 and (_g(o, LINE) != 0 or now < _g(o, OPEN_UNTIL) or o.stunTicks > 0 or DirRally.counterLive(S, f, o)):
		# A fighter with a blow of his own on its way, open after a miss, or staggered is not guarding, whatever he holds;
		# nor a rally's chaser against its counter-rush (10-26 item 30: he is committed to his arrival; a perfect block aside).
		if o == ex.A:
			ex.sA = 0.0
		else:
			ex.sD = 0.0
	if bool(a.get("zip", false)):
		DirZip.beforeBlow(S, ex, f, a)
	# What he is doing as it lands: winding a wound blow of his own, and a heavy's is armoured.
	var oKind: int = _g(o, KIND)
	var oWinding: bool = _windOn(o)
	var armour: bool = false
	var dmg: float = float(a.dmg)
	var laStop: bool = false   # launch anywhere: a second light into an answerable launcher's wind-up stops it (2026-10-18, 1a)
	if oWinding and oKind == BIG and (_g(o, FLAV) == 0 or (_g(o, FLAV) == 2 and anywhere())) and not special:   # launch anywhere: the launcher is armoured against lights too
		if not wound and _g(o, FLAV) == 2 and _lg(o, LA_SAFE) == 3 and _lg(o, LA_LHIT) >= 1 and _flurried(S, o):
			laStop = true   # its armour has taken its one light, and this second one lands close behind it (5a)
		elif not wound:
			armour = true
			dmg *= float(c.heavy.armour.lightMul)
			if _g(o, FLAV) == 2:
				_ls(o, LA_LHIT, _lg(o, LA_LHIT) + 1)
				_ls(o, LA_LHIT_AT, _now(S))   # the newest light it took: the next must land within armourLightTicks of it
		elif kind == MEDIUM and now - _g(o, HOLD_AT) >= int(c.heavy.armour.mediumUntilTicks):
			armour = true
	if kind == MEDIUM and energy == "" and not special and (ex.sD if o == ex.D else ex.sA) == 1.0:
		dmg *= float(c.medium.guardChipMul)   # a medium on a guard chips double, and tires it twice as fast
	var landed0: int = DirInterrupt.gi(f, DirInterrupt.LANDED)
	var was: bool = _inTick
	_inTick = true   # the exchange's clock has stepped this tick: a blow scheduled from inside this beat (a reversal's blow) counts from here
	if energy != "":
		_shotHit(S, ex, f, o, dmg, a, ex.sD if o == ex.D else ex.sA)   # a point-blank shot is the blast's own hit, with no exchange
	else:
		DirMelee.weigh(S, a.o, DirRally.sellWeight(S, f, o, a, DirMash.name(S, f, weightOf(a))))   # hit-stop by weight: the blow names its weight (a mash's later blows light_flow)
		DirMelee.strike(S, ex, f, o, dmg, a.o)
	_inTick = was
	f.ambush = false   # an ambush is its first blow
	if S.dirS.ex != ex or ex.cancel or ex.branch != "" or S.game.ko != null:
		return   # a perfect block took the exchange over
	if bool(a.get("double", false)):
		# One of the double hit's two blows: no run, no reel, no close. When both have landed they are thrown apart.
		_s(ex.A, DBL_N, _g(ex.A, DBL_N) + 1)
		if _g(ex.A, DBL_N) < 2 and _doubleLeft(ex):
			return   # the other's blow lands on this tick too, whatever this one broke: both are hit
		if _setPiece(ex):
			over(S, ex, "break")
		elif _g(ex.A, DBL_N) >= 2:
			_thrownApart(S, ex)
		return
	if bool(a.o.get("turned", false)):
		if bool(a.get("zip", false)):
			DirZip.onBlow(S, ex, f, o, a, 2)   # a zip's blow turned: he is countered
		if energy != "":
			_eLand(S, ex, f, o, energy, "guard")
		return   # a perfect block turned it (section 9f): he staggers in place and the brawl goes on
	if bool(a.get("zip", false)):
		# A zip's one blow: its reading's reel or stagger, and the exit is read (DirZip.onBlow). No run, no close.
		var hit: bool = DirInterrupt.gi(f, DirInterrupt.LANDED) != landed0
		if hit:
			_s(f, STRING_N, _g(f, STRING_N) + 1)
		if not _setPiece(ex):
			DirZip.onBlow(S, ex, f, o, a, 1 if hit else 0)
		else:
			over(S, ex, "break")
		return
	if quiet(ex) and f == ex.D and DirInterrupt.gi(f, DirInterrupt.LANDED) != landed0:
		DirZip.onHit(S, ex, o, f, a)   # a blow landed on a zipper in reach: he is caught, or countered
	if _setPiece(ex):
		over(S, ex, "break")   # the blow broke a limb: the break launch plays in this exchange
		return
	if DirInterrupt.gi(f, DirInterrupt.LANDED) == landed0:
		# Blocked: it chips, and no run changes. A heavy on a guard staggers the blocker in place (the set guard and
		# the fresh one are C2b's). A shot on a guard wore him by the blocked shot's rule, and no more.
		if energy != "":
			_eLand(S, ex, f, o, energy, "guard")
		if f.stunTicks > 0 and sureAgainst(ex, f):
			return   # he reversed it (section 9f): the attacker staggers in place, and the guard is not broken
		if kind == BIG:
			_tradeReset(ex)
			if not (DirRally.breakDazes(a) and DirRally.daze(S, ex, f, o, "guard_break")):   # 10-26 items 23, 24: only a charged blow or a tapped heavy outside a string dazes
				_stagger(S, ex, f, o, int(c.heavy.staggerTicks), "", true)   # a broken guard is an opening (23d 1: with the rally on, a daze)
			var gb = _ev(S, o, "guard_break")
			gb.target = float(S.fighters.find(f))
			gb.n = int(c.heavy.staggerTicks)
			SimEvents.feed(S, f.name + " BREAKS THE GUARD", o.name + " staggers in place for " + str(int(c.heavy.staggerTicks)) + " ticks")
		return
	if DirRally.turn(S, ex, f, o, a):
		return   # 23d 10: his counter-rush lands on the chaser in the air: a full send, and the rally is his
	_s(f, STRING_N, _g(f, STRING_N) + 1)
	if anywhere():
		_ls(f, LA_LINK, S.tick)   # his string's link: B within anywhere.link of this is the launcher
		_ls(o, LA_HITK, (LA_RIPK if (popOn() and bool(a.get("riposte", false))) else kind) + 1)   # (with pops, a perfect follow-up is hard to answer)
		_laAnswerPlan(S, f, o)   # an AI he hits may guess now that a launcher follows (never by reacting to one)
		_linkCue(S, f, o)   # UI's lit B: his B is the launcher for the link
	if DirGrapple.telling(o):
		DirGrapple.stopped(S, ex, o)   # a blow that lands in a catch's tell stops it: blows beat grabs
	if armour:
		if energy != "":
			_eLand(S, ex, f, o, energy, "armour")
		return   # it met a heavy's armour: its damage, and nothing more (no run, no reel, no close)
	if energy != "":
		_eLand(S, ex, f, o, energy, "hit", energy == "blast" and _g(f, RUN) >= RUN_U * int(c.energy.reach.blast.enderRun))
	# A wound blow ends the wind-up it lands on: a medium's always, a heavy's before its armour holds a medium.
	if (wound or laStop) and oWinding and _g(o, LINE) != 0:
		_wEnd(S, o, oKind, 2)
		_s(o, HOLD_AT, 0)
		_drop(S, ex, o)
		oWinding = false
	if energy == "blast" and _g(f, RUN) >= RUN_U * int(c.energy.reach.blast.enderRun):
		# The blast as a string's ender (section 5b, re-ruled in 14): his run is enderRun or more as it lands. A
		# knock-back of its own length along the stick's lean, half a set-up, and the brawl ends. Thrown cold it is a
		# medium with its own reel (below): an ender, and not an opener.
		_s(f, LL_AT, S.tick)
		_knock(S, ex, f, o, float(c.energy.reach.blast.knockBh), _quarter(f, o), bool(c.energy.reach.blast.halfSetup))
		return
	if bool(a.get("riposte", false)) or bool(a.get("reversal", false)):
		# A riposte, or a reversal's blow: on the brink it counts as a close does. The brawl goes on.
		_s(f, LL_AT, S.tick)
		if wound:
			_stagger(S, ex, f, o, int(c.heavy.staggerTicks), "heavy")
		else:
			_reel(S, o, int(c.riposteReelTicks))
		DirExchange.decisive(S, ex, f, o, "knockback", "riposte")
		if _setPiece(ex):
			over(S, ex, "finisher")
		return
	if kind == BIG and (bool(a.get("launcher", false)) or bool(a.get("charged", false))):
		_s(f, LL_AT, S.tick)
		_bigLanded(S, ex, f, o, a)   # the launcher, or a charged heavy: it sends him, whatever his run
		return
	var closing: bool = _closes(S, ex, f)
	_s(f, LL_AT, S.tick)
	if closing:
		# The close: a stagger in place, decisive at half a set-up, whatever threw it. The brawl stays together; his
		# run is spent, the rival's is cleared, his string is closed, and the trade's clock starts again.
		_s(f, RUN, 0)
		_s(o, RUN, 0)
		_tradeReset(ex)
		_s(o, SAFE_UNTIL, -1)   # no second close on him until closeGuardTicks after he recovers from this one
		_strEnd(f)
		_stagger(S, ex, f, o, int(c.flurry.staggerTicks), "flurry", true)   # the close is an opening
		SimEvents.feed(S, f.name + " CLOSES", o.name + " staggers in place for " + str(int(c.flurry.staggerTicks)) + " ticks")
		DirExchange.decisive(S, ex, f, o, "knockback", "blurPlain")
		if _setPiece(ex):
			over(S, ex, "finisher")
		return
	# The run (in quarters of a point: a burst's blow adds half a point): his goes up and the rival's comes down by
	# replyTakes. A landed medium counts flurry.runBy.medium both ways, so a flurry of mediums out-runs slow lights.
	var bolt: bool = energy == "bolt"
	var pts: int = int(round(float(c.flurry.runBy.medium) * float(RUN_U))) if (kind == MEDIUM and energy == "") else RUN_U
	if o.stunTicks <= 0 or bool(c.flurry.staggeredAddsRun):
		_s(f, RUN, _g(f, RUN) + (int(c.burst.runHalves) * RUN_U / 2 if bool(a.get("burst", false)) else (int(c.energy.reach.bolt.runHalves) * RUN_U / 2 if bolt else pts)))
	_s(o, RUN, maxi(0, _g(o, RUN) - pts * int(c.flurry.replyTakes)))
	if anywhere() and not (bool(la().get("placedOnly", false)) and weightOf(a) == "light_mash"):   # 10b: a mashed or burst blow builds no string
		var chNow: int = _now(S)
		_ls(f, LA_CH_N, (_lg(f, LA_CH_N) + 1) if (_lg(f, LA_CH_AT) > 0 and chNow - _lg(f, LA_CH_AT) <= int(la().get("chainGapTicks", 24))) else 1)
		_ls(f, LA_CH_AT, chNow)   # 2a: his landed blows in one chain of links
	if DirRally.whiffPunish(S, ex, f, o, a):
		return   # 23d 1: his heavy's whiff, punished: a daze in place of the reel
	if kind == BIG:
		_bigLanded(S, ex, f, o, a)
		return
	var reel: int = (int(c.energy.reach.blast.reelTicks) if energy == "blast" else int(c.medium.reelTicks)) if kind == MEDIUM else (int(c.burst.reelTicks) if bool(a.get("burst", false)) else (int(c.energy.reach.bolt.reelTicks) if bolt else int(c.flurry.reelTicks)))
	if oWinding:
		_s(o, REEL_AT, maxi(_g(o, REEL_AT), (_g(o, CONTACT) if _g(o, LINE) == 1 else now) + reel))   # a light on a winding medium: its reel waits until his blow has landed (one held past its wind-up has no landing tick yet: the reel counts from now)
	else:
		_reel(S, o, reel)


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
	if _g(f, LINE) != 0 and _wound(_g(f, KIND)) and _g(f, HOLD_AT) > 0:
		_wEnd(S, f, _g(f, KIND), 3)   # his wind-up is lost with it
	if _g(f, LINE) != 0 and _g(f, GUT) != 0:
		_s(f, GUT, 3 if (_g(f, GUT) & 3) != 0 else 0)   # a blow lost before it lands: his next is not to the gut if the lost one, or the one before it, was
	_s(f, LINE, 0)
	_s(f, HOLD_AT, 0)
	_s(f, CHG, 0)
	_s(f, BURST_N, 0)
	_s(f, HELD_P, 0)
	_s(f, FLAV, 0)
	_s(f, CLOSE_N, 0)
	_s(f, AI_HOLD, 0)
	_lcClose(S, f, "lapsed")
	_s(f, FREE_AT, mini(_g(f, FREE_AT), S.tick))
	_strEnd(f)


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


# ---------------------------------------------------------------- depth: the line and its frame (D1a)

## The frame, for the director's part of one tick (not state: it opens in lineEnter and closes in lineLeave).
static var _frOn: bool = false
static var _frX: float = 0.0      # the pair's middle as the frame opened: along the street, and in depth
static var _frZ: float = 0.0
static var _frCos: float = 1.0    # the line's direction: along the street, and in depth (the sine with its side)
static var _frSin: float = 0.0
static var _frVz: float = 0.0     # the pair's speed in depth for this tick, units a second
static var _frA = null
static var _frD = null
static var _frP: PackedFloat64Array = PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])   # where each stood as it opened
static var _dc: Dictionary = {}


## The director's own depth numbers (data/combat/depth.json, "director"; the file is Simulation's).
static func _dcfg() -> Dictionary:
	if _dc.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/depth.json"))
		var d: Dictionary = j.get("director", {}) if j is Dictionary else {}
		_dc = {"lineSinMin": float(d.get("lineSinMin", 0.1736)), "lineSinMax": float(d.get("lineSinMax", 0.5)),
			"arriveSin": float(d.get("arriveSin", 0.342)), "homeAfterTicks": int(d.get("homeAfterTicks", 30)),
			"homeBhPerSec": float(d.get("homeBhPerSec", 0.5))}
	return _dc


## The depth a ground or a face is read at from inside the brawl: the pair's middle while the frame is open, and
## the plane otherwise (so with depth off every read is today's).
static func _gz() -> float:
	return _frZ if _frOn else 0.0


## +1 when a body at f has more room toward the camera than away from it, else -1 (World's depthRoom).
static func _roomSide(S: SimState, f) -> int:
	var b: Array = WorldLanes.body()
	var room: Array = WorldLanes.depthRoom(S, f.x, f.y, f.z, float(b[0]), float(b[2]))
	return 1 if (float(room[1]) - f.z) >= (f.z - float(room[0])) else -1


## An approach ends a little to one side of D in depth, on the side with more room, so the attacker arrives on a
## line (DirBands._startRush; Rush.offZ). off: the rush's offset along the street.
static func arriveOff(S: SimState, D, off: float) -> float:
	return float(_roomSide(S, D)) * float(_dcfg().arriveSin) * absf(off)


## The line as a brawl starts: from the way the attacker came in, held between lineSinMin and lineSinMax (10 and 30
## degrees). lineSide is +1 when the fighter further along the street is the nearer to the camera. Two who stand
## at one depth take the smallest angle, with the attacker on the side that has more room. The carry's depth part
## is what the two were moving at in depth, by the brawl's carryShare.
static func _lineStart(S: SimState, ex) -> void:
	var dc: Dictionary = _dcfg()
	var A = ex.A
	var D = ex.D
	var dx: float = SimWrap.sdx(D.x, A.x)
	var dz: float = A.z - D.z
	var hl: float = SimDetMath.hypot(dx, dz)
	var side: int = _roomSide(S, D) * (1 if dx >= 0.0 else -1)
	if absf(dz) > 0.5 and dx != 0.0:
		side = 1 if (dz > 0.0) == (dx > 0.0) else -1
	S.dirS.lineSin = clampf(absf(dz) / maxf(hl, 1.0), float(dc.lineSinMin), float(dc.lineSinMax))
	S.dirS.lineSide = side
	S.dirS.carryZ = (A.vz + A.vzX + D.vz + D.vzX) * float(cfg().carryShare)
	S.dirS.homeWait = 0


## The frame opens (DirExchange.tick, before the brawl's part of the tick): each fighter's x becomes his distance
## along the line from the pair's middle, and both take the middle's depth. False when there is none to open:
## depth is off, or ex is not a running brawl with both held.
static func lineEnter(S: SimState, ex) -> bool:
	if not S.depthOn or _frOn or not isBrawl(ex) or ex.branch != "" or ex.A.state != "locked" or ex.D.state != "locked":
		return false
	SimDepth.enabled()   # the core's depth numbers are loaded
	var A = ex.A
	var D = ex.D
	var xc: float = SimWrap.wrap(A.x + SimWrap.sdx(A.x, D.x) * 0.5)
	var zc: float = (A.z + D.z) * 0.5
	var sn: float = S.dirS.lineSin
	_frX = xc
	_frZ = zc
	_frCos = sqrt(maxf(0.0, 1.0 - sn * sn))
	_frSin = sn * float(S.dirS.lineSide)
	_frVz = 0.0
	_frA = A
	_frD = D
	var k: int = 0
	for f in [A, D]:
		_frP[k] = f.x
		_frP[k + 1] = f.y
		_frP[k + 2] = f.z
		k += 3
		var hx: float = SimWrap.sdx(xc, f.x)
		var h: float = SimDetMath.hypot(hx, f.z - zc)
		if hx < 0.0 or (hx == 0.0 and (f.z - zc) * _frSin < 0.0):
			h = -h
		f.x = SimWrap.wrap(xc + h)
		f.z = zc
		f.zT = zc
	ex.z = zc
	_frOn = true
	return true


## The frame closes (DirExchange.tick, wherever the brawl's part of the tick ends): each fighter is put back on the
## line in the world, from where he stood as it opened, through the core's step call. So a face stops him as it
## stops any step, and he is back on the line by the next tick. A fighter sent off inside the frame is put back
## the same way.
static func lineLeave(S: SimState) -> void:
	if not _frOn:
		return
	_frOn = false
	var k: int = 0
	for f in [_frA, _frD]:
		var h: float = SimWrap.sdx(_frX, f.x)
		var y: float = f.y
		f.x = _frP[k]
		f.y = _frP[k + 1]
		f.z = _frP[k + 2]
		k += 3
		SimFighter.stepTo(S, f, _frX + h * _frCos, y, _frZ + h * _frSin)
	_frA = null
	_frD = null


## The pair's speed in depth for this tick, once from _move with the frame open. One sum: the push and the pull's
## share along the line (wx, the pair's speed along it, by the line's sine), the carry's depth part as it fades,
## and the ease home (after homeAfterTicks live ticks with no stick, toward the middle of its street or crossing,
## at homeBhPerSec). One cap: the core's (depth.json maxBhPerSec). Then World's room: the pair's middle never goes
## where a body has none.
static func _moveZ(S: SimState, ex, wx: float, held: bool) -> void:
	var dc: Dictionary = _dcfg()
	var d = S.dirS
	var wz: float = wx * _frSin
	var cn: int = _g(ex.A, CARRY_N)
	if d.carryZ != 0.0:
		wz += d.carryZ * float(cn) / maxf(1.0, float(int(cfg().carryTicks)))
		if cn <= 0:
			d.carryZ = 0.0
	if held:
		d.homeWait = 0
	else:
		d.homeWait += 1
		if d.homeWait >= int(dc.homeAfterTicks):
			var hm: Array = WorldLanes.home(S, _frX, _frZ, 0.0)
			var sp: float = float(dc.homeBhPerSec) * DirInterrupt.BH
			wz += clampf((float(hm[1]) - _frZ) / SimConst.DT, -sp, sp)
	wz = clampf(wz, -SimDepth.cap, SimDepth.cap)
	var b: Array = WorldLanes.body()
	var m: PackedFloat64Array = _mid(ex)
	var room: Array = WorldLanes.depthRoom(S, _frX, m[1], _frZ, float(b[0]), float(b[2]) + SimDepth.margin)
	var lo: float = minf(float(room[0]), _frZ)
	var hi: float = maxf(float(room[1]), _frZ)
	_frVz = clampf(wz, (lo - _frZ) / SimConst.DT, (hi - _frZ) / SimConst.DT)



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
	var out := {"x": m[0], "y": m[1], "vx": (ex.A.vx + ex.D.vx) * 0.5 * keep, "vy": (ex.A.vy + ex.D.vy) * 0.5 * keep,
		"part": _g(ex.A, PART_N), "double": (maxi(0, dbl - _now(S)) if dbl > 0 else -1)}
	if S.depthOn:   # D1: the middle's depth and its speed, and the line (its sine, and which way it is turned)
		out["z"] = (ex.A.z + ex.D.z) * 0.5
		out["vz"] = (ex.A.vz + ex.D.vz) * 0.5 * keep
		out["lineSin"] = S.dirS.lineSin
		out["lineSide"] = S.dirS.lineSide
	return out


## True while a double hit's two blows are on their way: nothing either fighter presses counts until they land.
static func doubling(ex) -> bool:
	return isBrawl(ex) and ex.branch == "" and _g(ex.A, DBL_AT) > 0


## The button's cell for a press_ack: x a light, y a heavy, b a signature.
static func _cell(kind: String) -> String:
	return "b" if kind == "sig" else ("y" if kind == "heavy" else "x")


## True when the pair's middle at (x, y) is inside a standing building's box. The ground is never the answer here: the
## core holds a fighter on it, so a brawl slides along the ground and up a ridge by itself.
static func _walled(S: SimState, x: float, y: float) -> bool:
	var yy: float = maxf(y + 0.5 * DirInterrupt.BH, WorldTerrain.groundY(S, x, _gz()) + 0.01)
	return WorldStructures.blockedAt(S, x, yy, _gz(), 0.0)


## His launcher's button is still down as its wind-up ends: the guarantee is lost (brawl-second-pass.md section 3).
## From here it is a heavy like any other: it winds on to the heavy's own time, the stagger is held no longer, and
## it can be blocked, or miss.
static func _unlaunch(S: SimState, ex, f) -> void:
	var c: Dictionary = cfg()
	var role: String = "A" if f == ex.A else "D"
	var o = ex.D if f == ex.A else ex.A
	var more: int = maxi(1, int(c.heavy.windupTicks) - int(c.launcher.windupTicks))
	for b in ex.beats:
		if b.done or b.op != "strike" or b.args == null or not b.args.get("brawl", false) or String(b.args.a) != role:
			continue
		b.args.erase("launcher")
		b.args.erase("sure")
		b.args.erase("aim")
		b.args["dmg"] = float(c.heavy.worth) * _unit()
		for key in ["ignoreStance", "noParry", "weighed"]:
			b.args.o.erase(key)
		b.t = ex.t + (float(more) - 0.25) / DirData.TICKS_PER_SEC
		_s(f, FLAV, 0)
		_s(f, CONTACT, _now(S) + more)
		_s(f, HOLD_AT, _now(S) + more - int(c.heavy.windupTicks))
		var wu = _ev(S, f, "windup", "start", "b")
		wu.target = float(S.fighters.find(o))
		wu.n = S.tick + more
		wu.dur = float(more)
		return


## f staggers o in place for `ticks` (a close, a landed heavy, a broken guard, a wound riposte): his blow on its way
## is lost. text: the stagger cue's text, or "" when the caller sends a cue of its own. opening: it is one of the
## openings that give f the launcher (a flurry's close, a broken guard).
static func _stagger(S: SimState, ex, f, o, ticks: int, text: String, opening: bool = false) -> void:
	o.stunTicks = maxi(o.stunTicks, ticks)
	_drop(S, ex, o)
	if text != "":
		var st = _ev(S, o, "stagger", text)
		st.target = float(S.fighters.find(f))
		st.n = ticks
	if opening:
		_lcOpen(S, ex, f, o, ticks, text if text != "" else "guard_break")


# ---------------------------------------------------------------- launch anywhere (the thirteenth round, behind its switch)

## Its integers sit after the press wait's (_laBase), found at run time and sized only when written: with
## brawl.launcher.anywhere.enabled off nothing is written, so play and the hash are window 1's.
const LA_LINK: int = 0    # S.tick his last blow landed clean: B within anywhere.link of it is the launcher
const LA_HITK: int = 1    # the kind of the last blow that landed clean on him, plus 1 (a reel from a medium or a heavy is hard to answer)
const LA_POW: int = 2     # the landing launcher's power x 1000, for its send; 0 none
const LA_ANS: int = 3     # S.tick until which the AI's guess that a launcher follows holds; 0 none
const LA_AILW: int = 4    # the landing the AI last weighed a launch in its string for
const LA_FP: int = 5      # his last blow's family and path for Combat's enders: family x 8 + path, plus 1
const LA_FRESH: int = 6   # the kinds of send marked on him (up, across, down, behind, building), four live ticks each; kept across brawls
const LA_SAFE: int = 26   # the launcher on his line: its safety (1 sure, 2 hard, 3 answerable)
const LA_LHIT: int = 27   # ... and the lights its armour has taken (an answerable one takes one)
const LA_LHIT_AT: int = 28   # ... and the live tick the newest of them landed (5a: a second must land within anywhere.armourLightTicks)
const LA_CH_N: int = 29     # his blows landed in one chain of links (2a: each within anywhere.chainGapTicks of his last)
const LA_CH_AT: int = 30    # ... and the live tick his last landed
const LA_PAY: int = 31      # a launcher's send on him: its power x 1000, plus 1, for its journey's pay (9a); 0 none
const LA_PAYN: int = 32     # ... and the launch number it was for (a later send is never paid as this one)
const LA_WAS: int = 33      # 1 while he was launched at the director's last tick (10c)
const LA_LANDED: int = 34   # the live tick he last came down from a launch, plus 1: his wary window (10c); 0 none
const LA_POP_UNTIL: int = 35   # the pop (rulings-2026-10-23c 1): S.tick he comes down in reach; 0 not popped
const LA_POP_AT: int = 36      # ... S.tick it began, plus 1
const LA_POP_TECH: int = 37    # ... his landing: 1 the AI will tech it, 2 teched (he lands set); 0 neither
const LA_POP_BURST: int = 38   # ... 1 the AI will burst out after pop.burstAfter
const LA_POP_SPK: int = 39     # 1 while his coming down is a spike's (23c 9): its landing digs a crater
const LA_POP_STUN: int = 40    # S.tick his juggle's stun ends (the pop and its landing, or the spike and its recovery): no opening before it
const LA_LAU1: int = 41        # 1 once he has thrown a launcher this match (10-26 item 19: the AI never guesses at his first)
const LA_N: int = 42
const LA_RIPK: int = 7         # LA_HITK's mark for a perfect follow-up (the riposte): hard to answer, as a medium (with pops)


static func la() -> Dictionary:
	return cfg().get("launcher", {}).get("anywhere", {})


## Game Design's 9a (rulings-2026-10-23 §9): a launcher's send pays. Its power goes with the send (DirMelee, after
## the send, so the launch number is the journey's), and World's contact pay reads payMul while that journey lasts.
static func paySend(o, p: float) -> void:
	if not anywhere() or float(la().get("landPay", 0.0)) <= 0.0:
		return
	_ls(o, LA_PAY, int(round(maxf(0.0, p) * 1000.0)) + 1)
	_ls(o, LA_PAYN, int(o.launchN))


## The pay of his journey's wear (WorldContact._pay): x (1 + anywhere.landPay x power) for a launcher's send, else 1.
## Game Design's 10c: each live tick (DirExchange.dirUpdate), the tick each fighter came down from a launch (left
## "launched"), which opens his wary window in _safety.
static func laTick(S: SimState) -> void:
	if popOn():
		_popTick(S)
	if not anywhere() or int(la().get("waryTicks", 0)) <= 0:
		return
	for f in S.fighters:
		var was: int = _lg(f, LA_WAS)
		var up: int = 1 if f.state == "launched" else 0
		if was == 1 and up == 0:
			_ls(f, LA_LANDED, _now(S) + 1)
		if was != up:
			_ls(f, LA_WAS, up)


static func payMul(f) -> float:
	if not anywhere():
		return 1.0
	var v: int = _lg(f, LA_PAY)
	if v <= 0 or _lg(f, LA_PAYN) != int(f.launchN):
		return 1.0
	return 1.0 + float(la().get("landPay", 0.0)) * float(v - 1) / 1000.0


## Game Design's pop (rulings-2026-10-23c): on under launch anywhere with anywhere.pop.enabled.
static func popOn() -> bool:
	return anywhere() and bool(popCfg().get("enabled", false))


static func popCfg() -> Dictionary:
	return la().get("pop", {})


## The landing launcher's power after freshness, for pop or send: the stick's kind of send (up, toward, down, away),
## or with no stick the freshest kind, as the planner prefers fresh. Marks come from sends only.
static func _popPower(S: SimState, f, o, aim: int) -> float:
	var p: float = float(_lg(f, LA_POW)) / 1000.0
	if aim >= 1 and aim <= 4:
		return p * freshMul(S, o, aim - 1)
	var best: float = 0.0
	for kd in range(5):
		best = maxf(best, freshMul(S, o, kd))
	return p * best


## f pops o (rulings-2026-10-23c 1): up and back down in reach, the brawl holding; his blow on its way is lost. The
## pop counts stringPoints toward f's next launcher (2: the launcher's own landing counted one). A second pop while
## he is still up lands him instead: down where the first began, with no tech. Cue "pop": up, slam.
static func _pop(S: SimState, ex, f, o, p: float) -> void:
	var pc: Dictionary = popCfg()
	var reel: int = int(pc.get("landReel", 8))
	var again: bool = _lg(o, LA_POP_UNTIL) > S.tick and o.rush != null
	_s(f, RUN, _g(f, RUN) + maxi(0, int(pc.get("stringPoints", 2)) - 1) * RUN_U)
	_drop(S, ex, o)
	var base: float = o.rush.py if again else o.y
	var r := SimState.Rush.new()
	r.px = o.x
	r.py = maxf(base, WorldTerrain.groundY(S, o.x))
	r.pz = o.z
	var ticks: int = int(pc.get("fallTicks", 6)) if again else int(pc.get("ticks", 30))
	var h: float = 0.0
	if not again:
		var bh: Array = pc.get("bh", [1.5, 3.0])
		h = lerpf(float(bh[0]), float(bh[1]), clampf(p / maxf(0.001, float(pc.get("full", 0.8))), 0.0, 1.0)) * DirInterrupt.BH
		r.arc = h
	r.end = S.T + float(ticks) * SimConst.DT
	o.rush = r
	o.vx = 0.0
	o.vy = 0.0
	var free: int = int(pc.get("freeAt", 0))
	var stun: int = mini(free, ticks) if (free > 0 and not again) else ticks + reel   # 23c 12: free from the apex, guard, perfect block and strike in the air
	o.stunTicks = maxi(o.stunTicks, stun)
	_ls(o, LA_POP_UNTIL, S.tick + ticks)
	_ls(o, LA_POP_TECH, 0)
	_ls(o, LA_POP_BURST, 0)
	_ls(o, LA_POP_STUN, S.tick + stun)
	_ls(o, LA_POP_SPK, 0)
	if not again:
		_ls(o, LA_POP_AT, S.tick + 1)
		if o.ai != null:
			var slot: int = S.fighters.find(o)
			var lv: Dictionary = DirAI.lv().get("brawl", {})
			if SimRng.keyed(int(S.game.seed), "pop.tech", S.tick * 4 + slot) < float(lv.get("recoil", {}).get("flip", 0.0)):
				_ls(o, LA_POP_TECH, 1)
			if SimRng.keyed(int(S.game.seed), "pop.burst", S.tick * 4 + slot) < float(lv.get("burst", 0.0)):
				_ls(o, LA_POP_BURST, 1)
	var e = _ev(S, o, "pop", "slam" if again else "up")
	e.target = float(S.fighters.find(f))
	e.n = S.tick + ticks
	e.dur = float(ticks)
	e.amount = h / DirInterrupt.BH
	e.x = p
	SimEvents.feed(S, o.name + (" IS BROUGHT DOWN" if again else " IS POPPED UP"), ("a second pop in a row lands him" if again else "power " + str(snappedf(p, 0.01)) + ": " + str(snappedf(h / DirInterrupt.BH, 0.1)) + " bh up and back down in reach over " + str(ticks) + " ticks"))


## f spikes a popped o (23c 9): down into the ground under him in spike.fallTicks, where his landing digs a crater and
## he recovers in spike.recoverTicks unless he techs it. The brawl goes on. No aim, journey, freshness mark, wary window
## or pay; his blow on its way is lost. Cue "pop": spike.
static func _spike(S: SimState, ex, f, o) -> void:
	var sc: Dictionary = popCfg().get("spike", {})
	var fall: int = int(sc.get("fallTicks", 6))
	var rec: int = int(sc.get("recoverTicks", 21))
	_drop(S, ex, o)
	var r := SimState.Rush.new()
	r.px = o.x
	r.py = WorldTerrain.groundY(S, o.x)
	r.pz = o.z
	r.end = S.T + float(fall) * SimConst.DT
	o.rush = r
	o.vx = 0.0
	o.vy = 0.0
	o.stunTicks = maxi(o.stunTicks, fall + rec)
	_ls(o, LA_POP_UNTIL, S.tick + fall)
	_ls(o, LA_POP_STUN, S.tick + fall + rec)
	_ls(o, LA_POP_SPK, 1)
	_ls(o, LA_POP_TECH, 0)
	_ls(o, LA_POP_BURST, 0)
	if o.ai != null and SimRng.keyed(int(S.game.seed), "spike.tech", S.tick * 4 + S.fighters.find(o)) < float(DirAI.lv().get("brawl", {}).get("recoil", {}).get("flip", 0.0)):
		_ls(o, LA_POP_TECH, 1)
	var e = _ev(S, o, "pop", "spike")
	e.target = float(S.fighters.find(f))
	e.n = S.tick + fall
	e.dur = float(fall)
	e.x = o.x
	SimEvents.feed(S, o.name + " IS SPIKED", "a launcher at a popped fighter slams him into the ground under him: the brawl goes on")


## Each tick (laTick): a popped fighter's tech (a dodge tap in the landing's last techTicks), his burst out (a light
## press after burstAfter: down in fallTicks), and his landing (set if teched, else he reels landReel). Cues "pop":
## tech, burst, land (n 1 set, 0 reeling).
static func _popTick(S: SimState) -> void:
	var pc: Dictionary = popCfg()
	for f in S.fighters:
		var until: int = _lg(f, LA_POP_UNTIL)
		if until <= 0:
			continue
		if S.tick >= until:
			var landedSet: bool = _lg(f, LA_POP_TECH) == 2
			if landedSet:
				f.stunTicks = 0
			_ls(f, LA_POP_UNTIL, 0)
			_ls(f, LA_POP_TECH, 0)
			_ls(f, LA_POP_BURST, 0)
			var spk: bool = _lg(f, LA_POP_SPK) == 1
			if spk:
				_ls(f, LA_POP_SPK, 0)
				var by = SimRoster.opp(S, f)
				WorldCrater.dig(S, f.x, WorldCrater.impactEnergy(float(popCfg().get("spike", {}).get("speed", 1800.0)), float(by.tier)), by, "impact", 0.0, 1.0, false)   # the spike's crater, under him
			if landedSet:
				_ls(f, LA_POP_STUN, S.tick)
			var le = _ev(S, f, "pop", "land")
			le.n = 1 if landedSet else 0
			le.amount = 1.0 if spk else 0.0
			continue
		if _lg(f, LA_POP_TECH) != 2 and until - S.tick <= int(pc.get("techTicks", 8)):
			var tap: bool = (f.ai == null and f.input != null and f.input.dodge) or (f.ai != null and _lg(f, LA_POP_TECH) == 1)
			if tap:
				_ls(f, LA_POP_TECH, 2)
				f.stunTicks = mini(f.stunTicks, until - S.tick)
				_ev(S, f, "pop", "tech")
				if _lg(f, LA_POP_SPK) == 0 and DirRecoil.popFlip(S, f, SimRoster.opp(S, f)):
					var fl: int = int(DirRecoil.cfg().get("flipTicks", 12))
					_ls(f, LA_POP_UNTIL, S.tick + fl)   # 23c 11: a teched pop landing is a recoil flip: he backflips out and lands set
					f.stunTicks = fl
		var at: int = _lg(f, LA_POP_AT) - 1
		if int(pc.get("freeAt", 0)) <= 0 and at >= 0 and S.tick - at >= int(pc.get("burstAfter", 12)) and f.rush != null and float(f.rush.arc) != 0.0:   # (free from the apex, he strikes instead: 23c 12)
			var out: bool = (f.ai == null and f.input != null and f.input.light) or (f.ai != null and _lg(f, LA_POP_BURST) == 1)
			if out:
				var ft: int = int(pc.get("fallTicks", 6))
				var r := SimState.Rush.new()
				r.px = f.x
				r.py = f.rush.py
				r.pz = f.z
				r.end = S.T + float(ft) * SimConst.DT
				f.rush = r
				f.stunTicks = 0
				_ls(f, LA_POP_UNTIL, S.tick + ft)
				_ls(f, LA_POP_TECH, 2)
				_ls(f, LA_POP_BURST, 0)
				_ev(S, f, "pop", "burst")


## True when launch anywhere is on (data/director/interrupts.json brawl.launcher.anywhere.enabled).
static func anywhere() -> bool:
	return on() and bool(la().get("enabled", false))


## Where launch anywhere's integers start: after the mash run's and the press wait's, which a player writes with every
## switch off, so a slot added here never moves his.
static func _laBase() -> int:
	return DirPress._base() + DirPress.PR_N


static func _lg(f, k: int) -> int:
	var i: int = _laBase() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _ls(f, k: int, v: int) -> void:
	DirGrapple._size(f)
	if f.act.dirI.size() < _laBase() + LA_N:
		f.act.dirI.resize(_laBase() + LA_N)
	f.act.dirI[_laBase() + k] = v


## Game Design's 5a (rulings-2026-10-19.md): only a real flurry stops an answerable launcher. True when a light landing now
## comes within anywhere.armourLightTicks live ticks of the last one its armour took (0 or missing: any second light).
static func _flurried(S: SimState, o) -> bool:
	var w: int = int(la().get("armourLightTicks", 0))
	return w <= 0 or _now(S) - _lg(o, LA_LHIT_AT) <= w


## True when a B of f's pressed at p is in his string (docs/design/launch-anywhere.md section 2): within anywhere.link
## ticks after one of his landed blows, or anywhere.kept ticks or fewer before one lands (held on his line, it is
## thrown as the launcher at the landing).
static func _linked(S: SimState, f, p: int) -> bool:
	var at: int = _lg(f, LA_LINK)
	if at <= 0 or p <= 0:
		return false
	if p >= at:
		return p - at <= int(la().get("link", 24))
	return at - p <= int(la().get("kept", 10))


## A B within anywhere.mashTicks of his last B press is the heavy flurry, never the launcher (the mash rule).
static func _bMash(f, p: int) -> bool:
	var last: int = _g(f, B_TAP)
	return last > 0 and p - last < int(la().get("mashTicks", 9))


## How safe f's launcher is (section 3): 1 sure (he is staggered: an opening), 2 hard to answer (he reels from a medium
## or a heavy), 3 answerable (he reels from a light or a bolt, or is free).
static func _safety(S: SimState, f, o) -> int:
	if o.stunTicks > 0 and not (popOn() and S.tick < _lg(o, LA_POP_STUN)):
		return 1   # (a juggle's stun is no opening: 23c 9)
	var wary: int = int(la().get("waryTicks", 0))
	if wary > 0 and _lg(o, LA_LANDED) > 0 and _now(S) - (_lg(o, LA_LANDED) - 1) <= wary:
		return 3   # Game Design's 10c: he came down from a launch within waryTicks, so a launcher that isn't sure is answerable
	var k: int = _lg(o, LA_HITK) - 1
	if _now(S) < _g(o, REEL_AT) and (k == MEDIUM or k == BIG or k == LA_RIPK):
		return 2
	var hc: int = 0 if popOn() else int(la().get("hardFromChain", 0))   # with pops, no string armour (rulings-2026-10-23c 3)
	if hc > 0 and _lg(f, LA_CH_N) >= hc and _now(S) - _lg(f, LA_CH_AT) <= int(la().get("chainGapTicks", 24)):
		return 2   # Game Design's 2a (rulings-2026-10-23): his string of landed blows makes the launcher hard to answer
	return 3


## The launcher's power before its wounds and its freshness (section 4): the string (his run's whole points, one at
## least) x the rival's state x the timing (x1: the perfect launcher waits on the perfect window, not on this build).
static func _power(S: SimState, f, o, safety: int) -> float:
	var pw: Dictionary = la().get("power", {})
	if pw.is_empty():
		return 1.0
	var run: int = clampi(_g(f, RUN) / RUN_U, 1, 4)
	var st: Dictionary = pw.state
	var sm: float = float(st.sure) if safety == 1 else (float(st.hard) if safety == 2 else float(st.answerable))
	return float(pw.string[run - 1]) * sm


## The wounds' factor at the launcher's landing: the region its piece strikes, battered or broken on him.
static func _woundMul(o, piece: String) -> float:
	var pw: Dictionary = la().get("power", {})
	if pw.is_empty() or piece == "":
		return 1.0
	var pc = DirRecipe.rec().get("pieces", {}).get(piece) if DirRecipe.on() else null
	var tg: String = String(pc.get("target", "")) if pc is Dictionary else ""
	var r: int = -1
	if tg == "head" or tg == "jaw":
		r = SimWounds.HEAD
	elif tg == "chest" or tg == "gut":
		r = SimWounds.CORE
	elif tg.begins_with("arm"):
		r = SimWounds.ARMS
	elif tg == "legs" or tg == "shins":
		r = SimWounds.LEGS
	if r < 0:
		return 1.0
	if SimWounds.broken(o, r):
		return float(pw.wounds.broken)
	if SimWounds.battered(o, r):
		return float(pw.wounds.battered)
	return 1.0


## The five kinds of send (section 5), by the planner's candidate: 0 up, 1 across, 2 down, 3 behind, 4 into a building.
## Behind has no candidate yet (the planner has no turned send): a stick held away is the planner's own pick until it does.
static func kindOfSend(k: Dictionary) -> int:
	var nm: String = String(k.get("name", ""))
	if k.has("brunt") or nm == "BUILDING SMASH" or (k.has("p") and k.p is Dictionary and bool(k.p.get("building", false))):
		return 4
	if nm == "UPPERCUT" or nm == "VENT LIFT":
		return 0
	if nm == "DRIVE DOWN" or nm == "CRATER SLAM" or nm == "MARSH SWALLOW":   # biomes W3: VENT LIFT is up, MARSH SWALLOW down
		return 2
	if nm == "SMASH BEHIND":
		return 3
	return 1


## The marks of a kind on o still inside anywhere.fresh.windowS of fight time (none with the switch off).
static func freshMarks(S: SimState, o, kind: int) -> int:
	var fr: Dictionary = la().get("fresh", {})
	if not anywhere() or fr.is_empty() or kind < 0 or kind > 4:
		return 0
	var win: int = int(round(float(fr.windowS) * DirData.TICKS_PER_SEC))
	var now: int = _now(S)
	var n: int = 0
	for q in range(4):
		var t: int = _lg(o, LA_FRESH + kind * 4 + q)
		if t > 0 and now - t <= win:
			n += 1
	return n


## Freshness: x factor for each mark of that kind on o in the window, x general for each mark of any kind, never under
## floor (Game Design, ff68e994). A fighter not launched in the window is full.
static func freshMul(S: SimState, o, kind: int) -> float:
	var fr: Dictionary = la().get("fresh", {})
	if not anywhere() or fr.is_empty():
		return 1.0
	var m: float = 1.0
	for q in range(freshMarks(S, o, kind)):
		m *= float(fr.factor)
	var all: int = 0
	for kd in range(5):
		all += freshMarks(S, o, kd)
	for q in range(all):
		m *= float(fr.get("general", 1.0))
	return maxf(float(fr.floor), m)


## Orb (homework 30): "each time you launch an opponent against something, the more destroyed it will be". So with
## anywhere.fresh.destruction false, freshness shortens the flight and the power counted at the send, and the power
## World's building ladder reads is the launcher's own.
static func freshHurts() -> bool:
	return bool(la().get("fresh", {}).get("destruction", false))


## Each launch marks its kind on the fighter it sends (DirMelee.launchBeat): the oldest of that kind's four marks goes.
static func markKind(S: SimState, o, kind: int) -> void:
	if not anywhere() or kind < 0 or kind > 4 or la().get("fresh", {}).is_empty():
		return
	var at: int = 0
	var oldest: int = 1 << 30
	for q in range(4):
		var t: int = _lg(o, LA_FRESH + kind * 4 + q)
		if t < oldest:
			oldest = t
			at = q
	_ls(o, LA_FRESH + kind * 4 + at, maxi(1, _now(S)))


## The cue launch_power at each launch (DirMelee.launchBeat), for QA's full-launch counter and the views: amount the
## power at the send after freshness (1 for a launch that isn't the launcher's), k 1 for a full one (anywhere.full and
## over), text the kind (up, across, down, behind, building).
static func powerCue(S: SimState, a, o, kind: int, power: float) -> void:
	if not anywhere():
		return
	var e = _ev(S, a, "launch_power", ["up", "across", "down", "behind", "building"][clampi(kind, 0, 4)])
	e.target = float(S.fighters.find(o))
	e.amount = power
	e.k = 1.0 if power >= float(la().get("full", 0.8)) - 0.0005 else 0.0
	e.n = S.tick


## The AI against a launcher that isn't sure (section 8): its reaction time is the wind-up's length, so it can't
## answer one it sees. Its only answer is one it was already guessing: when f's blow lands clean on an AI o, it decides
## once, at its level's brawl.anywhere.answer, that a launcher will follow while a B of his would still be one (the
## link). Keyed draws.
static func _laAnswerPlan(S: SimState, f, o) -> void:
	_ls(o, LA_ANS, 0)
	if o.ai == null:
		return   # a player answers for himself
	var an: Dictionary = la().get("answer", {})
	if bool(an.get("enabled", false)) and f.ai == null and _lg(f, LA_LAU1) == 0 and (an.get("firstFree", []) as Array).has(DirAI.level if DirAI.level != "" else String(DirAI.skill().level)):
		return   # 10-26 item 19: on easy and medium it never guesses at a player's first launcher of a match
	var share: float = float(DirAI.lv().get("brawl", {}).get("anywhere", {}).get("answer", 0.0))
	if share <= 0.0 or SimRng.keyed(int(S.game.seed), "brawl.answerLauncher", S.tick * 8 + S.fighters.find(o)) >= share:
		return
	_ls(o, LA_ANS, S.tick + int(la().get("link", 24)) + 1)


## The AI's guess, once a tick: a launcher that isn't sure winds on it, thrown while the guess held, and its reaction time
## has passed since it was thrown: it presses guard (never sooner, so it never answers within its reaction time; the
## contact is still inside the perfect window). The guess is spent with the press, or lapses. With anywhere.answer on,
## the press is timed to the contact (answer.leadTicks before it): the guess was made before the throw, and a press its
## reaction time after the throw came at the contact or later, since the wind-up is as long.
static func _laAnswerTick(S: SimState, f) -> void:
	var until: int = _lg(f, LA_ANS)
	if until <= 0:
		return
	var ex = S.dirS.ex
	if f.ai == null or ex == null or (f != ex.A and f != ex.D):
		_ls(f, LA_ANS, 0)
		return
	var o = ex.D if f == ex.A else ex.A
	var began: int = _g(o, LAND_AT)   # S.tick his launcher was thrown (his line is busy until it lands)
	if _g(o, FLAV) == 2 and _g(o, LINE) == 1 and _g(o, LC_LATE) == 1 and began <= until:
		var due: bool = S.tick - began >= int(DirAI.skill().get("reactTicks", 14))
		var an: Dictionary = la().get("answer", {})
		if bool(an.get("enabled", false)):
			due = _g(o, CONTACT) - _now(S) <= int(an.get("leadTicks", 3))   # inside the perfect window, in live ticks
		if f.stunTicks <= 0 and due:
			_ls(f, LA_ANS, 0)
			DirInterrupt.guardPress(S, f)
		return
	if S.tick > until:
		_ls(f, LA_ANS, 0)   # no launcher came while the guess held


## True while f mashes (10-26 item 21): his last two light presses came within anywhere.answer.mashTicks of each other,
## and the last of them as recently. A mash is rhythmic and readable: the AI's perfect block against it is DirInterrupt's.
static func mashing(S: SimState, f) -> bool:
	var m: int = int(la().get("answer", {}).get("mashTicks", 9))
	return _g(f, TAP_GAP) > 0 and _g(f, TAP_GAP) <= m and S.tick - _g(f, LAST_TAP) <= m


## The AI launches in its string at a hard-to-answer moment (section 8): once a landed blow, at its level's
## brawl.anywhere.inString. True when it presses B now.
static func _aiLaunchInString(S: SimState, f, c: Dictionary) -> bool:
	var at: int = _lg(f, LA_LINK)
	if at <= 0 or _lg(f, LA_AILW) == at:
		return false
	_ls(f, LA_AILW, at)
	var ex = S.dirS.ex
	if ex == null or (f != ex.A and f != ex.D):
		return false
	var o = ex.D if f == ex.A else ex.A
	if not _linked(S, f, S.tick) or _safety(S, f, o) != 2 or f.ki < float(c.launcher.ki):
		return false
	var share: float = float(DirAI.lv().get("brawl", {}).get("anywhere", {}).get("inString", 0.0))
	return share > 0.0 and SimRng.keyed(int(S.game.seed), "brawl.launchInString", at * 2 + (0 if f == ex.A else 1)) < share


## launch anywhere: the AI aims its launcher by its personality (Combat's launch-enders.md section 3, the
## fighter-pipeline's identity): the hero up or across, and across weighs less where people are along the line; the
## Anti-hero across or down, into buildings and the ground. A keyed draw by anywhere.aiAim's weights, its care's sign
## choosing the set, or its role while its care is 0 (hero; villain or rival). A reference fighter doesn't aim (the
## planner's pick).
static func _aiAim(S: SimState, f, o, i: SimIntent) -> void:
	var aw: Dictionary = la().get("aiAim", {})
	if aw.is_empty():
		return
	var pers: String = "hero" if f.care > 0.0 else ("villain" if f.care < 0.0 else "")
	if pers == "":
		var dd = FighterData.def(f.id)
		var role: String = String(dd.get("role", "")) if dd is Dictionary else ""
		pers = "hero" if role == "hero" else ("villain" if (role == "villain" or role == "rival") else "")
	if pers == "":
		return
	var w: Dictionary = aw.get(pers, {})
	var side: float = 1.0 if SimWrap.sdx(f.x, o.x) >= 0.0 else -1.0
	var wu: float = float(w.get("up", 0.0))
	var wa: float = float(w.get("across", 0.0))
	var wd: float = float(w.get("down", 0.0))
	if pers == "hero":
		var land: float = SimWrap.wrap(o.x + side * float(aw.get("popAtBh", 8.0)) * DirInterrupt.BH)
		wa *= 1.0 - clampf(float(WorldStructures.popNear(S, land, float(aw.get("popR", 3.0)) * DirInterrupt.BH)) / maxf(0.001, WorldStructures.popNearRef(S)), 0.0, 1.0)
	var tot: float = wu + wa + wd
	if tot <= 0.0:
		return
	var x: float = SimRng.keyed(int(S.game.seed), "brawl.aiAim", S.tick * 2 + S.fighters.find(f)) * tot
	if x < wu:
		i.mx = 0.0
		i.my = 1.0
	elif x < wu + wa:
		i.mx = side
		i.my = 0.0
	else:
		i.mx = 0.0
		i.my = -1.0


## Combat's enders (docs/combat/launch-enders.md), loaded once from res://data/combat/enders.json when it exists.
static var _endersData = null
static func _enders() -> Dictionary:
	if _endersData == null:
		_endersData = {}
		if FileAccess.file_exists("res://data/combat/enders.json"):
			var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/enders.json"))
			if j is Dictionary:
				_endersData = j
	return _endersData


const FAMS: Array = ["hands", "legs", "close"]
const PATHS: Array = ["line", "rise", "drop", "arc_in", "arc_out", "spin"]


## A piece's family and path, packed for LA_FP (family x 8 + path, plus 1; 0 unknown).
static func _famPath(piece: String) -> int:
	var pc = DirRecipe.rec().get("pieces", {}).get(piece) if DirRecipe.on() else null
	if not (pc is Dictionary):
		return 0
	var limb: String = String(pc.get("limb", ""))
	var fam: int = 0 if limb == "hand" else (1 if (limb == "foot" or limb == "knee") else (2 if limb != "" else -1))
	var pth: int = PATHS.find(String(pc.get("path", "")))
	if fam < 0 or pth < 0:
		return 0
	return fam * 8 + pth + 1


## The launcher's piece by Combat's enders: his last blow's family and path, and the send his stick asks (none: the
## planner picks the send, and the piece is picked as before). The lowest step first; a keyed draw within it.
## The step of the last ender picked (Combat's 1 to 5), for the re-chamber's tell. Not state: read at once.
static var _enderStep: int = 0

static func _ender(S: SimState, f, aim: int) -> String:
	_enderStep = 0
	var en: Dictionary = _enders()
	var fp: int = _lg(f, LA_FP) - 1
	if en.is_empty() or fp < 0 or aim <= 0 or aim > 4:
		return ""
	var send: String = ["up", "across", "down", "turned"][aim - 1]
	var key: String = String(FAMS[fp / 8]) + "." + String(PATHS[fp % 8])
	var rows = en.get("fighters", {}).get(DirRecipe.poolKey(f), {}).get("enders", {}).get(key, {}).get(send)
	if not (rows is Array) or rows.is_empty():
		return ""
	var best: int = 99
	for row in rows:
		best = mini(best, int(row.get("step", 99)))
	var pick: Array = []
	for row in rows:
		if int(row.get("step", 99)) == best:
			pick.append(String(row.strike))
	_enderStep = best
	return pick[mini(pick.size() - 1, int(SimRng.keyed(int(S.game.seed), "brawl.ender", S.dirS.exN * 64 + _g(f, BLOWS)) * float(pick.size())))]


## For UI (section 9's marks): whether f's B would launch now, sure or not, its power in pips (1 to 5), and the four
## kinds fresh on his rival (up, across, down, behind). Empty outside a brawl, or with launch anywhere off.
static func launcherNow(S: SimState, f) -> Dictionary:
	if not anywhere() or not inBrawl(S, f):
		return {}
	var ex = S.dirS.ex
	var o = ex.D if f == ex.A else ex.A
	var lcOpen: bool = _g(f, LC_UNTIL) > 0 and (o.stunTicks > 0 or S.tick <= _g(f, LC_UNTIL))
	var lit: bool = (lcOpen or _linked(S, f, S.tick)) and not _bMash(f, S.tick) and f.ki >= float(cfg().launcher.ki)
	if not lit:
		return {"on": false}
	var sf: int = _safety(S, f, o)
	var fresh: Array = []
	for kd in range(4):
		fresh.append(freshMarks(S, o, kd) == 0)
	return {"on": true, "sure": sf == 1, "safety": sf, "pips": clampi(int(round(_power(S, f, o, sf) * 5.0)), 1, 5), "fresh": fresh}


## UI's launcher marks as a cue's fields (the cue list's rules: k a count, amount a value). source: sure, hard or
## answerable; k: its power in pips (1 to 5); amount: the kinds fresh on his rival as a mask (1 up, 2 across, 4 down,
## 8 behind; a set bit is fresh).
static func _marks(S: SimState, e, f, o, sf: int) -> void:
	e.source = ["", "sure", "hard", "answerable"][clampi(sf, 1, 3)]
	e.k = float(clampi(int(round(_power(S, f, o, sf) * 5.0)), 1, 5))
	var m: int = 0
	for kd in range(4):
		if freshMarks(S, o, kd) == 0:
			m |= 1 << kd
	e.amount = float(m)


## A blow of f's landed clean: his B is the launcher for anywhere.link ticks. The cue launcher_link says so, for UI's lit
## B (an opening keeps its own cue, launcher_open, which Audio and Animation read as an opening). n: the S.tick the link
## ends; dur: its length. Its safety is read as the landing leaves him: sure in an opening, hard after a medium or a
## heavy, answerable after a light or a bolt (the hit's own stun is no opening). Only when he has the ki.
static func _linkCue(S: SimState, f, o) -> void:
	if f.ki < float(cfg().launcher.ki) or quiet(S.dirS.ex):
		return
	var k: int = _lg(o, LA_HITK) - 1
	var sf: int = 1 if _g(f, LC_UNTIL) > 0 else (2 if (k == MEDIUM or k == BIG or k == LA_RIPK) else 3)
	var link: int = int(la().get("link", 24))
	var e = _ev(S, f, "launcher_link", "link")
	e.target = float(S.fighters.find(o))
	e.n = S.tick + link
	e.dur = float(link)
	_marks(S, e, f, o, sf)


## An opening (brawl-second-pass.md section 3, as re-ruled): the rival o is staggered for launcher.minStagger ticks or
## more by a flurry's close, a broken guard, a perfect block or a zip's tech counter. Until the stagger ends f's B
## always lands. It launches when a launch is ready on o, and the cue launcher_open goes out only then (n: the tick the
## stagger is due to end; both players hear it). While the launcher rests on o (launcher.restS of fight time after any
## launch of him) the same B knocks him back, and there is no cue. The AI weighs every opening once, at its share.
static func _lcOpen(S: SimState, ex, f, o, ticks: int, why: String) -> void:
	var lc: Dictionary = cfg().launcher
	if ticks < int(lc.minStagger) or quiet(ex) or f.stunTicks > 0:
		return
	var was: int = _g(f, LC_UNTIL)
	_s(f, LC_UNTIL, maxi(was, S.tick + maxi(ticks, int(lc.get("lateTicks", 0)))))   # the stagger, or lateTicks after the close (the wider window)
	if was > 0:
		return   # his opening is on already: it lasts as long as the stagger does
	if f.ai != null:
		var share: float = float(DirAI.lv().get("brawl", {}).get("anywhere", {}).get("launcher", 0.0)) if anywhere() else float(DirAI.lv().get("brawl", {}).get("launcher", 0.0))
		_s(f, AI_LSAW, 1 if SimRng.keyed(int(S.game.seed), "brawl.launcher", S.tick * 2 + (0 if f == ex.A else 1)) < share else 0)
	if launcherRest(S, o) > 0:
		return   # resting: his B is the knock-back, and nothing announces it
	_s(f, LC_PING, 1)
	var e = _ev(S, f, "launcher_open", why)
	e.target = float(S.fighters.find(o))
	e.n = _g(f, LC_UNTIL)   # the window's end
	e.dur = float(ticks)   # the stagger: inside it his B always lands
	if anywhere():
		_marks(S, e, f, o, 1)   # an opening's launcher is sure: its marks for UI


## f's opening closes. The cue goes out only when launcher_open did. how: used (he threw the launch), lapsed (the
## stagger ended, or the brawl did).
static func _lcClose(S: SimState, f, how: String) -> void:
	if _g(f, LC_UNTIL) == 0:
		return
	_s(f, LC_UNTIL, 0)
	_s(f, AI_LSAW, 0)
	if _g(f, LC_PING) == 0:
		return
	_s(f, LC_PING, 0)
	var e = _ev(S, f, "launcher_close", how)
	e.n = S.tick


## For Animation, UI and QA: the S.tick f's opening ends (his B always lands until then: a launch when one is ready,
## else a knock-back), or -1 when he has none.
static func launcherOpen(S: SimState, f) -> int:
	if not inBrawl(S, f) or _g(f, LC_UNTIL) == 0:
		return -1
	var o = S.dirS.ex.D if f == S.dirS.ex.A else S.dirS.ex.A
	return maxi(_g(f, LC_UNTIL), S.tick + maxi(0, o.stunTicks))   # the window's end (the stagger's, or lateTicks after the close)


## For Animation, UI and QA: giving ground. Empty unless f may give ground on this tick (the rival winds or charges,
## and he is free to). gave: he has moved off against this wind-up. gap: how far past striking distance the two are,
## in body heights. leash: the most it may open.
static func giving(S: SimState, f) -> Dictionary:
	if not inBrawl(S, f) or S.dirS.ex.branch != "" or _giver(S, S.dirS.ex) != f:
		return {}
	var ex = S.dirS.ex
	var o = ex.D if f == ex.A else ex.A
	return {"gave": _g(f, GAVE) == 1, "gap": maxf(0.0, DirBands.dist(f, o) - float(DirData.contact().offset)) / DirInterrupt.BH, "leash": float(cfg().give.leashBh)}


## True while f winds or charges a wound blow whose button still decides it.
static func _windOn(f) -> bool:
	return _g(f, LINE) != 0 and _wound(_g(f, KIND)) and _g(f, HOLD_AT) > 0


## The fighter who may give ground on this tick (brawl-second-pass.md section 1), or null. The rival winds or charges
## a wound blow, and he has no blow of his own on its way or kept, no attack button down, and is neither staggered
## nor open after a miss. His guard may be up. When both wind, nobody may; a launcher's target is staggered.
static func _giver(S: SimState, ex):
	if quiet(ex) or _g(ex.A, DBL_AT) > 0:
		return null
	var wa: bool = _windOn(ex.A)
	if wa == _windOn(ex.D):
		return null
	var f = ex.D if wa else ex.A
	var w = ex.A if wa else ex.D
	if _g(w, FLAV) == 2 or f.stunTicks > 0 or _g(f, LINE) != 0 or _g(f, HELD_P) != 0 or _now(S) < _g(f, OPEN_UNTIL):
		return null
	var i: SimIntent = f.input
	if i.light or i.heavy or i.sig or i.lightHeld or i.heavyHeld or i.sigHeld:
		return null
	return f


## Giving ground, once a live tick while somebody may (g). His stick moves him alone, at give.bhPerSec (times his
## own speed with give.bySpeed on), and less behind a guard, and the rival isn't drawn along. A stick within 45
## degrees of straight away from the rival backs him off: the gap opens by his whole step, whatever the ground does
## under him (on a slope he goes further along it, up to twice the step, until it has). Any other way he goes where
## it points, and the ground turns that step along itself, the same length. The rival who winds follows: a stick of
## his within 45 degrees of straight at him closes an open gap by give.follow of the step, less as it points further
## off; the rest of that stick nudges the centre, as ever, and never opens the gap. The gap never opens past
## give.leashBh beyond striking distance, and a step never brings them inside it. At a building's face he goes up
## it by the same step. It answers at once: the nudge's ramp is the centre's.
static func _giveStep(S: SimState, ex, g) -> void:
	var gi: Dictionary = cfg().give
	var w = ex.D if g == ex.A else ex.A
	var near: float = float(DirData.contact().offset)
	var far: float = near + float(gi.leashBh) * DirInterrupt.BH
	for f in [g, w]:
		var o = w if f == g else g
		var st: PackedFloat64Array = stick(ex, f)
		var ul: float = SimDetMath.hypot(st[0], st[1])
		if ul <= SimAct.awayDead:
			continue
		var ux: float = st[0] / ul
		var uy: float = st[1] / ul
		var d0: float = DirBands.dist(f, o)
		if d0 <= 0.001:
			continue
		var ax: float = SimWrap.sdx(o.x, f.x) / d0   # straight away from the rival
		var ay: float = (f.y - o.y) / d0
		var sp: float = float(gi.bhPerSec) * DirInterrupt.BH
		if bool(gi.bySpeed):
			sp *= _flySpeed(S, f) / float(gi.speedRef)   # times his own speed, against a standard fighter's
		var along: float = ux * ax + uy * ay   # 1 straight away, -1 straight at him
		if f == g and along < 0.0:
			continue   # toward the rival his stick is a nudge of the centre (_move): alone, it could not take him inside striking distance
		var step: float = sp * SimConst.DT * minf(1.0, ul)
		var want: float = 0.0   # how much the gap should change by this step: over 0 it opens, under 0 it closes; 0: he goes where his stick points
		if f == w:
			if along >= 0.0:
				continue   # his stick doesn't point at the rival: it is his nudge of the centre and no more
			var owed: float = step * float(gi.follow) * clampf(-along / DirLaunch.TILT_CONE, 0.0, 1.0)
			step = minf(owed, maxf(0.0, d0 - near))
			# The follow he is owed comes off the counted gap in full, even when his own step through his reach has
			# already closed the ground between them and there is nothing left to walk into.
			if _g(f, GAPV_ON) == 1:
				_s(f, GAPV, maxi(0, _g(f, GAPV) - int(round(owed * 16.0))))
			if step <= 0.5:
				continue
			ux = -ax
			uy = -ay
			want = -step
		else:
			if f.stance == 1.0:
				step *= float(gi.guard)
			if along >= DirLaunch.TILT_CONE:   # within 45 degrees of straight away
				ux = ax
				uy = ay
				want = step
		var nx: float = f.x
		var ny: float = f.y
		var d1: float = d0
		var k: float = 1.0
		for _i in range(8):
			nx = SimWrap.wrap(f.x + ux * step * k)
			ny = maxf(WorldTerrain.groundY(S, nx, _gz()), f.y + uy * step * k)
			d1 = SimDetMath.hypot(SimWrap.sdx(o.x, nx), ny - o.y)
			if want == 0.0:
				# Where his stick points: the ground turns the step along itself, and it is no longer than a step.
				var ln: float = SimDetMath.hypot(SimWrap.sdx(f.x, nx), ny - f.y)
				if ln <= step + 0.01:
					break
				k *= step / ln
				continue
			var got: float = d1 - d0
			# Backing off, the gap opens by his step and no more: on a rising face the ground lifts him, and he takes a
			# shorter step along it. Following, the gap closes by the step at least.
			if (want > 0.0 and absf(got - want) <= 0.02) or (want < 0.0 and got <= want + 0.02) or (k >= 2.0 and absf(got) < absf(want)):
				break
			k = minf(2.0, k * 1.5 if got * want <= 0.0 else k * clampf(want / got, 0.25, 1.5))
		var fit: bool = want <= 0.0 or d1 - d0 <= want + 0.5   # false: a ledge lifted him further than any step along it
		var lim: float = d1
		if d1 > maxf(far, d0):
			lim = maxf(far, d0)
		elif d1 < minf(near, d0):
			lim = minf(near, d0)
		if lim != d1:
			if d1 <= 0.001:
				continue
			nx = SimWrap.wrap(o.x + SimWrap.sdx(o.x, nx) / d1 * lim)
			ny = maxf(WorldTerrain.groundY(S, nx, _gz()), o.y + (ny - o.y) / d1 * lim)
		if _walled(S, nx, ny) and not _walled(S, f.x, f.y):
			# A building's face: he goes up it by the same step (flight goes over anything, and nobody is cornered).
			nx = f.x
			ny = f.y + step
			if _walled(S, nx, ny):
				continue
		var went: float = SimDetMath.hypot(SimWrap.sdx(f.x, nx), ny - f.y)
		f.x = nx
		f.y = ny
		_own(f, went)
		if f == g:
			# What he gave is counted on the gap the winder's blow must reach: a whole step when he backs straight off (and
			# the leash did not hold him), whatever the ground made of it; any other way, and over a ledge that lifted him
			# further than his step, what the gap really changed by.
			var gave: float = want if (want > 0.0 and lim == d1 and fit) else DirBands.dist(f, o) - d0
			if _g(w, GAPV_ON) == 1:
				_s(w, GAPV, maxi(0, _g(w, GAPV) + int(round(gave * 16.0))))
			if gave > 0.01:
				_s(g, GAVE, 1)


## The live ticks a press's blow lands later, for the gap it closes on the way (brawl-second-pass.md section 1):
## give.closeTicksPerBh for each body height past the strike's reach, rounded up, and never more than
## give.closeMaxTicks.
static func _closeTicks(f, o) -> int:
	var gi: Dictionary = cfg().give
	var gap: float = (_gapDist(f, o) - float(DirData.contact().reach)) / DirInterrupt.BH
	if gap <= 0.0:
		return 0
	return mini(int(gi.closeMaxTicks), int(ceil(float(gi.closeTicksPerBh) * gap)))


## The gap a blow closes: the pair's distance, or the horizontal gap while one of them is popped (23c 12: he is struck
## and strikes at his height, and the striker steps up to it as the blow lands).
static func _gapDist(f, o) -> float:
	if popOn() and (_lg(o, LA_POP_UNTIL) > 0 or _lg(f, LA_POP_UNTIL) > 0):
		return absf(SimWrap.sdx(f.x, o.x))
	return DirBands.dist(f, o)


## f moves toward striking distance from o, on his own side and at o's height: the way that is left, shared over
## `ticks`. The closing move of a press, once a live tick, and the placement of a blow as it lands. No fighter of a
## brawl moves more than give.closeMaxBh in a tick: the step is what is left of that once the core's step (the
## pair's drift) and what he has moved alone on this tick are taken off. The ground holds him up, so on a slope he
## goes along it; the step is shortened until the whole of it, the rise included, fits.
static func _stepIn(S: SimState, ex, f, o, ticks: int) -> void:
	var ct: Dictionary = DirData.contact()
	var s: float = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(o.x, f.x)), -f.face)   # his side of the rival
	var gx: float = SimWrap.sdx(f.x, SimWrap.wrap(o.x + s * float(ct.offset)))
	var gy: float = maxf(o.y, WorldTerrain.groundY(S, f.x, _gz())) - f.y
	var gl: float = SimDetMath.hypot(gx, gy)
	if gl <= 0.5:
		return
	var room: float = (float(cfg().give.closeMaxBh) - float(cfg().give.closeSlackBh)) * DirInterrupt.BH - float(_g(f, OWN)) / 16.0   # the slack: what other rules may still move him by in this tick
	var step: float = minf(gl / float(maxi(1, ticks)), room)
	if step <= 0.0:
		return
	var nx: float = f.x
	var ny: float = f.y
	var went: float = 0.0
	for _k in range(6):
		nx = SimWrap.wrap(f.x + gx / gl * step)
		ny = maxf(WorldTerrain.groundY(S, nx, _gz()), f.y + gy / gl * step)
		went = SimDetMath.hypot(SimWrap.sdx(f.x, nx), ny - f.y)
		if went <= room:
			break
		step *= room / went * 0.97
	if went > room:
		return   # a face too steep to take in one step: he stays, and the attraction lifts him
	f.x = nx
	f.y = ny
	_own(f, went)


## How far past striking distance a blow of that kind lands, in body heights: a light's last step, a medium's and a
## heavy's reach, and a charged heavy's as it fills.
static func _reachOf(a, kind: int) -> float:
	var c: Dictionary = cfg()
	if kind == BIG:
		if bool(a.get("charged", false)):
			return lerpf(float(c.heavy.reachBh), float(c.heavy.charge.reachBh), clampf(float(a.get("charge", 0.0)), 0.0, 1.0))
		return float(c.heavy.reachBh)
	if kind == MEDIUM:
		return float(c.medium.reachBh)
	return float(c.give.lightReachBh)


## f's blow met nothing (brawl-second-pass.md section 1). A wound blow leaves him open for its recoverWhiff: no blow,
## no guard, no giving ground. The cue says why: gave_ground, the rival backed out of its reach against this wind-up;
## reach, they were apart some other way, or (placed) the two still stood beyond the strike's reach after its
## placement. n: the ticks he is open.
static func _miss(S: SimState, ex, f, o, kind: int, wind: bool, energy: String, placed: bool = false) -> void:
	var open: int = int(_wcfg(kind).recoverWhiff) if _wound(kind) else 0
	if open > 0:
		_s(f, FREE_AT, S.tick + open)
		_s(f, OPEN_UNTIL, _now(S) + open)
		if kind == BIG:
			DirRally.whiffed(S, f, open)   # 23d 1: a heavy's whiff, punished in it, dazes him
	if wind:
		_wEnd(S, f, kind, 4)
	var e = _ev(S, f, "miss", "gave_ground" if (_g(o, GAVE) == 1 and not placed) else "reach", _cellOf(2 if kind == BIG else (1 if kind == MEDIUM else 0)))
	e.target = float(S.fighters.find(o))
	e.n = open
	if energy != "":
		_eLand(S, ex, f, o, energy, "miss")
	SimEvents.feed(S, "MISS", f.name + "'s blow meets nothing: open for " + str(open) + " ticks")


## An energy art in reach lands, or doesn't (brawl-second-pass.md section 5b). what: bolt, blast. how: hit, guard,
## armour, miss. k is 1 on the one landing in energy.reach.flashEveryTicks that may take the full flash, for both
## fighters together; the rest get sparks at the hand.
static func _eLand(S: SimState, ex, f, o, what: String, how: String, ender: bool = false) -> void:
	var e = _ev(S, f, "energy_land", what, how)
	if ender:
		e.amount = 1.0   # a blast that lands as a string's ender: its own knock-back follows on this tick
	e.target = float(S.fighters.find(o))
	e.n = S.tick
	e.x = f.input.mx
	e.y = f.input.my
	var last: int = maxi(_g(ex.A, FLASH_AT), _g(ex.D, FLASH_AT))
	if how != "miss" and (last == 0 or S.tick - last >= int(cfg().energy.reach.flashEveryTicks)):
		e.k = 1.0
		_s(ex.A, FLASH_AT, S.tick)
		_s(ex.D, FLASH_AT, S.tick)


## The stick's quarter, as f holds it now (brawl-second-pass.md section 3): 0 none, 1 up, 2 toward the rival, 3 down,
## 4 away from him. Each owns 45 degrees either side, and a diagonal reads as up or down.
static func _quarter(f, o) -> int:
	var mx: float = f.input.mx
	var my: float = f.input.my
	if SimDetMath.hypot(mx, my) <= SimAct.awayDead:
		return 0
	if absf(my) >= absf(mx):
		return 1 if my > 0.0 else 3
	return 2 if mx * SimMathx.jsign(SimWrap.sdx(f.x, o.x)) > 0.0 else 4


## f launches o: the launcher, and a heavy charged to full. A launch whatever the earned gate says, aimed by the
## stick's quarter: up lifts him, toward drives him back along the line, and the planner picks among the candidates
## that way. With no stick it is the planner's own pick; so it is with the stick away, until a turning send exists,
## and with the stick down when he stands on the ground. mul: its share of a heavy's launch force (launcher.flightMul).
## The brawl ends with it.
static func _send(S: SimState, ex, f, o, aim: int, why: String, mul: float, extra: Dictionary = {}) -> void:
	var tilt: int = 0
	if aim == 1:
		tilt = 1
	elif aim == 3:
		tilt = 5
	elif aim == 2:
		tilt = 3 if SimWrap.sdx(f.x, o.x) >= 0.0 else 7
	var la: Dictionary = {"forced": true, "tilt": tilt, "why": why}
	la.merge(extra, true)   # (23d: the sell's send is sold and decisive)
	if _lg(f, LA_POW) > 0:
		la["power"] = float(_lg(f, LA_POW)) / 1000.0   # the launcher's power: freshness is applied once the send is picked
		var want: String = _sendOf(aim)
		if want != "" and DirLaunch.SENDS.has(want):
			la["sends"] = want   # the stick's kind is kept: the choreographer bends only inside it
	DirMelee.launchBeat(S, ex, f, o, float(cfg().heavy.force) * mul, false, la)
	if S.dirS.ex != ex:
		return
	if _setPiece(ex):
		over(S, ex, "finisher")   # the win finishes him: the finisher plays in this exchange
		return
	end(S, ex, "launch" if DirInterrupt.gi(ex.A, DirInterrupt.LAST_END) == DirInterrupt.END_LAUNCH else "knockback")


## f knocks o back: a heavy charged short of full, and the blast. A short send, decisive, and the brawl ends. bh: its
## length in body heights, or 0 for the knock-back's own by his tier. With the stick away (aim 4) he goes back past
## the attacker; any other way, along the line.
static func _knock(S: SimState, ex, f, o, bh: float, aim: int, half: bool = false) -> void:
	var kb: Dictionary = DirLaunch.data().knockBack
	var mul: float = 1.0
	if bh > 0.0:
		mul = bh / maxf(0.01, float(kb.distBh[clampi(int(f.tier) - 1, 0, 3)]))
	DirInterrupt.si(ex.A, DirInterrupt.LAST_END, DirInterrupt.END_KNOCK)
	SimFx.launchPlan(S, f, o, "", "KNOCK BACK")
	if aim == 4:
		DirLaunch.knock(S, f, o, mul, SimWrap.wrap(o.x + SimWrap.sdx(f.x, o.x)))
	else:
		DirLaunch.knock(S, f, o, mul)
	DirMelee._knockDecisive(S, ex, f, o, "blurPlain" if half else "")   # half: it counts as half a set-up, as a close does
	if S.dirS.ex != ex:
		return
	if _setPiece(ex):
		over(S, ex, "finisher")
		return
	end(S, ex, "knockback")


## The brawl's slots of both fighters are cleared as it begins. Two things are kept: the tick of the last full flash
## of an energy blow in reach (one landing in energy.reach.flashEveryTicks may take it, across brawls too), and the
## tick each fighter was last launched (the launcher's rest on him), and the match's double hits with the tick of
## the last (the AI's digging in is bounded by them).
static func _reset(ex) -> void:
	var flash: int = 0
	for f in [ex.A, ex.D]:
		_size(f)
		flash = maxi(flash, f.act.dirI[FLASH_AT])
		var launchedAt: int = f.act.dirI[LAUNCH_AT]
		var doubles: int = f.act.dirI[MATCH_DBL]
		var doubleAt: int = f.act.dirI[MATCH_DBL_AT]
		var hold: int = f.act.dirI[FLOOR] if (carries() and f.ai == null) else 0   # a player's hold that outlives the brawl (burst.holdCarries)
		var holdAt: int = f.act.dirI[FLOOR_AT]
		var holdT: int = f.act.dirI[FLOOR_T]
		var sent: int = f.act.dirI[SENT]
		var moveAt: int = f.act.dirI[MOVE_AT]
		for k in range(BASE, END):
			f.act.dirI[k] = 0
		f.act.dirI[SENT] = sent
		f.act.dirI[MOVE_AT] = moveAt
		f.act.dirI[FLOOR] = hold
		f.act.dirI[FLOOR_AT] = holdAt if hold != 0 else 0
		f.act.dirI[FLOOR_T] = holdT if hold != 0 else 0
		f.act.dirI[LAUNCH_AT] = launchedAt
		f.act.dirI[MATCH_DBL] = doubles
		f.act.dirI[MATCH_DBL_AT] = doubleAt
	for f in [ex.A, ex.D]:
		f.act.dirI[FLASH_AT] = flash
		for k in range(LA_LINK, LA_FRESH):
			if _laBase() + k < f.act.dirI.size():
				f.act.dirI[_laBase() + k] = 0   # (written only with launch anywhere on)


## The brawl's movement, once a live tick (brawl-second-pass.md section 1). Each stick goes through Controls' ramp
## and moves the centre at nudgeMul of his own free-flight speed, less while he guards; a staggered fighter has no
## stick. The two add up, so two who agree go twice as fast and two who oppose cancel. The centre's own speed follows
## the sticks by at most a full nudge over nudgeRampTicks, up and down. The speed the brawl began with is added,
## fading over carryTicks. A player's held stick is never left dead by any of that: the pair moves his way by
## nudge.floor of his own nudge at least. The whole is never more than maxStepBh in a tick. At a building's face the
## part of the step along the face carries on, and a step straight into it goes up the face and over. The core moves a locked fighter by his own velocity on its next step, after
## its damping (SimFighter.lockedKeep): so both are given the centre's velocity over what the damping keeps.
static func _move(S: SimState, ex) -> void:
	var c: Dictionary = cfg()
	var A = ex.A
	var D = ex.D
	var dt: float = SimConst.DT
	var live: bool = not quiet(ex) and _g(A, DBL_AT) == 0
	var gv = _giver(S, ex)   # while he may give ground his stick moves him alone (_giveStep), and is no nudge of the centre
	var tx: float = 0.0
	var ty: float = 0.0
	var top: float = 0.0
	var ownX: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])   # each one's own nudge, A then D
	var ownY: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])
	for f in [A, D]:
		var rx: int = 0
		var ry: int = 0
		if live and f.stunTicks <= 0:
			var st: PackedFloat64Array = stick(ex, f)
			rx = SimAim.nudge_units(st[0])
			ry = SimAim.nudge_units(st[1])
		elif live and f.ai == null:
			# Staggered, he stumbles the way he leans, at nudge.stagger of a nudge. The core clears a stunned fighter's
			# stick, so it is read as he holds it (Simulation's record, blank for a launched or dropped fighter).
			rx = SimAim.nudge_units(f.heldMx * float(c.nudge.stagger))
			ry = SimAim.nudge_units(f.heldMy * float(c.nudge.stagger))
		var nx: int = SimAim.nudge_ramp(_g(f, NUDGE_X), rx)
		var ny: int = SimAim.nudge_ramp(_g(f, NUDGE_Y), ry)
		_s(f, NUDGE_X, nx)
		_s(f, NUDGE_Y, ny)
		var sp: float = float(c.nudgeMul) * _flySpeed(S, f)
		top = maxf(top, sp)
		if gv == f and _alone(ex, f):
			continue
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
		ownX[0 if f == A else 1] = ux * sp
		ownY[0 if f == A else 1] = uy * sp
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
	# A player's held stick always moves the pair his way (Orb's rule: he can always move, outside knock-backs,
	# staggers and hit-stop): by nudge.floor of his own nudge at least, whatever the AI's stick, the speed the brawl
	# began with or the centre's old drift say. Two players who oppose each other still cancel.
	var floorShare: float = float(c.nudge.floor)
	if floorShare > 0.0:
		for pk in range(2):
			var pl = A if pk == 0 else D
			var own: float = SimDetMath.hypot(ownX[pk], ownY[pk])
			if pl.ai != null or own <= 0.0:
				continue
			if (D if pk == 0 else A).ai == null and ownX[pk] * ownX[1 - pk] + ownY[pk] * ownY[1 - pk] < 0.0:
				continue
			var his: float = (wx * ownX[pk] + wy * ownY[pk]) / own   # the pair's speed along his stick
			if his < floorShare * own:
				wx += (floorShare * own - his) * ownX[pk] / own
				wy += (floorShare * own - his) * ownY[pk] / own
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
			elif not _walled(S, m[0], m[1] + sl * dt + cl):
				# Nobody is cornered: the pair goes up the face by the same step, and over it (flight goes over anything).
				# The centre keeps its speed across, so the step carries on the moment the face is cleared.
				wx = 0.0
				wy = sl
			else:
				wx = 0.0
				wy = 0.0
				vx = 0.0
				vy = 0.0
	# On a slope the ground lifts a fighter who walks into it. The whole step, the lift included, keeps to the cap: the
	# step across is halved until it does, and a face too steep for that stops it (a nudge upward goes over).
	if wx != 0.0:
		var fit: bool = false
		var across: float = absf(wx)
		for _k in range(5):
			var lift: float = 0.0
			for f in [A, D]:
				lift = maxf(lift, WorldTerrain.groundY(S, SimWrap.wrap(f.x + wx * dt), _gz()) - (f.y + wy * dt))
			if lift <= 0.0 or SimDetMath.hypot(wx * dt, wy * dt + lift) <= cap * dt:
				fit = true
				break
			wx *= 0.5
		if not fit:
			wx = 0.0
			wy = maxf(wy, across)   # too steep to take in one step: they go up it by the same step
	if _frOn:
		_moveZ(S, ex, wx, tx != 0.0 or ty != 0.0)
	_s(A, CEN_VX, int(round(vx * 16.0)))
	_s(A, CEN_VY, int(round(vy * 16.0)))
	_s(A, PMOVE_X, _g(A, MOVE_X))
	_s(A, PMOVE_Y, _g(A, MOVE_Y))
	_s(A, MOVE_X, int(round(wx * 16.0)))
	_s(A, MOVE_Y, int(round(wy * 16.0)))
	carryOn(ex)


## True when the stick of f, the one who may give ground, moves him alone (_giveStep): any stick that does not point
## at the rival. Toward him it nudges the centre, as always.
static func _alone(ex, f) -> bool:
	var o = ex.D if f == ex.A else ex.A
	var st: PackedFloat64Array = stick(ex, f)
	var ul: float = SimDetMath.hypot(st[0], st[1])
	if ul <= SimAct.awayDead:
		return false
	return st[0] * SimWrap.sdx(o.x, f.x) + st[1] * (f.y - o.y) >= 0.0


## Both fighters are given the pair's velocity, over what the core's damping keeps. Once a tick from _move, and again
## after each blow (DirExchange.runBeat): a strike places its attacker and stops him, and the pair's drift carries on.
static func carryOn(ex) -> void:
	if not isBrawl(ex) or ex.branch != "" or ex.A.state != "locked" or ex.D.state != "locked":
		return
	var keep: float = SimFighter.lockedKeep(SimConst.DT)
	for f in [ex.A, ex.D]:
		f.vx = float(_g(ex.A, MOVE_X)) / 16.0 / keep
		f.vy = float(_g(ex.A, MOVE_Y)) / 16.0 / keep
		if _frOn:   # D1: the pair moves along its line, and drifts in depth
			f.vx = float(_g(ex.A, MOVE_X)) / 16.0 * _frCos / keep
			f.vz = _frVz / keep


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
	var gv: int = _g(f, AI_GIVE)
	if gv != 0:
		# It gives ground (1: straight away from him) or follows him (2: straight at him).
		var lx: float = SimWrap.sdx(f.x, o.x)
		var ly: float = o.y - f.y
		var ll: float = SimDetMath.hypot(lx, ly)
		var way: float = 1.0 if gv == 2 else -1.0
		return PackedFloat64Array([way * lx / ll, way * ly / ll]) if ll > 0.0 else PackedFloat64Array([way * side, 0.0])
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
	DirCamIntent.doubleHit(S, ex, S.tick + lead)
	_s(ex.A, DBL_N, 0)
	_s(ex.A, PART_N, 0)
	var m: PackedFloat64Array = _mid(ex)
	for df in [ex.A, ex.D]:
		_s(df, MATCH_DBL, _g(df, MATCH_DBL) + 1)
		_s(df, MATCH_DBL_AT, maxi(1, _now(S)))
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
		var g: float = WorldTerrain.groundY(S, r.px, _gz())
		var ground: bool = f.y - WorldTerrain.groundY(S, f.x, _gz()) <= within and not WorldTerrain.seaAt(S, r.px)
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


## True when a `sig` press of f's is B, the heavy (brawl-second-pass.md sections 2 and 5): no stance is held. With a
## stance held it is that stance's signature, as before.
static func isB(f, kind: String) -> bool:
	return kind == "sig" and on() and (f.input.stanceMask & 15) == 0 and f.act.mode != 1   # with the energy family held, B is the beam


## After a blow of f's has landed (DirExchange.runBeat): a press he made while it was on its way is thrown now, so a
## flurry's pace is its blows' own time and not a tick more.
static func afterBlow(S: SimState, ex, b) -> void:
	if S.dirS.ex != ex or not isBrawl(ex) or ex.branch != "" or ex.cancel or b.args == null:
		return
	var f = ex.A if String(b.args.a) == "A" else ex.D
	var hp: int = _g(f, HELD_P)
	if hp == 0 or f.state != "locked" or not _free(S, f) or S.tick - _g(f, HELD_AT) > int(cfg().heldPressTicks):
		return
	var was: bool = _inTick
	_inTick = true
	_throw(S, f, (hp & 7) - 1, _g(f, HELD_AT), false, false, (hp & 8) != 0, (hp & 16) != 0, (hp & 32) != 0)
	_inTick = was


## A shot meets f on his lunge with a wound blow (DirBlast.hit): what stops that blow's wind-up stops the lunge. A
## bolt is a light, a heavy shot a medium and a charged shot a heavy (heavy.armour.shotMediumPower and
## shotHeavyPower). Y's lunge, a medium's: a heavy shot or a charged one stops it. B's, a heavy's, armoured: a bolt
## does armour.lightMul of its damage and he keeps coming; a heavy shot stops it in its first
## armour.mediumUntilTicks; a charged shot stops it. Returns "stop", "shrug" (the armour took a bolt) or "".
static func lungeShot(S: SimState, f, power: float) -> String:
	var ar: Dictionary = cfg().heavy.armour
	var w: int = 2 if power >= float(ar.shotHeavyPower) else (1 if power >= float(ar.shotMediumPower) else 0)
	var at: int = DirInterrupt.gi(f, DirInterrupt.APPR_TICK)
	if bigLunge(f, at):
		if w == 0:
			return "shrug"
		return "stop" if (w == 2 or S.tick - at < int(ar.mediumUntilTicks)) else ""
	return "stop" if w >= 1 else ""


## B was pressed out of reach (DirExchange.requestAttack): his lunge is the heavy's, and the blow it arrives with is the heavy.
static func noteBig(f, tick: int) -> void:
	_s(f, BIG_REQ, tick)


## True for a wound blow: a medium or a heavy.
static func _wound(kind: int) -> bool:
	return kind >= MEDIUM


## The data block of a wound blow's kind.
static func _wcfg(kind: int) -> Dictionary:
	return cfg().heavy if kind == BIG else cfg().medium


## A brawl light's damage: the unit every blow's worth is counted in.
static func _unit() -> float:
	return float(cfg().light.damage) * float(cfg().damageMul)


## The level of the button that throws a blow of that kind: X, Y or B.
static func _down(f, kind: int) -> bool:
	return f.input.sigHeld if kind == BIG else (f.input.heavyHeld if kind == MEDIUM else f.input.lightHeld)


## The cell of a strength's button, for a press_ack and the windup cue.
static func _cellOf(st: int) -> String:
	return "b" if st == 2 else ("y" if st == 1 else "x")


## For Animation, UI and QA: f's wind-up. Empty when he has none. strength: medium or heavy. n: the live ticks since
## it began. left: the live ticks until it lands (-1 while he holds it past its end). armoured: a heavy's is, from its
## first tick. charge: 0 before a heavy's charge begins, then its share of full (1 at the flash).
static func winding(S: SimState, f) -> Dictionary:
	if not inBrawl(S, f) or _g(f, LINE) == 0 or not _wound(_g(f, KIND)) or _g(f, HOLD_AT) <= 0:
		return {}
	var kind: int = _g(f, KIND)
	var now: int = _now(S)
	var n: int = now - _g(f, HOLD_AT)
	var ch: Dictionary = cfg().heavy.charge
	var share: float = clampf(float(n - int(ch.fromTicks)) / maxf(1.0, float(int(ch.fullTicks) - int(ch.fromTicks))), 0.0, 1.0) if (kind == BIG and _g(f, CHG) > 0) else 0.0
	return {"strength": STRENGTH[kind], "n": maxi(0, n), "left": (_g(f, CONTACT) - now) if _g(f, LINE) == 1 else -1, "armoured": kind == BIG and _g(f, FLAV) == 0, "charge": share,
		"launcher": _g(f, FLAV) == 2, "energy": _g(f, FLAV) == 1}


## The windup cue's end, for a wound blow that announced its start. how: 1 thrown, 2 stopped by a blow, 3 lost to a
## stagger or the brawl's end, 4 a miss.
static func _wEnd(S: SimState, f, kind: int, how: int) -> void:
	var e = _ev(S, f, "windup", "end", _cellOf(2 if kind == BIG else 1))
	e.k = float(how)
	e.n = S.tick


## A wound blow's button at its wind-up's end, once a live tick (brawl-second-pass.md sections 2 and 3). Button up,
## it lands on its tick. Still down, it waits. Let go inside the grace, it goes at once. A medium still down at the
## decision point goes by itself, at a tap's strength, and so does the blast. A heavy still down there is charging:
## full at charge.fullTicks, it goes charge.landTicks after he lets go, and by itself at charge.maxTicks. A launcher
## still down as its wind-up ends has lost its guarantee, and is a heavy from there.
static func _windTick(S: SimState, ex, f, kind: int, now: int, up: bool = false) -> void:
	var c: Dictionary = cfg()
	var w: Dictionary = _wcfg(kind)
	var n: int = now - _g(f, HOLD_AT)
	var down: bool = _down(f, kind) and not up   # up: a fresh press of the button says the old one was let go
	if _g(f, LINE) == 1:
		if _g(f, CHG) == 0 and now >= _g(f, CONTACT) and down:
			if _g(f, FLAV) == 2:
				_unlaunch(S, ex, f)
			else:
				_park(S, ex, f)   # still held as its wind-up ends: it waits for the release
		return
	var ch: Dictionary = c.heavy.charge
	if kind == BIG and _g(f, CHG) > 0:
		if _g(f, CHG) == 1 and n >= int(ch.fullTicks):
			_s(f, CHG, 2)
			var fl = _ev(S, f, "charge_full", "", "b")
			fl.n = S.tick
		if not down or n >= int(ch.maxTicks):
			_letGo(S, ex, f, int(ch.landTicks), clampf(float(n - int(ch.fromTicks)) / maxf(1.0, float(int(ch.fullTicks) - int(ch.fromTicks))), 0.0, 1.0))
		return
	var wind: int = int(c.energy.reach.blast.windupTicks) if _g(f, FLAV) == 1 else int(w.windupTicks)
	if not down:
		_letGo(S, ex, f, 0, -1.0)   # let go inside the grace: a tap, and it goes at once
	elif n >= wind + SimInputData.ti(["read", "windupGrace"], 4):
		var more: float = float(ch.ki) - float(c.heavy.ki)
		if kind == BIG and f.ki >= more:
			f.ki -= more   # the charge's price, over the tap's
			_s(f, CHG, 1)
			var cs = _ev(S, f, "windup", "charge", "b")
			cs.n = S.tick + int(ch.fullTicks) - n   # the tick of its flash
			_repiece(S, ex, f, 2, "heavyHeld")   # it is a charge from here: its piece is the held cell's
		else:
			_letGo(S, ex, f, 0, -1.0)   # a medium has no charge yet, and a heavy he can't pay for: it goes by itself, a tap


## His wound blow waits past its wind-up for the button.
static func _park(S: SimState, ex, f) -> void:
	var role: String = "A" if f == ex.A else "D"
	for b in ex.beats:
		if not b.done and b.op == "strike" and b.args != null and b.args.get("brawl", false) and String(b.args.a) == role:
			b.t = ex.t + 3600.0
			_s(f, LINE, 2)
			_s(f, CONTACT, _now(S) + (1 << 20))
			return


## His parked wound blow goes: it lands `lead` live ticks from now. charge: -1 for a tap; else the heavy's charge, 0 to
## 1, which sets its worth between charge.worth's two ends and its reach. The stick's quarter is read here, once.
static func _letGo(S: SimState, ex, f, lead: int, charge: float) -> void:
	var c: Dictionary = cfg()
	var role: String = "A" if f == ex.A else "D"
	var o = ex.D if f == ex.A else ex.A
	for b in ex.beats:
		if b.done or b.op != "strike" or b.args == null or not b.args.get("brawl", false) or String(b.args.a) != role:
			continue
		if charge >= 0.0:
			var ch: Dictionary = c.heavy.charge
			b.args["charge"] = charge
			b.args["charged"] = true
			b.args["aim"] = _quarter(f, o)
			b.args["dmg"] = lerpf(float(ch.worth[0]), float(ch.worth[1]), charge) * _unit()
			if charge >= 1.0:
				DirInterrupt.si(f, DirInterrupt.PHRASE_P, DirInterrupt.gi(f, DirInterrupt.PHRASE_P) | (DirAlchemy.HELD << 8))   # held to full: a launch's earner
		b.t = ex.t + (float(lead) - 0.25) / DirData.TICKS_PER_SEC
		_s(f, LINE, 1)
		_s(f, CHG, 3)
		_s(f, CONTACT, _now(S) + lead)
		var e = _ev(S, f, "blow", "release")
		e.n = S.tick + lead
		e.amount = float(S.tick)
		e.dur = float(lead)
		e.x = maxf(0.0, charge)
		return


## A heavy landed clean. A tap staggers him in place. The launcher launches him when a launch is ready; while it
## rests it is the hammer, and staggers him in place. A charged heavy knocks him back, and at a full charge it launches him. A launch is aimed
## by the stick's quarter.
static func _bigLanded(S: SimState, ex, f, o, a) -> void:
	var c: Dictionary = cfg()
	_tradeReset(ex)
	if bool(a.get("launcher", false)):
		if bool(a.get("ready", false)):
			if a.has("power"):
				_ls(f, LA_POW, int(round(float(a.power) * _woundMul(o, String(a.get("piece", ""))) * 1000.0)))
			if DirRally.dazed(S, o):
				if a.has("power"):
					_ls(f, LA_POW, 1000)   # 23d 5: B at a dazed fighter is the sure launcher at full power, whatever the string
				_send(S, ex, f, o, int(a.get("aim", 0)), "the sell's send", float(c.launcher.flightMul), {"sold": true, "decisive": true})
				if a.has("power"):
					_ls(f, LA_POW, 0)
				return
			var pp: float = _popPower(S, f, o, int(a.get("aim", 0))) if (popOn() and a.has("power")) else 9.0
			if popOn() and _lg(o, LA_POP_UNTIL) > S.tick:
				_spike(S, ex, f, o)   # 23c 9: B at a popped fighter is the spike, never a send
			elif pp < float(popCfg().get("full", 0.8)):
				_pop(S, ex, f, o, pp)   # rulings-2026-10-23c 1: a weak launch is a pop, and the brawl holds
			else:
				_send(S, ex, f, o, int(a.get("aim", 0)), "the launcher", float(c.launcher.flightMul))
			if a.has("power"):
				_ls(f, LA_POW, 0)
		else:
			# The hammer (the fourth round): a resting launcher parts nobody. He staggers in place, as from a landed
			# heavy, and the brawl goes on: so using the launcher never breaks off a player's own pressure.
			_stagger(S, ex, f, o, int(c.heavy.staggerTicks), "heavy")
		return
	if bool(a.get("charged", false)):
		if float(a.get("charge", 0.0)) >= 1.0:
			if not DirRally.daze(S, ex, f, o, "charged_heavy"):   # 23d 1: with the rally on, a clean full charge dazes
				_send(S, ex, f, o, int(a.get("aim", 0)), "a heavy charged to full", 1.0)
		else:
			_knock(S, ex, f, o, 0.0, int(a.get("aim", 0)))
		return
	if DirRecoil.heavyRecoil(S, ex, f, o):
		return   # Game Design's 1a: a clean tapped heavy recoils him 1.5 bh, in place of the stagger
	_stagger(S, ex, f, o, int(c.heavy.staggerTicks), "heavy")


## The burst (brawl-second-pass.md section 3), once a live tick: a light whose button is still down burstStart live
## ticks after its press. From there seven more blows follow by themselves, landing at burst.lands live ticks from the
## press: fast at first, then slowing. The first of them is a full light; each after it is worth burst.rate for each
## tick of its gap. They are the director's blows and not presses: they aren't in his log. Letting go stops it after
## the blow in hand. After the last he is open burst.openTicks.
static func _burstTick(S: SimState, ex, f, now: int) -> void:
	var x: int = _g(f, X_LIVE)
	if x <= 0:
		return
	var n: int = _g(f, BURST_N)
	if f.stunTicks > 0:
		# A stagger ends the burst. It takes his buttons too (the core drops his held levels while it lasts), so the
		# hold can't be read here: it waits, and picks up at the floor pace when the stagger ends if X is still down.
		_burstEnd(S, f)
		_s(f, X_LIVE, 0)
		if int(cfg().burst.floorGap) > 0:
			_s(f, FLOOR, 2)
			_s(f, FLOOR_AT, S.tick)
			_s(f, FLOOR_T, now)
		return
	if not f.input.lightHeld:
		_burstEnd(S, f)
		_s(f, X_LIVE, 0)   # he let go: this press can't burst any more (the hold itself ends when X has read up two ticks: _held)
		return
	var c: Dictionary = cfg()
	var bu: Dictionary = c.burst
	var lands: Array = bu.lands
	if n == 0:
		if now - x < SimInputData.ti(["read", "burstStart"], 16):
			return
		n = 1   # the press's own light was its first blow
		_s(f, BURST_N, 1)
		var bs = _ev(S, f, "burst", "start", "x")
		bs.n = S.tick + maxi(1, x + int(lands[0]) - now)
	if n > lands.size():
		return
	var at: int = x + int(lands[n - 1])   # the live tick its next blow lands
	var lead: int = int(c.light.contactTicks)
	if now < at - lead or _g(f, LINE) != 0:
		return
	var worth: float = float(bu.second) if n == 1 else float(bu.rate) * float(int(lands[n - 1]) - int(lands[n - 2]))
	blowAt(S, ex, f, LIGHT, maxi(1, at - now), worth * _unit(), {"burst": n + 1, "flurry": true})   # burst: the blow's number in it, 2 to 8 (the press's own light was the first)
	_s(f, BURST_N, n + 1)
	if n + 1 > lands.size():
		_burstEnd(S, f)
		_s(f, X_LIVE, 0)
		if int(bu.floorGap) > 0:
			_s(f, FLOOR, 2)   # X is still down: it goes on at the floor pace, its next blow floorGap after this one
			_s(f, FLOOR_AT, S.tick + int(bu.floorGap))
			_s(f, FLOOR_T, now)
		else:
			_s(f, FREE_AT, _g(f, FREE_AT) + int(bu.openTicks))   # with no floor pace, after the last he is open


## The first move (the fourth round), once a director's tick: a fighter sent by a launch, a wall slam or a knock-back
## is marked while he is sent, and from the tick he is free again he can't start an approach for firstMove.lockTicks.
static func sentTick(S: SimState) -> void:
	if not on():
		return
	var lock: int = int(cfg().get("firstMove", {}).get("lockTicks", 0))
	if lock <= 0:
		return
	for f in S.fighters:
		if f.state == "launched" or f.state == "dropped" or f.state == "down":
			if _g(f, SENT) == 0:
				_s(f, SENT, 1)
		elif _g(f, SENT) == 1 and f.state == "free" and f.stunTicks <= 0:
			_s(f, SENT, 0)
			_s(f, MOVE_AT, S.tick + lock)
			if bool(_rcfg().get("enabled", false)):
				_s(f, RET_N, 1)   # he is returning: his approach back and his first blow back are read (bands.return)
				_s(f, RET_AT, _now(S))


## No window shorter for a freeze (DirWindows; rulings-2026-10-19b 4c): his windows that count every tick, the riposte
## and the launcher's late window, are put back by the freeze's ticks, and to at least `least` live ticks after it.
static func freezeWindows(S: SimState, f, frozen: int, least: int) -> void:
	for k in [RIP_UNTIL, LC_UNTIL]:
		var u: int = _g(f, k)
		if u > 0 and u >= S.tick:
			_s(f, k, maxi(u + frozen, S.tick + frozen + least))


## A freeze put his blow back d live ticks (DirWindows): its line's contact and its wind-up move with it.
static func holdBlow(S: SimState, f, d: int) -> void:
	if _g(f, LINE) == 0:
		return
	_s(f, CONTACT, _g(f, CONTACT) + d)
	if _g(f, HOLD_AT) > 0:
		_s(f, HOLD_AT, _g(f, HOLD_AT) + d)


## The return's numbers (data/director/interrupts.json bands.return).
static func _rcfg() -> Dictionary:
	return DirBands.data().get("return", {})


## True while f is returning from a send: free again after a launch, a knock-back or a fall, his first blow back still to
## come, and for bands.return.forTicks at most.
static func returning(S: SimState, f) -> bool:
	if _g(f, RET_N) != 1:
		return false
	var rc: Dictionary = _rcfg()
	if not bool(rc.get("enabled", false)) or _now(S) - _g(f, RET_AT) > int(rc.get("forTicks", 600)):
		return false
	return true


## His first blow back from a send in a planned exchange (a far charge's arrival keeps its template): every beat of it
## waits bands.return.firstWindTicks, and its window with it, and the windup cue (text "return") shows the tell.
static func returnTell(S: SimState, ex, A, D) -> void:
	var rw: int = int(_rcfg().get("firstWindTicks", 10))
	var first: float = INF
	for b in ex.beats:
		if not b.done:
			b.t += float(rw) / DirData.TICKS_PER_SEC
			if b.op == "strike" or b.op == "chainStrike":
				first = minf(first, b.t)
	if ex.windowStart >= 0.0:
		ex.windowStart += float(rw) / DirData.TICKS_PER_SEC
	_s(A, RET_N, 0)
	var e = _ev(S, A, "windup", "return", "")
	e.target = float(S.fighters.find(D))
	e.n = S.tick + (int(round((first - ex.t) * DirData.TICKS_PER_SEC)) if first < INF else rw)
	e.dur = float(rw)


## A recoil flip (DirRecoil): he is no longer sent, the first move is not the rival's, and he is not returning.
static func recoilFree(f) -> void:
	_s(f, SENT, 0)
	_s(f, MOVE_AT, 0)
	_s(f, RET_N, 0)


## True while the first move is the rival's: f was sent, and is free for fewer than firstMove.lockTicks.
static func moveLocked(S: SimState, f) -> bool:
	return on() and (_g(f, SENT) == 1 or S.tick < _g(f, MOVE_AT))


## True while A has the first move on D (firstMove.pursue): D was sent, is free again, and may not yet start an
## approach. A's press from the far band then flies in.
static func pursues(S: SimState, A, D) -> bool:
	return on() and bool(cfg().get("firstMove", {}).get("pursue", false)) and _g(D, SENT) == 0 and S.tick < _g(D, MOVE_AT) and not moveLocked(S, A)


## A press of his that would have started an approach while the first move is the rival's: it is spent, and says so.
static func moveRefused(S: SimState, f, kind: String) -> void:
	var a = _ev(S, f, "press_ack", "refused", _cell(kind))
	a.n = _g(f, MOVE_AT)


## Whether a held X outlives the brawl it was pressed in (burst.holdCarries).
static func carries() -> bool:
	return bool(cfg().get("burst", {}).get("holdCarries", false)) and int(cfg().burst.get("floorGap", 0)) > 0


## A press of f's, for his hold. x: it is an X with the button down and no energy family held, so it is a hold from
## here: its burst first, then the floor pace. Any other press ends the hold he had.
static func _hold(S: SimState, f, x: bool) -> void:
	if x and f.input.lightHeld and int(cfg().burst.floorGap) > 0:
		_s(f, FLOOR, 1)
		_s(f, FLOOR_AT, S.tick + int(cfg().burst.floorGap))
		_s(f, FLOOR_T, _now(S))
	elif _g(f, FLOOR) != 0:
		_s(f, FLOOR, 0)


## An attack press of f's that no brawl took (DirExchange.requestAttack), with burst.holdCarries: an X that stays
## down is a hold from here, and any other press ends the hold he had. Never the AI's: it holds X while its far
## charge lasts, and that is no held X.
static func pressedOut(S: SimState, f, kind: String) -> void:
	if on() and carries() and f.ai == null:
		_hold(S, f, kind == "light" and f.act.mode != 1 and not isB(f, kind))


## True while holdTick's press is being asked for: it is the hold's, and no press of his (not state: it lives for
## one call).
static var holding: bool = false


## With burst.holdCarries, once a live tick outside a brawl: a hold whose fighter is free, with no exchange, approach
## or taunt of his own going, presses as a tap does, floorGap apart. Out of reach that tap is an approach, so a held
## X closes the gap again after a brawl has ended. The blow it arrives with is the floor's: no new burst.
static func holdTick(S: SimState) -> void:
	if not on() or not carries() or S.game.ko != null:
		return
	for f in S.fighters:
		if f.ai != null or _held(S, f) == 0:
			continue   # the AI carries no hold; no hold, or one whose button can't be read on this tick
		if S.dirS.ex != null or S.tick < _g(f, FLOOR_AT) or f.state != "free" or f.rush != null or f.act.mode == 1:
			continue
		if DirBands.pending(f) or DirBands.taunting(f):
			continue
		_s(f, FLOOR, 2)
		_s(f, FLOOR_AT, S.tick + int(cfg().burst.floorGap))
		holding = true
		DirExchange.requestAttack(S, f, "light")
		holding = false


## His hold as it reads on this tick: its state (1 or 2) while X is down, else 0. A stagger takes his buttons: the
## core drops his held levels while it lasts, and on the tick it ends that tick's were dropped before the director
## sees the stagger over. So X is not read while he is staggered, and it counts as let go only when it has read up
## on two live ticks running. Then the hold is over. Safe to call more than once a tick.
static func _held(S: SimState, f) -> int:
	var h: int = _g(f, FLOOR)
	if h == 0:
		return 0
	var now: int = _now(S)
	if f.stunTicks > 0:
		if _g(f, FLOOR_T) != now:
			_s(f, FLOOR_T, now)
		return 0
	if f.input.lightHeld:
		if _g(f, FLOOR_T) != now:
			_s(f, FLOOR_T, now)
		return h
	if now - _g(f, FLOOR_T) >= 2:
		_s(f, FLOOR, 0)   # up two live ticks running: he let go
	return 0


## A held X after its burst (brawl-second-pass.md section 3, re-ruled in 14): it keeps throwing, one blow every
## burst.floorGap ticks for as long as X stays down. Each is a press through the tap's own path: a reel carries it
## as it carries a mashed press, and after a stagger the hold picks up again. It is worth the burst's rate for each
## tick of its gap and adds a full point to his run, as a tap does. Letting go ends it; a new burst needs a new press.
static func _floorTick(S: SimState, ex, f) -> void:
	if _held(S, f) == 0:
		return   # no hold, or one that waits a stagger out
	var hp: int = _g(f, HELD_P)
	if S.tick < _g(f, FLOOR_AT) or _g(f, X_LIVE) != 0 or (hp != 0 and (hp & 32) == 0):
		return   # not due, its burst still to come or running, or a press of his own is waiting
	var c: Dictionary = cfg()
	var gap: int = int(c.burst.floorGap)
	var last: int = _g(f, LAST_TAP)
	_s(f, FLOOR, 2)
	_s(f, FLOOR_AT, S.tick + gap)
	_s(f, LAST_AT, S.tick)
	f.lastAtkT = S.T
	_s(f, TAP_GAP, clampi(gap, int(c.flurry.minGap), int(c.flurry.maxGap)))
	_s(f, LAST_TAP, S.tick)
	if _g(f, LINE) == 0 and not _wound(_g(f, KIND)):
		_s(f, FREE_AT, mini(_g(f, FREE_AT), last + _g(f, TAP_GAP)))   # as a tap: the blow before lasts one tap gap
	if not _free(S, f):
		_s(f, HELD_P, 1 | 32)   # held as a press is, and thrown as his line frees
		_s(f, HELD_AT, S.tick)
		return
	_throw(S, f, 0, S.tick, false, false, false, false, true)


## His burst is over: he let go, he was staggered, another press replaced it, or its last blow is thrown.
static func _burstEnd(S: SimState, f) -> void:
	var n: int = _g(f, BURST_N)
	if n == 0:
		return
	_s(f, BURST_N, 0)
	var e = _ev(S, f, "burst", "end", "x")
	e.k = float(n)
	e.n = S.tick


## The strength of the next blow of the AI's string: a heavy or a medium at its level's shares, when it has the ki.
## A light or a medium is an energy art at its level's energy share (4 added to the strength).
static func _aiPick(S: SimState, ex, f, bl: Dictionary) -> int:
	var c: Dictionary = cfg()
	var key: int = S.tick * 2 + (0 if f == ex.A else 1)
	if _g(f, AI_MEDS) == 1 and f.ki >= float(c.medium.ki):
		return 1   # this string is mediums: he has thrown two heavies running
	var r: float = SimRng.keyed(int(S.game.seed), "brawl.mix", key)
	var mh: float = float(bl.get("mixHeavy", 0.0))
	if r < mh:
		return 2 if f.ki >= float(c.heavy.ki) else 0
	var st: int = 0
	if r < mh + float(bl.get("mixMedium", 0.0)) and f.ki >= float(c.medium.ki):
		st = 1
	var er: Dictionary = c.energy.reach
	if SimRng.keyed(int(S.game.seed), "brawl.energy", key) < float(bl.get("energy", 0.0)) and f.ki >= float((er.blast if st == 1 else er.bolt).ki):
		st |= 4
	return st


## The AI presses a blow of that strength, as a player does: X, Y, or B with no stance held; with 4 added, with the
## energy family held. Its next choice comes when the blow has had its pace. A heavy that isn't a tap is charged at
## its level's share: the button stays down to the flash, and it lets go within charge.aiReleaseTicks of it.
static func _aiPress(S: SimState, f, i: SimIntent, st: int, bl: Dictionary, tap: bool = false) -> void:
	var c: Dictionary = cfg()
	if (st & 4) != 0:
		i.mode = 1
		st &= 3
	if st == 2:
		i.sig = true
		i.sigHeld = true
		var wait: int = int(c.heavy.windupTicks) + 1
		var ch: Dictionary = c.heavy.charge
		var key: int = S.tick * 2 + (0 if f == S.dirS.ex.A else 1)
		_s(f, AI_HOLD, 0)
		if not tap and f.ki >= float(ch.ki) and SimRng.keyed(int(S.game.seed), "brawl.charge", key) < float(bl.get("charge", 0.0)):
			var after: int = 1 + int(SimRng.keyed(int(S.game.seed), "brawl.chargeLet", key) * float(int(ch.aiReleaseTicks)))
			_s(f, AI_HOLD, mini(after, int(ch.aiReleaseTicks)))   # the live ticks it holds on after the flash
			wait = int(ch.fullTicks) + int(ch.aiReleaseTicks) + int(ch.landTicks) + 2
		_s(f, AI_NEXT, S.tick + wait)
	elif st == 1:
		i.heavy = true
		i.heavyHeld = true
		_s(f, AI_NEXT, S.tick + int(c.medium.gap[0]))
	else:
		i.light = true
		_s(f, AI_NEXT, S.tick + (_g(f, AI_GAP) if _g(f, AI_GAP) > 0 else int(bl.get("tapGap", 10))))


# ---------------------------------------------------------------- once a live tick

## Before the exchange's beats (DirExchange.dirUpdate): what ends the brawl, held heavies, held presses, the trade,
## the walk-out, the centre's movement and the attraction.
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
	DirGrapple.tick(S, ex)   # the catch, the clinch and their exits (DirGrapple)
	if S.dirS.ex != ex or ex.branch != "":
		return
	_inTick = true
	for f in [ex.A, ex.D]:
		# What he has moved on this tick already: the core's step (the pair's drift, and a slope's lift), read against
		# where the director last left him; on the tick the brawl began, his flight or his lunge.
		var had: int = 0
		if _g(f, ARR_AT) == S.tick and S.tick > 0:
			had = _g(f, ARR_MV)
		elif _g(f, LAST_T) > 0:
			had = int(ceil(SimDetMath.hypot(SimWrap.sdx(float(_g(f, LAST_X)) / 16.0, f.x), f.y - float(_g(f, LAST_Y)) / 16.0) * 16.0))
		_s(f, OWN, 0)
		_own(f, float(had) / 16.0)
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
		if not _windOn(o):
			_s(f, GAVE, 0)   # the wind-up he gave ground against is over
		_laAnswerTick(S, f)
		# A launcher on its way holds the stagger until it lands. The launcher's window lasts as long as the stagger.
		if _g(f, FLAV) == 2 and _g(f, LINE) == 1 and _g(f, LC_LATE) == 0:
			o.stunTicks = maxi(o.stunTicks, _g(f, CONTACT) - now + 2)
		elif _g(f, LC_UNTIL) > 0 and o.stunTicks <= 0 and S.tick > _g(f, LC_UNTIL):
			_lcClose(S, f, "lapsed")
		# A boost with the stick away leaves, at the dodge-cancel's price and by its rules (a dodge tap is DirInterrupt's).
		if ex.t > SimConst.DT * 1.5 and f.input.sprint and f.stunTicks <= 0 and not DirGrapple.holds(f) and not sureAgainst(ex, f) and now >= _g(f, OPEN_UNTIL) and f.input.mx * SimMathx.jsign(SimWrap.sdx(f.x, o.x)) < -SimAct.awayDead and DirInterrupt.dodgeCancel(S, ex, f):
			_inTick = false
			return
		# A heavy still held as its wind-up ends waits for the release; it is let go, or lets go at heldMaxTicks.
		if _g(f, LINE) != 0 and _wound(_g(f, KIND)) and _g(f, HOLD_AT) > 0:
			_windTick(S, ex, f, _g(f, KIND), now)
		# A held press is thrown as his line frees, or lapses.
		var hp: int = _g(f, HELD_P)
		if (hp & 7) > 1 and _g(f, LINE) == 0 and not _wound(_g(f, KIND)):
			_s(f, FREE_AT, mini(_g(f, FREE_AT), _g(f, LAND_AT) + int(c.light.recover)))   # a wound blow kept behind a light: the mix-up
		if hp != 0:
			if S.tick - _g(f, HELD_AT) > int(c.heldPressTicks):
				_s(f, HELD_P, 0)
				if (hp & 32) == 0:   # a blow of the floor pace was no press: it has no ack
					var a = _ev(S, f, "press_ack", "lapsed", _cellOf((hp & 7) - 1))
					a.n = _g(f, HELD_AT)
			elif _free(S, f):
				_throw(S, f, (hp & 7) - 1, _g(f, HELD_AT), false, false, (hp & 8) != 0, (hp & 16) != 0, (hp & 32) != 0)
		_burstTick(S, ex, f, now)
		_floorTick(S, ex, f)
		# His string is over when nothing of his was thrown or landed for a while.
		if _g(f, STR_ON) == 1 and _g(f, LINE) == 0 and S.tick - _g(f, LAND_AT) > int(c.stringLapseTicks):
			_strEnd(f)
	_inTick = false
	_tradeTick(S, ex)
	if S.dirS.ex != ex or ex.branch != "":
		return
	if _g(ex.A, DBL_AT) > 0 and now > _g(ex.A, DBL_AT) + 2:
		_thrownApart(S, ex)   # one of the two blows was lost on its way: they are thrown apart all the same
		return
	# The walk-out: both hold away for partTicks full ticks running, and the brawl lets go, free. It ends partTicks
	# after the tick the later stick was first read, never sooner.
	if not quiet(ex) and not DirGrapple.holds(ex.A) and _g(ex.A, DBL_AT) == 0 and ex.t > SimConst.DT * 1.5 and _parting(S, ex):
		_s(ex.A, PART_N, _g(ex.A, PART_N) + 1)
		if _g(ex.A, PART_N) > int(c.partTicks):
			end(S, ex, "walk")
			return
	else:
		_s(ex.A, PART_N, 0)
	_move(S, ex)
	# A press from a gap closes it over ticks, as part of the blow (_throw).
	var stepping: bool = false
	for f in [ex.A, ex.D]:
		var cn: int = _g(f, CLOSE_N)
		if cn > 0:
			stepping = true
			if _g(f, OWN) < (1 << 20):
				_s(f, CLOSE_N, cn - 1)
				_stepIn(S, ex, f, ex.D if f == ex.A else ex.A, cn)
	# A wound blow steps through its reach in its last ticks before the contact, so its hand has no gap left to bridge
	# as it lands (Animation's reach of a piece). What it steps is added back when the reach is read (contact): the
	# reach is the blow's, and stepping doesn't lengthen it.
	for f in [ex.A, ex.D]:
		if _windOn(f) and _g(f, CLOSE_N) == 0 and _g(f, GAPV_ON) == 0:
			# The gap his blow must reach is counted from here: what it is now, then what the rival gives and he follows.
			_s(f, GAPV, int(round(maxf(0.0, DirBands.dist(f, ex.D if f == ex.A else ex.A) - float(DirData.contact().offset)) * 16.0)))
			_s(f, GAPV_ON, 1)
		if _g(f, LINE) == 1 and _wound(_g(f, KIND)) and _g(f, CLOSE_N) == 0 and f.stunTicks <= 0:
			var left: int = _g(f, CONTACT) - now
			if left >= 1 and left <= _lungeTicks(f):
				var lo = ex.D if f == ex.A else ex.A
				var d0: float = DirBands.dist(f, lo)
				_stepIn(S, ex, f, lo, 1)
				var stepped: float = d0 - DirBands.dist(f, lo)
				if stepped > 0.0:
					_s(f, PRE, _g(f, PRE) + int(round(stepped * 16.0)))
					stepping = true
	# While one winds a slow blow the other may give ground, and the winder may follow: each moves alone.
	var gv = _giver(S, ex)
	if gv != null:
		_giveStep(S, ex, gv)
	# The attraction: the pair's gap is held at striking distance, at one height. Past breakBh it lets go. It rests
	# while a step in is closing a gap, and while somebody may give ground.
	var d: float = SimWrap.sdx(ex.A.x, ex.D.x)
	if DirBands.dist(ex.A, ex.D) > float(c.breakBh) * DirInterrupt.BH:
		end(S, ex, "apart")
		return
	var ct: Dictionary = DirData.contact()
	var pull: float = float(c.pullBhPerSec) * DirInterrupt.BH * SimConst.DT * 0.5
	if ex.A.rush == null and ex.D.rush == null and gv == null and not stepping:
		var was := [ex.A.x, ex.A.y, ex.D.x, ex.D.y]
		if absf(d) > float(ct.offset):
			var px: float = minf((absf(d) - float(ct.offset)) * 0.5, pull)
			ex.A.x = SimWrap.wrap(ex.A.x + SimMathx.jsign(d) * px)
			ex.D.x = SimWrap.wrap(ex.D.x - SimMathx.jsign(d) * px)
		var dy: float = ex.D.y - ex.A.y
		var hi = ex.D if dy > 0.0 else ex.A
		if absf(dy) > 1.0 and hi.y <= WorldTerrain.groundY(S, hi.x, _gz()) + 0.5:
			# The higher one stands on the ground and can't come down (a slope the pair is on): the other comes up to him.
			var lo = ex.A if dy > 0.0 else ex.D
			lo.y = minf(hi.y, lo.y + float(c.maxStepBh) * DirInterrupt.BH)
		elif absf(dy) > 1.0:
			var py: float = minf(absf(dy) * 0.5, pull)
			ex.A.y = maxf(WorldTerrain.groundY(S, ex.A.x, _gz()), ex.A.y + SimMathx.jsign(dy) * py)
			ex.D.y = maxf(WorldTerrain.groundY(S, ex.D.x, _gz()), ex.D.y - SimMathx.jsign(dy) * py)
		_own(ex.A, SimDetMath.hypot(SimWrap.sdx(float(was[0]), ex.A.x), ex.A.y - float(was[1])))
		_own(ex.D, SimDetMath.hypot(SimWrap.sdx(float(was[2]), ex.D.x), ex.D.y - float(was[3])))
	if S.tick - maxi(_g(ex.A, LAST_AT), _g(ex.D, LAST_AT)) > int(c.idleTicks) and _g(ex.A, LINE) == 0 and _g(ex.D, LINE) == 0:
		end(S, ex, "idle")


# ---------------------------------------------------------------- the AI in a brawl (B1: the simplest that holds its commitments)

## The AI's input in a brawl (DirAI.aiInput). It chooses when its last choice has played out, not on a timer.
##  - A string of blows at its level's tap gap, each a light, a medium or a heavy by its shares (the mix-up).
##  - A guard for a drawn time, after which it must attack.
##  - A heavy against a rival who is guarding, at its level's guard-break rate; and into a running flurry of lights,
##    whose blows its armour takes, at heavyIntoFlurry.
##  - A medium into a rival's heavy while a medium still ends it, at mediumIntoHeavy: one draw for each wind-up.
##  - The burst, a held X, at its share.
##  - Its signature as outside, pressed with the charging stance held, since B alone is the heavy.
##  - As a trade starts it weighs digging in, at its level's digIn: dug in, it matches his pace for that trade, blow
##    for blow, until the trade breaks or the double hit lands. Two AIs never both dig in to one trade (digInBoth).
## It answers a paced string by its answerBy-th landed blow with a guard, and attacks into a gap (section 9c). Against a
## shooter it takes its level's vsShooter guard share. It writes real presses and holds, as a player does.
static func aiInput(S: SimState, f) -> void:
	var ex = S.dirS.ex
	var i: SimIntent = f.input
	var c: Dictionary = cfg()
	var lv: Dictionary = DirAI.lv()
	var bl: Dictionary = lv.get("brawl", {})
	var o = ex.D if f == ex.A else ex.A
	var slot: int = 0 if f == ex.A else 1
	var seed: int = int(S.game.seed)
	f.ai.st = 0.0
	_s(f, AI_GIVE, 0)
	if ex.branch != "" or ex.cancel or f.stunTicks > 0:
		return
	if quiet(ex):
		if f == ex.D:
			DirZip.aiReach(S, ex, f, i)   # the rival of a zipper in reach: its guard, its answer, its punish
		return   # a zipper in reach: his one blow is on its way
	if _g(ex.A, DBL_AT) > 0:
		return   # the double hit is on its way: nothing it presses counts
	if DirGrapple.aiInput(S, ex, f, o, i):
		return   # a catch's tell or a clinch is the grapple's, or it catches now
	# Giving ground, and following a rival who does (brawl-second-pass.md section 1). One draw for each wind-up: it
	# backs off after its reaction time, hands down, until his blow has landed or missed.
	var oh: int = _g(o, HOLD_AT)
	var m30: int = (1 << 30) - 1
	if _windOn(o) and _g(o, FLAV) != 2:
		if (_g(f, AI_GSAW) & m30) != oh:
			_s(f, AI_GSAW, oh | ((1 << 30) if SimRng.keyed(seed, "brawl.give", oh * 2 + slot) < float(bl.get("giveGround", 0.0)) else 0))
		if (_g(f, AI_GSAW) >> 30) == 1 and _g(f, LINE) == 0 and _now(S) - oh >= int(DirAI.skill().get("reactTicks", 14)):
			_s(f, AI_GIVE, 1)
			_s(f, AI_GUARD, 0)
			_s(f, AI_LEFT, 0)
			_s(f, HELD_P, 0)
			return
	if _windOn(f) and _g(o, GAVE) == 1:
		var fh: int = _g(f, HOLD_AT)
		if (_g(f, AI_FSAW) & m30) != fh:
			_s(f, AI_FSAW, fh | ((1 << 30) if SimRng.keyed(seed, "brawl.follow", fh * 2 + slot) < float(bl.get("follow", 0.0)) else 0))
		if (_g(f, AI_FSAW) >> 30) == 1:
			_s(f, AI_GIVE, 2)   # it walks its blow after him
	# Its heavy's charge: the button stays down to the flash, and AI_HOLD live ticks more.
	var ah: int = _g(f, AI_HOLD)
	if ah > 0:
		if (_g(f, LINE) != 0 and _g(f, KIND) == BIG and _g(f, CHG) != 3) or (_g(f, HELD_P) & 7) == 3:
			if _g(f, CHG) == 2:
				ah -= 1
				_s(f, AI_HOLD, ah)
			if ah > 0:
				i.sigHeld = true
		else:
			_s(f, AI_HOLD, 0)
	if S.tick < _g(f, AI_BURST):
		i.lightHeld = true   # ... or X, for its burst
		return
	if _aiPart(S, ex, f, o, bl):
		return   # it holds away with the rival, to walk out
	var gap: int = int(bl.get("tapGap", 10))
	if DirRally.aiSell(S, ex, f, o, i, bl):
		return   # 10-26 item 10: at a dazed rival it sells its mediums before B
	# The launcher: a tap of B while the stagger it caused holds the window open, at its level's share.
	if anywhere() and _aiLaunchInString(S, f, c):
		_s(f, AI_RIP, 0)
		_s(f, AI_GUARD, 0)
		_s(f, AI_LEFT, 0)
		_aiAim(S, f, o, i)
		_aiPress(S, f, i, 2, bl, true)
		return
	if _g(f, AI_LSAW) == 1 and _g(f, LC_UNTIL) > 0:
		_s(f, AI_LSAW, 0)
		if f.ki >= float(c.launcher.ki):
			_s(f, AI_RIP, 0)
			_s(f, AI_GUARD, 0)
			_s(f, AI_LEFT, 0)
			if anywhere():
				_aiAim(S, f, o, i)
			_aiPress(S, f, i, 2, bl, true)
			return
	# He missed, and is open: a medium while it still lands in time, else a light.
	if _now(S) < _g(o, OPEN_UNTIL) and _free(S, f) and S.tick >= _g(f, AI_NEXT):
		_s(f, AI_GUARD, 0)
		_s(f, AI_LEFT, 0)
		var openLeft: int = _g(o, OPEN_UNTIL) - _now(S)
		_aiPress(S, f, i, 1 if (f.ki >= float(c.medium.ki) and openLeft > int(c.medium.windupTicks) + _closeTicks(f, o)) else 0, bl)
		return
	# Its riposte (section 9f): after its perfect block, its next press inside the window, a light.
	if _g(f, AI_RIP) == 1:
		if _g(f, RIP_UNTIL) == 0 or S.tick > _g(f, RIP_UNTIL):
			_s(f, AI_RIP, 0)
		elif _free(S, f):
			_s(f, AI_RIP, 0)
			_s(f, AI_GUARD, 0)
			_s(f, AI_LEFT, 0)
			i.light = true
			_s(f, AI_NEXT, S.tick + gap)
			return
		else:
			return   # its line is busy: the riposte waits
	# Digging in (section 7, as re-ruled in 14 and in the fourth round): an AI that digs in during this match does so
	# as a trade starts. It matches his pace for that trade, blow for blow, until the trade breaks or the double hit lands.
	var t0: int = _g(ex.A, TRADE_T0)
	if t0 > 0 and _g(ex.A, TRADE_WIN) == 0:
		if (_g(f, AI_DIG) & m30) != t0:
			# Drawn once a match (the fourth round): at its level's share this AI digs in during this match, or it doesn't.
			# A share for each trade served nobody: a steady presser reached the cap in every match.
			var share: float = float(bl.get("digIn", 0.0)) * float(DirAI.skill().get("digInBy", {}).get(String(f.id), 1.0))
			share = 1.0 if SimRng.keyed(seed, "brawl.dig.match", slot) < share else 0.0
			if S.T < float(DirAI.skill().get("digInAfterS", 0.0)):
				share = 0.0   # not in the match's first seconds
			# Two AIs never both dig in to one trade (digInBoth): each would match the other, and every such trade would
			# run level to the double hit. One of the two, drawn for the trade, may. Against a player he is the one who
			# presses on, and nothing changes.
			if o.ai != null and not bool(DirAI.skill().get("digInBoth", false)) and (0 if SimRng.keyed(seed, "brawl.dig.who", t0) < 0.5 else 1) != slot:
				share = 0.0
			# It digs in to a bounded number of double hits: only while the match has had fewer than digInMax, and not
			# within digInRestS of fight time of the last. Against a steady presser every trade it dug in to ran to one.
			var digMax: int = int(DirAI.skill().get("digInMax", -1))
			var digRest: int = int(round(float(DirAI.skill().get("digInRestS", 0.0)) * DirData.TICKS_PER_SEC))
			if (digMax >= 0 and _g(f, MATCH_DBL) >= digMax) or (_g(f, MATCH_DBL_AT) > 0 and _now(S) - _g(f, MATCH_DBL_AT) < digRest):
				share = 0.0
			_s(f, AI_DIG, t0 | ((1 << 30) if SimRng.keyed(seed, "brawl.dig", t0 * 2 + slot) < share else 0))
		if (_g(f, AI_DIG) >> 30) == 1:
			_s(f, AI_GUARD, 0)
			_s(f, AI_LEFT, 0)
			if S.tick >= _g(f, AI_NEXT):
				i.light = true
				var pace: int = _g(o, TAP_GAP)
				_s(f, AI_NEXT, S.tick + (pace if pace > 0 else gap))
			return
	# Against a shooter (ruling 5) its guard share is its level's vsShooter number.
	var vs: Dictionary = lv.get("vsShooter", {}) if shooter(S, f, o) else {}
	var flurried: bool = _g(o, TAP_GAP) > 0 and S.tick - _g(o, LAST_TAP) <= int(c.flurry.maxGap) and o.stunTicks <= 0 and o.stance != 1.0
	# Section 9c: it answers a string by its answerBy-th landed blow, and doesn't stand and take the next: after its
	# reaction time it drops what it was doing and guards for guardMaxTicks, then it must attack. A flurry is not a
	# string to answer: against mashing it does what it does anyway.
	var by: int = int(bl.get("answerBy", 0))
	if by > 0 and _g(o, STRING_N) >= by and _g(o, ANSWERED) == 0 and not flurried:
		_s(o, ANSWERED, 1)
		_s(f, AI_ANS_AT, S.tick + int(DirAI.skill().get("reactTicks", 14)))
	if _g(f, AI_ANS_AT) > 0 and S.tick >= _g(f, AI_ANS_AT):
		_s(f, AI_ANS_AT, 0)
		_s(f, AI_GUARD, S.tick + int(bl.get("guardMaxTicks", 28)))
		_s(f, AI_LEFT, -1)
		_aiNudge(S, ex, f, false)
	# The rival winds a heavy: a medium that lands while one still ends it. One draw for each wind-up it sees.
	if oh > 0 and _g(o, LINE) != 0 and _g(o, KIND) == BIG and _g(o, FLAV) == 0 and _g(f, AI_SAW) != oh:
		_s(f, AI_SAW, oh)
		if _free(S, f) and f.ki >= float(c.medium.ki) and (_now(S) - oh) + int(c.medium.windupTicks) < int(c.heavy.armour.mediumUntilTicks) and SimRng.keyed(seed, "brawl.vsheavy", S.tick * 2 + slot) < float(bl.get("mediumIntoHeavy", 0.0)):
			_s(f, AI_GUARD, 0)
			_s(f, AI_LEFT, 0)
			_aiPress(S, f, i, 1, bl)
			return
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
	var left: int = _g(f, AI_LEFT)
	if left > 0:
		# The next blow of its string, on its cadence whatever its line is doing, as a player taps: one it cannot
		# throw at once is held.
		_s(f, AI_LEFT, left - 1)
		_aiPress(S, f, i, _aiPick(S, ex, f, bl), bl)
		return
	if _g(f, LINE) != 0:
		return   # a new choice waits for its blow to land
	# A new choice.
	if SimFighter.sigFree(f) or (f.ki >= 50.0 and S.T >= f.sigReadyT and S.rng.next() < float(DirAI.skill().sigPick)):
		i.sig = true
		i.stanceMask |= 4   # the charging stance: with no stance held, B is the heavy
		_s(f, AI_NEXT, S.tick + gap)
		return
	if o.stance == 1.0 and f.ki >= float(c.heavy.ki) and S.rng.next() < float(bl.get("breakGuard", lv.get("breakGuard", 0.0))):
		_aiPress(S, f, i, 2, bl)   # a heavy at a guard
		_aiNudge(S, ex, f, true)
		return
	if flurried and f.ki >= float(c.heavy.ki) and SimRng.keyed(seed, "brawl.into", S.tick * 2 + slot) < float(bl.get("heavyIntoFlurry", 0.0)):
		_aiPress(S, f, i, 2, bl)   # a heavy into his flurry of lights: its armour takes them
		_aiNudge(S, ex, f, true)
		return
	if left == 0 and S.rng.next() < float(vs.get("guardShare", bl.get("guardShare", 0.3))):
		var g: Array = bl.get("guardTicks", [20, 60])
		_s(f, AI_GUARD, S.tick + int(S.rng.range_(float(g[0]), float(g[1]) + 0.999)))
		_s(f, AI_LEFT, -1)   # after a guard it must attack
		i.guard = true
		f.ai.st = 1.0
		_aiNudge(S, ex, f, false)
		return
	if SimRng.keyed(seed, "brawl.burst", S.tick * 2 + slot) < float(bl.get("burst", 0.0)):
		i.light = true
		i.lightHeld = true
		var lands: Array = c.burst.lands
		_s(f, AI_BURST, S.tick + int(lands[lands.size() - 1]) + 2)
		_s(f, AI_NEXT, S.tick + int(lands[lands.size() - 1]) + int(c.burst.openTicks))
		_s(f, AI_LEFT, 0)
		_aiNudge(S, ex, f, true)
		return
	var n: Array = bl.get("string", [3, 5])
	_s(f, AI_LEFT, int(S.rng.range_(float(n[0]), float(n[1]) + 0.999)) - 1)
	# Each string has its own pace, between tapGap and tapGapMax: its pace isn't one number to fall short of.
	var gmax: int = maxi(gap, int(bl.get("tapGapMax", gap)))
	_s(f, AI_GAP, mini(gmax, gap + int(SimRng.keyed(seed, "brawl.tapgap", S.tick * 2 + slot) * float(gmax - gap + 1))))
	# Against a rival whose last two blows were heavies its string is mediums, at its level's share: the triangle,
	# played by the AI (a medium that lands on a heavy in its first ticks ends it).
	_s(f, AI_MEDS, 1 if (_g(o, LAST2) == HEAVY2 and SimRng.keyed(seed, "brawl.meds", S.tick * 2 + slot) < float(bl.get("mediumVsHeavies", 0.0))) else 0)
	_aiPress(S, f, i, _aiPick(S, ex, f, bl), bl)
	_aiNudge(S, ex, f, true)
	DirCamIntent.aiString(S, f, o, _g(f, AI_LEFT) + 1, _g(f, AI_GAP), int(c.light.contactTicks))   # the camera-intent feed: the AI's string, as it starts it


## f has moved by `d` units on this tick (the core's step; then a step in, giving ground, the attraction): the closing
## rule counts it. Called after the move: it marks where he now is.
static func _own(f, d: float) -> void:
	_s(f, OWN, mini(1 << 20, _g(f, OWN) + int(ceil(d * 16.0))))
	_s(f, LAST_X, int(round(f.x * 16.0)))
	_s(f, LAST_Y, int(round(f.y * 16.0)))
	_s(f, LAST_T, 1)


## True when the lunge f is on began with B, the heavy (DirBlast.hit; begin): his press of that tick in the log says
## so. The tick of his last B pressed out of reach stands in when the log has moved on.
static func bigLunge(f, tick: int) -> bool:
	var pp: int = DirAlchemy.at(f, tick)
	if pp >= 0:
		return (pp & DirAlchemy.BIG) != 0
	return _g(f, BIG_REQ) > 0 and tick == _g(f, BIG_REQ)


## An opening from outside this file (DirZip: the tech counter that staggers a zipper).
static func opening(S: SimState, ex, f, o, ticks: int, why: String) -> void:
	if isBrawl(ex) and ex.branch == "":
		_lcOpen(S, ex, f, o, ticks, why)


## For UI and Audio: true while f has an opening and his B would launch (the launcher isn't resting on his rival).
static func launcherReady(S: SimState, f) -> bool:
	if launcherOpen(S, f) < 0:
		return false
	return launcherRest(S, S.dirS.ex.D if f == S.dirS.ex.A else S.dirS.ex.A) == 0


## The live ticks for which the launcher still rests on o: launcher.restS of fight time after any launch of him. 0: a
## launch is ready on him. Cheap: one slot and the clock.
static func launcherRest(S: SimState, o) -> int:
	if anywhere():
		return 0   # launch anywhere: freshness replaces the rest
	var at: int = _g(o, LAUNCH_AT)
	if at <= 0:
		return 0
	return maxi(0, int(round(float(cfg().launcher.restS) * DirData.TICKS_PER_SEC)) - (_now(S) - at))


## o was launched, by anything (DirLaunch.doLaunch): the launcher rests on him from now.
static func launched(S: SimState, o) -> void:
	if on():
		_s(o, LAUNCH_AT, maxi(1, _now(S)))


## True while f is open after a miss: no blow, no guard, no dodge, no giving ground (DirInterrupt.dodgeCancel).
static func open(S: SimState, f) -> bool:
	return inBrawl(S, f) and _now(S) < _g(f, OPEN_UNTIL)


## A point-blank shot lands (brawl-second-pass.md section 5b): the blast's own hit in the core, with no exchange
## passed. On a guard it wears him by the blocked shot's rule; clean, it spreads as a shot and cripples nothing; the
## mood reads the bolt as a light and the blast as a medium (the hit's form). The brawl's own read of his guard
## stands (eff: his stance as the brawl reads it: a fighter with a blow on its way, staggered or open is not
## guarding). Returns 2 when a perfect block turned it, 1 when it landed clean, 0 when a guard took it.
static func _shotHit(S: SimState, ex, f, o, dmg: float, a, eff: float) -> int:
	f.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(f.x, o.x)), f.face)
	if bool(a.o.get("perfect", false)):
		DirInterrupt.perfectBlock(S, ex, f, o, a.o)
		return 2
	var er: Dictionary = cfg().energy.reach
	var blast: bool = String(a.energy) == "blast"
	var power: float = float(SimShots.kinds.get(String((er.blast if blast else er.bolt).shot), {}).get("power", 1.0))
	var held: float = o.stance
	o.stance = eff
	DirInterrupt.si(o, DirInterrupt.HIT_AT, S.tick)
	var so := {"kind": "blast", "shot": power, "form": "brawl_medium" if blast else "brawl_light", "stop": float(a.o.get("stop", 0.0)), "shake": 7.0 if blast else 3.0}
	DirMelee.weigh(S, so, "medium" if blast else "light")   # hit-stop by weight: a blast a medium's, a bolt a light's
	SimDamage.hit(S, null, f, o, dmg, so)
	o.stance = held
	if eff == 1.0:
		return 0
	DirInterrupt.si(f, DirInterrupt.LANDED, DirInterrupt.gi(f, DirInterrupt.LANDED) + 1)
	DirInterrupt.si(o, DirInterrupt.TAKEN, DirInterrupt.gi(o, DirInterrupt.TAKEN) + 1)
	return 1


## The live ticks before its contact in which f's wound blow steps through its reach (tick): enough steps of
## give.closeMaxBh, less its slack, to cover the reach of its strength. A heavy let go from a charge has the charge's.
static func _lungeTicks(f) -> int:
	var c: Dictionary = cfg()
	var kind: int = _g(f, KIND)
	var reach: float = float(c.heavy.charge.reachBh) if (kind == BIG and _g(f, CHG) == 3) else float(_wcfg(kind).reachBh)
	return int(ceil(reach / maxf(0.05, float(c.give.closeMaxBh) - float(c.give.closeSlackBh))))


## A signature's tell (Game Design's ruling, 2026-10-06): the defender isn't frozen for it. Once a live tick, until the
## beam leaves, his stick moves him alone at the rate of giving ground, less behind a guard, for at most
## give.leashBh in all. It is movement and nothing else: the beam's outcome is still read from his stance and his
## answers, which he holds while he moves, and moving doesn't take him out of the beam. The AI does it against its
## level's giveGround share of the signatures it faces, straight away from the attacker, after its reaction time.
static func tellTick(S: SimState, ex) -> void:
	if not on() or ex.kind != "sig" or isBrawl(ex) or ex.cancel:
		return
	var tell: bool = false
	for b in ex.beats:
		if not b.done and b.op == "beamFire":
			tell = true
	var f = ex.D
	if not tell or f.state != "locked" or f.stunTicks > 0:
		return
	var gi: Dictionary = cfg().give
	if _g(f, TELL_N) != ex.n:
		_s(f, TELL_N, ex.n)
		_s(f, TELL_MV, 0)
	var ux: float = f.input.mx
	var uy: float = f.input.my
	if f.ai != null:
		ux = 0.0
		uy = 0.0
		var share: float = float(DirAI.lv().get("brawl", {}).get("giveGround", 0.0))
		if ex.t * DirData.TICKS_PER_SEC >= float(int(DirAI.skill().get("reactTicks", 14))) and SimRng.keyed(int(S.game.seed), "brawl.tellGive", ex.n * 2 + (0 if f == S.fighters[0] else 1)) < share:
			var lx: float = SimWrap.sdx(ex.A.x, f.x)
			var ly: float = f.y - ex.A.y
			var ll: float = SimDetMath.hypot(lx, ly)
			if ll > 0.0:
				ux = lx / ll
				uy = ly / ll
	var ul: float = SimDetMath.hypot(ux, uy)
	if ul <= SimAct.awayDead:
		return
	var step: float = float(gi.bhPerSec) * DirInterrupt.BH * SimConst.DT * minf(1.0, ul)
	if bool(gi.bySpeed):
		step *= _flySpeed(S, f) / float(gi.speedRef)
	if f.stance == 1.0:
		step *= float(gi.guard)
	step = minf(step, float(gi.leashBh) * DirInterrupt.BH - float(_g(f, TELL_MV)) / 16.0)
	if step <= 0.0:
		return
	var nx: float = SimWrap.wrap(f.x + ux / ul * step)
	var ny: float = maxf(WorldTerrain.groundY(S, nx, _gz()), f.y + uy / ul * step)
	if _walled(S, nx, ny) and not _walled(S, f.x, f.y):
		return
	_s(f, TELL_MV, _g(f, TELL_MV) + int(ceil(SimDetMath.hypot(SimWrap.sdx(f.x, nx), ny - f.y) * 16.0)))
	f.x = nx
	f.y = ny

