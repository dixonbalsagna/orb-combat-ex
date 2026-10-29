extends SceneTree
## A replay played in a fresh process (Simulation, 2026-10-29). A replay's header (SimReplay.dataHash(setup)) must be the
## same in the process that records it and in a fresh one that plays it, whatever the recording process ran before. The
## computer's level is in it from the setup (DirAI.levelOf): the director's data hash is made once a process, and while
## the level was read through it, a header held the level of the process's first match (determinism.md section 10).
##
##   godot --headless --path . --script res://sim/core/tools/replay_xproc_check.gd -- [--ticks=600] [--negative-control]
##
## Two recording processes, each a fresh Godot that this one runs, record AI-versus-AI matches on one seed:
##   r1  Hard as its first match, then Easy, then a setup with no level (it runs at the level before it, Easy);
##   r2  Easy as its first match, then Hard, then Medium.
## Each replay is then played in a fresh process of its own. It passes only if:
##   - every replay with a level plays; the one with none plays or is refused as other data, never at a checkpoint;
##   - Hard's header and final are the same from both processes, and so are Easy's;
##   - Hard's, Easy's and Medium's headers all differ, and so do their finals (the level reaches the match);
##   - Medium's header is a fresh process's hash for a setup with no level, so no earlier replay's hash moves.
## --negative-control runs it with each of four breaks, and each must fail it (it stops at the first failure): the header
## leaves the level out; the header takes the level of the process's first match (the fault before 2026-10-29); the
## playback drops the level; the match runs at the data's own level under its setup's header.
## The children: --record=<name> --levels=<l,l,l> and --play=<name>, with --dir, --ticks and --break, each writing
## <name>.out.json into a folder of user:// named for this process, which is deleted at the end.

const SEED: int = 21
const RECORDS: Array = [["r1", "hard,easy,none"], ["r2", "easy,hard,medium"]]
const BREAKS: Array = ["nolevel", "firstmatch", "dropplay", "runmedium"]
const WHAT: Dictionary = {
	"nolevel": "the header leaves the level out",
	"firstmatch": "the header takes the level of the process's first match",
	"dropplay": "the playback drops the level",
	"runmedium": "the match runs at the data's own level under its setup's header",
}

var dir: String = ""
var ticks: int = 600
var brk: String = ""
var broken: Array = []   # a child that exited badly, printed a script error or wrote nothing: the run fails, negative control or not


func _initialize() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		var kv := s.trim_prefix("--").split("=", true, 1)
		a[kv[0]] = kv[1] if kv.size() > 1 else ""
	ticks = int(a.get("ticks", "600"))
	brk = String(a.get("break", ""))
	if a.has("record"):
		dir = String(a.dir)
		quit(_record(String(a.record), String(a.levels).split(",")))
		return
	if a.has("play"):
		dir = String(a.dir)
		quit(_play(String(a.play)))
		return
	dir = "user://replay_xproc_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	var t0: int = Time.get_ticks_msec()
	var code: int = 0
	if a.has("negative-control"):
		var caught: int = 0
		for b in BREAKS:
			brk = b
			var fails: Array = _run(true)
			if not fails.is_empty():
				caught += 1
			print("-- break %s (%s): %s" % [b, WHAT[b], ("caught: " + String(fails[0])) if not fails.is_empty() else "MISSED"])
		if caught == BREAKS.size() and broken.is_empty():
			print("PASS negative control: %d of %d breaks caught (%.1f s)" % [caught, BREAKS.size(), (Time.get_ticks_msec() - t0) / 1000.0])
		else:
			code = 1
			print("FAIL negative control: %d of %d breaks caught%s" % [caught, BREAKS.size(), "" if broken.is_empty() else "; " + "; ".join(broken)])
	else:
		var fails: Array = _run(false)
		fails.append_array(broken)
		for f in fails:
			print("FAIL: " + String(f))
		if fails.is_empty():
			print("PASS  6 replays from 2 recording processes, each played in a fresh process: Hard %s, Easy %s, Medium %s (%d ticks, %.1f s)" % [_hd.get("hard", ""), _hd.get("easy", ""), _hd.get("medium", ""), ticks, (Time.get_ticks_msec() - t0) / 1000.0])
		else:
			code = 1
			print("FAIL %d failure(s)" % fails.size())
	_clean()
	quit(code)


var _hd: Dictionary = {}   # the headers by level, for the PASS line


## The whole check with the current break. stopEarly: return at the first failure (the negative control).
func _run(stopEarly: bool) -> Array:
	var fails: Array = []
	var by: Dictionary = {}
	for r in RECORDS:
		if not _child(["--record=" + String(r[0]), "--levels=" + String(r[1])]):
			return ["recording process %s broke" % r[0]]
		var o = _load(String(r[0]) + ".out.json")
		for k in range((o.replays as Array).size()):
			by["%s_%d" % [r[0], k]] = o.replays[k]
	var H1: Dictionary = by.r1_0
	var E1: Dictionary = by.r1_1
	var N1: Dictionary = by.r1_2
	var E2: Dictionary = by.r2_0
	var H2: Dictionary = by.r2_1
	var M2: Dictionary = by.r2_2
	_hd = {"hard": H1.data, "easy": E2.data, "medium": M2.data}
	# what the recordings alone show
	if H1.data != H2.data:
		fails.append("Hard's header depends on what the process ran first: %s as its first match, %s after Easy" % [H1.data, H2.data])
	if E1.data != E2.data:
		fails.append("Easy's header depends on what the process ran first: %s after Hard, %s as its first match" % [E1.data, E2.data])
	if H1.final != H2.final or E1.final != E2.final:
		fails.append("a level on the same seed ended differently in the two processes: Hard %s and %s, Easy %s and %s" % [H1.final, H2.final, E1.final, E2.final])
	if H1.data == E2.data or H1.data == M2.data or E2.data == M2.data:
		fails.append("the levels' headers are not all different: Hard %s, Easy %s, Medium %s" % [H1.data, E2.data, M2.data])
	if H1.final == E2.final or H1.final == M2.final or E2.final == M2.final:
		fails.append("the levels' matches are not all different (the level does not reach the match): finals Hard %s, Easy %s, Medium %s" % [H1.final, E2.final, M2.final])
	if stopEarly and not fails.is_empty():
		return fails
	# each replay in a fresh process
	for name in ["r1_0", "r1_1", "r2_0", "r2_1", "r2_2", "r1_2"]:
		var x: Dictionary = by[name]
		if not _child(["--play=" + name]):
			fails.append("the process playing %s broke" % name)
			return fails
		var p = _load(name + ".out.json")
		x.play = p
		if not bool(p.ok) and not (x.level == "none" and p.reason == "data"):
			fails.append("%s (%s, recorded in %s) %s in a fresh process: header %s, the process's %s" % [name, x.level, name.substr(0, 2),
				"was refused as other data" if p.reason == "data" else "failed at tick %d (%s)" % [int(p.firstBadTick), p.reason], x.data, p.here])
			if stopEarly:
				return fails
	if M2.has("play") and M2.data != M2.play.fresh:
		fails.append("Medium's header %s is not a fresh process's hash for a setup with no level, %s" % [M2.data, M2.play.fresh])
	return fails


## One child Godot, waited for. Its script errors are printed here, so tools/gate.mjs counts them.
func _child(args: Array) -> bool:
	var out: Array = []
	var full: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://sim/core/tools/replay_xproc_check.gd", "--"]
	full.append_array(args)
	full.append_array(["--dir=" + dir, "--ticks=%d" % ticks])
	if brk != "":
		full.append("--break=" + brk)
	var code: int = OS.execute(OS.get_executable_path(), full, out, true)
	var bad: bool = false
	for chunk in out:
		for line in String(chunk).split("\n"):
			var l: String = line.strip_edges()
			if l.begins_with("SCRIPT ERROR") or l.begins_with("Parse Error") or l.begins_with("ERROR: Failed to load script"):
				print(l)
				bad = true
	var name: String = String(args[0]).split("=")[1]
	if code != 0 or bad or not FileAccess.file_exists(dir.path_join(name + ".out.json")):
		broken.append("child %s: exit %d%s" % [args[0], code, ", script errors" if bad else ""])
		return false
	return true


## A recording process: one match a level, in order, on one seed, each saved as <name>_<k>.json.
func _record(name: String, levels: PackedStringArray) -> int:
	var replays: Array = []
	for k in range(levels.size()):
		var lv: String = levels[k]
		var su: Dictionary = {} if lv == "none" else {"aiLevel": lv}
		var R := SimCore.createSim()
		var rec := SimReplay.recorder(R, SEED, {"p1": true, "p2": true}, su)
		if brk == "runmedium":
			DirAI.level = ""   # the break: the match runs at the data's own level, its header the setup's
		for t in range(ticks):
			rec.step([null, null])
			R.out.fx.clear()
			R.out.feed.clear()
		var rp: Dictionary = rec.finish()
		SimCore.dispose(R)
		if brk == "nolevel":   # the break: the header leaves the level out (with the level cleared, or the keyless setup's hash reads the one just set)
			var keep: String = DirAI.level
			DirAI.level = ""
			rp.data = SimReplay.dataHash(_noLevel(su))
			DirAI.level = keep
		elif brk == "firstmatch":
			rp.data = SimReplay.dataHash({} if levels[0] == "none" else {"aiLevel": levels[0]})   # the break: the first match's level
		_save("%s_%d.json" % [name, k], rp)
		replays.append({"level": lv, "data": rp.data, "final": rp.final})
	_save(name + ".out.json", {"replays": replays})
	return 0


## A playing process: a fresh Godot that plays one replay.
func _play(name: String) -> int:
	var rp = _load(name + ".json")
	var fresh: String = SimReplay.dataHash({})   # this fresh process's hash for a setup with no level
	if brk == "dropplay":
		(rp.setup as Dictionary).erase("aiLevel")   # the break: the playback drops the level
	elif brk == "nolevel" and rp.data == SimReplay.dataHash(_noLevel(rp.setup)):
		rp.data = SimReplay.dataHash(rp.setup)   # the break's other half: the header check as it is when the level is not in it
	var here: String = SimReplay.dataHash(rp.setup)
	var out: Dictionary = SimReplay.play(rp)
	_save(name + ".out.json", {"ok": out.ok, "reason": out.reason, "firstBadTick": out.firstBadTick, "final": out.final, "fresh": fresh, "here": here})
	return 0


func _noLevel(su: Dictionary) -> Dictionary:
	var c: Dictionary = su.duplicate(true)
	c.erase("aiLevel")
	return c


func _save(file: String, d: Dictionary) -> void:
	var f := FileAccess.open(dir.path_join(file), FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()


func _load(file: String):
	return JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(file)))


## This process's folder: every file in it, then the folder.
func _clean() -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)
	DirAccess.remove_absolute(dir)
