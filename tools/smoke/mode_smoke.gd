extends SceneTree
## The mode smoke (A-MODES-08, X-05 first reading; Tools, 2026-11-14): the real main scene, headless, driven through the menus BY ROW NAME, not by screen points: one mode a run, to a result, a rematch and the way back out.
##   godot --headless --fixed-fps 60 --path . --script res://tools/smoke/mode_smoke.gd -- --mode=solo|two [--out=<file>] [--cap=<ticks to a result>]
## The steps, each one a line of the result: the first run's How to play card closed; the start menu is open; the row "players" is found by name and set (1 person: solo, 2: two people); intros are set off so
## the match starts at once; the row "start" is chosen; a match is running (the sim's tick advances); the human slots are driven with scripted intents (the host's film_in channel) until a KO or the cap; the
## match-over card opens and its rows are read (play again, save, main menu, ...); "again" (a rematch) is chosen by name and a second match runs for 120 ticks; the pause menu is opened, "menu" (back to the start
## menu) is chosen by name and the start menu is open again; the row "quit" is looked for in the start menu's rows (a build without one says "not built"). A step that fails is a FAIL line and the run goes on as
## far as it can: a failing line is an acceptable first reading. The result is printed and, with --out, written as JSON ({mode, platform, steps:[{name, ok, detail}], pass}). Exit 0 when every step passed.
## Run it with the user's data folder pointed away from the real one (tools/smoke/mode-smoke.mjs does): the game saves its menu choices as it is played.

var mode: String = "solo"
var out_path: String = ""
var cap: int = 600
var main: Node
var hud: Node
var steps: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.substr(7)
		elif a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--cap="):
			cap = int(a.substr(6))
	main = load("res://render/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _step(name: String, ok: bool, detail: String = "") -> void:
	steps.append({"name": name, "ok": ok, "detail": detail})
	print("%s  %s%s" % ["ok  " if ok else "FAIL", name, ("  (" + detail + ")") if detail != "" else ""])


func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame


## The id of the row the start menu's focus is on.
func _focus_row() -> String:
	var rows: Array = hud._menu_rows()
	return str(rows[clampi(hud._menu_focus, 0, rows.size() - 1)])


## Moves the start menu's focus to the row named `id` with the down action, as a pad's D-pad does. False when the row is not there.
func _goto(id: String) -> bool:
	if not (hud._menu_rows() as Array).has(id):
		return false
	for _i in range(24):
		if _focus_row() == id:
			return true
		hud.menu_action("down")
		await _frames(1)
	return _focus_row() == id


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


func _finish() -> void:
	var all_ok: bool = true
	for s in steps:
		if not bool(s.ok):
			all_ok = false
	var doc := {"mode": mode, "platform": OS.get_name(), "pass": all_ok, "steps": steps}
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(doc, "  "))
			f.close()
	print("mode_smoke: %s on %s: %d steps, %d failed" % [mode, OS.get_name(), steps.size(), steps.filter(func(s): return not bool(s.ok)).size()])
	quit(0 if all_ok else 1)


func _run() -> void:
	await _frames(40)
	hud = main.ui_hud
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
	_step("the start menu is open" + ("" if opened_by_game else " (opened by the smoke: a headless run has no window)"), hud.is_start_menu_open(), "rows: " + ",".join(PackedStringArray(hud._menu_rows())))
	if not hud.is_start_menu_open():
		_finish()
		return
	# players, by name
	var want_two: bool = mode == "two"
	var found: bool = await _goto("players")
	_step("the row 'players' is found by name", found)
	if found and want_two != (int(hud.menu_config().get("players", 1)) == 2):
		hud.menu_action("accept")
		await _frames(2)
	var players: int = int(hud.menu_config().get("players", 1))
	_step("the mode is set: %s" % ("two people" if want_two else "one person against the computer"), players == (2 if want_two else 1), "players %d" % players)
	# intros off, by name, so the match starts at once
	if await _goto("intros"):
		if bool(hud.menu_config().get("intros", true)):
			hud.menu_action("accept")
			await _frames(2)
	_step("intros are off (a match that starts at once)", not bool(hud.menu_config().get("intros", true)))
	# start
	var seed_before: int = int(main.host.seed)
	var have_start: bool = await _goto("start")
	_step("the row 'start' is found by name", have_start)
	if have_start:
		hud.menu_action("accept")
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
	# play to a result. Hit points no longer end a match (wounds and finishers do), so the smoke plays `cap` ticks with the scripted humans and then ENDS the match with the sim's own SimDamage.ko (what the
	# sim's checks call): this is a smoke of the screens and the way through the modes, not of the finisher or of balance (the step says so)
	var t: int = 0
	var over: bool = false
	while t < cap and not over:
		_drive(humans, t)
		await process_frame
		t += 1
		if t == cap:
			SimDamage.ko(main.host.S, main.host.S.fighters[1], main.host.S.fighters[0])
		over = main.host.S.game.ko != null
	_release(humans)
	_step("the match plays %d ticks, then the smoke ends it with SimDamage.ko (a result card is what is under test, not the finisher)" % cap, over, "ticks %d" % t)
	if not over:
		_finish()
		return
	# the match-over card
	var w0: int = 0
	while w0 < 900 and not (hud._pm_open and hud._pm_over):
		await process_frame
		w0 += 1
	var card: bool = hud._pm_open and hud._pm_over
	var ids: Array = UiPause.ids(false, int(hud._humans()) >= 2, true) if card else []
	_step("the match-over card opens with its rows", card and ids.has("again"), "rows: " + ",".join(PackedStringArray(ids)))
	if not card:
		_finish()
		return
	# rematch, by name
	hud.pause_menu_choose("again")
	var seed_mid: int = int(main.host.seed)
	var r0: int = 0
	while r0 < 1800 and not (main.host.S != null and int(main.host.ticks) > 20 and main.host.S.game.ko == null and not hud._pm_open):
		await process_frame
		r0 += 1
	_step("a rematch ('again') starts a new match that runs", main.host.S != null and main.host.S.game.ko == null and int(main.host.ticks) > 20, "tick %d, seed %d to %d" % [int(main.host.ticks), seed_mid, int(main.host.seed)])
	for k in range(120):
		_drive(humans, k)
		await process_frame
	_release(humans)
	_step("the second match plays on for 120 ticks", main.host.S != null and main.host.S.game.ko == null)
	# back to the menu, by name
	hud.show_pause_menu()
	await _frames(3)
	_step("the pause menu opens in the match", hud._pm_open)
	if hud._pm_open:
		hud.pause_menu_choose("menu")
		await _frames(5)
	_step("'menu' goes back to the start menu", hud.is_start_menu_open())
	var rows: Array = hud._menu_rows()
	if rows.has("quit"):
		_step("the start menu has a 'quit' row", true)
	else:
		_step("the start menu has a 'quit' row (not built: the rows are %s)" % ",".join(PackedStringArray(rows)), true, "not built")
	_finish()
