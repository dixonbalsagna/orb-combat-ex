class_name WorldPlanetWorld
## Planet window 2 (DRAFT, scratch): a match on a slice of the stored planet. For a setup with a `planet` key the world is read from WorldPlanet instead of built by genWorld:
## the ground (S.base) from the slice's heights, the biome of each column from its biomes, and the settlements from the places the line passes, laid by today's D1 generator
## (a stand-in for window 3's city from its plan). A setup without `planet` is genWorld as it was.
##
## Stand-ins and decisions this draft makes (each is a question for the EP, Game Design or Rendering; see docs/world/planet-window2.md):
##  - the two ice biomes read as existing biome names (BIOME_NAME below) because the director's and the renderer's tables know only those;
##  - a city is Bellgate's archetype and a town the outskirts village's, with the span set from the place's chord on the line and the people from the place's weight;
##  - a place that crosses the seam is cut at it (the seam is the antipode of the touch-down: rare);
##  - the fighters start astride the touch-down (the middle column).

## Planet biome ids 0 to 6 (ocean, plains, forest, desert, mountains, ice sheet, sea ice) as WorldBiomes names, and 7 and 8 for a town's and a city's ground.
const BIOME_NAME: Array = ["ocean", "plains", "forest", "desert", "mountains", "mountains", "plains", "village", "city"]
const ARCH_CITY: String = "bellgate"
const ARCH_TOWN: String = "outskirts"


## The chords of the places a slice holds: [id, kind, col0, col1], each trimmed to the line and to dry ground (`heights`: the slice's, before any platform). Standing places only.
static func chordsOf(sl: WorldPlanet.Slice, heights: PackedFloat32Array) -> Array:
	var NC: int = SimConst.NC
	var COL: float = SimConst.COL
	var chords: Array = []
	for h in sl.held:
		if not h.standing:
			continue
		var hc: int = int(h.half / COL)
		var c0: int = maxi(0, h.col - hc)
		var c1: int = mini(NC - 1, h.col + hc)
		while c0 < c1 and heights[c0] < WorldTerrain.TRIM_G:
			c0 += 1
		while c1 > c0 and heights[c1] < WorldTerrain.TRIM_G:
			c1 -= 1
		if c1 - c0 < 8:
			continue
		chords.append([h.id, h.kind, c0, c1])
	return chords


## A town's or a city's ground over its chord, in the biome table: village or city where the ground is dry (`base`: before the platform).
static func settleBiomes(cols: PackedByteArray, base: PackedFloat32Array, chords: Array) -> void:
	for ch in chords:
		for i in range(ch[2], ch[3] + 1):
			if base[i] >= 0.0:
				cols[i] = 8 if ch[1] == WorldPlanet.KIND_CITY else 7


## The platform under each settlement: the ground inside is lifted to at least SETTLE_FLOOR with a blend at each end (genWorld's _platforms).
static func platform(base: PackedFloat32Array, chords: Array) -> void:
	var NC: int = SimConst.NC
	for ch in chords:
		var i0: int = ch[2]
		var i1: int = ch[3]
		for i in range(i0 - WorldTerrain.PLATFORM_BLEND, i1 + WorldTerrain.PLATFORM_BLEND + 1):
			var j: int = (i + NC) % NC
			var g: float = base[j]
			if g >= WorldTerrain.SETTLE_FLOOR or g < WorldTerrain.TRIM_G:
				continue
			var w: float = 1.0
			if i < i0 + WorldTerrain.PLATFORM_BLEND:
				w = clampf(float(i - (i0 - WorldTerrain.PLATFORM_BLEND)) / float(2 * WorldTerrain.PLATFORM_BLEND), 0.0, 1.0)
			if i > i1 - WorldTerrain.PLATFORM_BLEND:
				w = minf(w, clampf(float((i1 + WorldTerrain.PLATFORM_BLEND) - i) / float(2 * WorldTerrain.PLATFORM_BLEND), 0.0, 1.0))
			w = w * w * (3.0 - 2.0 * w)
			base[j] = g + (WorldTerrain.SETTLE_FLOOR - g) * w


## The settlements of `chords`, by D1's generator: {buildings, dlist, pop}. wsum: the people weight the places' shares are of. planTag: 0 at the match's start; a turn's number after
## (a building's plan index is its index in its settlement plus 1,000 a turn, so a place's plan indices stay unique across layouts). distOffset and setOffset: where the districts and
## settlements number from (a turn lays places beside kept ones).
static func settle(S: SimState, P: WorldPlanet.Planet, chords: Array, wsum: float, planTag: int, distOffset: int, setOffset: int) -> Dictionary:
	var COL: float = SimConst.COL
	var PS: float = SimConst.PS
	var arch: Dictionary = {}
	for sd in WorldSettle.data().settlements:
		arch[sd.id] = sd
	var buildings: Array = []
	var newPop: float = 0.0
	var dOff: int = distOffset
	var si: int = setOffset - 1
	var dlist: Array = []
	for ch in chords:
		si += 1
		var sd: Dictionary = (arch[ARCH_CITY] if ch[1] == WorldPlanet.KIND_CITY else arch[ARCH_TOWN]).duplicate(true)
		sd.id = "p%d" % ch[0]
		sd.span = [float(ch[2]) * COL / PS, float(ch[3]) * COL / PS]
		sd.pop_share = float(P.people[ch[0]]) / maxf(wsum, 1.0)
		var g: Dictionary = WorldSettle.generate(S, sd)
		for dd in g.districts:
			dd["settlement"] = si
			dlist.append(dd)
		for ei in range(g.buildings.size()):
			var e = g.buildings[ei]
			var nb := SimState.Building.new()
			nb.place = ch[0]
			nb.plan = ei + 1000 * planTag
			nb.x = e.x; nb.w = e.w; nb.d = e.d; nb.h = e.h; nb.kind = e.kind; nb.row = float(e.row); nb.z = e.z; nb.seed = e.seed
			nb.district = dOff + int(e.district); nb.shape = String(e.shape); nb.landmark = int(e.landmark)
			nb.floors = e.floors
			nb.fmask = (1 << nb.floors) - 1
			nb.maxhp = e.maxhp; nb.hp = e.maxhp; nb.alive = true
			nb.pop = float(e.pop); nb.popAlive = nb.pop
			newPop += nb.pop
			buildings.append(nb)
		dOff += g.districts.size()
	return {"buildings": buildings, "dlist": dlist, "pop": newPop}


## The ring a slice was read on, as the epoch carries it (an axis, the columns and a touch-down): from a ring the picker or a setup named, or a great circle. {} when it is not one the turn
## handles (a ring with its centre on the right of the way the columns run).
static func specOf(circ: Dictionary) -> Dictionary:
	if not circ.has("st"):
		return {"c": circ.n, "t": circ.u, "cols": SimConst.PLANET_NC}
	if float(circ.get("s", 1.0)) < 0.0:
		return {}
	return {"c": circ.c, "t": WorldRingPick.ringPoint(circ, 0.0), "cols": SimConst.NC}


static func gen(S: SimState, setup: Dictionary) -> bool:
	WorldClimate.useGen(int(setup.get("planetGen", 0)))   # the generation this match's planet is made by: its setup's, else the data's (gen 1 unless Orb has flipped it)
	WorldBiomes.fineCols = PackedByteArray()
	var seed: int = int(setup.planet)
	var touch: int = int(setup.get("touch", 0))
	var arena = setup.get("arena", {})
	var ring: Dictionary = WorldRingPick.ringOfArena(arena) if arena is Dictionary else {}
	var sl: WorldPlanet.Slice = WorldPlanet.sliceRing(seed, ring) if not ring.is_empty() else WorldPlanet.sliceFor(seed, touch, PackedByteArray(), false, int(arena.get("side", 1)) if arena is Dictionary else 1)   # the arena's columns are SimConst.NC (newMatch set them)
	if sl == null:
		return false
	var P: WorldPlanet.Planet = WorldPlanet.make(seed)
	var NC: int = SimConst.NC
	S.deform.resize(NC)
	S.deform.fill(0.0)
	S.base = sl.heights.duplicate()
	S.buildings.clear()
	S.trees.clear()
	# the biome of each column, and a town's or a city's ground over its chord
	var cols := PackedByteArray()
	cols.resize(NC)
	for i in range(NC):
		cols[i] = sl.biomes[i]
	var chords: Array = chordsOf(sl, S.base)
	settleBiomes(cols, S.base, chords)
	WorldBiomes.planetCols = cols
	platform(S.base, chords)
	var sh: int = WorldPlanet.sliceHash(sl)
	var lakes: Array = []
	if sl.fine.size() == NC:   # a gen 2 planet: the fine biomes, and the trees they grow (data/biomes/ground.json)
		WorldBiomes.fineCols = sl.fine
		S.trees = WorldGround.layTrees(sl.fine, cols, S.base, sh)
		lakes = WorldLakes.plan(S.base, chords, sl.fine, cols)   # window 5: the valleys of the ring that hold water; trees do not grow in them
		if WorldRivers.enabled():   # window 14: where the ring crosses a river it is cut into the ground and planted as a narrow shallow lake
			var rsp: Dictionary = specOf(sl.circ)
			if not rsp.is_empty():
				var rv: Array = WorldRivers.plan(P, rsp, S.base, chords, sl.fine, cols, lakes)
				WorldRivers.carve(S.base, rv)
				lakes = lakes + rv
		S.trees = WorldLakes.dryTrees(S.trees, lakes, NC)
	# the settlements, by D1's generator
	var wsum: float = 0.0
	for ch in chords:
		wsum += float(P.people[ch[0]])
	var gen: Dictionary = settle(S, P, chords, wsum, 0, 0, 0)
	for nb in gen.buildings:
		S.buildings.append(nb)
	var dlist: Array = gen.dlist
	S.lanes = WorldLanes.build(S, dlist)
	S.world = SimState.World.new()
	S.world.pop0 = maxf(gen.pop, 1.0)
	S.rubble = PackedFloat32Array()
	S.rubble.resize(NC)
	S.rubble.fill(0.0)
	WorldStructures.buildIndex(S)
	S.scorch = PackedFloat32Array()
	S.scorch.resize(NC)
	S.scorch.fill(0.0)
	if WorldAfter.on() or WorldCraters.on():   # a beam's aftermath (after.gd) and a material crater's jobs and strips (craters.gd): sized only with a switch on
		WorldAfter.size(S)
	S.craters.clear()
	S.crack = PackedFloat32Array()
	S.crack.resize(NC)
	S.crack.fill(0.0)
	S.slides.clear()
	if setup.has("wear"):   # the campaign's place state (the setup is the switch: the campaign's host gives it wear only while data/fight/campaign.json is on): a worn place's buildings are already fallen or weakened (window 14; place state only, never a count of people)
		WorldCampaign.applyWear(S, setup.wear)
	WorldWater.init(S)
	WorldLakes.apply(S, lakes)
	WorldCollateral.init(S)
	var spec: Dictionary = specOf(sl.circ)
	if not spec.is_empty():
		S.planetRing = {"seed": seed, "c": spec.c, "t": spec.t, "cols": spec.cols}   # unhashed: the ring this match plays on, whether or not it can turn (a renderer's far land)
		if sl.fine.size() == NC:
			S.planetRing["fine"] = sl.fine   # a gen 2 ring's fine biomes: the turn blends them like planetCols
			S.planetRing["lakes"] = lakes    # and its lakes: the water module keeps them level, the turn carries them
	if WorldEpoch.enabled(setup):   # the calm-moment turn (docs/world/calm-turn-world.md): the epoch starts on the ring this match plays on
		if not spec.is_empty():
			S.epoch = WorldEpoch.begin(S, seed, sl.circ, spec, chords, dlist, sh)
	return true
