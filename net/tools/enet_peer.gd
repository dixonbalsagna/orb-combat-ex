extends SceneTree
## One peer of the ENet two-process check (net/tools/enet_check.gd starts two of these; docs/net/rollback.md section 11).
## It plays a seeded match over ENet on 127.0.0.1 at 60 frames a second of wall time: NetHost (handshake, rollback
## session at the agreed delay, time sync) over NetEnetTransport, with the bots' inputs (NetBot) for its slot. The
## session runs in verify mode, so every confirmed tick's state is at hand: for each it records the cheap digest
## (NetDesync.digest) and the tick's feed and fx digest, and every --hash-every ticks and at the end the full gameplay
## SimHash. It writes them, the handshake and the time sync's figures to --out as JSON, and exits 0 once it has run and
## confirmed --ticks ticks (the match's end: no bot match reaches a KO) and the other peer holds all its inputs.
##   godot --headless --path . --script res://net/tools/enet_peer.gd -- --role=host|join --port=47100 --out=PATH
##     [--seed=1] [--ticks=3600] [--setup=default] [--profile=lan] [--slowdown=1] [--hash-every=60]
##     [--perturb=T] [--hitch=T:F] [--timeout=S]
## --profile injects a NetLoopback profile's latency, jitter and loss on this peer's outgoing packets (its share of the
## round trip). --perturb=T flips one RNG bit after every run of tick T (a divergent peer: the negative control).
## --hitch=T:F freezes the process for F frames when its session reaches tick T (time sync must recover).

const FRAME_MS: float = 1000.0 / 60.0


func _init() -> void:
	var o := {"role": "", "port": 47100, "out": "", "seed": 1, "ticks": 3600, "setup": "default", "profile": "lan", "slowdown": 1.0,
		"hashEvery": 60, "perturb": -1, "hitchAt": -1, "hitchFrames": 0, "timeout": 0.0}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		if kv.size() < 2:
			continue
		match kv[0]:
			"role": o.role = kv[1]
			"port": o.port = int(kv[1])
			"out": o.out = kv[1]
			"seed": o.seed = int(kv[1])
			"ticks": o.ticks = int(kv[1])
			"setup": o.setup = kv[1]
			"profile": o.profile = kv[1]
			"slowdown": o.slowdown = float(kv[1])
			"hash-every": o.hashEvery = maxi(1, int(kv[1]))
			"perturb": o.perturb = int(kv[1])
			"hitch":
				var p: PackedStringArray = kv[1].split(":")
				o.hitchAt = int(p[0])
				o.hitchFrames = int(p[1]) if p.size() > 1 else 30
			"timeout": o.timeout = float(kv[1])
	quit(_run(o))


func _run(o: Dictionary) -> int:
	if o.role != "host" and o.role != "join" or o.out == "":
		push_error("enet_peer: --role=host|join and --out are required")
		return 2
	var slot: int = 0 if o.role == "host" else 1
	var setup: Dictionary = NetStraight.SETUPS[o.setup]
	var ai := {"p1": false, "p2": false}
	var S := SimCore.createSim()
	SimCore.newMatch(S, o.seed, ai, setup)
	var tr: NetEnetTransport = NetEnetTransport.listen("127.0.0.1", o.port) if slot == 0 else NetEnetTransport.dial("127.0.0.1", o.port)
	var prof: Dictionary = NetLoopback.PROFILES[o.profile]
	var skew: float = float(prof.get("skew", 0.5))
	var oneWay: float = float(prof.ping) * (skew if slot == 0 else 1.0 - skew)
	if float(prof.ping) > 0.0 or float(prof.loss) > 0.0:
		tr.impair(oneWay, float(prof.jitter), float(prof.loss), (o.seed * 7919 + slot * 104729 + 11) & 0xFFFFFFFF)
	var host := NetHost.new(tr, S, slot, NetHandshake.keyOf(o.seed, ai, setup), NetDelay.device(o.slowdown), NetBot.new(o.seed, slot))
	var res := {"role": o.role, "slot": slot, "profile": o.profile, "seed": o.seed, "ticks": o.ticks, "slowdown": o.slowdown,
		"err": "", "digests": [], "hashes": {}, "final": "", "desync": -1}
	var digests: Array = []
	digests.resize(o.ticks)
	host.configure = func(sess: NetSession) -> void:
		sess.verify = true
		sess.matchInfo = {"seed": o.seed, "setup": setup, "ai": ai}
		if o.perturb >= 0:
			var pt: int = o.perturb
			sess.perturb = func(S_: SimState, t: int) -> void:
				if t == pt:
					S_.rng.a ^= 1
		sess.onConfirmed = func(b: int, st, out: String) -> void:
			if b > o.ticks:
				return
			if st == null:
				if res.err == "":
					res.err = "no state for confirmed tick %d" % b
				return
			digests[b - 1] = NetDesync.digest(st) + "|" + out
			if b % o.hashEvery == 0 or b == o.ticks:
				res.hashes[str(b)] = SimHash.stateHash(st).gameplay
	var t0: int = Time.get_ticks_usec()
	var limit: float = o.timeout * 1000.0 if o.timeout > 0.0 else float(o.ticks) * FRAME_MS * 4.0 + 30000.0
	var n: int = 0
	var lingerTo: float = -1.0
	var hitched: bool = false
	var adv: Array = []
	var frameUs := PackedInt32Array()
	while true:
		var now: float = float(Time.get_ticks_usec() - t0) / 1000.0
		var f0: int = Time.get_ticks_usec()
		host.frame(now, o.ticks)
		if host.session != null:
			frameUs.append(Time.get_ticks_usec() - f0)
			if not hitched and o.hitchAt >= 0 and host.session.frame >= o.hitchAt:
				hitched = true
				host.stallFrames = o.hitchFrames
			if host.frames % 15 == 0:   # the system clock is shared by both processes: enet_check measures the true lead
				adv.append([int(Time.get_unix_time_from_system() * 1000.0), host.session.frame, snappedf(host.sync.current, 0.01)])
		if host.hs.failed != "":
			res.err = "handshake: " + host.hs.failed
			break
		if tr.failed != "":
			res.err = tr.failed
			break
		if host.finished(o.ticks):
			if lingerTo < 0.0:
				lingerTo = now + 1500.0   # keep answering, so the other peer hears our acknowledgements
			elif now >= lingerTo or not tr.isOpen():
				break
		elif not tr.isOpen():
			res.err = "the other peer disconnected at tick %d" % (host.session.frame if host.session != null else -1)
			break
		if now > limit:
			res.err = "timed out after %.0f s at tick %s" % [now / 1000.0, str(host.session.frame) if host.session != null else "(handshake)"]
			break
		n += 1
		var after: float = float(Time.get_ticks_usec() - t0) / 1000.0
		var due: float = float(n) * FRAME_MS
		if due > after:
			OS.delay_usec(int((due - after) * 1000.0))
		elif after - due > 100.0:
			n = int(after / FRAME_MS)   # far behind: drop the schedule rather than run a burst
	var sess: NetSession = host.session
	if sess != null:
		if res.err == "" and sess.finalTo >= o.ticks:
			res.final = SimHash.stateHash(sess.S).gameplay
		res.desync = int(sess.desync.get("tick", -1))
		var fu: Array = Array(frameUs)
		fu.sort()
		res.merge({"delay": host.hs.delay, "mine": int(host.hs.mine.get("delay", -1)), "theirs": host.hs.theirs,
			"hsRttMedian": float(host.hs.mine.get("medianMs", -1.0)), "hsSamples": host.hs.rtts.size(), "hsMs": host.hs.doneAt,
			"playRttMedian": host.rttMs(), "rttSamples": host.rttAll, "frames": host.frames, "waits": host.waits,
			"syncDecisions": host.sync.decisions, "stalls": sess.stalls, "rollbacks": sess.rollbacks, "resim": sess.resimTicks,
			"maxDepth": sess.maxDepth, "mispredicted": sess.mispredicted, "checksMatched": sess.checksMatched,
			"pktOut": tr.pktOut, "pktIn": tr.pktIn, "bytesOut": tr.bytesOut, "bytesIn": tr.bytesIn,
			"lost": tr.lag.lost if tr.lag != null else 0, "wallS": float(Time.get_ticks_usec() - t0) / 1e6,
			"frameP50Ms": float(fu[fu.size() / 2]) / 1000.0 if not fu.is_empty() else 0.0,
			"frameP99Ms": float(fu[int(fu.size() * 0.99)]) / 1000.0 if not fu.is_empty() else 0.0, "adv": adv})
	res.digests = digests
	host.close()
	SimCore.dispose(S)
	var fo := FileAccess.open(o.out, FileAccess.WRITE)
	if fo == null:
		push_error("enet_peer: cannot write %s" % o.out)
		return 2
	fo.store_string(JSON.stringify(res))
	fo.close()
	return 0 if res.err == "" else 1
