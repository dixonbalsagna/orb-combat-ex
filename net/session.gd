class_name NetSession
extends RefCounted
## One peer's rollback session over the deterministic sim (docs/net/rollback.md). No transport: the host hands it the
## local intent each frame and every remote input as it arrives (net/loopback.gd is the test host), and sends what
## localSince() returns.
##
## The model, per frame:
##   - the local intent is for tick frame + delay (input delay); ticks below `delay` are neutral for every slot, so both
##     peers start with the same confirmed inputs;
##   - a tick runs with each slot's confirmed input, or a prediction where none has arrived: the slot's last confirmed
##     input with its edge fields cleared (a held stick or guard carries on, a press does not repeat);
##   - before a tick that uses a prediction, the state is saved (NetSnapshot), at most one save every `saveEvery` ticks;
##   - an input that arrives for a tick already run, and differs from what that tick used, rolls the state back to the
##     newest save at or before it and runs every tick again up to the present (re-simulation);
##   - a tick whose inputs are all confirmed, after ticks that all were, is final: onConfirmed reports it.
## The session reads no clock (the determinism lint's rule for sim code holds here too); a profiling host sets `clock`.

const NEUTRAL: int = 127 | (127 << 8)   # SimIntent.pack of a cleared intent: the stick centred, every flag off
## The edge fields of a packed intent (SimIntent.pack's layout): upgrade, special, guardPress, dodge, powerPress, powerTap,
## light, heavy, sig, context, transform, the legacy pressed stance, escape and waited. A prediction clears them.
const EDGE_MASK: int = (3 << 18) | (7 << 20) | (1 << 24) | (1 << 25) | (1 << 28) | (1 << 29) | (1 << 30) | (1 << 31) | (1 << 32) | (1 << 33) | (1 << 34) | (7 << 35) | (1 << 42) | (15 << 43)

var S: SimState
var players: int = 2
var local: int = 0
var delay: int = 2            # input delay, ticks
var saveEvery: int = 1        # at most one snapshot every this many ticks (1: before every predicted tick)
var maxAhead: int = 20        # ticks the session may run past the confirmed frontier before it waits
var verify: bool = false      # save before every tick and report every confirmed tick's state (the test harness)
var onConfirmed: Callable     # (tick: int, state: SimState or null, out: String) -> void: the state after `tick` ticks once final
var clock: Callable           # () -> int microseconds, for profiling only; unset in a game
var afterRestore: Callable    # tests only (the check's negative control): (S) -> void, called after every restore
var rollbackOn: bool = true   # tests only: false ignores late inputs that contradict a prediction (the negative control)

var frame: int = 0            # ticks run so far: the next tick to run
var finalTo: int = 0          # the state after this many ticks is final and reported
var inputs: Array = []        # per slot: tick -> packed intent, confirmed (local, or received)
var contig := PackedInt32Array()   # per slot: every tick below it has its confirmed input
var used: Array = []          # per slot: tick -> the packed intent the tick last ran with
var outLog: Dictionary = {}   # tick -> digest of the feed and fx the tick last produced (NetSession.outDigest)
var snaps: Dictionary = {}    # boundary -> NetSnapshot of the state before that tick
var lastSaved: int = -1       # the newest boundary in snaps
var pool := NetSnapshot.Pool.new()
var _rollTo: int = -1         # the earliest tick a late input contradicted, -1 for none

# statistics
var stalls: int = 0           # frames the session waited (maxAhead reached)
var predictedTicks: int = 0   # tick runs that used at least one prediction
var mispredicted: int = 0     # remote inputs that differed from the prediction a tick ran with
var rollbacks: int = 0
var resimTicks: int = 0       # ticks run again
var maxDepth: int = 0         # the longest rollback, in ticks
var depthHist: Dictionary = {}   # rollback depth -> count
var resimThisFrame: int = 0
var resimFrames: PackedInt32Array = PackedInt32Array()   # per advance(): ticks re-simulated in that frame
var saves: int = 0
var restores: int = 0
var usStep: int = 0           # with a clock: time in SimCore.step (first runs and re-runs), in take() and in restore()
var usSave: int = 0
var usRestore: int = 0
var usSteps: int = 0          # steps timed


## S has had its newMatch (every peer the same seed, AI flags and setup). local is this peer's slot.
func _init(S_: SimState, local_: int, delay_: int = 2, players_: int = 2) -> void:
	S = S_
	local = local_
	delay = delay_
	players = players_
	contig.resize(players)
	for k in range(players):
		var d: Dictionary = {}
		for t in range(delay):
			d[t] = NEUTRAL
		inputs.append(d)
		used.append({})
		contig[k] = delay


## The confirmed frontier: every tick below it has every slot's input.
func confirmedFrontier() -> int:
	var c: int = contig[0]
	for k in range(1, players):
		c = mini(c, contig[k])
	return c


## False when the session is too far ahead of the confirmed inputs to run another tick (the host tries again next frame).
func canAdvance() -> bool:
	return frame - confirmedFrontier() < maxAhead


## One frame: the local intent for tick frame + delay, any rollback the received inputs call for, then one tick. Returns
## false (and takes nothing) when the session must wait.
func advance(localPacked: int) -> bool:
	resimThisFrame = 0
	if not canAdvance():
		stalls += 1
		sync()
		resimFrames.append(resimThisFrame)
		return false
	addInput(local, frame + delay, localPacked)
	sync()
	_run(frame)
	frame += 1
	_confirm()
	resimFrames.append(resimThisFrame)
	return true


## An input for (slot, tick), local or received. Duplicates are ignored. One for a tick already run that differs from what
## it ran with marks a rollback, which sync() (or the next advance()) performs.
func addInput(k: int, t: int, p: int) -> void:
	var d: Dictionary = inputs[k]
	if d.has(t):
		return
	d[t] = p
	while d.has(contig[k]):
		contig[k] += 1
	if t < frame and int(used[k].get(t, -1)) != p:
		mispredicted += 1
		if rollbackOn and (_rollTo < 0 or t < _rollTo):
			_rollTo = t


## Perform a pending rollback and report what has become final.
func sync() -> void:
	if _rollTo >= 0:
		_rollback(_rollTo)
		_rollTo = -1
	_confirm()


## This peer's confirmed inputs from tick `since` on (at most `cap`), for a packet: [first tick, PackedInt64Array].
func localSince(since: int, cap: int = 64) -> Array:
	var d: Dictionary = inputs[local]
	var out := PackedInt64Array()
	var t: int = since
	while d.has(t) and out.size() < cap:
		out.append(d[t])
		t += 1
	return [since, out]


## The packed intent a slot's tick runs with now: the confirmed one, or the prediction.
func inputFor(k: int, t: int) -> int:
	var d: Dictionary = inputs[k]
	if d.has(t):
		return d[t]
	var last: int = contig[k] - 1
	return (int(d[last]) if last >= 0 else NEUTRAL) & ~EDGE_MASK


func _run(t: int) -> void:
	var ins: Array = []
	var predicted: bool = false
	for k in range(players):
		var p: int = inputFor(k, t)
		if not inputs[k].has(t):
			predicted = true
		used[k][t] = p
		ins.append(SimIntent.unpack(p))
	if verify or (predicted and (lastSaved < 0 or t - lastSaved >= saveEvery)):
		if not snaps.has(t):
			_save(t)
	if predicted:
		predictedTicks += 1
	var t0: int = clock.call() if clock.is_valid() else 0
	SimCore.step(S, ins)
	if clock.is_valid():
		usStep += clock.call() - t0
		usSteps += 1
	if onConfirmed.is_valid():
		outLog[t] = outDigest(S)
	S.out.feed.clear()
	S.out.fx.clear()


func _save(t: int) -> void:
	var t0: int = clock.call() if clock.is_valid() else 0
	snaps[t] = NetSnapshot.take(S, pool)
	if clock.is_valid():
		usSave += clock.call() - t0
	saves += 1
	lastSaved = maxi(lastSaved, t)


func _rollback(r: int) -> void:
	var s: int = -1
	for b in snaps:
		if b <= r and b > s:
			s = b
	if s < 0:
		push_error("NetSession: no snapshot at or before tick %d (frame %d): the inputs can no longer be honoured" % [r, frame])
		return
	for b in snaps.keys():   # the saves after s belong to the timeline being replaced: the restore writes into them
		if b > s:
			pool.put(snaps[b])
			snaps.erase(b)
	lastSaved = s
	var t0: int = clock.call() if clock.is_valid() else 0
	NetSnapshot.restore(S, snaps[s], pool)
	if clock.is_valid():
		usRestore += clock.call() - t0
	if afterRestore.is_valid():
		afterRestore.call(S)
	restores += 1
	var depth: int = frame - s
	rollbacks += 1
	resimTicks += depth
	resimThisFrame += depth
	maxDepth = maxi(maxDepth, depth)
	depthHist[depth] = int(depthHist.get(depth, 0)) + 1
	for t in range(s, frame):
		_run(t)


## Report the ticks that have become final, then drop what no rollback can need: saves older than the newest one at or
## before the confirmed frontier, and the per-tick records below it.
func _confirm() -> void:
	var c: int = mini(confirmedFrontier(), frame)
	while finalTo < c:
		var b: int = finalTo + 1
		if onConfirmed.is_valid():
			var st: SimState = S if b == frame else (snaps[b].root if snaps.has(b) else null)
			onConfirmed.call(b, st, outLog.get(b - 1, ""))
		outLog.erase(b - 1)
		for k in range(players):
			used[k].erase(b - 1)
		finalTo = b
	var keep: int = -1
	for b in snaps:
		if b <= c and b > keep:
			keep = b
	for b in snaps.keys():
		if b < keep:
			pool.put(snaps[b])
			snaps.erase(b)


## The session's confirmed inputs as a SimReplay-style input list: [tick, slot, packed], only where a slot's input
## changed, for ticks below `upto`.
func confirmedLog(upto: int) -> Array:
	var out: Array = []
	for k in range(players):
		var last: int = -1
		for t in range(upto):
			var p: int = inputs[k][t]
			if p != last:
				out.append([t, k, p])
				last = p
	return out


## Free the saves and the pool (their objects can point at each other).
func close() -> void:
	for b in snaps:
		pool.put(snaps[b])
	snaps.clear()
	pool.clear()


## What a tick told its host: the feed lines (the director's decisions as text) and the fx events, as one digest.
static func outDigest(S_: SimState) -> String:
	if S_.out.feed.is_empty() and S_.out.fx.is_empty():
		return ""
	var h := SimHash.Hasher.new()
	for l in S_.out.feed:
		h.num(l.t)
		h.text(l.tag)
		h.text(l.sub)
	SimHash.hashFx(h, S_.out.fx)
	return h.hex()
