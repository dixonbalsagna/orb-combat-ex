class_name SimIntro
## The intro phase (docs/architecture/intro-phase.md; Camera's row 7): a run of pre-clock ticks at the start of a match,
## built like a pause. SimCore.step returns false, S.T stays 0, no input is consumed and nothing else in the sim runs.
## Inside it a composed timeline plays: each fighter falls from the sky and lands in a crater, one may wait for the other,
## they stare, the clock starts.
##
## The timeline is data (data/fight/intro.json): a template (a scenario) is a list of slots, each filled by one part, and a
## part is a short list of beats. The director's composer (sim/director/intro.gd, DirIntro) picks the template, who
## arrives first, the gap between the arrivals and each slot's part, with keyed draws on the match seed; this module plays
## what it picked. The pick is a few integers in S.intro (hashed); the beats are worked out from them and the data. What
## the facts add for the view only (gestures, the voice slots' tags) rides beside them and touches no gameplay state.
##
## It is a match setting, in newMatch's setup and so in the replay header:
##   "intro": "skip"   its effects at once (both craters, both fighters on the ground) with no pre-clock tick. It is what a
##                     setup without the key gets, so the game, the batches and the goldens share one opening
##   "intro": true     the classic opening: the template marked classic, the left spot first, its default gap
##   "intro": {...}    a composed opening ("play": true): the composer draws it. The record may fix "scenario" (a template's
##                     id), "order" (the slot that arrives first) and "gap" (ticks), and may carry "avoid" (template ids
##                     played lately, the newest first: the host's no-repeat list) and "facts": what the host resolved
##                     about the pair (Narrative's plotlines, docs/narrative/dynamic-intros.md section 11). The composer
##                     reads tones, weights, gap, look, clock and gestures; plot and intents are passed through on the
##                     events; anything else is ignored. A record with no "facts" takes the data's defaultFacts (a
##                     first meeting). "take" (0, 1, 2, ...: the host's rematch counter) makes the same seed compose
##                     a different opening on each take. "classic": true asks for the classic opening
##   "intro": false    the old flat start
## A press on a human slot skips it (after skipFrom ticks): the landings left are applied at once, in order.
##
## Whatever is composed, and whether it ran or was skipped, the state at the clock is the same: both fighters free on their
## start spots, each in his entrance crater, the craters' records in the order of the start spots. So a fight does not
## depend on its intro. The fall is a closed-form path, not flight physics, and S.rng is not read.
##
## Two fighters. "Left" is the fighter on the left start spot: in a normal match slot 0. Going by the spot and not the
## slot keeps the craters' order the same when a QA arm exchanges the spawn sides. The entrance craters are nobody's.

const PATH: String = "res://data/fight/intro.json"
const TPS: int = 60
const FIRST: int = 0      # a beat's role: the fighter who arrives first ...
const SECOND: int = 1     # ... the one who arrives second ...
const LEFT: int = 2       # ... the one on the left start spot ...
const RIGHT: int = 3      # ... the other ...
const BOTH: int = -1      # ... or nobody in particular
const OWN: int = -2       # (in a part: the beat takes its slot's role)
const ROLES: Dictionary = {"first": FIRST, "second": SECOND, "left": LEFT, "right": RIGHT, "both": BOTH}
const ROLE_NAMES: Array = ["first", "second", "left", "right"]
const KINDS: Array = ["fall", "land", "wait", "line", "staredown", "gesture"]
const POINTS: Array = ["land_first", "land_second", "wait", "look_start", "look_end"]   # where a facts gesture may play
const MAX_GESTURES: int = 16
const MAX_FILLS: int = 64   # the ways one template's slots can be filled, at most (each is checked when the data loads)

static var _loaded: bool = false
static var _hash: String = ""
static var _errors: Array = []
static var skipFrom: int = 0         # a press skips from this tick on
static var fallHeight: float = 0.0   # units above the ground the fall starts from
static var craterE: float = 0.0      # the entrance crater's energy (WorldCrater.dig)
static var parts: Dictionary = {}    # id -> {type, mode, ticks, beats: [{t, kind, intent, who}]}
static var templates: Array = []     # in the file's order: {id, weight, tone, clock, gapMin, gapMax, gapDef, notTwice, classic, fills, slots: [{who, pool, after, gap, with, draw}]}
static var clockBend: Array = [0, 0] # the least and the most a match's facts may add to a template's clock
static var points: Dictionary = {}   # a gesture point -> its ticks from its anchor (look_end: from the clock, negative)
static var defaultFacts: Dictionary = {}   # the facts a composed intro takes when its record sends none (DirIntro.compose)
static var classicI: int = 0         # the template a plain "intro": true plays
static var _flat: Dictionary = {}    # "template:gap:picks" -> its timeline (flatten)
# the classic opening's ticks, for tools: A is the first to arrive, B the second
static var fall: Array = [0, 0]
static var land: Array = [0, 0]
static var staredown: int = 0
static var clock: int = 0


# ---------------------------------------------------------------- data

static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	_errors = []
	_flat = {}
	var j = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (j is Dictionary):
		_err("data/fight/intro.json is missing or not valid JSON")
		j = {}
	var h := SimHash.Hasher.new()
	h.text("intro")
	FighterData._canon(h, j)
	_hash = h.hex()
	skipFrom = _tick("skipFrom", j.get("skipFrom"))
	fallHeight = float(j.get("fallHeight", 0.0))
	craterE = float(j.get("craterEnergy", 0.0))
	if not (fallHeight > 0.0) or craterE < 0.0:
		_err("fallHeight must be above 0 and craterEnergy at least 0")
	var cb = j.get("clockBend", {})
	clockBend = [int(float(cb.get("min", 0))), int(float(cb.get("max", 0)))] if cb is Dictionary else [0, 0]
	if clockBend[0] > 0 or clockBend[1] < 0:
		_err("clockBend: min must be 0 or less and max 0 or more")
	points = {}
	var gp = j.get("gesturePoints", {})
	for name in POINTS:
		var v = gp.get(name) if gp is Dictionary else null
		points[name] = int(float(v)) if (v is float or v is int) else 0
		if (name == "look_end") != (points[name] < 0) and points[name] != 0:
			_err("gesturePoints." + name + ": look_end counts back from the clock (negative); the others count on (0 or more)")
	parts = {}
	var pj = j.get("parts", {})
	if not (pj is Dictionary):
		pj = {}
	for id in pj:
		if String(id).begins_with("_"):
			continue
		var p: Dictionary = pj[id]
		var where: String = "parts." + id + "."
		var beats: Array = []
		var falls: int = 0
		var lands: int = 0
		for b in p.get("beats", []):
			var kind: String = String(b.get("kind", ""))
			if not KINDS.has(kind):
				_err(where + "beats: unknown kind '" + kind + "'")
				continue
			var who: int = OWN
			if b.has("who"):
				who = ROLES.get(String(b.who), OWN)
				if who == OWN or who == BOTH:
					_err(where + "beats: who must be first, second, left or right")
			var bt: int = _tick(where + "beats.t", b.get("t"))
			if (kind == "line" or kind == "gesture") and String(b.get("intent", "")) == "":
				_err(where + "beats: a line and a gesture need an intent")
			falls += 1 if kind == "fall" else 0
			lands += 1 if kind == "land" else 0
			beats.append({"t": bt, "kind": kind, "intent": String(b.get("intent", "")), "who": who})
		var pt: Dictionary = {"type": String(p.get("type", "")), "mode": String(p.get("mode", "")), "ticks": _tick(where + "ticks", p.get("ticks", 0)), "beats": beats}
		if pt.type == "entrance":
			if falls != 1 or lands != 1 or pt.ticks < 1 or pt.mode == "":
				_err(where + "an entrance has one fall, one land, a length and a mode")
		elif falls != 0 or lands != 0:
			_err(where + "only an entrance falls and lands")
		parts[id] = pt
	templates = []
	classicI = -1
	var tj = j.get("templates", [])
	if not (tj is Array) or tj.is_empty():
		_err("templates: at least one is needed")
		tj = []
	for tp in tj:
		var id: String = String(tp.get("id", ""))
		var where: String = "templates." + id + "."
		for o in templates:
			if o.id == id:
				_err(where + "id: used twice")
		var gj: Dictionary = tp.get("gap", {})
		var t := {"id": id, "weight": float(tp.get("weight", 0.0)), "tone": String(tp.get("tone", "")), "clock": _tick(where + "clock", tp.get("clock")),
			"gapMin": _tick(where + "gap.min", gj.get("min")), "gapMax": _tick(where + "gap.max", gj.get("max")), "gapDef": _tick(where + "gap.default", gj.get("default")),
			"notTwice": tp.get("notTwice", false) == true, "classic": tp.get("classic", false) == true, "fills": 1, "slots": []}
		if id == "" or t.weight < 0.0 or not (t.gapMin <= t.gapDef and t.gapDef <= t.gapMax):
			_err(where + "an id, a weight of at least 0, and gap.min <= gap.default <= gap.max are needed")
		for s in tp.get("slots", []):
			var who: int = ROLES.get(String(s.get("who", "")), OWN)
			var pool: Array = []
			for pid in s.get("pool", []):
				if parts.has(String(pid)):
					pool.append(String(pid))
				else:
					_err(where + "slots: unknown part '" + String(pid) + "'")
			if who == OWN or pool.is_empty():
				_err(where + "slots: each needs who (first, second, left, right or both) and a pool of parts")
				continue
			for pid in pool:
				if parts[pid].type == "entrance" and who != FIRST and who != SECOND:
					_err(where + "slots: an entrance is first's or second's")
			t.fills *= pool.size()
			t.slots.append({"who": who, "pool": pool, "after": _tick(where + "slots.after", s.get("after", 0)), "gap": s.get("gap", false) == true, "with": s.get("with", false) == true, "draw": s.get("draw", true) == true})
		templates.append(t)
		var ti: int = templates.size() - 1
		if t.classic and classicI < 0:
			classicI = ti
		if t.fills > MAX_FILLS:
			_err(where + "slots: more than %d ways to fill them" % MAX_FILLS)
			continue
		if skipFrom >= t.clock:
			_err(where + "clock: skipFrom must be before it")
		# every way to fill it, at the shortest, the default and the longest gap, must be a whole intro inside its length
		for gap in [t.gapMin, t.gapDef, t.gapMax]:
			for picks in range(t.fills):
				var fl: Dictionary = flatten(ti, gap, picks)
				if fl.why != "":
					_err(where + "with a gap of %d and fill %d: %s" % [gap, picks, fl.why])
				elif fl.need > t.clock:
					_err(where + "with a gap of %d and fill %d it needs %d ticks, and the clock is %d" % [gap, picks, fl.need, t.clock])
	if classicI < 0:
		_err("templates: one must be marked classic")
		classicI = 0
	if not templates.is_empty():
		var c: Dictionary = flatten(classicI, templates[classicI].gapDef, 0)
		fall = c.fall
		land = c.land
		staredown = c.staredown
		clock = templates[classicI].clock
	# the default facts: a record's own facts keys. What the composer and the playback read of them is checked here
	defaultFacts = {}
	var df = j.get("defaultFacts")
	if df is Dictionary:
		defaultFacts = df
		var dl = df.get("look")
		if dl != null and not (dl is String and parts.has(dl) and parts[dl].type == "look"):
			_err("defaultFacts.look: not a look part")
		var dg = df.get("gestures", [])
		if not (dg is Array) or dg.size() * 2 > MAX_GESTURES:
			_err("defaultFacts.gestures: a list of at most %d" % (MAX_GESTURES / 2))
			dg = []
		for g in dg:
			if not (g is Dictionary and POINTS.has(String(g.get("at", ""))) and ROLES.has(String(g.get("who", ""))) and String(g.get("intent", "")) != ""):
				_err("defaultFacts.gestures: each needs at (a gesture point), who (a role) and intent")
		if not (df.get("intents", {}) is Dictionary):
			_err("defaultFacts.intents: a record by voice slot")
	elif df != null:
		_err("defaultFacts: a record of facts")


## The timeline of template ti with this gap and these parts (picks: one digit a slot, the first slot lowest, each in
## the base of its pool's size): {"beats": [{t, kind, role, intent, mode}] in time order, "fall" and "land": the ticks by
## arrival (first, second), "staredown", "wait" (the wait beat's tick, or -1), "need" (the shortest clock it fits in),
## "why": "" or what is wrong with it}. A pure function of the data, kept.
static func flatten(ti: int, gap: int, picks: int) -> Dictionary:
	var key: String = "%d:%d:%d" % [ti, gap, picks]
	if _flat.has(key):
		return _flat[key]
	var tp: Dictionary = templates[ti]
	var beats: Array = []
	var fallT: Array = [-1, -1]
	var landT: Array = [-1, -1]
	var stare: int = -1
	var waitT: int = -1
	var why: String = ""
	var cursor: int = 0
	var p: int = picks
	for s in tp.slots:
		var n: int = s.pool.size()
		var part: Dictionary = parts[s.pool[p % n]]
		p /= n
		var start: int = cursor + s.after + (gap if s.gap else 0)
		for b in part.beats:
			var role: int = b.who if b.who != OWN else s.who
			var bt: int = start + b.t
			if b.kind == "fall" or b.kind == "land":
				var into: Array = fallT if b.kind == "fall" else landT
				if into[role] >= 0:
					why = "a fighter enters twice"
				into[role] = bt
			elif b.kind == "staredown":
				if stare >= 0:
					why = "two staredowns"
				stare = bt
			elif role == BOTH:
				why = "a " + b.kind + " beat needs one fighter"
			elif b.kind == "wait":
				waitT = bt
			var at: int = beats.size()   # in time order; beats of one tick stay in the order they were written
			while at > 0 and beats[at - 1].t > bt:
				at -= 1
			beats.insert(at, {"t": bt, "kind": b.kind, "role": role, "intent": b.intent, "mode": part.mode})
		if not s.with:
			cursor = start + part.ticks
	if why == "":
		if fallT[0] < 0 or fallT[1] < 0 or landT[0] < 0 or landT[1] < 0:
			why = "each fighter needs one entrance"
		elif landT[0] > landT[1]:
			why = "the first to arrive lands after the second"
		elif stare < landT[1]:
			why = "the staredown must come after both landings"
	var need: int = maxi(maxi(stare + 1, cursor), (beats[beats.size() - 1].t + 1) if not beats.is_empty() else 0)
	var res := {"beats": beats, "fall": fallT, "land": landT, "staredown": stare, "wait": waitT, "need": need, "why": why}
	_flat[key] = res
	return res


static func dataHash() -> String:
	_ensure()
	return _hash


static func errors() -> Array:
	_ensure()
	return _errors


static func _err(msg: String) -> void:
	_errors.append(msg)
	push_error("SimIntro: " + msg)


static func _tick(where: String, x) -> int:
	var f: float = float(x) if x != null else -1.0
	if x == null or f != floor(f) or f < 0.0:
		_err(where + ": must be a whole number of ticks, at least 0, got " + str(x))
		return 0
	return int(f)


# ---------------------------------------------------------------- the match

## A new match (sim.gd newMatch, after the fighters exist and before it clears the event list).
static func setup(S: SimState, su: Dictionary) -> void:
	_ensure()
	S.intro = SimState.IntroState.new()
	var mode = su.get("intro", "skip")   # a match that does not say starts from the intro's end state, as the game does
	var req = null   # what to compose, when it plays
	if mode is Dictionary:
		var pl = mode.get("play", true)
		if pl is String and pl == "skip":
			mode = "skip"
		elif pl is bool and pl == false:
			mode = false
		else:
			req = mode
	elif mode is bool and mode == true:
		req = {"classic": true}
	if req != null:
		var c: Dictionary = DirIntro.compose(S, req)   # the director's pick: the scenario, who is first, the gap, the parts
		var it = S.intro
		it.scenario = c.scenario
		it.first = c.first
		it.gap = c.gap
		it.picks = c.picks
		it.clock = c.clock
		it.notes = c.notes
		it.gestures = c.gestures
		it.facts = c.facts   # the record's own, or the data's default when it sent none (DirIntro.compose)
		it.left = it.clock
		for f in S.fighters:
			f.state = "intro"
			f.vx = 0.0
			f.vy = 0.0
			f.y = WorldTerrain.groundY(S, f.x) + fallHeight
	elif mode is String and mode == "skip":
		for k in _order(S):
			_land(S, k)
		_stand(S)


## One step of the sim (SimCore.step, before the pause and the hit-stop). True while the intro runs: the tick is a
## pre-clock tick. inputs is what step was given; only a press on a human slot is read, and only to skip.
static func tick(S: SimState, inputs) -> bool:
	var it = S.intro
	if it.left <= 0:
		return false
	var tp: Dictionary = templates[it.scenario]
	var tl: Dictionary = flatten(it.scenario, it.gap, it.picks)
	var t: int = it.t
	if t == 0:
		SimFx.introStart(S, float(it.clock) / float(TPS), float(skipFrom) / float(TPS), tp.id, it.first, it.gap, String(it.facts.get("plot", "")))
		for n in it.notes:   # the composer's reasons, for the debug feed
			SimEvents.feed(S, n[0], n[1])
		it.notes = []
	var who: Array = [it.first, 1 - it.first]   # the slots by arrival: first, second
	if t >= skipFrom and _pressed(S, inputs):
		for k in who:
			if (it.landed & (1 << k)) == 0:
				_land(S, k)
		it.left = 0
		it.t += 1
		_stand(S)
		SimFx.clockStart(S, "skip")
		return true
	for b in tl.beats:
		if b.t > t:
			break
		if b.t < t:
			continue
		var k: int = slotOf(S, b.role)
		if b.kind == "fall":
			var g: float = WorldTerrain.groundY(S, S.fighters[k].x)
			SimFx.entranceFall(S, S.fighters[k], g, g + fallHeight, float(tl.land[b.role] - b.t) / float(TPS), b.mode)
		elif b.kind == "wait":
			if (it.landed & (1 << k)) != 0:
				S.fighters[k].state = "waiting"   # he stands waiting for the other, until the staredown
				SimFx.introBeat(S, k, "wait", float(tl.staredown - t) / float(TPS))
		elif b.kind == "line":
			var arrival: String = ROLE_NAMES[FIRST if k == it.first else SECOND]
			SimFx.introLine(S, k, b.intent, arrival, lineTags(it.facts, b.intent, [arrival, ROLE_NAMES[LEFT if k == leftSlot(S) else RIGHT]]))
		elif b.kind == "gesture":
			SimFx.introGesture(S, k, b.intent, "part")
		elif b.kind == "staredown":
			for f in S.fighters:
				if f.state == "waiting":
					f.state = "intro"
			SimFx.staredownStart(S, float(it.clock - t) / float(TPS))
	for g in it.gestures:   # the facts' gestures: [tick, slot, intent, point], in time order
		if g[0] == t:
			SimFx.introGesture(S, g[1], g[2], g[3])
	for r in range(who.size()):   # r: 0 the first to arrive, 1 the second
		var k: int = who[r]
		var f = S.fighters[k]
		if (it.landed & (1 << k)) != 0:
			continue
		if t >= tl.land[r]:
			_land(S, k)
		elif t >= tl.fall[r]:
			var p: float = float(t - tl.fall[r] + 1) / float(tl.land[r] - tl.fall[r])
			f.y = WorldTerrain.groundY(S, f.x) + fallHeight * (1.0 - p * p)   # he accelerates down: a closed-form fall, no flight physics
	it.t += 1
	it.left -= 1
	if it.left == 0:
		_stand(S)
		SimFx.clockStart(S, "full")
	return true


## The intro this match plays, for the view (Camera plans its cuts from it at intro_start): {"scenario": the template's
## id, "plot": the facts' plot id, "first": the slot that arrives first, "gap", "clock": its length in ticks, "beats":
## [{t, kind, actor (a slot, or -1), intent, mode, at}] in time order, the facts' gestures among them (kind gesture, at
## their point)}. Empty when the match plays none.
static func timeline(S: SimState) -> Dictionary:
	var it = S.intro
	if it.scenario < 0:
		return {}
	var out: Array = []
	for b in flatten(it.scenario, it.gap, it.picks).beats:
		out.append({"t": b.t, "kind": b.kind, "actor": slotOf(S, b.role), "intent": b.intent, "mode": b.mode, "at": "part" if b.kind == "gesture" else ""})
	for g in it.gestures:
		var at: int = out.size()
		while at > 0 and out[at - 1].t > g[0]:
			at -= 1
		out.insert(at, {"t": g[0], "kind": "gesture", "actor": g[1], "intent": g[2], "mode": "", "at": g[3]})
	return {"scenario": templates[it.scenario].id, "plot": String(it.facts.get("plot", "")), "first": it.first, "gap": it.gap, "clock": it.clock, "beats": out}


## The tags the facts give a voice slot (facts.intents, Narrative's: the sim reads none of them): {stance, angle, event,
## p}. slot is the line's intent; roles are the speaker's names (first or second, and left or right). An entry with
## "lines" holds one row a speaker; a row or an entry that names another "who" is not his. No entry: no tags, p 1.
static func lineTags(facts: Dictionary, slot: String, roles: Array) -> Dictionary:
	var out := {"stance": "", "angle": "", "event": "", "p": 1.0}
	var all = facts.get("intents")
	var e = all.get(slot) if all is Dictionary else null
	if not (e is Dictionary):
		return out
	if e.get("lines") is Array:
		var row = null
		for r in e.lines:
			if r is Dictionary and roles.has(String(r.get("who", ""))):
				row = r
				break
		e = row
	elif e.has("who") and not roles.has(String(e.who)):
		e = null
	if e is Dictionary:
		out.stance = String(e.get("stance", ""))
		out.angle = String(e.get("angle", ""))
		out.event = String(e.get("event", ""))
		var pv = e.get("p", 1.0)
		out.p = clampf(float(pv), 0.0, 1.0) if (pv is float or pv is int) else 1.0
	return out


## The slot a role names in this match, or -1 for both.
static func slotOf(S: SimState, role: int) -> int:
	if role == FIRST:
		return S.intro.first
	if role == SECOND:
		return 1 - S.intro.first
	if role == LEFT:
		return leftSlot(S)
	if role == RIGHT:
		return 1 - leftSlot(S)
	return -1


## The slot on the left start spot.
static func leftSlot(S: SimState) -> int:
	return _order(S)[0]


## Slot k touches down: he is on the ground and the entrance crater is dug under him (World's dig; the start spots are
## open ground, clear of every town, so nobody is hurt). The two craters' records are kept in the order of the start
## spots (left, then right) whoever landed first, so the state at the clock does not depend on the order of arrival.
static func _land(S: SimState, k: int) -> void:
	var f = S.fighters[k]
	var it = S.intro
	var top: float = WorldTerrain.groundY(S, f.x) + fallHeight
	var r: float = 0.0
	if craterE > 0.0:
		var rec = WorldCrater.dig(S, f.x, craterE, null, "impact", 0.0, 1.0)
		if rec != null:
			r = rec.r
			var n: int = S.craters.size()
			if it.dug != 0 and k == leftSlot(S) and n >= 2 and S.craters[n - 1] == rec:   # the left spot's fighter landed second
				S.craters[n - 1] = S.craters[n - 2]
				S.craters[n - 2] = rec
			it.dug |= 1 << k
	f.y = WorldTerrain.groundY(S, f.x)
	it.landed |= 1 << k
	SimFx.entranceLand(S, f, top, r)


## The clock starts: both fighters are free, standing where they landed.
static func _stand(S: SimState) -> void:
	for f in S.fighters:
		f.state = "free"
		f.vx = 0.0
		f.vy = 0.0
		f.y = WorldTerrain.groundY(S, f.x)


## The slots in the order of the start spots: the left one, then the other.
static func _order(S: SimState) -> Array:
	if S.fighters.size() == 2 and S.fighters[1].x < S.fighters[0].x:
		return [1, 0]
	return range(S.fighters.size())


static func _pressed(S: SimState, inputs) -> bool:
	if inputs == null:
		return false
	for k in range(mini(inputs.size(), S.fighters.size())):
		var i = inputs[k]
		if i == null or S.fighters[k].ai != null:
			continue
		if i.light or i.heavy or i.sig or i.guardPress or i.dodge or i.powerPress or i.transform or i.context or i.dash or i.escape:
			return true
	return false
