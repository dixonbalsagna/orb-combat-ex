"""Window 20, third add-on (World, 2026-10-26): the calm turn's read for Simulation's K (docs/architecture/calm-turn-read.md).   python mk_p23.py <root>   (after mk_p22.py)
 - sim/world/epoch.gd: `_warm` reads `n / rings` of each ring when the turn data's `warmTotal` is 1 (absent or 0: n each ring, as today); each ring is read TO its counted columns (RingJob.readTo), and a ring
   counts as read by the state's count, never by how far a host's job has got; `_prep` hashes to the counted columns; `readAhead(S, units)` steps the warm rings' jobs past the count (a host's idle time), which
   changes no state; `warmPlan(S)` tells a host what is warming
 - sim/world/planet.gd: RingJob.readTo(target)"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def planet(s):
    return rep(s, '''	func step(n: int) -> bool:
		if done:
			return true
		var j: int = mini(SimConst.NC, i + n)
		WorldPlanet.readColumns(P, slice, i, j)
''', '''	## Reads on to column `target` (the columns up to it are read; at the end the places): a job already past it does nothing, so a host that read ahead leaves the sim's tick nothing to do.
	func readTo(target: int) -> bool:
		if done:
			return true
		if i < target:
			return step(target - i)
		return false

	func step(n: int) -> bool:
		if done:
			return true
		var j: int = mini(SimConst.NC, i + n)
		WorldPlanet.readColumns(P, slice, i, j)
''')


def epoch(s):
    s = rep(s, '''static func _warm(S: SimState) -> bool:
	var E = S.epoch
	var n: int = int(E.next.k)
	var all: bool = true
	for w in E.warm:
		if int(w.cols) >= SimConst.NC:
			continue
		var key: String = _jkey(S, float(w.deg))
		var job = _jobs.get(key)
		if job == null:
			var P := WorldPlanet.make(int(E.seed))
			job = WorldPlanet.RingJob.new(P, WorldRingPick.ringFrom(w.spec.c, int(w.spec.cols), w.spec.t))
			if int(w.cols) > 0:
				job.step(int(w.cols))   # the catch-up of a carried state
			_jobs[key] = job
		job.step(n)
		w.cols = int(w.cols) + n
		if job.done:
			w.cols = maxi(int(w.cols), SimConst.NC)
			if int(w.ptk) < 0:
				w.ptk = 0   # read: its preparation's ticks begin (the first is this one: _prep, below)
			WorldPlanet.memoRing(int(E.seed), job.ring, job.slice)
		else:
			w.cols = mini(int(w.cols), SimConst.NC - 1)
			all = false
	_prep(S, E)
	return all
''', '''static func _warm(S: SimState) -> bool:
	var E = S.epoch
	var n: int = _share(E)
	var all: bool = true
	for w in E.warm:
		if int(w.cols) >= SimConst.NC:
			continue
		var job = _jobFor(S, E, w)
		var target: int = int(w.cols) + n
		job.readTo(target)   # up to the counted columns: a job a host has read ahead is there already
		w.cols = target
		if target >= SimConst.NC:   # the count says read (never how far a host's job has got: a replay warms on the same tick)
			w.cols = maxi(int(w.cols), SimConst.NC)
			if int(w.ptk) < 0:
				w.ptk = 0   # read: its preparation's ticks begin (the first is this one: _prep, below)
			WorldPlanet.memoRing(int(E.seed), job.ring, job.slice)
		else:
			w.cols = mini(int(w.cols), SimConst.NC - 1)
			all = false
	_prep(S, E)
	return all


## The columns a warm tick reads of each ring: the pick's k each (the turn data's `warmTotal` 0, as always), or k in all shared among the warm rings (`warmTotal` 1: a launch pick's two rings cost a tick what a form pick's one does).
static func _share(E: Dictionary) -> int:
	var n: int = int(E.next.k)
	if int(data().get("warmTotal", 0)) == 1 and E.warm.size() > 1:
		n = maxi(1, n / E.warm.size())
	return n


## The warm ring's job (derived data outside the state): made when first asked, caught up to the columns the state counts.
static func _jobFor(S: SimState, E: Dictionary, w: Dictionary):
	var key: String = _jkey(S, float(w.deg))
	var job = _jobs.get(key)
	if job == null:
		var P := WorldPlanet.make(int(E.seed))
		job = WorldPlanet.RingJob.new(P, WorldRingPick.ringFrom(w.spec.c, int(w.spec.cols), w.spec.t))
		if int(w.cols) > 0:
			job.readTo(int(w.cols))   # the catch-up of a carried state
		_jobs[key] = job
	return job


## A host's idle time (Rendering's SimHost, a frame with time left): steps the decided turn's rings' jobs on past the columns the state has counted, `units` of about 20 us (a column of gen 2 is about 3) in all,
## the ring nearest to done first. The state is not touched (the slices are derived data outside it): a ring counts as read, and the swap happens, on the same ticks whatever a host does; the sim's tick then finds
## its columns read and reads nothing. Returns the columns read now. A host calls it between sim ticks (never from inside one).
static func readAhead(S: SimState, units: int, colUnits: int = 3) -> int:
	var E = S.epoch
	if E == null or E.next == null:
		return 0
	var left: int = maxi(0, units / maxi(1, colUnits))
	var did: int = 0
	var best: Array = []
	for w in E.warm:
		var job = _jobFor(S, E, w)
		if not job.done:
			best.append(job)
	best.sort_custom(func(a, b): return a.i > b.i)
	for job in best:
		if left <= 0:
			break
		var from: int = job.i
		job.step(left)
		did += job.i - from
		left -= job.i - from
	return did


## What is warming, for a host that reads ahead: [[columns read now, columns of the ring, counted by the state]] a warm ring.
static func warmPlan(S: SimState) -> Array:
	var E = S.epoch
	var out: Array = []
	if E == null or E.next == null:
		return out
	for w in E.warm:
		var job = _jobs.get(_jkey(S, float(w.deg)))
		out.append([int(job.i) if job != null else 0, SimConst.NC, int(w.cols)])
	return out
''')
    s = rep(s, '''		_hashTo(ep, job.slice, int(job.i))   # the slice's heights are hashed as the columns are read
''', '''		_hashTo(ep, job.slice, mini(int(w.cols), SimConst.NC))   # the slice's heights are hashed as the columns are counted read (a job a host has read ahead is not the count)
''')
    return s


rw(R, 'sim/world/planet.gd', planet)
rw(R, 'sim/world/epoch.gd', epoch)
print('p23 applied')
