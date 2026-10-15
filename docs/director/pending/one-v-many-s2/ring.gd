class_name DirRing
## One versus many, stage 2: the one's partner and the ring (docs/director/one-v-many.md section 5;
## docs/director/pending/one-v-many-s2/DESIGN.md). Slot 0 is the one, and every other slot is one of the many, as
## Simulation's stage 1 places them. The one brawls with one partner at a time; the rest wait in a ring round him and
## never ask for an exchange. With two bodies none of this runs: nothing is read, written, sized or drawn, so every 1v1
## match is the same to the bit.

const BASE: int = DirZip.END
const ROLE: int = BASE + 0        # 0 none (two bodies), 1 the one, 2 the partner, 3 in the ring
const ROLE_AT: int = BASE + 1     # the live tick the role began
const PARTNER: int = BASE + 2     # on the one: his partner's slot plus 1 (0 none yet: slot 1)
const TAG_AT: int = BASE + 3      # on the one: the live tick of the last tag (0 none)
const THREAT_AT: int = BASE + 4   # on a ring guard: the live tick his last threat began
const SIDE: int = BASE + 5        # on a ring guard: the side of the one he keeps, 1 or 2 (-1 and +1 in x); 0 not chosen
const STEP_IN: int = BASE + 6     # on a ring guard: 1 while a threat steps him in to the band's inner edge
const REFUSED: int = BASE + 7     # on anyone: presses the ring refused (a count, for the probe)
const TAGS: int = BASE + 8        # on the one: tags so far (a count, for the probe)
const END: int = BASE + 9

const NONE := 0
const ONE := 1
const PART := 2
const RING := 3


static func cfg() -> Dictionary:
	return DirBrawl.cfg().get("ring", {})


## True with more than two bodies and the ring's data switched on.
static func on(S: SimState) -> bool:
	return S.fighters.size() > 2 and bool(cfg().get("enabled", false))


static func _g(f, k: int) -> int:
	return f.act.dirI[k] if k < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirBrawl._size(f)
	if f.act.dirI.size() < END:
		f.act.dirI.resize(END)
	f.act.dirI[k] = v


static func _slot(S: SimState, f) -> int:
	return S.fighters.find(f)


## The fighter f fights now. With two bodies, or the ring off, it is SimRoster.opp, exactly as before. With the ring
## on: the one's partner for the one, and the one for every one of the many.
static func partner(S: SimState, f):
	if not on(S):
		return SimRoster.opp(S, f)
	var one = S.fighters[0]
	if f != one:
		return one
	var p: int = _g(one, PARTNER) - 1
	return S.fighters[p] if p >= 1 and p < S.fighters.size() else S.fighters[1]


## f's role this tick.
static func role(S: SimState, f) -> int:
	if not on(S):
		return NONE
	if f == S.fighters[0]:
		return ONE
	return PART if f == partner(S, S.fighters[0]) else RING


## True when f is one of the many and not the one's partner: he waits in the ring.
static func inRing(S: SimState, f) -> bool:
	return on(S) and role(S, f) == RING


# ---------------------------------------------------------------- the press

## Every press, before the exchange is asked (DirExchange.requestAttack). A ring guard's press is refused and counted;
## the one's press first picks whom it is at (pick). Returns false when the press goes no further.
static func mayPress(S: SimState, f, kind: String) -> bool:
	if inRing(S, f):
		_s(f, REFUSED, _g(f, REFUSED) + 1)
		var e = DirBrawl._ev(S, f, "press_ack", "ring", "b")
		e.target = float(_slot(S, S.fighters[0]))
		return false
	if f == S.fighters[0]:
		pick(S, f)
	return true


## The one's press picks a guard: the one his stick points at within 45 degrees and within striking distance (a tag,
## if the tag's spacing allows and no exchange is running); else his partner. The press then goes to the partner.
static func pick(S: SimState, one) -> void:
	if not _quiet(S, one):
		return   # inside an exchange the stick is the brawl's own (its nudge); a pick waits for the exchange's end
	var mx: float = one.input.mx
	var my: float = one.input.my
	var ul: float = SimDetMath.hypot(mx, my)
	if ul <= SimAct.awayDead:
		return
	var reach: float = float(DirData.contact().offset) + float(cfg().get("pickBh", 1.5)) * DirInterrupt.BH
	var cosMin: float = cos(deg_to_rad(float(cfg().get("pickDeg", 45.0))))
	var best = null
	var bestD: float = INF
	for k in range(1, S.fighters.size()):
		var g = S.fighters[k]
		if g == partner(S, one) or g.state != "free":
			continue
		var dx: float = SimWrap.sdx(one.x, g.x)
		var dy: float = g.y - one.y
		var d: float = SimDetMath.hypot(dx, dy)
		if d <= 0.001 or d > reach:
			continue
		if (mx * dx + my * dy) / (ul * d) < cosMin:
			continue
		if d < bestD:
			bestD = d
			best = g
	if best != null:
		tag(S, best, "pick")


# ---------------------------------------------------------------- the tag

## Makes g the one's partner, if the tag's spacing allows. why: pick, sent, slice.
static func tag(S: SimState, g, why: String) -> bool:
	var one = S.fighters[0]
	var now: int = DirBrawl._now(S)
	var last: int = _g(one, TAG_AT)
	if last > 0 and now - last < int(cfg().get("tagMinTicks", 30)):
		return false
	var old = partner(S, one)
	if g == old or g == one:
		return false
	_s(one, PARTNER, _slot(S, g) + 1)
	_s(one, TAG_AT, now)
	_s(one, TAGS, _g(one, TAGS) + 1)
	_s(g, ROLE, PART)
	_s(g, ROLE_AT, now)
	_s(old, ROLE, RING)
	_s(old, ROLE_AT, now)
	_s(old, SIDE, 0)
	_s(old, STEP_IN, 0)
	_s(old, THREAT_AT, now)
	var e = DirBrawl._ev(S, g, "ring_tag", why, "")
	e.target = float(_slot(S, old))
	SimEvents.feed(S, "TAG", g.name + " steps in for " + old.name + " (" + why + ")")
	return true


## Once a tick (DirExchange.dirUpdate): the roles' start, and the tags the fight makes by itself. A partner who is sent
## (launched, knocked back, slammed) hands over to the nearest ring guard; so does one who has held the one for the
## slice with no exchange running at the end of it.
static func tick(S: SimState) -> void:
	if not on(S):
		return
	var one = S.fighters[0]
	var now: int = DirBrawl._now(S)
	if _g(one, ROLE) != ONE:
		_s(one, ROLE, ONE)
		_s(one, ROLE_AT, now)
		_s(one, PARTNER, 2)
		for k in range(1, S.fighters.size()):
			var f = S.fighters[k]
			_s(f, ROLE, PART if k == 1 else RING)
			_s(f, ROLE_AT, now)
			_s(f, THREAT_AT, now)
	# A tag waits for a quiet moment: no exchange running, and the one free on his feet (not sent, not in the air from a
	# launch). So no blow, landing or exchange of the outgoing partner's outlives his handover.
	if not _quiet(S, one):
		return
	var p = partner(S, one)
	var next = _nearestRing(S, one)
	if next == null:
		return
	if DirBrawl._g(p, DirBrawl.SENT) != 0:
		tag(S, next, "sent")
	elif S.dirS.ex == null and now - _g(p, ROLE_AT) >= int(round(float(cfg().get("sliceS", 6.0)) * DirData.TICKS_PER_SEC)):
		tag(S, next, "slice")


## True when a tag may happen: no exchange running and none on its way (an approach), the one free and not sent, and
## no shot of the partner's in flight. So nothing the outgoing partner started lands after he has gone to the ring.
static func _quiet(S: SimState, one) -> bool:
	if S.dirS.ex != null or DirBands.who(S) >= 0 or one.state != "free" or DirBrawl._g(one, DirBrawl.SENT) != 0:
		return false
	var pf = partner(S, one)
	if DirInterrupt.gi(pf, DirInterrupt.BLAST_REQ) != 0:
		return false   # a blast of his winding up: it would leave from the ring
	var p: int = _slot(S, pf)
	for sh in S.shots:
		if int(sh.owner) == p:
			return false
	return true


## The ring guard nearest the one, free and on his feet; null when there is none.
static func _nearestRing(S: SimState, one):
	var best = null
	var bestD: float = INF
	for k in range(1, S.fighters.size()):
		var g = S.fighters[k]
		if g == partner(S, one) or g.state != "free" or DirBrawl._g(g, DirBrawl.SENT) != 0:
			continue
		var d: float = DirBands.dist(one, g)
		if d < bestD:
			bestD = d
			best = g
	return best


# ---------------------------------------------------------------- the ring's AI

## A ring guard's stick, in place of the AI's own (DirAI.aiInput): he never presses. He keeps the band ringBh round the
## one on his side (on the plane, the side with fewer of the many when he joins the ring), level with him, and every
## threatEveryS he steps in to the band's inner edge and out again (a threat), so nobody in the ring stands idle.
static func aiInput(S: SimState, f) -> void:
	var i: SimIntent = f.input
	var one = S.fighters[0]
	var now: int = DirBrawl._now(S)
	var c: Dictionary = cfg()
	var band: Array = c.get("ringBh", [4.5, 6.5])
	var lo: float = float(band[0]) * DirInterrupt.BH
	var hi: float = float(band[1]) * DirInterrupt.BH
	if _g(f, SIDE) == 0:
		var left := 0
		var right := 0
		for k in range(1, S.fighters.size()):
			var g = S.fighters[k]
			if g == f:
				continue
			if SimWrap.sdx(one.x, g.x) < 0.0:
				left += 1
			else:
				right += 1
		_s(f, SIDE, 1 if left < right else (2 if right < left else (1 if SimWrap.sdx(one.x, f.x) < 0.0 else 2)))
	var side: float = -1.0 if _g(f, SIDE) == 1 else 1.0
	if _g(f, STEP_IN) == 0 and now - _g(f, THREAT_AT) >= int(round(float(c.get("threatEveryS", 3.0)) * DirData.TICKS_PER_SEC)):
		_s(f, STEP_IN, 1)
		_s(f, THREAT_AT, now)
		var e = DirBrawl._ev(S, f, "ring_threat", "step", "")
		e.target = float(_slot(S, one))
	# His place: the band's middle, and a body height further out for each ring guard on his side with a lower slot, so
	# two on one side don't want the same spot.
	var rank := 0
	for k in range(1, _slot(S, f)):
		var g = S.fighters[k]
		if inRing(S, g) and _g(g, SIDE) == _g(f, SIDE):
			rank += 1
	var want: float = lo if _g(f, STEP_IN) == 1 else minf(hi, (lo + hi) * 0.5 + float(rank) * DirInterrupt.BH)
	var tx: float = SimWrap.wrap(one.x + side * want)
	var dx: float = SimWrap.sdx(f.x, tx)
	if _g(f, STEP_IN) == 1 and (absf(SimWrap.sdx(one.x, f.x)) <= lo + 0.25 * DirInterrupt.BH or now - _g(f, THREAT_AT) >= int(c.get("stepInTicks", 45))):
		_s(f, STEP_IN, 0)   # in at the edge, or out of time: back out to his place in the band
	var dead: float = 0.25 * DirInterrupt.BH
	i.mx = 0.0 if absf(dx) <= dead else SimMathx.jsign(dx)
	var dy: float = one.y - f.y
	i.my = 0.0 if absf(dy) <= dead else SimMathx.jsign(dy) * minf(1.0, absf(dy) / DirInterrupt.BH)
	i.light = false
	i.heavy = false
	i.sig = false
	i.lightHeld = false
	i.heavyHeld = false
	i.sigHeld = false
