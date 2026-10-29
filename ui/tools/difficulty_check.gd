extends SceneTree
## The start menu's computer level (UI, docs/ui/start-menu.md): the choice reaches the AI's level through the match setup, Medium is the match of today's default, and a level changes the match.
##   sim   SimCore.newMatch with {"aiLevel": level} sets DirAI.level (Medium is "", the data's own level); a match at each level is the same twice (the state hash every 60 ticks);
##         Medium is byte-identical to a setup with no key; Easy and Hard differ from Medium.
##   host  the main scene's _on_menu_started puts the menu's ai_level in the setup (SimHost.setup_used), and a New match after it keeps it.
## Usage (repo root): godot --headless --path . --script res://ui/tools/difficulty_check.gd [-- --ticks=900]

var ticks: int = 900
var fails: int = 0


func _ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: " + what)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	_run.call_deferred()


func _hashes(seed: int, setup: Dictionary) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, setup)
	var out: Array = []
	for t in range(1, ticks + 1):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		if t % 60 == 0:
			out.append(SimHash.stateHash(S).gameplay)
	SimCore.dispose(S)
	return out


func _run() -> void:
	var levels: Array = UiMenu.levels()
	_ok(levels == ["easy", "medium", "hard"], "the menu's levels are the three of data/director/ai.json, in its order (got %s)" % str(levels))
	_ok(UiMenu.level_of("nope") == "medium" and UiMenu.level_of("hard") == "hard", "level_of keeps a level the data has and gives the default for anything else")
	_ok(UiMenu.level_step("medium", 1, false) == "hard" and UiMenu.level_step("hard", 1, false) == "hard" and UiMenu.level_step("hard", 1, true) == "easy" and UiMenu.level_step("easy", -1, false) == "easy", "level_step holds at the ends, or wraps on Enter")
	var seed: int = 12345
	var none: Array = _hashes(seed, {})
	var by: Dictionary = {}
	for lv in levels:
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed, {}, {"aiLevel": lv})
		var want: String = "" if lv == "medium" else lv
		_ok(DirAI.level == want, "aiLevel %s: DirAI.level is '%s' (got '%s')" % [lv, want, DirAI.level])
		_ok(DirAI.lv() == (DirAI.skill().levels as Dictionary)[lv], "aiLevel %s: the AI reads that level's numbers" % lv)
		SimCore.dispose(S)
		by[lv] = _hashes(seed, {"aiLevel": lv})
		_ok(by[lv] == _hashes(seed, {"aiLevel": lv}), "aiLevel %s: the match is the same twice" % lv)
	_ok(by["medium"] == none, "Medium is byte-identical to a setup with no level")
	_ok(by["easy"] != by["medium"] and by["hard"] != by["medium"] and by["easy"] != by["hard"], "Easy, Medium and Hard play three different matches")
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, seed, {}, {"aiLevel": "bogus"})
	_ok(DirAI.level == "", "an unknown level in the setup runs at the data's own level")
	SimCore.dispose(S2)

	# The host: the menu's Start puts the level in the setup, and a New match keeps it.
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vp.add_child(main)
	await process_frame
	main.manual = false
	for lv in levels:
		main._on_menu_started({"players": 1, "p1": "kb", "p2": "kb", "intros": false, "ai_level": lv})
		var want2: String = "" if lv == "medium" else lv
		_ok(str(main.host.setup_used.get("aiLevel", "")) == lv, "host, %s: the match's setup carries aiLevel (got '%s')" % [lv, str(main.host.setup_used.get("aiLevel", ""))])
		_ok(DirAI.level == want2, "host, %s: the sim ran the match at that level" % lv)
		main.start_match(1234)
		_ok(str(main.host.setup_used.get("aiLevel", "")) == lv, "host, %s: a New match keeps the level" % lv)
		main._on_menu_started({"players": 1, "p1": "kb", "p2": "kb", "intros": true, "ai_level": lv})
		_ok(str(main.host.setup_used.get("aiLevel", "")) == lv, "host, %s, with the intro: the setup carries aiLevel" % lv)
	print("\ndifficulty_check: %s" % ("passed" if fails == 0 else "%d failed" % fails))
	quit(0 if fails == 0 else 1)
