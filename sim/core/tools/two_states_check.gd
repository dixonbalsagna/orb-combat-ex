extends SceneTree
## Several sims in one process, with rollback snapshots (docs/architecture/packed-structures.md). A building's and a
## tree's record is shared by every snapshot of its state, and its per-tick fields live in the state's packed arrays, so
## this checks what another state in the process, or a snapshot read after its state moved on, could break. For each
## setup and seed, three states run the same bots' inputs in one process, interleaved tick by tick, and every 3 ticks
## the check hits a building and a tree itself (their per-tick fields written through the records, as World's code
## writes them), so every run has changes for a snapshot to miss:
##   R straight, the reference;
##   A saving before every tick and, every 7th tick, restoring 5 ticks back and running them again (a rollback);
##   C made at the half (a fresh match, after R and A have moved on), given A's snapshot of 12 ticks earlier, run up to
##     the present and on to the end.
## It passes (exit 0) only if:
##   - after every tick, NetDesync.digest of A (and of C once it runs) equals R's, and a live state's records read the
##     same values as its arrays;
##   - every snapshot of A read 12 ticks after it was taken, as a peer reads a confirmed tick (NetSession.onConfirmed):
##     its NetDesync.digest equals R's at that tick, and every 30 ticks so do its SimHash.stateHash and the field walk
##     (NetDesync.firstDiffs) against R's snapshot of that tick;
##   - C starts as R did (its digest and SimHash at tick 0);
##   - at the end the three full SimHash agree.
##   godot --headless --path . --script res://sim/core/tools/two_states_check.gd -- [--seeds=1,2] [--ticks=600]
##     [--setups=default,planet,calm,turn] [--negative-control]
## The setup "turn" is "calm" with a turn decided at tick 30, so every run crosses the swap at tick 73 and A's rollbacks
## restore into the turn's preparation. It is not in the default list yet: on HEAD a rollback into that window waits for
## ever, because the swap dropped the ring jobs the preparation needs (World's WorldEpoch._prep; the fix is parked with
## this check, docs/architecture/pending/packed-structures/).
## --negative-control breaks it three ways and passes only if each is caught: a snapshot read through its records (as
## NetDesync.digest read one until 2026-10-28), a restore that leaves the records on the arrays they had (no
## afterRestore), and a snapshot restored into another state that keeps the first state's records (no _rebuildRecords).

const SETUPS: Dictionary = {   # rollback_check.gd's
	"default": {},
	"planet": {"planet": 7, "touch": 3},
	"calm": {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}},
	"turn": {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}},   # calm, with a turn decided at tick TURN_AT
}
const EVERY: int = 7         # a rollback every this many ticks
const DEPTH: int = 5         # how far back
const LAG: int = 12          # a snapshot is read this many ticks after it was taken
const HASH_EVERY: int = 30   # the full SimHash and the field walk of a snapshot, every this many ticks
const TURN_AT: int = 30      # the setup "turn" has a turn decided before this tick (as epoch_check's playRun)
const HIT_EVERY: int = 3     # the check's own hit on a building and a tree, every this many ticks
const BREAKS: Dictionary = {
	"records": "a snapshot read through its records",
	"restore": "a restore that leaves the records on their old arrays",
	"cross": "a snapshot restored into another state that keeps the first state's records",
}

var failures: int = 0
var quiet: bool = false
var sabotage: String = ""   # the negative control's current break, a key of BREAKS


func _init() -> void:
	var seeds: Array = [1, 2]
	var ticks: int = 600
	var setups: Array = ["default", "planet", "calm"]
	var negative: bool = false
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		match kv[0]:
			"seeds": seeds = Array(kv[1].split(",")).map(func(s): return int(s))
			"ticks": ticks = int(kv[1])
			"setups": setups = Array(kv[1].split(","))
			"negative-control": negative = true
	print("Orb Combat EX two-states check   Godot %s   seeds %s   %d ticks   setups %s%s" % [Engine.get_version_info().string,
		str(seeds), ticks, ",".join(setups), "   negative control" if negative else ""])
	if negative:
		quiet = true
		var caught: int = 0
		for s in BREAKS:
			sabotage = s
			failures = 0
			for name in setups:
				for seed in seeds:
					_run(name, seed, ticks)
			print("  %s  %s: %d failing run(s)" % ["caught" if failures > 0 else "MISSED", BREAKS[s], failures])
			caught += 1 if failures > 0 else 0
		print("%s  negative control: %d of %d breaks caught" % ["PASS" if caught == BREAKS.size() else "FAIL", caught, BREAKS.size()])
		quit(0 if caught == BREAKS.size() else 1)
		return
	for name in setups:
		for seed in seeds:
			_run(name, seed, ticks)
	print("%s  %d failure(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)


func _run(name: String, seed: int, ticks: int) -> void:
	var setup: Dictionary = SETUPS[name]
	var turn: bool = name == "turn"
	var bots: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
	var ins: Array = []   # per tick, both slots' packed intents (neutral for the first two, as a session's input delay)
	for t in range(ticks):
		ins.append([NetSession.NEUTRAL if t < 2 else bots[0].next(), NetSession.NEUTRAL if t < 2 else bots[1].next()])
	var R := _make(seed, setup)
	var A := _make(seed, setup)
	var C: SimState = null
	var pool := NetSnapshot.Pool.new()
	var rPool := NetSnapshot.Pool.new()
	var snapA: Dictionary = {}   # boundary -> A's snapshot before that tick
	var snapR: Dictionary = {}   # boundary -> R's, every HASH_EVERY ticks, until A's of that tick is read
	var refD: Array = [NetDesync.digest(R)]   # [b]: R's digest after b ticks
	var refRec: Array = [_recordsDigest(R)]   # the same read through the records (the "records" break)
	var refH: Dictionary = {0: SimHash.stateHash(R).gameplay}
	snapR[0] = NetSnapshot.take(R, rPool)
	var err: String = ""
	var rollbacks: int = 0
	var reads: int = 0
	var cFrom: int = -1
	var cAt: int = ticks / 2
	var swapAt: int = -1
	for t in range(ticks):
		var b: int = t + 1
		_tick(R, t, ins[t], turn)
		if swapAt < 0 and R.epoch != null and int(R.epoch.n) > 0:
			swapAt = b
		refD.append(NetDesync.digest(R))
		refRec.append(_recordsDigest(R))
		if b % HASH_EVERY == 0:
			refH[b] = SimHash.stateHash(R).gameplay
			snapR[b] = NetSnapshot.take(R, rPool)
		# A, with a rollback every EVERY ticks
		snapA[t] = NetSnapshot.take(A, pool)
		_tick(A, t, ins[t], turn)
		if b % EVERY == 0 and b > DEPTH:
			var s: int = b - DEPTH
			for k in snapA.keys():   # the saves after s belong to the timeline being replaced (as NetSession._rollback)
				if k > s:
					pool.put(snapA[k])
					snapA.erase(k)
			_restore(A, snapA[s], pool)
			rollbacks += 1
			for u in range(s, b):
				if u > s:
					snapA[u] = NetSnapshot.take(A, pool)
				_tick(A, u, ins[u], turn)
		if err == "" and NetDesync.digest(A) != refD[b]:
			err = "A (rolling back): the digest after tick %d differs from R's" % b
		if err == "":
			err = _liveSame(A, "A", b)
		# a snapshot of A read after A moved on, as a peer reads a confirmed tick
		var r: int = b - LAG
		if r >= 0 and snapA.has(r):
			reads += 1
			var root: SimState = snapA[r].root
			if sabotage == "records":
				if err == "" and _recordsDigest(root) != refRec[r]:
					err = "A's snapshot of tick %d read through its records at tick %d differs from R's" % [r, b]
			elif err == "" and NetDesync.digest(root) != refD[r]:
				err = "A's snapshot of tick %d, read at tick %d: its digest differs from R's" % [r, b]
			if snapR.has(r):
				if err == "" and SimHash.stateHash(root).gameplay != refH[r]:
					err = "A's snapshot of tick %d, read at tick %d: its SimHash differs from R's" % [r, b]
				var diffs: Array = NetDesync.firstDiffs(root, snapR[r].root, 4)
				if err == "" and not diffs.is_empty():
					err = "A's snapshot of tick %d against R's: the field walk finds %s" % [r, str(diffs)]
				rPool.put(snapR[r])
				snapR.erase(r)
		# C: a fresh state, made after R and A moved on, given A's snapshot of LAG ticks ago
		if t == cAt and snapA.has(b - LAG):
			C = _make(seed, setup)
			if err == "" and NetDesync.digest(C) != refD[0]:
				err = "C, made at tick %d: its digest at tick 0 differs from R's" % b
			if err == "" and SimHash.stateHash(C).gameplay != refH[0]:
				err = "C, made at tick %d: its SimHash at tick 0 differs from R's" % b
			cFrom = b - LAG
			var src: SimState = snapA[cFrom].root
			var kept: Array = [src.buildings, src.trees, src.get("hold"), src.get("bBound"), src.get("tBound")]
			NetSnapshot.restore(C, snapA[cFrom])
			if sabotage == "cross":   # what the restore left before afterRestore gave C records of its own
				C.buildings = kept[0]; C.trees = kept[1]
				C.set("hold", kept[2]); C.set("bBound", kept[3]); C.set("tBound", kept[4])
			for u in range(cFrom, b):
				_tick(C, u, ins[u], turn)
		elif C != null:
			_tick(C, t, ins[t], turn)
		if C != null:
			if err == "" and NetDesync.digest(C) != refD[b]:
				err = "C (A's snapshot of tick %d restored into it): the digest after tick %d differs from R's" % [cFrom, b]
			if err == "":
				err = _liveSame(C, "C", b)
		for k in snapA.keys():   # keep what the next read and the next rollback need
			if k < b + 1 - LAG:
				pool.put(snapA[k])
				snapA.erase(k)
	var hR: String = SimHash.stateHash(R).gameplay
	if err == "" and SimHash.stateHash(A).gameplay != hR:
		err = "A's final SimHash differs from R's"
	if err == "" and C != null and SimHash.stateHash(C).gameplay != hR:
		err = "C's final SimHash differs from R's"
	if err == "" and C == null:
		err = "C never ran (--ticks too short)"
	if err != "":
		failures += 1
	if not quiet:
		var turns: String = "   the turn swapped at tick %d" % swapAt if turn else ""
		print("%-8s seed %d  %s  %d ticks  %d rollbacks  %d snapshots read late  C from tick %d at %d  %d buildings %d trees%s%s" % [name, seed,
			"ok  " if err == "" else "FAIL", ticks, rollbacks, reads, cFrom, cAt + 1, R.buildings.size(), R.trees.size(), turns,
			"" if err == "" else "\n  FAIL  " + err])
	for k in snapA:
		pool.put(snapA[k])
	for k in snapR:
		rPool.put(snapR[k])
	pool.clear()
	rPool.clear()
	for S in [R, A, C]:
		if S != null:
			SimCore.dispose(S)


func _make(seed: int, setup: Dictionary) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, setup)
	return S


## Tick t with its inputs, in every run of it (straight, again after a rollback, or C catching up), after the check's own
## hit. With `turn`, the turn is decided before tick TURN_AT, past the caps' gap, so every run crosses the swap.
func _tick(S: SimState, t: int, pair: Array, turn: bool) -> void:
	if t % HIT_EVERY == 1:
		var k: int = t / HIT_EVERY
		if not S.buildings.is_empty():
			var b = S.buildings[(k * 7) % S.buildings.size()]
			b.hp = b.hp * 0.875
			b.fled = b.fled + 1.0
			b.wear = b.wear + 0.5
			b.marks = mini(b.marks + 1, 2)
			var fd := PackedFloat32Array()   # a new array, never one written in place (the floor writes' contract)
			fd.resize(maxi(1, b.floors))
			fd.fill(0.125 * float(k % 7))
			b.fdmg = fd
		if not S.trees.is_empty():
			var tr = S.trees[(k * 5) % S.trees.size()]
			tr.burn = tr.burn + 0.25
	if turn and t == TURN_AT:
		S.epoch.lastT = S.T - float(WorldEpoch.data().gapSeconds)
		WorldEpoch.ask(S, "two states", 0.5 * (S.fighters[0].x + S.fighters[1].x), 1, 0)
		WorldEpoch.choose(S, 2, 64, 2.5)
	SimCore.step(S, [SimIntent.unpack(pair[0]), SimIntent.unpack(pair[1])])
	S.out.feed.clear()
	S.out.fx.clear()


## A rollback's restore; the "restore" break puts the hold's old arrays back after it, as a missing afterRestore would.
func _restore(S: SimState, snap: NetSnapshot, pool: NetSnapshot.Pool) -> void:
	var h = S.get("hold")
	var old: Dictionary = {}
	if sabotage == "restore" and h != null:
		for k in NetSnapshot.props(h):
			old[k] = h.get(k)
	NetSnapshot.restore(S, snap, pool)
	for k in old:
		h.set(k, old[k])


## A live state's records read the values its arrays hold ("" when they do, or with no arrays: records not bound yet).
func _liveSame(S: SimState, who: String, b: int) -> String:
	if not S.has_method("bound") or not S.call("bound"):   # by name: the check runs on a tree before the packed structures too
		return ""
	if _recordsDigest(S) != _arraysDigest(S):
		return "%s after tick %d: its records read other values than its arrays hold" % [who, b]
	return ""


## The buildings' and trees' per-tick fields read through their records.
static func _recordsDigest(S: SimState) -> String:
	var v := PackedFloat64Array()
	for b in S.buildings:
		v.append(b.hp); v.append(b.fmask); v.append(b.popAlive); v.append(b.fled); v.append(b.wear); v.append(1.0 if b.alive else 0.0)
		v.append(b.marks); v.append(b.fdmg.size())
		for x in b.fdmg:
			v.append(x)
	for t in S.trees:
		v.append(t.burn); v.append(1.0 if t.alive else 0.0)
	return _md5(v)


## The same fields read from the state's arrays (a bound state).
static func _arraysDigest(S) -> String:
	var v := PackedFloat64Array()
	for i in range(S.buildings.size()):
		v.append(S.bHp[i]); v.append(S.bFmask[i]); v.append(S.bPopAlive[i]); v.append(S.bFled[i]); v.append(S.bWear[i]); v.append(float(S.bAlive[i]))
		v.append(S.bMarks[i]); v.append(S.bFdmg[i].size())
		for x in S.bFdmg[i]:
			v.append(x)
	for i in range(S.trees.size()):
		v.append(S.tBurn[i]); v.append(float(S.tAlive[i]))
	return _md5(v)


static func _md5(v: PackedFloat64Array) -> String:
	var md := HashingContext.new()
	md.start(HashingContext.HASH_MD5)
	md.update(v.to_byte_array())
	return md.finish().hex_encode()
