class_name NetLoopback
extends RefCounted
## Two peers in one process, joined by simulated links with latency, jitter and loss (no sockets). Both run a NetSession
## at 60 frames a second of simulated wall time; every frame each peer sends one packet with all its inputs the other has
## not acknowledged, so a lost packet costs a frame, not an input. Packets can arrive out of order (jitter).
## Used by net/tools/rollback_check.gd (determinism) and rollback_bench.gd (cost).

const FRAME_MS: float = 1000.0 / 60.0

## Network profiles: ping is the round trip in ms (each way is half), jitter the most one packet's one-way delay moves
## either way, loss the share of packets dropped. "far" is a one-way 200 ms link (400 ms ping), past the brief's range.
const PROFILES: Dictionary = {
	"lan": {"ping": 0.0, "jitter": 0.0, "loss": 0.0},
	"p40": {"ping": 40.0, "jitter": 4.0, "loss": 0.0},
	"p80j": {"ping": 80.0, "jitter": 12.0, "loss": 0.01},
	"p120": {"ping": 120.0, "jitter": 20.0, "loss": 0.03},
	"p160": {"ping": 160.0, "jitter": 25.0, "loss": 0.05},
	"p200": {"ping": 200.0, "jitter": 30.0, "loss": 0.10},
	"p200c": {"ping": 200.0, "jitter": 0.0, "loss": 0.0},
	"asym": {"ping": 140.0, "jitter": 40.0, "loss": 0.02, "skew": 0.8},
	"far": {"ping": 400.0, "jitter": 40.0, "loss": 0.10},
}


## A one-way link: packets wait in flight until their arrival time.
class Link:
	var oneWay: float = 0.0
	var jitter: float = 0.0
	var loss: float = 0.0
	var r: SimRng
	var flight: Array = []   # [arrival ms, packet]
	var sent: int = 0
	var lost: int = 0

	func _init(oneWay_: float, jitter_: float, loss_: float, seed: int) -> void:
		oneWay = oneWay_
		jitter = jitter_
		loss = loss_
		r = SimRng.new(seed)

	func send(now: float, packet: Dictionary) -> void:
		sent += 1
		if r.next() < loss:
			lost += 1
			return
		var d: float = maxf(0.0, oneWay + (r.next() * 2.0 - 1.0) * jitter)
		flight.append([now + d, packet])

	## The packets that have arrived by `now`, in arrival order.
	func receive(now: float) -> Array:
		var got: Array = []
		var keep: Array = []
		for e in flight:
			if e[0] <= now:
				got.append(e)
			else:
				keep.append(e)
		flight = keep
		got.sort_custom(func(a, b): return a[0] < b[0])
		return got.map(func(e): return e[1])


## A peer: its session, its bot, and what the other side has acknowledged of its inputs.
class Peer:
	var session: NetSession
	var bot: NetBot
	var acked: int = 0   # the other peer holds every one of our inputs below this tick

	func packet() -> Dictionary:
		var since: Array = session.localSince(acked)
		return {"from": session.local, "frame": session.frame, "ack": session.contig[1 - session.local], "first": since[0], "inputs": since[1]}

	func take(pk: Dictionary) -> void:
		acked = maxi(acked, int(pk.ack))
		var t: int = int(pk.first)
		for p in pk.inputs:
			session.addInput(int(pk.from), t, p)
			t += 1


var peers: Array = []
var links: Array = []    # links[k] carries peer k's packets to the other
var now: float = 0.0
var frames: int = 0
var clock: Callable      # () -> int microseconds: with it, each peer's frame (receive and advance) is timed into frameUs
var frameUs: Array = [PackedInt32Array(), PackedInt32Array()]


## Two peers on fresh sims of the same match. profile is a PROFILES entry; seed seeds the links; bots answer for each
## slot from botSeed.
static func make(matchSeed: int, setup: Dictionary, profile: Dictionary, delay: int, botSeed: int, linkSeed: int) -> NetLoopback:
	var L := NetLoopback.new()
	var skew: float = float(profile.get("skew", 0.5))
	var ping: float = float(profile.ping)
	for k in range(2):
		var S := SimCore.createSim()
		SimCore.newMatch(S, matchSeed, {"p1": false, "p2": false}, setup)
		var p := Peer.new()
		p.session = NetSession.new(S, k, delay)
		p.bot = NetBot.new(botSeed, k)   # its first answer is for tick `delay`: the ticks below are neutral
		L.peers.append(p)
		var oneWay: float = ping * (skew if k == 0 else 1.0 - skew)
		L.links.append(Link.new(oneWay, float(profile.jitter), float(profile.loss), (linkSeed * 7919 + k * 104729) & 0xFFFFFFFF))
	return L


## One frame of wall time: deliver what has arrived, advance each peer that is below `until` ticks, send.
func step(until: int) -> void:
	for k in range(2):
		var p: Peer = peers[k]
		var t0: int = clock.call() if clock.is_valid() else 0
		var playing: bool = p.session.frame < until   # timed: the frames of play, not the flush after the last tick
		for pk in links[1 - k].receive(now):
			p.take(pk)
		if p.session.frame < until:
			if p.session.canAdvance():
				p.session.advance(p.bot.next())
			else:
				p.session.advance(0)   # waits (takes nothing)
		else:
			p.session.sync()
		if clock.is_valid() and playing:
			frameUs[k].append(clock.call() - t0)
	for k in range(2):
		links[k].send(now, peers[k].packet())
	now += FRAME_MS
	frames += 1


## Run until both peers have run `ticks` ticks and confirmed all of them (or a frame cap, for a stuck run).
func run(ticks: int) -> bool:
	var cap: int = ticks * 4 + 600
	while frames < cap:
		step(ticks)
		var done: bool = true
		for p in peers:
			if p.session.frame < ticks or p.session.finalTo < ticks:
				done = false
		if done:
			return true
	return false


func close() -> void:
	for p in peers:
		p.session.close()
		SimCore.dispose(p.session.S)
