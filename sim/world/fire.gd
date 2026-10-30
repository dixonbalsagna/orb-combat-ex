class_name WorldFire
extends RefCounted
## Fires in the forests (docs/world/forest-fire.md, window 18; data/biomes/fire.json, off by default): a landscape that answers back, cheap and cosmetic. Today a blast or a beam fells the trees inside its radius and
## leaves the rest untouched. With the fire on, the trees just beyond the felled ring catch (a chance by the biome's flammability), burn for a few seconds, spread to near trees of flammable ground, and burn out:
## a burnt tree is dead with burn 1 (a felled one has burn 0), so the renderer can draw flames while 0 < burn < 1 and a charred stump after. Water puts a fire out. It never hurts a fighter, a building or a person
## and adds no casualty: it is a look. The state is the trees' own `burn` (hashed already, never set until now); no draw from a stream (keyed draws only), nothing runs when no tree burns.

const PATH := "res://data/biomes/fire.json"
const SCHEMA := "biomes.fire/1"

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""
static var K_ON: bool = false
static var K_BAND_LO: float = 0.7
static var K_BAND_HI: float = 1.3
static var K_CHANCE: float = 0.6
static var K_TICKS: int = 360
static var K_SPREAD_R: float = 280.0
static var K_SPREAD: float = 0.25
static var K_EVERY: int = 6
static var K_MAX: int = 80
static var K_QUENCH: float = 1.0
static var _flam: Dictionary = {}


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash


static func on() -> bool:
	if not _loaded:
		_load()
	return K_ON


## For tools and checks: the switch for this process (the file is not touched).
static func setOn(on_: bool) -> void:
	if not _loaded:
		_load()
	K_ON = on_ and _errors.is_empty()


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return   # no file: no fires
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("fire.json: not a %s object" % SCHEMA)
		return
	for k in ["enabled", "ignite", "burn", "flammable"]:
		if not j.has(k):
			_errors.append("fire.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	var ig: Dictionary = j.ignite
	var bu: Dictionary = j.burn
	if float(ig.bandLo) < 0.0 or float(ig.bandHi) <= float(ig.bandLo) or int(bu.ticks) < 2 or float(bu.spreadRadius) <= 0.0 or int(bu.every) < 1 or int(bu.maxBurning) < 1:
		_errors.append("fire.json: ignite.bandHi above bandLo, burn.ticks at least 2, spreadRadius above 0, every and maxBurning at least 1")
	var fine: Array = []
	for g in WorldClimate.data().get("fine", []):
		fine.append(String(g.name))
	for k in j.flammable:
		if not (fine.has(String(k)) or ["village", "city", "ocean", "plains", "forest", "desert", "mountains"].has(String(k))):
			_errors.append("fire.json: flammable names %s, which is not a biome" % String(k))
	if not _errors.is_empty():
		return
	_d = j
	_hash = str(text.hash())
	K_ON = bool(j.enabled)
	K_BAND_LO = float(ig.bandLo)
	K_BAND_HI = float(ig.bandHi)
	K_CHANCE = float(ig.chance)
	K_TICKS = int(bu.ticks)
	K_SPREAD_R = float(bu.spreadRadius)
	K_SPREAD = float(bu.spread)
	K_EVERY = int(bu.every)
	K_MAX = int(bu.maxBurning)
	K_QUENCH = float(bu.quenchDepth)
	_flam = {}
	for k in j.flammable:
		_flam[String(k)] = float(j.flammable[k])


## How readily the ground at x burns, 0 to 1 (fire.json's flammable, by the fine biome on a gen 2 planet, else the biome's name).
static func flammability(x: float) -> float:
	if not _loaded:
		_load()
	return float(_flam.get(WorldBiomes.fineNameAt(x), 0.0))


## A blast or a beam's sample at (x, y) of radius r has felled the trees inside 0.7 r (WorldStructures.damageArea): the trees from bandLo to bandHi of r that are still standing may catch, by chance x the ground's
## flammability, from a keyed draw. Only while fewer than maxBurning trees burn.
static func ignite(S: SimState, x: float, y: float, r: float) -> void:
	var burning: int = 0
	for t in S.trees:
		if t.alive and t.burn > 0.0:
			burning += 1
	var seed: int = int(S.game.seed)
	for i in range(S.trees.size()):
		if burning >= K_MAX:
			return
		var t = S.trees[i]
		if not t.alive or t.burn > 0.0:
			continue
		var d: float = absf(SimWrap.sdx(x, t.x))
		if d < r * K_BAND_LO or d >= r * K_BAND_HI or y >= WorldTerrain.groundY(S, t.x) + r * K_BAND_HI:
			continue
		var p: float = K_CHANCE * flammability(t.x)
		if p > 0.0 and SimRng.keyed(seed, "fire/ig", i * 100003 + S.tick) < p:
			t.burn = 1.0 / float(K_TICKS)
			burning += 1
			SimFx.fire(S, t.x, WorldTerrain.groundY(S, t.x), 2)


## One tick (WorldWater.step calls it): each burning tree burns a little more, burns out at 1 (dead, burn 1, a small flame), goes out in water, and, every `every` ticks, may light a flammable tree within
## spreadRadius (a chance a second, falling with the distance and the ground's flammability). Nothing runs when no tree burns.
static func step(S: SimState) -> void:
	var burning: Array = []
	for i in range(S.trees.size()):
		var t = S.trees[i]
		if t.alive and t.burn > 0.0:
			burning.append(i)
	if burning.is_empty():
		return
	var NC: int = SimConst.NC
	var COL: float = SimConst.COL
	var spreadTick: bool = S.tick % K_EVERY == 0
	var buckets: Dictionary = {}
	if spreadTick:
		for j in range(S.trees.size()):
			var u = S.trees[j]
			if u.alive and u.burn <= 0.0:
				var bc: int = int(floor(SimWrap.wrap(u.x) / COL)) / 9
				if not buckets.has(bc):
					buckets[bc] = []
				buckets[bc].append(j)
	var lit: int = 0
	var seed: int = int(S.game.seed)
	var nb: int = maxi(1, NC / 9)
	for i in burning:
		var t = S.trees[i]
		var col: int = int(floor(SimWrap.wrap(t.x) / COL)) % NC
		if S.water[col] > K_QUENCH:
			t.burn = 0.0   # the water puts it out
			continue
		t.burn += 1.0 / float(K_TICKS)
		if t.burn >= 1.0:
			t.burn = 1.0
			t.alive = false
			SimFx.fire(S, t.x, WorldTerrain.groundY(S, t.x), 1)
			continue
		if not spreadTick or burning.size() + lit >= K_MAX:
			continue
		var bc0: int = int(floor(SimWrap.wrap(t.x) / COL)) / 9
		for db in range(-2, 3):
			var key: int = posmod(bc0 + db, nb)
			if not buckets.has(key):
				continue
			for j in buckets[key]:
				var u = S.trees[j]
				if not u.alive or u.burn > 0.0:
					continue
				var d: float = absf(SimWrap.sdx(t.x, u.x))
				if d > K_SPREAD_R:
					continue
				var p: float = K_SPREAD * flammability(u.x) * (1.0 - d / K_SPREAD_R) * float(K_EVERY) / 60.0
				if SimRng.keyed(seed, "fire/sp", ((i * 4099 + j) * 977 + S.tick) & 0x7FFFFFFF) < p:
					u.burn = 1.0 / float(K_TICKS)
					lit += 1
					SimFx.fire(S, u.x, WorldTerrain.groundY(S, u.x), 2)
