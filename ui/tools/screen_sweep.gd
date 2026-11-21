extends SceneTree
## The text half of the screen sweep (A-UI-09; docs/ui/screen-sweep.md): every menu and HUD state at one screen size (1280 by 800, the Steam Deck's, unless --size=WxH), drawn headless with every line's size and rectangle
## kept (UiText.boxing), and for each state the smallest text on it (its size, the line, where it is drawn from), how many lines went off the screen, and how many lines there were. It prints one line a state,
## `SWEEP {json}`, and one `SWEEP_DONE`; ui/tools/sweep.mjs reads them and takes the stills (through tools/machine/capture.mjs, the launcher). Nothing here writes into the tree or the sim.
##   godot --headless --path <tree> --script res://ui/tools/screen_sweep.gd -- [--size=1280x800]
## The floor is 9 px (a state with a line under it fails) and the aim 12 px (proposed in the A1 brief; the thresholds are the runner's).

var size_px: Vector2i = Vector2i(1280, 800)


class Probe extends Control:
	var fn: Callable

	func _draw() -> void:
		fn.call(self)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--size="):
			var wh: PackedStringArray = a.substr(7).split("x")
			if wh.size() == 2:
				size_px = Vector2i(int(wh[0]), int(wh[1]))
	_run.call_deferred()


## Report one state from the lines drawn while `UiText.boxing` was on.
func _report(id: String, seen: Array, query: String) -> void:
	var view := Rect2(Vector2.ZERO, Vector2(size_px))
	var min_fs: int = 9999
	var min_text: String = ""
	var min_at: String = ""
	var outside: int = 0
	var first_out: String = ""
	for b in seen:
		var fs: int = int(b["fs"])
		if fs < min_fs:
			min_fs = fs
			min_text = str(b["text"]).left(40)
			min_at = str(b["at"])
		if not view.grow(1.0).encloses(b["rect"]):
			outside += 1
			if first_out == "":
				first_out = "'%s' %s" % [str(b["text"]).left(30), str(b["rect"])]
	print("SWEEP " + JSON.stringify({"id": id, "query": query, "lines": seen.size(), "min_px": (min_fs if min_fs != 9999 else 0), "min_text": min_text, "min_at": min_at, "outside": outside, "outside_first": first_out, "size": "%dx%d" % [size_px.x, size_px.y]}))


## Draw `fn(canvas)` (a widget's own draw) once and report it.
func _drawn(id: String, query: String, fn: Callable) -> void:
	var pr := Probe.new()
	pr.size = Vector2(size_px)
	pr.fn = fn
	root.add_child(pr)
	UiText.boxes = []
	UiText.boxing = true
	pr.queue_redraw()
	await process_frame
	UiText.boxing = false
	var seen: Array = UiText.boxes.duplicate()
	UiText.boxes = []
	pr.queue_free()
	_report(id, seen, query)


func _run() -> void:
	root.size = size_px
	UiData.set_feature("menus_rail", true)
	UiData.set_feature("menu_modes", true)
	var vp := Vector2(size_px)
	var lay := UiLayout.new()
	lay.dp = 1.0
	lay.compute(vp, false)
	var fo: Array = UiSettings.focusable(UiSettings.rows())
	# The start menu's pages.
	var pick: Array = UiModes.fighters()
	var cfg1 := {"players": 1, "p1": "kb", "p2": "kb", "ai_level": "medium", "intros": true, "reduce_flashing": true, "shake": true, "captions": true, "guide": true, "p1_fighter": str(pick[0]), "p2_fighter": str(pick[1])}
	var cfg2: Dictionary = cfg1.duplicate()
	cfg2["players"] = 2
	var base := {"focus": 0, "not_now": false, "device": "kbd", "style": "neutral", "since": 1.0, "prev": -1, "bar_since": 1.0, "reduced": false, "safe": Rect2(), "version": "Version 0000000"}
	for spec in [["menu-modes", "modes", cfg1, false, "rail&modes&quitrow&menu"], ["menu-modes-midmatch", "modes", cfg1, true, "rail&modes&quitrow&menu&mmid"], ["menu-setup-solo", "setup", cfg1, false, "rail&modes&quitrow&menu&mpick=solo"],
			["menu-setup-two", "setup", cfg2, false, "rail&modes&quitrow&menu&mpick=versus"], ["menu-quit", "quit", cfg1, false, "rail&modes&quitrow&menu&mquit"]]:
		var st: Dictionary = base.duplicate()
		st["cfg"] = spec[2]
		st["page"] = spec[1]
		st["mid_match"] = spec[3]
		var mp: Dictionary = UiMenu.plan(vp, lay.s, 1.0, false, st)
		await _drawn(str(spec[0]), str(spec[4]), func(ci): UiMenu.draw(ci, mp))
	var st_old: Dictionary = base.duplicate()
	st_old["cfg"] = cfg1
	UiData.set_feature("menu_modes", false)
	var mold: Dictionary = UiMenu.plan(vp, lay.s, 1.0, false, st_old)
	await _drawn("menu-single-card", "menu", func(ci): UiMenu.draw(ci, mold))
	UiData.set_feature("menu_modes", true)
	# The pause menu, the new-match question, Quit's question, the match-over card.
	var pbase := {"focus": 0, "device": "kbd", "style": "neutral", "since": 1.0, "prev": -1, "bar_since": 1.0, "reduced": false, "win": ""}
	for spec in [["pause", {}, "rail&modes&quitrow&at=20&pause"], ["pause-lan", {"facts": ["Buildings lost: 3", "Craters: 2"], "where": "Saved reports go in the 'saved' folder beside the game.", "join": true}, "rail&modes&quitrow&at=20&pause&lan"],
			["pause-new-match-question", {"confirm": true}, "rail&at=20&pause&pconfirm"], ["pause-quit-question", {"quit_ask": true}, "rail&modes&quitrow&at=20&pause&pquit"],
			["match-over", {"over": true, "win": "Grist wins", "facts": ["Grist wins", "Buildings lost: 3", "Craters: 2"]}, "rail&modes&quitrow&ko&over&lan"],
			["match-over-saved", {"over": true, "win": "Grist wins", "facts": ["Grist wins", "Buildings lost: 3", "Craters: 2"], "status": "Match saved: saved/orb-combat-match-1234567890.json", "where": "Saved reports go in the 'saved' folder beside the game."}, "rail&modes&quitrow&ko&over&lan&saved"]]:
		var ps: Dictionary = pbase.duplicate()
		ps.merge(spec[1], true)
		var pp: Dictionary = UiPause.plan(vp, lay.s, 1.0, false, ps)
		await _drawn(str(spec[0]), str(spec[2]), func(ci): UiPause.draw(ci, pp))
	# Settings: the Rail's tabs, and the old card.
	var sst := {"focus": int(fo[0]), "scroll": 0.0, "device": "kbd", "help_scroll": 0, "style": "neutral", "since": 1.0, "reduced": false}
	var sp: Dictionary = UiSettings.plan(vp, lay.s, 1.0, false, sst, {})
	await _drawn("settings", "rail&settings=1", func(ci): UiSettings.draw(ci, sp, {}))
	UiData.set_feature("menus_rail", false)
	var sp_old: Dictionary = UiSettings.plan(vp, lay.s, 1.0, false, sst, {})
	await _drawn("settings-old-card", "settings=1", func(ci): UiSettings.draw(ci, sp_old, {}))
	UiData.set_feature("menus_rail", true)
	# The match HUD, a mock scenario each.
	for scn in UiMockFeed.SCENARIOS:
		await _hud_state("hud-" + str(scn).replace("_", "-"), str(scn), "scenario=" + str(scn))
	# The screens that open over the HUD: how to play, the feedback panel, the control remap and the first-run notice.
	await _hud_overlay("howto", "howto=0", func(h): h.show_howto(false, 0))
	await _hud_overlay("howto-about", "howto=1", func(h): h.show_howto(false, UiHowto.page_index("about")))
	await _hud_overlay("feedback", "feedback=1", func(h): h.show_feedback("pause"))
	await _hud_overlay("remap", "remap=1", func(h):
		UiData.set_feature("remap", true)
		h.show_remap(""))
	await _hud_overlay("first-run-notice", "notice=1", func(h): h.show_photo_notice(false))
	print("SWEEP_DONE")
	quit(0)


## A screen that opens over the HUD (`open` is called with the HUD), drawn for a second with the lines of its last frame kept.
func _hud_overlay(id: String, query: String, open: Callable) -> void:
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var hud: UiHud = load("res://ui/hud/ui_hud.tscn").instantiate()
	host.add_child(hud)
	var f: Array = UiMockFeed.fighters("hero_vs_proud")
	hud.setup(f[0], f[1])
	hud.set_option("force_redraw", true)
	open.call(hud)
	for i in range(60):
		hud.advance(1.0 / 60.0)
	UiText.boxes = []
	UiText.boxing = true
	await process_frame
	UiText.boxing = false
	var seen: Array = UiText.boxes.duplicate()
	UiText.boxes = []
	host.queue_free()
	await process_frame
	_report(id, seen, query)


## The match HUD in a mock scenario for three seconds, every layer drawn every frame, the lines of the last frame kept.
func _hud_state(id: String, scn: String, query: String) -> void:
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var hud: UiHud = load("res://ui/hud/ui_hud.tscn").instantiate()
	host.add_child(hud)
	var f: Array = UiMockFeed.fighters(scn)
	hud.setup(f[0], f[1])
	hud.set_option("show_prompts", true)
	hud.set_option("force_redraw", true)
	hud.anchor_fn = func(slot): return {"pos": Vector2(float(size_px.x) * (0.35 + 0.3 * float(slot)), float(size_px.y) * 0.55), "h": 120.0, "visible": true}
	var feed := UiMockFeed.new(scn, 3)
	var seen_all: Array = []
	for i in range(180):
		for e in feed.step(1.0 / 60.0):
			hud.consume(e)
		hud.advance(1.0 / 60.0)
		if i % 30 == 29:
			UiText.boxes = []
			UiText.boxing = true
			await process_frame
			UiText.boxing = false
			seen_all.append_array(UiText.boxes.duplicate())
			UiText.boxes = []
	host.queue_free()
	await process_frame
	_report(id, seen_all, query)
