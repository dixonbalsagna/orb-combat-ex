class_name WorldBiomes
## Biome layout of the wrapped planet: the twin of biomes.js (SEG, biomeAt).

## [start, end, biome] spans of world x, in order, covering [0, W): the original spans times the planet scale. Static data.
const P: float = SimConst.PS
const SEG: Array = [[0.0 * P, 1200.0 * P, "ocean"], [1200.0 * P, 1800.0 * P, "village"], [1800.0 * P, 2350.0 * P, "plains"], [2350.0 * P, 3850.0 * P, "city"], [3850.0 * P, 4500.0 * P, "village"], [4500.0 * P, 5500.0 * P, "forest"], [5500.0 * P, 6500.0 * P, "desert"], [6500.0 * P, 7600.0 * P, "mountains"], [7600.0 * P, 8000.0 * P, "village"], [8000.0 * P, 8300.0 * P, "plains"], [8300.0 * P, 9600.0 * P, "ocean"]]


## A match on a planet's slice (WorldPlanetWorld.gen): the biome of each column, as an index into WorldPlanetWorld.BIOME_NAME; empty for the hand-made world.
static var planetCols := PackedByteArray()
static var fineCols := PackedByteArray()   ## Generation 2: the fine biome of each column (WorldClimate.F_*), parallel to planetCols; empty for the hand-made world and a gen 1 planet. The ground profiles (world/ground.gd) read it
static var worldId: int = 0   # the last world a match built (SimCore.newMatch: claim); a match's step takes its own tables again when this is not its id
static var _ids: int = 0


## A new id for the world a match is building, which is now the current one.
static func claim() -> int:
	_ids += 1
	worldId = _ids
	return worldId


## The fine biome name of the column at x for the director: on a gen 2 planet the fine biome (climate.json's fine names: jungle, savanna, tundra, taiga, wetland, beach, highland, volcanic and the built seven), on any
## other world the biome's own name (biomeAt); a town's or a city's ground reads "village" or "city" (its settlement), never a fine id: the stored codes 7 and 8 are not the fine ids 7 and 8.
static func fineNameAt(x: float) -> String:
	var xw: float = SimWrap.wrap(x)
	if fineCols.size() > 0 and fineCols.size() == planetCols.size():
		var i: int = mini(int(xw / SimConst.COL), planetCols.size() - 1)
		var st: int = planetCols[i]
		if st >= 7:
			return "city" if st == 8 else "village"
		return WorldClimate.fineName(fineCols[i])
	return biomeAt(xw)


static func biomeAt(x: float) -> String:
	x = SimWrap.wrap(x)
	if planetCols.size() > 0:
		return WorldPlanetWorld.BIOME_NAME[planetCols[mini(int(x / SimConst.COL), planetCols.size() - 1)]]
	for s in SEG:
		if x >= s[0] and x < s[1]:
			return s[2]
	return "plains"
