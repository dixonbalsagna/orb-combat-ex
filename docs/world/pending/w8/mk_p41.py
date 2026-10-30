"""World, 2026-10-30: hash helpers for the replay header, and the swapped ring's job and preparation kept for 21 ticks.   python mk_p41.py <root>   (root: main)
 - sim/world/density.gd: enabled(), dataHash() (cached, the parsed data without the "_" notes)
 - sim/world/climate.gd: genFor(setup): the generation a setup's planet is made by (its planetGen, else climate.json's gen; never genNow())
 - sim/world/planet.gd: dataHash(gen = 0): keyed on the generation given (genFor(setup)), genNow() when 0 (every caller so far)
 - sim/world/epoch.gd: swap() retires the ring jobs and the preparation of the world it leaves for KEEP_TICKS instead of dropping them (a rollback that runs the swap again finds them: no cold read, no unprep);
   tick() sweeps what has aged out; release(S) drops a disposed sim's; cold and unprep are process counters (coldCount, unprepCount), no longer in S.epoch
 - sim/world/tools/epoch_check.gd: reads the counters, and checks the retention"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def density(s):
    s = rep(s, '''static var _errors: Array = []
''', '''static var _errors: Array = []
static var _hash: String = ""
''')
    s = rep(s, '''	_d = j


## True for a gen 2 ring with the module on.
static func on() -> bool:
	return bool(data().get("enabled", false)) and WorldClimate.genNow() >= 2
''', '''	_d = j
	var h := SimHash.Hasher.new()
	h.text("biomes.density")
	FighterData._canon(h, j)
	_hash = h.hex()


## The module's switch (a gen 2 ring reads the file only when it is on).
static func enabled() -> bool:
	return bool(data().get("enabled", false))


## A hash of the parsed data without the "_" notes, made once, for the replay header (a gen 2 replay's buildings follow this file). "" when the file did not load.
static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash


## True for a gen 2 ring with the module on.
static func on() -> bool:
	return enabled() and WorldClimate.genNow() >= 2
''')
    return s


def climate(s):
    return rep(s, '''static func useGen(g: int) -> void:
	curGen = g
''', '''static func useGen(g: int) -> void:
	curGen = g


## The generation a setup's planet is made by: its planetGen, else the data's (WorldPlanetWorld.gen's rule). Never genNow(), which is a tool's choice in force or the last match's: a replay header is made before the match.
static func genFor(setup: Dictionary) -> int:
	var g: int = int(setup.get("planetGen", 0))
	return g if g > 0 else int(data().get("gen", 1))
''')


def planet(s):
    return rep(s, '''## Folded into the replay's data hash when a planet is used.
static func dataHash() -> String:
	if not _cLoaded:
		_cLoad()
	if WorldClimate.genNow() >= 2:''', '''## Folded into the replay's data hash when a planet is used. gen: the generation the planet is made by (WorldClimate.genFor(setup)); 0 is the one in force (genNow).
static func dataHash(gen: int = 0) -> String:
	if not _cLoaded:
		_cLoad()
	if (gen if gen > 0 else WorldClimate.genNow()) >= 2:''')


def epoch(s):
    s = rep(s, '''static var _jobs: Dictionary = {}   # "worldId/bearing" -> RingJob (the warm read of a candidate ring, kept whole until the swap): derived data outside the state; the state keeps how many columns it was asked for
''', '''static var _jobs: Dictionary = {}   # "worldId/bearing" -> RingJob (the warm read of a candidate ring, kept whole until the swap): derived data outside the state; the state keeps how many columns it was asked for
static var _retired: Array = []   # [[worldId, owner (the sim's instance id), the S.tick the world's jobs and preparation go at]]: a swap leaves the world it turned away from in _plans and _jobs for KEEP_TICKS (see swap)
static var coldCount: int = 0     # process diagnostics, not state (a rolled-back re-run of a swap must leave the state as a straight run does): swaps that read their ring on the swap tick
static var unprepCount: int = 0   # ... and swaps that made their preparation on the swap tick
const KEEP_TICKS: int = 21        # NetSession's maxAhead 20 + 1: a rollback can run a swap again at most this many ticks after it
''')
    s = rep(s, '"refused": 0, "waited": 0, "cold": 0, "unprep": 0, "chords"', '"refused": 0, "waited": 0, "chords"')
    s = rep(s, '''static func tick(S: SimState, hold: bool = true) -> void:
	var E = S.epoch
	if E == null or E.next == null:
		return
''', '''static func tick(S: SimState, hold: bool = true) -> void:
	var E = S.epoch
	if not _retired.is_empty():
		_sweep(S)
	if E == null or E.next == null:
		return
''')
    s = rep(s, '''static func _dropJobs(S: SimState) -> void:
	_plans.erase(S.worldId)
	var pre: String = "%d/" % S.worldId
	for k in _jobs.keys():
		if String(k).begins_with(pre):
			_jobs.erase(k)
''', '''static func _dropJobs(S: SimState) -> void:
	_dropWorld(S.worldId)


static func _dropWorld(wid: int) -> void:
	_plans.erase(wid)
	var pre: String = "%d/" % wid
	for k in _jobs.keys():
		if String(k).begins_with(pre):
			_jobs.erase(k)


## The swap leaves its world's ring jobs and preparation in place for KEEP_TICKS, keyed by the world it turned away from (the new world has its own id): a rollback that restores a state of that world and
## runs the swap again finds them, and the re-run is the swap it was (no ring read on the tick, no preparation made on it) instead of the cold one. A swap run again renews the term.
static func _retire(S: SimState) -> void:
	var me: int = S.get_instance_id()
	for r in _retired:
		if int(r[0]) == S.worldId and int(r[1]) == me:
			r[2] = S.tick + KEEP_TICKS
			return
	_retired.append([S.worldId, me, S.tick + KEEP_TICKS])


## Drops what has aged out, for this sim's retired worlds: called each tick, free when nothing is retired.
static func _sweep(S: SimState) -> void:
	var me: int = S.get_instance_id()
	var keep: Array = []
	for r in _retired:
		if int(r[1]) == me and S.tick >= int(r[2]):
			_dropWorld(int(r[0]))
		else:
			keep.append(r)
	_retired = keep


## A sim is disposed (SimCore.dispose): its world's jobs and preparation and every world it retired go with it. They are derived data in static dictionaries, so nothing else would drop them.
static func release(S: SimState) -> void:
	var me: int = S.get_instance_id()
	var keep: Array = []
	for r in _retired:
		if int(r[1]) == me:
			_dropWorld(int(r[0]))
		else:
			keep.append(r)
	_retired = keep
	_dropWorld(S.worldId)
''')
    s = rep(s, '''		E.cold = int(E.cold) + 1   # a ring read on the swap tick''', '''		coldCount += 1   # a ring read on the swap tick''')
    s = rep(s, '''		E.unprep = int(E.unprep) + 1   # a preparation lost''', '''		unprepCount += 1   # a preparation lost''')
    s = rep(s, '''		_prepTo(S, E, pl, ep, sl, int(data().prepTicks) - 1, int(data().prepTicks))
	_dropJobs(S)
	var NC: int = SimConst.NC''', '''		_prepTo(S, E, pl, ep, sl, int(data().prepTicks) - 1, int(data().prepTicks))
	_retire(S)   # kept for KEEP_TICKS, under this world's id (the swap gives the sim a new one below)
	var NC: int = SimConst.NC''')
    return s


rw(R, 'sim/world/density.gd', density)
rw(R, 'sim/world/climate.gd', climate)
rw(R, 'sim/world/planet.gd', planet)
rw(R, 'sim/world/epoch.gd', epoch)
print('p41 applied')
