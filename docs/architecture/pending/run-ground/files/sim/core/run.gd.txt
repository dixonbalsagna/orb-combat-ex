class_name SimRun
extends RefCounted
## The run (docs/architecture/run-core.md). Built so far: the run's keyed hash H (section 4) and each stage's ground
## (section 11): the ring of the planet the next stage is fought on, picked by World's ring picker (WorldRingPick,
## sim/world/ringpick.gd) from Narrative's claims (data/narrative/opponent_grounds.json), a candidate every few frames
## of the previous stage's beats. Behind data/fight/run.json's ground.enabled (off): the story mode's host asks for
## a stage's ground only with it on.
##
## Nothing here runs in a match's tick, and nothing here is hashed. A pick ends as the stage's setup ({planet, arena}:
## the ring as exact bits), which the stage's header carries, so a stage replays from its header and never picks
## again. A pick is a pure function of the run seed, the chapter, the offer, the opponent and the places' states: the
## same answer on any machine, however many frames it took.
##
## The rules (Game Design's run-mode.md 1.2; Narrative's fallbacks):
##   the first stage: a Close ring round the player's own home (WorldRingPick.firstRing);
##   a stage between: the opponent's claim at its size for the chapter (the data's phases: early, early, mid), Close at
##                a Proving ground, with the opponent's home tried first (WorldRingPick.pick);
##   the boss:    the Whole circle through the boss's home and the most populous place still standing
##                (WorldRingPick.bossRing); with no other place standing, his claim at Whole. The story's ring wins:
##                Whole's minimum is waived while it holds his home and a standing city (Game Design's
##                rulings-2026-10-23.md 4), so the result says `waived` and nothing falls back.
## A run never fights the same ring twice (the EP's ruling): the host passes the rings the run has fought (each
## stage's setup.arena, as its header carries it) as opts.used, and World's picker passes them over (a repeat only
## when nothing else meets even the crude minimum, flagged `repeat`).
## Homes are a stand-in until Orb names them (homework 39): the claims' fighters, in the file's order, take the
## planet's cities by people, most first, then its towns.

const FILE: String = "res://data/fight/run.json"
const CLAIMS: String = "res://data/narrative/opponent_grounds.json"
const MASK: int = 0xFFFFFFFF
const SIZES: Array = ["close", "half", "whole"]

static var _d = null
static var _errors: Array = []
static var _claims: Dictionary = {}
static var _order: Array = []
static var groundOn_: bool = false
static var framesPerRead: Dictionary = {"close": 1, "half": 1, "whole": 3}
static var stages: int = 3
static var phases: Array = ["early", "early", "mid"]
static var provingSize: String = "close"


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	_d = {}
	var j = FighterData._load(FILE, "fight/run.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary) or j.get("schema") != "fight.run/1":
		_err("fight/run.json: missing, or not a fight.run/1 object")
		j = {}
	_d = j
	var g = j.get("ground", {})
	if not (g is Dictionary):
		_err("fight/run.json: ground must be an object")
		g = {}
	if not (g.get("enabled") is bool):
		_err("fight/run.json: ground.enabled must be true or false")
	groundOn_ = g.get("enabled") == true
	var fr = g.get("framesPerRead", {})
	if not (fr is Dictionary):
		_err("fight/run.json: ground.framesPerRead must be an object")
		fr = {}
	framesPerRead = {}
	for sz in SIZES:
		framesPerRead[sz] = _int("ground.framesPerRead." + sz, fr.get(sz), 1, 10)
	stages = _int("ground.stagesBeforeBoss", g.get("stagesBeforeBoss"), 1, 12)
	var ph = g.get("phases")
	phases = []
	if ph is Array:
		for p in ph:
			if p is String and (p == "early" or p == "mid"):
				phases.append(p)
	if phases.is_empty() or not (ph is Array) or phases.size() != ph.size():
		_err("fight/run.json: ground.phases is a list of \"early\" and \"mid\"")
		phases = ["mid"]
	provingSize = String(g.get("provingSize", ""))
	if not SIZES.has(provingSize):
		_err("fight/run.json: ground.provingSize is close, half or whole")
		provingSize = "close"
	_claims = {}
	_order = []
	var c = JSON.parse_string(FileAccess.get_file_as_string(CLAIMS)) if FileAccess.file_exists(CLAIMS) else null
	if c is Dictionary and c.get("claims") is Dictionary:
		_claims = c.claims
		_order = _claims.keys()
	else:
		_err("narrative/opponent_grounds.json: missing, or no claims")


static func groundOn() -> bool:
	_ensure()
	return groundOn_


static func errors() -> Array:
	_ensure()
	return _errors


## Tests only: read the files again on the next call.
static func reload() -> void:
	_d = null


## Narrative's claim for a fighter id ({} for one with none).
static func claim(id: String) -> Dictionary:
	_ensure()
	return _claims.get(id, {})


# ===================================================================== the run's keyed hash

## The run seed's two 32-bit halves. A run seed is 64 bits as 16 hex digits (a JSON number is exact only below 2^53).
static func halves(run: String) -> Array:
	if run.length() != 16 or not run.is_valid_hex_number(false):
		_err("a run seed is 16 hex digits, not '%s'" % run)
		return [0, 0]
	return [run.substr(0, 8).hex_to_int() & MASK, run.substr(8, 8).hex_to_int() & MASK]


## H(run, key, a, b) (run-core.md section 4): every draw a run makes before a match, 32 bits. FNV-1a over the key, then
## fmix32 over the run seed's high half, its low half and the two indices, each in turn.
static func H(run: String, key: String, a: int, b: int) -> int:
	var hl: Array = halves(run)
	var h: int = 0x811c9dc5
	for i in range(key.length()):
		h = SimRng.imul((h ^ key.unicode_at(i)) & MASK, 0x01000193)
	var x: int = SimRng._fmix((h ^ int(hl[0])) & MASK)
	x = SimRng._fmix((x ^ int(hl[1])) & MASK)
	x = SimRng._fmix((x ^ SimRng.imul(a & MASK, 0x9E3779B1)) & MASK)
	return SimRng._fmix((x ^ SimRng.imul(b & MASK, 0x85EBCA77)) & MASK)


## The run's planet: H(run, "planet", 0, 0).
static func planetSeed(run: String) -> int:
	return H(run, "planet", 0, 0)


## A stage's match seed: H(run, "stage", chapter, choice). It leaves the history out (run-core.md section 4).
static func stageSeed(run: String, chapter: int, choice: int) -> int:
	return H(run, "stage", chapter, choice)


# ===================================================================== a stage's ground

## The stand-in homes (until Orb names them, homework 39): fighter id -> place id. The claims' fighters in the file's
## order take the planet's cities by people, most first (ties to the lower id), then its towns; -1 when none is left.
static func homes(P: WorldPlanet.Planet) -> Dictionary:
	_ensure()
	var cities: Array = []
	var towns: Array = []
	for i in range(P.n):
		if P.kind[i] == WorldPlanet.KIND_CITY:
			cities.append(i)
		else:
			towns.append(i)
	var most := func(a: int, b: int) -> bool: return P.people[a] > P.people[b] or (P.people[a] == P.people[b] and a < b)
	cities.sort_custom(most)
	towns.sort_custom(most)
	var pool: Array = cities + towns
	var out: Dictionary = {}
	for k in range(_order.size()):
		out[_order[k]] = int(pool[k]) if k < pool.size() else -1
	return out


## Which rule picks a chapter's ground: "first" (chapter 1), "boss" (past the stages before the boss), else "claim".
static func ruleOf(chapter: int) -> String:
	_ensure()
	if chapter <= 1:
		return "first"
	return "boss" if chapter > stages else "claim"


## A chapter's ring size for an opponent: Close for the first stage and a Proving ground ("proving"), Whole for the
## boss, else his claim's size for the chapter's phase.
static func sizeFor(opponent: String, chapter: int, kind: String = "") -> String:
	_ensure()
	var rule: String = ruleOf(chapter)
	if rule == "first":
		return "close"
	if rule == "boss":
		return "whole"
	if kind == "proving":
		return provingSize
	var phase: String = String(phases[mini(chapter - 1, phases.size() - 1)])
	var sz = claim(opponent).get("size", {}).get(phase) if claim(opponent).get("size") is Dictionary else null
	return String(sz) if sz is String and SIZES.has(sz) else "half"


## The next stage's ground, to be stepped (GroundJob.step, or frame() once a frame for the data's pace) during the
## previous stage's beats, or picked at once (finishNow). opts: player (the player's fighter id, PROTAGONIST), choice
## (the offer's index, 0), kind ("proving" for a Proving ground), standing (a byte a place, 0 for a fallen one; empty:
## all stand), damaged (place ids hurt earlier in the run), used (the rings the run has fought: each stage's
## setup.arena, or a spec; WorldRingPick.usedList), homes (fighter id -> place id, in place of the stand-in).
static func beginGround(run: String, chapter: int, opponent: String, opts: Dictionary = {}) -> GroundJob:
	_ensure()
	var g := GroundJob.new()
	g.run = run
	g.chapter = chapter
	g.choice = int(opts.get("choice", 0))
	g.opponent = opponent
	g.planet = planetSeed(run)
	g.P = WorldPlanet.make(g.planet)
	g.standing = opts.get("standing", PackedByteArray())
	g.damaged = opts.get("damaged", [])
	g.used = opts.get("used", [])
	var hm: Dictionary = opts.get("homes", homes(g.P))
	g.rule = ruleOf(chapter)
	g.size = sizeFor(opponent, chapter, String(opts.get("kind", "")))
	var stream: int = H(run, "ground", chapter, g.choice)
	if g.rule == "first":
		g.home = int(hm.get(String(opts.get("player", "PROTAGONIST")), -1))
		if g.home >= 0:
			g.spec = WorldRingPick.firstRing(g.P, g.home, stream)
			g.spec["kind"] = "round"   # a ring round a place holds it (WorldRingPick.evalRing)
			g.spec["place"] = g.home
	elif g.rule == "boss":
		g.home = int(hm.get(opponent, -1))
		var b = WorldRingPick.bossRing(g.P, g.home, g.standing) if g.home >= 0 else null
		if b != null:
			g.spec = b
			g.spec["place"] = g.home
	if g.spec.is_empty():
		g.rule = "boss_claim" if g.rule == "boss" else "claim"
		g.home = int(hm.get(opponent, -1))
		g.job = WorldRingPick.beginPick(g.P, claim(opponent), g.size, stream, {"home": g.home, "standing": g.standing, "damaged": g.damaged, "used": g.used})
	return g


## A stage's ground in steps. The reads are pure and the choice is made over them all at the end, so the answer is
## the same however it is stepped (the host owns the clock; this owns none).
class GroundJob extends RefCounted:
	var run: String = ""
	var chapter: int = 0
	var choice: int = 0
	var opponent: String = ""
	var rule: String = ""
	var size: String = ""
	var planet: int = 0
	var home: int = -1
	var P: WorldPlanet.Planet
	var spec: Dictionary = {}                 # the first or the boss's ring (read once, for the report)
	var job: WorldRingPick.PickJob = null      # a claim's pick
	var standing := PackedByteArray()
	var damaged: Array = []
	var used: Array = []
	var reads: int = 0
	var frames: int = 0
	var done: bool = false
	var result: Dictionary = {}

	## Reads up to n more candidates; true when the ground is picked.
	func step(n: int) -> bool:
		if done or n <= 0:
			return done
		if job != null:
			var before: int = job.evs.size()
			done = job.step(n)
			reads += job.evs.size() - before
			if done:
				result = job.result
				result["waived"] = false
			return done
		var ev: Dictionary = WorldRingPick.evalRing(P, spec, standing, damaged)
		reads += 1
		var sc: Dictionary = WorldRingPick.score(ev, SimRun.claim(opponent), home)
		var ok: bool = WorldRingPick.meets(ev, size)
		var me: Dictionary = {"c": spec.c, "cols": int(spec.cols), "kind": str(spec.get("kind", "")), "place": int(spec.get("place", -1))}
		result = {"ok": ok, "spec": {"c": spec.c, "t": spec.t, "cols": spec.cols}, "score": sc.score, "must": sc.must, "home": sc.home,
			"relaxed": false, "kind": rule, "place": home, "ev": ev, "idx": -1, "tried": 1,
			"repeat": WorldRingPick.usedMatch(me, WorldRingPick.usedList(used)), "waived": rule == "boss" and not ok and SimRun.bossWaived(ev, home)}
		done = true
		return done

	## The host calls it once a frame during the beats: a candidate on the first frame and every framesPerRead[size]
	## frames after (World: a Whole read costs about four Close ones).
	func frame() -> bool:
		frames += 1
		if (frames - 1) % int(SimRun.framesPerRead.get(size, 1)) != 0:
			return done
		return step(1)

	## Whatever is left, at once (the beats ended first).
	func finishNow() -> void:
		step(1 << 30)

	## The stage's setup: the planet and the ring as exact bits, for its header (the match reads nothing else of this).
	func setup() -> Dictionary:
		return {"planet": planet, "arena": WorldRingPick.arenaOf(result.spec)}

	## The stage's match seed.
	func matchSeed() -> int:
		return SimRun.stageSeed(run, chapter, choice)


## Game Design's waiver (rulings-2026-10-23.md 4): the boss's ring stands under Whole's minimum while it holds his
## home and at least one standing city.
static func bossWaived(ev: Dictionary, home: int) -> bool:
	var homeHeld: bool = false
	var city: bool = false
	for h in ev.held:
		if int(h.id) == home:
			homeHeld = true
		if int(h.kind) == WorldPlanet.KIND_CITY and not h.fallen:
			city = true
	return homeHeld and city


static func _int(where: String, x, lo: int, hi: int) -> int:
	if not (x is float or x is int) or float(x) != floor(float(x)) or int(x) < lo or int(x) > hi:
		_err("fight/run.json: %s is a whole number from %d to %d" % [where, lo, hi])
		return lo
	return int(x)


static func _err(msg: String) -> void:
	_errors.append(msg)
	if not FighterData.quiet:
		push_error("SimRun: " + msg)
