class_name NetLoopback
extends RefCounted
## Two peers in one process, joined by simulated links with latency, jitter and loss (no sockets), each peer's pair of
## links wrapped as its NetTransport (NetLinkTransport). Both run a NetSession
## at 60 frames a second of simulated wall time; every frame each peer sends one packet with all its inputs the other has
## not acknowledged, so a lost packet costs a frame, not an input. Packets can arrive out of order (jitter).
## Each packet also carries the peer's newest confirmed checkpoint digests (NetSession.chkOut, desync detection). An
## optional spectator (addSpectator) hangs off one peer, the relay, over a link of its own: it receives only the
## confirmed inputs of every slot and the relay's digests, and acknowledges what it holds.
## Used by net/tools/rollback_check.gd (determinism), desync_check.gd, spectator_check.gd and rollback_bench.gd (cost).

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


## A peer: its session, its player (a NetBot, or a NetAiDriver: anything whose next() gives the packed intent for the
## next tick), and what the other side has acknowledged of its inputs.
class Peer:
	var session: NetSession
	var bot   # NetBot or NetAiDriver
	var transport: NetTransport   # a NetLinkTransport over links[k] out and the other's link in
	var acked: int = 0   # the other peer holds every one of our inputs below this tick

	func packet() -> Dictionary:
		var since: Array = session.localSince(acked)
		return {"from": session.local, "frame": session.frame, "ack": session.contig[1 - session.local], "first": since[0], "inputs": since[1],
			"chk": session.chkOut.duplicate(true)}

	func take(pk: Dictionary) -> void:
		acked = maxi(acked, int(pk.ack))
		var t: int = int(pk.first)
		for p in pk.inputs:
			session.addInput(int(pk.from), t, p)
			t += 1
		for c in pk.chk:
			session.addRemoteCheck(int(c[0]), c[1])


var peers: Array = []
var links: Array = []    # links[k] carries peer k's packets to the other
var now: float = 0.0
var frames: int = 0
var clock: Callable      # () -> int microseconds: with it, each peer's frame (receive and advance) is timed into frameUs
var frameUs: Array = [PackedInt32Array(), PackedInt32Array()]
var spectator: NetSpectator = null
var relay: int = 0            # the peer that relays to the spectator
var specLinks: Array = []     # [relay -> spectator, spectator -> relay]
var specAcked: int = 0        # the spectator holds every tick below this
var relayPredicted: bool = false   # tests only (the spectator check's negative control): relay the inputs ticks ran with, guesses included


## Two peers on fresh sims of the same match. profile is a PROFILES entry; seed seeds the links; bots answer for each
## slot from botSeed.
## With `wire`, every packet goes through NetTransport's bytes on its way. `ai` is newMatch's: a slot the sim's own AI
## plays ignores its inputs (the AI runs inside each tick, and is run again by a rollback).
static func make(matchSeed: int, setup: Dictionary, profile: Dictionary, delay: int, botSeed: int, linkSeed: int, wire: bool = false, ai: Dictionary = {"p1": false, "p2": false}) -> NetLoopback:
	var L := NetLoopback.new()
	var skew: float = float(profile.get("skew", 0.5))
	var ping: float = float(profile.ping)
	for k in range(2):
		var S := SimCore.createSim()
		SimCore.newMatch(S, matchSeed, ai, setup)
		var p := Peer.new()
		p.session = NetSession.new(S, k, delay)
		p.bot = NetBot.new(botSeed, k)   # its first answer is for tick `delay`: the ticks below are neutral
		L.peers.append(p)
		var oneWay: float = ping * (skew if k == 0 else 1.0 - skew)
		L.links.append(Link.new(oneWay, float(profile.jitter), float(profile.loss), (linkSeed * 7919 + k * 104729) & 0xFFFFFFFF))
	for k in range(2):
		L.peers[k].transport = NetLinkTransport.new(L.links[k], L.links[1 - k], wire)
	return L


## The handshake (NetHandshake) between two peers on links of this profile, on simulated time, each with its own
## device: {delay, proposals: [peer 0's, peer 1's], rttMedian: [ms, ms], frames, failed}. Its links are its own (other
## seeds), so a check can run the match on make()'s links at the agreed delay. keys gives each peer its own match key,
## and pickLarger = false breaks the rule (both for tests only).
static func agree(matchKey: String, profile: Dictionary, devices: Array, linkSeed: int, keys: Array = [], pickLarger: bool = true) -> Dictionary:
	var skew: float = float(profile.get("skew", 0.5))
	var ls: Array = []
	for k in range(2):
		var oneWay: float = float(profile.ping) * (skew if k == 0 else 1.0 - skew)
		ls.append(Link.new(oneWay, float(profile.jitter), float(profile.loss), (linkSeed * 5023 + k * 7907 + 3) & 0xFFFFFFFF))
	var trs: Array = [NetLinkTransport.new(ls[0], ls[1], true), NetLinkTransport.new(ls[1], ls[0], true)]
	var hss: Array = []
	for k in range(2):
		hss.append(NetHandshake.new(keys[k] if keys.size() == 2 else matchKey, devices[k]))
		hss[k].pickLarger = pickLarger   # tests only
	var t: float = 0.0
	var f: int = 0
	while f < 600:
		for k in range(2):
			for pk in trs[k].receive(t):
				hss[k].take(t, pk, trs[k])
			hss[k].step(t, trs[k])
		f += 1
		t += FRAME_MS
		if (hss[0].done() and hss[1].done()) or hss[0].failed != "" or hss[1].failed != "":
			break
	var fail: String = hss[0].failed if hss[0].failed != "" else hss[1].failed
	if fail == "" and not (hss[0].done() and hss[1].done()):
		fail = "the handshake did not finish in %d frames" % f
	if fail == "" and hss[0].delay != hss[1].delay:
		fail = "the peers agreed on different delays (%d, %d)" % [hss[0].delay, hss[1].delay]
	return {"delay": hss[0].delay, "delays": [hss[0].delay, hss[1].delay], "proposals": [int(hss[0].mine.get("delay", -1)), int(hss[1].mine.get("delay", -1))],
		"rttMedian": [float(hss[0].mine.get("medianMs", -1.0)), float(hss[1].mine.get("medianMs", -1.0))],
		"samples": [hss[0].rtts.size(), hss[1].rtts.size()], "rtts": [hss[0].rtts, hss[1].rtts], "frames": f, "failed": fail}


## A spectator on a fresh sim of the same match, fed by peer `relay_` over links like the relay's own (the same
## latency, jitter and loss each way, other seeds).
func addSpectator(matchSeed: int, setup: Dictionary, profile: Dictionary, lag: int, relay_: int, linkSeed: int) -> NetSpectator:
	var S := SimCore.createSim()
	SimCore.newMatch(S, matchSeed, {"p1": false, "p2": false}, setup)
	spectator = NetSpectator.new(S, 2, lag)
	relay = relay_
	var oneWay: float = links[relay].oneWay
	for k in range(2):
		specLinks.append(Link.new(oneWay, float(profile.jitter), float(profile.loss), (linkSeed * 6151 + k * 92821 + 17) & 0xFFFFFFFF))
	return spectator


func _relayPacket() -> Dictionary:
	var sess: NetSession = peers[relay].session
	var got: Array = sess.confirmedSince(specAcked)
	if relayPredicted:   # the bug the negative control plants: the ticks this peer has run, with the inputs they used
		var per: Array = []
		for k in range(2):
			var a := PackedInt64Array()
			for t in range(specAcked, mini(sess.frame, specAcked + 64)):
				a.append(sess.inputs[k][t] if sess.inputs[k].has(t) else int(sess.used[k].get(t, sess.inputFor(k, t))))
			per.append(a)
		got = [specAcked, per]
	return {"first": got[0], "per": got[1], "chk": sess.chkOut.duplicate(true)}


## One frame of wall time: deliver what has arrived, advance each peer that is below `until` ticks, send.
func step(until: int) -> void:
	for k in range(2):
		var p: Peer = peers[k]
		var t0: int = clock.call() if clock.is_valid() else 0
		var playing: bool = p.session.frame < until   # timed: the frames of play, not the flush after the last tick
		for pk in p.transport.receive(now):
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
	if spectator != null:
		for pk in specLinks[0].receive(now):
			spectator.take(int(pk.first), pk.per)
			for c in pk.chk:
				spectator.addCheck(int(c[0]), c[1])
		for pk in specLinks[1].receive(now):
			specAcked = maxi(specAcked, int(pk.ack))
		if spectator.frame < until:
			spectator.advance(until)
	for k in range(2):
		peers[k].transport.send(now, peers[k].packet())
	if spectator != null:
		specLinks[0].send(now, _relayPacket())
		specLinks[1].send(now, {"ack": spectator.have})
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
		if spectator != null and spectator.have < ticks:
			done = false
		if done:
			if spectator != null:
				spectator.flush(ticks)
			return true
	return false


func close() -> void:
	for p in peers:
		if p.bot is NetAiDriver:
			p.bot.close()
		p.session.close()
		SimCore.dispose(p.session.S)
	if spectator != null:
		spectator.close()
