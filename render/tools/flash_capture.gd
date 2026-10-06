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

const SCENARIOS: Array = ["mash", "clash", "signature", "transform", "collapse", "ai"]
const SEED: int = 12345
const FORM_TICKS: Array = [300, 1500]
## Which slots are the AI's (true) in each scenario.
const AI_SLOTS: Dictionary = {"mash": [false, false], "clash": [false, false], "signature": [false, true], "transform": [true, true], "collapse": [true, true], "ai": [true, true]}

var main: Node
var scenario: String = ""
var steps: int = 0               # ticks stepped since the page loaded
var _held: Dictionary = {}       # what this hook has pressed, so a button is only sent when it changes
var _frames: int = 0
var _ready_told: bool = false
var _shown_due: bool = false     # a tick was drawn last frame: its step() resolves now


func _init(m: Node) -> void:
	main = m
	JavaScriptBridge.eval("""window.__flashcap = {
		ready: false, tick: 0, scenario: '', error: '', in_window: 0, _req: null, _want: 0, _done: 0, _waiting: [],
		start(scenario, opts) { this._req = { scenario: String(scenario), reduced: !!(opts && opts.reduced), seed: (opts && opts.seed) | 0 }; },
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
		begin(str(st.req.get("scenario", "")), bool(st.req.get("reduced", false)), int(st.req.get("seed", 0)))
	if int(st.get("pending", 0)) > 0:
		step()


## Set a worst case up, as tools/flash/flash_worst.gd does, and hold the sim (nothing ticks until step()).
func begin(sc: String, reduced: bool, seed: int = 0) -> void:
	var err: String = ""
	if not SCENARIOS.has(sc):
		err = "no scenario '%s' (%s): playing ai" % [sc, ", ".join(PackedStringArray(SCENARIOS))]
		sc = "ai"
	scenario = sc
	var ai: Array = AI_SLOTS[sc]
	var host: SimHost = main.host
	main.start_match(seed if seed != 0 else SEED, {"p1": ai[0], "p2": ai[1]}, {})   # its own setup: no intro, not filed
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
	JavaScriptBridge.eval("window.__flashcap.scenario = %s; window.__flashcap.error = %s; window.__flashcap.tick = 0;" % [JSON.stringify(sc), JSON.stringify(err)], true)


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
			_walk(S, 250.0)
			_btn(0, "west", _tap(t, 4, 0))
			_btn(1, "west", _tap(t, 4, 2))
			_btn(0, "north", t % 37 < 2)
			_btn(1, "north", t % 41 < 2)
		"clash":        # both human, ki kept full, both firing the signature together every 30 ticks
			_walk(S, 1500.0)
			for f in S.fighters:
				f.ki = 100.0
			_btn(0, "east", t % 30 < 2)
			_btn(1, "east", t % 30 < 2)
		"signature":    # player one firing the signature on a cycle against the AI
			_walk(S, 1800.0)
			S.fighters[0].ki = 100.0
			_btn(0, "east", t % 90 < 2)
			_btn(0, "west", t % 90 > 40 and _tap(t, 6, 0))
		"transform":    # AI against AI, the form made ready for both three times
			_ready_forms(S, t, [60, 500, 1000])
		"collapse":     # AI against AI, a blast through a row of buildings every 150 ticks
			_stage_collapse(S, t)
		"ai":           # the real AI match, forms readied at 300 and 1500, a tier raised at 900
			_ready_forms(S, t, FORM_TICKS)
			if t == 900:
				S.fighters[0].tier = 3.0
			if t == 1200:
				S.fighters[1].stage[1] = 2


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
	if t < 90 or (t - 90) % 150 != 0:
		return
	var alive: Array = []
	for b in S.buildings:
		if b.alive:
			alive.append(b)
	if alive.is_empty():
		return
	var cx: float = S.fighters[0].x
	alive.sort_custom(func(a, b): return absf(SimWrap.sdx(cx, a.x)) < absf(SimWrap.sdx(cx, b.x)))
	var k: int = ((t - 90) / 150) % maxi(1, alive.size() / 4)
	var b0 = alive[mini(alive.size() - 1, k * 3)]
	S.fighters[0].tier = 3.0
	WorldStructures.explode(S, b0.x, WorldTerrain.groundY(S, b0.x) + 40.0, 800.0, S.fighters[0])
