"""The far land's two follow-ups (World, scratch): the match's ring kept in unhashed state, and settlements in the far map.   python mk_farsites.py <root>
 - S.planetRing (state.gd, sim.gd newMatch: Simulation's lines; planet_world.gen and WorldEpoch.swap set it): {seed, c, t, cols}, the ring this match plays on, for every planet match (the turn on or not)
 - WorldPlanet.farPlaces: the places beside a ring, for a renderer
 - WorldFarMap.sites / places: a settlement layer of the map (0 none, 1 town, 2 city, the place's own footprint)"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def state(s):
    return rep(s, '''var epoch = null ''', '''var planetRing = {}                  # World: the ring this match's planet world plays on ({seed, c, t, cols}: the axis, the touch-down point and the columns, as WorldRingPick.ringFrom takes them), for a planet match with the calm-moment turn on or off, kept up to date at a turn; {} for the hand-made world. A renderer's far land reads it. Not hashed
var epoch = null ''')


def sim(s):
    return rep(s, '''	S.epoch = null   # World's calm-moment turn''', '''	S.planetRing = {}   # World: the planet match's ring (planet_world.gd sets it)
	S.epoch = null   # World's calm-moment turn''')


def planet_world(s):
    return rep(s, '''	if WorldEpoch.enabled(setup):   # the calm-moment turn (docs/world/calm-turn-world.md): the epoch starts on the ring this match plays on
		var spec: Dictionary = specOf(sl.circ)
		if not spec.is_empty():
			S.epoch =''', '''	var spec: Dictionary = specOf(sl.circ)
	if not spec.is_empty():
		S.planetRing = {"seed": seed, "c": spec.c, "t": spec.t, "cols": spec.cols}   # unhashed: the ring this match plays on, whether or not it can turn (a renderer's far land)
	if WorldEpoch.enabled(setup):   # the calm-moment turn (docs/world/calm-turn-world.md): the epoch starts on the ring this match plays on
		if not spec.is_empty():
			S.epoch =''')


def epoch(s):
    return rep(s, '''	E.ring = spec
''', '''	E.ring = spec
	S.planetRing = {"seed": seed, "c": spec.c, "t": spec.t, "cols": spec.cols}   # unhashed: the ring now played on
''')


def planet(s):
    a = '''## The slice of an explicit ring (WorldRingPick: an axis, the columns, a touch-down), memoised outside the state like sliceFor's.'''
    new = '''## The places beside a ring, for a renderer's far land (the towns and cities past the arena, which the map's heights and biomes do not show): every place within `maxLateral` units of the ring, as
## {id, kind (KIND_CITY or KIND_TOWN), col (its column along the ring, a float in [0, NC)), z (its signed lateral offset, farColumn's z: positive toward the ring's centre, so farColumn(ring, col, z)
## is at its centre), rad (its radius in units), dir ([x, y, z], the unit vector of its centre), people (the place's weight)}. Sorted by id. A pure function of the planet and the ring.
static func farPlaces(P: Planet, ring: Dictionary, maxLateral: float = 1.0e18) -> Array:
	var out: Array = []
	var stf: float = ring.get("st", 1.0)
	var tc: int = touchCol()
	var nc: float = float(SimConst.NC)
	var u: Array = ring.u
	var v: Array = ring.v
	for i in range(P.n):
		var lat: float = lateral(P, ring, P.px[i], P.py[i], P.pz[i])
		if absf(lat) > maxLateral:
			continue
		var along: float = atan2f(P.px[i] * v[0] + P.py[i] * v[1] + P.pz[i] * v[2], P.px[i] * u[0] + P.py[i] * u[1] + P.pz[i] * u[2])
		var col: float = float(tc) + along * (P.R * stf) / SimConst.COL
		col -= floor(col / nc) * nc
		out.append({"id": i, "kind": int(P.kind[i]), "col": col, "z": lat, "rad": P.rad[i], "dir": [P.px[i], P.py[i], P.pz[i]], "people": int(P.people[i])})
	return out


'''
    return rep(s, a, new + a)


def farmap(s):
    s = rep(s, '''var next: int = 0
var done: bool = false
''', '''var next: int = 0
var done: bool = false
var sites := PackedByteArray()   # the settlements' layer, whole from the start: 0 none, 1 a town's ground, 2 a city's (each place's own radius, WorldPlanet's), as the map's texels see it
''')
    s = rep(s, '''	hs.resize(n * n)
	bs.resize(n * n)
''', '''	hs.resize(n * n)
	bs.resize(n * n)
	sites.resize(n * n)
	sites.fill(0)
	_mark_sites()
''')
    s = rep(s, '''## Read `count` more texels; true when the map is whole.''', '''## The settlements' layer: every texel whose centre lies within a place's radius of its centre (and the texel that holds the centre, however small the place) is its kind's; a city over a town.
## About 1.4 degrees (600 units) a texel at 256 against radii of 2,400 (a town) and 6,500 (a city) units.
func _mark_sites() -> void:
	var inv: float = 1.0 / float(n)
	for k in range(P.n):
		var kind: int = 2 if int(P.kind[k]) == WorldPlanet.KIND_CITY else 1
		var rad: float = float(P.rad[k])
		var cx: float = P.px[k]
		var cy: float = P.py[k]
		var cz: float = P.pz[k]
		var t: Vector2 = _uv(cx, cy, cz)
		var ci: int = int(floor(t.x + 0.5))
		var cj: int = int(floor(t.y + 0.5))
		var w: int = int(ceil(rad / (P.R * 1.77 * inv))) + 1   # a texel is at most about twice its mean angle (3.54 / n radians) across
		var chord: float = rad / P.R
		for j in range(maxi(0, cj - w), mini(n, cj + w + 1)):
			for i in range(maxi(0, ci - w), mini(n, ci + w + 1)):
				var d: Array = decode((float(i) + 0.5) * inv, (float(j) + 0.5) * inv)
				var dx: float = d[0] - cx
				var dy: float = d[1] - cy
				var dz: float = d[2] - cz
				if sqrt(dx * dx + dy * dy + dz * dz) <= chord:
					sites[j * n + i] = maxi(int(sites[j * n + i]), kind)
		if ci >= 0 and ci < n and cj >= 0 and cj < n:
			sites[cj * n + ci] = maxi(int(sites[cj * n + ci]), kind)


## The places beside a ring (WorldPlanet.farPlaces) within `maxLateral` units, for drawing a distant town or city where it stands.
func places(ring: Dictionary, maxLateral: float = 1.0e18) -> Array:
	return WorldPlanet.farPlaces(P, ring, maxLateral)


## The settlement under a unit vector: 0 none, 1 a town's ground, 2 a city's (the nearest texel's, as biome()).
func site(qx: float, qy: float, qz: float) -> int:
	var t: Vector2 = _uv(qx, qy, qz)
	return sites[_tex(int(floor(t.x + 0.5)), int(floor(t.y + 0.5)))]


## Read `count` more texels; true when the map is whole.''')
    # field returns the sites too
    s = rep(s, '''	var bout := PackedByteArray()
	hout.resize(ncols * depths.size())
	bout.resize(ncols * depths.size())
	for di in range(depths.size()):''', '''	var bout := PackedByteArray()
	var sout := PackedByteArray()
	hout.resize(ncols * depths.size())
	bout.resize(ncols * depths.size())
	sout.resize(ncols * depths.size())
	for di in range(depths.size()):''')
    s = rep(s, '''			bout[di * ncols + ci] = biome(qx, qy, qz)
	return {"h": hout, "b": bout}''', '''			bout[di * ncols + ci] = biome(qx, qy, qz)
			sout[di * ncols + ci] = site(qx, qy, qz)
	return {"h": hout, "b": bout, "s": sout}''')
    s = rep(s, '''## WorldPlanet.farField's block of ground, read from the map: the height and biome at''', '''## WorldPlanet.farField's block of ground, read from the map (and "s", the settlement under each sample: 0 none, 1 town, 2 city): the height and biome at''')
    return s


rw(R, 'sim/core/state.gd', state)
rw(R, 'sim/core/sim.gd', sim)
rw(R, 'sim/world/planet_world.gd', planet_world)
rw(R, 'sim/world/epoch.gd', epoch)
rw(R, 'sim/world/planet.gd', planet)
rw(R, 'sim/world/farmap.gd', farmap)
print('far ring and sites applied')
