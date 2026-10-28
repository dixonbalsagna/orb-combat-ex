extends SceneTree
## The spectator's check (docs/net/rollback.md section 8). Two peers over the loopback (net/loopback.gd), run as a game
## runs them, and a spectator fed by one of them (the relay) over a link with the same profile: it receives only the
## confirmed inputs of both slots, plays them --lag ticks behind the newest it holds, never predicts and never rolls
## back. Passes (exit 0) only if, on every profile:
##   - the spectator's state equals the straight run's (SimHash.stateHash) after every --hash-every-th tick and at the
##     end, and every tick's feed and fx digest equals the straight run's;
##   - the spectator's checkpoint digests equal the relay's (no desync seen) and it compared most of them;
##   - it ran every tick, and the players' own desync detection saw nothing.
## It prints how far behind the players the spectator ran (ticks) its jitter buffer's lag at the end and how often it ran dry.
## --negative-control breaks the relay twice and passes only if the check catches both: a relay that forwards the inputs
## its ticks ran with (predictions included) instead of the confirmed ones, and a stream in which one slot's stick is thrown
## the other way for 12 ticks. Each must show as a state that differs from the straight run's and as a spectator desync.
##   godot --headless --path . --script res://net/tools/spectator_check.gd -- [--seeds=1,2] [--ticks=900] [--lag=6]
##     [--profiles=...|all] [--setup=default|features|planet] [--delay=2] [--relay=0] [--hash-every=10] [--negative-control]

const SETUPS: Dictionary = {
	"default": {},
	"features": {"v2": [true, true], "forms": true, "brake": true, "flight": true, "hitstop": true, "ricochet": true},
	"planet": {"planet": 7, "touch": 3},
}

var failures: int = 0


func _init() -> void:
	var seeds: Array = [1, 2]
	var ticks: int = 900
	var lag: int = 6
	var profiles: Array = NetLoopback.PROFILES.keys()
	var setupName: String = "default"
	var delay: int = 2
	var relay: int = 0
	var hashEvery: int = 10
	var negative: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--lag="):
			lag = maxi(0, int(a.substr(6)))
		elif a.begins_with("--profiles=") and a.substr(11) != "all":
			profiles = Array(a.substr(11).split(","))
		elif a.begins_with("--setup="):
			setupName = a.substr(8)
		elif a.begins_with("--delay="):
			delay = int(a.substr(8))
		elif a.begins_with("--relay="):
			relay = clampi(int(a.substr(8)), 0, 1)
		elif a.begins_with("--hash-every="):
			hashEvery = maxi(1, int(a.substr(13)))
		elif a == "--negative-control":
			negative = true
	var setup: Dictionary = SETUPS[setupName]
	print("Orb Combat EX spectator check   Godot %s   setup %s   %d ticks   lag %d   relay peer %d   delay %d   hash every %d" % [Engine.get_version_info().string, setupName, ticks, lag, relay, delay, hashEvery])
	var objects0: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var caught: int = 0
	var missed: int = 0
	var runs: int = 0
	var hashed: int = 0
	for seed in seeds:
		var ref := _straight(seed, setup, ticks, delay, hashEvery)
		for pname in profiles:
			if negative:
				for brk in ["predicted", "flip"]:
					if brk == "predicted" and pname == "lan":
						continue   # lan never predicts: the forwarded inputs are the confirmed ones
					var res := _run(seed, setup, ticks, delay, lag, relay, hashEvery, pname, ref, brk)
					if brk == "predicted" and res.mispred == 0:
						continue
					var hit: bool = res.err != "" and res.specDesync
					print("  %s %-9s %-6s  %s%s" % ["caught" if hit else "MISSED", brk, pname, res.err, "" if res.specDesync else "  (no spectator desync)"])
					if hit:
						caught += 1
					else:
						missed += 1
				continue
			var res := _run(seed, setup, ticks, delay, lag, relay, hashEvery, pname, ref, "")
			runs += 1
			hashed += int(res.hashed)
			print("  %s seed %d %-6s  hashes %4d  checkpoints %2d  behind players: mean %.1f ticks (%.0f ms), max %d  lag %d->%d, rebuffers %d, frames idle %d/%d  %s" % ["ok  " if res.err == "" else "FAIL", seed, pname, res.hashed, res.checks, res.behind, res.behind * NetLoopback.FRAME_MS, res.behindMax, lag, res.lag, res.rebuffers, res.waits, res.frames, res.err])
			if res.err != "":
				failures += 1
	if negative:
		print("%s  negative control: %d break(s) caught, %d missed" % ["PASS" if missed == 0 and caught > 0 else "FAIL", caught, missed])
		quit(0 if missed == 0 and caught > 0 else 1)
		return
	var objects1: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	print("objects alive before %d, after %d" % [objects0, objects1])
	if objects1 > objects0 + 50:
		print("FAIL  runs leak objects (%d more)" % (objects1 - objects0))
		failures += 1
	if runs == 0:
		failures += 1
	print("%s  %d spectated sessions, %d spectator hash comparisons, %d failure(s)" % ["PASS" if failures == 0 else "FAIL", runs, hashed, failures])
	quit(0 if failures == 0 else 1)


## The straight run: {hash: tick -> gameplay hash, out: per tick digest, final}.
func _straight(seed: int, setup: Dictionary, ticks: int, delay: int, hashEvery: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, setup)
	var bots: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
	var hashes: Dictionary = {}
	var outs: Array = []
	for t in range(ticks):
		var ins: Array = []
		for k in range(2):
			ins.append(SimIntent.unpack(NetSession.NEUTRAL if t < delay else bots[k].next()))
		SimCore.step(S, ins)
		outs.append(NetSession.outDigest(S))
		S.out.feed.clear()
		S.out.fx.clear()
		if (t + 1) % hashEvery == 0 or t + 1 == ticks:
			hashes[t + 1] = SimHash.stateHash(S).gameplay
	var ref := {"hash": hashes, "out": outs, "final": hashes[ticks]}
	SimCore.dispose(S)
	return ref


func _run(seed: int, setup: Dictionary, ticks: int, delay: int, lag: int, relay: int, hashEvery: int, pname: String, ref: Dictionary, brk: String) -> Dictionary:
	var profile: Dictionary = NetLoopback.PROFILES[pname]
	var L := NetLoopback.make(seed, setup, profile, delay, seed, seed * 41 + int(profile.ping) + 5)
	var sp := L.addSpectator(seed, setup, profile, lag, relay, seed * 43 + int(profile.ping) + 11)
	L.relayPredicted = brk == "predicted"
	var flipAt: int = ticks / 2 + 3
	if brk == "flip":
		sp.flip = func(t: int, k: int, p: int) -> int:   # slot 1's stick thrown the other way for 12 ticks
			if k != 1 or t < flipAt or t >= flipAt + 12:
				return p
			return (p & ~0xFF) | (254 if (p & 0xFF) <= 127 else 0)
	var res := {"err": "", "hashed": 0, "checks": 0, "behind": 0.0, "behindMax": 0, "waits": 0, "frames": 0, "mispred": 0, "specDesync": false, "lag": 0, "rebuffers": 0}
	var behindSum: int = 0
	var behindN: int = 0
	sp.onTick = func(b: int, st: SimState) -> void:
		if res.err != "":
			return
		var o: String = NetSession.outDigest(st)
		if o != ref.out[b - 1]:
			res.err = "spectator: tick %d's feed and fx differ from the straight run" % b
			return
		if ref.hash.has(b):
			if SimHash.stateHash(st).gameplay != ref.hash[b]:
				res.err = "spectator: SimHash differs from the straight run after tick %d" % b
				return
			res.hashed += 1
	var cap: int = ticks * 4 + 600
	while L.frames < cap:
		L.step(ticks)
		var lead: int = L.peers[relay].session.frame - sp.frame
		if sp.frame < ticks:
			behindSum += lead
			behindN += 1
			res.behindMax = maxi(res.behindMax, lead)
		var done: bool = sp.have >= ticks
		for p in L.peers:
			if p.session.frame < ticks or p.session.finalTo < ticks:
				done = false
		if done:
			break
	var dryInPlay: int = sp.waits
	sp.flush(ticks)
	if sp.frame < ticks and res.err == "":
		res.err = "spectator ran %d of %d ticks" % [sp.frame, ticks]
	if res.err == "" and SimHash.stateHash(sp.S).gameplay != ref.final:
		res.err = "spectator: final state differs from the straight run"
	res.specDesync = not sp.desync.is_empty()
	if res.err == "" and res.specDesync:
		res.err = "spectator desync at checkpoint %d" % sp.desync.tick
	res.checks = sp.checksMatched
	if brk == "" and res.err == "" and sp.checksMatched < ticks / 60 - 2:
		res.err = "spectator compared only %d checkpoints" % sp.checksMatched
	for p in L.peers:
		res.mispred += p.session.mispredicted
		if brk == "" and res.err == "" and not p.session.desync.is_empty():
			res.err = "peer %d saw a desync" % p.session.local
	res.behind = float(behindSum) / maxf(1.0, float(behindN))
	res.waits = dryInPlay
	res.lag = sp.lag
	res.rebuffers = sp.rebuffers
	res.frames = sp.frames
	L.close()
	return res
