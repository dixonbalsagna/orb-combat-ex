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
##
## --ai (docs/net/rollback.md section 12): each slot's input comes from the fighter AI (NetAiDriver), run on its own peer
## from that peer's present state (predictions included) to a KO. --ticks is then the cap (45000 by default) and a run
## stops --tail ticks (120) after the KO. The inputs depend on what each peer saw, so the straight run replays the
## confirmed inputs the peers agreed on; and on every profile where no prediction was wrong (lan always), it also runs the
## AI itself, from the straight state, and its inputs must equal the peers' (the AI reads nothing the state does not
## carry). Each setup is played with v2 slots (the AI states its stance through held fields). With --negative-control it
## plants a third break, "impure": peer 0's AI runs on its live state, so its writes (S.rng draws, its timers) reach that
## sim alone; it must be caught on every profile.
## --ai=sim plays P2 as the sim's own AI (newMatch's ai flag): it runs inside every tick on the peer's state and is run
## again by every rollback, so it is rollback-safe only if the snapshot restores everything it reads and writes. P1 is the
## driver's, so inputs still arrive late. The "impure" break is P1's.

const SETUPS: Dictionary = {
	"default": {},
	"features": {"v2": [true, true], "forms": true, "brake": true, "flight": true, "hitstop": true, "ricochet": true},
	"planet": {"planet": 7, "touch": 3},
	"calm": {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}},   # the calm-moment turn: World's statics keyed by world
	"depth": {"depth": true},   # fight lanes: depth physical (data/combat/depth.json's switch, on for this match)
	"planet2": {"planet": 7, "touch": 3, "arena": {"cols": 2400}, "planetGen": 2, "intro": false},   # a gen 2 ring, as QA plays them (qa/godot/qa_planet.gd)
	"planet2depth": {"planet": 7, "touch": 3, "arena": {"cols": 2400}, "planetGen": 2, "intro": false, "depth": true},
}

## Containers the state reaches by two paths that are only read, never written in place (checked by reading the code,
## 2026-10-28): a snapshot splits them into two equal copies, which changes nothing. World's ring axis vectors: a turn
## replaces the ring and its vectors whole (world/epoch.gd, world/ringpick.gd). A gen 2 ring's fine biomes (checked
## 2026-10-28, ai-depth): S.fineCols and S.planetRing["fine"] are both the slice's array (core/sim.gd, world/planet_world.gd),
## and the calm turn builds a new one and sets both (world/epoch.gd); nothing writes either in place. Any other sharing
## fails the check.
const READ_ONLY_SHARED: Array = ["S.planetRing[c] and S.epoch[c0]", "S.planetRing[c] and S.epoch[ring][c]", "S.planetRing[t] and S.epoch[ring][t]", "S.fineCols and S.planetRing[fine]"]

var failures: int = 0
var sabotage: String = ""   # the negative control's current break: "", "restore" or "norollback"
var sparse: int = 0         # 0: verify mode; K: the game's saving, one save at most every K ticks
var devices: Array = [NetDelay.device(1.0), NetDelay.device(1.0)]
var refs: Dictionary = {}   # [seed, delay] -> the straight run
var aiMode: bool = false    # --ai: the fighter AI drives every slot, to a KO
var aiSim: bool = false     # --ai=sim: P2 is the sim's own AI (inside the tick, re-run by rollbacks); P1 the driver's
var aiFlags: Dictionary = {"p1": false, "p2": false}
var tail: int = 120         # --ai: ticks played on after the KO


func _init() -> void:
	var seeds: Array = [1, 2, 3, 4]
	var ticks: int = -1
	var profiles: Array = NetLoopback.PROFILES.keys()
	var setupName: String = "default"
	var delay: int = 2
	var hashEvery: int = -1
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
		elif a == "--ai" or a == "--ai=sim":
			aiMode = true
			aiSim = a == "--ai=sim"
			if aiSim:
				aiFlags = {"p1": false, "p2": true}
		elif a.begins_with("--tail="):
			tail = maxi(1, int(a.substr(7)))
	if ticks < 0:
		ticks = 45000 if aiMode else 1200
	if hashEvery < 0:
		hashEvery = 60 if aiMode else 1
	var setup: Dictionary = SETUPS[setupName]
	if aiMode:
		setup = setup.duplicate(true)
		setup["v2"] = [true, true]
	print("Orb Combat EX rollback check   Godot %s   setup %s   %d ticks   delay %s   hash every %d   %s" % [Engine.get_version_info().string, setupName, ticks, str(delay) if delay >= 0 else "auto (handshake)", hashEvery, "verify mode" if sparse == 0 else "sparse saving, every %d" % sparse])
	if aiMode:
		print("fighter AI on every slot (%s), cap %d ticks, tail %d" % ["P1 NetAiDriver, P2 the sim's own AI" if aiSim else "NetAiDriver", ticks, tail])
		if sabotage != "":
			_aiNegative(seeds, setup, ticks, delay, hashEvery, profiles)
		else:
			_aiMain(seeds, setupName, setup, ticks, delay, hashEvery, profiles)
		return
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
	var ag: Dictionary = NetLoopback.agree(NetHandshake.keyOf(seed, aiFlags, setup), NetLoopback.PROFILES[pname], devices, seed * 131 + int(NetLoopback.PROFILES[pname].ping))
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


## --ai: every seed on every profile, to a KO.
func _aiMain(seeds: Array, setupName: String, setup: Dictionary, cap: int, delay: int, hashEvery: int, profiles: Array) -> void:
	var objects0: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var sessions: int = 0
	var hashed: int = 0
	var digests: int = 0
	var kos: int = 0
	var own: int = 0
	for seed in seeds:
		for pname in profiles:
			var d: int = _delayFor(seed, setupName, setup, pname, delay)
			if d < 0:
				continue
			var t0: int = Time.get_ticks_msec()
			var res := _aiSession(seed, setup, cap, d, hashEvery, pname)
			sessions += 1
			hashed += int(res.hashed)
			digests += int(res.digests)
			kos += 1 if res.ko >= 0 else 0
			own += 1 if res.own else 0
			var tag: String = "ok  " if res.err == "" else "FAIL"
			print("  %s seed %d %-6s  delay %d  KO %s  ticks %5d  exchanges %4d  digests %5d  hashes %4d  rollbacks %5d  resim %6d  max depth %2d  stalls %4d  lost %4d/%d  AI straight %s  %.0f s  %s" % [tag, seed, pname, d, "tick %d" % res.ko if res.ko >= 0 else "none", res.until, res.exN, res.digests, res.hashed, res.rollbacks, res.resim, res.maxDepth, res.stalls, res.lost, res.sent, "same" if res.own else "-", (Time.get_ticks_msec() - t0) / 1000.0, res.err])
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
	print("%s  %d AI sessions, %d reached a KO, %d also matched the AI's own straight run, %d confirmed-tick digest and %d SimHash comparisons (every %d ticks), %d failure(s)" % ["PASS" if failures == 0 else "FAIL", sessions, kos, own, digests, hashed, hashEvery, failures])
	quit(0 if failures == 0 else 1)


## --ai --negative-control: each break must be caught; "restore" and "norollback" wherever an input arrived late,
## "impure" everywhere.
func _aiNegative(seeds: Array, setup: Dictionary, cap: int, delay: int, hashEvery: int, profiles: Array) -> void:
	var missed: int = 0
	var caught: int = 0
	for seed in seeds:
		for brk in ["impure", "restore", "norollback"]:
			for pname in profiles:
				if pname == "lan" and brk != "impure":
					continue
				sabotage = ""
				var d: int = _delayFor(seed, "", setup, pname, delay)
				if d < 0:
					continue
				sabotage = brk
				var res := _aiSession(seed, setup, cap, d, hashEvery, pname)
				if brk != "impure" and res.mispred == 0:
					continue
				print("  %s %-10s seed %d %-6s  delay %d  %s" % ["caught" if res.err != "" else "MISSED", brk, seed, pname, d, res.err])
				if res.err == "":
					missed += 1
				else:
					caught += 1
	sabotage = ""
	print("%s  AI negative control: %d break(s) caught, %d missed" % ["PASS" if missed == 0 and caught > 0 else "FAIL", caught, missed])
	quit(0 if missed == 0 and caught > 0 else 1)


## One AI match over the loopback: both peers' confirmed ticks against the straight replay of the inputs they confirmed.
func _aiSession(seed: int, setup: Dictionary, cap: int, delay: int, hashEvery: int, pname: String) -> Dictionary:
	var profile: Dictionary = NetLoopback.PROFILES[pname]
	var L := NetLoopback.make(seed, setup, profile, delay, seed, seed * 31 + int(profile.ping), false, aiFlags)
	var res := {"err": "", "hashed": 0, "digests": 0, "rollbacks": 0, "resim": 0, "maxDepth": 0, "mispred": 0, "stalls": 0, "lost": 0, "sent": 0, "ko": -1, "until": 0, "exN": 0, "own": false}
	# Per peer: {dig: [NetDesync.digest after tick b, at b - 1], hash: {b: SimHash gameplay hash, every hashEvery ticks},
	# out: [feed and fx digests], ko}. The full gameplay hash costs some 15 ms a state, so a match of 30,000 ticks hashes
	# every hashEvery ticks (and its last), and the desync digest (a third of a millisecond, the same fields in a cheaper
	# fold) every tick.
	var rec: Array = []
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		sess.verify = sparse == 0
		sess.saveEvery = maxi(1, sparse)
		if sabotage == "restore":
			sess.afterRestore = func(S_: SimState) -> void: S_.rng.a ^= 1
		elif sabotage == "norollback":
			sess.rollbackOn = false
		var drv := NetAiDriver.new(k, seed, sess)
		drv.impure = sabotage == "impure" and k == 0
		L.peers[k].bot = drv
		var r := {"dig": [], "hash": {}, "out": [], "ko": -1}
		rec.append(r)
		sess.onConfirmed = func(b: int, st, out: String) -> void:
			r.out.append(out)
			r.dig.append(NetDesync.digest(st) if st != null else "")
			if st != null and (b % hashEvery == 0 or b == res.until):
				r.hash[b] = SimHash.stateHash(st).gameplay
			if r.ko < 0 and st != null and st.game.ko != null:
				r.ko = b
	var until: int = cap
	res.until = until
	var done: bool = false
	while L.frames < cap * 4 + 600:
		L.step(until)
		var ko: int = rec[0].ko if rec[0].ko >= 0 else rec[1].ko
		if ko >= 0:
			until = mini(cap, ko + tail)
		res.until = until
		done = true
		for p in L.peers:
			if p.session.frame < until or p.session.finalTo < until:
				done = false
		if done:
			break
	res.until = until
	res.ko = rec[0].ko if rec[0].ko >= 0 and rec[0].ko <= until else -1
	if not done:
		res.err = "did not confirm %d ticks in %d frames" % [until, L.frames]
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
	var log: Array = [[], []]
	if res.err == "":
		for slot in range(2):
			for t in range(until):
				var v0 = L.peers[0].session.inputs[slot].get(t)
				var v1 = L.peers[1].session.inputs[slot].get(t)
				if res.err == "" and (v0 == null or v0 != v1):
					res.err = "the peers' confirmed inputs of slot %d at tick %d differ" % [slot, t]
				log[slot].append(int(v0) if v0 != null else NetSession.NEUTRAL)
	if res.err == "" and (rec[0].ko != rec[1].ko):
		res.err = "the peers saw the KO at different ticks (%d, %d)" % [rec[0].ko, rec[1].ko]
	if res.err == "":
		var ref := _aiStraight(seed, setup, until, delay, hashEvery, log)
		res.exN = ref.exN
		if not ref.replayOk:
			res.err = "the straight run's replay did not verify"
		elif not ref.aliases.is_empty():
			res.err = "the state shares containers: %s" % str(ref.aliases)
		elif ref.ko != res.ko:
			res.err = "the straight run's KO (tick %d) is not the peers' (%d)" % [ref.ko, res.ko]
		for k in range(2):
			for b in range(1, until + 1):
				if res.err != "":
					break
				if rec[k].out[b - 1] != ref.out[b - 1]:
					res.err = "peer %d: tick %d's feed and fx differ from the straight run" % [k, b]
				elif rec[k].dig[b - 1] == "":
					if sparse == 0:
						res.err = "peer %d: no state for confirmed tick %d" % [k, b]
				elif rec[k].dig[b - 1] != ref.dig[b - 1]:
					res.err = "peer %d: the state's digest differs from the straight run after tick %d" % [k, b]
				else:
					res.digests += 1
					if ref.hash.has(b):
						if rec[k].hash.get(b, "") != ref.hash[b]:
							res.err = "peer %d: SimHash differs from the straight run after tick %d" % [k, b]
						else:
							res.hashed += 1
		if res.err == "" and SimHash.stateHash(L.peers[0].session.S).gameplay != SimHash.stateHash(L.peers[1].session.S).gameplay:
			res.err = "the peers' final states differ"
		# No prediction was wrong, so every state either peer's AI read was the straight run's: the AI run from the straight
		# state must give the same inputs, or it reads something the state does not carry.
		if res.err == "" and res.mispred == 0:
			var own := _aiStraight(seed, setup, until, delay, hashEvery, [])
			for slot in range(2):
				for t in range(until):
					if res.err == "" and int(own.log[slot][t]) != int(log[slot][t]):
						res.err = "slot %d's AI input at tick %d differs from the AI run on the straight state" % [slot, t]
			if res.err == "" and own.final != ref.final:
				res.err = "the AI's own straight run ends in another state"
			res.own = res.err == ""
	L.close()
	return res


## The straight run of an AI match: the inputs of `log` ([slot] -> per tick), or with an empty log the AI itself
## (NetAiDriver on the straight state; tick t's input read after t - delay ticks, as a peer's is). {dig, hash, out, log,
## final, replayOk, ko, exN, aliases}.
func _aiStraight(seed: int, setup: Dictionary, ticks: int, delay: int, hashEvery: int, log: Array) -> Dictionary:
	var S := SimCore.createSim()
	var rec := SimReplay.recorder(S, seed, aiFlags, setup)
	var drivers: Array = []
	var played: Array = [[], []]
	if log.is_empty():
		for k in range(2):
			drivers.append(NetAiDriver.new(k, seed, null, S))
			for t in range(delay):
				played[k].append(NetSession.NEUTRAL)
	var hashes: Dictionary = {}
	var aliases: Array = NetSnapshot.aliasAudit(S)
	var digs: Array = []
	var outs: Array = []
	var ko: int = -1
	for t in range(ticks):
		var ins: Array = []
		for k in range(2):
			var p: int
			if log.is_empty():
				played[k].append(drivers[k].think(S))   # the input for tick t + delay
				p = played[k][t]
			else:
				p = log[k][t]
			ins.append(SimIntent.unpack(p))
		rec.step(ins)
		outs.append(NetSession.outDigest(S))
		S.out.feed.clear()
		S.out.fx.clear()
		digs.append(NetDesync.digest(S))
		if (t + 1) % hashEvery == 0 or t + 1 == ticks:
			hashes[t + 1] = SimHash.stateHash(S).gameplay
		if ko < 0 and S.game.ko != null:
			ko = t + 1
		if t + 1 == ticks / 2:
			aliases += NetSnapshot.aliasAudit(S)
	aliases += NetSnapshot.aliasAudit(S)
	aliases = aliases.filter(func(a): return not READ_ONLY_SHARED.has(a))
	var rp: Dictionary = rec.finish()
	var play: Dictionary = SimReplay.play(rp)
	var final: String = hashes[ticks]
	var out := {"dig": digs, "hash": hashes, "out": outs, "log": played if log.is_empty() else log, "final": final, "replayOk": play.ok and play.final == final, "ko": ko, "exN": S.dirS.exN, "aliases": aliases}
	for drv in drivers:
		drv.close()
	SimCore.dispose(S)
	return out
