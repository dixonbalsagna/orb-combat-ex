class_name SimCampaign
extends RefCounted
## The campaign's sim foundation (Game Design's campaign.md 1.1 to 1.4, 2 and 7; docs/architecture/campaign-core.md):
## an episode is a run (SimRun's state, run-core.md section 12) with an arc block, five columns on one planet, and the
## player choosing each column's place by flying there. Behind data/fight/campaign.json's enabled (off): the campaign's
## host uses none of it while it is off.
##
##   the arc block (state.arc): the arc's id (16 hex digits, its seed), its kind (filler_episode, filler_arc,
##                main_episode, main_arc), its villain (a roster fighter: arc_villain), the episode's index, the five
##                columns' place ids and the places taken, the side-story fields, and the open threads, as ids only;
##   the seeds:   the episode seed is H(arc, "episode", e); every draw of a column is mixed from it, so an episode is
##                the same for the same arc, episode and history, on any machine;
##   the columns: a stage won advances the column, and the next column's places come from the episode seed. Until
##                World's places-for-column query lands (campaign-core.md section 4), a stand-in picks them from the
##                planet's standing places;
##   the season:  a small local record beside the run states, the number of the last main-story episode won (Legal
##                mc02: whole numbers, no personal data).
## No fighter reads any of it (Legal mc01 and mc06): the arc block is in the run state, never in a match's setup, and the
## parity check holds that no fighter, director or input file names it.

const FILE: String = "res://data/fight/campaign.json"
const KINDS: Array = ["filler_episode", "filler_arc", "main_episode", "main_arc"]
const MAIN: Array = ["main_episode", "main_arc"]
const MASK: int = 0xFFFFFFFF
const SEASON_FORMAT: String = "meridian-season"
const THREAD_RE: String = "^[A-Za-z0-9_.:-]{1,48}$"   # an id: a roster id, a place id, a short tag; no spaces, no words

static var _d = null
static var _errors: Array = []
static var on_: bool = false
static var columns: int = 5
static var placesMin: int = 2
static var placesMax: int = 3
static var crossFrom: int = 2          # a place not taken in this column can come back ...
static var crossTo: int = 4            # ... in this one, as a consequence (campaign.md 2.2)
static var sideShare: int = 500        # thousandths: a main-story episode won offers a side story on about half
static var arcEpisodes: int = 3
static var families: Array = ["training_day", "rivalry_game", "tournament", "rescue"]
static var stageCols: int = 1200       # the stand-in stage ring round a place (Close), until World's ring turn


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	var j = FighterData._load(FILE, "fight/campaign.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary) or j.get("schema") != "fight.campaign/1":
		_err("fight/campaign.json: missing, or not a fight.campaign/1 object")
		j = {}
	_d = j
	if not (j.get("enabled") is bool):
		_err("fight/campaign.json: enabled must be true or false")
	on_ = j.get("enabled") == true
	columns = _int("columns", j.get("columns"), 1, 9)
	var pc = j.get("placesPerColumn", {})
	placesMin = _int("placesPerColumn.min", pc.get("min") if pc is Dictionary else null, 1, 6)
	placesMax = _int("placesPerColumn.max", pc.get("max") if pc is Dictionary else null, placesMin, 6)
	var cb = j.get("crossBack", {})
	crossFrom = _int("crossBack.from", cb.get("from") if cb is Dictionary else null, 1, columns)
	crossTo = _int("crossBack.to", cb.get("to") if cb is Dictionary else null, crossFrom, columns)
	sideShare = _int("sideShare", j.get("sideShare"), 0, 1000)
	arcEpisodes = _int("arcEpisodes", j.get("arcEpisodes"), 1, 9)
	stageCols = _int("stageCols", j.get("stageCols"), 600, SimConst.PLANET_NC)
	var fam = j.get("families")
	families = []
	if fam is Array:
		for f in fam:
			if f is String:
				families.append(f)
	if families.size() < 2 or not (fam is Array) or families.size() != fam.size():
		_err("fight/campaign.json: families is a list of at least two ids")
		families = ["training_day", "rivalry_game"]


static func enabled() -> bool:
	_ensure()
	return on_


static func errors() -> Array:
	_ensure()
	return _errors


## Tests only: read the file again on the next call.
static func reload() -> void:
	_d = null


# ===================================================================== seeds

## A draw from a 32-bit seed: FNV-1a over the key, then fmix32 over the seed and the two indices, in turn (SimRun.H's mix,
## with one seed word).
static func mix(seed: int, key: String, a: int, b: int) -> int:
	var h: int = 0x811c9dc5
	for i in range(key.length()):
		h = SimRng.imul((h ^ key.unicode_at(i)) & MASK, 0x01000193)
	var x: int = SimRng._fmix((h ^ (seed & MASK)) & MASK)
	x = SimRng._fmix((x ^ SimRng.imul(a & MASK, 0x9E3779B1)) & MASK)
	return SimRng._fmix((x ^ SimRng.imul(b & MASK, 0x85EBCA77)) & MASK)


## The episode seed: H(arc, "episode", e). Every draw of the episode's columns is mixed from it.
static func episodeSeed(arcId: String, e: int) -> int:
	return SimRun.H(arcId, "episode", e, 0)


## The episode's run seed (16 hex digits, SimRun's), for its stages' seeds: two words of the arc's hash.
static func episodeRun(arcId: String, e: int) -> String:
	return "%08x%08x" % [SimRun.H(arcId, "episode", e, 0), SimRun.H(arcId, "episode", e, 1)]


## The arc's planet: one planet for every episode of the arc (campaign.md 2.1).
static func arcPlanet(arcId: String) -> int:
	return SimRun.H(arcId, "planet", 0, 0)


# ===================================================================== the arc block

## A new arc block (campaign.md 1.1 and 1.4). opts: player (the player's fighter id, PROTAGONIST), number (a main-story
## episode's number in the season), follows (the main-story episode a side story follows), villain (a fixed villain, as a
## main story's), family (a filler episode's family).
static func newArc(arcId: String, kind: String, opts: Dictionary = {}) -> Dictionary:
	_ensure()
	var player: String = String(opts.get("player", "PROTAGONIST"))
	var villain: String = String(opts.get("villain", _drawVillain(arcId, player)))
	var fams: Array = []
	if kind == "filler_arc":
		# its first two episodes take two different filler families by the arc's seed; the finale takes the general ones
		var a: int = SimRun.H(arcId, "family", 0, 0) % families.size()
		var b: int = SimRun.H(arcId, "family", 1, 0) % (families.size() - 1)
		fams = [families[a], families[b if b < a else b + 1]]
	elif kind == "filler_episode":
		fams = [String(opts.get("family", families[SimRun.H(arcId, "family", 0, 0) % families.size()]))]
	return {"id": arcId, "kind": kind, "villain": villain, "player": player, "episode": 0,
		"episodes": arcEpisodes if kind == "filler_arc" else 1, "number": int(opts.get("number", 0)), "follows": int(opts.get("follows", -1)),
		"families": fams, "column": 0, "columns": [], "taken": [], "done": false,
		"side": {"offered": false, "place": -1, "family": ""}, "threads": []}


## The villain of a generated arc: a roster or bench fighter whose role is villain or rival, not the player, by the
## arc's seed (sorted ids, so a new fighter never moves an old arc's draw except where he sorts in).
static func _drawVillain(arcId: String, player: String) -> String:
	var pool: Array = []
	for id in FighterData.order() + FighterData.bench():
		if String(id) != player and ["villain", "rival"].has(String(FighterData.def(String(id)).get("role", ""))):
			pool.append(String(id))
	pool.sort()
	if pool.is_empty():
		return ""
	return pool[SimRun.H(arcId, "villain", 0, 0) % pool.size()]


## Episode e of an arc as a run state (SimRun.newRun with the episode's run seed, the arc's planet, and the arc block),
## with its first column's places. opts: mode (story), people (the planet's people, World's census), places (a run
## state's places to start from: the arc's planet as it stands, or a copy for a side story), assist.
static func newEpisode(arc: Dictionary, e: int, P: WorldPlanet.Planet, opts: Dictionary = {}) -> Dictionary:
	_ensure()
	var s: Dictionary = SimRun.newRun(episodeRun(String(arc.id), e), String(opts.get("mode", "story")), String(arc.player), int(opts.get("people", 0)), opts.get("assist", {}))
	s.planet.seed = arcPlanet(String(arc.id))
	if opts.get("places") is Dictionary:
		s.places = opts.places.duplicate(true)
	var a: Dictionary = arc.duplicate(true)
	a.episode = e
	a.column = 0
	a.columns = [columnPlaces(s, a, P, 0)]
	a.taken = []
	a.done = false
	a.side = {"offered": false, "place": -1, "family": ""}
	s["arc"] = a
	return s


## The places of column c (0-based) from the episode seed: World's places-for-column query when it lands, a stand-in
## today. The climax (the last column) is the opponent's home ground; the others take placesMin to placesMax standing
## places the episode has not fought on, and the column crossTo offers crossFrom's untaken places first.
static func columnPlaces(s: Dictionary, arc: Dictionary, P: WorldPlanet.Planet, c: int) -> Array:
	var es: int = episodeSeed(String(arc.id), int(arc.episode))
	var homes: Dictionary = SimRun.homes(P)
	var standing: PackedByteArray = SimRun.groundOpts(s, P).standing
	var taken: Array = arc.taken
	if c == columns - 1:
		var home: int = int(homes.get(String(arc.villain), -1))
		if home >= 0 and standing[home] == 1:
			return [home]
	var pool: Array = []
	for i in range(P.n):
		if standing[i] == 1 and not _has(taken, i):
			pool.append(i)
	# a seeded shuffle of the pool (Fisher-Yates on the column's own draws)
	for k in range(pool.size() - 1, 0, -1):
		var j: int = mix(es, "column", c, k) % (k + 1)
		var t = pool[k]
		pool[k] = pool[j]
		pool[j] = t
	var first: Array = []
	if c == crossTo - 1 and arc.columns.size() >= crossFrom:
		for i in arc.columns[crossFrom - 1]:
			if not _has(taken, int(i)) and standing[int(i)] == 1:
				first.append(int(i))
	var n: int = placesMin + mix(es, "count", c, 0) % (placesMax - placesMin + 1)
	var out: Array = []
	for i in first + pool:
		if out.size() >= n:
			break
		if not out.has(i):
			out.append(i)
	return out


## The next run state after a stage of the episode (SimRun.carry), and a stage won advances the column: the place
## fought (end.place, one of the column's) is taken and the next column's places come from the seed. After the last
## column the episode is done; a main-story episode won may then offer a side story (campaign.md 1.4). A place that is
## not one of the column's is refused: the state comes back unchanged.
static func advance(state: Dictionary, end: Dictionary, P: WorldPlanet.Planet) -> Dictionary:
	_ensure()
	var arc: Dictionary = state.get("arc", {})
	if arc.is_empty() or arc.done:
		return SimRun.carry(state, end)
	var won: bool = end.get("result") == "won"
	var place: int = int(end.get("place", -1))
	if won and not _has(arc.columns[int(arc.column)], place):
		_err("campaign: place %d is not one of column %d's %s" % [place, int(arc.column) + 1, str(arc.columns[int(arc.column)])])
		return state.duplicate(true)
	var s: Dictionary = SimRun.carry(state, end)
	if not won or s.over != "":
		return s
	var a: Dictionary = s.arc
	a.taken.append(place)
	a.column = int(a.column) + 1
	if int(a.column) < columns:
		a.columns.append(columnPlaces(s, a, P, int(a.column)))
	else:
		a.done = true
		if MAIN.has(a.kind):
			a.side = sideOffer(s, a, P)
	return s


## The side story a main-story episode won may offer (campaign.md 1.4): a seeded draw, H(arc, "side", n), on about
## sideShare of them; its place a standing one the episode didn't fight on (World's ring picker places it along the
## ring, within 10 to 25 s of flight, when it lands), and its family one of the filler families.
static func sideOffer(s: Dictionary, arc: Dictionary, P: WorldPlanet.Planet) -> Dictionary:
	var n: int = int(arc.number)
	var d: int = SimRun.H(String(arc.id), "side", n, 0)
	if d % 1000 >= sideShare:
		return {"offered": false, "place": -1, "family": ""}
	var standing: PackedByteArray = SimRun.groundOpts(s, P).standing
	var pool: Array = []
	for i in range(P.n):
		if standing[i] == 1 and not _has(arc.taken, i):
			pool.append(i)
	if pool.is_empty():
		return {"offered": false, "place": -1, "family": ""}
	return {"offered": true, "place": pool[SimRun.H(String(arc.id), "side", n, 1) % pool.size()], "family": families[SimRun.H(String(arc.id), "side", n, 2) % families.size()]}


## The filler episode a side story opens (campaign.md 1.2 and 1.4): its own arc block, following the main-story
## episode it came from (the card reads n.5), on a copy of the main arc's planet as it stands; nothing it does carries
## back (the host keeps the main story's state apart).
static func openSide(main: Dictionary, P: WorldPlanet.Planet, opts: Dictionary = {}) -> Dictionary:
	var arc: Dictionary = main.arc
	if not arc.side.offered:
		_err("campaign: no side story was offered")
		return {}
	var id: String = "%08x%08x" % [SimRun.H(String(arc.id), "side", int(arc.number), 3), SimRun.H(String(arc.id), "side", int(arc.number), 4)]
	var side: Dictionary = newArc(id, "filler_episode", {"player": arc.player, "follows": int(arc.number), "family": String(arc.side.family), "villain": String(opts.get("villain", arc.villain))})
	var s: Dictionary = newEpisode(side, 0, P, {"mode": main.mode, "people": int(main.planet.people), "places": main.places})
	s.planet.seed = int(main.planet.seed)   # the main arc's planet, as it stands
	return s


## The title card's number (campaign.md 1.3): a main-story episode's own number, a side story's "n.5", or "" (SIDE STORY).
static func cardNumber(arc: Dictionary) -> String:
	if MAIN.has(arc.kind):
		return str(int(arc.number))
	if int(arc.follows) >= 0:
		return "%d.5" % int(arc.follows)
	return ""


# ===================================================================== threads

## Open threads are ids only (Legal mc02: about fighters and places' wear, never a toll), short and plain.
static func openThread(state: Dictionary, id: String) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	if not RegEx.create_from_string(THREAD_RE).search(id):
		_err("campaign: a thread id is %s, not '%s'" % [THREAD_RE, id])
	elif not s.arc.threads.has(id):
		s.arc.threads.append(id)
	return s


## A thread closed. Filler never resolves a main-story thread (campaign.md 1.2): "main:" ids stay open in a filler kind.
static func closeThread(state: Dictionary, id: String) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	if id.begins_with("main:") and not MAIN.has(s.arc.kind):
		_err("campaign: filler can't resolve the main-story thread '%s'" % id)
		return s
	s.arc.threads.erase(id)
	return s


# ===================================================================== the season record

## The season record (campaign.md 1.4): the save's small record beside the run states, whole numbers only (mc02).
static func newSeason() -> Dictionary:
	return {"format": SEASON_FORMAT, "v": 1, "lastMain": 0}


## The season after an episode: a main-story episode won to its end moves lastMain up to its number.
static func seasonAfter(season: Dictionary, state: Dictionary) -> Dictionary:
	var out: Dictionary = season.duplicate(true)
	var arc: Dictionary = state.get("arc", {})
	if not arc.is_empty() and MAIN.has(arc.kind) and arc.done and state.over == "":
		out.lastMain = maxi(int(out.lastMain), int(arc.number))
	return out


## Why a season record or an arc block is refused ("" when sound): a header's or a save's check.
static func checkSeason(season) -> String:
	if not (season is Dictionary) or season.get("format") != SEASON_FORMAT or int(season.get("v", 0)) != 1:
		return "not a %s v1" % SEASON_FORMAT
	if not (season.get("lastMain") is int or season.get("lastMain") is float) or int(season.lastMain) < 0:
		return "lastMain is a whole number from 0"
	for k in season:
		if not ["format", "v", "lastMain"].has(k):
			return "a season record holds only format, v and lastMain (mc02), not '%s'" % k
	return ""


static func checkArc(arc) -> String:
	if not (arc is Dictionary) or not KINDS.has(arc.get("kind")):
		return "the kind is one of %s" % str(KINDS)
	if not (arc.get("id") is String) or String(arc.id).length() != 16 or not String(arc.id).is_valid_hex_number(false):
		return "the arc id is 16 hex digits"
	if not (arc.get("columns") is Array) or arc.columns.size() > columns or not (arc.get("taken") is Array) or not (arc.get("threads") is Array):
		return "columns, taken and threads are lists"
	for t in arc.threads:
		if not (t is String) or not RegEx.create_from_string(THREAD_RE).search(t):
			return "a thread is an id only"
	return ""


## A list of place ids holds v (a list read back from JSON holds floats).
static func _has(arr: Array, v: int) -> bool:
	for x in arr:
		if int(x) == v:
			return true
	return false


static func _int(where: String, x, lo: int, hi: int) -> int:
	if not (x is float or x is int) or float(x) != floor(float(x)) or int(x) < lo or int(x) > hi:
		_err("fight/campaign.json: %s is a whole number from %d to %d" % [where, lo, hi])
		return lo
	return int(x)


static func _err(msg: String) -> void:
	_errors.append(msg)
	if not FighterData.quiet:
		push_error("SimCampaign: " + msg)
