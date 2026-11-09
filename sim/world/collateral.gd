class_name WorldCollateral
## Where a hit reaches people (docs/world/collateral-caps.md, retired in part; docs/design/bystanders.md; Orb's "no civilian deaths going forward", Legal RL-257).
##
## Nobody dies, and nothing counts or pays for a person hit. scatter() is the one place people are moved: a blow, a fall, a crater, a body through the floors makes them
## leave the building at once and run to a shelter (the population is conserved), or be flung and bounce (a keyed speed and a number of bounces, drawn by the renderer),
## and an evacuate event tells the renderer to draw it. No fighter's menace, power, anguish or form reads it. The rolling budget, the ceiling and the set-piece tokens
## below are what held the old death count back; they allow nothing now and wait for the structure-mass budget (bystanders.md section 2).
##
## No draw from S.rng anywhere here: the thrown speeds are keyed (SimRng.keyed).

const WS: float = SimConst.WS
const POP_REF: float = 425.0
const WINDOW_S: int = 61   # 61 one-second buckets: the current second and the 60 before it, so a kill never leaves the window less than 60 s after it (60 freed a second's kills up to a second early: docs/world/collateral-caps.md section 12)
## The tables are data (data/biomes/collateral.json): budget per rolling 60 s and the ceiling on the cumulative total, by tier, as shares of the people present at the
## stage's start (pop0 in versus); what one set piece may borrow beyond the window's room, by tier, for each kind (slide, chain, landslide, quake, catastrophe).
## Loaded once when the class is first used; a fifth entry (the boss's: data/fight/tier5.json) extends a table and the tier functions follow its length.
const PATH := "res://data/biomes/collateral.json"
static var BUDGET: Array = []
static var CEILING: Array = []
static var EVENT_ALLOW: Dictionary = {}
static var METER_NORM: String = "pop0"
static var loadErrors: Array = []
static var dataHash: String = ""


static func _static_init() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		loadErrors.append("collateral.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != "biomes.collateral/1":
		loadErrors.append("collateral.json: schema is not biomes.collateral/1")
		return
	for v in j.budget:
		BUDGET.append(float(v))
	for v in j.ceiling:
		CEILING.append(float(v))
	for k in j.eventAllow:
		var a: Array = []
		for v in j.eventAllow[k]:
			a.append(float(v))
		EVENT_ALLOW[k] = a
	METER_NORM = str(j.meterNorm)
	MASS_REF = float(j.get("massRef", MASS_REF_DEFAULT))
	var bys: Dictionary = j.get("bystanders", {})
	if bys.is_empty():
		loadErrors.append("collateral.json: bystanders is missing")
	else:
		EVAC_R = float(bys.scatterBh) * BODY_H
		SHELTER_MIN = EVAC_R
		SHELTER_MAX = 4.0 * EVAC_R
		FLING_LO = float(bys.flingSpeed[0])
		FLING_HI = float(bys.flingSpeed[1])
		BOUNCES_MAX = int(bys.bouncesMax)
		UP_WITHIN_S = float(bys.upWithinSec)
	dataHash = str(text.hash())


## What an allowance reads at a tier: the table's entry, or its last when the table is shorter than the tier.
static func eventAllow(kind: String, tier: int) -> float:
	if not EVENT_ALLOW.has(kind):
		return 0.0
	var a: Array = EVENT_ALLOW[kind]
	return a[clampi(tier - 1, 0, a.size() - 1)]


## What the meter gains per casualty are divided by (data: pop0 or present).
static func normPeople(S: SimState) -> float:
	return S.world.present if METER_NORM == "present" and S.world.present > 0.0 else S.world.pop0
# ---- the district flight: while the window is over budget (or the ceiling is reached) and a heavy event was recent ----
static var EVAC_R: float = 600.0           # buildings this close to the latest heavy event empty: bystanders.scatterBh body heights (8 x 75 units), data/biomes/collateral.json
const EVAC_RATE: float = 0.30          # of a building's remaining people per second
const FLIGHT_MAX: float = 0.4          # the district flight takes at most this share of a building's people over a match
const EVAC_ACTIVE_S: float = 8.0       # the flight goes on for this long after the latest heavy event
const EVAC_LOT: float = 0.5            # flight lots are reported in events of at least this many people
const EVAC_MAX_PER_TICK: int = 12
## Where the fleeing go. With RELOCATE the people who flee take shelter in the nearest standing building outside the danger
## zone (SHELTER_MIN to SHELTER_MAX from the event, at most SHELTER_CAP times its own people), so the population is conserved
## and only the budget limits how many die; without it they leave the planet's count for good.
const RELOCATE: bool = true
static var SHELTER_MIN: float = 600.0
static var SHELTER_MAX: float = 2400.0
const SHELTER_CAP: float = 2.0
const BODY_H: float = 75.0              # a body height in units (the struggle meeting point's too)
static var FLING_LO: float = 300.0     # bystanders.flingSpeed: the speed range of a person thrown, units a second
static var FLING_HI: float = 900.0
static var BOUNCES_MAX: int = 2        # bystanders.bouncesMax
static var UP_WITHIN_S: float = 3.0    # bystanders.upWithinSec: on their feet again and running
const HIST_BUCKETS: int = 48           # the lure's population histogram (director/ai.gd LURE_STEP = W / 48)


static func histBucket(x: float) -> int:
	return mini(int(SimWrap.wrap(x) / (SimConst.W / 48.0)), HIST_BUCKETS - 1)   # one bucket is a 48th of the arena (director/location.gd STEP)


## ---- far places (docs/world/places-everywhere.md; Game Design, ring-any-angle/game-design.md section 15): with plans.farPeople the buildings of the places the first ring does not hold have people, asleep until the
## place is posed (a fighter within plans.farReach of it), and with plans.farAnguish those people count toward the hero's anguish as a fraction of their own place's base (RL-228 term 3: a larger place does not raise the cost by itself), and
## feed nothing else: not the budget or the ceiling, menace, power, Witness or mood (which read pop0 and `casualties`, neither of which they touch). S.world.farMask has a bit for each place posed. Nothing here runs unless the records hold a "far" record.
static var _far: Dictionary = {}   # world id -> [first far index, places [{place, first, count, pop, dir}]]: derived from the buildings, not state


static func _farInfo(S: SimState) -> Array:
	var hit = _far.get(S.worldId)
	if hit != null and hit[2] == S.buildings.size() and hit[4] == S.fieldRecs.size():   # (a world of the same id and size with another set of records, as a plan switched, is another world)
		return hit
	var n: int = -1
	for r in S.fieldRecs:
		if r.k == "far":
			n = int(r.n)
	var places: Array = []
	if n >= 0:
		var cur: int = -1
		for bi in range(n, S.buildings.size()):
			var b = S.buildings[bi]
			if int(b.place) != cur:
				cur = int(b.place)
				places.append({"place": cur, "first": bi, "count": 0, "pop": 0.0})
			places[places.size() - 1].count += 1
			places[places.size() - 1].pop += float(b.pop)
	if _far.size() > 8:
		_far.clear()
	var held: Dictionary = {}   # the first ring's places: a far place counts, when wholly lost, as plans.farShare of one of them (the average first-ring place's people)
	for bi in range(mini(maxi(n, 0), S.buildings.size())):
		held[int(S.buildings[bi].place)] = true
	var w: float = WorldPlan.farShare() * S.world.pop0 / float(maxi(held.size(), 1))
	hit = [n, places, S.buildings.size(), w, S.fieldRecs.size()]
	_far[S.worldId] = hit
	return hit


static func isFar(S: SimState, bi: int) -> bool:
	if S.fieldRecs.is_empty():
		return false
	var n: int = int(_farInfo(S)[0])
	return n >= 0 and bi >= n


## Every 30th tick: a far place whose first building is within farReach of a fighter (by planet distance, through the frame) is posed: its people wake.
static func wakeFar(S: SimState) -> void:
	if S.frame == null or S.fieldRecs.is_empty() or int(S.T * 60.0 + 0.5) % 30 != 0:
		return
	var info: Array = _farInfo(S)
	if int(info[0]) < 0:
		return
	var R: float = SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI)
	var reach: float = WorldPlan.farReach()
	var pl: Array = info[1]
	for f in S.fighters:
		SimField.placeAt(S, f.x, f.z)
		var fx: float = SimField.ox
		var fy: float = SimField.oy
		var fz: float = SimField.oz
		for k in range(mini(pl.size(), 62)):
			if (S.world.farMask >> k) & 1:
				continue
			var i3: int = 3 * int(pl[k].first)
			var ex: float = fx - S.bDir[i3]
			var ey: float = fy - S.bDir[i3 + 1]
			var ez: float = fz - S.bDir[i3 + 2]
			var d: float = R * sqrt(ex * ex + ey * ey + ez * ez)
			if d <= reach:
				S.world.farMask |= 1 << k
				for bi in range(int(pl[k].first), int(pl[k].first) + int(pl[k].count)):
					S.buildings[bi].popAlive = S.buildings[bi].pop


## Start of a match, after the buildings exist: the window, the state and the lure histogram.
static func init(S: SimState) -> void:
	var w: SimState.World = S.world
	w.cbBuckets = PackedFloat32Array()
	w.cbBuckets.resize(WINDOW_S)
	w.cbBuckets.fill(0.0)
	w.cbSec = 0.0
	w.cbSum = 0.0
	w.maxTier = 1.0
	w.present = w.pop0
	w.peopleLeft = -1.0
	w.evtKind = ""
	w.evtLeft = 0.0
	w.evtToken = 0.0
	w.evtDead = 0.0
	w.evtEvac = 0.0
	w.tokenSeq = 0.0
	w.heavyX = -1.0
	w.heavyT = -1.0e9
	w.stateT = 0.0
	w.evacuated = 0.0
	w.massLost = 0.0
	w.mass0 = 0.0
	for b in S.buildings:
		if b.alive and not isFar(S, b.idx):
			w.mass0 += WorldBrunt.massOf(b)   # the arena's structure mass at the start: what the destruction gains are normalised by
	w.lotAcc = PackedFloat32Array()
	w.lotAcc.resize(S.buildings.size())
	w.lotAcc.fill(0.0)
	S.popHist = PackedFloat32Array()
	S.popHist.resize(HIST_BUCKETS)
	S.popHist.fill(0.0)
	for b in S.buildings:
		S.popHist[histBucket(b.x)] += livedMass(S, b)   # the lure reads the lived-in structure mass, never the people (bystanders.md section 2)


## The higher of the two fighters' tiers, 1 to 4.
static func tier(S: SimState) -> int:
	var t: float = 1.0
	for f in S.fighters:
		t = maxf(t, f.tier)
	return clampi(int(t), 1, BUDGET.size())


static func _advance(S: SimState) -> void:
	var w: SimState.World = S.world
	var sec: int = int(floor(S.T))
	var last: int = int(w.cbSec)
	if sec <= last:
		return
	if sec - last >= WINDOW_S:
		w.cbBuckets.fill(0.0)
	else:
		for s in range(last + 1, sec + 1):
			w.cbBuckets[s % WINDOW_S] = 0.0
	w.cbSec = float(sec)
	var sum: float = 0.0
	for i in range(WINDOW_S):
		sum += w.cbBuckets[i]
	w.cbSum = sum


static func budget(S: SimState) -> float:
	return BUDGET[tier(S) - 1] * S.world.mass0


## Structure mass the window still admits right now (before borrowing).
static func room(S: SimState) -> float:
	_advance(S)
	return maxf(0.0, budget(S) - S.world.cbSum)


## Structure mass the cumulative ceiling still admits.
static func ceilingLeft(S: SimState) -> float:
	return maxf(0.0, CEILING[clampi(int(S.world.maxTier), 1, CEILING.size()) - 1] * S.world.mass0 - S.world.massLost)


## True when the window or the ceiling is spent: the launch planner stops adding chains that would break more (bystanders.md section 2). Nothing is held back by it: structures take their damage.
static func isOver(S: SimState) -> bool:
	return room(S) <= 0.000001 or ceilingLeft(S) <= 0.000001


## Open a set piece: returns its token, which the source passes to kill() (through damageArea and damageBuilding) so the
## allowance belongs to this event's own source. At tier 1 and 2 there is no allowance.
static func beginEvent(S: SimState, kind: String, cause) -> float:
	var w: SimState.World = S.world
	w.tokenSeq += 1.0
	w.evtToken = w.tokenSeq
	w.evtKind = kind
	var t: int = tier(S)
	w.evtLeft = eventAllow(kind, t) * w.mass0
	w.evtDead = 0.0
	w.evtEvac = 0.0
	return w.evtToken


## Close a set piece and return {"dead", "evac", "borrowed"} for the token; an unknown token returns zeros.
static func endEvent(S: SimState, token: float) -> Dictionary:
	var w: SimState.World = S.world
	var r := {"dead": 0.0, "evac": 0.0}
	if token != 0.0 and token == w.evtToken:
		r.dead = w.evtDead
		r.evac = w.evtEvac
		w.evtKind = ""
		w.evtLeft = 0.0
		w.evtToken = 0.0
		w.evtDead = 0.0
		w.evtEvac = 0.0
	return r


## Record where the latest heavy event was (the district flight flees from it).
static func heavy(S: SimState, x: float) -> void:
	S.world.heavyX = x
	S.world.heavyT = S.T


## The nearest standing building outside the danger zone that can take n more people, or -1.
static func shelter(S: SimState, cx: float, n: float) -> int:
	if not RELOCATE:
		return -1
	var best: int = -1
	var bd: float = 1e18
	for bi in WorldStructures.near(S, cx, SHELTER_MAX):
		var b = S.buildings[bi]
		if not b.alive or isFar(S, bi):
			continue
		var d: float = absf(SimWrap.sdx(cx, b.x))
		if d < SHELTER_MIN or d > SHELTER_MAX or b.popAlive + n > SHELTER_CAP * b.pop:
			continue
		if d < bd:
			bd = d
			best = bi
	return best


## Nobody dies (Orb, 2026-11-07, CD-05; docs/design/bystanders.md; Legal RL-257). The one place people are moved. want is how many would be in the way in building bi (or -1 for people outside any
## building); they all leave it at once and run to a shelter, so the population is conserved, and the renderer draws the run. how "flung" is a hit (a body through the floors, a fall, a crater
## opening under them): the same people thrown clear, with a keyed speed and a number of bounces for the renderer, which draws the arc and never writes the sim. No one is removed, hurt or counted:
## S.world.casualties is never written, and nothing here touches any fighter's menace, power, anguish or form. cx is the x of the event that caused it (the crowd runs from it); evt is the caller's
## set-piece token (kept for the callers, it allows nothing now). Returns how many ran.
static func scatter(S: SimState, bi: int, want: float, cause, evt: float, cx: float, floor_: int = -1, how: String = "scatter") -> float:
	if want <= 0.0:
		return 0.0
	var w: SimState.World = S.world
	var b = S.buildings[bi] if bi >= 0 else null
	if bi >= 0 and isFar(S, bi):   # --- far branch begin: a far town's people sleep until it is posed, so nothing is read or moved there ---
		return 0.0   # --- far branch end ---
	var ran: float = want
	if b != null:
		ran = minf(want, b.popAlive)
		b.popAlive -= ran
	if ran <= 0.000001:
		return 0.0
	w.evacuated += ran
	var dest: int = shelter(S, cx, ran)
	if dest >= 0:
		S.buildings[dest].popAlive += ran
	SimFx.evacuate(S, bi, b.x if b != null else cx, ran, cx, how, WorldCrater._slot(S, cause), dest, floor_)
	if how == "flung":
		var e = S.out.fx[S.out.fx.size() - 1]
		var key: int = (S.tick * 4096 + maxi(bi, 0)) * 8 + (floor_ + 1) % 8
		e.spd = FLING_LO + (FLING_HI - FLING_LO) * SimRng.keyed(int(S.game.seed), "bystander.fling.speed", key)
		e.k = float(int(SimRng.keyed(int(S.game.seed), "bystander.fling.bounces", key) * float(BOUNCES_MAX + 1)))
		e.dur = UP_WITHIN_S
	heavy(S, cx)
	return ran


## ---- what the meters read: destruction, never a person (docs/design/bystanders.md sections 3 and 4; Legal RL-257) ----
## No decision in the sim reads who or how many are inside a building. A building is lived-in by its own housing (`pop`, a flag of the place: a home, a tower, a lab), and is
## occupied until its first damage, which empties it. Everything below reads those and the structure mass (WorldBrunt.massOf: a house 1, a low tower 5, a tall tower 15).
const MASS_REF_DEFAULT: float = 600.0

static var MASS_REF: float = MASS_REF_DEFAULT   # data/biomes/collateral.json massRef: the structure mass of the reference arena, so a gain by mass reads the same on every planet


## What a destruction or terror gain is multiplied by: the reference arena's mass over this one's (as people were normalised by pop0).
static func norm(S: SimState) -> float:
	return MASS_REF / maxf(S.world.mass0, 1.0)


## True when the place is lived-in: its housing, not who is inside.
static func lived(b) -> bool:
	return b.pop > 0.0


## A far town is read only once its place is posed (a fighter within plans.farReach, wakeFar), as its people were.
static func _farAwake(S: SimState, bi: int) -> bool:
	if not isFar(S, bi):
		return true
	var info: Array = _farInfo(S)
	var pl: Array = info[1]
	for k in range(mini(pl.size(), 62)):
		if int(pl[k].first) <= bi and bi < int(pl[k].first) + int(pl[k].count):
			return ((S.world.farMask >> k) & 1) == 1
	return false


## Lived-in, standing and untouched: the people are inside it. Its first damage empties it.
static var blindPeople: bool = false   # tests only: occupied reads a person (popAlive), the negative control of the civilians-removed identity


static func occupied(S: SimState, b) -> bool:
	if blindPeople:
		return b.alive and b.popAlive > 0.0 and b.hp >= b.maxhp
	return b.alive and b.pop > 0.0 and b.hp >= b.maxhp and _farAwake(S, b.idx)


## The structure mass a decision sees at b: its mass while it is occupied, else 0.
static func livedMass(S: SimState, b) -> float:
	return WorldBrunt.massOf(b) if occupied(S, b) else 0.0


## The place at x: the place of the nearest building to it, by the shortest arc (-1 with none within reach).
static func _placeAt(S: SimState, x: float) -> int:
	var best: int = -1
	var bd: float = 1.0e18
	for bi in WorldStructures.near(S, x, 3000.0):
		var d: float = absf(SimWrap.sdx(x, S.buildings[bi].x))
		if d < bd:
			bd = d
			best = int(S.buildings[bi].place)
	return best


## A building has fallen (damageBuilding, once): its mass joins the window and the total, and the fighter who brought it down feeds on it, and the one it was brought down near is pressured.
## menace and the villain's power by `whose: self` rows (his blow, send, beam or body), anguish by `whose: self` (he did it) or `opponent` (anyone else did) within `within` of him, and the
## failing to protect: a fall inside the place he is fighting in while he is the nearest fighter to it. All times the arena's norm, and capped at 100.
static func fell(S: SimState, b, cause) -> void:
	var w: SimState.World = S.world
	var m: float = WorldBrunt.massOf(b)
	_advance(S)
	w.massLost += m
	w.cbBuckets[int(w.cbSec) % WINDOW_S] += m
	w.cbSum += m
	var nm: float = norm(S)
	if cause != null and cause.hasMenace:
		cause.menace = SimMathx.jmin(100.0, cause.menace + m * cause.md.menaceDestroyed * nm)
		cause.power = SimMathx.jmin(100.0, cause.power + m * cause.md.worldPower * nm)
	var place: int = -2
	for f in S.fighters:
		if not f.hasAnguish:
			continue
		var dx: float = absf(SimWrap.sdx(f.x, b.x))
		if dx > f.md.anguishNear:
			continue
		var g: float = f.md.anguishDestroyedSelf if cause == f else f.md.anguishDestroyedOther
		if f.md.anguishFailed > 0.0:
			var nearest: bool = true
			for o in S.fighters:
				if o != f and absf(SimWrap.sdx(o.x, b.x)) < dx:
					nearest = false
			if nearest:
				if place == -2:
					place = int(b.place)
				if place >= 0 and _placeAt(S, f.x) == place:
					g += f.md.anguishFailed
		f.anguish = SimMathx.jmin(100.0, f.anguish + m * g * nm)
	if cause != null and not S.fighters.has(cause) and cause.hasAnguish:   # a body of another fight (a shot from outside, cross-fights): what he brings down costs him as at home
		cause.anguish = SimMathx.jmin(100.0, cause.anguish + m * cause.md.anguishDestroyedSelf * nm)


## A lived-in building has taken its first damage (damageBuilding, once): whoever is inside streams out, which is terror for the one whose blow it was, by the size of the place, and a cost to the
## fighter near it. The lure's histogram loses its mass. Nothing here reads who or how many were inside.
static func emptied(S: SimState, b, cause) -> void:
	var nm: float = norm(S)
	if cause != null and cause.hasMenace:
		cause.menace = SimMathx.jmin(100.0, cause.menace + cause.md.menaceEmptied[WorldBrunt.sizeClass(b)] * nm)
	for f in S.fighters:
		if f.hasAnguish and absf(SimWrap.sdx(f.x, b.x)) <= f.md.anguishNear:
			f.anguish = SimMathx.jmin(100.0, f.anguish + f.md.anguishEmptied * nm)
	if cause != null and not S.fighters.has(cause) and cause.hasAnguish:   # a body of another fight (a shot from outside): a place his shot empties costs him as at home
		cause.anguish = SimMathx.jmin(100.0, cause.anguish + cause.md.anguishEmptied * nm)
	if not isFar(S, b.idx):   # the lure holds the first ring only (a far place never joined it)
		S.popHist[histBucket(b.x)] = maxf(0.0, S.popHist[histBucket(b.x)] - WorldBrunt.massOf(b))


## A crater or a trench has been dug (WorldCrater): by his send or his beam, wide enough (`minBh` body heights across), it feeds the villain; powering up on the ground does not.
static func dug(S: SimState, across: float, kind: String, cause) -> void:
	if cause == null or not cause.hasMenace or kind == "powerup":
		return
	if across < cause.md.menaceCraterBh * BODY_H:
		return
	cause.menace = SimMathx.jmin(100.0, cause.menace + cause.md.menaceCrater * norm(S))


## The combat trauma, read from this tick's events (they are never a person struck by the world): a region of the opposing fighter broken, and the opposing fighter reaching the brink. Not normalised.
static func _trauma(S: SimState) -> void:
	for e in S.out.fx:
		if int(e.tick) != S.tick or (e.type != "region_broken" and e.type != "brink_enter"):
			continue
		var vi: int = int(e.actor)
		if vi < 0 or vi >= S.fighters.size():
			continue
		var victim = S.fighters[vi]
		for f in S.fighters:
			if f.hasMenace and SimCross.team(f) != SimCross.team(victim):   # a foe of his: the other team (by the slot he started in), whatever the roster
				f.menace = SimMathx.jmin(100.0, f.menace + (f.md.menaceBreak if e.type == "region_broken" else f.md.menaceBrink))


## Once per unfrozen tick: advance the window, report the state once a second, and run the district flight.
static func tick(S: SimState) -> void:
	var w: SimState.World = S.world
	_advance(S)
	wakeFar(S)
	_trauma(S)
	var sec: int = int(floor(S.T))
	if sec > int(w.stateT):
		w.stateT = float(sec)
		SimFx.collateralState(S, room(S), budget(S), ceilingLeft(S), isOver(S))
	if w.heavyX < 0.0 or S.T - w.heavyT > EVAC_ACTIVE_S:
		return
	var dt: float = S.dt
	var events: int = 0
	var dest: int = shelter(S, w.heavyX, 1.0)
	var moved: float = 0.0
	for bi in WorldStructures.near(S, w.heavyX, EVAC_R):
		var b = S.buildings[bi]
		if not b.alive or b.popAlive <= 0.0 or isFar(S, bi):
			continue
		if absf(SimWrap.sdx(w.heavyX, b.x)) - b.w / 2.0 > EVAC_R:
			continue
		var take: float = minf(b.popAlive * EVAC_RATE * dt, FLIGHT_MAX * b.pop - b.fled)
		if take <= 0.0:
			continue
		b.fled += take
		b.popAlive -= take
		w.evacuated += take
		w.lotAcc[bi] += take
		moved += take
		if w.lotAcc[bi] >= EVAC_LOT and events < EVAC_MAX_PER_TICK:
			SimFx.evacuate(S, bi, b.x, w.lotAcc[bi], w.heavyX, "flight", -1.0, dest)
			w.lotAcc[bi] = 0.0
			events += 1
	if dest >= 0 and moved > 0.0:
		S.buildings[dest].popAlive += moved
