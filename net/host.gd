class_name NetHost
extends RefCounted
## One peer's host over a transport (docs/net/rollback.md section 11): the handshake, then the rollback session with
## the agreed delay, with time sync and ping measurement, all on whatever NetTransport it is given. Call frame() once a
## frame with the host's clock. The game packets are the loopback's (NetLoopback.Peer.packet) plus four fields:
## ts (the sender's clock), echo and age (the newest ts it received and how long it has held it, for the round trip),
## and adv (its frame advantage, for time sync), and, once a slot has been handed to the AI, ai (the takeovers). A packet
## from a peer that has not started yet is dropped: everything in it comes again.
## Every game packet is checked before anything in it is used (the audit's F-10): its fields of the right kinds, at most
## MAX_INPUTS inputs from a tick no further than MAX_REACH past this peer's frame, takeovers of a real slot at a tick not
## already final, at most MAX_CHECKS checkpoints. One that fails is dropped whole and counted (`rejected`).

var tr: NetTransport
var S: SimState
var local: int = 0
var remote: int = 1           # the other PC's slot
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
var paused: bool = false      # this PC's game is paused: idle() keeps the link and says so
var remotePaused: bool = false   # the other PC said it's paused, and hasn't moved on since
var heardAt: float = -1.0       # when anything last came from the other peer (NetLan's drop rule reads it)
var rejected: int = 0           # game packets dropped whole by the checks
static var check: bool = true   # tests only: off for lan_check's negative controls (a bad packet is used)
const MAX_INPUTS: int = 128     # inputs in one packet (a peer sends at most 64: NetSession.localSince)
const MAX_REACH: int = 240      # ticks past this peer's frame and delay that a packet's inputs, frame or takeovers may reach (4 s; a true peer is within its lead)
const MAX_CHECKS: int = 16      # checkpoints in one packet


## S has had its newMatch; matchKey is NetHandshake.keyOf of it; bot answers for slot local_.
func _init(tr_: NetTransport, S_: SimState, local_: int, matchKey: String, device: Dictionary, bot_: NetBot, remote_: int = -1) -> void:
	tr = tr_
	S = S_
	local = local_
	remote = remote_ if remote_ >= 0 else 1 - local_
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
		heardAt = now
		_take(now, pk)
	if session == null:
		hs.step(now, tr)
		if not hs.done() or hs.failed != "":
			return
		_start()
	if until > session.frame:
		paused = false
	if session.frame < until:
		if sync.shouldWait(session.frame):
			waits += 1
			session.sync()
		elif session.canAdvance():
			var pi: int = bot.next()   # first: it sets the bot's word
			var pw = bot.get("word")
			session.advance(pi, int(pw) if pw != null else 0)
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
	var pk := {"from": local, "frame": session.frame, "ack": session.ackOf(remote), "first": since[0], "inputs": since[1],
		"chk": session.chkOut.duplicate(true), "ts": now, "echo": _echo, "age": now - _echoAt if _echo >= 0.0 else 0.0,
		"adv": sync.current}
	if since[2].size() > 0:
		pk["words"] = since[2]   # the second words (rollback.md section 14), only when there is one
	if not session.aiFrom.is_empty():
		pk["ai"] = session.takeoverList()   # the AI's takeovers (rollback.md section 13), until the match ends
	return pk


func _take(now: float, pk: Dictionary) -> void:
	if str(pk.get("hs", "")) == "pause":
		remotePaused = bool(pk.get("on", false))
		return
	if pk.has("hs"):
		hs.take(now, pk, tr)
		return
	if session == null or not _isInt(pk.get("from", -1)) or int(pk.get("from", -1)) != remote:
		return
	if check and not valid(pk):
		rejected += 1
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
	for tk in pk.get("ai", []):   # before the inputs: a takeover supersedes the slot's inputs at its tick and after
		session.takeover(int(tk[0]), int(tk[1]))
	acked = maxi(acked, int(pk.get("ack", 0)))
	var t: int = int(pk.get("first", 0))
	var ws: PackedInt32Array = pk.get("words", PackedInt32Array())
	var n: int = 0
	for p in pk.get("inputs", PackedInt64Array()):
		session.addInput(remote, t, p, ws[n] if n < ws.size() else 0)
		t += 1
		n += 1
	for c in pk.get("chk", []):
		session.addRemoteCheck(int(c[0]), c[1])
	var rf: int = int(pk.get("frame", 0))
	if rf > _remoteFrame:
		remotePaused = false   # it has moved on: no longer paused
	if rf >= _remoteFrame:   # a packet overtaken by a newer one would understate the other's frame: time sync skips it
		_remoteFrame = rf
		sync.observe(session.frame, rf, float(pk.get("adv", 0.0)), rttMs())


## A game packet is safe to use: the kinds of its fields, and how far and how much it reaches (see the top).
func valid(pk: Dictionary) -> bool:
	for f in ["frame", "ack", "first"]:
		if pk.has(f) and not _isInt(pk[f]):
			return false
	for f in ["ts", "echo", "age", "adv"]:
		if pk.has(f) and not (pk[f] is float or pk[f] is int):
			return false
	var hi: int = session.frame + session.delay + MAX_REACH
	var ins = pk.get("inputs", PackedInt64Array())
	var ws = pk.get("words", PackedInt32Array())
	var first: int = int(pk.get("first", 0))
	if not (ins is PackedInt64Array) or not (ws is PackedInt32Array) or ins.size() > MAX_INPUTS or ws.size() > ins.size() or first < 0 or first + ins.size() > hi:
		return false
	if int(pk.get("frame", 0)) < 0 or int(pk.get("frame", 0)) > hi or int(pk.get("ack", 0)) < 0 or int(pk.get("ack", 0)) > hi:
		return false
	var ai = pk.get("ai", [])
	if not (ai is Array) or ai.size() > session.players:
		return false
	for tk in ai:
		if not (tk is Array) or tk.size() != 2 or not _isInt(tk[0]) or not _isInt(tk[1]):
			return false
		var k: int = int(tk[0])
		var t: int = int(tk[1])
		var again: bool = session.aiFrom.has(k) and int(session.aiFrom[k]) <= t   # every packet carries the takeovers: one already taken is no news
		if k < 0 or k >= session.players or t < 0 or t > hi or (t < session.finalTo and not again):
			return false
	var chk = pk.get("chk", [])
	if not (chk is Array) or chk.size() > MAX_CHECKS:
		return false
	for c in chk:
		if not (c is Array) or c.size() != 2 or not _isInt(c[0]) or not (c[1] is String):
			return false
	return true


static func _isInt(v) -> bool:
	return v is int or (v is float and is_finite(v) and float(int(v)) == v)


## A frame while this PC's game is paused: the link is serviced and the session's packets go out as ever, so the other PC keeps hearing from it
## (an unserviced link drops past ENet's timeout), but no tick is run. A pause notice goes with it.
func idle(now: float) -> void:
	paused = true
	frame(now, session.frame if session != null else 0)
	tr.send(now, {"hs": "pause", "on": true})


## Done when this peer has run and confirmed `until` ticks and the other holds all its inputs.
func finished(until: int) -> bool:
	return session != null and session.frame >= until and session.finalTo >= until and acked >= until


func close() -> void:
	if session != null:
		session.close()
	tr.close()
