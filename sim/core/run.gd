class_name SimRun
extends RefCounted
## The run (docs/architecture/run-core.md). Built so far: the run's keyed hash H (section 4), the run state and its
## carry (section 12: newRun, stateHash, carry, the chain, groundOpts), and each stage's ground
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
##   the first stage: a Close ring round the player's own home, turned toward land when it is under Close's minimum
##                with the home kept on it (WorldRingPick.beginFirstRing; Game Design's rulings-2026-10-23.md 6);
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
const MODES: Array = ["story", "standard", "hard"]
const CAUSES: Array = ["player", "opponent", "other"]
const STATE_FORMAT: String = "meridian-run-state"

static var _d = null
static var _errors: Array = []
static var _claims: Dictionary = {}
static var _order: Array = []
static var groundOn_: bool = false
## Planet units (a climate cell, about 20 microseconds; a place's try-set is 1000) spent on the planet's own make for each read a host asks of the ground, when the planet is not made yet (WorldPlanet.makeJob):
## about 5 ms a read, so a gen 2 planet (about a second) is made over the first beats of the stage before it, a frame at a time, and the pick starts when it is whole.
const PLANET_UNITS_PER_READ: int = 250
static var framesPerRead: Dictionary = {"close": 1, "half": 1, "whole": 3}
static var stages: int = 3
static var phases: Array = ["early", "early", "mid"]
static var provingSize: String = "close"
static var damagedShare: int = 50       # thousandths: a place lost this share of its buildings or people is damaged
static var fallenShare: int = 400       # thousandths: under this share of its buildings standing or people present, fallen
static var livesStart: Dictionary = {"story": 2, "standard": 1, "hard": 0}
static var livesMax: int = 3
static var fillsKeep: int = 500         # thousandths of a fill carried to the next fight
static var dreadDivisor: int = 400      # thousandths: Dread is the villains' kills' share of the planet's people over this


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
	var cy = j.get("carry", {})
	if not (cy is Dictionary):
		_err("fight/run.json: carry must be an object")
		cy = {}
	damagedShare = _int("carry.damagedShare", cy.get("damagedShare"), 1, 1000)
	fallenShare = _int("carry.fallenShare", cy.get("fallenShare"), 1, 1000)
	livesMax = _int("carry.livesMax", cy.get("livesMax"), 0, 9)
	var ls = cy.get("livesStart", {})
	livesStart = {}
	for m in MODES:
		livesStart[m] = _int("carry.livesStart." + m, ls.get(m) if ls is Dictionary else null, 0, livesMax)
	fillsKeep = _int("carry.fillsKeep", cy.get("fillsKeep"), 0, 1000)
	dreadDivisor = _int("carry.dreadDivisor", cy.get("dreadDivisor"), 1, 1000)
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
	g.opts = opts
	g.pj = WorldPlanet.makeJob(g.planet)
	if g.pj.done:   # made already: the ground starts here, as it always did
		g.start()
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
	var opts: Dictionary = {}
	var pj: WorldPlanet.PlanetJob = null       # the planet being made in steps, until it is whole (null once the ground has started)
	var spec: Dictionary = {}                 # the first or the boss's ring (read once, for the report)
	var job: WorldRingPick.PickJob = null      # a claim's pick
	var first: WorldRingPick.FirstJob = null   # the first stage's ring
	var standing := PackedByteArray()
	var damaged: Array = []
	var used: Array = []
	var reads: int = 0
	var frames: int = 0
	var done: bool = false
	var result: Dictionary = {}

	## The ground's start, once the planet is whole (beginGround when it already is, else the first step after the planet's job finishes).
	func start() -> void:
		pj = null
		P = WorldPlanet.make(planet)
		standing = opts.get("standing", PackedByteArray())
		damaged = opts.get("damaged", [])
		used = opts.get("used", [])
		var hm: Dictionary = opts.get("homes", SimRun.homes(P))
		rule = SimRun.ruleOf(chapter)
		size = SimRun.sizeFor(opponent, chapter, String(opts.get("kind", "")))
		var stream: int = SimRun.H(run, "ground", chapter, choice)
		if rule == "first":
			home = int(hm.get(String(opts.get("player", "PROTAGONIST")), -1))
			if home >= 0:   # stepped like the others: one read, 13 when the ring is turned toward land
				first = WorldRingPick.beginFirstRing(P, home, stream, {"standing": standing, "damaged": damaged})
		elif rule == "boss":
			home = int(hm.get(opponent, -1))
			var b = WorldRingPick.bossRing(P, home, standing) if home >= 0 else null
			if b != null:
				spec = b
				spec["place"] = home
		if spec.is_empty() and first == null:
			rule = "boss_claim" if rule == "boss" else "claim"
			home = int(hm.get(opponent, -1))
			job = WorldRingPick.beginPick(P, SimRun.claim(opponent), size, stream, {"home": home, "standing": standing, "damaged": damaged, "used": used})

	## Reads up to n more candidates; true when the ground is picked. While the planet is still being made the reads go to it (PLANET_UNITS_PER_READ each) and nothing is picked until it is whole (the same call then goes on to the pick, so finishNow still finishes).
	func step(n: int) -> bool:
		if done or n <= 0:
			return done
		if pj != null:
			if not pj.step(n * SimRun.PLANET_UNITS_PER_READ):
				return false
			start()
		if job != null:
			var before: int = job.evs.size()
			done = job.step(n)
			reads += job.evs.size() - before
			if done:
				result = job.result
				result["waived"] = false
			return done
		while first != null and not first.done and n > 0:
			first.step(1)
			reads += 1
			n -= 1
		if first != null and spec.is_empty():
			if not first.done or n <= 0:
				return done
			spec = first.spec.duplicate()
			spec["place"] = home   # on the ring, round or through it (a round ring's centre counts as held)
		var ev: Dictionary = WorldRingPick.evalRing(P, spec, standing, damaged)
		reads += 1
		var sc: Dictionary = WorldRingPick.score(ev, SimRun.claim(opponent), home)
		var ok: bool = WorldRingPick.meets(ev, size)
		var me: Dictionary = {"c": spec.c, "cols": int(spec.cols), "kind": str(spec.get("kind", "")), "place": int(spec.get("place", -1))}
		result = {"ok": ok, "spec": {"c": spec.c, "t": spec.t, "cols": spec.cols}, "score": sc.score, "must": sc.must, "home": sc.home,
			"relaxed": false, "kind": rule, "place": home, "ev": ev, "idx": -1, "tried": 1, "turned": bool(spec.get("turned", false)),
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


# ===================================================================== the run state (run-core.md section 12)

## A new run's state (run-core.md section 12; Game Design's run-mode.md 7): whole numbers and short strings only, so it
## is exact in JSON and hashes the same on any machine. people: the planet's people at the run's start (World's
## census), the measure of Dread. assist: {"endless": true} for the Endless retries assist (lives are never spent).
static func newRun(run: String, mode: String, fighter: String, people: int, assist: Dictionary = {}) -> Dictionary:
	_ensure()
	return {"format": STATE_FORMAT, "v": 1, "run": run, "mode": mode, "endless": assist.get("endless", false) == true,
		"chapter": 1, "planet": {"seed": planetSeed(run), "people": people}, "places": {},
		"player": {"fighter": fighter, "ceiling": 0, "boons": [], "fills": {"witness": 0, "trial": 0}, "branches": [], "wounds": [0, 0, 0, 0],
			"lives": int(livesStart.get(mode, 0)), "livesSpent": 0},
		"villainKills": 0, "dread": 0, "sky": 0, "ledger": [], "over": ""}


## The run state's hash: the core's canonical walk (dictionaries by sorted key, every value tagged, a whole float the
## same number as its int), so a state that has been through JSON hashes as it did.
static func stateHash(state: Dictionary) -> String:
	var h := SimHash.Hasher.new()
	h.text(STATE_FORMAT)
	FighterData._canon(h, state)
	return h.hex()


## Why a stage header's run state is refused (run-core.md section 3), or "" when it is a run state.
static func checkState(state) -> String:
	if not (state is Dictionary) or state.get("format") != STATE_FORMAT or int(state.get("v", 0)) != 1:
		return "not a %s v1" % STATE_FORMAT
	if not (state.get("run") is String) or String(state.run).length() != 16 or not String(state.run).is_valid_hex_number(false):
		return "the run seed is 16 hex digits"
	if not MODES.has(state.get("mode")):
		return "the mode is story, standard or hard"
	if not (state.get("chapter") is int or state.get("chapter") is float) or int(state.chapter) < 1:
		return "the chapter is a whole number from 1"
	for k in ["planet", "places", "player"]:
		if not (state.get(k) is Dictionary):
			return "%s is an object" % k
	if not (state.get("ledger") is Array):
		return "the ledger is a list"
	return ""


## The next run state from a stage's end (run-mode.md 1.3, 1.4, 4.1, 5.2): a pure function, the input left as it was.
## `end` (run-core.md section 12), as the host hands it:
##   result "won" or "lost"; opponent (roster id), villain (his kills count toward Dread), offer (rampage, proving,
##   crossing, first, boss), ticks, how, finisher; arena (the ring fought: setup.arena, so the run never fights it again);
##   the player at the fight's end: wounds (a stage a region, 0 fresh to 3 broken), fills {witness, trial} (thousandths of
##   each meter), branches; ash (thousandths); places {"<id>": {buildings (in the place), people (at the run's start),
##   down (buildings down in all, at the end), dead {player, opponent, other} (this fight's), fled (this fight's), wear
##   (World's list for the place, whole, as the slice ends it)}}; boon {kind (form, ability, lifeline, rest, or a rare
##   boon's id), id} taken after a won fight, or none.
static func carry(state: Dictionary, end: Dictionary) -> Dictionary:
	_ensure()
	var s: Dictionary = state.duplicate(true)
	if s.over != "":
		return s
	var pl: Dictionary = s.player
	if end.get("result") != "won":
		# a lost fight is retried from its start, the run state as it began (run-mode.md 4.1): a life is spent
		if s.endless:
			pl.livesSpent = int(pl.livesSpent) + 1
		elif int(pl.lives) > 0:
			pl.lives = int(pl.lives) - 1
			pl.livesSpent = int(pl.livesSpent) + 1
		else:
			s.over = "lost"
			s.ledger.append(_record(s, end))
		return s
	# the places: the dead stay dead, those who fled a standing place come home, those who fled a fallen one are gone
	var ps: Dictionary = end.get("places", {})
	var keys: Array = ps.keys()
	keys.sort_custom(func(a, b): return int(a) < int(b))   # place ids in number order
	var fell: Array = []
	for k in keys:
		var e: Dictionary = ps[k]
		var id: String = str(int(k)) if (k is int or k is float) else String(k)
		var p: Dictionary = s.places.get(id, {"buildings": 0, "people": 0, "down": 0, "dead": {"player": 0, "opponent": 0, "other": 0}, "gone": 0, "status": "fresh", "changed": 0, "wear": []})
		p.buildings = maxi(int(p.buildings), int(e.get("buildings", 0)))
		p.people = maxi(int(p.people), int(e.get("people", 0)))
		p.down = maxi(int(p.down), int(e.get("down", 0)))
		var dead: Dictionary = e.get("dead", {})
		for c in CAUSES:
			p.dead[c] = int(p.dead[c]) + int(dead.get(c, 0))
		if e.has("wear"):
			p.wear = e.wear.duplicate(true)
		var fled: int = int(e.get("fled", 0))
		var deadAll: int = int(p.dead.player) + int(p.dead.opponent) + int(p.dead.other)
		var present: int = int(p.people) - deadAll - int(p.gone) - fled
		var st: String = "fresh"
		if (int(p.buildings) > 0 and (int(p.buildings) - int(p.down)) * 1000 < fallenShare * int(p.buildings)) or (int(p.people) > 0 and present * 1000 < fallenShare * int(p.people)):
			st = "fallen"
		elif (int(p.buildings) > 0 and int(p.down) * 1000 >= damagedShare * int(p.buildings)) or (int(p.people) > 0 and (deadAll + int(p.gone)) * 1000 >= damagedShare * int(p.people)):
			st = "damaged"
		if st == "fallen" or p.status == "fallen":
			p.gone = int(p.gone) + fled   # fled a fallen place: gone for good
		if ["fresh", "damaged", "fallen"].find(st) > ["fresh", "damaged", "fallen"].find(p.status):
			if st == "fallen":
				fell.append(int(id))
			p.status = st
			p.changed = int(s.chapter)
		s.places[id] = p
		if end.get("villain", false) == true:
			s.villainKills = int(s.villainKills) + int(dead.get("opponent", 0))
	# the player (run-mode.md 1.3): every region heals one stage, a rest heals all; his fills at half; his branches
	var w: Array = end.get("wounds", [0, 0, 0, 0])
	var broken: bool = false
	var wn: Array = []
	for r in range(4):
		var x: int = int(w[r]) if r < w.size() else 0
		broken = broken or x >= 3
		wn.append(maxi(0, x - 1))
	var boon = end.get("boon", null)
	var kind: String = String(boon.get("kind", "")) if boon is Dictionary else ""
	if end.get("offer") == "crossing" or kind == "rest":
		wn = [0, 0, 0, 0]
	pl.wounds = wn
	var fl: Dictionary = end.get("fills", {})
	pl.fills = {"witness": int(fl.get("witness", 0)) * fillsKeep / 1000, "trial": int(fl.get("trial", 0)) * fillsKeep / 1000}
	pl.branches = Array(end.get("branches", [])).duplicate(true)
	# lives (run-mode.md 4.1): a clean win and a lifeline each give one, three at most; the boons (1.4)
	if not broken:
		pl.lives = mini(livesMax, int(pl.lives) + 1)
	if kind == "lifeline":
		pl.lives = mini(livesMax, int(pl.lives) + 1)
	elif kind == "form":
		pl.ceiling = int(pl.ceiling) + 1
	elif kind != "" and kind != "rest":
		pl.boons.append(String(boon.get("id", kind)))
	# Dread (run-mode.md 5.2): the villains' kills' share of the planet's people, over dreadDivisor, at most 1
	var people: int = int(s.planet.people)
	s.dread = mini(1000, int(s.villainKills) * 1000000 / (people * dreadDivisor)) if people > 0 else 0
	s.sky = int(end.get("ash", s.sky))
	var rec: Dictionary = _record(s, end)
	rec["fell"] = fell
	s.ledger.append(rec)
	s.chapter = int(s.chapter) + 1
	return s


## A stage's line in the ledger: facts, whole numbers and ids (the beat picker reads its bands from them).
static func _record(s: Dictionary, end: Dictionary) -> Dictionary:
	var dead := {"player": 0, "opponent": 0, "other": 0}
	var ps: Dictionary = end.get("places", {})
	for k in ps:
		var d: Dictionary = ps[k].get("dead", {})
		for c in CAUSES:
			dead[c] = int(dead[c]) + int(d.get(c, 0))
	var rec: Dictionary = {"chapter": int(s.chapter), "offer": String(end.get("offer", "")), "opponent": String(end.get("opponent", "")), "result": String(end.get("result", "")),
		"how": String(end.get("how", "")), "finisher": String(end.get("finisher", "")), "ticks": int(end.get("ticks", 0)), "dead": dead}
	if end.get("arena") is Dictionary:
		rec["arena"] = end.arena.duplicate(true)
	return rec


## The chain through the stage headers (run-core.md section 4): link(0) = H(run, "run"); a stage's next link hashes
## its link, the hash of the run state it started from, its final gameplay hash and the hash of the state it ended in.
## The link travels in the header's run block, not in the state (a state can't hold its own hash).
static func link0(run: String) -> String:
	return "%08x" % H(run, "run", 0, 0)


static func nextLink(link: String, startHash: String, finalHash: String, endHash: String) -> String:
	var h := SimHash.Hasher.new()
	h.text("link")
	for x in [link, startHash, finalHash, endHash]:
		h.text(x)
	return h.hex()


## beginGround's inputs from the run's history: standing (a byte a place of P, 0 for a fallen one), damaged (the place
## ids no longer fresh, in order) and used (the ring of every fight won: a run never fights one twice).
static func groundOpts(state: Dictionary, P: WorldPlanet.Planet) -> Dictionary:
	var standing := PackedByteArray()
	standing.resize(P.n)
	standing.fill(1)
	var damaged: Array = []
	for k in state.places:
		var i: int = int(k)
		if i < 0 or i >= P.n:
			continue
		if state.places[k].status == "fallen":
			standing[i] = 0
		if state.places[k].status != "fresh":
			damaged.append(i)
	damaged.sort()
	var used: Array = []
	for rec in state.ledger:
		if rec.get("result") == "won" and rec.get("arena") is Dictionary:
			used.append(rec.arena)
	return {"standing": standing, "damaged": damaged, "used": used}


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
