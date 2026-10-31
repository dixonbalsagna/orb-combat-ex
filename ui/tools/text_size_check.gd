extends SceneTree
## The Text size option (Settings, Normal 1.0 / Large 1.25 / Larger 1.5; UiText.size_mult): at the PC sizes, at each step, every screen that plans its own text still fits, so nothing is cut and no line ends in "...".
## It plans each screen the way hud_check does (UiLayout.compute, then the widget's plan) and asks the plan's own `fits`, plus the screen-specific rules: the Settings help is whole, the start menu's controls
## stay 48 dp targets, every text is at or above the floor of the step. Also: a larger step never draws a text smaller than a smaller one, and the option round-trips through the saved options.
## Usage (repo root): godot --headless --path . --script res://ui/tools/text_size_check.gd

const SIZES: Array = [[Vector2(1280, 720), 1.0], [Vector2(1280, 800), 1.0], [Vector2(1920, 1080), 1.0], [Vector2(3840, 2160), 1.0]]
const STEPS: Array = [1.0, 1.25, 1.5]

var fails: int = 0
var checks: int = 0


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL: " + what)


var steps: Array = STEPS


## A node whose _draw runs a callable, so a widget's own draw can run (headless too) with UiText keeping the rectangle of every line.
class Probe extends Control:
	var fn: Callable

	func _draw() -> void:
		fn.call(self)


## The match HUD at a size and step, driven by a mock scenario for `secs` seconds with every line's rectangle kept each frame: how many lines went off the screen and how many pairs overlap
## (a line over another line is a collision: two texts that no longer have room). {"outside": n, "overlaps": n, "lines": n, "sample": first of each}.
func _match_lines(sz: Vector2i, scn: String, secs: float, step: float) -> Dictionary:
	root.size = sz
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var hud: UiHud = load("res://ui/hud/ui_hud.tscn").instantiate()
	host.add_child(hud)
	var f: Array = UiMockFeed.fighters(scn)
	hud.setup(f[0], f[1])
	hud.set_option("text_size", step)   # a new HUD starts at its own option (Normal), so the step is the HUD's
	hud.set_option("show_prompts", true)
	hud.set_option("force_redraw", true)   # every layer draws every frame, so the lines of this frame are all kept
	hud.anchor_fn = func(slot): return {"pos": Vector2(float(sz.x) * (0.35 + 0.3 * float(slot)), float(sz.y) * 0.55), "h": 120.0, "visible": true}
	var feed := UiMockFeed.new(scn, 3)
	var out := {"outside": 0, "overlaps": 0, "lines": 0, "sample": ""}
	var view := Rect2(Vector2.ZERO, Vector2(sz))
	for i in range(int(secs * 60.0)):
		for e in feed.step(1.0 / 60.0):
			hud.consume(e)
		hud.advance(1.0 / 60.0)
		if i % 20 == 19:
			UiText.boxes = []
			UiText.boxing = true
			await process_frame
			UiText.boxing = false
			var seen: Array = UiText.boxes.duplicate()
			UiText.boxes = []
			out["lines"] += seen.size()
			for a in seen:
				if not view.grow(1.0).encloses(a["rect"]):
					out["outside"] += 1
					if out["sample"] == "":
						out["sample"] = "'%s' %s from %s" % [str(a["text"]).left(30), str(a["rect"]), str(a["at"])]
			for x in range(seen.size()):
				for y in range(x + 1, seen.size()):
					var ra: Rect2 = seen[x]["rect"]
					var rb: Rect2 = seen[y]["rect"]
					var inter: Rect2 = ra.intersection(rb)
					if inter.size.x > 1.0 and inter.size.y > 0.5 * minf(ra.size.y, rb.size.y) and str(seen[x]["text"]) != str(seen[y]["text"]):
						out["overlaps"] += 1
						if out["sample"] == "":
							out["sample"] = "'%s' over '%s'" % [str(seen[x]["text"]).left(24), str(seen[y]["text"]).left(24)]
	host.queue_free()
	await process_frame
	UiText.size_mult = step
	return out


## Draw with `fn(canvas)` and check that every line it draws lies inside `card` (so none is cut off by the card's edge, and none is drawn over the edge).
func _drawn(tag: String, card: Rect2, fn: Callable) -> void:
	var pr := Probe.new()
	pr.size = Vector2(4000, 2400)
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
	var bad: int = 0
	var first: String = ""
	for b in seen:
		var r: Rect2 = b["rect"]
		if not card.grow(2.0).encloses(r):
			bad += 1
			if first == "":
				first = "'%s' %s outside the card %s" % [str(b["text"]).left(40), str(r), str(card)]
	_ok(seen.size() > 0 and bad == 0, "%s: every line drawn lies inside the card (%d lines, %d outside; %s)" % [tag, seen.size(), bad, first])


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--negative-control":
			steps = [1.0, 3.0]   # a step the layouts are not built for: the check must fail
	_run.call_deferred()


func _run() -> void:
	UiData.ensure()
	var opt: Dictionary = UiData.options().get("text_size", {})
	_ok((opt.get("choices", []) as Array) == STEPS and float(opt.get("default", 0.0)) == 1.0, "the option's steps are Normal 1.0, Large 1.25, Larger 1.5, and Normal is the default")
	for cs in SIZES:
		var sz: Vector2 = cs[0]
		var dpv: float = cs[1]
		var smallest: Dictionary = {}
		var match_base: Dictionary = {}
		for step in steps:
			UiText.size_mult = step
			var lay := UiLayout.new()
			lay.dp = dpv
			lay.compute(sz, false)
			var tag := "%dx%d x%.2f" % [int(sz.x), int(sz.y), step]
			_ok(UiText.px(18.0, lay.s) >= int(round(UiLook.text_floor * step)), "%s: the smallest text asked for is the floor times the step" % tag)
			# The start menu: one player, two players, mid-match, with Not now.
			for cfg in [{"players": 1, "p1": "kb", "p2": "kb", "ai_level": "medium"}, {"players": 2, "p1": "pad", "p2": "kb", "ai_level": "medium"}, {"players": 1, "p1": "pad", "p2": "kb", "ai_level": "hard"}]:
				for mid in [false, true]:
					var mp: Dictionary = UiMenu.plan(sz, lay.s, dpv, false, {"focus": 0, "cfg": cfg, "mid_match": mid, "safe": lay.safe, "pad_missing": false, "not_now": not mid})
					_ok(bool(mp["fits"]), "%s: the start menu fits (%d players, mid %s)" % [tag, int(cfg["players"]), str(mid)])
					_ok(float(mp["fs"]) >= UiLook.text_floor, "%s: the start menu's text is at or above the floor" % tag)
			# What each screen draws stays inside its card (the key hints and every line, not only the plan's own fits).
			for cfg2 in [{"players": 1, "p1": "kb", "p2": "kb", "ai_level": "medium"}, {"players": 2, "p1": "pad", "p2": "kb", "ai_level": "medium"}]:
				for mid2 in [false, true]:
					var mp2: Dictionary = UiMenu.plan(sz, lay.s, dpv, false, {"focus": 0, "cfg": cfg2, "mid_match": mid2, "safe": lay.safe, "pad_missing": false, "not_now": not mid2})
					await _drawn("%s: start menu draw (%d players, mid %s)" % [tag, int(cfg2["players"]), str(mid2)], mp2["card"], func(ci): UiMenu.draw(ci, mp2))
			var dopts: Dictionary = UiData.option_defaults()
			for dev2 in ["kbd", "pad"]:
				for fi in [1, 9, 15, 20, 32]:
					var sp2: Dictionary = UiSettings.plan(sz, lay.s, dpv, false, {"focus": fi, "scroll": 0.0, "device": dev2}, dopts)
					await _drawn("%s: Settings draw (row %d, %s)" % [tag, fi, dev2], sp2["card"], func(ci): UiSettings.draw(ci, sp2, dopts))
			for ps2 in [{}, {"two": true}, {"confirm": true}, {"over": true}]:
				var pp2: Dictionary = UiPause.plan(sz, lay.s, dpv, false, ps2)
				await _drawn("%s: pause menu draw %s" % [tag, str(ps2)], pp2["card"], func(ci): UiPause.draw(ci, pp2))
			for gate2 in [false, true]:
				var np2: Dictionary = UiNotice.plan(sz, lay.s, dpv, false, {"focus": -1, "gate": gate2, "safe": lay.safe})
				await _drawn("%s: notice draw (gate %s)" % [tag, str(gate2)], np2["card"], func(ci): UiNotice.draw(ci, np2))
			# Settings: every row focused, the foot follows its help.
			var rws: Array = UiSettings.rows()
			var worst_foot: int = 0
			for i in range(rws.size()):
				var sp: Dictionary = UiSettings.plan(sz, lay.s, dpv, false, {"focus": i, "scroll": 0.0}, {})
				_ok(bool(sp["fits"]), "%s: Settings fits with row %d (%s) focused" % [tag, i, str(rws[i].get("key", rws[i].get("label", "")))])
				if str(rws[i].get("help", "")) != "":
					var hl: PackedStringArray = UiText.wrap(str(rws[i]["help"]), int(sp["fs_small"]), (sp["footer"] as Rect2).size.x)
					_ok(int(sp["help_lines"]) >= mini(hl.size(), int(sp["help_lines"])) and (int(sp["help_lines"]) >= hl.size() or int(sp["help_scroll"]) >= 0), "%s: row %d: the help is whole or scrolls" % [tag, i])
					if sz.y >= 720.0:
						_ok(int(sp["help_lines"]) >= hl.size(), "%s: row %d (%s): the whole help shows in the foot, no '...' (%d lines needed, %d shown)" % [tag, i, str(rws[i].get("key", "")), hl.size(), int(sp["help_lines"])])
					worst_foot = maxi(worst_foot, int(sp["help_lines"]))
			# The pause menu, the match-over card, the confirm card, two players.
			for ps in [{}, {"two": true}, {"confirm": true}, {"over": true}]:
				var pp: Dictionary = UiPause.plan(sz, lay.s, dpv, false, ps)
				_ok(bool(pp["fits"]), "%s: the pause menu fits %s" % [tag, str(ps)])
			# How to play: every page, keyboard and pad.
			for dev in ["kbd", "xbox"]:
				for pg in range(UiHowto.page_count()):
					var hp: Dictionary = UiHowto.plan(sz, lay.s, dpv, false, pg, dev, 0)
					_ok(bool(hp["fits"]), "%s: How to play fits (%s page %d)" % [tag, dev, pg])
			for gate in [false, true]:
				var np: Dictionary = UiNotice.plan(sz, lay.s, dpv, false, {"focus": -1, "gate": gate, "safe": lay.safe})
				_ok(bool(np["fits"]) or float(np["max_scroll"]) > 0.0, "%s: the notice fits or scrolls (gate %s)" % [tag, str(gate)])
			for st in [UiFeedback.STATE_WRITE, UiFeedback.STATE_COPIED, UiFeedback.STATE_REVIEW]:
				var fp: Dictionary = UiFeedback.plan(sz, lay.s, dpv, false, st)
				_ok(bool(fp["fits"]), "%s: the feedback card fits (%s)" % [tag, str(st)])
			var lp: Dictionary = UiLoading.plan(sz, lay.s, dpv, lay.safe, {"phase": "climate", "progress": 0.5})
			_ok(lp.has("line"), "%s: the loading screen plans" % tag)
			# The match HUD: no more lines off the screen and no more lines over lines than at Normal.
			for scn in ["hero_vs_proud", "empress_vs_cyborg", "stress", "controls"]:
				var ml: Dictionary = await _match_lines(Vector2i(sz), scn, 8.0, step)
				if step == 1.0:
					match_base[scn] = ml
					_ok(int(ml["lines"]) > 0, "%s: the match HUD drew lines (%s)" % [tag, scn])
				else:
					var b0: Dictionary = match_base.get(scn, {"outside": 0, "overlaps": 0})
					_ok(int(ml["outside"]) <= int(b0["outside"]) and int(ml["overlaps"]) <= int(b0["overlaps"]), "%s: the match HUD (%s) has no more lines off the screen (%d, Normal %d) or over each other (%d, Normal %d) than Normal; first: %s" % [tag, scn, int(ml["outside"]), int(b0["outside"]), int(ml["overlaps"]), int(b0["overlaps"]), str(ml["sample"])])
			smallest[step] = UiText.px(18.0, lay.s)
		if steps == STEPS:
			_ok(int(smallest[1.25]) >= int(smallest[1.0]) and int(smallest[1.5]) >= int(smallest[1.25]) and int(smallest[1.5]) > int(smallest[1.0]), "%dx%d: a bigger step asks for bigger text" % [int(sz.x), int(sz.y)])
	UiText.size_mult = 1.0
	# The option: a Settings row that cycles the three steps, applied to UiText, saved with the options, restored by a new HUD, and a value the data does not list snaps to the nearest step.
	UiPrefs.path = "user://ui_prefs_test_textsize.json"   # a file of its own: the player's saved choices are not touched
	if FileAccess.file_exists(UiPrefs.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(UiPrefs.path))
	var hud: UiHud = load("res://ui/hud/ui_hud.tscn").instantiate()
	hud.size = Vector2(1280, 720)
	root.add_child(hud)
	await process_frame
	_ok(UiText.size_mult == 1.0 and float(hud.opts["text_size"]) == 1.0, "a new HUD starts at Normal")
	var row: Dictionary = {}
	for r in UiSettings.rows():
		if str(r.get("key", "")) == "text_size":
			row = r
	_ok(not row.is_empty() and UiSettings.choice_word("text_size", 1.25) == "Large" and UiSettings.choice_word("text_size", 1.5) == "Larger" and UiSettings.choice_word("text_size", 1.0) == "Normal", "Settings lists Text size: Normal, Large, Larger")
	_ok(not row.is_empty() and UiSettings.stepped(row, hud.opts, 1) == 1.25, "Settings: Right from Normal is Large")
	hud.settings_set("text_size", 1.5)
	_ok(UiText.size_mult == 1.5 and float(hud.opts["text_size"]) == 1.5, "choosing Larger sets the multiplier the layouts read")
	var saved = UiPrefs.get_value("options", {})
	_ok(saved is Dictionary and float((saved as Dictionary).get("text_size", 0.0)) == 1.5, "the choice is saved with the options")
	hud.set_option("text_size", 1.0)
	_ok(UiText.size_mult == 1.0, "a step back to Normal sets 1.0")
	hud.set_option("text_size", 9.0)
	_ok(float(hud.opts["text_size"]) == 1.5 and UiText.size_mult == 1.5, "a value the data does not list snaps to the nearest step (9.0 is Larger)")
	hud.set_option("text_size", 0.2)
	_ok(float(hud.opts["text_size"]) == 1.0 and UiText.size_mult == 1.0, "and a small one to Normal")
	hud.queue_free()
	await process_frame
	var hud2: UiHud = load("res://ui/hud/ui_hud.tscn").instantiate()
	hud2.size = Vector2(1280, 720)
	root.add_child(hud2)
	await process_frame
	hud2.load_saved_options()
	_ok(UiText.size_mult == 1.5 and float(hud2.opts["text_size"]) == 1.5, "a new HUD that loads the saved options is at Larger again (round-trip through save and load)")
	hud2.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(UiPrefs.path))
	UiText.size_mult = 1.0
	print("\ntext_size_check: %d checks, %d failed" % [checks, fails])
	quit(0 if fails == 0 else 1)
