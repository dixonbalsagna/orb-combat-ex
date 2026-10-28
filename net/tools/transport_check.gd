extends SceneTree
## Tests for the transport layer on the loopback, with no sockets (docs/net/rollback.md section 11). Exit 0 only if
## every part passes:
##   1. the wire codec (NetTransport.encode and decode): game and handshake packets come back equal, and malformed
##      bytes come back as null;
##   2. the handshake (NetHandshake via NetLoopback.agree) on every profile and on pairs of devices: both peers finish,
##      agree, and the delay is the larger of the two proposals, each NetDelay.choose of that peer's own round trips on
##      its own device; the measured round trip is near the profile's ping; a peer in another match, or speaking
##      another protocol version, is refused;
##   3. two NetHosts over link transports through the codec, with the second peer's clock 2% fast, a late start and a
##      40-frame freeze of the first: every confirmed tick's state digest and feed and fx equal the straight run's at
##      the agreed delay, no desync fires, and time sync keeps the peers within --max-lead frames of each other over
##      the last third of the match (the freeze is at the first third).
##   godot --headless --path . --script res://net/tools/transport_check.gd -- [--seed=1] [--ticks=900]
##     [--profiles=lan,p120,p200] [--max-lead=4] [--negative-control]
## --negative-control runs parts 2 and 3 against a handshake that takes the smaller proposal and against time sync
## turned off, and passes only if both are caught.

const FRAME_MS: float = 1000.0 / 60.0
const DEVICE_PAIRS: Array = [[1.0, 1.0], [1.0, 4.0], [4.0, 1.0], [2.0, 1.0]]

var failures: int = 0
var quiet: bool = false
var pickLarger: bool = true
var syncOn: bool = true


func _init() -> void:
	var seed: int = 1
	var ticks: int = 900
	var profiles: Array = ["lan", "p120", "p200"]
	var maxLead: int = 4
	var negative: bool = false
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		match kv[0]:
			"seed": seed = int(kv[1])
			"ticks": ticks = int(kv[1])
			"profiles": profiles = Array(kv[1].split(","))
			"max-lead": maxLead = int(kv[1])
			"negative-control": negative = true
	print("Orb Combat EX transport check   Godot %s   seed %d   %d ticks   %s" % [Engine.get_version_info().string, seed, ticks, "negative control" if negative else "max lead %d" % maxLead])
	if negative:
		quiet = true
		var caught: int = 0
		pickLarger = false
		failures = 0
		_handshakes(seed)
		print("  %s  a handshake that takes the smaller proposal: %d failing case(s)" % ["caught" if failures > 0 else "MISSED", failures])
		caught += 1 if failures > 0 else 0
		pickLarger = true
		syncOn = false
		failures = 0
		for pname in profiles:
			_hosts(seed, ticks, pname, maxLead)
		print("  %s  time sync turned off: %d failing case(s)" % ["caught" if failures > 0 else "MISSED", failures])
		caught += 1 if failures > 0 else 0
		print("%s  negative control: %d of 2 breaks caught" % ["PASS" if caught == 2 else "FAIL", caught])
		quit(0 if caught == 2 else 1)
		return
	_codec()
	_handshakes(seed)
	for pname in profiles:
		_hosts(seed, ticks, pname, maxLead)
	print("%s  %d failure(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)


func _expect(cond: bool, what: String) -> void:
	if not cond:
		failures += 1
		if not quiet:
			print("  FAIL  " + what)


func _codec() -> void:
	var pk := {"from": 1, "frame": 1234, "ack": 1230, "first": 1229, "inputs": PackedInt64Array([NetSession.NEUTRAL, 0x7FFFFFFFFFFF, -5]),
		"chk": [[1140, "0123456789abcdef0123456789abcdef"], [1200, "ffeeddccbbaa99887766554433221100"]],
		"ts": 98765.25, "echo": 98700.5, "age": 16.5, "adv": -1.5}
	var b := NetTransport.encode(pk)
	var back: Variant = NetTransport.decode(b)
	_expect(back is Dictionary and str(back) == str(pk), "codec: a game packet comes back equal (%s)" % str(back))
	_expect(b.size() == 40 + 3 * 8 + 2 * 20, "codec: a game packet with 3 inputs and 2 digests is %d bytes" % b.size())
	var empty := pk.duplicate(true)
	empty["inputs"] = PackedInt64Array()
	empty["chk"] = []
	_expect(str(NetTransport.decode(NetTransport.encode(empty))) == str(empty), "codec: an empty game packet comes back equal")
	var hs := {"hs": "hello", "v": NetHandshake.PROTO, "match": "1|{}|{}", "delay": 3, "got": true}
	_expect(str(NetTransport.decode(NetTransport.encode(hs))) == str(hs), "codec: a handshake packet comes back equal")
	_expect(NetTransport.decode(PackedByteArray()) == null, "codec: empty bytes are refused")
	_expect(NetTransport.decode(b.slice(0, b.size() - 3)) == null, "codec: a truncated game packet is refused")
	var longer := b.duplicate()
	longer.append(0)
	_expect(NetTransport.decode(longer) == null, "codec: a game packet with trailing bytes is refused")
	var junk := b.duplicate()
	junk[0] = 9
	_expect(NetTransport.decode(junk) == null, "codec: an unknown kind is refused")
	var notDict := PackedByteArray([2])
	notDict.append_array(var_to_bytes([1, 2, 3]))
	_expect(NetTransport.decode(notDict) == null, "codec: a Variant that is not a Dictionary is refused")
	if not quiet:
		print("codec: a game packet is %d bytes with 3 inputs and 2 digests, %d with none" % [b.size(), NetTransport.encode(empty).size()])


func _handshakes(seed: int) -> void:
	var key: String = NetHandshake.keyOf(seed, {"p1": false, "p2": false}, {})
	var lines: Array = []
	for pname in NetLoopback.PROFILES:
		var prof: Dictionary = NetLoopback.PROFILES[pname]
		var row: Array = []
		for pair in DEVICE_PAIRS:
			var devs: Array = [NetDelay.device(pair[0]), NetDelay.device(pair[1])]
			var ag: Dictionary = _agree(key, prof, devs, seed * 977 + int(prof.ping) + int(pair[1] * 10.0), [])
			var tag: String = "%s x%s/x%s" % [pname, pair[0], pair[1]]
			_expect(ag.failed == "", "handshake %s: %s" % [tag, ag.failed])
			if ag.failed != "":
				continue
			for k in range(2):
				var own: int = int(NetDelay.choose(ag.rtts[k], devs[k]).delay)
				_expect(ag.proposals[k] == own, "handshake %s: peer %d proposed %d, its own round trips give %d" % [tag, k, ag.proposals[k], own])
				var lo: float = float(prof.ping) - 2.0 * float(prof.jitter) - 1.0
				var hi: float = float(prof.ping) + 2.0 * float(prof.jitter) + 2.0 * FRAME_MS + 1.0
				_expect(ag.rttMedian[k] >= lo and ag.rttMedian[k] <= hi, "handshake %s: peer %d's median round trip %.1f ms is outside %.0f to %.0f" % [tag, k, ag.rttMedian[k], lo, hi])
				_expect(ag.samples[k] >= 1, "handshake %s: peer %d measured nothing" % [tag, k])
			_expect(ag.delays[0] == ag.delays[1], "handshake %s: the peers hold different delays %s" % [tag, str(ag.delays)])
			_expect(ag.delay == maxi(ag.proposals[0], ag.proposals[1]), "handshake %s: delay %d from proposals %s is not the larger" % [tag, ag.delay, str(ag.proposals)])
			row.append("%d (%d, %d)" % [ag.delay, ag.proposals[0], ag.proposals[1]])
		lines.append("  %-6s %s" % [pname, "   ".join(row)])
	var other: Dictionary = _agree(key, NetLoopback.PROFILES["p80j"], [NetDelay.device(1.0), NetDelay.device(1.0)], 5, [key, NetHandshake.keyOf(seed + 1, {"p1": false, "p2": false}, {})])
	_expect(other.failed.contains("another match"), "handshake: a peer in another match is refused (%s)" % other.failed)
	var hs := NetHandshake.new(key, NetDelay.device(1.0))
	var sink := NetTransport.new()
	hs.take(0.0, {"hs": "hello", "v": NetHandshake.PROTO + 1, "match": key, "delay": 2, "got": false}, sink)
	_expect(hs.failed.contains("protocol"), "handshake: another protocol version is refused (%s)" % hs.failed)
	if not quiet:
		print("handshake: delay (proposals) per device pair x1/x1, x1/x4, x4/x1, x2/x1")
		for l in lines:
			print(l)


func _agree(key: String, prof: Dictionary, devs: Array, linkSeed: int, keys: Array) -> Dictionary:
	if pickLarger:
		return NetLoopback.agree(key, prof, devs, linkSeed, keys)
	return NetLoopback.agree(key, prof, devs, linkSeed, keys, false)   # the negative control's: it takes the smaller proposal


## Two hosts over the codec on one clock; peer 1's clock runs 2% fast and starts 30 frames late; peer 0 freezes for 40
## frames at tick ticks/3.
func _hosts(seed: int, ticks: int, pname: String, maxLead: int) -> void:
	var prof: Dictionary = NetLoopback.PROFILES[pname]
	var skew: float = float(prof.get("skew", 0.5))
	var ls: Array = []
	for k in range(2):
		ls.append(NetLoopback.Link.new(float(prof.ping) * (skew if k == 0 else 1.0 - skew), float(prof.jitter), float(prof.loss), (seed * 3301 + k * 5009 + int(prof.ping)) & 0xFFFFFFFF))
	var ai := {"p1": false, "p2": false}
	var key: String = NetHandshake.keyOf(seed, ai, {})
	var hosts: Array = []
	var digests: Array = [[], []]
	for k in range(2):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed, ai, {})
		var h := NetHost.new(NetLinkTransport.new(ls[k], ls[1 - k], true), S, k, key, NetDelay.device(1.0), NetBot.new(seed, k))
		h.sync.on = syncOn
		var mine: Array = digests[k]
		mine.resize(ticks)
		h.configure = func(sess: NetSession) -> void:
			sess.verify = true
			sess.onConfirmed = func(b: int, st, out: String) -> void:
				if b <= ticks and st != null:
					mine[b - 1] = NetDesync.digest(st) + "|" + out
		hosts.append(h)
	var now: float = 0.0
	var wall: int = 0
	var froze: bool = false
	var leads: Array = []
	var cap: int = ticks * 3 + 1200
	while wall < cap:
		for k in range(2):
			if k == 1 and wall < 30:
				continue
			var reps: int = 2 if k == 1 and wall % 50 == 49 else 1
			for r in range(reps):
				hosts[k].frame(now, ticks)
		var s0: NetSession = hosts[0].session
		var s1: NetSession = hosts[1].session
		if s0 != null and not froze and s0.frame >= ticks / 3:
			froze = true
			hosts[0].stallFrames = 40
		if s0 != null and s1 != null and s0.frame < ticks and s1.frame < ticks:
			leads.append(s0.frame - s1.frame)
		now += FRAME_MS
		wall += 1
		if hosts[0].finished(ticks) and hosts[1].finished(ticks):
			break
	var err: String = ""
	for k in range(2):
		if err == "" and not hosts[k].finished(ticks):
			err = "peer %d did not finish in %d frames" % [k, cap]
		if err == "" and hosts[k].hs.failed != "":
			err = "peer %d's handshake: %s" % [k, hosts[k].hs.failed]
	var d: int = hosts[0].hs.delay
	var ref: Dictionary = NetStraight.run(seed, {}, ticks, d, ticks) if err == "" else {}
	if err == "":
		for k in range(2):
			for t in range(ticks):
				if err == "" and str(digests[k][t]) != ref.digests[t]:
					err = "peer %d: confirmed tick %d differs from the straight run" % [k, t + 1]
			if err == "" and not hosts[k].session.desync.is_empty():
				err = "peer %d: desync detection fired" % k
			if err == "" and SimHash.stateHash(hosts[k].S).gameplay != ref.final:
				err = "peer %d: the final SimHash differs" % k
	var worst: int = 0
	var lateWorst: int = 0
	for i in range(leads.size()):
		worst = maxi(worst, absi(leads[i]))
		if i >= leads.size() * 2 / 3:
			lateWorst = maxi(lateWorst, absi(leads[i]))
	if err == "" and lateWorst > maxLead:
		err = "the peers drifted %d frames apart over the last third (at most %d)" % [lateWorst, maxLead]
	_expect(err == "", "hosts %s: %s" % [pname, err])
	if err != "" and not quiet:
		print("  lead every 30 frames: %s" % str(leads.filter(func(x): return true).slice(0, leads.size(), 30)))
	if not quiet:
		print("hosts %-6s %s  delay %d  rtt %.0f/%.0f ms  lead max %d, last third %d  waits %d/%d  stalls %d/%d  rollbacks %d/%d  %d/%d B a packet  %s" % [pname,
			"ok  " if err == "" else "FAIL", d, hosts[0].rttMs(), hosts[1].rttMs(), worst, lateWorst, hosts[0].waits, hosts[1].waits,
			hosts[0].session.stalls if hosts[0].session else -1, hosts[1].session.stalls if hosts[1].session else -1,
			hosts[0].session.rollbacks if hosts[0].session else -1, hosts[1].session.rollbacks if hosts[1].session else -1,
			hosts[0].tr.bytesOut / maxi(1, hosts[0].tr.pktOut), hosts[1].tr.bytesOut / maxi(1, hosts[1].tr.pktOut), err])
	for h in hosts:
		var S: SimState = h.S
		h.close()
		SimCore.dispose(S)
