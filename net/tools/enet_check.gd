extends SceneTree
## The ENet two-process check (docs/net/rollback.md section 11). For each network profile it starts two headless Godot
## processes (net/tools/enet_peer.gd), a host and a joiner on 127.0.0.1, which handshake over ENet and play the same
## seeded match to its end with the bots' inputs, each impairing its outgoing packets with the profile's latency,
## jitter and loss. Then it plays the straight, non-networked run at the delay they agreed, and passes (exit 0) only if:
##   - both processes finished and agreed on the delay, and it is the larger of their two proposals;
##   - at every confirmed tick, both peers' state digests and feed-and-fx digests equal each other's and the straight
##     run's; at every --hash-every-th tick and at the end, so do their gameplay SimHashes;
##   - neither peer's desync detection fired;
##   - time sync held the peers together: over the second half, the true lead (each process samples the shared system
##     clock with its session frame) averaged at most --max-lead-mean frames either way and never passed --max-lead.
## At most three Godot processes run at once: this one and the two peers.
##   godot --headless --path . --script res://net/tools/enet_check.gd -- [--seed=1] [--ticks=3600]
##     [--profiles=lan,p120,p200] [--slowdowns=1,1] [--hash-every=60] [--hitch=T:F] [--setup=default] [--port=47100] [--max-lead=12] [--max-lead-mean=3]
##     [--negative-control]
## --slowdowns gives each peer's device (NetDelay.device) for its proposal. --hitch freezes the joiner for F frames at
## tick T, so time sync has to bring the peers back together.
## --negative-control runs the same match with the joiner perturbed (one RNG bit flipped at the middle tick) and passes
## only if the check fails it: the digests part at that tick, and the peers' desync detection fires.

var failures: int = 0


func _init() -> void:
	var o := {"seed": 1, "ticks": 3600, "profiles": ["lan", "p120", "p200"], "slowdowns": ["1", "1"], "hashEvery": 60, "hitch": "",
		"setup": "default", "port": 47100, "negative": false, "maxLead": 12.0, "maxLeadMean": 3.0}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		match kv[0]:
			"seed": o.seed = int(kv[1])
			"ticks": o.ticks = int(kv[1])
			"profiles": o.profiles = Array(kv[1].split(","))
			"slowdowns": o.slowdowns = Array(kv[1].split(","))
			"hash-every": o.hashEvery = maxi(1, int(kv[1]))
			"hitch": o.hitch = kv[1]
			"setup": o.setup = kv[1]
			"port": o.port = int(kv[1])
			"max-lead": o.maxLead = float(kv[1])
			"max-lead-mean": o.maxLeadMean = float(kv[1])
			"negative-control": o.negative = true
	print("Orb Combat EX ENet two-process check   Godot %s   seed %d   %d ticks   setup %s   devices x%s   %s%s" % [Engine.get_version_info().string,
		o.seed, o.ticks, o.setup, " and x".join(o.slowdowns), "negative control" if o.negative else "hash every %d" % o.hashEvery,
		("   hitch " + o.hitch) if o.hitch != "" else ""])
	var dir: String = OS.get_user_data_dir().path_join("enet_check")
	DirAccess.make_dir_recursive_absolute(dir)
	var refs: Dictionary = {}
	var caught: int = 0
	var runs: int = 0
	for i in range(o.profiles.size()):
		var pname: String = o.profiles[i]
		runs += 1
		var outs: Array = _play(o, pname, o.port + i * 2, dir)
		if outs.is_empty():
			failures += 1
			continue
		var d: int = int(outs[0].get("delay", -1))
		if not refs.has(d):
			refs[d] = NetStraight.run(o.seed, NetStraight.SETUPS[o.setup], o.ticks, d, o.hashEvery)
		var err: String = _compare(outs, refs[d], o)
		_print(pname, outs, err)
		if o.negative:
			var want: int = o.ticks / 2 + 1   # the first state after the perturbed tick
			var ok: bool = err != "" and int(outs[0].desync) > 0 and int(outs[1].desync) > 0 and err.contains("tick %d " % want)
			print("  %s  perturbed peer on %s: %s; desync detection at %d and %d" % ["caught" if ok else "MISSED", pname, err if err != "" else "no difference found", int(outs[0].desync), int(outs[1].desync)])
			if ok:
				caught += 1
		elif err != "":
			failures += 1
	if o.negative:
		print("%s  negative control: %d of %d perturbed matches caught" % ["PASS" if caught == runs else "FAIL", caught, runs])
		quit(0 if caught == runs else 1)
		return
	print("%s  %d two-process matches over ENet, %d ticks each, %d failure(s)" % ["PASS" if failures == 0 else "FAIL", runs, o.ticks, failures])
	quit(0 if failures == 0 else 1)


## Start both peers, wait for them, read what they wrote. [] on a failure (printed).
func _play(o: Dictionary, pname: String, port: int, dir: String) -> Array:
	var exe: String = OS.get_executable_path()
	var root: String = ProjectSettings.globalize_path("res://")
	var pids: Array = []
	var files: Array = []
	for role in ["host", "join"]:
		var out: String = dir.path_join("%s-%s-%d.json" % [pname, role, port])
		if FileAccess.file_exists(out):
			DirAccess.remove_absolute(out)
		files.append(out)
		var args: Array = ["--headless", "--path", root, "--script", "res://net/tools/enet_peer.gd", "--", "--role=" + role,
			"--port=%d" % port, "--out=" + out, "--seed=%d" % o.seed, "--ticks=%d" % o.ticks, "--setup=" + o.setup,
			"--profile=" + pname, "--slowdown=" + str(o.slowdowns[0 if role == "host" else 1]), "--hash-every=%d" % o.hashEvery]
		if role == "join":
			if o.negative:
				args.append("--perturb=%d" % (o.ticks / 2))
			if o.hitch != "":
				args.append("--hitch=" + o.hitch)
		var pid: int = OS.create_process(exe, PackedStringArray(args))
		if pid <= 0:
			print("FAIL  %s: could not start the %s process" % [pname, role])
			for p in pids:
				OS.kill(p)
			return []
		pids.append(pid)
		if role == "host":
			OS.delay_msec(300)   # let it bind before the joiner dials (the joiner retries anyway while it pings)
	var deadline: int = Time.get_ticks_msec() + int(float(o.ticks) * 1000.0 / 60.0 * 4.0) + 90000
	var codes: Array = [-1, -1]
	while true:
		var running: bool = false
		for k in range(2):
			if codes[k] == -1:
				if OS.is_process_running(pids[k]):
					running = true
				else:
					codes[k] = OS.get_process_exit_code(pids[k])
		if not running:
			break
		if Time.get_ticks_msec() > deadline:
			for k in range(2):
				if codes[k] == -1:
					OS.kill(pids[k])
			print("FAIL  %s: the peers did not finish in time (killed)" % pname)
			return []
		OS.delay_msec(100)
	var outs: Array = []
	for k in range(2):
		var txt: String = FileAccess.get_file_as_string(files[k])
		var v: Variant = JSON.parse_string(txt) if txt != "" else null
		if not (v is Dictionary):
			print("FAIL  %s: the %s wrote no result (exit %d)" % [pname, ["host", "join"][k], codes[k]])
			return []
		v["exit"] = codes[k]
		outs.append(v)
	return outs


## "" when both peers match each other and the straight run, else the first difference.
func _compare(outs: Array, ref: Dictionary, o: Dictionary) -> String:
	for k in range(2):
		if str(outs[k].err) != "":
			return "%s: %s" % [outs[k].role, outs[k].err]
	var a: Dictionary = outs[0]
	var b: Dictionary = outs[1]
	if int(a.delay) != int(b.delay) or int(a.mine) != int(b.theirs) or int(b.mine) != int(a.theirs) or int(a.delay) != maxi(int(a.mine), int(b.mine)):
		return "handshake: delays %d and %d from proposals %d and %d" % [int(a.delay), int(b.delay), int(a.mine), int(b.mine)]
	for t in range(o.ticks):
		var da: String = str(a.digests[t])
		var db: String = str(b.digests[t])
		if da != db:
			return "the peers' digests part at confirmed tick %d " % (t + 1)
		if da != ref.digests[t]:
			return "both peers differ from the straight run at confirmed tick %d " % (t + 1)
	for key in ref.hashes:
		if str(a.hashes.get(key, "")) != ref.hashes[key] or str(b.hashes.get(key, "")) != ref.hashes[key]:
			return "the SimHash differs from the straight run after tick %s " % key
	if str(a.final) != ref.final or str(b.final) != ref.final:
		return "the final SimHash differs"
	for k in range(2):
		if int(outs[k].desync) >= 0:
			return "%s: desync detection fired at %d" % [outs[k].role, int(outs[k].desync)]
		if int(outs[k].exit) != 0:
			return "%s exited %d" % [outs[k].role, int(outs[k].exit)]
	var lead: Array = leadOf(a.adv, b.adv)
	if lead.size() < 10:
		return "time sync: too few lead samples (%d)" % lead.size()
	var sum: float = 0.0
	for i in range(lead.size() / 2, lead.size()):
		sum += absf(lead[i])
		if absf(lead[i]) > o.maxLead:
			return "time sync: the peers were %.1f frames apart in the second half (at most %.0f)" % [lead[i], o.maxLead]
	var mean: float = sum / float(lead.size() - lead.size() / 2)
	if mean > o.maxLeadMean:
		return "time sync: the peers were %.1f frames apart on average in the second half (at most %.1f)" % [mean, o.maxLeadMean]
	return ""


func _print(pname: String, outs: Array, err: String) -> void:
	var a: Dictionary = outs[0]
	var b: Dictionary = outs[1]
	if a.has("delay"):
		print("  %s %-6s  delay %d (proposals %d, %d)  handshake rtt %.0f/%.0f ms in %.0f/%.0f ms  play rtt %.0f/%.0f ms  rollbacks %d/%d  max depth %d/%d  waits %d/%d  stalls %d/%d  lost %d/%d of %d/%d  %.0f/%.0f B/s  frame p50 %.2f/%.2f p99 %.1f/%.1f ms  wall %.0f s  %s" % [
			"ok  " if err == "" else "FAIL", pname, int(a.delay), int(a.mine), int(b.mine), float(a.hsRttMedian), float(b.hsRttMedian), float(a.hsMs), float(b.hsMs),
			float(a.playRttMedian), float(b.playRttMedian), int(a.rollbacks), int(b.rollbacks), int(a.maxDepth), int(b.maxDepth),
			int(a.waits), int(b.waits), int(a.stalls), int(b.stalls), int(a.lost), int(b.lost), int(a.pktOut) + int(a.lost), int(b.pktOut) + int(b.lost),
			float(a.bytesOut) / float(a.wallS), float(b.bytesOut) / float(b.wallS), float(a.frameP50Ms), float(b.frameP50Ms), float(a.frameP99Ms), float(b.frameP99Ms),
			float(a.wallS), err])
		print("         time sync: decisions %d/%d; %s" % [int(a.syncDecisions), int(b.syncDecisions), _leadSummary(a.adv, b.adv)])
	else:
		print("  FAIL %-6s  %s" % [pname, err])


## The true lead, from both peers' samples of [system clock ms, session frame]: the host's frame minus the joiner's
## (interpolated) at each of the host's samples while both play. Its worst, and its worst and mean size over the
## second half.
static func leadOf(a: Array, b: Array) -> Array:
	var out: Array = []
	var j: int = 0
	for e in a:
		var t: float = float(e[0])
		while j + 1 < b.size() and float(b[j + 1][0]) < t:
			j += 1
		if j + 1 >= b.size() or float(b[j][0]) > t:
			continue
		var t0: float = float(b[j][0])
		var t1: float = float(b[j + 1][0])
		var f: float = float(b[j][1]) + (float(b[j + 1][1]) - float(b[j][1])) * ((t - t0) / maxf(1.0, t1 - t0))
		out.append(float(e[1]) - f)
	return out


func _leadSummary(a: Array, b: Array) -> String:
	var lead: Array = leadOf(a, b)
	if lead.is_empty():
		return "(no lead samples)"
	var worst: float = 0.0
	var late: float = 0.0
	var sum: float = 0.0
	var n: int = 0
	for i in range(lead.size()):
		worst = maxf(worst, absf(lead[i]))
		if i >= lead.size() / 2:
			late = maxf(late, absf(lead[i]))
			sum += absf(lead[i])
			n += 1
	return "true lead (host minus joiner, system clock): max %.1f frames; second half max %.1f, mean %.1f" % [worst, late, sum / maxf(1.0, float(n))]
