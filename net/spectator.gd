class_name NetSpectator
extends RefCounted
## A spectator (docs/net/rollback.md section 8): a peer with no input slot that receives only confirmed inputs, every
## slot's, from a relay (a player's session, NetSession.confirmedSince, or later a server) and plays them through a
## jitter buffer: it starts once it holds `lag` ticks, then plays one tick a frame; when the buffer runs dry it stops,
## raises `lag` by 2 (at most maxLag) and fills up again; when it holds more than twice `lag` it catches up a tick or
## more a frame. It never predicts and never rolls back, so every tick it runs is final: its state equals
## the players' confirmed state tick for tick. It computes the same checkpoint digests as the players (NetDesync.digest)
## and compares them with the ones the relay forwards, so a spectator that drifted, or a relay that sent it something
## other than the confirmed stream, is caught like a desync between players.

var S: SimState
var players: int = 2
var lag: int = 6              # the jitter buffer's target, ticks: a late packet does not stall the view
var maxLag: int = 60          # the most the buffer grows to (one second)
var catchUp: int = 3          # the most ticks run in one frame when the buffer holds more than twice lag
var checkEvery: int = 60      # as NetSession's; 0 off
var onTick: Callable          # (tick: int, state: SimState) -> void: after each tick, with the state after it and its output
var flip: Callable            # tests only (the negative control): (t, slot, packed) -> packed, applied to inputs as they arrive

var frame: int = 0            # ticks run: the next tick to run
var have: int = 0             # every tick below it has every slot's input
var inputs: Array = []        # per slot: PackedInt64Array by tick
var chkMine: Dictionary = {}  # boundary -> digest
var chkRelay: Dictionary = {} # boundary -> digest the relay forwarded
var checksMatched: int = 0
var desync: Dictionary = {}   # the first mismatch: {tick, local, remote}
var waits: int = 0            # frames that played nothing (filling the buffer, or dry)
var rebuffers: int = 0        # times the buffer ran dry after playing began
var playing: bool = false
var leadSum: int = 0          # sum over frames of (have - frame), for the mean lead
var frames: int = 0


## S has had its newMatch, the same as the players'.
func _init(S_: SimState, players_: int = 2, lag_: int = 6) -> void:
	S = S_
	players = players_
	lag = lag_
	for k in range(players):
		inputs.append(PackedInt64Array())


## A relay packet's inputs: [first tick, [PackedInt64Array per slot]] (NetSession.confirmedSince). Out-of-order and
## repeated packets are fine: only the ticks it does not hold yet are taken, and only contiguously.
func take(first: int, per: Array) -> void:
	var n: int = (per[0] as PackedInt64Array).size()
	if first > have or first + n <= have:
		return
	for k in range(players):
		var a: PackedInt64Array = per[k]
		for i in range(have - first, n):
			var p: int = a[i]
			if flip.is_valid():
				p = flip.call(first + i, k, p)
			inputs[k].append(p)
	have = first + n


## A checkpoint digest a player confirmed (forwarded by the relay).
func addCheck(t: int, d: String) -> void:
	if chkRelay.has(t) or t <= 0:
		return
	chkRelay[t] = d
	_compare()


## One frame: one tick from the buffer, more while it holds over twice `lag` (at most catchUp), none from tick `until` on.
func advance(until: int = 1 << 40) -> void:
	frames += 1
	var lead: int = have - frame
	leadSum += lead
	if not playing:
		if lead < lag:
			waits += 1
			return
		playing = true
	if lead <= 0:
		waits += 1
		rebuffers += 1
		playing = false
		lag = mini(lag + 2, maxLag)
		return
	var ran: int = 0
	while frame < have and frame < until and (ran == 0 or (have - frame > lag * 2 and ran < catchUp)):
		_run()
		ran += 1


## Play out everything received below tick `until` (the end of a match).
func flush(until: int = 1 << 40) -> void:
	while frame < mini(have, until):
		_run()


func _run() -> void:
	var t: int = frame
	if checkEvery > 0 and t > 0 and t % checkEvery == 0:
		chkMine[t] = NetDesync.digest(S)
		_compare()
	var ins: Array = []
	for k in range(players):
		ins.append(SimIntent.unpack(inputs[k][t]))
	SimCore.step(S, ins)
	frame += 1
	if onTick.is_valid():
		onTick.call(frame, S)   # the tick's feed and fx are still in S.out here
	S.out.feed.clear()
	S.out.fx.clear()


func _compare() -> void:
	if not desync.is_empty():
		return
	for t in chkMine.keys():
		if chkRelay.has(t):
			if chkRelay[t] != chkMine[t]:
				desync = {"tick": t, "local": chkMine[t], "remote": chkRelay[t]}
				return
			checksMatched += 1
			chkMine.erase(t)
			chkRelay.erase(t)


func close() -> void:
	SimCore.dispose(S)
