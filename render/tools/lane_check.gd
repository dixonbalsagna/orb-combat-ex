extends SceneTree
## Lane colours and safe-area insets (headless), through the real main scene.
## The colour-blind presets (UI's `colour_vision` option; Art's data/art/colour-vision.json):
## - with the option off nothing is remapped: a fighter's aura colour is the sim's, to the bit;
## - with a preset on, everything Rendering draws in a fighter's aura colour is UI's lane colour for him: the view's
##   aura colour, and RenderLook.col() of the sim's aura string (his beams, after-images and the old HUD ask that).
##   Where UI's lane colour is not the one in Art's file the check says so in a note: Rendering follows UI's, so the
##   world and the HUD agree;
## - the fighters' body colours are not remapped (Art: they stay apart under every preset);
## - off again, it is the sim's colour again, and nothing is rebuilt for a change that is none.
## The safe-area insets (UiHud.insets):
## - CSS's insets scale from the page's pixels to the viewport's; nothing odd in, nothing out;
## - a phone's safe rectangle against its window gives the four insets;
## - a desktop run has none.
##   godot --headless --path . --script res://render/tools/lane_check.gd

var main: Node
var fails: int = 0


func _initialize() -> void:
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	print("%s %s" % ["ok   " if ok else "FAIL ", what])
	if not ok:
		fails += 1


func _run() -> void:
	await process_frame
	main.started = true
	main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
	var host: SimHost = main.host
	var S: SimState = host.S
	for k in range(3):
		main.frame(1.0 / 60.0)
	var raw: Array = [Color.html(str(S.fighters[0].aura)), Color.html(str(S.fighters[1].aura))]
	var v0: FighterView = main.fighter_views[0]
	_expect(RenderLook._lanes.is_empty() and main.fighter_views[0]._aura_col == raw[0] and main.fighter_views[1]._aura_col == raw[1] and RenderLook.col(str(S.fighters[0].aura)) == raw[0], "with the option off nothing is remapped: each fighter's aura colour is the sim's, to the bit")
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/art/colour-vision.json"))
	var ids: Array = ["protagonist", "rival"]
	for mode in ["protan", "deutan", "tritan"]:
		main.ui_hud.set_option("colour_vision", mode)
		for k in range(3):
			main.frame(1.0 / 60.0)
		var want: Array = [Color.html(str(art.presets[mode][ids[0]].aura)), Color.html(str(art.presets[mode][ids[1]].aura))]
		var lanes: Array = main.ui_hud.lane_colors()
		var ok: bool = not (lanes[0] as Color).is_equal_approx(raw[0]) or not (lanes[1] as Color).is_equal_approx(raw[1])
		for i in range(2):
			ok = ok and (main.fighter_views[i]._aura_col as Color).is_equal_approx(lanes[i]) and RenderLook.col(str(S.fighters[i].aura)).is_equal_approx(lanes[i])
			ok = ok and RenderLook.col(str(S.fighters[i].col)) == Color.html(str(S.fighters[i].col))
			if not (lanes[i] as Color).is_equal_approx(want[i]):
				print("note  %s: UI's lane colour for %s is #%s, and Art's preset says #%s (Rendering follows UI's, so the world and the HUD agree)" % [mode, str(S.fighters[i].id), (lanes[i] as Color).to_html(false), (want[i] as Color).to_html(false)])
		_expect(ok and main.fighter_views[0] != v0, "%s: each fighter's aura colour is UI's lane colour for him under the preset, the views were built again in them, and the body colours are left alone" % mode)
		v0 = main.fighter_views[0]
	var panes_ok: bool = true
	for p in main.all_panes():
		for i in range(mini(2, p.fighter_views.size())):
			panes_ok = panes_ok and (p.fighter_views[i]._aura_col as Color).is_equal_approx(RenderLook.col(str(S.fighters[i].aura)))
	_expect(panes_ok and main.fighter_views[0].flash_view.pulses_fn.is_valid(), "every pane's views have the preset's colour, and the rebuilt views keep their hooks (a head flash still asks the register)")
	main.ui_hud.set_option("colour_vision", "off")
	for k in range(3):
		main.frame(1.0 / 60.0)
	var v_off: FighterView = main.fighter_views[0]
	_expect(RenderLook._lanes.is_empty() and v_off._aura_col == raw[0] and main.fighter_views[1]._aura_col == raw[1], "off again: the sim's colours, to the bit")
	main.start_match(7, {"p1": true, "p2": true}, {"intro": "skip"})
	var v_new: FighterView = main.fighter_views[0]
	for k in range(3):
		main.frame(1.0 / 60.0)
	_expect(main.fighter_views[0] == v_new and RenderLook._lanes.is_empty(), "a new match with the option off builds its views once: nothing is rebuilt for a change that is none")
	# The safe-area insets.
	var css: Vector4 = main.insets_css("0,47,0,34,390", 1170.0)
	_expect(css == Vector4(0.0, 141.0, 0.0, 102.0) and main.insets_css("", 1170.0) == Vector4.ZERO and main.insets_css("1,2,3,4,0", 1170.0) == Vector4.ZERO and main.insets_css("-5,0,0,0,400", 800.0) == Vector4.ZERO, "CSS's insets scale from the page's pixels to the viewport's (a phone upright: top %.0f, bottom %.0f), and a bad answer gives none" % [css.y, css.w])
	var land: Vector4 = main.insets_rect(Rect2(132.0, 0.0, 2268.0, 1107.0), Rect2(0.0, 0.0, 2532.0, 1170.0), 2532.0)
	_expect(land == Vector4(132.0, 0.0, 132.0, 63.0) and main.insets_rect(Rect2(0.0, 0.0, 1920.0, 1080.0), Rect2(0.0, 0.0, 1920.0, 1080.0), 1280.0) == Vector4.ZERO, "a phone's safe rectangle against its window gives the four insets (on its side: %s), and a full safe area gives none" % str(land))
	_expect(main.ui_hud.insets == Vector4.ZERO, "a desktop run hands UI no insets")
	print("lane check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)
