extends SceneTree
## Desync detection's check (docs/net/rollback.md section 7). Two peers over the loopback (net/loopback.gd), run as a
## game runs them (not in verify mode), exchange a checkpoint digest every --every ticks. Passes (exit 0) only if:
##   - clean runs, every profile: no desync is reported, every checkpoint both peers confirmed equals the straight run's
##     digest at that tick, and the peers agreed on all but the last few checkpoints;
##   - injected divergence: one peer's state is changed once, at a tick that is not a checkpoint, by each of a set of
##     injections (one RNG bit, one ulp of a fighter's x, a building's hp, a terrain column, the mood's casualty count,
##     the director's cool-down). Both peers report a desync at the first checkpoint after it, with the last agreed
##     checkpoint the one before, the two digests crossed, and a report (NetDesync.report) whose field walk finds the
##     difference against the other peer and against the divergent peer's own replay, and none on the clean peer's
##     replay. The reports are written to --out. An injection the sim itself erases before the checkpoint (a fighter's
##     x that a landing or a snap overwrites: the divergent peer's full SimHash there equals the straight run's) has
##     nothing to detect and counts as healed; each injection must be detected in at least one run.
## --ai-timers plays P2 as the sim's own AI and instead injects a change to each of its timers on the tick before a
## checkpoint, so nothing else can differ yet: both peers must report a desync at that checkpoint, with the same report.
## With --negative-control the digest leaves out the timers (NetDesync.aiBlind) and every injection must be missed there.
## --negative-control breaks the detector twice and passes only if the check catches both: a blind detector (digests
## exchanged but never compared) must miss the injections, and a stale one (a checkpoint keeps its first run's digest,
## a guess, rather than its last) must raise a false alarm on every clean run where a re-run changed a checkpoint's state.
##   godot --headless --path . --script res://net/tools/desync_check.gd -- [--seeds=1,2] [--ticks=900] [--every=60]
##     [--profiles=lan,p80j,...|all] [--setup=default|features|planet] [--delay=2] [--out=user://desync] [--negative-control]
##     [--ai-timers]

const SETUPS: Dictionary = {
	"default": {},
	"features": {"v2": [true, true], "forms": true, "brake": true, "flight": true, "hitstop": true, "ricochet": true},
	"planet": {"planet": 7, "touch": 3},
}

## name -> the change, made to the divergent peer's state after every run of the injection tick.
var INJECT: Dictionary = {
	"rng": func(S: SimState) -> void: S.rng.a ^= 1,
	"fighter_x": func(S: SimState) -> void: S.fighters[1].x = S.fighters[1].x + absf(S.fighters[1].x) * 2.220446049250313e-16 + 5e-324,
	"building_hp": func(S: SimState) -> void: _firstAlive(S).hp -= 1.0,
	"terrain": func(S: SimState) -> void: S.deform[S.deform.size() / 3] += 0.001,
	"mood": func(S: SimState) -> void: S.mood.casGiven += 1,
	"director": func(S: SimState) -> void: S.dirS.cool += 1e-6,
}

## name -> the change to P2's AI, for --ai-timers (the timers NetDesync.digest reads).
var AI_INJECT: Dictionary = {
	"ai_t": func(S: SimState) -> void: S.fighters[1].ai.t += 1e-6,
	"ai_atk": func(S: SimState) -> void: S.fighters[1].ai.atk += 1e-6,
	"ai_sT": func(S: SimState) -> void: S.fighters[1].ai.sT += 1e-6,
	"ai_sOff": func(S: SimState) -> void: S.fighters[1].ai.sOff += 1e-6,
	"ai_st": func(S: SimState) -> void: S.fighters[1].ai.st = float((int(S.fighters[1].ai.st) + 1) % 3),
}

var failures: int = 0
var outDir: String = "user://desync"
var aiFlags: Dictionary = {"p1": false, "p2": false}


static func _firstAlive(S: SimState):
	for b in S.buildings:
		if b.alive:
			return b
	return S.buildings[0]


func _init() -> void:
	var seeds: Array = [1, 2]
	var ticks: int = 900
	var every: int = 60
	var profiles: Array = NetLoopback.PROFILES.keys()
	var setupName: String = "default"
	var delay: int = 2
	var negative: bool = false
	var aiTimers: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--every="):
			every = maxi(1, int(a.substr(8)))
		elif a.begins_with("--profiles=") and a.substr(11) != "all":
			profiles = Array(a.substr(11).split(","))
		elif a.begins_with("--setup="):
			setupName = a.substr(8)
		elif a.begins_with("--delay="):
			delay = int(a.substr(8))
		elif a.begins_with("--out="):
			outDir = a.substr(6)
		elif a == "--negative-control":
			negative = true
		elif a == "--ai-timers":
			aiTimers = true
	DirAccess.make_dir_recursive_absolute(outDir)
	var setup: Dictionary = SETUPS[setupName]
	print("Orb Combat EX desync check   Godot %s   setup %s   %d ticks   checkpoint every %d   delay %d" % [Engine.get_version_info().string, setupName, ticks, every, delay])
	if aiTimers:
		_aiTimers(seeds, ticks, every, delay, profiles, negative)
		return
	if negative:
		_negative(seeds, setup, ticks, every, delay, profiles)
		return
	var objects0: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var runs: int = 0
	var checks: int = 0
	var detected: Dictionary = {}   # injection -> runs where it was detected (not healed)
	for seed in seeds:
		var ref := _straight(seed, setup, ticks, every, delay)
		print("seed %d  straight: %d checkpoints, digest %.0f us mean, SimHash.stateHash %.0f us" % [seed, ref.digest.size(), ref.usDigest, ref.usFull])
		for pname in profiles:
			var res := _run(seed, setup, ticks, every, delay, pname, ref, "", -1, "")
			runs += 1
			checks += int(res.matched)
			print("  %s clean   %-6s  checkpoints matched %3d  rollbacks %4d  %s" % ["ok  " if res.err == "" else "FAIL", pname, res.matched, res.rollbacks, res.err])
			if res.err != "":
				failures += 1
		var x: int = ticks / 3 + 7   # not a checkpoint
		for inj in INJECT:
			for pname in profiles:
				var res := _run(seed, setup, ticks, every, delay, pname, ref, inj, x, "")
				runs += 1
				if res.err == "" and not res.healed:
					detected[inj] = int(detected.get(inj, 0)) + 1
				print("  %s %-11s %-6s  %s" % ["ok  " if res.err == "" else "FAIL", inj, pname, res.err if res.err != "" else res.note])
				if res.err != "":
					failures += 1
	for inj in INJECT:
		if int(detected.get(inj, 0)) == 0:
			print("FAIL  injection %s healed every time: it tested nothing" % inj)
			failures += 1
	var objects1: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	print("objects alive before %d, after %d" % [objects0, objects1])
	if objects1 > objects0 + 50:
		print("FAIL  runs leak objects (%d more)" % (objects1 - objects0))
		failures += 1
	if runs == 0:
		failures += 1
	print("%s  %d runs, %d checkpoints matched, %d failure(s)" % ["PASS" if failures == 0 else "FAIL", runs, checks, failures])
	quit(0 if failures == 0 else 1)


func _negative(seeds: Array, setup: Dictionary, ticks: int, every: int, delay: int, profiles: Array) -> void:
	var caught: int = 0
	var missed: int = 0
	for seed in seeds:
		var ref := _straight(seed, setup, ticks, every, delay)
		for pname in profiles:
			for inj in ["rng", "building_hp"]:
				var res := _run(seed, setup, ticks, every, delay, pname, ref, inj, ticks / 3 + 7, "blind")
				print("  %s blind %-11s %-6s  %s" % ["caught" if res.err != "" else "MISSED", inj, pname, res.err])
				if res.err != "":
					caught += 1
				else:
					missed += 1
			if pname == "lan":
				continue   # lan never predicts, so a stale checkpoint is never a guess
			var st := _run(seed, setup, ticks, every, delay, pname, ref, "", -1, "stale")
			if st.crossed == 0:
				print("  skip   stale %-6s  no re-run changed a checkpoint's state: the stale guesses were right" % pname)
				continue
			print("  %s stale %-6s  %s" % ["caught" if st.err != "" else "MISSED", pname, st.err])
			if st.err != "":
				caught += 1
			else:
				missed += 1
	print("%s  negative control: %d break(s) caught, %d missed" % ["PASS" if missed == 0 and caught > 0 else "FAIL", caught, missed])
	quit(0 if missed == 0 and caught > 0 else 1)


## --ai-timers: P2 is the sim's AI, and each of its timers changes on the tick before a checkpoint.
func _aiTimers(seeds: Array, ticks: int, every: int, delay: int, profiles: Array, negative: bool) -> void:
	aiFlags = {"p1": false, "p2": true}
	var setup: Dictionary = {"v2": [true, true]}
	var x: int = (ticks / 3 / every) * every + every - 1
	NetDesync.aiBlind = negative
	var caught: int = 0
	var missed: int = 0
	for seed in seeds:
		var ref := _straight(seed, setup, ticks, every, delay)
		for pname in profiles:
			if not negative:
				var clean := _run(seed, setup, ticks, every, delay, pname, ref, "", -1, "")
				print("  %s clean         %-6s  checkpoints matched %3d  rollbacks %4d  %s" % ["ok  " if clean.err == "" else "FAIL", pname, clean.matched, clean.rollbacks, clean.err])
				failures += 1 if clean.err != "" else 0
			for inj in AI_INJECT:
				var res := _run(seed, setup, ticks, every, delay, pname, ref, inj, x, "")
				if negative:
					caught += 1 if res.err != "" else 0
					missed += 0 if res.err != "" else 1
					print("  %s blind %-7s %-6s  %s" % ["caught" if res.err != "" else "MISSED", inj, pname, res.err])
				else:
					failures += 0 if res.err == "" and not res.healed else 1
					print("  %s %-13s %-6s  %s" % ["ok  " if res.err == "" and not res.healed else "FAIL", inj, pname, res.err if res.err != "" else res.note])
	if negative:
		print("%s  AI timers negative control: %d break(s) caught, %d missed" % ["PASS" if missed == 0 and caught > 0 else "FAIL", caught, missed])
		quit(0 if missed == 0 and caught > 0 else 1)
		return
	print("%s  AI timers: %d failure(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)


## The straight run: the bots' inputs with no network, the digest at every checkpoint. {digest: tick -> digest, usDigest,
## usFull}.
func _straight(seed: int, setup: Dictionary, ticks: int, every: int, delay: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, aiFlags, setup)
	var bots: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
	var dig: Dictionary = {}
	var full: Dictionary = {}
	var us: int = 0
	for t in range(ticks + 1):
		if t > 0 and t % every == 0:
			var t0: int = Time.get_ticks_usec()
			dig[t] = NetDesync.digest(S)
			us += Time.get_ticks_usec() - t0
			full[t] = SimHash.stateHash(S).gameplay
		if t == ticks:
			break
		var ins: Array = []
		for k in range(2):
			ins.append(SimIntent.unpack(NetSession.NEUTRAL if t < delay else bots[k].next()))
		SimCore.step(S, ins)
		S.out.feed.clear()
		S.out.fx.clear()
	var t1: int = Time.get_ticks_usec()
	SimHash.stateHash(S)
	var usFull: int = Time.get_ticks_usec() - t1
	SimCore.dispose(S)
	return {"digest": dig, "full": full, "usDigest": float(us) / maxf(1.0, float(dig.size())), "usFull": float(usFull)}


## One loopback run. inj: an INJECT name (peer 1 diverges after tick x) or "". brk: "", "blind" or "stale".
func _run(seed: int, setup: Dictionary, ticks: int, every: int, delay: int, pname: String, ref: Dictionary, inj: String, x: int, brk: String) -> Dictionary:
	var profile: Dictionary = NetLoopback.PROFILES[pname]
	var L := NetLoopback.make(seed, setup, profile, delay, seed, seed * 37 + int(profile.ping) + 3, false, aiFlags)
	var res := {"err": "", "note": "", "matched": 0, "rollbacks": 0, "crossed": 0, "healed": false}
	var info := {"seed": seed, "setup": setup, "ai": aiFlags}
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		sess.checkEvery = every
		sess.matchInfo = info
		sess.chkCompare = brk != "blind"
		sess.chkStale = brk == "stale"
		sess.onCheck = func(b: int, d: String) -> void:
			if inj == "" and brk == "" and res.err == "" and ref.digest.has(b) and d != ref.digest[b]:
				res.err = "peer %d: checkpoint %d's digest differs from the straight run's" % [k, b]
	var at: Dictionary = {}   # the divergent peer's full SimHash at the checkpoint after the injection, from its last run
	var want: int = (x / every + 1) * every
	if inj != "":
		var f: Callable = INJECT[inj] if INJECT.has(inj) else AI_INJECT[inj]
		L.peers[1].session.perturb = func(S_: SimState, t: int) -> void:
			if t == x:
				f.call(S_)
			if t == want - 1:
				at["h"] = SimHash.stateHash(S_).gameplay
	if not L.run(ticks):
		res.err = "did not confirm %d ticks" % ticks
	var s0: NetSession = L.peers[0].session
	var s1: NetSession = L.peers[1].session
	for sess in [s0, s1]:
		res.rollbacks += sess.rollbacks
		res.crossed += sess.chkStaleWrong
	res.matched = mini(s0.checksMatched, s1.checksMatched)
	if res.err == "":
		if inj == "":
			if not s0.desync.is_empty() or not s1.desync.is_empty():
				var dd: Dictionary = s0.desync if not s0.desync.is_empty() else s1.desync
				res.err = "false alarm: desync at checkpoint %d" % dd.tick
			elif brk == "" and res.matched < ticks / every - 3:
				res.err = "only %d checkpoints agreed of %d" % [res.matched, ticks / every]
		else:
			if s0.desync.is_empty() and s1.desync.is_empty() and at.get("h", "") == ref.full.get(want, "-"):
				res.note = "healed: the state equals the straight run's again by checkpoint %d (SimHash), nothing to detect" % want
				res.healed = true
				L.close()
				return res
			res.err = _judge(s0, s1, x, every, inj, seed, pname)
			if res.err == "":
				res.note = "desync at %d (agreed to %d): %s" % [s1.desync.tick, s1.desync.lastAgreed, _lastNote]
	L.close()
	return res


var _lastNote: String = ""


func _judge(s0: NetSession, s1: NetSession, x: int, every: int, inj: String, seed: int, pname: String) -> String:
	var want: int = (x / every + 1) * every
	if s0.desync.is_empty() or s1.desync.is_empty():
		return "divergence missed (peer 0 %s, peer 1 %s)" % ["saw it" if not s0.desync.is_empty() else "did not", "saw it" if not s1.desync.is_empty() else "did not"]
	var a: Dictionary = s0.desync
	var b: Dictionary = s1.desync
	if int(a.tick) != want or int(b.tick) != want:
		return "desync reported at %d and %d, expected %d" % [a.tick, b.tick, want]
	if int(a.lastAgreed) != want - every or int(b.lastAgreed) != want - every:
		return "last agreed %d and %d, expected %d" % [a.lastAgreed, b.lastAgreed, want - every]
	if a.local != b.remote or a.remote != b.local:
		return "the two reports' digests do not cross"
	var r1 := NetDesync.report(s1, s0.desync.snap)
	var r0 := NetDesync.report(s0, s1.desync.snap)
	if not r1.replayRuns or not r0.replayRuns:
		return "a report's replay does not run"
	if r1.vsPeer.is_empty() or r0.vsPeer.is_empty():
		return "the field walk found no difference between the peers"
	if r1.vsReplay.is_empty():
		return "the divergent peer's walk against its replay found nothing"
	if not r0.vsReplay.is_empty():
		return "the clean peer differs from its own replay at %s" % r0.vsReplay[0].path
	if r0.replayDigest != r0.local:
		return "the clean peer's replay digest differs from its checkpoint"
	for r in [r0, r1]:
		var path: String = "%s/seed%d-%s-%s-peer%d.json" % [outDir, seed, inj, pname, r.slot]
		if NetDesync.writeReport(r, path) != OK:
			return "could not write %s" % path
	_lastNote = "first field %s (%s vs %s), %d field(s) listed" % [r1.vsReplay[0].path, r1.vsReplay[0].b, r1.vsReplay[0].a, r1.vsReplay.size()]
	return ""
