class_name NetHandshake
extends RefCounted
## The start of a match over a transport (docs/net/rollback.md section 11): measure the round trip, propose an input
## delay, agree on it. Pure protocol: the host passes its clock (`now`, ms) and the transport, and the handshake reads
## nothing else, so the loopback runs it on simulated time and ENet on the wall clock.
##   1. Ping. Every frame, until it holds `samples` round trips or `timeoutMs` has passed, it sends {hs: "ping", ts}. The
##      other side answers each ping with {hs: "pong", ts} at once, now and for the rest of the match. A round trip is
##      the arrival time minus ts, on this peer's own clock, so the two clocks never have to agree. It includes the wait
##      for the next frame on each side, which every input pays too. Only pings sent once the other peer has been heard
##      from count: an earlier one waited for the other peer to start, not for the link.
##   2. Propose. NetDelay.choose(round trips, this device): this peer's delay.
##   3. Hello. Every frame it sends {hs: "hello", v, match, delay, got}: the protocol version, the match key (seed,
##      setup and roster: both peers must play the same match), its proposal, and whether it holds the other's hello.
##      Once it holds the other's hello, the delay is the larger of the two proposals, and the handshake is done. A done
##      peer stops sending hellos but answers any hello whose `got` is false, so a lost last hello costs a frame, not
##      the match.
## A version or match mismatch fails the handshake (`failed` says why) on both sides.

const PROTO: int = 1

var matchKey: String = ""
var device: Dictionary = {}
var opts: Dictionary = {}       # NetDelay.choose options
var samples: int = 16           # round trips to measure
var timeoutMs: float = 3000.0   # stop pinging after this long and use what came back (none: NetDelay's no-sample delay)
var pickLarger: bool = true     # tests only: false takes the smaller proposal (the transport check's negative control)

var startMs: float = -1.0
var rtts: Array = []            # measured round trips, ms
var mine: Dictionary = {}       # NetDelay.choose's answer, once the pings are done
var theirs: int = -1            # the other peer's proposal, once its hello arrived
var delay: int = -1             # the agreed delay, once done
var failed: String = ""
var doneAt: float = -1.0
var heardAt: float = -1.0       # when the first packet from the other peer arrived


func _init(matchKey_: String, device_: Dictionary, opts_: Dictionary = {}) -> void:
	matchKey = matchKey_
	device = device_
	opts = opts_


func done() -> bool:
	return delay >= 0


## One frame: what this peer sends.
func step(now: float, tr: NetTransport) -> void:
	if startMs < 0.0:
		startMs = now
	if failed != "" or done():
		return
	if mine.is_empty():
		if rtts.size() >= samples or now - startMs >= timeoutMs:
			mine = NetDelay.choose(rtts, device, opts)
			_agree(now)
		else:
			tr.send(now, {"hs": "ping", "ts": now})
	if not mine.is_empty() and not done():
		tr.send(now, _hello())


## A handshake packet from the other peer (any packet with an "hs" field), at any time, during the match too.
func take(now: float, pk: Dictionary, tr: NetTransport) -> void:
	if heardAt < 0.0:
		heardAt = now
	match str(pk.get("hs", "")):
		"ping":
			tr.send(now, {"hs": "pong", "ts": pk.get("ts", 0.0)})
		"pong":
			# a ping sent before the other peer was there waited for it, not for the link: only later ones count
			if mine.is_empty() and float(pk.get("ts", -1.0)) >= heardAt:
				rtts.append(now - float(pk.get("ts", now)))
		"hello":
			if int(pk.get("v", -1)) != PROTO:
				failed = "protocol %s, this peer speaks %d" % [str(pk.get("v")), PROTO]
				return
			if str(pk.get("match", "")) != matchKey:
				failed = "the other peer is in another match (%s, this one %s)" % [str(pk.get("match")), matchKey]
				return
			theirs = int(pk.get("delay", -1))
			_agree(now)
			if done() and not bool(pk.get("got", false)):
				tr.send(now, _hello())


func _agree(now: float) -> void:
	if done() or mine.is_empty() or theirs < 0:
		return
	delay = maxi(int(mine.delay), theirs) if pickLarger else mini(int(mine.delay), theirs)
	doneAt = now


func _hello() -> Dictionary:
	return {"hs": "hello", "v": PROTO, "match": matchKey, "delay": int(mine.delay), "got": theirs >= 0}


## The match key both peers must share: seed, AI flags and setup.
static func keyOf(seed: int, ai: Dictionary, setup: Dictionary) -> String:
	return "%d|%s|%s" % [seed, JSON.stringify(ai, "", true), JSON.stringify(setup, "", true)]
