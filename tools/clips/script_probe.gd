extends SceneTree
## Plays one scripted clip scene headless and says what happened (Tools, 2026-11-28; docs/tools/clips.md, "Trial clips"), so a scene's outcome
## is checked before a browser is started. The same driver and the same real scene as the capture. Run through tools/godot-run.sh, on the tree
## the clip is built from (tools/clips/trial-web.mjs keeps it):
##   bash tools/godot-run.sh --path <tree> --script res://tools/clips/script_probe.gd -- --scene=<script.json> [--names=beam_touch,damage]
## Prints one line an event ("ev <tick> <name> <text> a<actor> ...<amount>"), one a change of health or state ("hp ..."), then "PROBE done".

const DT: float = 1.0 / 60.0
const Driver = preload("res://tools/clips/script_driver.gd")

var main: Node
var drv = Driver.new()
var names: Array = []
var _last: String = ""


func _initialize() -> void:
	var file: String = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			file = a.substr(8)
		elif a.begins_with("--names="):
			names = Array(a.substr(8).split(",", false))
	if file == "" or not drv.load_text(FileAccess.get_file_as_string(file)):
		printerr("script_probe: --scene=<script.json> (could not read '%s')" % file)
		quit(2)
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(960, 540)
	root.add_child(vp)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vp.add_child(main)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var ai: Array = drv.computer_slots()
	main.start_match(drv.seed_value(), {"p1": ai[0], "p2": ai[1]}, drv.setup())
	var host = main.host
	var guard: int = 0
	while (host.loading() or not main._build_queue.is_empty()) and guard < 20000:
		main.frame(DT)
		guard += 1
	for dev in range(2):   # as the capture hook does: each pad's first press claims the next free slot
		if not ai[dev]:
			host.hub.pad_button(dev, "back", true)
			host.hub.pad_button(dev, "back", false)
			host.take_players()
	host.drained.connect(func(events, _lines): drv.seen(events, host.ticks))
	var total: int = int(drv.sc.get("ticks", 300))
	var shown: int = 0
	for _i in range(total):
		drv.drive(main, host.ticks)
		host.acc = DT * 0.9999
		main.frame(DT)
		var S = host.S
		var a = S.fighters[0]
		var b = S.fighters[1]
		while shown < drv.heard.size():
			var h: Array = drv.heard[shown]
			shown += 1
			if names.is_empty() or names.has(h[1]):
				print("ev %4d %s '%s' a%d att%d vic%d %.1f" % h)
		var line: String = "p0 %.0f %s | p1 %.0f %s" % [a.hp, a.state, b.hp, b.state]
		if line != _last:
			print("hp %4d %s | gap %.0f" % [host.ticks, line, SimWrap.sdx(a.x, b.x)])
			_last = line
	print("PROBE done ticks=%d" % host.ticks)
	quit(0)
