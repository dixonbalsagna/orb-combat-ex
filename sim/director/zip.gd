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
## Flight strikes (flightStrikes.enabled, off; docs/design/playable-build.md section 1) make it one grammar: hold LT, point the left
## stick, press X, Y or B. The stick's bearing on the press's tick picks the path (the zip, the line through him, the arc over or
## under him, the parting shot), the button the blow (X quick, Y heavy, B biggest), from contact to rangeBh. A player's press counts
## within takeBack.ticks of LT's press (the take-back) or inside a chain. Its start cue is zip_light, zip_heavy or zip_big, its text
## the path's word and its source the button. docs/director/pending/flight-strikes/README.md.
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

# Flight strikes: the exit is the path's, so the exit's ring isn't read, and its first slots hold the flight strike's own state.
# F_LINK to F_OPEN outlive the strike (the chain, and the opening after a miss).
const F_PATH: int = RING        # 0 the zip, 1 the line, 2 the arc over, 3 the arc under, 4 the parting shot
const F_WORTH: int = RING + 1   # its worth in its chain, in thousandths
const F_NEXT: int = RING + 2    # a chain press kept for its end: path * 4 + button (1 X, 2 Y, 3 B); 0 none
const F_NEXT_AT: int = RING + 3 # ... and the S.tick of that press
const F_LINK: int = RING + 4    # its link in the chain: 0 the first strike
const F_STREAK: int = RING + 5  # the same path and button this many times running in the chain
const F_LAST: int = RING + 6    # the last strike's path * 4 + button
const F_END: int = RING + 7     # S.tick the last flight strike completed its path (0 none, or it didn't)
const F_OPEN: int = RING + 8    # S.tick until which he's open after a miss
const F_KEEP: Array = [F_LINK, F_STREAK, F_LAST, F_END, F_OPEN]
const ZIP_P: int = 0
const LINE_P: int = 1
const OVER_P: int = 2
const UNDER_P: int = 3
const PART_P: int = 4
const BIGK: int = 3             # KIND: B, the flight strike's biggest blow
const PATHS: Array = ["zip", "line", "over", "under", "parting"]
const BTNS: Array = ["", "x", "y", "b"]
const STARTS: Array = ["", "zip_light", "zip_heavy", "zip_big"]

const PHASES: Array = ["", "tell", "in", "reach", "out"]
const READS: Array = ["speed", "tech", "heavy"]
const EXITS: Array = ["", "home", "far", "point"]
const PASSES: Array = ["", "over", "round", "under"]


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("zip", {})


static func on() -> bool:
	return DirBrawl.on() and cfg().get("enabled", false)


static var _fsForce: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func fsCfg() -> Dictionary:
	return cfg().get("flightStrikes", {})


static func setFsForce(v: int) -> void:
	_fsForce = v


## The flight strikes (zip.flightStrikes.enabled, off).
static func fsOn() -> bool:
	return on() and (bool(fsCfg().get("enabled", false)) if _fsForce < 0 else _fsForce == 1)


static func _size(f) -> void:
	if f.act.dirI.size() >= END:
		return
	DirBrawl._size(f)
	if f.act.dirI.size() < END:
		f.act.dirI.resize(END)


static func _g(f, k: int) -> int:
	_size(f)
	return f.act.dirI[k]


static func _s(f, k: int, v: int) -> void:
	_size(f)
	f.act.dirI[k] = v


static func _cue(S: SimState, f, name: String, text: String = "", source: String = ""):
	SimFx.cue(S, f, name, text, source)
	return S.out.fx[S.out.fx.size() - 1]


## True while f is zipping, from his press to the end of his way out (or to the catch).
static func zipping(f) -> bool:
	return _g(f, PH) != 0


## True on his way out: no strike reaches him there.
static func untouchable(f) -> bool:
	return _g(f, PH) == 4


## True from the tick the rival ended his ticks in reach under him (a dodge away, a burst) until the zip's next tick,
## when he leaves by his exit: no strike reaches him in between, as none does on his way out (DirExchange._start).
static func leaving(S: SimState, f) -> bool:
	return _g(f, PH) == 3 and _g(f, STATE) != 2 and not _mine(S, f)


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
	var big: bool = DirBrawl.isB(A, kind)   # B with no stance held: the heavy
	var fs: bool = fsOn()
	if fs and kind == "sig" and (A.input.stanceMask & LT) != 0 and A.act.mode != 1:
		big = true   # LT + B: the flight strike's biggest blow (never a send)
	if not on() or (kind == "sig" and not big):
		return false
	if zipping(A):
		if fs and _chainPress(S, A, kind, big):
			return true
		_cue(S, A, "press_ack", "zip", DirBrawl._cell(kind)).n = S.tick
		return true
	if fs and S.tick < _g(A, F_OPEN):
		_s(A, F_NEXT, ["light", "heavy", "sig"].find(kind) + 1)   # the latest press waits for the opening's end (the brawl's held-press rule)
		_s(A, F_NEXT_AT, S.tick)
		_cue(S, A, "press_ack", "open", DirBrawl._cell(kind)).n = S.tick   # a flight strike's miss: he's open, and his presses wait
		return true
	var Z = aimedAt(S, A)
	if Z != null:
		if A.act.mode == 1 or A.state != "free" or A.stunTicks > 0:
			return false
		var w: int = 3 if big else (2 if kind == "heavy" else 1)   # X, Y the medium, B the heavy
		var price: float = float((DirBrawl.cfg().heavy if w == 3 else DirBrawl.cfg().medium).ki)
		if w >= 2 and A.ki < price:
			w = 1
		if w >= 2 and _g(A, ANS_W) != w:
			A.ki -= price   # a wound blow is paid for as it is pressed, as in a brawl
		var pp: int = S.tick - DirBrawl._waited(A)
		var mash: bool = _g(A, ANS_LAST) > 0 and pp - _g(A, ANS_LAST) <= int(DirBrawl.cfg().flurry.maxGap)
		_s(A, ANS_LAST, pp)
		if w >= _g(A, ANS_W):
			_s(A, ANS_W, w)
			_s(A, ANS_AT, pp)
			_s(A, ANS_MASH, 1 if mash else 0)
		_cue(S, A, "press_ack", "answer", DirBrawl._cell(kind)).n = S.tick
		return true
	if fs:
		return _fsTakes(S, A, kind, big)
	if (A.input.stanceMask & LT) == 0:
		return false
	var D = SimRoster.opp(S, A)
	var c: Dictionary = cfg()
	var d: float = DirBands.dist(A, D) / BH
	if d < float(c.band.minBh) or d > float(c.band.maxBh):
		return false   # in reach the same buttons are the step strike and its family; further out, the piloted charge
	if S.dirS.ex != null or S.game.ko != null or (A.state != "free" and A.state != "charging") or A.stunTicks > 0 or DirBands.pending(A) \
			or D.hidden or D.state == "launched" or D.state == "down" or D.state == "dropped" or zipping(D) or DirBury.safe(S, D):
		_cue(S, A, "press_ack", "zip_refused", DirBrawl._cell(kind)).n = S.tick
		return true
	var heavy: bool = kind == "heavy"
	if A.ki < float((c.heavy if heavy else c.strike).ki):
		_cue(S, A, "press_ack", "zip_no_ki", DirBrawl._cell(kind)).n = S.tick
		return false
	start(S, A, D, heavy, S.tick - DirBrawl._waited(A))
	return true


# ---------------------------------------------------------------- flight strikes: the press

## LT held with X, Y or B (flightStrikes): the flight strike, its path read from the left stick on the press's tick.
##  - A player's press counts within takeBack.ticks of LT's press, LT still held (the take-back: the slip or dodge-cancel LT made
##    is undone, its energy and cooldown given back), or inside a chain. Past the window, LT still held, the button is its own
##    blow and LT's own move carries on (Game Design's ruling of 2026-11-06). The computer's press is its own choice.
##  - Knocked back or launched: nothing new (held LT is the air brake). Charging a beam or a stick strike, or LB held too (the
##    vanish): not read. Past rangeBh: today's long strike.
##  - Stunned or busy: refused, with the knock. No energy: refused, with the knock, and nothing starts (no take-back either).
static func _fsTakes(S: SimState, A, kind: String, big: bool) -> bool:
	var fc: Dictionary = fsCfg()
	var tb: Dictionary = fc.takeBack
	if not (_ltHeld(A) or (A.ai == null and not bool(tb.get("needsLtHeld", true)))):
		return false
	if (A.input.stanceMask & DirStick.LB) != 0 or A.beamCharge != null or DirStick.pending(A) or DirStick.holding(A):
		return false   # LB + LT is the vanish; a charge keeps its own rules (and a stick strike's press is the stick's)
	if A.state == "launched" or A.state == "down" or A.state == "dropped":
		return false   # nothing new: held LT is the air brake
	var age: int = S.tick - A.act.dodgeTick
	var back: bool = A.ai == null and age >= 0 and age <= int(tb.ticks)
	var link: bool = _g(A, F_END) > 0 and S.tick - _g(A, F_END) <= int(fc.chain.afterTicks)
	if A.ai == null and not back and not link:
		return false   # past the window, LT still held: the button is its own blow, and LT's slip or escape carries on
	var D = DirBrawl.rivalOf(S, A)
	var d: float = DirBands.dist(A, D) / BH
	if d < float(fc.rangeBh[0]) or d > float(fc.rangeBh[1]):
		return false   # past the middle band's edge: today's long strike
	if back and age == 0 and DirBrawl.exOf(S) == null and DirBands.pending(A):
		DirBands.cancel(S, A)   # LT is read first: LT's press calls his own approach off, and the take-back below undoes its cost
	if S.game.ko != null or DirBrawl.exOf(S) != null or (A.state != "free" and A.state != "charging") or A.stunTicks > 0 or DirBands.pending(A):
		_refused(S, A, kind, "stunned" if A.stunTicks > 0 else "busy")
		return true
	if D.hidden or D.state == "launched" or D.state == "down" or D.state == "dropped" or zipping(D) or DirBury.safe(S, D):
		_cue(S, A, "press_ack", "zip_refused", DirBrawl._cell(kind)).n = S.tick
		return true
	var btn: int = BIGK if big else (2 if kind == "heavy" else 1)
	var ln: int = (_g(A, F_LINK) + 1) if link else 0
	var price: float = _price(btn, d, ln)
	var refund: float = _refund(A) if back else 0.0
	if A.ki + refund < price:
		_refused(S, A, kind, "ki")   # "No energy": the pad knocks, and LT's own move carries on
		return true
	if back:
		_takeBack(S, A, refund)
	_fsStart(S, A, D, btn, _pathOf(S, A, D), S.tick - DirBrawl._waited(A), price, ln)
	return true



## A player's press in a brawl (DirBrawl.takes; playable-build.md section 1: the flight strikes replace the stances' LT lane, from
## contact): 1 when it's a flight strike, so the brawl gives way and the press goes on to start it (takes); 2 when it would be one but
## can't be paid ("No energy", the knock, the press spent); 0 when it's the brawl's own blow. The same take-back window as outside:
## a face press within takeBack.ticks of LT's press, LT held. His line must be free (no blow of his own on its way, no reel).
static func fromBrawl(S: SimState, f, kind: String) -> int:
	if not fsOn() or f.act.mode == 1 or (f.ai != null and _g(f, AI_EXIT) == 0):
		return 0   # (the computer's own when it picked one: aiBrawl)
	var big: bool = kind == "sig" and (f.input.stanceMask & LT) != 0
	if kind == "sig" and not big:
		return 0
	var fc: Dictionary = fsCfg()
	var tb: Dictionary = fc.takeBack
	if not (_ltHeld(f) or not bool(tb.get("needsLtHeld", true))):
		return 0
	if (f.input.stanceMask & DirStick.LB) != 0 or f.beamCharge != null or DirStick.pending(f) or DirStick.holding(f):
		return 0
	var age: int = S.tick - f.act.dodgeTick
	if (f.ai == null and (age < 0 or age > int(tb.ticks))) or not DirBrawl._free(S, f):
		return 0
	var D = DirBrawl.rivalOf(S, f)
	var d: float = DirBands.dist(f, D) / BH
	if D.hidden or DirBury.safe(S, D) or D.state == "launched" or D.state == "down" or D.state == "dropped" or d > float(fc.rangeBh[1]):
		return 0
	var btn: int = BIGK if big else (2 if kind == "heavy" else 1)
	if f.ki + _refund(f) < _price(btn, d, _nextLink(S, f)):
		_refused(S, f, kind, "ki")
		return 2
	return 1


## LT held: the dodge control physically down when Controls' dodgeHeld bit is on (a player's), else the stance mask's LT.
static func _ltHeld(A) -> bool:
	if A.ai == null and SimInputData.dodge_held_on():
		return A.input.dodgeHeld
	return (A.input.stanceMask & LT) != 0


## The path, from the left stick on the press's tick against the line to him (bearing): under deadzone the zip; within towardDeg
## of toward the line; within awayDeg of away the parting shot; else the half above the line is the arc over and the half below
## it the arc under. The computer's is its pick (AI_EXIT, aiUse).
static func _pathOf(S: SimState, A, D) -> int:
	if A.ai != null and _g(A, AI_EXIT) > 0:
		var p: int = _g(A, AI_EXIT) - 1
		_s(A, AI_EXIT, 0)
		return p
	var b: Dictionary = fsCfg().bearing
	var mx: float = A.input.mx
	var my: float = A.input.my
	var sl: float = SimDetMath.hypot(mx, my)
	if sl < float(b.deadzone):
		return ZIP_P
	var lx: float = SimWrap.sdx(A.x, D.x)
	var ly: float = D.y - A.y
	var ll: float = SimDetMath.hypot(lx, ly)
	if ll < 1.0:
		lx = A.face
		ly = 0.0
		ll = 1.0
	var c: float = (mx * lx + my * ly) / (sl * ll)
	if c >= SimDetMath.cos(float(b.towardDeg) * SimMathx.PI / 180.0):
		return LINE_P
	if c <= -SimDetMath.cos(float(b.awayDeg) * SimMathx.PI / 180.0):
		return PART_P
	var nx: float = -ly   # the line's normal on its upper side (for a line straight up or down, the side he faces)
	var ny: float = lx
	if ny < 0.0 or (ny == 0.0 and nx * A.face < 0.0):
		nx = -nx
		ny = -ny
	return OVER_P if mx * nx + my * ny >= 0.0 else UNDER_P


## The price: X, Y or B's own (blows), plus up to kiByDistance.add rising evenly from fromBh to toBh; each link of a chain
## chain.kiMul times the one before.
static func _price(btn: int, dBh: float, link: int) -> float:
	var fc: Dictionary = fsCfg()
	var kd: Dictionary = fc.kiByDistance
	var t: float = clampf((dBh - float(kd.fromBh)) / maxf(0.001, float(kd.toBh) - float(kd.fromBh)), 0.0, 1.0)
	var p: float = float(fc.blows[BTNS[btn]].ki) + float(kd.add) * t
	for _i in range(link):
		p *= float(fc.chain.kiMul)
	return p


## What the take-back gives back: the dodge-cancel's energy when LT's press made a paid one (its cooldown is fresh), else 0.
static func _refund(A) -> float:
	var dc: Dictionary = DirInterrupt.data().dodgeCancel
	return float(dc.ki) if A.act.dodgeCool > int(dc.cooldownTicks) - int(fsCfg().takeBack.ticks) - 2 else 0.0


## The take-back (Game Design's ruling of 2026-11-06): the slip or dodge-cancel LT made is undone. Its energy and its cooldown come
## back, and the slip's protection ends at once. The body carries on from where it is. The cue take_back (text cancel or slip).
static func _takeBack(S: SimState, A, refund: float) -> void:
	var dc: Dictionary = DirInterrupt.data().dodgeCancel
	var w: int = int(fsCfg().takeBack.ticks) + 2
	var was: String = "slip"
	if refund > 0.0 or A.act.dodgeCool > int(dc.freeGapTicks) - w:
		was = "cancel"
		A.ki = minf(100.0, A.ki + refund)
		A.act.dodgeCool = 0
	A.act.dodgeTick = -1000000
	_cue(S, A, "take_back", was, "")


## A press the flight strike refuses: the pad knocks and nothing starts. press_refused's text is the reason (ki: "No energy" at the
## edge, by UI's rule; stunned; busy), its source the button's cell.
static func _refused(S: SimState, A, kind: String, why: String) -> void:
	_cue(S, A, "press_refused", why, DirBrawl._cell(kind)).n = S.tick


## A press inside a flight strike: in its last chain.lateTicks, LT held, it's kept, and the next link starts as this one ends.
static func _chainPress(S: SimState, A, kind: String, big: bool) -> bool:
	if not _ltHeld(A) or _left(A) > int(fsCfg().chain.lateTicks):
		return false
	var btn: int = BIGK if big else (2 if kind == "heavy" else 1)
	_s(A, F_NEXT, _pathOf(S, A, DirBrawl.rivalOf(S, A)) * 4 + btn)
	_s(A, F_NEXT_AT, S.tick - DirBrawl._waited(A))
	_cue(S, A, "press_ack", "chain", DirBrawl._cell(kind)).n = S.tick
	return true


## The live ticks left of his flight strike once his blow has resolved (a large number before it has).
static func _left(f) -> int:
	var ph: int = _g(f, PH)
	if ph == 4:
		return _g(f, LEFT)
	if ph == 3 and _g(f, STATE) == 1:
		return _g(f, LEFT) + _g(f, WAYOUT)
	return 1 << 20


## The kept press starts the next link as this one ends (_end, done). Refused as a press is.
static func _chain(S: SimState, f) -> void:
	var nx: int = _g(f, F_NEXT)
	var at: int = _g(f, F_NEXT_AT)
	_s(f, F_NEXT, 0)
	var D = DirBrawl.rivalOf(S, f)
	var fc: Dictionary = fsCfg()
	var btn: int = nx & 3
	var kind: String = ["", "light", "heavy", "sig"][btn]
	var d: float = DirBands.dist(f, D) / BH
	if d > float(fc.rangeBh[1]) or DirBrawl.exOf(S) != null or S.game.ko != null or f.state != "free" or f.stunTicks > 0 \
			or D.hidden or D.state == "launched" or D.state == "down" or D.state == "dropped" or zipping(D) or DirBury.safe(S, D):
		_cue(S, f, "press_ack", "zip_refused", DirBrawl._cell(kind)).n = S.tick
		return
	var ln: int = _g(f, F_LINK) + 1
	var price: float = _price(btn, d, ln)
	if f.ki < price:
		_refused(S, f, kind, "ki")
		return
	_fsStart(S, f, D, btn, nx >> 2, at, price, ln)


## The flight strike starts: the price is paid, and the tell begins where he stands. A link of a chain has its tell halved (never
## under chain.tellMin), unless it's the same path and button for the chain.repeatFullTell-th time running, and it's worth
## chain.worthMul a link (never under chain.worthFloor). The reach and the way out keep the zip's tables by weight (X the strike's,
## Y and B the heavy's); the line and the arcs have their own reach ticks (reachTicks: before his blow, after it).
static func _fsStart(S: SimState, A, D, btn: int, path: int, p: int, price: float, link: int) -> void:
	var c: Dictionary = cfg()
	var fc: Dictionary = fsCfg()
	var ch: Dictionary = fc.chain
	var k: Dictionary = c.heavy if btn >= 2 else c.strike
	var pb: int = path * 4 + btn
	var streak: int = (_g(A, F_STREAK) + 1) if (link > 0 and _g(A, F_LAST) == pb) else 1
	var tell: int = int(fc.blows[BTNS[btn]].tell)
	if link > 0 and streak % int(ch.repeatFullTell) != 0:
		tell = maxi(int(ch.tellMin), roundi(float(tell) * float(ch.tellMul)))
	var worth: float = 1.0
	for _i in range(link):
		worth *= float(ch.worthMul)
	worth = maxf(float(ch.worthFloor), worth)
	_size(A)
	for i in range(PH, END):
		if i != ANS_W and i != ANS_AT and i != AI_EXIT and not F_KEEP.has(i):
			A.act.dirI[i] = 0
	A.ki -= price
	var d: float = DirBands.dist(A, D)
	var rb: int = int(k.reachBefore)
	var ra: int = int(k.reachAfter)
	if path == LINE_P:
		rb = int(fc.line.reachTicks[0])
		ra = int(fc.line.reachTicks[1])
	elif path == OVER_P or path == UNDER_P:
		rb = int(fc.arc.reachTicks[0])
		ra = int(fc.arc.reachTicks[1])
	_s(A, KIND, btn)
	_s(A, PRESS, p)
	_s(A, TELL, tell)
	_s(A, READ, 1 if DirBands.pending(D) else 0)   # pressed inside his tell: the tech reading, as a zip's
	_s(A, RB, rb)
	_s(A, RA, ra)
	_s(A, WAYOUT, int(k.outTicks))
	_s(A, X0, roundi(A.x * FX))
	_s(A, Y0, roundi(A.y * FX))
	_s(A, D0, roundi(d * FX))
	_s(A, SIDE, 1 if SimWrap.sdx(D.x, A.x) >= 0.0 else -1)
	_s(A, F_PATH, path)
	_s(A, F_WORTH, roundi(worth * 1000.0))
	_s(A, F_LINK, link)
	_s(A, F_STREAK, streak)
	_s(A, F_LAST, pb)
	_s(A, F_END, 0)
	_s(A, F_OPEN, 0)
	if path == OVER_P or path == UNDER_P:
		var pl: Array = _loop(S, A, D, true)   # the plan, as the loop would fly it from here
		_s(A, WAYIN, maxi(1, int(pl[1]) - rb))
		_s(A, WAYOUT, int(pl[0]) - int(pl[1]))
	else:
		_s(A, WAYIN, _travel(d / BH))
	_s(A, PH, 1)
	_s(A, LEN, tell)
	_s(A, LEFT, tell)
	_s(D, ANS_W, 0)
	_s(D, ANS_LAST, 0)
	DirBands.endTaunt(S, A, false, "cut")
	A.state = "free"
	A.hideT = 0.0
	A.rush = null
	A.breathT = S.T
	A.vx = 0.0
	A.vy = 0.0
	A.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(A.x, D.x)), A.face)
	var e = _cue(S, A, STARTS[btn], PATHS[path], BTNS[btn])
	e.target = float(S.fighters.find(D))
	e.amount = float(tell)
	e.n = _g(A, WAYIN)
	e.dur = float(tell + _g(A, WAYIN) + rb + ra + _g(A, WAYOUT))
	e.x = float(rb)
	e.y = float(ra)
	e.k = float(link)
	SimFx.rush(S, A, D, S.tick + tell + _g(A, WAYIN))
	seen(S, D, A, tell + _g(A, WAYIN))
	SimEvents.feed(S, A.name + " FLIGHT STRIKE", PATHS[path] + ", " + BTNS[btn].to_upper() + (", link " + str(link) if link > 0 else "") + "; " + SimMathx.jstr(SimMathx.jround(d / BH)) + " bh; " + SimMathx.jstr(SimMathx.jround(price)) + " ki; a tell of " + str(tell) + " ticks")


## Travel (RL-076): at least travel.minTicks, and never more than travel.bhPerTick a tick.
static func _travel(dBh: float) -> int:
	var tr: Dictionary = fsCfg().travel
	return maxi(int(tr.minTicks), int(ceil(dBh / float(tr.bhPerTick))))


## An arc's loop round D (SimFighter.loopRush): over or under, its top arc.riseBh over his head, ending arc.endUpBh up on his far
## side, in arc.ticks at least and inside the travel floor. Returns [its ticks, the tick of its top (or bottom), where the blow lands].
## plan: only planned, and f's rush is left as it was.
static func _loop(S: SimState, f, D, plan: bool) -> Array:
	var fc: Dictionary = fsCfg()
	var ac: Dictionary = fc.arc
	var tr: Dictionary = fc.travel
	var keep = f.rush
	var n: int = SimFighter.loopRush(S, f, D, _g(f, F_PATH) == OVER_P, (1.0 + float(ac.riseBh)) * BH, float(ac.endUpBh) * BH, int(ac.ticks), int(tr.minTicks), float(tr.bhPerTick) * BH)
	var lu: float = f.rush.lu
	if plan:
		f.rush = keep
	return [n, clampi(roundi(float(n) * (lu + (1.0 - lu) * 0.5)), 2, n - 1)]


## The way in, by path, when the tell is done. The zip, the line and the parting shot fly to striking distance on his own side in
## the travel floor's ticks. An arc flies its loop: the ticks in reach open reachTicks before its top, and the loop flies on
## through them, so its blow lands at the top (or the bottom).
static func _fsGo(S: SimState, f, D) -> void:
	if _g(f, READ) == 0 and _zipRead(S, f, SimPressRead.NO_BEAT) == "tech":
		_s(f, READ, 1)
	var path: int = _g(f, F_PATH)
	var n: int
	if path == OVER_P or path == UNDER_P:
		var pl: Array = _loop(S, f, D, false)
		n = maxi(1, int(pl[1]) - _g(f, RB))
		_s(f, WAYOUT, int(pl[0]) - int(pl[1]))
	else:
		n = _travel(DirBands.dist(f, D) / BH)
		var r := SimState.Rush.new()
		r.tgt = D
		r.off = DirMelee.sideOff(f, D, float(DirData.contact().offset), "own")
		r.end = S.T + float(n) * SimConst.DT
		f.rush = r
	_s(f, WAYIN, n)
	_s(f, PH, 2)
	_s(f, LEN, n)
	_s(f, LEFT, n)


## True while f flies an arc's loop.
static func _looping(f) -> bool:
	return f.rush != null and f.rush.loop != 0


## True while d is in his dodge's protection: a flight strike that reaches him now misses.
static func _dodging(S: SimState, d) -> bool:
	return S.tick - d.act.dodgeTick < SimAct.dodgeWindow


## A dodge made it a miss (playable-build.md section 1): he stops where he is, open for missOpenTicks: his presses wait, and in a
## brawl his guard doesn't hold.
static func _miss(S: SimState, f) -> void:
	var n: int = int(fsCfg().missOpenTicks)
	f.rush = null
	f.vx = 0.0
	f.vy = 0.0
	_s(f, F_OPEN, S.tick + n)
	DirBrawl._s(f, DirBrawl.OPEN_UNTIL, DirBrawl._now(S) + n)
	DirBrawl._s(f, DirBrawl.FREE_AT, S.tick + n)
	SimEvents.feed(S, f.name + " MISSES", "a dodge: he's open for " + str(n) + " ticks")
	_end(S, f, "missed")


## His flight strike's damage: X a medium's worth (blows.x.worth), Y the zip heavy's (blows.y.damage), B a tapped B's (the brawl's
## heavy worth), by the reading's mul, at its worth in the chain.
static func _fsDamage(f) -> float:
	var fc: Dictionary = fsCfg()
	var bc: Dictionary = DirBrawl.cfg()
	var mul: float = float(cfg().mul[["speed", "tech", "held"][_g(f, READ)]]) * float(_g(f, F_WORTH)) / 1000.0
	var btn: int = _g(f, KIND)
	if btn == 1:
		return float(fc.blows.x.worth) * DirBrawl._unit() * mul
	if btn == 2:
		return float(fc.blows.y.damage) * float(bc.damageMul) * mul
	return float(bc.heavy.worth) * DirBrawl._unit() * mul


## The arrival of a flight strike (from _arrive, its exchange begun): the rival's answer, and his blow. Counters (section 1):
##  - Only a heavy (B) timed to land from counter.heavyBefore ticks before the arrival to his blow, or a charged stick strike, stops
##    it. It stops where it has reached: the striker takes the counter's blow at counter.mul and reels counter.reelTicks, never
##    knocked down or sent (onHit), and the brawl goes on.
##  - A light or a medium doesn't stop it: it lands as it would, and his blow still comes. A guard blocks his blow, and the path
##    completes. A perfect block is a reversal. A dodge is a miss (_arrive, _reach).
static func _fsArrive(S: SimState, ex, f, D, dmg: float) -> void:
	var bc: Dictionary = DirBrawl.cfg()
	var fc: Dictionary = fsCfg()
	var rb: int = _g(f, RB)
	var aw: int = _g(D, ANS_W)
	var at: int = _g(D, ANS_AT)
	_s(D, ANS_W, 0)
	var hmark: int = at + int(bc.heavy.windupTicks)
	var stick: bool = DirStick.chargedAt(S, D)
	var thrown: bool = aw == 3 and at >= S.tick - int(fc.counter.get("heavyThrownBefore", 0))   # its wind-up started in the window: it meets him as he arrives
	if stick or thrown or (aw == 3 and hmark >= S.tick - int(fc.counter.heavyBefore) and hmark <= S.tick + rb):
		if stick:
			DirStick.spendCharge(D)
		f.rush = null   # it stops where it's reached
		_s(f, STATE, 3)
		DirBrawl.blowAt(S, ex, D, DirBrawl.MEDIUM, 1 if (stick or thrown) else maxi(1, hmark - S.tick), float(bc.heavy.worth) * DirBrawl._unit() * float(fc.counter.mul), {"counter": "flight", "sure": true})
		SimEvents.feed(S, D.name + " COUNTERS THE FLIGHT STRIKE", "with " + ("a charged stick strike" if stick else ("a B thrown in the window" if thrown else "a B landing in the window")))
		return
	var rd: int = _g(f, READ)
	var x: Dictionary = {"zip": true, "style": READS[rd], "read": rd}
	if _g(f, KIND) == 1:
		x["bk"] = DirBrawl.MEDIUM   # X: a medium's worth and hit-stop, with the quick blow's piece
	if _looping(f):
		x["stepped"] = true   # the loop places him: the brawl's step in doesn't
	DirBrawl.blowAt(S, ex, f, DirBrawl.LIGHT if _g(f, KIND) == 1 else DirBrawl.BIG, rb, dmg, x)
	if aw == 1:
		if S.tick - at <= int(cfg().counter.techBefore):
			DirBrawl._throw(S, D, SimAct.LIGHT, at, false, false)   # it lands as it would (markAnswer makes no counter of it)
	elif aw >= 2:
		var wb: Dictionary = bc.heavy if aw == 3 else bc.medium
		var mark: int = at + int(wb.windupTicks)
		if mark < S.tick - int(fc.counter.heavyBefore):
			DirBrawl._s(D, DirBrawl.FREE_AT, mark + int(wb.recoverWhiff))   # too early: it met nothing, and he's in its recovery
			SimEvents.feed(S, D.name + " TOO EARLY", "his blow met nothing before the flight strike arrived")
		else:
			DirBrawl.blowAt(S, ex, D, DirBrawl.BIG if aw == 3 else DirBrawl.MEDIUM, maxi(1, mark - S.tick), float(wb.worth) * DirBrawl._unit(), {})


## Where a flight strike ends, read on the tick his blow lands (or the tick the exchange ends under him):
##  - the zip: where he started; the line: line.pastBh past him on his other side, at his height; an arc: its loop's end, behind him
##    arc.endUpBh up (the loop flies on if it's still flying); the parting shot: parting.addBh further than he started, at least
##    parting.minBh from him and never over maxBh, on the bearing he came in on.
##  - The way out's ticks: the loop's own; the line's the travel floor; the zip's and the parting shot's the zip's table (out), never
##    under the travel floor.
static func _fsExit(S: SimState, f, o) -> void:
	var c: Dictionary = cfg()
	var fc: Dictionary = fsCfg()
	var path: int = _g(f, F_PATH)
	var side: float = float(_g(f, SIDE))
	var x0: float = float(_g(f, X0)) / FX
	var y0: float = float(_g(f, Y0)) / FX
	var kind: int = 1
	var ex: float = x0
	var ey: float = y0
	var pass_: int = 0
	if path == LINE_P:
		kind = 2
		ex = SimWrap.wrap(o.x - side * float(fc.line.pastBh) * BH)
		ey = o.y
	elif path == OVER_P or path == UNDER_P:
		kind = 2
		var lr: float = maxf(1.0, (1.0 + float(fc.arc.riseBh) - float(fc.arc.endUpBh)) * BH)
		ex = SimWrap.wrap(o.x - side * lr)
		ey = o.y + float(fc.arc.endUpBh) * BH
		pass_ = 1 if path == OVER_P else 3
	elif path == PART_P:
		kind = 3
		var pc: Dictionary = fc.parting
		var dist: float = clampf(float(_g(f, D0)) / FX + float(pc.addBh) * BH, float(pc.minBh) * BH, float(pc.maxBh) * BH)
		var bx: float = SimWrap.sdx(o.x, x0)
		var by: float = y0 - o.y
		var bl: float = SimDetMath.hypot(bx, by)
		if bl < 1.0:
			bx = side
			by = 0.0
			bl = 1.0
		ex = SimWrap.wrap(o.x + bx / bl * dist)
		ey = o.y + by / bl * dist
	ey = maxf(ey, SimFighter.floorFor(S, f, ex, 0.0))
	_s(f, EXIT, kind)
	_s(f, EX_X, roundi(ex * FX))
	_s(f, EX_Y, roundi(ey * FX))
	var path_: float = SimDetMath.hypot(SimWrap.sdx(f.x, ex), ey - f.y) / BH
	var n: int
	if _looping(f):
		n = maxi(1, roundi((f.rush.end - S.T) / SimConst.DT - 0.5))
	elif path == LINE_P:
		n = _travel(path_)
	else:
		n = _g(f, WAYOUT)
		if path_ > float(c.out.freeBh):
			n += int(ceil((path_ - float(c.out.freeBh)) / float(c.out.bhPerTick)))
		n = maxi(mini(n, int(c.out.maxTicks)), _travel(path_))
	_s(f, WAYOUT, n)
	_s(f, PASS, pass_)
	var e = _cue(S, f, "zip_out", EXITS[kind])
	e.target = float(S.fighters.find(o))
	e.x = ex
	e.y = ey
	e.n = n
	e.amount = float(_g(f, RB))
	e.dur = float(_g(f, RA))
	e.k = float(_g(f, READ))


## The exit, by the switch: the path's (flight strikes), else the stick's.
static func _exitFor(S: SimState, f, o) -> void:
	if fsOn():
		_fsExit(S, f, o)
	else:
		_pickExit(S, f, o)


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
			if fsOn() and _g(f, F_OPEN) > 0 and S.tick >= _g(f, F_OPEN):
				_openEnd(S, f)
			continue
		if not fsOn():
			_ringPush(f)
		if ph == 1:
			_tell(S, f)
		elif ph == 2:
			_wayIn(S, f)
		elif ph == 3:
			_reach(S, f)
		else:
			_wayOut(S, f)


## The stick, once a live tick, into the exit's ring (SimAim: the direction held for 3 of the last 12 ticks wins).
static func _ringPush(f) -> void:
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
	var heavy: bool = _g(f, KIND) >= 2
	var k: Dictionary = c.heavy if heavy else c.strike
	var down: bool = f.input.heavyHeld if heavy else f.input.lightHeld
	var fs: bool = fsOn()
	var left: int = _g(f, LEFT) - 1
	if _g(f, HOLD) == 1 and not down:
		left = 0   # let go inside the extra ticks: he goes now, in the speed reading
		_s(f, HOLD, 0)
		_s(f, TELL, _g(f, LEN) - _g(f, LEFT) + 1)
		_s(f, LEN, _g(f, TELL))
	elif left <= 0 and _g(f, HOLD) == 0 and down and _g(f, READ) == 0 and not fs:   # (a flight strike has no held reading: B in one is never a send)
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
	if fs:
		_fsGo(S, f, D)
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
		if _looping(f):
			return   # an arc's loop follows him itself
		var lead: float = D.vx * SimConst.DT if (S.fighters[0] == f and D.rush == null and D.state == "free") else 0.0
		var side: float = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(D.x, f.x)), SimMathx.jsign(f.rush.off))
		f.rush.off = side * maxf(float(DirData.contact().offset), float(DirData.contact().get("minSeparation", 45.0))) + lead
		return
	_arrive(S, f, D)


## He is at the rival: the ticks in reach begin. They run on the brawl's lines with no brawl announced. An answer the
## rival pressed before now is resolved against the arrival, which is the counter's mark.
static func _arrive(S: SimState, f, D) -> void:
	var c: Dictionary = cfg()
	var heavy: bool = _g(f, KIND) >= 2
	var fs: bool = fsOn()
	var loop: bool = fs and _looping(f)
	if not loop:
		f.rush = null
	if (D.state != "free" and D.state != "charging") or D.hidden or untouchable(D) or (not loop and DirBands.dist(f, D) > float(DirBands.data().closeBh) * BH * 1.5):
		_end(S, f, "outrun")
		return
	if fs and _dodging(S, D):
		_miss(S, f)   # he dodged it: a miss
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
	var dmg: float = (float(c.heavy.damage) if heavy else float(bc.light.damage) * float(bc.skillMul)) * float(bc.damageMul) * mul   # the zip heavy keeps the worth it was built at, on its own key
	if fs:
		_fsArrive(S, ex, f, D, _fsDamage(f))
		SimFx.attack(S, f, D, "heavy" if heavy else "light", DirExchange.STN[int(D.stance)], ex.tag, false)
		SimEvents.feed(S, f.name + " FLIGHT STRIKE ARRIVES", PATHS[_g(f, F_PATH)] + "; his blow lands in " + str(_g(f, RB)) + " ticks")
		return
	var rb: int = _g(f, RB)
	# The rival's answer, pressed where he stood before the arrival. A heavy that lands inside its window cancels the
	# zip's blow: it lands in full and knocks him back.
	var aw: int = _g(D, ANS_W)
	var at: int = _g(D, ANS_AT)
	_s(D, ANS_W, 0)
	# A slow blow counters by when it lands, and not by when it is pressed (brawl-second-pass.md section 9): a medium
	# whose wind-up ends in the tech window is the tech counter, and a heavy whose wind-up ends in the heavy window
	# is the heavy counter.
	var wb: Dictionary = bc.heavy if aw == 3 else bc.medium
	var akind: int = DirBrawl.BIG if aw == 3 else DirBrawl.MEDIUM
	var hdmg: float = float(wb.worth) * DirBrawl._unit()
	var mark: int = at + int(wb.windupTicks)   # it lands as its wind-up ends
	var land: int = mark
	var cancelled: bool = aw >= 2 and mark >= S.tick - int(c.counter.heavyBefore if aw == 3 else c.counter.techBefore) and mark <= S.tick + rb
	if cancelled and aw == 3:
		DirBrawl.blowAt(S, ex, D, DirBrawl.BIG, maxi(1, land - S.tick), hdmg, {"counter": "heavy", "sure": true, "charged": true})
	elif cancelled:
		DirBrawl.blowAt(S, ex, D, DirBrawl.MEDIUM, maxi(1, land - S.tick), hdmg * float(c.counter.mul), {"counter": "tech", "sure": true})
	else:
		DirBrawl.blowAt(S, ex, f, DirBrawl.BIG if heavy else DirBrawl.LIGHT, rb, dmg, {"zip": true, "style": READS[rd], "read": rd})
		if aw == 1 and S.tick - at <= int(c.counter.techBefore):
			_s(D, ANS_LAST, at - 1 if _g(D, ANS_MASH) == 1 else 0)   # (markAnswer reads a press soon after another as a mash)
			DirBrawl._throw(S, D, SimAct.LIGHT, at, false, false)   # inside the window: markAnswer makes it the tech counter
		elif aw >= 2 and mark > S.tick + rb:
			DirBrawl.blowAt(S, ex, D, akind, land - S.tick, hdmg, {})   # too late to counter: it lands after his blow, and catches him if he is still there
		elif aw >= 2:
			# Too early: it met nothing, and he is in its recovery as the zip lands.
			DirBrawl._s(D, DirBrawl.FREE_AT, land + int(wb.recoverWhiff))
			SimEvents.feed(S, D.name + " TOO EARLY", "his blow met nothing before the zip arrived")
	SimFx.attack(S, f, D, "heavy" if heavy else "light", DirExchange.STN[int(D.stance)], ex.tag, false)
	SimEvents.feed(S, f.name + " ZIP ARRIVES", "in reach; his blow lands in " + str(rb) + " ticks" + (" (cancelled by the answer)" if cancelled else ""))


## The rival's blow, pressed in the ticks in reach (DirBrawl._throw): a single light pressed from counter.techBefore
## ticks before the arrival until the zipper's blow lands is the tech counter. It is worth a skill strike times
## counter.mul. A flurry blow or a heavy pressed there is not a counter: landing on him, it catches him.
static func markAnswer(S: SimState, ex, f, kind: int, p: int, args: Dictionary) -> void:
	if fsOn():
		# Against a flight strike a light or a medium lands as it would. A B thrown in the ticks in reach before his blow is the counter
		# (playable-build.md section 1, re-ruled 2026-11-07): his blow is cancelled, it meets him at once, and he reels (onHit).
		var zz = ex.A
		if kind == DirBrawl.BIG and _g(zz, STATE) == 0 and DirBrawl._g(zz, DirBrawl.LINE) == 1:
			DirBrawl._drop(S, ex, zz)
			_s(zz, STATE, 3)
			zz.rush = null   # it stops where it's reached
			args["counter"] = "flight"
			args["sure"] = true
			args["bk"] = DirBrawl.MEDIUM   # it reels him and sends nothing (onHit), with no stagger after it
			args["dmg"] = float(DirBrawl.cfg().heavy.worth) * DirBrawl._unit() * float(fsCfg().counter.mul)
			args["lead"] = 1   # (DirBrawl._throw reads it: it lands on the next live tick)
		return
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
	var fs: bool = fsOn()
	if not _mine(S, f):
		if fs and _g(f, STATE) == 0 and _dodging(S, DirBrawl.rivalOf(S, f)):
			_miss(S, f)   # the rival dodged out of his ticks in reach before his blow: a miss
			return
		if S.game.ko == null and S.dirS.ex == null and f.state == "free" and f.stunTicks <= 0:
			if _g(f, EXIT) == 0:
				_exitFor(S, f, SimRoster.opp(S, f))
			_leave(S, f)
		else:
			_end(S, f, "stopped")
		return
	if fs and _g(f, STATE) == 0 and f.stunTicks > 0:
		_caught(S, DirBrawl.exOf(S), f, "caught")   # a blow staggered him before his own landed
		return
	if _g(f, STATE) != 1:
		return
	var left: int = _g(f, LEFT) - 1
	_s(f, LEFT, left)
	var o = S.dirS.ex.D
	if left <= 0 and DirBrawl._g(o, DirBrawl.LINE) == 1 and DirBrawl._g(o, DirBrawl.CONTACT) <= DirBrawl._now(S) + 1:
		return   # a blow of the rival's lands on this last tick: it lands first
	if left <= 0:
		var loop = f.rush if (fs and _looping(f)) else null
		DirBrawl.end(S, S.dirS.ex, "zip")
		if loop != null:
			f.rush = loop   # (the exchange's end drops its attacker's move: an arc's loop flies on)
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
	var heavy: bool = _g(f, KIND) >= 2
	var rd: int = _g(f, READ)
	_exitFor(S, f, o)
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
	if _g(f, KIND) == BIGK:
		# B in a flight strike: a tapped B's stagger, by the one rule for B. Never a send.
		var nb: int = int(bc.heavy.staggerTicks)
		o.stunTicks = maxi(o.stunTicks, nb)
		DirBrawl._drop(S, ex, o)
		var sb = _cue(S, o, "stagger", "zip")
		sb.target = float(S.fighters.find(f))
		sb.n = nb
		return
	if rd == 2:
		# The held zip heavy: a knock-back. The exchange ends with it, and he leaves from where he stands.
		DirMelee.launchBeat(S, ex, f, o, float(bc.heavy.force), false, {"share": "chase"})
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
	if counter == "flight":
		DirBrawl._reel(S, z, int(fsCfg().counter.reelTicks))   # the flight strike's counter: he reels, never down or sent
		_caught(S, ex, z, "countered")
		return
	if fsOn() and counter == "":
		return   # a light or a medium doesn't stop a flight strike: it lands as it would, and his own blow still comes
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
		DirBrawl.opening(S, ex, by, z, n, "counter")   # a tech counter is an opening: his B in this stagger always lands
		return
	_caught(S, ex, z, "countered")


## He is caught or countered: the zip is over where he stands, and the brawl is announced with the rival as its starter.
static func _caught(S: SimState, ex, z, why: String, brawl: bool = true) -> void:
	if _g(z, STATE) == 2:
		return
	_s(z, STATE, 2)
	_s(z, PH, 0)
	if fsOn():
		z.rush = null   # an arc's loop stops where he's caught
		_s(z, F_END, 0)
		_s(z, F_NEXT, 0)
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
			var rad: float = float(b) * SimMathx.PI / 180.0
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
		ey = maxf(ey, SimFighter.floorFor(S, f, ex, 0.0))   # where he started may have been filled in since: he ends on it
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
	if fsOn() and _looping(f):
		# An arc: the rest of its loop is the way out, to its end behind him.
		var m: int = _g(f, WAYOUT)
		f.state = "free"
		f.vx = 0.0
		f.vy = 0.0
		_s(f, PH, 4)
		_s(f, LEN, m)
		_s(f, LEFT, m)
		SimFx.rush(S, f, DirBrawl.rivalOf(S, f), S.tick + m)
		return
	var c: Dictionary = cfg()
	var ex: float = float(_g(f, EX_X)) / FX
	var ey: float = float(_g(f, EX_Y)) / FX
	var n: int = _g(f, WAYOUT)
	var r := SimState.Rush.new()
	r.px = ex
	r.py = DirWater.rushTop(S, f, ey, float(n), f.z)   # under a lake's floor: no faster than the floor brings him (floorlift_check)
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
		if fsOn() and _g(f, F_NEXT) != 0:
			_chain(S, f)   # a press kept in its last ticks: the next link


## The zip is over, and why: done, stopped, outrun, shot, down. (caught and countered are _caught's.)
static func _end(S: SimState, f, why: String) -> void:
	var ph: int = _g(f, PH)
	_s(f, PH, 0)
	_s(f, HOLD, 0)
	if fsOn():
		_s(f, F_END, S.tick if why == "done" else 0)   # a chain's after-window counts from a path completed
		if why != "done":
			_s(f, F_NEXT, 0)
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
	if _g(f, KIND) >= 2 and sh.power <= float(DirBlast.data().charge.shrugPower):
		return "shrug"
	_end(S, f, "shot")
	return "stop"


# ---------------------------------------------------------------- the read

## The truth for the body (docs/animation/zip.md sections 9 and 12): empty when f is not zipping.
static func read(S: SimState, f) -> Dictionary:
	var ph: int = _g(f, PH)
	if ph == 0:
		return {}
	var heavy: bool = _g(f, KIND) >= 2
	var inReach: bool = ph == 3
	var n: int = _g(f, LEN) - _g(f, LEFT)
	var blow: int = 0
	if inReach:
		# In reach the phase is the ticks before his blow and the ticks after it: n counts across both.
		n = DirBrawl._now(S) - _g(f, ARR_L) if _g(f, STATE) == 0 else _g(f, RB) + (_g(f, RA) - _g(f, LEFT))
		blow = 0 if _g(f, STATE) == 0 else 1
	var ek: int = _g(f, EXIT)
	var r: Dictionary = {
		"reading": READS[_g(f, READ)], "btn": "y" if heavy else "x",
		"phase": PHASES[ph], "n": n, "len": _g(f, LEN),
		"tell": _g(f, TELL), "in": _g(f, WAYIN), "hits": 1, "hd": _g(f, RB) + _g(f, RA), "out": _g(f, WAYOUT), "lift": 0,
		"blow": blow,
		"via": "" if ek == 0 else ("back" if ek == 1 else "run"), "pass": PASSES[_g(f, PASS)], "entry_in": "", "entry_out": "",
		"dist_bh": float(_g(f, D0)) / FX / BH,
		"exit": EXITS[ek], "x": float(_g(f, EX_X)) / FX, "y": float(_g(f, EX_Y)) / FX,
	}
	if fsOn():
		r["path"] = PATHS[_g(f, F_PATH)]
		r["btn"] = BTNS[_g(f, KIND)]
		r["link"] = _g(f, F_LINK)
		r["loop"] = _looping(f)
	return r


# ---------------------------------------------------------------- the AI

## An AI attack beat in the mid band (DirAI.aiInput): it zips at its level's zipShare when it has the ki to spare and the
## rival is not pressing, with
## the heavy at zipHeavyShare. It writes the press a player makes: LT held with X or Y. Its exit is back, or at
## zipExit another: the far side, above, or away.
static func aiUse(S: SimState, f, o, i: SimIntent) -> bool:
	if not on() or i.mode != 0 or zipping(f) or zipping(o) or S.dirS.ex != null:
		return false
	if fsOn():
		return _aiFly(S, f, o, i, -1, "fs.ai.mid", S.tick * 2 + S.fighters.find(f))   # a flight strike: a rival who's pressing doesn't stop it
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


## The computer's flight strike path: one keyed draw over flightStrikes.ai.paths (zip, line, over, under, parting), among `among`
## when it's given (a moment that asks for some paths: round a guard, the line or an arc).
static func _aiPath(S: SimState, key: String, n: int, among: Array = []) -> int:
	var w0: Array = fsCfg().get("ai", {}).get("paths", [1, 1, 1, 1, 1])
	var w: Array = []
	for k in range(w0.size()):
		w.append(float(w0[k]) if (among.is_empty() or among.has(k)) else 0.0)
	var tot: float = 0.0
	for v in w:
		tot += float(v)
	var u: float = SimRng.keyed(int(S.game.seed), key + ".path", n) * tot
	for i in range(w.size()):
		u -= float(w[i])
		if u < 0.0:
			return i
	return w.size() - 1



## The computer's share of flight strikes at its level: ai.json flightShare (the zip's zipShare is the zip's own, with the switch off).
static func _flightShare() -> float:
	var lv: Dictionary = DirAI.lv()
	return float(lv.get("flightShare", lv.get("zipShare", 0.0)))


## The computer's flight strike (flightStrikes.ai; playable-build.md section 1, the computer's own): one keyed draw at its level's
## flightShare, its button by ai.buttons (a dearer one it can't pay for gives way to a cheaper one) and its path by ai.paths, among
## `among` when the moment asks for some. Never a press it can't pay for with ai.kiReserve kept back (link: the chain's next link). It
## writes the press a player makes: LT held with X, Y or B. True when it pressed.
static func _aiFly(S: SimState, f, o, i: SimIntent, path: int, key: String, n: int, among: Array = [], link: int = -1) -> bool:
	if link < 0:
		link = _nextLink(S, f)   # priced as the press will be
	var fc: Dictionary = fsCfg()
	var ai: Dictionary = fc.get("ai", {})
	var d: float = DirBands.dist(f, o) / BH
	var seed: int = int(S.game.seed)
	if d > float(fc.rangeBh[1]) or SimRng.keyed(seed, key, n) >= _flightShare():
		return false
	var bt: Dictionary = ai.get("buttons", {"x": 1.0, "y": 0.0, "b": 0.0})
	var bx: float = float(bt.get("x", 0.0))
	var by: float = float(bt.get("y", 0.0))
	var u: float = SimRng.keyed(seed, key + ".btn", n) * (bx + by + float(bt.get("b", 0.0)))
	var btn: int = 1 if u < bx else (2 if u < bx + by else BIGK)
	var reserve: float = float(ai.get("kiReserve", 0.0))
	while btn > 1 and f.ki < _price(btn, d, link) + reserve:
		btn -= 1
	if f.ki < _price(btn, d, link) + reserve:
		return false   # never a press it can't pay for
	i.light = btn == 1
	i.heavy = btn == 2
	i.sig = btn == BIGK
	i.lightHeld = false
	i.heavyHeld = false
	i.sigHeld = false
	i.stanceMask |= LT
	_s(f, AI_EXIT, 1 + (path if path >= 0 else _aiPath(S, key, n, among)))
	return true


## The link a press now would be: the next one within chain.afterTicks of a completed flight strike, else 0 (a fresh strike).
static func _nextLink(S: SimState, f) -> int:
	var e: int = _g(f, F_END)
	return (_g(f, F_LINK) + 1) if (e > 0 and S.tick - e <= int(fsCfg().chain.afterTicks)) else 0


## The computer in a brawl, about to press a blow (DirBrawl._aiPress): a flight strike in its place when it's losing the run (any path) or
## the rival has guarded for ai.brawlGuardSec (the line or an arc gets round a guard), at its share. Its line must be free.
static func aiBrawl(S: SimState, f, i: SimIntent, st: int) -> bool:
	if not fsOn() or f.ai == null or (st & 4) != 0:
		return false
	var ex = DirBrawl.exOf(S)
	if not DirBrawl.isBrawl(ex) or ex.branch != "" or DirBrawl.quiet(ex) or not DirBrawl._free(S, f):
		return false
	var o = DirBrawl.rivalOf(S, f)
	var guardT: int = int(float(fsCfg().get("ai", {}).get("brawlGuardSec", 1.0)) * DirData.TICKS_PER_SEC)
	var guarded: bool = o.act.guardSince >= 0 and S.tick - o.act.guardSince >= guardT if o.act.v2 else (o.stance == 1.0 and DirInterrupt.gi(o, DirInterrupt.GUARDED) >= 2)
	var losing: bool = DirBrawl._g(o, DirBrawl.RUN) > DirBrawl._g(f, DirBrawl.RUN)
	if not guarded and not losing:
		return false
	return _aiFly(S, f, o, i, -1, "fs.ai.brawl", S.tick * 2 + S.fighters.find(f), [LINE_P, OVER_P, UNDER_P] if guarded else [])


## The computer wants out of a brawl (DirBrawl._aiPart): the parting shot in place of the walk, at its share. One draw a decision.
static func aiOut(S: SimState, f, i: SimIntent, decision: int) -> bool:
	if not fsOn() or f.ai == null:
		return false
	var ex = DirBrawl.exOf(S)
	if not DirBrawl.isBrawl(ex) or ex.branch != "" or not DirBrawl._free(S, f):
		return false
	return _aiFly(S, f, DirBrawl.rivalOf(S, f), i, PART_P, "fs.ai.out", decision * 2 + S.fighters.find(f))


## A miss's opening has ended: his latest press in it is thrown now, if it was pressed within the brawl's heldPressTicks.
static func _openEnd(S: SimState, f) -> void:
	var k: int = _g(f, F_NEXT)
	var at: int = _g(f, F_NEXT_AT)
	_s(f, F_OPEN, 0)
	_s(f, F_NEXT, 0)
	if k > 0 and S.tick - at <= int(DirBrawl.cfg().heldPressTicks):
		DirExchange.requestAttack(S, f, ["light", "heavy", "sig"][k - 1])


## The AI's own zip, each tick: it keeps LT down and holds the stick for its exit.
static func aiZipping(S: SimState, f, i: SimIntent) -> void:
	var o = SimRoster.opp(S, f)
	var toward: float = SimMathx.jsign(SimWrap.sdx(f.x, o.x))
	i.stanceMask |= LT
	i.mx = 0.0
	i.my = 0.0
	if fsOn():
		# A chain link, in its last ticks: only when it can pay the next link in full and keep ai.kiReserve back. One draw a strike.
		if _g(f, F_NEXT) == 0 and _g(f, PH) >= 3 and _left(f) <= int(fsCfg().chain.lateTicks):
			_aiFly(S, f, DirBrawl.rivalOf(S, f), i, -1, "fs.ai.chain", _g(f, PRESS) * 2 + S.fighters.find(f), [], _g(f, F_LINK) + 1)
		return   # a flight strike's path was read at its press
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
	if u < zc and fsOn():
		# Against a flight strike the counter is a B thrown in the window (from counter.heavyThrownBefore before its arrival until his
		# blow): when its reaction reaches the window it throws one there; when it can't, it guards.
		var ta: int = maxi(rt, n - int(fsCfg().counter.get("heavyThrownBefore", 0)))
		if ta <= n + rb - 1 and D.ki >= float(DirBrawl.cfg().heavy.ki):
			_s(D, AI_ANS, 5)
			_s(D, AI_AT, S.tick + ta)
		else:
			_s(D, AI_ANS, 1)
			_s(D, AI_AT, S.tick + rt)
	elif u < zc:
		var mark: int = rt + int(DirBrawl.cfg().medium.windupTicks)
		if _g(Z, KIND) == 2 and mark >= n - int(c.counter.techBefore) and mark <= n + rb and D.ki >= float(DirBrawl.cfg().medium.ki):
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
	if a == 5 and S.tick >= _g(f, AI_AT) and _g(z, STATE) == 0:
		_s(f, AI_ANS, 9)
		i.sig = true   # B thrown in reach before his blow: the flight strike's counter (markAnswer)
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
