extends SceneTree
## The match as a replay on a desktop build (A-UI-02, Tools, 2026-11-14; render/core/match_recorder.gd). Headless, through the real SimHost: a solo match and a couch match are played with scripted intents, the report
## and the save are asked for, and the file each leaves in user://reports/ is read back and replayed with SimReplay.play: it must be there, hold the match's kind, mode, build, mark and replay, and reproduce to the
## last tick (the same final hash as the live state). Negative control: a replay with one recorded intent changed must not verify. Run from the repository root:
##   godot --headless --path . --script res://render/tools/match_recorder_check.gd
## Exit 0 when every check passes. The files the host's own save writes are removed again at the end.

var fails: int = 0
var checks: int = 0
var _made: Array = []


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL  ", what)


func _initialize() -> void:
	_run.call_deferred()


## Play `ticks` ticks of a match on a host; the humans are the slots in `humans`, driven by scripted intents (the film_in channel of the host: each slot's intent for the next tick).
func _play(host: SimHost, humans: Array, ticks: int) -> void:
	for t in range(ticks):
		for k in humans:
			var i := SimIntent.new()
			i.mx = 1.0 if (t / 90) % 2 == 0 else -1.0
			i.light = (t + 7 * int(k)) % 25 == 0
			i.heavy = (t + 11 * int(k)) % 140 == 0
			host.film_in[int(k)] = i
		host.advance(1.0 / 60.0, 1280.0, 720.0)
	for k in humans:
		host.film_in[int(k)] = null


const SCRATCH: String = "user://reports_check_main"   # every save of this check goes here (MatchRecorder.test_dir): the game's own user://reports is never written to or pruned (the GW1a review, S-05)


## The game's own reports folder as a list (name, size, time of each file; and whether the folder is there at all), to compare before and after.
func _real_folder() -> Array:
	var out: Array = ["exists=%s" % str(DirAccess.dir_exists_absolute("user://reports"))]
	for n in DirAccess.get_files_at("user://reports"):
		out.append("%s %d %d" % [n, FileAccess.get_file_as_bytes("user://reports/" + n).size(), FileAccess.get_modified_time("user://reports/" + n)])
	out.sort()
	return out


func _read(name: String) -> Dictionary:
	var path: String = SCRATCH + "/" + name
	if not FileAccess.file_exists(path):
		return {}
	var j = JSON.parse_string(FileAccess.get_file_as_string(path))
	return j if j is Dictionary else {}


func _run() -> void:
	var real_before: Array = _real_folder()
	MatchRecorder.test_dir = SCRATCH
	# nothing started: nothing to save
	_ok(SimHost.new().record_file("report") == "", "a host with no match started has nothing to save and answers the empty name")

	# a solo match: person one against the computer
	var host := SimHost.new()
	host.new_match(31, {"p1": false, "p2": true}, {"intro": false})
	_play(host, [0], 420)
	var live_final: String = SimHash.stateHash(host.S).gameplay
	var name: String = host.record_file("report", "tag-a", "a note")
	_made.append(name)
	_ok(name != "" and name.begins_with("solo-") and name.ends_with("-report.json"), "the report press writes a file named solo-<commit>-main-<time>-report.json (%s)" % name)
	var doc: Dictionary = _read(name)
	_ok(doc.get("kind", "") == "orb-solo-match" and doc.get("mode", "") == "solo" and doc.get("pc", "") == "main", "it is an orb-solo-match, mode solo")
	_ok(doc.get("build", null) is Dictionary and doc.get("reason", "") == "report" and int(doc.get("tick", -1)) == 420, "it carries the build, the reason and the tick (%s)" % str(doc.get("tick", "?")))
	var marks: Array = doc.get("marks", [])
	_ok(marks.size() == 1 and str(marks[0].get("kind", "")) == "report" and str(marks[0].get("tag", "")) == "tag-a" and str(marks[0].get("note", "")) == "a note" and int(marks[0].get("tick", -1)) == 420, "one report mark, at tick 420, with its tag and note")
	var rp: Dictionary = doc.get("replay", {})
	_ok(rp.get("format", "") == SimReplay.FORMAT and int(rp.get("ticks", 0)) == 420 and (rp.get("inputs", []) as Array).size() > 3, "the replay is SimReplay's, 420 ticks, with the presses in it (%d entries)" % (rp.get("inputs", []) as Array).size())
	_ok(str(rp.get("final", "")) == live_final, "its final hash is the live state's (the file was made between ticks)")
	# A-NET-05: a stamped build's replay names its build (SimReplay.buildId, once Simulation's replay-build park has landed); a tree with no stamp, or before that landing, writes no field
	var sr_probe := SimReplay.new()
	var want_build: String = str(sr_probe.call("buildId")) if sr_probe.has_method("buildId") else ""
	_ok(str(rp.get("build", "")) == want_build and (want_build != "" or not rp.has("build")), "the replay names the build exactly when the build is stamped (stamp '%s', replay '%s')" % [want_build, str(rp.get("build", "-"))])
	# B1: with SimReplay.header present, the recorded replay's header holds exactly the keys SimReplay.header writes (one header for every writer), and without it the keys are the ones this hook wrote before
	if sr_probe.has_method("header"):
		var hk: Array = (sr_probe.call("header", int(rp.get("seed", 0)), rp.get("setup", {}), rp.get("ai", {})) as Dictionary).keys()
		var rk: Array = []
		for k in ["format", "v", "intent", "data", "seed", "setup", "ai", "ticks", "inputs", "toggles", "checkpoints", "final", "build"]:
			if rp.has(k):
				rk.append(k)
		hk.sort()
		rk.sort()
		_ok(hk == rk, "the replay's header keys are SimReplay.header's, key for key (%s | %s)" % [str(hk), str(rk)])
	var played: Dictionary = SimReplay.play(rp)
	_ok(bool(played.ok) and str(played.final) == live_final, "SimReplay.play reproduces the match to the last tick (%s)" % str(played.get("reason", "")))
	# the same match saved again later: a second file, and the report mark of the first stays in the second's marks
	_play(host, [0], 60)
	var name2: String = host.record_file("save")
	_made.append(name2)
	var doc2: Dictionary = _read(name2)
	_ok(name2 != "" and name2.ends_with("-save.json") and int(doc2.get("tick", -1)) == 480 and (doc2.get("marks", []) as Array).size() == 1, "'Save this match' later writes a second file with 480 ticks, still holding the one mark")
	_ok(bool(SimReplay.play(doc2.get("replay", {})).ok), "and that replay verifies too")

	# negative control: a replay that has lost the second half of its recorded presses does not verify (and one with a press's intent swapped for a heavy plus signature does not either)
	var bad: Dictionary = (doc2.get("replay", {}) as Dictionary).duplicate(true)
	(bad.inputs as Array).resize((bad.inputs as Array).size() / 2)
	var verdict: Dictionary = SimReplay.play(bad)
	_ok(not bool(verdict.ok) or str(verdict.final) != str((doc2.get("replay", {}) as Dictionary).get("final", "")), "a replay missing the second half of its presses does not reproduce the match")
	var swapped: Dictionary = (doc2.get("replay", {}) as Dictionary).duplicate(true)
	var big := SimIntent.new()
	big.heavy = true
	big.sig = true
	big.mx = -1.0
	var sp: Array = SimReplay.split(SimIntent.pack(big))
	for e in swapped.inputs:
		if int(e[1]) == 0 and int(e[0]) > 30:
			e[2] = sp[0]
			e[3] = sp[1]
	var verdict2: Dictionary = SimReplay.play(swapped)
	_ok(not bool(verdict2.ok) or str(verdict2.final) != str((doc2.get("replay", {}) as Dictionary).get("final", "")), "a replay whose presses are all swapped for another intent does not reproduce the match")

	# a couch match: two people
	var host2 := SimHost.new()
	host2.new_match(52, {"p1": false, "p2": false}, {"intro": false})
	_play(host2, [0, 1], 300)
	var name3: String = host2.record_file("report")
	_made.append(name3)
	var doc3: Dictionary = _read(name3)
	_ok(name3 != "" and doc3.get("mode", "") == "couch", "a two-person match is mode couch")
	_ok(bool(SimReplay.play(doc3.get("replay", {})).ok) and str((doc3.get("replay", {}) as Dictionary).get("final", "")) == SimHash.stateHash(host2.S).gameplay, "and its replay verifies to the live final hash")

	# an AI toggle (a person hands the body back, or takes it) is in the replay and the replay still verifies
	var host3 := SimHost.new()
	host3.new_match(9, {"p1": false, "p2": true}, {"intro": false})
	_play(host3, [0], 100)
	host3.toggle_ai(1)
	_play(host3, [0, 1], 100)
	var name4: String = host3.record_file("report")
	_made.append(name4)
	var doc4: Dictionary = _read(name4)
	_ok((doc4.get("replay", {}).get("toggles", []) as Array).size() == 1 and bool(SimReplay.play(doc4.get("replay", {})).ok), "an AI toggle during the match is recorded and the replay still verifies")

	# a match of two fights (SimState.stage set): the recorder records nothing and never raises (found on the GW1a stack, 2026-11-14: anim_check printed "Invalid access to property 'ticks'" at before_step, because _begin
	# disarmed it and left no header, and the line after it read one)
	var srec := MatchRecorder.new()
	var sstate := SimState.new()
	sstate.stage = {}
	srec.arm(7, {}, {})
	srec.before_step(sstate, [])
	srec.toggle(sstate, 0)
	srec.before_step(sstate, [])
	_ok(not srec.armed and srec.replay.is_empty(), "a match of two fights is not recorded: the recorder disarms itself, keeps no header and a toggle or a tick after that raises nothing")
	_ok(srec.save(sstate, "report", "", "", {}, "user://reports_check_stage") == "", "and a save of it answers the empty name")

	# the folder keeps the newest files only
	var rec := MatchRecorder.new()
	var dir: String = "user://reports_check"
	DirAccess.make_dir_recursive_absolute(dir)
	for n in range(MatchRecorder.KEEP + 5):
		var f := FileAccess.open(dir.path_join("solo-aaaaaaaa-main-20260101-0000%02d-report.json" % n), FileAccess.WRITE)
		f.store_string("{}")
		f.close()
	MatchRecorder._prune(dir)
	var left: PackedStringArray = DirAccess.get_files_at(dir)
	_ok(left.size() == MatchRecorder.KEEP and not left.has("solo-aaaaaaaa-main-20260101-000000-report.json") and left.has("solo-aaaaaaaa-main-20260101-000024-report.json"), "the folder keeps the newest %d files and drops the oldest (%d left)" % [MatchRecorder.KEEP, left.size()])
	for n in left:
		DirAccess.remove_absolute(dir.path_join(n))
	DirAccess.remove_absolute(dir)
	rec = null

	# the player's own "Save this match" file is never pruned (the EP's ruling on S-05 (b), 2026-11-21): it survives 25 automatic reports that are all NEWER than it, and the automatic ones are cut to the newest KEEP
	var keep_host := SimHost.new()
	keep_host.new_match(77, {"p1": false, "p2": true}, {"intro": false})
	_play(keep_host, [0], 30)
	var kept: String = keep_host.record_file("save")
	_ok(kept != "" and kept.ends_with("-save.json") and FileAccess.file_exists(SCRATCH + "/" + kept), "a saved match is written to the check's own folder (%s)" % kept)
	for n in range(25):
		var rf := FileAccess.open(SCRATCH + "/" + "solo-bbbbbbbb-main-29990101-0000%02d-report.json" % n, FileAccess.WRITE)
		rf.store_string("{}")
		rf.close()
	MatchRecorder._prune(SCRATCH)
	var after: PackedStringArray = DirAccess.get_files_at(SCRATCH)
	var autos: int = 0
	for n in after:
		if n.begins_with("solo-bbbbbbbb") and n.ends_with("-report.json"):
			autos += 1
	_ok(after.has(kept), "the player's saved match survives 25 automatic reports, all newer than it")
	_ok(autos == MatchRecorder.KEEP, "and the automatic reports are cut to the newest %d (%d left)" % [MatchRecorder.KEEP, autos])

	for n in DirAccess.get_files_at(SCRATCH):
		DirAccess.remove_absolute(SCRATCH + "/" + n)
	DirAccess.remove_absolute(SCRATCH)
	MatchRecorder.test_dir = ""
	_ok(_real_folder() == real_before, "the game's own reports folder is exactly as it was (the same files, sizes and times, or no folder at all): the check wrote nothing into it and pruned nothing from it")
	_ok(not DirAccess.dir_exists_absolute(SCRATCH), "and the check's own folder is gone again")
	print("match_recorder_check: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)
