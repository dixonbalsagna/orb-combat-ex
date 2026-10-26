"""Window 20 add-on (World, 2026-10-26): the planet's load in steps, each piece bounded by the units a read gets (SimRun.planetUnitsPerRead), and the memo's eviction.   python mk_p21.py <root>
   (root: main + Simulation's planet-load park (grant_world.py, planet_load.py) + mk_p20a, mk_p20b, mk_p20c)
 - sim/world/climate.gd: the wind's carry (17 to 26 ms) in steps: Grid.step(n) reads cells and then carries rows, a unit a cell, ten a row of the wind, one a row of each blend; Grid.spent counts them
 - sim/world/rivers.gd: Flow made a few cells at a time (Flow.new(G, false), step(cells)); Flow.new(G) is the whole one, the same arrays to the last bit
 - sim/world/planet.gd: PlanetJob steps the grid, the carry, the flow field and the places (a try-set a few tries at a time, resumable, draw for draw); SliceJob reads a touch-down's ring in steps (the pick a
   circle at a time, the columns a slice, the held places) and memoises it where sliceFor finds it; the planet and slice memos evict the oldest, not all"""
import sys
from mk_wbc_lib import rw, rep
import flow_steps
R = sys.argv[1].rstrip('/') + '/'


def climate(s):
    a = s.index("\t## Reads up to n more cells' heights, then (once whole) carries the moisture; true when the grid is made.")
    b = s.index("## The planet's grid (built when first asked")
    new = '''	var spent: int = 0         # units spent: a cell a unit, then the carry's rows (the job's budget is told in these)
	var _cph: int = 0          # the carry's phase: 0 not begun, 1 the wind's rows, 2 the blend by the wind, 3 the blend between rows, 4 the blend along the rows, 5 made
	var _crow: int = 0
	var _east := PackedFloat32Array()   # wind toward -longitude
	var _west := PackedFloat32Array()   # wind toward +longitude
	var _mix := PackedFloat32Array()
	var _vb := PackedFloat32Array()

	## Does up to n more units of the work: the cells' heights (a unit a cell), then (once whole) the moisture's carry (ten units a row of the wind, one a row of each blend); true when the grid is made. A budget
	## of the whole job or more goes through it in the one call.
	func step(n: int) -> bool:
		if done:
			return true
		var left: int = n
		var total: int = w * h
		if cell < total:
			var last: int = mini(total, cell + n)
			for i in range(cell, last):
				var r: int = i / w
				var k: int = i - r * w
				var y: float = -1.0 + (float(r) + 0.5) * 2.0 / float(h)
				var c: float = sqrt(1.0 - y * y)
				ht[i] = WorldPlanet.ground(P, c * _cs[k], y, c * _sn[k])
			left -= last - cell
			spent += last - cell
			cell = last
			if cell < total:
				return false
			_cph = 1
			_crow = 0
			_east.resize(total)
			_west.resize(total)
			_mix.resize(total)
			_vb.resize(total)
		if left > 0 or n >= total:
			_carry(left)
		return done

	func finishNow() -> void:
		step(1 << 40)

	## The wind's moisture, both ways round each row twice (so the carry crosses the seam), then the two blended by the latitude's wind and blurred a little between rows; stepped by rows, the same arithmetic.
	func _carry(left0: int) -> void:
		var left: int = left0
		var d: Dictionary = WorldClimate.data().moist
		var evap: float = d.evap
		var rain0: float = d.rain0
		var rainOro: float = d.rainOro
		var oroH: float = d.oroH
		var b: float = d.blur
		var bh: float = d.blurLon
		while _cph < 5 and (left > 0 or left0 >= (1 << 30)):
			if _cph == 1:
				var r: int = _crow
				var base: int = r * w
				for dir in range(2):
					var m: float = 0.0
					for lap in range(2 * w):
						var k: int = lap % w if dir == 0 else w - 1 - (lap % w)
						var kp: int = (k - 1 + w) % w if dir == 0 else (k + 1) % w
						var hh: float = ht[base + k]
						if hh < 0.0:
							m = minf(1.0, m + evap)
						else:
							var rise: float = maxf(0.0, hh - maxf(ht[base + kp], 0.0))
							m = maxf(0.0, m - rain0 - rainOro * rise / oroH)
						if lap >= w:
							if dir == 0:
								_west[base + k] = m
							else:
								_east[base + k] = m
				_crow += 1
				left -= 10
				spent += 10
				if _crow >= h:
					_cph = 2
					_crow = 0
			elif _cph == 2:
				var r: int = _crow
				var y: float = -1.0 + (float(r) + 0.5) * 2.0 / float(h)
				var we: float = WorldClimate.westerly(y)
				for k in range(w):
					_mix[r * w + k] = _west[r * w + k] * we + _east[r * w + k] * (1.0 - we)
				_crow += 1
				left -= 1
				spent += 1
				if _crow >= h:
					_cph = 3
					_crow = 0
			elif _cph == 3:
				var r: int = _crow
				var ra: int = maxi(0, r - 1)
				var rb: int = mini(h - 1, r + 1)
				for k in range(w):
					_vb[r * w + k] = _mix[r * w + k] * (1.0 - 2.0 * b) + _mix[ra * w + k] * b + _mix[rb * w + k] * b
				_crow += 1
				left -= 1
				spent += 1
				if _crow >= h:
					_cph = 4
					_crow = 0
			else:
				var r: int = _crow
				for k in range(w):
					adv[r * w + k] = _vb[r * w + k] * (1.0 - 2.0 * bh) + _vb[r * w + (k - 1 + w) % w] * bh + _vb[r * w + (k + 1) % w] * bh
				_crow += 1
				left -= 1
				spent += 1
				if _crow >= h:
					_cph = 5
					done = true
					_east = PackedFloat32Array()
					_west = PackedFloat32Array()
					_mix = PackedFloat32Array()
					_vb = PackedFloat32Array()


'''
    return s[:a] + new + s[b:]


def planet(s):
    # ---- the memos: the oldest goes, not all
    s = rep(s, '''static func _memoPlanet(key: int, P: Planet) -> void:
	if _planets.size() > 6:
		_planets.clear()
	_planets[key] = P
''', '''static func _memoPlanet(key: int, P: Planet) -> void:
	while _planets.size() >= 7 and not _planets.has(key):
		_planets.erase(_planets.keys()[0])   # the oldest made goes (a Dictionary keeps its insertion order): the others stay, a host that loads a planet right before its match no longer loses them all
	_planets[key] = P
''')
    old = "\tif _slices.size() > 4:\n\t\t_slices.clear()\n\t_slices[key] = S\n"
    assert s.count(old) == 2
    s = s.replace(old, "\t_memoSlice(key, S)\n")
    s = rep(s, '''	if _slices.size() > 4:
		_slices.clear()
	_slices[_ringKey(seed, ring, PackedByteArray())] = slice
''', '''	_memoSlice(_ringKey(seed, ring, PackedByteArray()), slice)


## The slice memo keeps a few (five); a sixth evicts the oldest, not all.
static func _memoSlice(key: String, S: Slice) -> void:
	while _slices.size() > 4 and not _slices.has(key):
		_slices.erase(_slices.keys()[0])
	_slices[key] = S
''')
    # ---- the places: a try-set resumable
    a = s.index("static func _tryPlace(P: Planet, r: SimRng, kind: int, radius: float, tries: int, polar: bool) -> bool:")
    b = s.index("## The places of a planet: first as picture A placed them")
    tryplace = '''## What a try costs in the job's units (one is about 20 us): the height test, the gap test, the score (a gen 2 planet's climate and site reads): measured 53, 124 and 284 us a try.
const TRY_U_H: int = 3
const TRY_U_GAP: int = 3
const TRY_U_SCORE: int = 8


static func _tsBegin() -> Dictionary:
	return {"k": 0, "best": null, "bs": -1.0e9, "done": false}


## Up to `units` of a try-set's work, resuming at ts.k (the tries' draws in the same order as ever, so the same places): returns the units spent; ts.done when the set is made (the best of its tries placed).
static func _tryRun(P: Planet, r: SimRng, kind: int, radius: float, tries: int, polar: bool, ts: Dictionary, units: int) -> int:
	var c: Dictionary = P.c
	var spent: int = 0
	var best = ts.best
	var bs: float = ts.bs
	var k: int = ts.k
	while k < tries and spent < units:
		k += 1
		var p: Array = _randUnit(r)
		var h: float = ground(P, p[0], p[1], p[2])
		spent += TRY_U_H
		if h < c.placeHMin or h > c.placeHMax or (polar and absf(p[1]) > c.placeYMax):
			continue
		var dmin: float = 1.0e9
		for i in range(P.n):
			var g: float = _arc(P, p, P.px[i], P.py[i], P.pz[i]) - P.rad[i] - radius
			if g < dmin:
				dmin = g
		spent += TRY_U_GAP
		if dmin < c.placeGap:
			continue
		var sc: float = dmin * c.scoreGap - absf(h - c.scoreH0) * c.scoreHW + r.next()
		if P.gen >= 2:   # window 4: a harbour for a city, a fertile biome, nothing on ice, in the sea or on a range
			if sc + WorldSites.maxBonus(kind) <= bs:
				continue   # the climate term cannot lift it past the best so far
			spent += TRY_U_SCORE
			var bonus: float = WorldSites.score(P, kind, p[0], p[1], p[2], bs - sc)
			if bonus <= -1.0e8:
				continue
			sc += bonus
		if sc > bs:
			bs = sc
			best = p
	ts.k = k
	ts.best = best
	ts.bs = bs
	if k >= tries:
		ts.done = true
		if best != null:
			P.kind.append(kind)
			P.px.append(best[0])
			P.py.append(best[1])
			P.pz.append(best[2])
			P.rad.append(radius)
			P.n += 1
	return spent


static func _tryPlace(P: Planet, r: SimRng, kind: int, radius: float, tries: int, polar: bool) -> bool:
	var ts: Dictionary = _tsBegin()
	_tryRun(P, r, kind, radius, tries, polar, ts, 1 << 40)
	return ts.best != null


'''
    s = s[:a] + tryplace + s[b:]
    s = rep(s, '''	return {"r": SimRng.new(P.seed * int(P.c.placeSeedMul) + 1), "r2": null, "i": 0, "phase": 0, "dropped": [0, 0]}''',
            '''	return {"r": SimRng.new(P.seed * int(P.c.placeSeedMul) + 1), "r2": null, "i": 0, "phase": 0, "dropped": [0, 0], "ts": null, "spent": 0}''')
    a = s.index("## One _tryPlace (or the step between the two streams, or the last step); true when the places are all made.")
    b = s.index("## The people of a place at full, by weight (relative).")
    old = s[a:b]
    new = old
    new = new.replace("## One _tryPlace (or the step between the two streams, or the last step); true when the places are all made.",
                      "## Up to `units` of a try-set (a few tries: _tryRun), or the step between the two streams, or the last step; true when the places are all made. The default is a whole try-set a call, as it always was.\n## st.spent adds up the units a call spent (the job's budget is told in these).")
    new = new.replace("static func _placeStep(P: Planet, st: Dictionary) -> bool:", "static func _placeStep(P: Planet, st: Dictionary, units: int = 1 << 40) -> bool:")
    new = new.replace('''		var i: int = st.i
		if i < nc:
			_tryPlace(P, st.r, KIND_CITY, c.cityRadius, int(c.cityTries), false)
		elif i < nc + nt:
			_tryPlace(P, st.r, KIND_TOWN, c.townRadius, int(c.townTries), false)
		st.i = i + 1
''', '''		var i: int = st.i
		if i < nc + nt:
			if st.ts == null:
				st.ts = _tsBegin()
			if i < nc:
				st.spent += _tryRun(P, st.r, KIND_CITY, c.cityRadius, int(c.cityTries), false, st.ts, units)
			else:
				st.spent += _tryRun(P, st.r, KIND_TOWN, c.townRadius, int(c.townTries), false, st.ts, units)
			if not st.ts.done:
				return false
			st.ts = null
		st.i = i + 1
''')
    new = new.replace('''	if j < nd:
		if j < int(dr[KIND_CITY]):
			_tryPlace(P, st.r2, KIND_CITY, c.cityRadius, int(c.replaceTries), true)
		else:
			_tryPlace(P, st.r2, KIND_TOWN, c.townRadius, int(c.replaceTries), true)
		st.i = j + 1
''', '''	if j < nd:
		if st.ts == null:
			st.ts = _tsBegin()
		if j < int(dr[KIND_CITY]):
			st.spent += _tryRun(P, st.r2, KIND_CITY, c.cityRadius, int(c.replaceTries), true, st.ts, units)
		else:
			st.spent += _tryRun(P, st.r2, KIND_TOWN, c.townRadius, int(c.replaceTries), true, st.ts, units)
		if not st.ts.done:
			return false
		st.ts = null
		st.i = j + 1
''')
    assert new != old and new.count("st.spent +=") == 4
    s = s[:a] + new + s[b:]
    # ---- the planet job
    a = s.index("class PlanetJob extends RefCounted:")
    b = s.index("## Whether make(seed) would find the planet made")
    job = '''class PlanetJob extends RefCounted:
	const PLACE_COST: int = 1000
	const FLOW_CELLS: int = 50   # ticks of the flow field's work (about 0.4 us each) to a budget unit (about 20 us): about 370,000 whole, FLOW_COST units
	var seed: int = 0
	var key: int = 0
	var P: WorldPlanet.Planet
	var done: bool = false
	var _grid = null
	var _flow = null   # the rivers' drainage of the grid, stepped (WorldRivers.Flow)
	var _st: Dictionary = {}

	func _init(sd: int) -> void:
		seed = sd
		var gn: int = WorldClimate.genNow()
		key = sd * 4 + gn
		if WorldPlanet._planets.has(key):
			P = WorldPlanet._planets[key]
			done = true
			return
		P = WorldPlanet._newPlanet(sd, gn)
		if gn >= 2:
			_grid = WorldClimate.Grid.new(P)
		_st = WorldPlanet._placeBegin(P)

	## Spends up to `budget` units: the grid's cells and its carry's rows, the flow field's cells, the places' tries (a unit is about 20 us); every piece goes on where it left off, so a call is about the budget (a
	## try, a row of the wind or a circle may go a little over) and never a whole piece. A budget of the whole job or more goes through every piece in the one call.
	func step(budget: int) -> bool:
		if done:
			return true
		var left: int = budget
		if _grid != null:
			var before: int = _grid.spent
			_grid.step(left)
			left -= _grid.spent - before
			if not _grid.done:
				return false
			P.grid = _grid
			_grid = null
			if WorldRivers.enabled() and P.flow == null:   # the drainage of the grid (about 155 ms whole), made a few cells at a time
				_flow = WorldRivers.Flow.new(P.grid, false)
			if left <= 0:
				return false
		if _flow != null:
			var s0: int = _flow.spent
			var fin: bool = _flow.step(maxi(1, left * FLOW_CELLS))
			left -= maxi(1, (_flow.spent - s0 + FLOW_CELLS - 1) / FLOW_CELLS)
			if not fin:
				return false
			P.flow = _flow
			_flow = null
			if left <= 0:
				return false
		while true:
			_st.spent = 0
			var fin2: bool = WorldPlanet._placeStep(P, _st, maxi(1, left))
			left -= maxi(1, int(_st.spent))
			if fin2:
				WorldPlanet._memoPlanet(key, P)
				done = true
				return true
			if left <= 0:
				return false
		return done


'''
    s = s[:a] + job + s[b:]
    # ---- a touch-down's ring in steps
    a = s.index("## The ground beside a ring (window 2, the slow drift")
    sj = '''## A touch-down's ring read in steps (what sliceFor reads in one piece): the touch's point and candidate circles, each circle evaluated (a step takes at most one: about 96 surface reads, 4 to 6 ms) until one meets the
## minimum, then the ring's columns a slice at a time, then its held places; at the end the slice is memoised where sliceFor finds it, so sliceFor (and a match's start) then returns it at once. The slice is the
## same one, bit for bit. `slice` is null when no circle met the minimum (sliceFor's null). The planet is World's memo (make(seed): a cold planet would be made in one piece here, so a host loads it first); the arena's
## columns (SimConst.NC) must be the same for every call as for the first.
class SliceJob extends RefCounted:
	const COLUMN_UNITS: int = 2   # a ring column's read, in units (about 40 us on a gen 2 planet)
	const HELD_UNITS: int = 100   # the held places and the fine biomes' blend (about 2 ms)
	var seed: int = 0
	var touch: int = 0
	var standing := PackedByteArray()
	var relaxed: bool = false
	var side: int = 1
	var key: String = ""
	var slice = null
	var done: bool = false
	var _ph: int = 0   # 0 the planet and the candidates, 1 the circles, 2 the columns, 3 the held places
	var _P: WorldPlanet.Planet
	var _T: Array = []
	var _cand: Array = []
	var _ci: int = 0
	var _S = null
	var _i: int = 0

	func _init(sd: int, tch: int, st: PackedByteArray = PackedByteArray(), rel: bool = false, sd2: int = 1) -> void:
		seed = sd
		touch = tch
		standing = st
		relaxed = rel
		side = sd2
		key = "%d/%d/%s/%d/%s/%d/%d" % [sd, tch, str(st.hex_encode()), 1 if rel else 0, WorldPlanet.dataHash(), SimConst.NC, sd2]
		if WorldPlanet._slices.has(key):
			slice = WorldPlanet._slices[key]
			done = true

	func step(units: int) -> bool:
		if done:
			return true
		var left: int = maxi(1, units)
		while left > 0 and not done:
			if _ph == 0:
				_P = WorldPlanet.make(seed)
				_T = WorldPlanet.touchPoint(_P, touch)
				_cand = WorldPlanet.candidates(_P, _T, touch, standing)
				_ph = 1
				left -= 1
			elif _ph == 1:
				if _ci >= _cand.size():
					done = true   # no circle met the minimum: sliceFor's null (not memoised)
					return true
				var c: Dictionary = _P.c
				var circ: Dictionary = _cand[_ci]
				_ci += 1
				var needC: int = int(c.relaxCities) if relaxed else int(c.minCities)
				var needT: int = int(c.relaxTowns) if relaxed else int(c.minTowns)
				var e: Dictionary = WorldPlanet.evalCircle(_P, circ, standing, needC, needT)
				left -= 1 if e.get("skipped", false) else 2 * int(c.samples)
				if WorldPlanet.meets(c, e, relaxed):
					_S = WorldPlanet.readBegin(_P, WorldPlanet.ringThrough(circ, SimConst.NC, side), _T)
					_i = 0
					_ph = 2
			elif _ph == 2:
				var j: int = mini(SimConst.NC, _i + maxi(1, left / COLUMN_UNITS))
				WorldPlanet.readColumns(_P, _S, _i, j)
				left -= (j - _i) * COLUMN_UNITS
				_i = j
				if _i >= SimConst.NC:
					_ph = 3
			else:
				WorldPlanet.readHeld(_P, _S, standing)
				left -= HELD_UNITS
				slice = _S
				WorldPlanet._memoSlice(key, _S)
				_S = null
				done = true
		return done


'''
    s = s[:a] + sj + s[a:]
    return s


def rivers(s):
    return flow_steps.rivers(s)


rw(R, 'sim/world/climate.gd', climate)
rw(R, 'sim/world/rivers.gd', rivers)
rw(R, 'sim/world/planet.gd', planet)
print('p21 applied')
