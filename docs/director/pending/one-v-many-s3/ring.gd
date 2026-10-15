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
# Stage 3: the interjection, on the one (one in flight at most), and a new partner's step in.
const GRANT: int = BASE + 9       # on the one: the slot plus 1 of the guard granted an interjection, while it is in flight
const GRANT_AT: int = BASE + 10   # on the one: the live tick of the last grant (0 none)
const GRANT_PH: int = BASE + 11   # on the one: 1 the granted guard moves in, 2 his blow winds up
const GRANT_CT: int = BASE + 12   # on the one: the live tick the granted blow lands
const GRANTS: int = BASE + 13     # on the one: grants so far (a count)
const PULLS: int = BASE + 14      # on the one: grants pulled before they landed (a count)
const STEP_TAG: int = BASE + 15   # on a guard: the live tick a tag made him the partner, while he steps in (0 none)
const HOLD_UNTIL: int = BASE + 16 # on the one: the live tick until which his partner's line waits for an interjection
const END: int = BASE + 17

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
	# Game Design (empress-guards.md section 5): the one's run is carried across a tag; the new partner's is fresh. A
	# guard steps in to striking distance (a principal walks in by his own stick).
	DirBrawl._s(g, DirBrawl.RUN, 0)
	_s(g, STEP_TAG, now if isGuard(S, g) else 0)
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
	_stepTag(S, one, now)
	_interject(S, one, now)
	# A tag waits for a quiet moment: no exchange running, and the one free on his feet (not sent, not in the air from a
	# launch). So no blow, landing or exchange of the outgoing partner's outlives his handover.
	if not _quiet(S, one) or _g(one, GRANT) != 0:
		return
	var p = partner(S, one)
	var next = _nearestRing(S, one)
	if next == null:
		return
	if DirBrawl._g(p, DirBrawl.SENT) != 0:
		tag(S, next, "sent")
	elif S.dirS.ex == null and isGuard(S, p) and now - _g(p, ROLE_AT) >= int(round(float(cfg().get("sliceS", 6.0)) * DirData.TICKS_PER_SEC)):
		tag(S, next, "slice")   # (the Empress as partner has no slice: she keeps him until a decisive exchange or a parting)


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
	if _g(one, GRANT) == _slot(S, f) + 1:
		# Granted an interjection: the director moves him in and winds his blow (_interject); his own stick is still.
		i.mx = 0.0
		i.my = 0.0
		i.light = false
		i.heavy = false
		i.sig = false
		i.lightHeld = false
		i.heavyHeld = false
		i.sigHeld = false
		return
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


# ---------------------------------------------------------------- stage 3: guards, the step in, the interjection

## True while f is the one's partner and his line waits for an interjection (DirBrawl._free reads it): an AI partner from
## the grant to clearTicks after it lands, a player's only for clearTicks after it lands (before it, the guard yields).
static func holds(S: SimState, f) -> bool:
	return on(S) and f == partner(S, S.fighters[0]) and DirBrawl._now(S) < _g(S.fighters[0], HOLD_UNTIL)


## True while an interjection is in flight or its clearTicks after landing run: the brawl's double hit waits for it.
static func interjecting(S: SimState) -> bool:
	if not on(S):
		return false
	var one = S.fighters[0]
	return _g(one, GRANT) != 0 or DirBrawl._now(S) < _g(one, HOLD_UNTIL)


## True for one of the many who is not a principal: a guard (slot 2 and up). Slots 0 and 1 are the principals (Game
## Design's empress-guards.md section 5): only their KO ends a match, and only they close, launch or knock back.
static func isGuard(S: SimState, f) -> bool:
	return on(S) and _slot(S, f) >= 2


## A guard made the partner by a tag steps in to striking distance at the lunge's speed, for at most tagStepTicks, while
## nothing runs between him and the one. So a press of the one's lands on him as it would on a 1v1 rival in reach.
static func _stepTag(S: SimState, one, now: int) -> void:
	var p = partner(S, one)
	var t0: int = _g(p, STEP_TAG)
	if t0 <= 0:
		return
	var c: Dictionary = cfg()
	if now - t0 > int(c.get("tagStepTicks", 12)) or S.dirS.ex != null or p.state != "free" or one.state != "free":
		_s(p, STEP_TAG, 0)
		return
	var want: float = float(DirData.contact().offset) + float(c.get("tagStepBh", 0.3)) * DirInterrupt.BH
	if _moveTo(S, p, one, want, float(c.get("tagStepSpeed", 4000.0))):
		_s(p, STEP_TAG, 0)


## Moves f toward the point `want` units from the one on f's side, at most speed units a second, and level with him.
## True when he is there.
static func _moveTo(S: SimState, f, one, want: float, speed: float) -> bool:
	var sd: float = SimWrap.sdx(one.x, f.x)
	var side: float = SimMathx.jsign(sd) if absf(sd) > 0.5 else (-1.0 if _g(f, SIDE) == 1 else 1.0)
	var tx: float = SimWrap.wrap(one.x + side * want)
	var dx: float = SimWrap.sdx(f.x, tx)
	var step: float = speed * SimConst.DT
	var dy: float = one.y - f.y
	f.y += clampf(dy, -step, step)
	if absf(dx) <= step:
		f.x = tx
		return absf(dy) <= step
	f.x = SimWrap.wrap(f.x + SimMathx.jsign(dx) * step)
	return false


## The interjection (Game Design's empress-guards.md section 5, ruled 2026-10-15): one blow from the ring, a light (or a
## medium), never a heavy, a launcher or a grab. Granted on an opening the one gave (open after his own miss, or
## staggered where he stands), at most one in interject.everyS, to the nearest free guard in the ring. He moves in at the
## lunge's speed, his blow winds up in sight for windTicks (8 or more), and it lands as a beat of the partner's brawl that
## names him (args.a "X", args.who): guardable and perfect-blockable as any blow. It never lands within clearTicks of a
## blow of the partner's: a blow of the partner's due near it pulls it, and after it lands the partner's line waits.
static func _interject(S: SimState, one, now: int) -> void:
	var ic: Dictionary = cfg().get("interject", {})
	if ic.is_empty() or not bool(ic.get("enabled", true)):
		return
	var ex = S.dirS.ex
	var clear: int = int(ic.get("clearTicks", 8))
	var gs: int = _g(one, GRANT)
	if gs > 0:
		var g = S.fighters[gs - 1]
		if ex == null or not DirBrawl.isBrawl(ex) or ex.branch != "" or DirBrawl._g(g, DirBrawl.SENT) != 0 or g.stunTicks > 0 or g.state != "free":
			_pull(S, g, "lost")
			return
		var p = partner(S, one)
		if _g(one, GRANT_PH) == 1:
			var want: float = float(DirData.contact().offset)
			var there: bool = _moveTo(S, g, one, want, float(ic.get("speed", 4000.0)))
			if there or now - _g(one, GRANT_AT) >= int(ic.get("inTicksMax", 12)):
				var lead: int = maxi(8, int(ic.get("windTicks", 10)))
				var ct: int = now + lead
				if DirBrawl._g(p, DirBrawl.LINE) == 1 and absi(DirBrawl._g(p, DirBrawl.CONTACT) - ct) < clear:
					_pull(S, g, "partner")
					return
				_schedule(S, ex, g, one, lead)
				_s(one, GRANT_PH, 2)
				_s(one, GRANT_CT, ct)
		elif DirBrawl._g(p, DirBrawl.LINE) == 2 or (DirBrawl._g(p, DirBrawl.LINE) == 1 and absi(DirBrawl._g(p, DirBrawl.CONTACT) - _g(one, GRANT_CT)) < clear):
			_pull(S, g, "partner")   # the partner's blow is due within clearTicks of it, or held past its wind-up and due at any moment: the guard yields
		else:
			_moveTo(S, g, one, float(DirData.contact().offset), float(ic.get("speed", 4000.0)))   # he walks his blow after the one
		return
	if ex == null or not DirBrawl.isBrawl(ex) or ex.branch != "":
		return
	var last: int = _g(one, GRANT_AT)
	if last > 0 and now - last < int(round(float(ic.get("everyS", 1.5)) * DirData.TICKS_PER_SEC)):
		return
	var opening: bool = now < DirBrawl._g(one, DirBrawl.OPEN_UNTIL) or (one.stunTicks > 0 and DirBrawl._g(one, DirBrawl.SENT) == 0)
	if not opening:
		return
	var pp = partner(S, one)
	if DirBrawl._g(pp, DirBrawl.LINE) == 2:
		return   # the partner holds a blow past its wind-up: it may land at any moment
	var est: int = now + int(ic.get("inTicksMax", 12)) / 2 + maxi(8, int(ic.get("windTicks", 10)))
	if DirBrawl._g(pp, DirBrawl.LINE) == 1 and absi(DirBrawl._g(pp, DirBrawl.CONTACT) - est) < clear:
		return
	var g = _nearestRing(S, one)
	if g == null or not inRing(S, g):
		return
	_s(one, GRANT, _slot(S, g) + 1)
	_s(one, GRANT_AT, now)
	_s(one, GRANT_PH, 1)
	_s(one, GRANTS, _g(one, GRANTS) + 1)
	_s(g, STEP_IN, 0)
	if pp.ai != null:
		# An AI partner's line waits for it: free again clearTicks after its latest landing. A player's never waits: his
		# press wins, and the guard yields to it (_pull).
		var latest: int = now + int(ic.get("inTicksMax", 12)) + maxi(8, int(ic.get("windTicks", 10))) + clear
		_s(one, HOLD_UNTIL, maxi(_g(one, HOLD_UNTIL), latest))
	var e = DirBrawl._ev(S, g, "interject", "grant", "")
	e.target = float(_slot(S, one))


## The granted blow, as a beat of the partner's brawl: it lands lead live ticks from now. Its wind-up shows from now (the
## windup cue names him, with its landing tick and length).
static func _schedule(S: SimState, ex, g, one, lead: int) -> void:
	var c: Dictionary = DirBrawl.cfg()
	var ic: Dictionary = cfg().get("interject", {})
	var kinds: Array = ic.get("kinds", ["light"])
	var kind: int = DirBrawl.MEDIUM if (kinds.size() > 0 and String(kinds[0]) == "medium") else DirBrawl.LIGHT
	var dmg: float = (float(c.medium.worth) if kind == DirBrawl.MEDIUM else 1.0) * DirBrawl._unit() * float(ic.get("worthMul", 0.5))
	var o2 := {"class": "blow", "stop": float(int(c.hitstop.light)) / DirData.TICKS_PER_SEC, "big": false}
	var args := {"a": "X", "d": "A" if one == ex.A else "D", "who": _slot(S, g), "dmg": dmg, "o": o2, "brawl": true, "bk": kind,
		"strength": "medium" if kind == DirBrawl.MEDIUM else "light", "flurry": false, "grade": "none", "k": 0, "n": 0,
		"closing": false, "charge": 0.0, "hand": "r", "ender": false, "interject": true}
	DirExchange.schedule(ex, ex.t + (float(lead + 1) - 0.25) / DirData.TICKS_PER_SEC, "strike", args)
	var e = DirBrawl._ev(S, g, "windup", "interject", "")
	e.target = float(_slot(S, one))
	e.n = S.tick + lead
	e.dur = float(lead)


## The granted blow is pulled before it lands: the beat is marked, and the grant ends. why: partner, lost.
static func _pull(S: SimState, g, why: String) -> void:
	var one = S.fighters[0]
	var ex = S.dirS.ex
	if ex != null:
		for b in ex.beats:
			if not b.done and b.op == "strike" and b.args != null and String(b.args.get("a", "")) == "X" and int(b.args.get("who", -1)) == _slot(S, g):
				b.args["pulled"] = true
	_s(one, GRANT, 0)
	_s(one, GRANT_PH, 0)
	_s(one, PULLS, _g(one, PULLS) + 1)
	var e = DirBrawl._ev(S, g, "interject", "pulled:" + why, "")
	e.target = float(_slot(S, one))


## The granted blow lands (DirBrawl.contact hands a beat with args.a "X" here). It is a blow of the ring: no run, no
## close, no send. Out of reach it misses. On a guard or a perfect block it is what any blow is (DirMelee.strike). After
## it the one reels interject.reelTicks at most, and the partner's line waits clearTicks.
static func landX(S: SimState, ex, b) -> void:
	var a = b.args
	var one = S.fighters[0]
	var g = S.fighters[int(a.who)]
	var ic: Dictionary = cfg().get("interject", {})
	var granted: bool = _g(one, GRANT) == int(a.who) + 1
	_s(one, GRANT, 0)
	_s(one, GRANT_PH, 0)
	if bool(a.get("pulled", false)) or not granted:
		return
	if ex.branch != "" or DirBrawl._g(g, DirBrawl.SENT) != 0 or g.stunTicks > 0 or one.state != "locked":
		var e0 = DirBrawl._ev(S, g, "interject", "lost", "")
		e0.target = float(_slot(S, one))
		return
	var kind: int = int(a.bk)
	var far: float = DirBands.dist(g, one) - float(DirData.contact().offset)
	if far > (DirBrawl._reachOf(a, kind) - float(DirBrawl.cfg().give.edgeBh)) * DirInterrupt.BH:
		var e1 = DirBrawl._ev(S, g, "interject", "miss", "")
		e1.target = float(_slot(S, one))
		return
	# His guard, as the brawl reads it: a blow of his own on its way, open after a miss, or staggered: not guarding.
	var now: int = DirBrawl._now(S)
	var st: float = one.stance
	if st == 1.0 and (DirBrawl._g(one, DirBrawl.LINE) != 0 or now < DirBrawl._g(one, DirBrawl.OPEN_UNTIL) or one.stunTicks > 0):
		st = 0.0
	if one == ex.A:
		ex.sA = st
	else:
		ex.sD = st
	ex.kind = "medium" if kind == DirBrawl.MEDIUM else "light"
	DirMelee.strike(S, ex, g, one, float(a.dmg), a.o)
	var e = DirBrawl._ev(S, g, "interject", "landed", "")
	e.target = float(_slot(S, one))
	if S.dirS.ex != ex or ex.cancel or S.game.ko != null:
		return
	DirBrawl._s(one, DirBrawl.REEL_AT, maxi(DirBrawl._g(one, DirBrawl.REEL_AT), now + int(ic.get("reelTicks", 2))))
	var p = partner(S, one)
	_s(one, HOLD_UNTIL, maxi(_g(one, HOLD_UNTIL), now + int(ic.get("clearTicks", 8)) + 1))   # any partner's line waits clearTicks after it
