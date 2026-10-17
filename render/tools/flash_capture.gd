class_name FlashCapture
extends RefCounted
## The capture hook for Tools' frame analyser, the half of the photosensitivity check that measures pixels
## (docs/tools/flash-check.md; the contract is at the top of tools/flash/capture-web.mjs). It exists only when the
## game is started with --flashcap, or on the web with /play/?flashcap=1 (main.gd); normal play never makes one.
##
## The page then offers
##   window.__flashcap = { ready, start(scenario, { reduced, seed }), step() -> Promise<tick>, tick, scenario, error, in_window }
## - ready: true once the scene is built and its first frame is up. The game does not run by itself in this mode: no
##   first-run card, no notice, no intro, and no tick until step() asks for one.
## - start(scenario, {reduced}): sets one of Tools' worst cases up as tools/flash/flash_worst.gd does (the same
##   seeds, the same slots human or AI, the same inputs through the real pad path, and the same few writes into the
##   sim: full ki for the beam cases, forms made ready, a tier raised, both fighters set down beside the tallest
##   tower and a blast through a row of buildings for `collapse`) and holds the sim. Scenarios: mash, clash, signature, transform, collapse, ai. An unknown one plays `ai` and says so in
##   `error`. `reduced` is VFX's forced reduced motion, which also puts the flash register in its reduced mode.
## - step(): runs exactly one tick with that tick's inputs, draws it, and resolves with the tick when the next
##   animation frame starts, by which time the browser has shown the frame. `tick` is the tick on screen, and
##   `in_window` the flashes the register counts in its current second, for a cross-check.
##
## What it cannot do (say so wherever its clips are read):
## - It is not the game's own pacing. A tick is a frame here whatever the machine does; real play interpolates
##   between ticks at the display's rate. The frame is drawn at the end of its tick (interpolation 0.9999).
## - The crowd's run and startle cycles run on the shader's clock (TIME in crowd.gdshader), not on ticks, so between
##   two captured frames they move by however long the capture took. Nothing else in render/ or render/vfx does.
## - The picture is the page's canvas at whatever size the driver gave the window, at a device scale of 1. The hook
##   sets no size, and UI's scale follows the window.
## - The scenes are Tools' staging, not play: the writes into the sim above are made here too, so a capture match is
##   not a match the determinism tools know. The split view, the HUD and the camera are the game's own.
##
## The scenarios' rules are a copy of tools/flash/flash_worst.gd's (tools/ is not in an export). Tools' drift check
## fails when the two differ (docs/tools/flash-check.md): change them together.

const SCENARIOS: Array = ["mash", "mashcity", "clash", "signature", "signaturecity", "rushcity", "transform", "collapse", "mashdummy", "ring", "launchai", "clashcity", "signaturedummy", "blastdummy", "ai"]
const SEED: int = 12345
const FORM_TICKS: Array = [300, 1500]
## Which slots are the AI's (true) in each scenario.
const AI_SLOTS: Dictionary = {"mash": [false, false], "mashcity": [false, false], "clash": [false, false], "signature": [false, true], "signaturecity": [false, true], "rushcity": [false, true], "transform": [true, true], "collapse": [true, true], "ai": [true, true], "mashdummy": [false, true], "ring": [false, true], "launchai": [false, true], "clashcity": [false, false], "signaturedummy": [false, true], "blastdummy": [false, true]}

var main: Node
var scenario: String = ""
var steps: int = 0               # ticks stepped since the page loaded
var _held: Dictionary = {}       # what this hook has pressed, so a button is only sent when it changes
var _frames: int = 0
var _ready_told: bool = false
var VARIANT: int = 0                # a different run of a fixed scene: the pair set down VARIANT x 450 units further along the world (the page's start option)
var _shown_due: bool = false     # a tick was drawn last frame: its step() resolves now


func _init(m: Node) -> void:
	main = m
	JavaScriptBridge.eval("""window.__flashcap = {
		ready: false, tick: 0, scenario: '', error: '', in_window: 0, _req: null, _want: 0, _done: 0, _waiting: [],
		start(scenario, opts) { this._req = { scenario: String(scenario), reduced: !!(opts && opts.reduced), seed: (opts && opts.seed) | 0, variant: (opts && opts.variant) | 0, skip: (opts && opts.skip) | 0, slots: (opts && Array.isArray(opts.slots)) ? opts.slots.map(String) : [] }; },
		step() { return new Promise((res) => { this._waiting.push(res); this._want += 1; }); },
		_shown(tick, inWindow) { this.tick = tick; this.in_window = inWindow; this._done += 1; const r = this._waiting.shift(); if (r) r(tick); }
	};""", true)


## Once a frame, in place of the game's own frame (main._process): resolve the step drawn last frame, take a start
## request, and run one tick if a step is waiting.
func poll() -> void:
	var host: SimHost = main.host
	if _shown_due:
		_shown_due = false
		JavaScriptBridge.eval("window.__flashcap._shown(%d, %d);" % [host.ticks, host.vfx.flashes.in_window()], true)
	_frames += 1
	if not _ready_told and _frames >= 3:
		_ready_told = true
		JavaScriptBridge.eval("window.__flashcap.ready = true;", true)
	var st = JSON.parse_string(str(JavaScriptBridge.eval("(() => { const fc = window.__flashcap; const r = fc._req; fc._req = null; return JSON.stringify({ req: r, pending: fc._want - fc._done }); })()", true)))
	if not (st is Dictionary):
		return
	if st.get("req") is Dictionary:
		begin(str(st.req.get("scenario", "")), bool(st.req.get("reduced", false)), int(st.req.get("seed", 0)), int(st.req.get("skip", 0)), int(st.req.get("variant", 0)), Array(st.req.get("slots", [])))
	if int(st.get("pending", 0)) > 0:
		step()


## Set a worst case up, as tools/flash/flash_worst.gd does, and hold the sim (nothing ticks until step()).
func begin(sc: String, reduced: bool, seed: int = 0, skip: int = 0, variant: int = 0, slots: Array = []) -> void:
	VARIANT = variant
	var err: String = ""
	if not SCENARIOS.has(sc):
		err = "no scenario '%s' (%s): playing ai" % [sc, ", ".join(PackedStringArray(SCENARIOS))]
		sc = "ai"
	scenario = sc
	var ai: Array = AI_SLOTS[sc]
	var host: SimHost = main.host
	# a pairing other than the roster's first two: the page's `slots` (two fighter ids, tools/flash/capture-web.mjs --slots), as flash_worst.gd's --slots does
	var ai_set: Dictionary = {"p1": ai[0], "p2": ai[1]}
	for i in range(2, slots.size()):
		ai_set["p%d" % (i + 1)] = sc == "ring"   # the ring's bodies past the pair fight; any other scene's stand
	main.start_match(seed if seed != 0 else SEED, ai_set, {} if slots.size() < 2 else {"slots": slots})   # its own setup: no intro, not filed
	# Camera's travel budget (off by default): the page's `budget=1`, set by tools/flash/run-pixels.mjs --budget, so a run with and without it is the same sim
	var applied: Dictionary = {"budget": false, "hold": false, "mergezoom": false}   # what the hook really switched on: capture-web.mjs refuses a clip whose switch was asked for and not applied
	if main.split_view != null and _page_flag("budget"):
		main.split_view.set_travel_budget(true)
		applied["budget"] = true
	# Camera's launch hold (off by default): the page's `hold=1`, set by tools/flash/run-pixels.mjs --hold, so a run with and without it is the same sim
	if main.split_view != null and _page_flag("hold"):
		main.split_view.set_launch_hold(true)
		applied["hold"] = true
	# Camera's merge-zoom limit (off by default): the page's `mergezoom=1`, set by tools/flash/run-pixels.mjs --merge-zoom
	if main.split_view != null and _page_flag("mergezoom"):
		main.split_view.set_merge_zoom_limit(true)
		applied["mergezoom"] = true
	JavaScriptBridge.eval("window.__flashcap.switches = %s;" % JSON.stringify(applied), true)
	main.started = true              # the demo's prompt is not part of a worst case
	host.vfx.auto_quality = false
	host.vfx.destruction_enabled = true
	host.vfx.force_reduced = reduced
	_held.clear()
	host.release_all()
	for dev in range(2):             # the hub's two-human path: each pad's first press claims the next free slot
		if not ai[dev]:
			host.hub.pad_button(dev, "back", true)
			host.hub.pad_button(dev, "back", false)
			host.take_players()
	# `skip` ticks run without a picture first (the clip then starts at tick skip + 1): the fast-forward of a window subset, the same sim as a clip that drew them
	for i in range(maxi(0, skip)):
		if scenario != "":
			drive(scenario, host.ticks, host.S)
		host.acc = SimConst.DT * 0.9999
		main.frame(SimConst.DT)
	JavaScriptBridge.eval("window.__flashcap.scenario = %s; window.__flashcap.error = %s; window.__flashcap.tick = 0;" % [JSON.stringify(sc), JSON.stringify(err)], true)


## A switch of the page's own URL (`budget=1`, `hold=1`). main.parse_args() keeps only the keys of main.URL_ARGS, so the hook reads location.search itself.
func _page_flag(key: String) -> bool:
	for pair in str(JavaScriptBridge.eval("location.search", true)).trim_prefix("?").split("&", false):
		var kv: PackedStringArray = pair.split("=", true, 1)
		if kv[0] == key and kv.size() > 1 and kv[1] == "1":
			return true
	return false


## Exactly one tick, drawn at its end. The frame is on screen when the next animation frame starts (poll).
func step() -> void:
	var host: SimHost = main.host
	var before: int = host.ticks
	if scenario != "":
		drive(scenario, host.ticks, host.S)
	host.acc = SimConst.DT * 0.9999    # one tick's time short of a tick: the frame below runs one tick and draws its end
	main.frame(SimConst.DT)
	steps += 1
	if host.ticks != before + 1:
		JavaScriptBridge.eval("window.__flashcap.error = %s;" % JSON.stringify("a step ran %d ticks, not one (an overlay or a pause holds the game)" % (host.ticks - before)), true)
	_shown_due = true


# ------------------------------------------------------------------ the scenarios (tools/flash/flash_worst.gd)

## A tap: down for the first two ticks of every `gap`, shifted by `phase`.
static func _tap(t: int, gap: int, phase: int) -> bool:
	return ((t + phase) % gap) < 2


func _btn(dev: int, name: String, down: bool) -> void:
	var k: String = "%d:%s" % [dev, name]
	if down == _held.has(k):
		return
	if down:
		_held[k] = true
	else:
		_held.erase(k)
	main.host.hub.pad_button(dev, name, down)


func _stick(dev: int, x: float) -> void:
	var k: String = "%d:stick" % dev
	var v: float = signf(x)
	if _held.get(k, 0.0) == v:
		return
	_held[k] = v
	main.host.hub.pad_stick(dev, v, 0.0)


func _walk(S: SimState, near: float) -> void:
	var dx: float = SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)   # b minus a: positive when fighter 1 is to the right
	var far: bool = absf(dx) > near
	_stick(0, signf(dx) if far else 0.0)
	_stick(1, -signf(dx) if far else 0.0)


## The inputs and the staging for tick t of a scenario.
func drive(sc: String, t: int, S: SimState) -> void:
	match sc:
		"mash":         # both human, walking into reach and mashing light, with a heavy now and then
			_mash(t, S)
		"mashcity":     # the same, in the re-laid city, set down beside its tallest tower
			if t == 0:
				_to_the_city(S)
			_mash(t, S)
		"clash":        # both human, ki kept full, both firing the signature together every 30 ticks
			_walk(S, 1500.0)
			for f in S.fighters:
				f.ki = 100.0
			# the signature is the power layer's B (arena layout: RT held, then B); a base B is the heavy since the three-strength brawl
			_btn(0, "rt", true)
			_btn(1, "rt", true)
			_btn(0, "east", t % 30 < 12)
			_btn(1, "east", t % 30 < 12)
		"signature":    # player one firing the signature on a cycle against the AI
			_signature(t, S)
		"signaturecity":    # the same, started beside the tallest tower
			if t == 0:
				_to_the_city(S)
			_signature(t, S)
		"rushcity":    # player one sprints along the front street past the towers, turning every 150 ticks
			if t == 0:
				_to_the_city(S)
			_rush(t, S)
		"transform":    # AI against AI, the form made ready for both three times
			_ready_forms(S, t, [60, 500, 1000])
		"collapse":     # AI against AI, a blast through a row of buildings every 150 ticks
			_stage_collapse(S, t)
		"clashcity":    # the clash, started beside the tallest tower
			if t == 0:
				_to_the_city(S)
			_walk(S, 1500.0)
			for f in S.fighters:
				f.ki = 100.0
			_btn(0, "rt", true)
			_btn(1, "rt", true)
			_btn(0, "east", t % 30 < 12)
			_btn(1, "east", t % 30 < 12)
		"signaturedummy":    # player one fires the signature on a cycle at the idle dummy, beside the tallest tower
			if t == 0:
				_to_the_city(S)
			_signature(t, S)
		"blastdummy":   # player one mashes the energy blast point-blank on the idle dummy
			_blast_dummy(t, S)
		"mashdummy":  # player one against the idle training dummy: mash, burst, energy mash, blast, launcher chain
			_mash_dummy(t, S)
		"ring":         # player one against the ring: the AI and his guards
			_ring(t, S)
		"launchai":     # player one launches the AI
			_launch_ai(t, S)
		"ai":           # the real AI match, forms readied at 300 and 1500, a tier raised at 900
			_ready_forms(S, t, FORM_TICKS)
			if t == 900:
				S.fighters[0].tier = 3.0
			if t == 1200:
				S.fighters[1].stage[1] = 2
	# a variant of a fixed scene is a different run of it (Legal RL-131): the pair set down 450 units further along the world for each step of the variant (another place, another
	# scenery, another camera phase); 0 is the scene as it was
	if t == 0 and VARIANT != 0:
		_apply_variant(S, VARIANT)


## Both human, walking into reach and mashing light every 4 ticks each (staggered), with a heavy now and then.
func _mash(t: int, S: SimState) -> void:
	_walk(S, 250.0)
	_btn(0, "west", _tap(t, 4, 0))
	_btn(1, "west", _tap(t, 4, 2))
	_btn(0, "north", t % 37 < 2)
	_btn(1, "north", t % 41 < 2)


## Player one firing the signature on a cycle.
func _signature(t: int, S: SimState) -> void:
	_walk(S, 1800.0)
	S.fighters[0].ki = 100.0
	_btn(0, "rt", t % 90 < 60)
	_btn(0, "east", t % 90 > 2 and t % 90 < 14)
	_btn(0, "west", t % 90 > 40 and _tap(t, 6, 0))


## Player one sprints.
func _rush(t: int, S: SimState) -> void:
	# P1 sprints (stick held, dodge held: the sprint) along the front street, turning every 150 ticks so the run stays in the city; the AI fights him
	_stick(0, 1.0 if (t / 150) % 2 == 0 else -1.0)
	_btn(0, "lt", true)


## Player one against the idle training dummy (Legal RL-139: a mash-on-the-dummy scene for each fighter, in both modes), on a cycle of 600 ticks: the light mashed at the fastest tap
## (every 4 ticks), the medium mashed, the light held (the burst), the light mashed with energy held (RB: the energy mash in reach), the blast (energy held, the heavy), then a heavy
## to launch and the light after it (the launcher chain). Ki kept full; he walks to the dummy and stays in reach.
func _mash_dummy(t: int, S: SimState) -> void:
	_walk_in(S, 200.0)
	S.fighters[0].ki = 100.0
	var u: int = t % 600
	_btn(0, "rb", u >= 300 and u < 480)
	_btn(0, "west", (u < 120 and _tap(t, 4, 0)) or (u >= 240 and u < 300) or (u >= 300 and u < 420 and _tap(t, 4, 0)) or (u >= 500 and _tap(t, 6, 0)))
	_btn(0, "north", u >= 120 and u < 240 and _tap(t, 6, 0))
	_btn(0, "east", (u >= 420 and u < 480 and u % 30 < 12) or (u >= 480 and u < 490))


## Player one against the ring, the AI and his guards: the light mashed, the medium now and then, the signature once in a cycle of 300.
func _ring(t: int, S: SimState) -> void:
	_walk_in(S, 250.0)
	S.fighters[0].ki = 100.0
	var u: int = t % 300
	_btn(0, "rt", u >= 200 and u < 260)
	_btn(0, "east", u >= 203 and u < 215)
	_btn(0, "west", (u < 200 or u >= 260) and _tap(t, 4, 0))
	_btn(0, "north", t % 53 < 2)


## Player one launches the AI: a heavy every 45 ticks against the real AI (in the 1,800 ticks of the seed it launches the AI twice and is launched once; a launch is rare).
func _launch_ai(t: int, S: SimState) -> void:
	_walk_in(S, 250.0)
	S.fighters[0].ki = 100.0
	_btn(0, "east", t % 45 < 8)


## Player one goes to the other fighter and stops in reach (the other is the AI's or the dummy's): he walks, and sprints (dodge held) when a launch has sent them 900 units or more apart.
func _walk_in(S: SimState, near: float) -> void:
	var dx: float = SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)
	_stick(0, signf(dx) if absf(dx) > near else 0.0)
	_btn(0, "lt", absf(dx) > 900.0)


## Player one mashes the energy blast (energy held, the heavy tapped every 10 ticks) point-blank on the idle training dummy, ki kept full: the flames and the burn of a blast at close range,
## again and again (Legal RL-141: a mashed blast on the dummy).
func _blast_dummy(t: int, S: SimState) -> void:
	_walk_in(S, 120.0)
	S.fighters[0].ki = 100.0
	_btn(0, "rb", true)
	_btn(0, "east", _tap(t, 10, 0))


## The pair set down again `variant` x 450 units along the world from where the scene put them.
func _apply_variant(S: SimState, variant: int) -> void:
	for f in S.fighters:
		f.x = SimWrap.wrap(f.x + 450.0 * float(variant))
		f.y = WorldTerrain.groundY(S, f.x) + 10.0
		f.vx = 0.0
		f.vy = 0.0


func _ready_forms(S: SimState, t: int, ticks: Array) -> void:
	if ticks.has(t):
		for f in S.fighters:
			f.act.formReady = true


## At the start of a match the nearest building is far off the screen: both fighters are set down beside the tallest
## tower, so the blasts that follow are in view.
func _to_the_city(S: SimState) -> void:
	var tall = null
	for b in S.buildings:
		if b.alive and (tall == null or b.h > tall.h):
			tall = b
	if tall == null:
		return
	for i in range(2):
		var f = S.fighters[i]
		f.x = SimWrap.wrap(tall.x - 900.0 + 60.0 * float(i))
		f.y = WorldTerrain.groundY(S, f.x) + 10.0
		f.vx = 0.0
		f.vy = 0.0


func _stage_collapse(S: SimState, t: int) -> void:
	if t == 0:
		_to_the_city(S)
		return
	# A blast from tick 90 and every 150 after it, and its second 3 ticks later: a blast cannot finish a standing building (stages.json leaveFrac leaves a tenth
	# for the next), and the re-laid city's buildings are tall (thousands of hit points), so the blast is doubled, and aimed at the front row (the plane's row: a blast reaches only the buildings near it in depth).
	var u: int = t - 90
	if u < 0 or (u % 150 != 0 and u % 150 != 3):
		return
	var front: Array = []
	for b in S.buildings:
		if b.alive and b.row == WorldStructures.PLANE_ROW:
			front.append(b)
	if front.is_empty():
		return
	var cx: float = S.fighters[0].x
	front.sort_custom(func(a, b): return absf(SimWrap.sdx(cx, a.x)) < absf(SimWrap.sdx(cx, b.x)))
	var k: int = (u / 150) % maxi(1, front.size() / 3)
	var b0 = front[mini(front.size() - 1, k * 3)]
	S.fighters[0].tier = 3.0
	WorldStructures.explode(S, b0.x, WorldTerrain.groundY(S, b0.x) + 40.0, 800.0, S.fighters[0])
