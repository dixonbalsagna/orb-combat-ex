class_name NetHost
extends RefCounted
## One peer's host over a transport (docs/net/rollback.md section 11): the handshake, then the rollback session with
## the agreed delay, with time sync and ping measurement, all on whatever NetTransport it is given. Call frame() once a
## frame with the host's clock. The game packets are the loopback's (NetLoopback.Peer.packet) plus four fields:
## ts (the sender's clock), echo and age (the newest ts it received and how long it has held it, for the round trip),
## and adv (its frame advantage, for time sync). A packet from a peer that has not started yet is dropped: everything
## in it comes again.

var tr: NetTransport
var S: SimState
var local: int = 0
var hs: NetHandshake
var bot: NetBot
var session: NetSession = null
var sync := NetTimeSync.new()
var configure: Callable       # (session) -> void, once the session exists (verify mode, callbacks, test hooks)
var acked: int = 0            # the other peer holds every one of our inputs below this tick
var frames: int = 0           # frames run
var startFrame: int = -1      # the frame the session started on
var waits: int = 0            # frames time sync waited
var rtt := PackedFloat32Array()   # recent round trips during play, ms
var rttAll: int = 0
var _echo: float = -1.0       # the newest ts received, and when
var _echoAt: float = 0.0
var _remoteFrame: int = -1    # the newest frame the other peer has reported
var stallFrames: int = 0      # tests only: the next this many frames run nothing at all (a hitch: the process froze)


## S has had its newMatch; matchKey is NetHandshake.keyOf of it; bot answers for slot local_.
func _init(tr_: NetTransport, S_: SimState, local_: int, matchKey: String, device: Dictionary, bot_: NetBot) -> void:
	tr = tr_
	S = S_
	local = local_
	hs = NetHandshake.new(matchKey, device)
	bot = bot_


## The round-trip estimate: the median of the recent samples, or the handshake's while there are none.
func rttMs() -> float:
	if rtt.is_empty():
		return float(hs.mine.get("medianMs", 0.0)) if not hs.mine.is_empty() else 0.0
	var a: Array = Array(rtt)
	a.sort()
	return a[a.size() / 2]


## One frame: receive, then the handshake or one tick of the session, then send.
func frame(now: float, until: int) -> void:
	frames += 1
	if stallFrames > 0:
		stallFrames -= 1
		return
	for pk in tr.receive(now):
		_take(now, pk)
	if session == null:
		hs.step(now, tr)
		if not hs.done() or hs.failed != "":
			return
		_start()
	if session.frame < until:
		if sync.shouldWait(session.frame):
			waits += 1
			session.sync()
		elif session.canAdvance():
			session.advance(bot.next())
		else:
			session.advance(0)   # waits (takes nothing)
	else:
		session.sync()
	tr.send(now, _packet(now))


func _start() -> void:
	session = NetSession.new(S, local, hs.delay)
	startFrame = frames
	if configure.is_valid():
		configure.call(session)


func _packet(now: float) -> Dictionary:
	var since: Array = session.localSince(acked)
	return {"from": local, "frame": session.frame, "ack": session.contig[1 - local], "first": since[0], "inputs": since[1],
		"chk": session.chkOut.duplicate(true), "ts": now, "echo": _echo, "age": now - _echoAt if _echo >= 0.0 else 0.0,
		"adv": sync.current}


func _take(now: float, pk: Dictionary) -> void:
	if pk.has("hs"):
		hs.take(now, pk, tr)
		return
	if session == null or int(pk.get("from", -1)) != 1 - local:
		return
	var ts: float = float(pk.get("ts", -1.0))
	if ts > _echo:   # packets can arrive out of order: echo the newest
		_echo = ts
		_echoAt = now
	var e: float = float(pk.get("echo", -1.0))
	if e >= 0.0:
		rtt.append(now - e - float(pk.get("age", 0.0)))
		rttAll += 1
		if rtt.size() > 64:
			rtt.remove_at(0)
	acked = maxi(acked, int(pk.get("ack", 0)))
	var t: int = int(pk.get("first", 0))
	for p in pk.get("inputs", PackedInt64Array()):
		session.addInput(1 - local, t, p)
		t += 1
	for c in pk.get("chk", []):
		session.addRemoteCheck(int(c[0]), c[1])
	var rf: int = int(pk.get("frame", 0))
	if rf >= _remoteFrame:   # a packet overtaken by a newer one would understate the other's frame: time sync skips it
		_remoteFrame = rf
		sync.observe(session.frame, rf, float(pk.get("adv", 0.0)), rttMs())


## Done when this peer has run and confirmed `until` ticks and the other holds all its inputs.
func finished(until: int) -> bool:
	return session != null and session.frame >= until and session.finalTo >= until and acked >= until


func close() -> void:
	if session != null:
		session.close()
	tr.close()
