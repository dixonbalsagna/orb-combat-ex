class_name WorldPlanetCache
extends RefCounted
## The made planet in the cache (docs/world/gen3-field.md; the EP's order of 2026-11-01, Performance's load split: the climate grid is 0.7 s and the places 1.5 s of a warm load). A gen 3 planet is made by a
## job that builds the climate grid (the moisture carry) and then the places (a try-set a step); both are pure functions of the planet's data and seed, so a repeat visit reads them back: the grid's two arrays
## (the carried moisture and the ground height at each cell) and the places (kind, point, radius, people).
##
## The same envelope as the bake (WorldFieldCache.readBlob): the key carries the data hash, the Godot version, the seed and CODE_REV; the file is checked by key text, length and SHA-256; and the grid's first
## cells are recomputed now and compared bit for bit (the heights; they catch a change in the ground function). What the data hash and the witnesses cannot see is a change to the climate carry or the placing
## code with the data unchanged: **bump CODE_REV when sim/world/climate.gd's carry or planet.gd's placing changes**; `planet_cache_check` fails if it was not (it holds the made planet's digest for two seeds
## against sim/world/tools/planet_cache_vectors.json under the current CODE_REV).

const CODE_REV: int = 1
const WITNESS_CELLS: int = 24


static func enabled() -> bool:
	return WorldFieldCache.enabled() and bool(WorldField.data().get("cache", {}).get("planet", false))


static func keyOf(seed: int) -> String:
	return "%s|planet|seed %d|rev %d" % [WorldFieldCache.baseKey(), seed, CODE_REV]


## The made planet's pieces as one payload.
static func pack(P: WorldPlanet.Planet) -> PackedByteArray:
	var G: WorldClimate.Grid = P.grid
	var n: int = G.w * G.h
	var out := PackedByteArray()
	var head := PackedByteArray()
	head.resize(12)
	head.encode_u32(0, n)
	head.encode_u32(4, P.n)
	head.encode_u32(8, G.w)
	out.append_array(head)
	out.append_array(G.adv.to_byte_array())
	out.append_array(G.ht.to_byte_array())
	out.append_array(P.kind)
	out.append_array(P.px.to_byte_array())
	out.append_array(P.py.to_byte_array())
	out.append_array(P.pz.to_byte_array())
	out.append_array(P.rad.to_byte_array())
	out.append_array(P.people.to_byte_array())
	return out


static func store(P: WorldPlanet.Planet) -> void:
	if not enabled() or P.gen < 3 or P.grid == null:
		return
	WorldFieldCache.writeBlob(keyOf(P.seed), pack(P))


## Fills a planet fresh from `_newPlanet` from the cache; true when it is whole (grid and places) and can be memoised. False leaves P as it was.
static func load(P: WorldPlanet.Planet) -> bool:
	if not enabled() or P.gen < 3:
		return false
	var b: PackedByteArray = WorldFieldCache.readBlob(keyOf(P.seed))
	if b.size() < 12:
		return false
	var n: int = b.decode_u32(0)
	var np: int = b.decode_u32(4)
	var gw: int = b.decode_u32(8)
	var want: int = 12 + n * 8 + np * (1 + 8 * 4 + 4)
	if b.size() != want or n != int(WorldClimate.data().grid.w) * int(WorldClimate.data().grid.h) or gw != int(WorldClimate.data().grid.w):
		return false
	var o: int = 12
	var adv: PackedFloat32Array = b.slice(o, o + n * 4).to_float32_array()
	o += n * 4
	var ht: PackedFloat32Array = b.slice(o, o + n * 4).to_float32_array()
	o += n * 4
	var kind: PackedByteArray = b.slice(o, o + np)
	o += np
	var px: PackedFloat64Array = b.slice(o, o + np * 8).to_float64_array()
	o += np * 8
	var py: PackedFloat64Array = b.slice(o, o + np * 8).to_float64_array()
	o += np * 8
	var pz: PackedFloat64Array = b.slice(o, o + np * 8).to_float64_array()
	o += np * 8
	var rad: PackedFloat64Array = b.slice(o, o + np * 8).to_float64_array()
	o += np * 8
	var people: PackedInt32Array = b.slice(o, o + np * 4).to_int32_array()
	# witnesses: the first cells' heights, recomputed now by the grid's own step, must be the file's
	var G := WorldClimate.Grid.new(P)
	G.step(WITNESS_CELLS)
	for k in range(WITNESS_CELLS):
		if G.ht[k] != ht[k]:
			return false
	G.adv = adv
	G.ht = ht
	G.cell = n
	G.done = true
	G._cph = 5
	P.grid = G
	P.n = np
	P.kind = kind
	P.px = px
	P.py = py
	P.pz = pz
	P.rad = rad
	P.people = people
	return true


## A digest of the made planet (grid and places), for the vectors check and for tools: a hash of the packed bytes.
static func digest(P: WorldPlanet.Planet) -> String:
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(pack(P))
	return hc.finish().hex_encode().substr(0, 32)
