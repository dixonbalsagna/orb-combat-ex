extends SceneTree
## The mode smoke (A-MODES-08, X-05 first reading; Tools, 2026-11-14; re-pointed at the A1 menus by UI, 2026-11-20): the real main scene, headless at 1280 by 800 (the Steam Deck's, so the A1 menus show), driven through the menus the way a
## player with only a pad drives them: REAL PAD BUTTONS (Input.parse_input_event, D-pad, A, B, Start), and the lit row is read back by name from the menu's own plan. One mode a run:
##   godot --headless --fixed-fps 60 --resolution 1280x800 --path . --script res://tools/smoke/mode_smoke.gd -- --mode=solo|two [--out=<file>] [--cap=<ticks to a result>]
## The steps, each one a line of the result: the first run's How to play card closed; the start menu opens on the LIST OF MODES (the rows come from ui/data/modes.json) and has a Quit row (a missing Quit row FAILS); a mode that is
## not built cannot be started; the mode is chosen with A and the setup opens with its number of people; a fighter is picked with the D-pad and the two never match; intros are set off; Start is pressed and a match runs with the
## picked fighters; scripted humans play it; the match-over card opens with Quit among its rows; "again" (a rematch) is chosen with the pad and a second match runs; a button press picks the pad up (a headless run has none connected) and Start on the pad opens the pause menu, which has a Quit row; Quit asks "Close the game?" with Stay lit, and B stays;
## its "menu" row goes back to the list of modes, whose Quit asks the same and B stays; B goes back to the match; then Start, Quit and "Close the game" with the pad: the game is told to close and the program must END BY ITSELF (the result is
## written first; three seconds on and still running is a FAIL, and the runner fails a run it had to stop at the time limit). A step that fails is a FAIL line and the run goes on as far as it can. The result is printed and, with --out, written as
## JSON ({mode, platform, input "pad", window, natural_result, steps:[{name, ok, detail}], pass}). Exit 0 when every step passed.
## The match is still ended by the smoke (SimDamage.ko) when the scripted humans have not finished it by the cap: hit points no longer end a match on main (wounds and finishers do), so a result card is what is under test here,
## not the finisher; the result says so (natural_result false).
## Run it with the user's data folder pointed away from the real one (tools/smoke/mode-smoke.mjs does): the game saves its menu choices as it is played.

var mode: String = "solo"
var out_path: String = ""
var cap: int = 600
var main: Node
var hud: Node
var steps: Array = []
var natural_result: bool = false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.substr(7)
		elif a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--cap="):
			cap = int(a.substr(6))
	root.size = Vector2i(1280, 800)   # a headless run takes the project's own 1152 by 648 unless told: the A1 menus need the Steam Deck's 1280 by 800 (the list of modes with Quit does not fit 648 and the single card shows instead)
	main = load("res://render/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _step(name: String, ok: bool, detail: String = "") -> void:
	steps.append({"name": name, "ok": ok, "detail": detail})
	print("%s  %s%s" % ["ok  " if ok else "FAIL", name, ("  (" + detail + ")") if detail != "" else ""])


func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame


## One real pad press (down and up) through the engine's input path, then two frames for the game to answer.
func _pad(button: int) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = button
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	var u := InputEventJoypadButton.new()
	u.device = 0
	u.button_index = button
	u.pressed = false
	Input.parse_input_event(u)
	await _frames(1)


## One real key press (the keyboard's pause key), for the one thing a pad cannot do headless: a pad's Start opens the pause menu only for a pad the host has claimed, and a headless run has none connected.
func _key(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	var u := InputEventKey.new()
	u.keycode = code
	u.physical_keycode = code
	u.pressed = false
	Input.parse_input_event(u)
	await _frames(1)


## The start menu's rows and the one that is lit, by name, from the menu's own plan.
func _menu_rows() -> Array:
	return hud.menu_plan()["rows"]


func _menu_lit() -> String:
	var p: Dictionary = hud.menu_plan()
	var rows: Array = p["rows"]
	return str(rows[clampi(int(p["focus"]), 0, rows.size() - 1)])


## D-pad Down (it wraps) until the start menu's lit row is `id`; false when the row is not there.
func _menu_to(id: String) -> bool:
	if not _menu_rows().has(id):
		return false
	for _i in range(_menu_rows().size() + 2):
		if _menu_lit() == id:
			return true
		await _pad(JOY_BUTTON_DPAD_DOWN)
	return _menu_lit() == id


## The pause card's items and the lit one.
func _pause_ids() -> Array:
	var ids: Array = []
	for it in hud.pause_menu_plan()["items"]:
		ids.append(str(it["id"]))
	return ids


func _pause_lit() -> String:
	var ids: Array = _pause_ids()
	return str(ids[clampi(hud.pause_menu_focus(), 0, ids.size() - 1)]) if not ids.is_empty() else ""


## The pause card's focus does not wrap (Down at the last row stays there), so the lit row is walked to `id` with Down and, if the row is above, with Up.
func _pause_to(id: String) -> bool:
	if not _pause_ids().has(id):
		return false
	for dir in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_UP]:
		for _i in range(_pause_ids().size() + 1):
			if _pause_lit() == id:
				return true
			await _pad(dir)
	return _pause_lit() == id


## Drives the human slots with scripted intents for one frame: each walks at the other body until it is near, then presses light and now and then heavy.
func _drive(humans: Array, t: int) -> void:
	for k in humans:
		var i := SimIntent.new()
		var me = main.host.S.fighters[int(k)]
		var foe = main.host.S.fighters[1 - int(k)]
		var dx: float = SimWrap.sdx(me.x, foe.x)
		i.mx = signf(dx) if absf(dx) > 260.0 else 0.0
		i.light = (t + 9 * int(k)) % 22 == 0
		i.heavy = (t + 13 * int(k)) % 150 == 0
		main.host.film_in[int(k)] = i


func _release(humans: Array) -> void:
	for k in humans:
		main.host.film_in[int(k)] = null


## Writes the result file now (the run may end before _finish: the game closing is the last step) and says whether every step so far passed.
func _write_result() -> bool:
	var all_ok: bool = true
	for s in steps:
		if not bool(s.ok):
			all_ok = false
	var doc := {"mode": mode, "platform": OS.get_name(), "input": "pad", "window": "%dx%d" % [root.size.x, root.size.y], "natural_result": natural_result, "pass": all_ok, "steps": steps}
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(doc, "  "))
			f.close()
	print("mode_smoke: %s on %s: %d steps, %d failed" % [mode, OS.get_name(), steps.size(), steps.filter(func(s): return not bool(s.ok)).size()])
	return all_ok


func _finish() -> void:
	quit(0 if _write_result() else 1)


## The game was told to close ("Close the game" answered yes): main.gd connected quit_requested to get_tree().quit() before this, so the process is ending. The result is written NOW (the process may not live to _finish); if the game
## does not end within the frames the run waits afterwards, a failing step is added and the run finishes as a failure.
func _on_quit_requested() -> void:
	_step("the game is told to close when 'Close the game' is answered with the pad", true, "quit_requested fired; the program must now end by itself")
	if not _write_result():
		quit(1)


func _run() -> void:
	await _frames(5)
	root.size = Vector2i(1280, 800)   # (set once the window exists: a headless window starts tiny)
	await _frames(40)
	hud = main.ui_hud
	# the game makes its first planet at boot (the round planet is the default): every press goes to the loading screen until it is done, so the smoke waits for the load to end before it presses anything
	var load_t0: int = Time.get_ticks_msec()
	while hud != null and hud.is_loading() and Time.get_ticks_msec() - load_t0 < 180000:
		await _frames(10)
	if hud != null and Time.get_ticks_msec() - load_t0 > 500:
		print("note  the boot's planet load took %d ms before the menu could be pressed" % (Time.get_ticks_msec() - load_t0))
	if hud == null:
		_step("the HUD exists", false)
		_finish()
		return
	if hud.is_howto_open():
		hud.hide_howto()
		await _frames(5)
	# a headless run has no window, and the game opens its start menu by itself only when it has one (UiHud.setup: notice_auto_allowed names the display server): the smoke opens it as the game would
	var opened_by_game: bool = hud.is_start_menu_open()
	if not opened_by_game:
		hud.show_start_menu(false)
		await _frames(3)
	var rows0: Array = _menu_rows() if hud.is_start_menu_open() else []
	var page0: String = str(hud.menu_plan().get("page", "")) if hud.is_start_menu_open() else ""
	_step("the start menu opens on the list of modes" + ("" if opened_by_game else " (opened by the smoke: a headless run has no window)"), hud.is_start_menu_open() and page0 == "modes" and rows0.has("solo") and rows0.has("versus"), "page '%s', rows: %s; the HUD's screen %s, window %s, A1 menus on: %s, features menu_modes %s menus_rail %s" % [page0, ",".join(PackedStringArray(rows0)), str(hud.layout.vp), str(root.size), str(hud._menu_modes_on()), str(UiData.feature("menu_modes")), str(UiData.feature("menus_rail"))])
	if not hud.is_start_menu_open():
		_finish()
		return
	# Quit must be there: a start menu with no Quit row fails (a pad cannot close the game otherwise)
	_step("the list of modes has a 'quit' row", rows0.has("quit"), "rows: " + ",".join(PackedStringArray(rows0)))
	# a mode that is not built cannot be started
	var coming: String = ""
	for id in rows0:
		var md: Dictionary = UiModes.mode(str(id))
		if not md.is_empty() and str(md.get("state", "")) != "ready":
			coming = str(id)
			break
	if coming != "":
		await _menu_to(coming)
		await _pad(JOY_BUTTON_A)
		_step("a mode that is not built ('%s') cannot be started: A leaves the list on screen" % coming, str(hud.menu_plan().get("page", "")) == "modes" and not (main.host.S != null and int(main.host.ticks) > 30 and not hud.is_start_menu_open()))
	# the mode, by name, with A
	var want_two: bool = mode == "two"
	var mode_id: String = UiModes.mode_for_players(2 if want_two else 1)
	var found: bool = await _menu_to(mode_id)
	_step("the mode row '%s' is reached with the D-pad" % mode_id, found, "lit: " + _menu_lit())
	if found:
		await _pad(JOY_BUTTON_A)
	var players: int = int(hud.menu_config().get("players", 1))
	_step("A opens the setup for %s" % ("two people" if want_two else "one person against the computer"), str(hud.menu_plan().get("page", "")) == "setup" and players == (2 if want_two else 1), "players %d, page %s" % [players, str(hud.menu_plan().get("page", ""))])
	# a fighter, with the D-pad
	var f1_before: String = str(hud.menu_config().get("p1_fighter", ""))
	var have_f1: bool = await _menu_to("f1")
	if have_f1:
		await _pad(JOY_BUTTON_DPAD_RIGHT)
	var p1f: String = str(hud.menu_config().get("p1_fighter", ""))
	var p2f: String = str(hud.menu_config().get("p2_fighter", ""))
	_step("a fighter is picked with the D-pad and the two players never hold the same one", have_f1 and p1f != "" and p1f != f1_before and p1f != p2f, "player 1 %s (was %s), player 2 %s" % [p1f, f1_before, p2f])
	# intros off, with A, so the match starts at once
	if await _menu_to("intros"):
		if bool(hud.menu_config().get("intros", true)):
			await _pad(JOY_BUTTON_A)
	_step("intros are off (a match that starts at once)", not bool(hud.menu_config().get("intros", true)))
	# start, with A
	var have_start: bool = await _menu_to("start")
	_step("the row 'start' is reached with the D-pad", have_start)
	if have_start:
		await _pad(JOY_BUTTON_A)
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000 and not (main.host.S != null and int(main.host.ticks) > 30 and not hud.is_start_menu_open()):
		await _frames(2)
	var started: bool = main.host.S != null and int(main.host.ticks) > 30
	_step("a match is running: the tick advances", started, "tick %d" % int(main.host.ticks))
	if not started:
		_finish()
		return
	var humans: Array = [0, 1] if want_two else [0]
	_step("the match is of the mode: the bodies' AI flags", (main.host.S.fighters[0].ai == null) and ((main.host.S.fighters[1].ai == null) == want_two), "p1 human %s, p2 human %s" % [str(main.host.S.fighters[0].ai == null), str(main.host.S.fighters[1].ai == null)])
	var ids_played: Array = [str(main.host.S.fighters[0].id), str(main.host.S.fighters[1].id)]
	_step("the match starts with the picked fighters", ids_played == [p1f, p2f], "played %s, picked %s" % [str(ids_played), str([p1f, p2f])])
	# play to a result with scripted humans; end it with the sim's own KO when the cap passes (and say so)
	var t: int = 0
	var over: bool = false
	while t < cap and not over:
		_drive(humans, t)
		await process_frame
		t += 1
		over = main.host.S.game.ko != null
		if t == cap and not over:
			SimDamage.ko(main.host.S, main.host.S.fighters[1], main.host.S.fighters[0])
			over = main.host.S.game.ko != null
		elif over:
			natural_result = true
	_release(humans)
	_step("the match plays %d ticks and has a result (%s)" % [cap, "the scripted humans finished it" if natural_result else "ended by the smoke with SimDamage.ko: a result card is what is under test, not the finisher"], over, "ticks %d" % t)
	if not over:
		_finish()
		return
	# the match-over card
	var w0: int = 0
	while w0 < 900 and not (hud.is_pause_menu_open() and hud._pm_over):
		await process_frame
		w0 += 1
	var card: bool = hud.is_pause_menu_open() and hud._pm_over
	var ids: Array = _pause_ids() if card else []
	_step("the match-over card opens with its rows, Quit among them", card and ids.has("again") and ids.has("quit"), "rows: " + ",".join(PackedStringArray(ids)))
	if not card:
		_finish()
		return
	# rematch, with the pad
	var seed_mid: int = int(main.host.seed)
	var at_again: bool = await _pause_to("again")
	if at_again:
		await _pad(JOY_BUTTON_A)
	var r0: int = 0
	while r0 < 1800 and not (main.host.S != null and int(main.host.ticks) > 20 and main.host.S.game.ko == null and not hud.is_pause_menu_open()):
		await process_frame
		r0 += 1
	_step("a rematch ('again', chosen with the pad) starts a new match that runs", at_again and main.host.S != null and main.host.S.game.ko == null and int(main.host.ticks) > 20, "tick %d, seed %d to %d" % [int(main.host.ticks), seed_mid, int(main.host.seed)])
	for k in range(120):
		_drive(humans, k)
		await process_frame
	_release(humans)
	_step("the second match plays on for 120 ticks", main.host.S != null and main.host.S.game.ko == null)
	# the pause menu, with the pad. A pad's Start pauses only for a pad the host has claimed (one that drives a slot) and a headless run has none connected, so the smoke picks the pad up the way a player does: a button press on device 0, then Start
	await _pad(JOY_BUTTON_X)
	await _pad(JOY_BUTTON_START)
	await _frames(3)
	_step("Start on the pad opens the pause menu, Quit among its rows", hud.is_pause_menu_open() and _pause_ids().has("quit"), "rows: " + ",".join(PackedStringArray(_pause_ids())))
	if not hud.is_pause_menu_open():
		_finish()
		return
	# Quit on the pause menu asks first, with Stay lit, and B stays
	var at_quit: bool = await _pause_to("quit")
	if at_quit:
		await _pad(JOY_BUTTON_A)
	_step("Quit on the pause menu asks 'Close the game?' with Stay lit", at_quit and _pause_ids() == ["quit_yes", "quit_no"] and _pause_lit() == "quit_no", "rows %s, lit %s" % [",".join(PackedStringArray(_pause_ids())), _pause_lit()])
	await _pad(JOY_BUTTON_B)
	_step("B on the question stays: the pause menu is back and the game is still running", hud.is_pause_menu_open() and _pause_ids().has("quit") and is_instance_valid(main))
	var at_menu: bool = false
	if hud.is_pause_menu_open():
		at_menu = await _pause_to("menu")
		if at_menu:
			await _pad(JOY_BUTTON_A)
		await _frames(5)
	_step("'menu' goes back to the list of modes", hud.is_start_menu_open() and str(hud.menu_plan().get("page", "")) == "modes", "reached %s, pause open %s, start menu open %s, lit %s" % [str(at_menu), str(hud.is_pause_menu_open()), str(hud.is_start_menu_open()), _pause_lit()])
	# the start menu's Quit asks first, and B stays
	if hud.is_start_menu_open() and await _menu_to("quit"):
		await _pad(JOY_BUTTON_A)
		var qp: Dictionary = hud.menu_plan()
		_step("Quit asks 'Close the game?' with Stay lit", str(qp.get("page", "")) == "quit" and _menu_lit() == "quit_no", "page %s, lit %s" % [str(qp.get("page", "")), _menu_lit()])
		await _pad(JOY_BUTTON_B)
		_step("B on the question stays: the list of modes is back and the game is still running", str(hud.menu_plan().get("page", "")) == "modes" and is_instance_valid(main))
	else:
		_step("Quit asks 'Close the game?' with Stay lit", false, "no quit row to press")
	# back to the match (B on the list of modes is "Back to the match"), then the real thing: Start, Quit, "Close the game", and the program closes
	await _pad(JOY_BUTTON_B)
	await _frames(5)
	_step("B on the list of modes goes back to the match", not hud.is_start_menu_open() and main.host.S != null and main.host.S.game.ko == null)
	await _pad(JOY_BUTTON_START)
	await _frames(3)
	var to_quit: bool = hud.is_pause_menu_open() and await _pause_to("quit")
	if to_quit:
		await _pad(JOY_BUTTON_A)
	var to_yes: bool = to_quit and await _pause_to("quit_yes")
	_step("Start, Quit and the question's 'Close the game' row are reached with the pad", to_yes, "pause open %s, reached quit %s, rows %s, lit %s" % [str(hud.is_pause_menu_open()), str(to_quit), ",".join(PackedStringArray(_pause_ids())), _pause_lit()])
	if not to_yes:
		_finish()
		return
	hud.quit_requested.connect(_on_quit_requested)
	await _pad(JOY_BUTTON_A)
	# the game closes by itself: when it does, this line is never reached. Three seconds of frames later it did not.
	await _frames(180)
	_step("the program closes within three seconds of 'Close the game'", false, "still running after 180 frames")
	_finish()
