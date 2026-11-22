class_name WorldDefault
extends RefCounted
## The world a match plays on when its setup names none (A-WORLD-01, A-WORLD-14; docs/world/world-default.md; data/biomes/world.json). One module, read by the sim (SimCore.beginMatch, for headless matches and tests) and by the
## host (the menu's planet_part, which makes the planet ahead while the player decides), so the two always agree.
##   mode "arena":  a setup with no planet key plays the old hand-made arena, as it always has (shipped until the golden window GW1b).
##   mode "planet": a setup with no planet key plays the round planet: the one fixed planet (data `fixed`: the planet Orb's build plays), or, for a quick match, a planet drawn from the match's seed out of `random.pool`.
## An explicit key always wins: a setup with a `planet` plays that planet; a setup with `world: "arena"` plays the hand-made arena (what the tests that need it say). The first match of a newcomer and the tests use the fixed planet
## (`first: true`). The drawn planet is a pure function of the match's seed (SimRng.keyed, no stream), so the same seed plays the same planet on every machine; its seed is in the setup and so in the replay and the report.

const PATH := "res://data/biomes/world.json"
const SCHEMA := "biomes.world/1"

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var K_MODE: String = "arena"
static var K_FIXED: Dictionary = {"planet": 7, "touch": 3, "planetGen": 3}
static var K_RANDOM: bool = false
static var K_POOL: Array = [7, 12, 3, 13, 17]
static var K_TOUCHES: Array = [1, 2, 3]


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	K_MODE = "arena"
	K_FIXED = {"planet": 7, "touch": 3, "planetGen": 3}
	K_RANDOM = false
	K_POOL = [7, 12, 3, 13, 17]
	K_TOUCHES = [1, 2, 3]
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return   # no file: the old arena, as it was
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("world.json: not a %s object" % SCHEMA)
		return
	for k in ["mode", "fixed", "random"]:
		if not j.has(k):
			_errors.append("world.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	if not (String(j.mode) in ["arena", "planet"]):
		_errors.append("world.json: mode is arena or planet")
	var fx = j.fixed
	if not (fx is Dictionary) or not fx.has("planet") or not fx.has("touch") or not fx.has("planetGen") or int(fx.planetGen) < 2 or int(fx.touch) < 0:
		_errors.append("world.json: fixed is {planet, touch, planetGen (2 or 3)}")
	var rd = j.random
	if not (rd is Dictionary) or not rd.has("enabled") or not (rd.get("pool") is Array) or (rd.pool as Array).is_empty() or not (rd.get("touches") is Array) or (rd.touches as Array).is_empty():
		_errors.append("world.json: random is {enabled, pool (planet seeds, not empty), touches (not empty)}")
	if not _errors.is_empty():
		return
	_d = j
	K_MODE = String(j.mode)
	K_FIXED = {"planet": int(fx.planet), "touch": int(fx.touch), "planetGen": int(fx.planetGen)}
	K_RANDOM = bool(rd.enabled)
	K_POOL = []
	for p in rd.pool:
		K_POOL.append(int(p))
	K_TOUCHES = []
	for t in rd.touches:
		K_TOUCHES.append(int(t))


static func mode() -> String:
	if not _loaded:
		_load()
	return K_MODE


static func planetDefault() -> bool:
	return mode() == "planet"


## Tests only: the mode, the fixed planet and the random switch without the file.
static func setForTest(mode_: String, random_: bool) -> void:
	if not _loaded:
		_load()
	K_MODE = mode_
	K_RANDOM = random_


## The planet a quick match with this seed plays: [planet seed, touch], a pure function of the match's seed out of the data's pool. The same seed, the same planet, on every machine.
static func draw(matchSeed: int) -> Array:
	if not _loaded:
		_load()
	var a: int = int(SimRng.keyed(matchSeed, "world.planet", 0) * float(K_POOL.size()))
	var b: int = int(SimRng.keyed(matchSeed, "world.touch", 0) * float(K_TOUCHES.size()))
	return [K_POOL[clampi(a, 0, K_POOL.size() - 1)], K_TOUCHES[clampi(b, 0, K_TOUCHES.size() - 1)]]


## The planet part of a setup that names none: the planet keys (planet, touch, planetGen) to merge into it, or {} when the data's mode is the arena. first: a newcomer's first match (the fixed planet, never the draw).
static func part(matchSeed: int, first: bool = false) -> Dictionary:
	if not _loaded:
		_load()
	if K_MODE != "planet":
		return {}
	var out: Dictionary = K_FIXED.duplicate()
	if K_RANDOM and not first:
		var d: Array = draw(matchSeed)
		out["planet"] = int(d[0])
		out["touch"] = int(d[1])
	return out


## A setup with the default world applied: the setup as given when it names a planet, or `world: "arena"`, or the mode is the arena; else a copy with the planet keys merged. Never changes the dictionary it is given.
static func apply(setup: Dictionary, matchSeed: int, first: bool = false) -> Dictionary:
	if setup.has("planet") or String(setup.get("world", "")) == "arena":
		return setup
	var p: Dictionary = part(matchSeed, first or bool(setup.get("first", false)))
	if p.is_empty():
		return setup
	var out: Dictionary = setup.duplicate()
	out.merge(p)
	return out


## What a report or the HUD reads of a match's world: the planet's seed (or 0 for the hand-made arena), its generation and the touch. From the state alone.
static func describe(S) -> Dictionary:
	if S.planetRing is Dictionary and not S.planetRing.is_empty() and S.planetRing.has("seed"):
		return {"planet": int(S.planetRing.seed), "gen": int(S.planetGen), "cols": int(S.planetRing.get("cols", SimConst.PLANET_NC))}
	return {"planet": 0, "gen": 1, "cols": 0}
