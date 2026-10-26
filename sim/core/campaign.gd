class_name SimCampaign
extends RefCounted
## The campaign's sim foundation (Game Design's campaign.md 1.1 to 1.4, 2 and 7; docs/architecture/campaign-core.md):
## an episode is a run (SimRun's state, run-core.md section 12) with an arc block, five columns on one planet, and the
## pair choosing each column's place by flying there. The places, the ring and its turns are World's (WorldCampaign,
## docs/world/campaign-route.md); the seeds, the state and the route's bookkeeping are here. Behind
## data/fight/campaign.json's enabled (off), the one switch: the campaign's host uses none of it while it is off.
##
##   the arc block (state.arc): the arc's id (16 hex digits, its seed), its kind (filler_episode, filler_arc,
##                main_episode, main_arc), its villain (a roster fighter: arc_villain), the episode's index, each
##                column's sites as World offered them and the site flown to, the ring the pair fly and their column on
##                it, the run's wear (place state, World's bands) and the places used, the side-story fields, and the
##                open threads, as ids only;
##   the seeds:   the episode seed is H(arc, "episode", e) (World's epSeed); every draw of the route comes from it or
##                from the arc's own;
##   the columns: the host steps World's column job (beginColumn: a ring's read a frame) during the beats before the
##                column, and columnDone keeps its answer; a stage won at one of its sites advances the column;
##   the season:  a small local record beside the run states, the number of the last main-story episode won (Legal
##                mc02: whole numbers, no personal data).
## No fighter reads any of it (Legal mc01 and mc06): the arc block is in the run state; a stage's setup carries the
## planet, the ring, the wear and the slots only; and the parity check holds that no fighter, director or input file
## names it.

const FILE: String = "res://data/fight/campaign.json"
const KINDS: Array = ["filler_episode", "filler_arc", "main_episode", "main_arc"]
const MAIN: Array = ["main_episode", "main_arc"]
const MASK: int = 0xFFFFFFFF
const SEASON_FORMAT: String = "meridian-season"
const THREAD_RE: String = "^[A-Za-z0-9_.:-]{1,48}$"   # an id: a roster id, a place id, a short tag; no spaces, no words
const SITE_KEYS: Array = ["id", "kind", "place", "arc", "entry", "dir", "preferred"]   # a site as the run state keeps it: whole numbers and short strings

static var _d = null
static var _errors: Array = []
static var on_: bool = false
static var columns: int = 5
static var sideShare: int = 500        # thousandths: a main-story episode won offers a side story on about half
static var arcEpisodes: int = 3
static var families: Array = ["training_day", "rivalry_game", "tournament", "rescue"]
static var crossFrom: int = 2        # the cross-back (campaign.md 2.2): column crossFrom's untaken place is asked again at column crossTo
static var crossTo: int = 4
static var ringCols: int = 2400        # the episode's first ring round the player's home (Half: a column's band, 322 to 806 columns each way, fits it)


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
	sideShare = _int("sideShare", j.get("sideShare"), 0, 1000)
	arcEpisodes = _int("arcEpisodes", j.get("arcEpisodes"), 1, 9)
	ringCols = _int("ringCols", j.get("ringCols"), 600, SimConst.PLANET_NC)
	var cb = j.get("crossBack")
	if not (cb is Dictionary):
		cb = {}
	crossFrom = _int("crossBack.from", cb.get("from"), 1, 9)
	crossTo = _int("crossBack.to", cb.get("to"), 1, 9)
	if crossTo <= crossFrom or crossTo >= columns:
		_err("fight/campaign.json: crossBack.to is after crossBack.from and before the climax")
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


## The episode seed: H(arc, "episode", e), World's epSeed. Every draw of the episode's route is mixed from it.
static func episodeSeed(arcId: String, e: int) -> int:
	return SimRun.H(arcId, "episode", e, 0)


## The episode's run seed (16 hex digits, SimRun's), for its stages' seeds: two words of the arc's hash.
static func episodeRun(arcId: String, e: int) -> String:
	return "%08x%08x" % [SimRun.H(arcId, "episode", e, 0), SimRun.H(arcId, "episode", e, 1)]


## The arc's planet: one planet for every episode of the arc (campaign.md 2.1).
static func arcPlanet(arcId: String) -> int:
	return SimRun.H(arcId, "planet", 0, 0)


## The arc's 32-bit seed, for World's side story.
static func arcSeed(arcId: String) -> int:
	return SimRun.H(arcId, "arc", 0, 0)


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
		"families": fams, "column": 0, "columns": [], "taken": [], "done": false, "ring": {}, "pc": 0, "resize": false, "turns": [], "rings": [], "back": -1,
		"wear": {}, "used": [], "side": {"offered": false, "place": -1, "family": "", "ring": {}, "how": "", "turn": 0}, "threads": []}


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


## The episode's first ring: ringCols round the player's home (World's homes when Orb names them; SimRun's stand-in
## today), its touch-down on a bearing from the episode seed. The pair start at its middle.
static func firstRing(arc: Dictionary, P: WorldPlanet.Planet) -> Dictionary:
	var home: int = int(SimRun.homes(P).get(String(arc.player), 0))
	var phi: float = float(mix(episodeSeed(String(arc.id), int(arc.episode)), "first", 0, 0)) / 4294967296.0 * SimMathx.TAU
	return WorldRingPick.arenaOf(WorldRingPick.roundSpec(WorldRingPick.placePoint(P, home), ringCols, phi))


## Episode e of an arc as a run state (SimRun.newRun with the episode's run seed, the arc's planet, and the arc block).
## Its columns come from World's job, a column at a time (beginColumn, columnDone). opts: mode (story), people (the
## planet's people, World's census), places (a run state's places to start from), wear (the arc's place state as it
## stands), ring and pc (the ring and the pair's column to start on: a side story's), assist.
static func newEpisode(arc: Dictionary, e: int, P: WorldPlanet.Planet, opts: Dictionary = {}) -> Dictionary:
	_ensure()
	var s: Dictionary = SimRun.newRun(episodeRun(String(arc.id), e), String(opts.get("mode", "story")), String(arc.player), int(opts.get("people", 0)), opts.get("assist", {}))
	s.planet.seed = arcPlanet(String(arc.id))
	if opts.get("places") is Dictionary:
		s.places = opts.places.duplicate(true)
	var a: Dictionary = arc.duplicate(true)
	a.episode = e
	a.column = 0
	a.columns = []
	a.taken = []
	a.done = false
	a.turns = []
	a.rings = []
	a.back = -1
	a.used = []
	a.wear = opts.wear.duplicate(true) if opts.get("wear") is Dictionary else {}
	a.side = {"offered": false, "place": -1, "family": "", "ring": {}, "how": "", "turn": 0}
	a.ring = opts.ring.duplicate(true) if opts.get("ring") is Dictionary else firstRing(a, P)
	a.pc = int(opts.get("pc", int(a.ring.cols) / 2))
	a.resize = false
	s["arc"] = a
	return s


## The climax's home (the column World pins): the villain's home ground.
static func climaxHome(arc: Dictionary, P: WorldPlanet.Planet) -> int:
	return int(SimRun.homes(P).get(String(arc.villain), -1))


## The arc's planet, loaded before its first episode (SimPlanetLoad, planet-load.md): the host steps it a slice a frame
## from the moment the arc is known (while the pair are picked: Game Design's rulings-2026-10-26 item 27), then
## WorldPlanet.make finds it made for newEpisode and the columns. Every episode of the arc, and its side stories, fly it.
static func beginLoad(arcId: String) -> SimPlanetLoad.Job:
	return SimPlanetLoad.begin(arcPlanet(arcId))


## The current column's job (World's WorldCampaign.beginColumn): the host steps it a ring's read a frame during the
## beats before the column (500 ms at once on a gen 2 planet), and hands the result to columnDone. With
## SimPlanetLoad.strict on (the game's host), a gen 2 planet not made is refused (null): the host loads it first.
static func beginColumn(state: Dictionary, P: WorldPlanet.Planet) -> WorldCampaign.ColumnJob:
	var seed: int = int(state.planet.seed)
	if SimPlanetLoad.strict and WorldClimate.genNow() >= 2 and not SimPlanetLoad.ready(seed, WorldClimate.genNow()):   # never made cold in a column's job
		SimPlanetLoad.refused += 1
		_err("campaign: planet %d is not made: load it first (SimCampaign.beginLoad)" % seed)
		return null
	var a: Dictionary = state.arc
	var used: Array = []
	for u in a.used:
		used.append(int(u))
	var opts: Dictionary = {"used": used, "wear": a.wear, "pin": climaxHome(a, P), "turn": true}
	if int(a.column) + 1 == crossTo and crossBackPlace(a) >= 0:
		opts["prefer"] = crossBackPlace(a)   # the cross-back: World offers it, leading the sites, when it stands in the band of a ring
	return WorldCampaign.beginColumn(int(state.planet.seed), episodeSeed(String(a.id), int(a.episode)), int(a.column) + 1, a.ring, int(a.pc), opts)


## The cross-back's place (campaign.md 2.2): the first named place column crossFrom offered that the pair did not take,
## nor took in any column before crossTo, in World's order; or -1 (that column is not played yet, or offered no other
## place). It reads only the columns before crossTo, so it is the same answer at column crossTo and after the episode.
static func crossBackPlace(arc: Dictionary) -> int:
	if arc.columns.size() < crossFrom or arc.taken.size() < crossFrom:
		return -1
	var used: Array = []
	for c in range(mini(crossTo - 1, arc.taken.size())):
		var t: Dictionary = siteOf(arc, c, int(arc.taken[c]))
		if not t.is_empty() and int(t.place) >= 0:
			used.append(int(t.place))
	for site in arc.columns[crossFrom - 1]:
		if int(site.place) >= 0 and int(site.id) != int(arc.taken[crossFrom - 1]) and not used.has(int(site.place)):
			return int(site.place)
	return -1


## World's answer for the current column into the state: its sites (as whole numbers and short strings), the ring the
## pair fly from here (World's start: after any turn, its touch-down at the pair) and their column on it, the column's
## ring length (its sites lie on it), whether the stage needs a match of another length (the climax's whole circle),
## the turn's degrees, and at column crossTo the place the cross-back asked (back; World marks it preferred if offered).
static func columnDone(state: Dictionary, res: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	var a: Dictionary = s.arc
	if a.done or a.columns.size() != int(a.column):
		_err("campaign: column %d is already made, or the episode is done" % (int(a.column) + 1))
		return s
	if int(a.column) + 1 == crossTo:
		a.back = crossBackPlace(a)
	var sites: Array = []
	for site in res.get("sites", []):
		var keep: Dictionary = {}
		for k in SITE_KEYS:
			keep[k] = String(site.get(k, "")) if k == "kind" else int(site.get(k, 0))
		sites.append(keep)
	a.columns.append(sites)
	if res.get("start") is Dictionary:
		a.ring = res.start.duplicate(true)
		a.pc = int(res.get("pc", int(a.ring.cols) / 2))
	a.rings.append(int(a.ring.cols))
	a.resize = res.get("resize", false) == true
	var t = res.get("turn")
	a.turns.append(int(round(float(t.deg))) if t is Dictionary else 0)
	return s


## A column's site by its id, or {} when it is not one of them.
static func siteOf(arc: Dictionary, c: int, id: int) -> Dictionary:
	if c < 0 or c >= arc.columns.size():
		return {}
	for site in arc.columns[c]:
		if int(site.id) == id:
			return site
	return {}


## The setup of the stage at one of the current column's sites (flying there starts it): the planet, the ring the
## pair fly re-centred on the site (World's rebased: its touch-down at pc + the site's arc, so the stage is fought
## there), the run's wear on its places (World lays it at the start), and the slots.
static func stageSetup(state: Dictionary, site: Dictionary, slots: Array, P: WorldPlanet.Planet) -> Dictionary:
	var a: Dictionary = state.arc
	var at: int = posmod(int(a.pc) + int(site.arc), int(a.ring.cols))
	var arena: Dictionary = WorldRingPick.arenaOf(WorldCampaign.rebased(P, WorldCampaign.specOf(a.ring), at))
	return {"planet": int(state.planet.seed), "arena": arena, "wear": a.wear.duplicate(true), "slots": slots.duplicate()}


## The next run state after a stage of the episode (SimRun.carry), and a stage won advances the route: end.site (the id
## of one of the column's sites) is taken, its place joins the used, the stage's wear (end.wear: WorldCampaign.wearOf
## of its final state) is merged, and the pair's column moves to the site. After the last column the episode is done; a
## main-story episode won may then offer a side story (campaign.md 1.4). A site that is not one of the column's is
## refused: the state comes back as it was.
static func advance(state: Dictionary, end: Dictionary, P: WorldPlanet.Planet) -> Dictionary:
	_ensure()
	var arc: Dictionary = state.get("arc", {})
	if arc.is_empty() or arc.done:
		return SimRun.carry(state, end)
	var won: bool = end.get("result") == "won"
	var site: Dictionary = siteOf(arc, int(arc.column), int(end.get("site", -1)))
	if won and site.is_empty():
		_err("campaign: site %d is not one of column %d's" % [int(end.get("site", -1)), int(arc.column) + 1])
		return state.duplicate(true)
	var s: Dictionary = SimRun.carry(state, end)
	if not won or s.over != "":
		return s
	var a: Dictionary = s.arc
	a.taken.append(int(site.id))
	if int(site.place) >= 0:
		a.used.append(int(site.place))
	a.wear = WorldCampaign.mergeWear(a.wear, end.get("wear", {}))
	a.pc = posmod(int(a.pc) + int(site.arc), int(a.ring.cols))
	a.column = int(a.column) + 1
	if int(a.column) >= columns:
		a.done = true
		if MAIN.has(a.kind):
			a.side = sideOffer(s, a)
	return s


## The side story a main-story episode won may offer (campaign.md 1.4): my seeded draw, H(arc, "side", n), on about
## sideShare of them; then World places it (WorldCampaign.side: a named city or town in the band, then anywhere on the
## ring, then on the ring turned at the episode's end: rulings-2026-10-26 item 2) with its Close ring, and the family is
## one of the filler families. how is World's (band, widened or turned), and turn the end's turn in whole degrees (0:
## none), which the host plays at the calm moment. World finds none: none is offered, and the draw is spent.
static func sideOffer(s: Dictionary, arc: Dictionary) -> Dictionary:
	var none: Dictionary = {"offered": false, "place": -1, "family": "", "ring": {}, "how": "", "turn": 0}
	var n: int = int(arc.number)
	if SimRun.H(String(arc.id), "side", n, 0) % 1000 >= sideShare:
		return none
	var used: Array = []
	for u in arc.used:
		used.append(int(u))
	var r: Dictionary = WorldCampaign.side(int(s.planet.seed), arcSeed(String(arc.id)), n, arc.ring, int(arc.pc), {"wear": arc.wear, "used": used})
	if not r.get("ok", false):
		return none
	var t = r.get("turn")
	return {"offered": true, "place": int(r.place), "family": families[SimRun.H(String(arc.id), "side", n, 2) % families.size()], "ring": r.arena.duplicate(true),
		"how": String(r.get("how", "band")), "turn": int(round(float(t.deg))) if t is Dictionary else 0}


## The filler episode a side story opens (campaign.md 1.2 and 1.4): its own arc block following the main-story episode
## it came from (the card reads n.5), on the main arc's planet as it stands (a copy of its wear and places) and on the
## side story's ring; nothing it does carries back (the host keeps the main story's state apart).
static func openSide(main: Dictionary, P: WorldPlanet.Planet, opts: Dictionary = {}) -> Dictionary:
	var arc: Dictionary = main.arc
	if not arc.side.offered:
		_err("campaign: no side story was offered")
		return {}
	var id: String = "%08x%08x" % [SimRun.H(String(arc.id), "side", int(arc.number), 3), SimRun.H(String(arc.id), "side", int(arc.number), 4)]
	var side: Dictionary = newArc(id, "filler_episode", {"player": arc.player, "follows": int(arc.number), "family": String(arc.side.family), "villain": String(opts.get("villain", arc.villain))})
	var s: Dictionary = newEpisode(side, 0, P, {"mode": main.mode, "people": int(main.planet.people), "places": main.places, "wear": arc.wear, "ring": arc.side.ring})
	s.planet.seed = int(main.planet.seed)   # the main arc's planet, as it stands
	return s


## The title card's number (campaign.md 1.3): a main-story episode's own number, a side story's "n.5", or "" (SIDE STORY).
static func cardNumber(arc: Dictionary) -> String:
	if MAIN.has(arc.kind):
		return str(int(arc.number))
	if int(arc.follows) >= 0:
		return "%d.5" % int(arc.follows)
	return ""


# ===================================================================== QA's record

## QA's campaign record of an episode (docs/qa/rally-campaign-rows.md), from its run state: the fights' length in
## seconds (the ledger's ticks: the stages won, and a lost run's last; the flights, beats and retries join when the host
## times them), the arc, and each column's ring by World's size names, whether the ring turned before it, and its
## places from the pair in signed columns to their near edge (World's band measure; 0 inside one). Rescues, rematches, a partner and the stage templates stay zero or empty
## until those steps exist.
static func qaRecord(state: Dictionary) -> Dictionary:
	var a: Dictionary = state.get("arc", {})
	if a.is_empty():
		return {}
	var ticks: int = 0
	for rec in state.ledger:
		ticks += int(rec.get("ticks", 0))
	var names: Dictionary = {}
	var sizes: Dictionary = WorldRingPick.cfg().get("sizes", {})
	for k in sizes:
		names[int(sizes[k])] = String(k).capitalize()
	var cols: Array = []
	for c in range(a.columns.size()):
		var places: Array = []
		for site in a.columns[c]:
			places.append({"fromPair": int(site.dir) * int(site.entry)})   # World's band measure: to the place's near edge, signed by its side
		var n: int = int(a.rings[c]) if c < a.rings.size() else 0
		cols.append({"n": c + 1, "ring": names.get(n, str(n)), "turned": c < a.turns.size() and int(a.turns[c]) != 0, "places": places})
	return {"episodeSec": int(round(float(ticks) * SimConst.DT)), "arc": String(a.id), "columns": cols, "rescues": {"n": 0, "won": 0},
		"rematches": {"n": 0, "won": 0}, "partner": {"stages": 0, "won": 0}, "templates": [], "arcTemplates": {}}


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
	if not (arc.get("columns") is Array) or arc.columns.size() > columns or not (arc.get("taken") is Array) or not (arc.get("threads") is Array) or not (arc.get("wear") is Dictionary) or not (arc.get("used") is Array) or not (arc.get("rings") is Array):
		return "columns, taken, used, rings and threads are lists, and wear an object"
	for t in arc.threads:
		if not (t is String) or not RegEx.create_from_string(THREAD_RE).search(t):
			return "a thread is an id only"
	for col in arc.columns:
		for site in col:
			for k in site:
				if not SITE_KEYS.has(k):
					return "a site holds only %s, not '%s'" % [str(SITE_KEYS), k]
	return ""


static func _int(where: String, x, lo: int, hi: int) -> int:
	if not (x is float or x is int) or float(x) != floor(float(x)) or int(x) < lo or int(x) > hi:
		_err("fight/campaign.json: %s is a whole number from %d to %d" % [where, lo, hi])
		return lo
	return int(x)


static func _err(msg: String) -> void:
	_errors.append(msg)
	if not FighterData.quiet:
		push_error("SimCampaign: " + msg)
