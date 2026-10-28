extends SceneTree
## The rollback core's determinism check (docs/net/rollback.md section 6). For each seed it plays a straight,
## non-networked replay of the bots' inputs (SimReplay's recorder, so the run is a replay file too, which SimReplay.play
## then verifies), and for each network profile two peers over the loopback (net/loopback.gd), in verify mode. Passes
## (exit 0) only if, at every confirmed tick of both peers:
##   - SimHash.stateHash's gameplay hash equals the straight run's at that tick (every --hash-every ticks; 1 by default),
##   - the tick's feed lines and fx events (the director's decisions as the host sees them) equal the straight run's,
## and both peers' confirmed input logs and final states equal the straight run's, and neither peer's desync detection
## (NetSession.checkEvery, on at its default) fired. It also checks the state graph has no
## shared plain containers (NetSnapshot.aliasAudit) and that sessions free their objects.
##   godot --headless --path . --script res://net/tools/rollback_check.gd -- [--seeds=1,2,3] [--ticks=1200]
##     [--profiles=lan,p80j,...|all] [--setup=default|features|planet|calm] [--delay=2|auto] [--devices=1,1]
##     [--hash-every=1] [--sparse=K] [--negative-control]
## --delay=auto runs each profile at the delay its handshake agrees (NetLoopback.agree: both peers ping over links of
## that profile, propose NetDelay.choose for their own device, --devices' slowdowns, and the larger wins), against a
## straight run with that delay.
## --sparse=K runs the sessions as a game would (not in verify mode): a save only before a predicted tick, at most one
## every K ticks. The feed and fx of every confirmed tick and the final states are still compared; the SimHash only at
## the confirmed ticks whose state the session still holds (a save, or the present).
## --negative-control breaks the session on purpose, twice (a restore that leaves one bit of the RNG wrong; late inputs
## that never roll back), and passes only if the check catches both on every profile where an input arrived late.

const SETUPS: Dictionary = {
	"default": {},
	"features": {"v2": [true, true], "forms": true, "brake": true, "flight": true, "hitstop": true, "ricochet": true},
	"planet": {"planet": 7, "touch": 3},
	"calm": {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}},   # the calm-moment turn: World's statics keyed by world
}

## Containers the state reaches by two paths that are only read, never written in place (checked by reading the code,
## 2026-10-28): a snapshot splits them into two equal copies, which changes nothing. World's ring axis vectors: a turn
## replaces the ring and its vectors whole (world/epoch.gd, world/ringpick.gd). Any other sharing fails the check.
const READ_ONLY_SHARED: Array = ["S.planetRing[c] and S.epoch[c0]", "S.planetRing[c] and S.epoch[ring][c]", "S.planetRing[t] and S.epoch[ring][t]"]

var failures: int = 0
var sabotage: String = ""   # the negative control's current break: "", "restore" or "norollback"
var sparse: int = 0         # 0: verify mode; K: the game's saving, one save at most every K ticks
var devices: Array = [NetDelay.device(1.0), NetDelay.device(1.0)]
var refs: Dictionary = {}   # [seed, delay] -> the straight run


func _init() -> void:
	var seeds: Array = [1, 2, 3, 4]
	var ticks: int = 1200
	var profiles: Array = NetLoopback.PROFILES.keys()
	var setupName: String = "default"
	var delay: int = 2
	var hashEvery: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--profiles=") and a.substr(11) != "all":
			profiles = Array(a.substr(11).split(","))
		elif a.begins_with("--setup="):
			setupName = a.substr(8)
		elif a.begins_with("--delay="):
			delay = -1 if a.substr(8) == "auto" else int(a.substr(8))
		elif a.begins_with("--devices="):
			devices = Array(a.substr(10).split(",")).map(func(s): return NetDelay.device(float(s)))
		elif a.begins_with("--hash-every="):
			hashEvery = maxi(1, int(a.substr(13)))
		elif a.begins_with("--sparse="):
			sparse = maxi(1, int(a.substr(9)))
		elif a == "--negative-control":
			sabotage = "on"
	var setup: Dictionary = SETUPS[setupName]
	print("Orb Combat EX rollback check   Godot %s   setup %s   %d ticks   delay %s   hash every %d   %s" % [Engine.get_version_info().string, setupName, ticks, str(delay) if delay >= 0 else "auto (handshake)", hashEvery, "verify mode" if sparse == 0 else "sparse saving, every %d" % sparse])
	if sabotage != "":
		_negative(seeds, setup, ticks, delay, hashEvery, profiles)
		return
	var objects0: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var sessions: int = 0
	var hashed: int = 0
	for seed in seeds:
		for pname in profiles:
			var d: int = _delayFor(seed, setupName, setup, pname, delay)
			if d < 0:
				continue
			var ref := _ref(seed, setup, ticks, d, hashEvery)
			var res := _session(seed, setup, ticks, d, hashEvery, NetLoopback.PROFILES[pname], ref)
			sessions += 1
			hashed += int(res.hashed)
			var tag: String = "ok  " if res.err == "" else "FAIL"
			print("  %s %-6s  delay %d  hashes %5d  outs %5d  rollbacks %5d  resim %6d  max depth %2d  stalls %4d  lost %4d/%d  %s" % [tag, pname, d, res.hashed, res.outs, res.rollbacks, res.resim, res.maxDepth, res.stalls, res.lost, res.sent, res.err])
			if res.err != "":
				failures += 1
	var objects1: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	print("objects alive before %d, after %d" % [objects0, objects1])
	if objects1 > objects0 + 50:
		print("FAIL  sessions leak objects (%d more)" % (objects1 - objects0))
		failures += 1
	if sessions == 0:
		print("FAIL  no session ran")
		failures += 1
	print("%s  %d sessions, %d confirmed-tick hash comparisons, %d failure(s)" % ["PASS" if failures == 0 else "FAIL", sessions, hashed, failures])
	quit(0 if failures == 0 else 1)


## Each break must be caught on every profile that rolls back (lan never does, so it is skipped).
func _negative(seeds: Array, setup: Dictionary, ticks: int, delay: int, hashEvery: int, profiles: Array) -> void:
	var missed: int = 0
	var caught: int = 0
	for seed in seeds:
		for brk in ["restore", "norollback"]:
			for pname in profiles:
				if pname == "lan":
					continue
				sabotage = ""
				var d: int = _delayFor(seed, "", setup, pname, delay)
				if d < 0:
					continue
				var ref := _ref(seed, setup, ticks, d, hashEvery)
				sabotage = brk
				var res := _session(seed, setup, ticks, d, hashEvery, NetLoopback.PROFILES[pname], ref)
				if res.mispred == 0:
					continue   # every input arrived in time: nothing was predicted wrong, so nothing to catch
				print("  %s %-10s %-6s  delay %d  %s" % ["caught" if res.err != "" else "MISSED", brk, pname, d, res.err])
				if res.err == "":
					missed += 1
				else:
					caught += 1
	print("%s  negative control: %d break(s) caught, %d missed" % ["PASS" if missed == 0 and caught > 0 else "FAIL", caught, missed])
	quit(0 if missed == 0 and caught > 0 else 1)


## The delay a profile's session runs at: the fixed one, or (fixed < 0) the one its handshake agrees; -1 on a failed
## handshake (a failure, counted).
func _delayFor(seed: int, setupName: String, setup: Dictionary, pname: String, fixed: int) -> int:
	if fixed >= 0:
		return fixed
	var ag: Dictionary = NetLoopback.agree(NetHandshake.keyOf(seed, {"p1": false, "p2": false}, setup), NetLoopback.PROFILES[pname], devices, seed * 131 + int(NetLoopback.PROFILES[pname].ping))
	if setupName != "":
		print("  handshake %-6s  proposals %d and %d -> delay %d   rtt median %.0f, %.0f ms   %d frames  %s" % [pname, ag.proposals[0], ag.proposals[1], ag.delay, ag.rttMedian[0], ag.rttMedian[1], ag.frames, ag.failed])
	if ag.failed != "" or ag.delay != maxi(ag.proposals[0], ag.proposals[1]):
		print("FAIL  handshake on %s: %s" % [pname, ag.failed if ag.failed != "" else "the delay is not the larger proposal"])
		failures += 1
		return -1
	return ag.delay


## The straight run for (seed, delay), made once and checked when made.
func _ref(seed: int, setup: Dictionary, ticks: int, delay: int, hashEvery: int) -> Dictionary:
	var key: Array = [seed, delay]
	if refs.has(key):
		return refs[key]
	var ref := _straight(seed, setup, ticks, delay, hashEvery)
	if sabotage == "":
		print("seed %d  delay %d  straight: %d exchanges, %d ticks with feed or fx, replay %s, KO %s, aliases %s" % [seed, delay, ref.exN, ref.outTicks, "verified" if ref.replayOk else "FAILED", ref.ko, "none" if ref.aliases.is_empty() else str(ref.aliases)])
		if not ref.replayOk or not ref.aliases.is_empty():
			failures += 1
	refs[key] = ref
	return ref


## The straight run: the same inputs, no network. {hash: tick -> gameplay hash, out: tick -> digest, final, inputs,
## exN, outTicks, replayOk, aliases, ko}.
func _straight(seed: int, setup: Dictionary, ticks: int, delay: int, hashEvery: int) -> Dictionary:
	var S := SimCore.createSim()
	var rec := SimReplay.recorder(S, seed, {"p1": false, "p2": false}, setup)
	var bots: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
	var hashes: Dictionary = {}
	var outs: Array = []
	var log: Array = [[], []]
	var aliases: Array = NetSnapshot.aliasAudit(S)
	var outTicks: int = 0
	for t in range(ticks):
		var ins: Array = []
		for k in range(2):
			var p: int = NetSession.NEUTRAL if t < delay else bots[k].next()
			log[k].append(p)
			ins.append(SimIntent.unpack(p))
		rec.step(ins)
		var d: String = NetSession.outDigest(S)
		if d != "":
			outTicks += 1
		outs.append(d)
		S.out.feed.clear()
		S.out.fx.clear()
		if (t + 1) % hashEvery == 0 or t + 1 == ticks:
			hashes[t + 1] = SimHash.stateHash(S).gameplay
		if t + 1 == ticks / 2:
			aliases += NetSnapshot.aliasAudit(S)
	aliases += NetSnapshot.aliasAudit(S)
	aliases = aliases.filter(func(a): return not READ_ONLY_SHARED.has(a))
	var rp: Dictionary = rec.finish()
	var play: Dictionary = SimReplay.play(rp)
	var ref := {"hash": hashes, "out": outs, "final": hashes[ticks], "log": log, "exN": S.dirS.exN, "outTicks": outTicks,
		"replayOk": play.ok and play.final == hashes[ticks], "aliases": aliases, "ko": S.game.ko != null}
	SimCore.dispose(S)
	return ref


func _session(seed: int, setup: Dictionary, ticks: int, delay: int, hashEvery: int, profile: Dictionary, ref: Dictionary) -> Dictionary:
	var L := NetLoopback.make(seed, setup, profile, delay, seed, seed * 31 + int(profile.ping))
	var res := {"err": "", "hashed": 0, "outs": 0, "rollbacks": 0, "resim": 0, "maxDepth": 0, "mispred": 0, "stalls": 0, "lost": 0, "sent": 0}
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		sess.verify = sparse == 0
		sess.saveEvery = maxi(1, sparse)
		if sabotage == "restore":
			sess.afterRestore = func(S_: SimState) -> void: S_.rng.a ^= 1
		elif sabotage == "norollback":
			sess.rollbackOn = false
		sess.onConfirmed = func(b: int, st, out: String) -> void:
			if res.err != "":
				return
			if out != ref.out[b - 1]:
				res.err = "peer %d: tick %d's feed and fx differ from the straight run" % [k, b]
				return
			res.outs += 1
			if ref.hash.has(b):
				if st == null:
					if sparse == 0:
						res.err = "peer %d: no state for confirmed tick %d" % [k, b]
					return
				if SimHash.stateHash(st).gameplay != ref.hash[b]:
					res.err = "peer %d: SimHash differs from the straight run after tick %d" % [k, b]
					return
				res.hashed += 1
	if not L.run(ticks):
		res.err = "did not confirm %d ticks in %d frames" % [ticks, L.frames]
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		res.rollbacks += sess.rollbacks
		res.resim += sess.resimTicks
		res.mispred += sess.mispredicted
		res.maxDepth = maxi(res.maxDepth, sess.maxDepth)
		res.stalls += sess.stalls
		res.lost += L.links[k].lost
		res.sent += L.links[k].sent
		if res.err == "" and not sess.desync.is_empty() and sabotage == "":
			res.err = "peer %d: desync detection fired at checkpoint %d" % [k, sess.desync.tick]
		if res.err == "":
			if SimHash.stateHash(sess.S).gameplay != ref.final:
				res.err = "peer %d: final state differs from the straight run" % k
			else:
				for slot in range(2):
					for t in range(ticks):
						if res.err == "" and int(sess.inputs[slot][t]) != int(ref.log[slot][t]):
							res.err = "peer %d: confirmed input of slot %d at tick %d differs" % [k, slot, t]
	L.close()
	return res
