extends SceneTree
## Do two PCs' processors play the same match? (docs/net/two-pc-check.md.) One seeded match on a generation 3 planet and its rematch, in one process, as the game's host plays them (one SimState, a
## second newMatch on it), with their check numbers written to a small text file. Run it on each PC, then compare the two files. No network: no socket, no port, no firewall.
##   godot --headless --path . --script res://net/tools/two_pc_check.gd -- --out=PATH [--build=NAME] [--ticks=3600] [--timeout=900]
##   godot --headless --script res://net/tools/two_pc_check.gd -- --compare=A,B        exit 0 the same, 1 they disagree, 2 not comparable (another build or data)
##   godot --headless --path . --script res://net/tools/two_pc_check.gd -- --self-test  [--ticks=900]
##   godot --headless --path . --script res://net/tools/two_pc_check.gd -- --negative-control  [--ticks=900]
## --setup=fights2 or --setup=together (with any of the above) plays two fights instead (NetLan's 2v2 setups, hits across them off or on): the first match the AI in all four slots, the rematch NetBots in
## slots 0 and 2 against the AI, and every body's x and y in the lines.
## The first match is the sim's AI against itself, the rematch a NetBot against the AI, and a scripted ask turns the line every 300 ticks, so a line that has moved reaches what's read and cached.
## Every 60 ticks a line holds the desync digest, the gameplay SimHash, a rolling digest of the ticks' feed and fx, and the fighters' x and y as raw bytes. Below the --- line the two files must be
## byte for byte the same. Above it, build, godot, proto, data and setup must match or the two aren't comparable; cpu, cores, os and the timings are for reading, and are never compared.
## --self-test (fresh processes, one at a time): two clean runs agree; a rematch after the first match equals the same match first in a fresh process, so the first match leaves nothing behind.
## --negative-control, each must be caught: one ulp of a fighter's hit points at a tick (they disagree, at the next line), a number changed in the data (not comparable), one digit changed in a
## report (they disagree), a report cut short (they disagree), a report from another build (not comparable).

const FORMAT: int = 1
const SEED_A: int = 77
const SEED_B: int = 78
const EVERY: int = 60
const ASK_EVERY: int = 300
const SETUP: Dictionary = {"v2": [true, true], "planet": 7, "touch": 3, "planetGen": 3}   # the preview's own, on the whole planet
const HEADER_MUST: Array = ["format", "build", "godot", "proto", "data", "setup"]
const SAMPLES: int = 24   # snapshot takes and restores timed at the end of a match

var _deadlineMs: int = 0
var setupName: String = ""
var setupNow: Dictionary = SETUP


func _init() -> void:
	var a: Dictionary = {}
	for s in OS.get_cmdline_user_args():
		var kv := s.trim_prefix("--").split("=", true, 1)
		a[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var ticks: int = int(a.get("ticks", 3600))
	setupName = String(a.get("setup", ""))
	setupNow = {"fights2": NetLan.SETUP2, "together": NetLan.SETUP2X}.get(setupName, SETUP)
	if setupNow.get("outside", false) and not NetLan.outsideKeyed():
		DirOutside.setForce(1)   # the together setup's blows from outside (Simulation's per-setup key does it once it's in)
	if a.has("compare"):
		var p := String(a.compare).split(",")
		var r: Dictionary = compareFiles(p[0], p[1])
		print(r.say)
		quit(r.code)
		return
	if a.has("self-test"):
		quit(_selfTest(ticks))
		return
	if a.has("negative-control"):
		quit(_negative(ticks))
		return
	if not a.has("out"):
		print("two_pc_check: --out=PATH is required")
		quit(3)
		return
	_deadlineMs = Time.get_ticks_msec() + int(a.get("timeout", 900)) * 1000
	var text: String = play(ticks, String(a.get("build", "unnamed")), String(a.get("break", "")), a.has("only-rematch"))
	if text == "":
		print("two_pc_check: over the time limit, no report written")
		quit(3)
		return
	var f := FileAccess.open(String(a.out), FileAccess.WRITE)
	if f == null:
		print("two_pc_check: can't write %s" % a.out)
		quit(3)
		return
	f.store_string(text)
	f.close()
	print("two_pc_check: wrote %s, %d lines" % [a.out, text.split("\n").size()])
	quit(0)


## The report's text, "" past the time limit. brk: "" or "ulp" (one ulp of fighter 2's hit points at tick 500 of the first match), "data" (a number in the swing's data). onlyB: no first match.
func play(ticks: int, build: String, brk: String, onlyB: bool) -> String:
	if brk == "data":
		var d: Dictionary = SimSwing.data()
		d.slowRate = float(d.slowRate) + 1.0
	var S := SimCore.createSim()
	var body := PackedStringArray()
	var us: Array = [0, 0, 0, 0]   # tick count, tick time, the worst tick, swings
	if not onlyB:
		SimCore.newMatch(S, SEED_A, {"p1": true, "p2": true, "p3": true, "p4": true} if setupNow.has("fights") else {"p1": true, "p2": true}, setupNow)
		if not _match(S, "A", ticks, null, brk, body, us):
			return ""
	SimCore.newMatch(S, SEED_B, NetLan.AI2 if setupNow.has("fights") else {"p1": false, "p2": true}, setupNow)
	if not _match(S, "B", ticks / 2, NetBot.new(SEED_B, 0), brk, body, us):
		return ""
	var head := PackedStringArray([
		"format %d" % FORMAT,
		"build %s" % build,
		"godot %s" % Engine.get_version_info().string,
		"proto %d" % NetHandshake.PROTO,
		"data %s" % SimReplay.dataHash(setupNow),
		"setup %s" % JSON.stringify(setupNow, "", true),
		"cpu %s" % OS.get_processor_name(),
		"cores %d" % OS.get_processor_count(),
		"os %s" % OS.get_name(),
		"ticks %d" % us[0],
		"swings %d" % us[3],
		"tick_ms mean %.3f worst %.1f" % [float(us[1]) / maxf(1.0, float(us[0])) / 1000.0, float(us[2]) / 1000.0],
		"snapshot_ms %s" % _snapTimes(S),
		"---",
	])
	SimCore.dispose(S)
	return "\n".join(head) + "\n" + "\n".join(body) + "\nend\n"


## One match, its lines into body. False past the time limit.
func _match(S: SimState, name: String, n: int, bot: NetBot, brk: String, body: PackedStringArray, us: Array) -> bool:
	var roll: String = ""
	var way: float = 1.0
	var bot2: NetBot = NetBot.new(SEED_B, 1)   # two fights: the second player, in slot 2
	var neutral: SimIntent = SimIntent.unpack(NetSession.NEUTRAL)
	for t in range(n):
		if _deadlineMs > 0 and Time.get_ticks_msec() > _deadlineMs:
			return false
		if t % ASK_EVERY == ASK_EVERY / 2 and SimSwing.ask(S, {"deg": 50.0 * way, "cause": "launch"}):
			way = -way
			us[3] += 1
		var t0: int = Time.get_ticks_usec()
		if bot != null and setupNow.has("fights"):
			var p: int = bot.next()
			var q: int = bot2.next()
			SimCore.step(S, [NetSession.intentOf(p, bot.word), null, NetSession.intentOf(q, bot2.word), null])
		elif bot != null:
			var p: int = bot.next()
			SimCore.step(S, [NetSession.intentOf(p, bot.word), neutral])
		else:
			SimCore.step(S)
		var dt: int = Time.get_ticks_usec() - t0
		us[0] += 1
		us[1] += dt
		us[2] = maxi(us[2], dt)
		roll = (roll + NetSession.outDigest(S)).md5_text()
		S.out.feed.clear()
		S.out.fx.clear()
		if brk == "ulp" and name == "A" and t == 500:
			S.fighters[1].hp = S.fighters[1].hp + absf(S.fighters[1].hp) * 2.220446049250313e-16
		if (t + 1) % EVERY == 0 or t + 1 == n:
			var nums := PackedFloat64Array()
			for f in (SimStage.bodies(S) if S.stage != null else S.fighters):
				nums.append(f.x)
				nums.append(f.y)
			body.append("%s %d %s %s %s %s" % [name, t + 1, NetDesync.digest(S), SimHash.stateHash(S).gameplay, roll, nums.to_byte_array().hex_encode()])
	return true


## A save and a restore of this state, the middle of SAMPLES: the old PC's rollback cost. Timed only; it changes no line, as the match is over.
func _snapTimes(S: SimState) -> String:
	var take := PackedInt64Array()
	var back := PackedInt64Array()
	for k in range(SAMPLES):
		var t0: int = Time.get_ticks_usec()
		var snap: NetSnapshot = NetSnapshot.take(S)
		var t1: int = Time.get_ticks_usec()
		NetSnapshot.restore(S, snap)
		take.append(t1 - t0)
		back.append(Time.get_ticks_usec() - t1)
	take.sort()
	back.sort()
	return "take %.2f restore %.2f" % [float(take[SAMPLES / 2]) / 1000.0, float(back[SAMPLES / 2]) / 1000.0]


## {code, say}. code 0: the same; 1: they disagree; 2: not comparable.
static func compareFiles(pa: String, pb: String) -> Dictionary:
	var a: String = FileAccess.get_file_as_string(pa)
	var b: String = FileAccess.get_file_as_string(pb)
	if a == "" or b == "":
		return {"code": 2, "say": "NOT COMPARABLE: can't read %s" % (pa if a == "" else pb)}
	return compare(a, b)


static func compare(a: String, b: String) -> Dictionary:
	var sa: Array = _split(a)
	var sb: Array = _split(b)
	for k in HEADER_MUST:
		if sa[0].get(k, "") != sb[0].get(k, ""):
			return {"code": 2, "say": "NOT COMPARABLE: %s differs (%s, %s). Run both from the same kit." % [k, sa[0].get(k, "none"), sb[0].get(k, "none")]}
	var la: PackedStringArray = sa[1]
	var lb: PackedStringArray = sb[1]
	var cpu: String = "%s and %s" % [sa[0].get("cpu", "?"), sb[0].get("cpu", "?")]
	for i in range(mini(la.size(), lb.size())):
		if la[i] != lb[i]:
			var pa: PackedStringArray = la[i].split(" ")
			var pb: PackedStringArray = lb[i].split(" ")
			var what: PackedStringArray = []
			for c in range(mini(pa.size(), pb.size())):
				if pa[c] != pb[c]:
					what.append(["match", "tick", "digest", "state hash", "feed and fx", "fighters' places"][mini(c, 5)])
			return {"code": 1, "say": "DIFFERENT: %s first disagree in match %s at tick %s, in: %s" % [cpu, pa[0], pa[1] if pa.size() > 1 else "?", ", ".join(what)]}
	if la.size() != lb.size() or la.is_empty() or la[la.size() - 1] != "end":
		return {"code": 1, "say": "DIFFERENT: a report is cut short (%d and %d lines)" % [la.size(), lb.size()]}
	return {"code": 0, "say": "THE SAME: %s agree on all %d lines" % [cpu, la.size() - 1]}


## [header as a dictionary, body lines]
static func _split(t: String) -> Array:
	var h: Dictionary = {}
	var body := PackedStringArray()
	var inBody: bool = false
	for l in t.split("\n", false):
		if inBody:
			body.append(l)
		elif l == "---":
			inBody = true
		else:
			var kv := l.split(" ", true, 1)
			h[kv[0]] = kv[1] if kv.size() > 1 else ""
	return [h, body]


func _child(ticks: int, tag: String, extra: Array = []) -> String:
	var path: String = OS.get_user_data_dir().path_join("two_pc_%d_%s.txt" % [OS.get_process_id(), tag])
	var args: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://net/tools/two_pc_check.gd", "--", "--out=" + path, "--ticks=%d" % ticks, "--build=selftest"] + extra + (["--setup=" + setupName] if setupName != "" else [])
	var out: Array = []
	var code: int = OS.execute(OS.get_executable_path(), args, out, true)
	var text: String = FileAccess.get_file_as_string(path)
	DirAccess.remove_absolute(path)
	if code != 0 or String(out[0]).contains("SCRIPT ERROR"):
		print("FAIL  child %s: exit %d" % [tag, code])
		print(String(out[0]).right(800))
		return ""
	return text


func _selfTest(ticks: int) -> int:
	var fails: int = 0
	var one: String = _child(ticks, "one")
	var two: String = _child(ticks, "two")
	var r: Dictionary = compare(one, two) if one != "" and two != "" else {"code": 3, "say": "no report"}
	print("two clean runs: " + r.say)
	fails += 0 if r.code == 0 else 1
	var fresh: String = _child(ticks, "fresh", ["--only-rematch"])
	var la: PackedStringArray = _split(one)[1] if one != "" else PackedStringArray()
	var lb: PackedStringArray = _split(fresh)[1] if fresh != "" else PackedStringArray()
	var rematch := PackedStringArray()
	for l in la:
		if l.begins_with("B "):
			rematch.append(l)
	var first: int = -1
	for i in range(mini(rematch.size(), lb.size())):
		if rematch[i] != lb[i]:
			first = i
			break
	var same: bool = first < 0 and rematch.size() > 0 and lb.size() == rematch.size() + 1
	print("a rematch against the same match first in a fresh process: %s" % ("the same" if same else "DIFFERENT at line %d: %s against %s" % [first, rematch[first].left(60) if first >= 0 else "", lb[first].left(60) if first >= 0 else ""]))
	fails += 0 if same else 1
	print("TWO_PC: %d check(s) failed" % fails)
	return 0 if fails == 0 else 1


func _negative(ticks: int) -> int:
	var fails: int = 0
	var clean: String = _child(ticks, "clean")
	if clean == "":
		print("TWO_PC: 1 check(s) failed")
		return 1
	var rows: Array = []
	var ulp: String = _child(ticks, "ulp", ["--break=ulp"])
	rows.append(["one ulp of a fighter's hit points", ulp, 1])
	var data: String = _child(ticks, "data", ["--break=data"])
	rows.append(["a number changed in the data", data, 2])
	var body: PackedStringArray = clean.split("\n")
	var at: int = body.size() - 8
	var old: String = body[at]
	var i: int = old.find(" ", old.find(" ") + 1) + 1   # the digest's first character
	var tampered: PackedStringArray = body.duplicate()
	tampered[at] = old.left(i) + ("0" if old[i] != "0" else "1") + old.substr(i + 1)
	rows.append(["one digit changed in a report", "\n".join(tampered), 1])
	rows.append(["a report cut short", "\n".join(body.slice(0, at)) + "\n", 1])
	rows.append(["a report from another build", clean.replace("build selftest", "build other"), 2])
	for r in rows:
		var res: Dictionary = compare(clean, r[1]) if r[1] != "" else {"code": -1, "say": "no report"}
		var caught: bool = res.code == r[2]
		print("  %s %-36s %s" % ["caught" if caught else "MISSED", r[0], res.say])
		fails += 0 if caught else 1
	print("TWO_PC: %d check(s) failed" % fails)
	return 0 if fails == 0 else 1
