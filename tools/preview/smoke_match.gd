extends SceneTree
## A smoke match for the stack tool (tools/preview/stack.mjs): the real scene (render/main.tscn, the way tools/flash/flash_worst.gd builds it), an AI match on a generated planet, a number of ticks,
## headless, one process. It prints one line, `SMOKE ok ticks=N ...`, and exits 0 when the match reached the ticks; a script error anywhere prints Godot's own `SCRIPT ERROR` line, which the tool reads.
##   godot --headless --path <tree> --script res://tools/preview/smoke_match.gd -- [--ticks=900] [--seed=12345] [--planet=7] [--no-planet]
## Nothing here writes into the tree or the sim: it only calls main.start_match and main.frame, as the game does.

const DT: float = 1.0 / 60.0

var main: Node
var ticks_wanted: int = 900
var seed_value: int = 12345
var planet: int = 7
var use_planet: bool = true
var planet_gen: int = 0     # 0: the setup names none (the data's own); 3: a field world, a whole ring (no arena key), as the stack asks for World's gen 3


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks_wanted = int(a.substr(8))
		elif a.begins_with("--seed="):
			seed_value = int(a.substr(7))
		elif a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--planet-gen="):
			planet_gen = int(a.substr(13))
		elif a == "--no-planet":
			use_planet = false
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	vpn.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var sv := SplitView.new()
	main.split_view = sv
	main.add_child(sv)
	main._sync_split_options()
	sv.attach(main)
	if use_planet:
		main._planet_next = {"planet": planet, "touch": 3}   # the planet part of the next match's setup, as the menu leaves it
		if planet_gen > 0:
			main._planet_next["planetGen"] = planet_gen
	main.start_match(seed_value, {"p1": true, "p2": true}, null)
	var host: SimHost = main.host
	var frames: int = 0
	var limit: int = ticks_wanted * 6 + 4000   # the planet's load is stepped by frame(): it takes frames before the first tick
	while host.ticks < ticks_wanted and frames < limit:
		main.frame(DT)
		frames += 1
	var S: SimState = host.S
	var hp: Array = []
	for f in S.fighters:
		hp.append(snappedf(f.hp, 0.1))
	var ok: bool = host.ticks >= ticks_wanted
	# what the match actually was: the planet generation the world read back, and whether the state holds a field world's frame (a gen 3 whole ring; S.get is null where a tree has no such field)
	var fine: int = S.fineCols.size() if "fineCols" in S else -1
	print("SMOKE %s ticks=%d wanted=%d frames=%d planet=%s gen=%d genNow=%d frame=%s fine=%d hp=%s" % ["ok" if ok else "SHORT", host.ticks, ticks_wanted, frames, str(use_planet), planet_gen, WorldClimate.genNow(), str(S.get("frame") != null), fine, str(hp)])
	quit(0 if ok else 1)
