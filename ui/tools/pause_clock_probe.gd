extends SceneTree
## A-UI-01 probe: the real scene (render/main.tscn), the Rail on, pause opened the way the game does (the sim held, the HUD advanced by 0), and the rail's slide read frame by frame.
##   godot --headless --path <tree> --script res://ui/tools/pause_clock_probe.gd -- [--reduced]
const DT: float = 1.0 / 60.0
var main: Node


func _initialize() -> void:
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
	UiData.set_feature("menus_rail", true)
	var reduced: bool = OS.get_cmdline_user_args().has("--reduced")
	main.start_match(12345, {"p1": false, "p2": true}, null)
	for i in range(240):
		main.frame(DT)
	var hud: UiHud = main.ui_hud
	hud.set_option("reduced_motion", reduced)
	hud.show_pause_menu()
	print("paused=%s rail=%s" % [str(main.host.paused), str(hud.pause_menu_plan().has("rail"))])
	var first: float = -1.0
	for i in range(60):
		main.frame(DT)
		await process_frame
		var s: float = float(hud.pause_menu_plan().get("slide", -1.0))
		if i in [0, 5, 10, 20, 40, 59]:
			print("frame %d: slide %.3f paused=%s" % [i, s, str(main.host.paused)])
		if first < 0.0 and s >= 1.0:
			first = float(i)
	print("PROBE reduced=%s slid_in_at_frame=%s" % [str(reduced), str(first)])
	quit(0)
