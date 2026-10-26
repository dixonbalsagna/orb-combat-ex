class_name WorldCampaign
extends RefCounted
## World's part of the campaign's first slice (docs/design/campaign.md sections 1.4, 2.2, 2.3 and 7; docs/world/campaign-route.md; data/biomes/campaign.json, off by default). Three things, all pure functions of
## the planet, the ring, the episode's seed and the run's place state (no clock, no state, no draw from a stream: every draw is a keyed one):
##   column(...)  the places a column offers on the ring the pair are flying, each within 10 to 25 s of flight of where they are, and, when the ring would offer a poorer choice than a turned one, the turn
##                (the ring turns about the pair's point at a calm moment, between columns). The climax (column 5) is the boss's home: the ring through the pair and it.
##   side(...)    a side story's place (campaign 1.4): a standing city or town on the current ring within the usual flight, and the Close ring round it for the filler episode.
##   wounds       a place's wear is a band 0 to 3 (scarred, ruined, fallen) and nothing else (Legal mc02: place state only, never a count of people): wearOf reads a finished stage, mergeWear keeps the worse
##                band, standingOf and damagedOf feed the ring picker, applyWear lays a place's wear on a later stage's buildings.
## A ring travels as the setup's `arena` ({cols, c, t} with the axis and the touch-down as exact bits, WorldRingPick.arenaOf), so a run state holds it as JSON. The pair stands at column `pc` of it (the
## touch-down's column, cols / 2, when a stage starts there); a result's `start` is the same ring with its touch-down at the pair's point, which is what the next stage's setup.arena wants.
## The planner is independent of SimConst.NC (a match sets it; the planner runs between matches): columns are the ring's own, mid = cols / 2.

const PATH := "res://data/biomes/campaign.json"
const SCHEMA := "biomes.campaign/1"
const BIO_OCEAN: int = 0
const BIO_SEA_ICE: int = 6
const BIO_NAMES: Array = ["ocean", "plains", "forest", "desert", "mountains", "ice_sheet", "sea_ice", "village", "city"]

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""
static var K_ON: bool = false
static var K_SPEED: float = 1032.0
static var K_MIN_S: float = 10.0
static var K_MAX_S: float = 25.0
static var K_CLIMAX_S: float = 45.0
static var _cols: Array = []
static var K_STRIDE: int = 8
static var K_SEP_S: float = 5.0
static var K_JIT: float = 0.25
static var K_NOVEL: float = 0.4
static var K_FALLEN: float = 1.0
static var K_OPEN_MIN: float = 0.5
static var K_BEAR: Array = []
static var K_TURN_BONUS: float = 0.3
static var K_TURN_GAIN: float = 0.2
static var K_SIDE_SEP: float = 3.0
static var K_SIDE_COLS: int = 1200
static var K_W_BAND: Array = []
static var K_W_FALLEN: Array = []
static var K_W_HP: Array = []


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


## The data's hash; the replay's data hash carries it only while the campaign is on (Simulation's call: nothing here is read otherwise).
static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash


## Is the campaign on? The data's switch (campaign.enabled).
static func enabled() -> bool:
	if not _loaded:
		_load()
	return K_ON


## For tools and checks: the switch for this process (the file is not touched).
static func setOn(on: bool) -> void:
	if not _loaded:
		_load()
	K_ON = on and _errors.is_empty()


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_errors.append("campaign.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("campaign.json: not a %s object" % SCHEMA)
		return
	for k in ["enabled", "flight", "columns", "sites", "turn", "side", "wear"]:
		if not j.has(k):
			_errors.append("campaign.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	if j.columns.size() != 5:
		_errors.append("campaign.json: columns has the campaign's five entries")
	for c in j.columns:
		if int(c.min) < 1 or int(c.max) < int(c.min) or int(c.max) > 4 or float(c.pThree) < 0.0 or float(c.pThree) > 1.0 or int(c.settled) > int(c.max):
			_errors.append("campaign.json: a column has 1 to 4 places (min within max), pThree in [0, 1] and no more settled than it offers")
	var fl: Dictionary = j.flight
	if float(fl.speed) <= 0.0 or float(fl.minS) <= 0.0 or float(fl.maxS) <= float(fl.minS) or float(fl.climaxMaxS) < float(fl.maxS):
		_errors.append("campaign.json: flight.speed and minS above 0, maxS above minS, climaxMaxS at least maxS")
	if int(j.sites.openStride) < 1 or int(j.side.ringCols) < 100:
		_errors.append("campaign.json: sites.openStride at least 1 and side.ringCols at least 100")
	if j.wear.band.size() != 3 or j.wear.fallen.size() != 4 or j.wear.hpKeep.size() != 4:
		_errors.append("campaign.json: wear has 3 bands and 4 entries of fallen and hpKeep")
	if not _errors.is_empty():
		return
	_d = j
	_hash = str(text.hash())
	K_ON = bool(j.enabled)
	K_SPEED = float(fl.speed)
	K_MIN_S = float(fl.minS)
	K_MAX_S = float(fl.maxS)
	K_CLIMAX_S = float(fl.climaxMaxS)
	_cols = j.columns
	K_STRIDE = int(j.sites.openStride)
	K_SEP_S = float(j.sites.sepS)
	K_JIT = float(j.sites.jitter)
	K_NOVEL = float(j.sites.novelty)
	K_FALLEN = float(j.sites.fallen)
	K_OPEN_MIN = float(j.sites.openMin)
	K_BEAR = j.turn.bearings
	K_TURN_BONUS = float(j.turn.bonus)
	K_TURN_GAIN = float(j.turn.minGain)
	K_SIDE_SEP = float(j.side.sepS)
	K_SIDE_COLS = int(j.side.ringCols)
	K_W_BAND = j.wear.band
	K_W_FALLEN = j.wear.fallen
	K_W_HP = j.wear.hpKeep


# ===================================================================== geometry

## The signed number of columns from column `from` to column `to` the short way round a ring of `cols`.
static func arcCols(from: int, to: int, cols: int) -> int:
	var d: int = posmod(to - from, cols)
	if d > cols / 2:
		d -= cols
	return d


## The ring as {c, t, cols} (the touch-down as the point at angle 0) from the setup's `arena`.
static func specOf(arena: Dictionary) -> Dictionary:
	var ring: Dictionary = WorldRingPick.ringOfArena(arena)
	return {"c": ring.c, "t": WorldRingPick.ringPoint(ring, 0.0), "cols": int(arena.cols)}


## The same ring with its touch-down at the pair's point (column pc of `spec`): the ring a stage that starts where they stand plays on. mid is the touch-down's column, cols / 2.
static func rebased(P: WorldPlanet.Planet, spec: Dictionary, pc: int) -> Dictionary:
	var cols: int = int(spec.cols)
	var ring: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
	var a: float = float(pc - cols / 2) * SimConst.COL / (P.R * float(ring.st))
	return {"c": spec.c, "t": WorldRingPick.ringPoint(ring, a), "cols": cols}


## Turn `spec` by `deg` about its point at column pc (WorldEpoch.turned, with this ring's own middle column).
static func turnedSpec(P: WorldPlanet.Planet, spec: Dictionary, pc: int, deg: float) -> Dictionary:
	return WorldEpoch.turned(P, spec, pc, deg, int(spec.cols) / 2)


static func _fineName(P: WorldPlanet.Planet) -> String:
	return WorldClimate.fineName(P.outF) if P.outF >= 0 else BIO_NAMES[clampi(P.outB, 0, BIO_NAMES.size() - 1)]


## What the ring holds within the flight band of the pair (at column pc): the settled places and open ground, as candidates {kind, place, col, half, arc, entry, flightS, settled, biome, fine, feats, band, fallen, key}.
## arc: the signed columns from the pair to the place's centre; entry: the columns to its near edge (0 inside it); flightS: the seconds of flight to the edge. `wear`: place id (as text) to band.
static func _candidates(P: WorldPlanet.Planet, spec: Dictionary, pc: int, minS: float, maxS: float, wear: Dictionary) -> Array:
	var cols: int = int(spec.cols)
	var mid: int = cols / 2
	var ring: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
	var step: float = SimConst.COL / (P.R * float(ring.st))
	var COL: float = SimConst.COL
	var c: Dictionary = P.c
	var lo: int = int(ceil(minS * K_SPEED / COL))
	var hi: int = mini(int(floor(maxS * K_SPEED / COL)), cols / 2)
	var out: Array = []
	var held: Array = []   # [centre column, half columns] of the places (open ground keeps clear of them)
	var u: Array = ring.u
	var v: Array = ring.v
	var arcR: float = P.R * float(ring.st)
	for i in range(P.n):
		var lat: float = WorldPlanet.lateral(P, ring, P.px[i], P.py[i], P.pz[i])
		var reach: float = (c.cityReach if P.kind[i] == WorldPlanet.KIND_CITY else c.townReach) * P.rad[i]
		if absf(lat) >= reach:
			continue
		var along: float = WorldPlanet.atan2f(P.px[i] * v[0] + P.py[i] * v[1] + P.pz[i] * v[2], P.px[i] * u[0] + P.py[i] * u[1] + P.pz[i] * u[2])
		var cc: int = posmod(mid + int(round(along / step)), cols)
		var half: int = int(sqrt(maxf(0.0, P.rad[i] * P.rad[i] - lat * lat)) / COL)
		held.append([cc, half])
		var arc: int = arcCols(pc, cc, cols)
		var entry: int = maxi(0, absi(arc) - half)
		var fs: float = float(entry) * COL / K_SPEED
		if fs < minS or fs > maxS:
			continue
		var band: int = int(wear.get(str(i), 0))
		var city: bool = P.kind[i] == WorldPlanet.KIND_CITY
		out.append({"kind": "city" if city else "town", "place": i, "col": cc, "half": half, "arc": arc, "entry": entry, "flightS": fs, "settled": true, "biome": 8 if city else 7, "fine": "", "feats": ["settled"], "band": band, "fallen": band >= 3, "key": 1000000 + i})
	# open ground: every stride-th column in the band, either side, on land and clear of the places
	for sgn in [-1, 1]:
		var dd: int = lo
		while dd <= hi:
			var cc: int = posmod(pc + sgn * dd, cols)
			dd += K_STRIDE
			var inside: bool = false
			for h in held:
				if absi(arcCols(h[0], cc, cols)) <= int(h[1]) + 8:
					inside = true
					break
			if inside:
				continue
			var p: Array = WorldRingPick.ringPoint(ring, float(cc - mid) * step)
			WorldPlanet.surfAt(P, p[0], p[1], p[2])
			var b: int = P.outB
			if b == BIO_OCEAN or b == BIO_SEA_ICE:
				continue
			var fine: String = _fineName(P)
			var land: int = 1
			var coast: bool = false
			for off in [-48, -24, 24, 48]:
				var q: Array = WorldRingPick.ringPoint(ring, float(posmod(cc + off, cols) - mid) * step)
				WorldPlanet.surfAt(P, q[0], q[1], q[2])
				if P.outB == BIO_OCEAN or P.outB == BIO_SEA_ICE:
					coast = true
				else:
					land += 1
			if float(land) / 5.0 < K_OPEN_MIN:
				continue
			var feats: Array = [fine]
			if coast:
				feats.append("coast")
			var oa: int = arcCols(pc, cc, cols)
			out.append({"kind": "open", "place": -1, "col": cc, "half": 4, "arc": oa, "entry": absi(oa), "flightS": float(absi(oa)) * COL / K_SPEED, "settled": false, "biome": b, "fine": fine, "feats": feats, "band": 0, "fallen": false, "key": cc})
	return out


## The column's places from the candidates, greedily: the best base score first, a new kind of ground worth `novelty` more, at least sepS seconds of flight between two, and the settled ones the column asks for
## taken first. Returns {sites (west to east), score}.
static func _choose(cands: Array, col: int, epSeed: int, cfg: Dictionary, cols: int, used: Array) -> Dictionary:
	var sepCols: int = int(ceil(K_SEP_S * K_SPEED / SimConst.COL))
	var pool: Array = []
	for c in cands:
		if c.place >= 0 and used.has(c.place):
			continue
		var s: float = 1.0 + (float(cfg.pull) if c.settled else 0.0) - (K_FALLEN if c.fallen else 0.0)
		s += (SimRng.keyed(epSeed, "camp/c%d" % col, int(c.key)) - 0.5) * 2.0 * K_JIT
		var cc: Dictionary = c.duplicate()
		cc["score"] = s
		pool.append(cc)
	var n: int = int(cfg.min)
	for extra in range(int(cfg.max) - int(cfg.min)):
		if SimRng.keyed(epSeed, "camp/n%d" % col, extra) < float(cfg.pThree):
			n += 1
		else:
			break
	var chosen: Array = []
	var settledHave: int = 0
	var total: float = 0.0
	while chosen.size() < n and not pool.is_empty():
		var forced: bool = int(cfg.settled) - settledHave >= n - chosen.size()
		var best: int = -1
		var bs: float = -1.0e9
		for i in range(pool.size()):
			var c: Dictionary = pool[i]
			if forced and not c.settled:
				continue
			var clash: bool = false
			for h in chosen:
				if absi(arcCols(h.col, c.col, cols)) < sepCols:
					clash = true
					break
			if clash:
				continue
			var s: float = c.score
			var fresh: bool = true
			for h in chosen:
				if h.kind == c.kind and h.biome == c.biome:
					fresh = false
			if fresh and not chosen.is_empty():
				s += K_NOVEL
			if s > bs + 1.0e-12 or (absf(s - bs) <= 1.0e-12 and best >= 0 and c.key < pool[best].key):
				bs = s
				best = i
		if best < 0:
			break
		var pick: Dictionary = pool[best]
		pool.remove_at(best)
		if pick.settled:
			settledHave += 1
		chosen.append(pick)
		total += bs
	if chosen.size() < int(cfg.min):
		total -= 5.0 * float(int(cfg.min) - chosen.size())
	if settledHave < int(cfg.settled):
		total -= 5.0 * float(int(cfg.settled) - settledHave)
	chosen.sort_custom(func(a, b): return a.arc < b.arc)
	return {"sites": chosen, "score": total, "n": n}


static func _publish(sites: Array) -> Array:
	var out: Array = []
	for k in range(sites.size()):
		var s: Dictionary = sites[k]
		out.append({"id": k, "kind": s.kind, "place": s.place, "arc": s.arc, "entry": s.entry, "half": s.half, "dir": 1 if s.arc >= 0 else -1, "flightS": s.flightS, "settled": s.settled, "biome": s.biome, "fine": s.fine, "feats": s.feats, "wear": s.band, "fallen": s.fallen})
	return out


# ===================================================================== the column

## The places of column `col` (1 to 5) of an episode on the planet `planetSeed`, with the episode's seed `epSeed`, for a pair standing at column pc of the ring `arena` (a setup's arena).
## opts: used (place ids the episode has used: not offered again), wear (the run's place state, id as text to band 0 to 3), pin (the climax's home place id: the boss's), turn (false: stay on this ring),
## minS and maxS (the flight band, seconds; the data's by default).
## Returns {ok (the column has all the places it asks for), col, turn (null, or {deg, from}: the ring turns about the pair's point), arena (the ring the places lie on, the pair at its column pc), start (the same ring
## with its touch-down at the pair's point: the next stage's arena), pc (the pair's column in start: cols / 2), cols, resize (the climax's ring is a different length), sites, score, notes}. A site:
## {id, kind (city, town, open), place (planet place id, or -1), arc (signed columns from the pair), entry (columns to its near edge), half, dir (-1 or 1: which way), flightS (seconds to its edge), settled,
## biome, fine, feats, wear, fallen}. The first column's id order is west to east.
static func column(planetSeed: int, epSeed: int, col: int, arena: Dictionary, pc: int, opts: Dictionary = {}) -> Dictionary:
	var job: ColumnJob = beginColumn(planetSeed, epSeed, col, arena, pc, opts)
	job.step(1 << 30)
	return job.result


## The same answer in steps (the host spends a ring's read a frame: the module owns no clock). A ring's read is 20 to 55 ms on a busy PC (the climax's is none); a column reads the ring as it is and each of the
## turns the data's bearings allow, both ways (nine rings with the data's four), so `step(1)` a frame spreads a column over nine frames.
static func beginColumn(planetSeed: int, epSeed: int, col: int, arena: Dictionary, pc: int, opts: Dictionary = {}) -> ColumnJob:
	return ColumnJob.new(planetSeed, epSeed, col, arena, pc, opts)


class ColumnJob extends RefCounted:
	var P: WorldPlanet.Planet
	var epSeed: int = 0
	var col: int = 1
	var cfg: Dictionary = {}
	var base: Dictionary = {}
	var cols: int = 0
	var mid: int = 0
	var wear: Dictionary = {}
	var used: Array = []
	var minS: float = 0.0
	var maxS: float = 0.0
	var pin: int = -1
	var degs: Array = []
	var res: Array = []
	var notes: Array = []
	var done: bool = false
	var result: Dictionary = {}

	func _init(planetSeed: int, es: int, c: int, arena: Dictionary, pc: int, opts: Dictionary) -> void:
		P = WorldPlanet.make(planetSeed)
		epSeed = es
		col = c
		cfg = WorldCampaign._cols_cfg(c)
		var spec: Dictionary = WorldCampaign.specOf(arena)
		cols = int(spec.cols)
		mid = cols / 2
		wear = opts.get("wear", {})
		used = opts.get("used", [])
		minS = float(opts.get("minS", WorldCampaign.K_MIN_S))
		maxS = float(opts.get("maxS", WorldCampaign.K_MAX_S))
		pin = int(opts.get("pin", -1))
		base = WorldCampaign.rebased(P, spec, pc)
		degs = [0.0]
		if not bool(cfg.pinned) and bool(opts.get("turn", true)):
			for dg in WorldCampaign.K_BEAR:
				degs.append(float(dg))
				degs.append(-float(dg))

	## Reads up to n more rings; true when the column is made (`result`).
	func step(n: int) -> bool:
		if done:
			return true
		if bool(cfg.pinned):
			result = WorldCampaign._climax(P, epSeed, col, base, pin, wear, notes)
			done = true
			return true
		var left: int = n
		while res.size() < degs.size() and left > 0:
			var dg: float = degs[res.size()]
			var ts: Dictionary = base if dg == 0.0 else WorldCampaign.turnedSpec(P, base, mid, dg)
			res.append({"deg": dg, "spec": ts, "res": WorldCampaign._choose(WorldCampaign._candidates(P, ts, mid, minS, maxS, wear), col, epSeed, cfg, cols, used)})
			left -= 1
		if res.size() < degs.size():
			return false
		var best: Dictionary = res[0]
		best["total"] = best.res.score
		var noneTotal: float = best.res.score
		notes.append("no turn: %d place(s), score %.2f" % [best.res.sites.size(), best.res.score])
		for k in range(1, res.size()):
			var r: Dictionary = res[k]
			r["total"] = r.res.score + WorldCampaign.K_TURN_BONUS
			notes.append("turn %+.0f: %d place(s), score %.2f" % [r.deg, r.res.sites.size(), r.total])
			if r.total > float(best.total) + 1.0e-12:
				best = r
		if float(best.deg) != 0.0 and float(best.total) < noneTotal + WorldCampaign.K_TURN_GAIN:
			best = res[0]
			notes.append("the best turn gains less than %.2f: the ring stays" % WorldCampaign.K_TURN_GAIN)
		var settledN: int = 0
		for s in best.res.sites:
			if s.settled:
				settledN += 1
		var ok: bool = best.res.sites.size() >= int(cfg.min) and settledN >= int(cfg.settled)
		result = {"ok": ok, "col": col, "turn": null if float(best.deg) == 0.0 else {"deg": float(best.deg), "from": WorldRingPick.arenaOf(base)}, "arena": WorldRingPick.arenaOf(best.spec), "start": WorldRingPick.arenaOf(best.spec),
			"pc": mid, "cols": cols, "resize": false, "sites": WorldCampaign._publish(best.res.sites), "score": float(best.total), "notes": notes}
		done = true
		return true


static func _cols_cfg(col: int) -> Dictionary:
	if not _loaded:
		_load()
	return _cols[clampi(col, 1, _cols.size()) - 1]


## The climax (column 5): the ring through the pair's point and the boss's home place (the whole circle), the home its one place. pin < 0: the most populous standing city. The flight to it is the build-up
## and may pass the band (`far` is true past climaxMaxS).
static func _climax(P: WorldPlanet.Planet, epSeed: int, col: int, base: Dictionary, pin: int, wear: Dictionary, notes: Array) -> Dictionary:
	var home: int = pin
	if home < 0:
		var bp: int = -1
		for i in range(P.n):
			if int(wear.get(str(i), 0)) >= 3:
				continue
			if bp < 0 or P.people[i] > P.people[bp] or (P.people[i] == P.people[bp] and i < bp):
				bp = i
		home = bp
		notes.append("no pinned home: the most populous standing place, %d" % home)
	if home < 0:
		return {"ok": false, "col": col, "turn": null, "arena": WorldRingPick.arenaOf(base), "start": WorldRingPick.arenaOf(base), "pc": int(base.cols) / 2, "cols": int(base.cols), "resize": false, "sites": [], "score": 0.0, "notes": notes}
	var T: Array = base.t
	var H: Array = WorldRingPick.placePoint(P, home)
	var n: Array = WorldPlanet._cross(T, H)
	var nl: float = sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2])
	if nl < 1.0e-9:   # the pair stand on the home (or opposite it): any great circle through the point
		n = WorldPlanet._cross(T, [0.0, 1.0, 0.0] if absf(T[1]) < 0.9 else [1.0, 0.0, 0.0])
	var cols: int = SimConst.PLANET_NC
	var spec: Dictionary = {"c": WorldPlanet._unit(n), "t": T, "cols": cols}
	var ang: float = WorldPlanet.acosf(SimMathx.jclamp(T[0] * H[0] + T[1] * H[1] + T[2] * H[2], -1.0, 1.0))
	var arc: int = int(round(ang * P.R / SimConst.COL))
	var rr: Dictionary = WorldRingPick.ringFrom(spec.c, cols, T)
	var side: int = 1
	var hv: float = H[0] * rr.v[0] + H[1] * rr.v[1] + H[2] * rr.v[2]
	if hv < 0.0:
		side = -1
	arc *= side
	var half: int = int(P.rad[home] / SimConst.COL)
	var entry: int = maxi(0, absi(arc) - half)
	var fs: float = float(entry) * SimConst.COL / K_SPEED
	var city: bool = P.kind[home] == WorldPlanet.KIND_CITY
	var band: int = int(wear.get(str(home), 0))
	var site: Dictionary = {"id": 0, "kind": "city" if city else "town", "place": home, "arc": arc, "entry": entry, "half": half, "dir": side, "flightS": fs, "settled": true, "biome": 8 if city else 7, "fine": "", "feats": ["settled", "home"], "wear": band, "fallen": band >= 3}
	notes.append("the climax: the ring through the pair and place %d, %.1f s of flight%s" % [home, fs, " (the build-up: past the band)" if fs > K_CLIMAX_S else ""])
	var dgs: float = WorldEpoch.driftOf(base.c, spec.c)
	return {"ok": true, "col": col, "turn": {"deg": dgs, "from": WorldRingPick.arenaOf(base), "toward": home}, "arena": WorldRingPick.arenaOf(spec), "start": WorldRingPick.arenaOf(spec), "pc": cols / 2, "cols": cols, "resize": cols != int(base.cols), "sites": [site], "score": 1.0, "notes": notes, "far": fs > K_CLIMAX_S}


# ===================================================================== a side story

## A side story's place (campaign 1.4): a standing city or town on the ring, within the flight band of the pair at column pc, and at least `side.sepS` seconds from each of the column's places (opts.sites: the
## arcs of the places the column offers, in columns). opts: used (place ids), wear. `arcSeed` and `n` key the draw (the arc's, and the episode's number). Returns {ok, site, arena (a Close ring round the
## place, the filler episode's ground), place} or {ok: false, why}. Nothing is drawn when the arc's own draw (H(arc, "side", n), the run's) said no: the caller asks only on a yes.
static func side(planetSeed: int, arcSeed: int, n: int, arena: Dictionary, pc: int, opts: Dictionary = {}) -> Dictionary:
	var P: WorldPlanet.Planet = WorldPlanet.make(planetSeed)
	var spec: Dictionary = specOf(arena)
	var cols: int = int(spec.cols)
	var wear: Dictionary = opts.get("wear", {})
	var used: Array = opts.get("used", [])
	var avoid: Array = opts.get("sites", [])
	var sepCols: int = int(ceil(K_SIDE_SEP * K_SPEED / SimConst.COL))
	var base: Dictionary = rebased(P, spec, pc)
	var best = null
	var bs: float = -1.0e9
	for c in _candidates(P, base, cols / 2, K_MIN_S, K_MAX_S, wear):
		if not c.settled or c.fallen or used.has(c.place):
			continue
		var clash: bool = false
		for a in avoid:
			if absi(arcCols(int(a), int(c.arc), cols)) < sepCols:
				clash = true
		if clash:
			continue
		var s: float = 1.0 + (SimRng.keyed(arcSeed, "camp/side%d" % n, int(c.key)) - 0.5) * 2.0 * K_JIT + (0.2 if c.kind == "city" else 0.0)
		if s > bs:
			bs = s
			best = c
	if best == null:
		return {"ok": false, "why": "no standing city or town within %.0f to %.0f s of flight on this ring" % [K_MIN_S, K_MAX_S]}
	var phi: float = SimRng.keyed(arcSeed, "camp/sidering%d" % n, int(best.place)) * 2.0 * SimMathx.PI
	var rs: Dictionary = WorldRingPick.roundSpec(WorldRingPick.placePoint(P, int(best.place)), K_SIDE_COLS, phi)
	return {"ok": true, "site": _publish([best])[0], "place": int(best.place), "arena": WorldRingPick.arenaOf(rs)}


# ===================================================================== the planet's wounds: place state only

## A finished stage's wear: for each place that has buildings in S, its band 0 to 3 from the share of them that have fallen (the data's band thresholds), as {place id as text: band}, the places with band over 0 only.
## Nothing about people is read.
static func wearOf(S: SimState) -> Dictionary:
	if not _loaded:
		_load()
	var tot: Dictionary = {}
	var lost: Dictionary = {}
	for b in S.buildings:
		if b.place < 0:
			continue
		tot[b.place] = int(tot.get(b.place, 0)) + 1
		if not b.alive:
			lost[b.place] = int(lost.get(b.place, 0)) + 1
	var out: Dictionary = {}
	var ids: Array = tot.keys()
	ids.sort()
	for id in ids:
		var share: float = float(int(lost.get(id, 0))) / float(int(tot[id]))
		var band: int = 0
		for k in range(3):
			if share >= float(K_W_BAND[k]):
				band = k + 1
		if band > 0:
			out[str(id)] = band
	return out


## The run's place state after a stage: the worse band of each place (a wound is never healed here).
static func mergeWear(prev: Dictionary, now: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in prev.keys():
		out[str(k)] = int(prev[k])
	for k in now.keys():
		out[str(k)] = maxi(int(out.get(str(k), 0)), int(now[k]))
	return out


## The standing byte of each of the planet's places for the ring picker: 0 for a fallen place (band 3), else 1.
static func standingOf(P: WorldPlanet.Planet, wear: Dictionary) -> PackedByteArray:
	var s := PackedByteArray()
	s.resize(P.n)
	s.fill(1)
	for k in wear.keys():
		if int(wear[k]) >= 3 and int(k) >= 0 and int(k) < P.n:
			s[int(k)] = 0
	return s


## The place ids hurt (band 1 or more), ascending, for the ring picker's `damaged`.
static func damagedOf(wear: Dictionary) -> Array:
	var out: Array = []
	for k in wear.keys():
		if int(wear[k]) >= 1:
			out.append(int(k))
	out.sort()
	return out


## Lay a place's wear on a stage's buildings, at the match's start (WorldPlanetWorld.gen, before the collateral window): the share of each worn place's buildings the data names for its band are already fallen
## (the lowest by a keyed order, so the same ones every time), their people gone (they count as no casualty of the stage), and the others keep the data's share of their hp. A fallen building leaves its heap.
## Returns the number of buildings laid fallen.
static func applyWear(S: SimState, wear: Dictionary) -> int:
	if not _loaded:
		_load()
	var byPlace: Dictionary = {}
	for b in S.buildings:
		if b.place >= 0 and int(wear.get(str(b.place), 0)) > 0:
			if not byPlace.has(b.place):
				byPlace[b.place] = []
			byPlace[b.place].append(b)
	var ids: Array = byPlace.keys()
	ids.sort()
	var fell: int = 0
	var gone: float = 0.0
	for id in ids:
		var band: int = clampi(int(wear.get(str(id), 0)), 0, 3)
		var list: Array = byPlace[id]
		var order: Array = []
		for b in list:
			order.append([SimRng.keyed(int(id) * 7919 + 13, "wear", int(b.plan)), b.idx])
		order.sort_custom(func(a, c): return a[0] < c[0] or (a[0] == c[0] and a[1] < c[1]))
		var nf: int = int(round(float(K_W_FALLEN[band]) * float(list.size())))
		var keep: float = float(K_W_HP[band])
		for k in range(order.size()):
			var b = S.buildings[order[k][1]]
			if k < nf:
				b.alive = false
				b.hp = 0.0
				gone += b.pop
				b.popAlive = 0.0
				WorldStructures._heap(S, b)
				fell += 1
			else:
				b.hp = maxf(b.maxhp * keep, 1.0)
	if gone > 0.0:
		S.world.pop0 = maxf(S.world.pop0 - gone, 1.0)
	return fell
