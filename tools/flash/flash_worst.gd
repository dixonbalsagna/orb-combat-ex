extends SceneTree
## Half 1 of the photosensitivity check (docs/tools/flash-check.md): plays the worst cases Legal names through the real game scene and writes the flash register's whole
## log for each, in normal and in reduced-flashing mode, for tools/flash/check-log.js to recount. Headless, one process, no window.
##   mash        both fighters human, walking into reach and mashing light (every 4 ticks each, staggered) with a heavy now and then
##   clash       both human, ki kept full, both firing the signature together every 30 ticks, so beams meet
##   signature   P1 human firing the signature on a cycle against the AI
##   transform   AI against AI, the form made ready for both at fixed ticks three times (tier 1 to 4: the game never goes past 4), so the transformation plays through again and again
##   collapse    AI against AI, with building collapses staged in the sim's own way (WorldStructures.explode through a row of towers, again and again)
##   ai          the real AI matches of hash_check (seeds 12345, 4, 7), forms readied at 300 and 1500, a tier raised at 900
## The scenes are driven through the real input path (host.key_down) and the real scene (main.frame); the only direct writes into the sim are the ones hash_check
## already makes (formReady, tier), ki refills for the signature cases and the explosions of `collapse`. Nothing here reads a figure out of the register to decide a run:
## the rows are written out and the Node tool recounts them.
##
## Usage (from the repo root):
##   godot --headless --path . --script res://tools/flash/flash_worst.gd [-- --out=build/flash --only=mash,clash --ticks=1800 --seeds=12345,4]
## --negative-control adds four unrefusable flashes (the register's `note`) at ticks 100 to 130 of every run: check-log.js must then FAIL, which proves the chain from the register's log to the verdict can fail.
## Exit 0 when every run was played and written (the verdict is check-log.js's), 1 on a tool error. At most one Godot process; the scenes run one after another.

const DT: float = 1.0 / 60.0
const FORM_TICKS: Array = [300, 1500]
const SCENARIOS: Array = ["mash", "clash", "signature", "transform", "collapse", "ai"]
const SEEDS: Dictionary = {"mash": [12345], "clash": [12345], "signature": [12345], "transform": [12345], "collapse": [12345], "ai": [12345, 4, 7]}
const TICKS: Dictionary = {"mash": 1800, "clash": 1500, "signature": 1500, "transform": 1500, "collapse": 1500, "ai": 3600}
## Which slots are AI (true) in each scenario.
const AI_SLOTS: Dictionary = {"mash": [false, false], "clash": [false, false], "signature": [false, true], "transform": [true, true], "collapse": [true, true], "ai": [true, true]}

var main: Node
var out_dir: String = "build/flash"
var only: Array = []
var tick_override: int = 0
var seed_override: Array = []
var held: Dictionary = {}        # key code -> true: what this tool has pressed, so a key is only sent when it changes
var events: Dictionary = {}      # event type (and beam_outcome:kind) -> count, for the run being played
var body_on: Array = [false, false]
var body_starts: Array = [[], []]   # per fighter, the ticks at which the body hit flash began (by the rule Rendering uses)
var failed: bool = false
var trace: bool = false
var negative: bool = false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--only="):
			only = Array(a.substr(7).split(","))
		elif a == "--negative-control":
			negative = true
		elif a == "--trace":
			trace = true
		elif a.begins_with("--ticks="):
			tick_override = int(a.substr(8))
		elif a.begins_with("--seeds="):
			seed_override = Array(a.substr(8).split(",")).map(func(s): return int(s))
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
	main.host.vfx.auto_quality = false
	main.host.vfx.destruction_enabled = true
	if not DirAccess.dir_exists_absolute(_abs(out_dir)):
		DirAccess.make_dir_recursive_absolute(_abs(out_dir))
	var written: int = 0
	for sc in SCENARIOS:
		if not only.is_empty() and not only.has(sc):
			continue
		for seed in (seed_override if not seed_override.is_empty() else SEEDS[sc]):
			for reduced in [false, true]:
				var run: Dictionary = await _play(sc, int(seed), reduced)
				var name: String = "flash-%s-%s%s.json" % [sc, "reduced" if reduced else "normal", "" if SEEDS[sc].size() == 1 else "-%d" % seed]
				var f := FileAccess.open(_abs(out_dir).path_join(name), FileAccess.WRITE)
				if f == null:
					push_error("cannot write %s" % name)
					failed = true
					continue
				f.store_string(JSON.stringify(run))
				f.close()
				written += 1
				var s: Dictionary = run["summary"]
				print("%-10s %-8s seed %-6d %4d ticks: %3d asks, %3d granted, worst %d in 60 ticks (the register's own figure), events %s" % [sc, "reduced" if reduced else "normal", seed, run["ticks"], run["rows"].size(), s["granted"], s["worst_second"], _top(run["events"])])
	print("wrote %d run files to %s" % [written, _abs(out_dir)])
	quit(1 if failed or written == 0 else 0)


static func _abs(p: String) -> String:
	return p if p.is_absolute_path() else ProjectSettings.globalize_path("res://").path_join(p)


static func _top(ev: Dictionary) -> String:
	var keys: Array = ["damage", "beam_outcome", "transform", "building_fall", "tier_up", "shot_hit", "shot_clash"]
	var parts: Array = []
	for k in keys:
		parts.append("%s %d" % [k, int(ev.get(k, 0))])
	return ", ".join(parts)


func _play(sc: String, seed: int, reduced: bool) -> Dictionary:
	var ai: Array = AI_SLOTS[sc]
	main.start_match(seed, {"p1": ai[0], "p2": ai[1]})
	var host: SimHost = main.host
	host.vfx.force_reduced = reduced
	_release_all()
	_claim_pads(ai)
	events.clear()
	body_on = [false, false]
	body_starts = [[], []]
	var cb := func(evs: Array, _lines: Array):
		for e in evs:
			events[e.type] = int(events.get(e.type, 0)) + 1
			if e.type == "beam_outcome":
				var k: String = "beam_outcome:%s" % str(e.kind)
				events[k] = int(events.get(k, 0)) + 1
	host.drained.connect(cb)
	var total: int = tick_override if tick_override > 0 else int(TICKS[sc])
	var reduced_seen: bool = false
	var guard: int = 0
	while host.ticks < total and guard < total * 4:
		_drive(sc, host.ticks, host.S)
		if negative and [100, 110, 120, 130].has(host.ticks):
			host.vfx.flashes.note("explosion", host.S.tick)   # four flashes the register cannot refuse in 30 ticks: the count must fail
		var before: int = host.ticks
		main.frame(DT)
		guard += 1
		if trace and host.ticks != before and host.ticks % 60 == 0:
			var S2: SimState = host.S
			print("  t%d dx %.0f  %s/%s  hp %.0f/%.0f  ki %.0f/%.0f  ai %s/%s  held %s" % [host.ticks, SimWrap.sdx(S2.fighters[0].x, S2.fighters[1].x), S2.fighters[0].state, S2.fighters[1].state, S2.fighters[0].hp, S2.fighters[1].hp, S2.fighters[0].ki, S2.fighters[1].ki, S2.fighters[0].ai != null, S2.fighters[1].ai != null, held.keys()])
		if host.ticks != before:
			_watch_body(host.S, host.ticks)
			reduced_seen = reduced_seen or host.vfx.flashes.reduced
	host.drained.disconnect(cb)
	_release_all()
	var fl = host.vfx.flashes
	var sm: Dictionary = fl.summary()
	return {
		"scenario": sc, "seed": seed, "reduced": reduced, "reduced_seen": reduced_seen, "ticks": host.ticks, "cap": sm["cap"],
		"rows": fl.log_rows(), "asked": int(sm["granted"]) + int(sm["refused"]), "summary": sm, "events": events.duplicate(),
		"proxy": {"body_hit": {"seconds": RenderLook.HIT_FLASH_S, "worst_per_fighter": [_worst_starts(body_starts[0]), _worst_starts(body_starts[1])], "worst_flashes_per_second": maxi(_worst_starts(body_starts[0]), _worst_starts(body_starts[1])), "starts": [body_starts[0].size(), body_starts[1].size()]}},
	}


## The body hit flash is Rendering's (fighter_view.gd: white while T - hurtT < HIT_FLASH_S) and is not under the register, so it is counted here from the same
## sim field and the same constant: a start is the tick the white comes on after it was off.
func _watch_body(S: SimState, tick: int) -> void:
	for i in range(2):
		var f = S.fighters[i]
		var on: bool = S.T - f.hurtT < RenderLook.HIT_FLASH_S and S.T >= f.hurtT
		if on and not body_on[i]:
			body_starts[i].append(tick)
		body_on[i] = on


static func _worst_starts(ts: Array) -> int:
	var best: int = 0
	for i in range(ts.size()):
		var k: int = 0
		for j in range(i, ts.size()):
			if int(ts[j]) < int(ts[i]) + 60:
				k += 1
			else:
				break
		best = maxi(best, k)
	return best


# ------------------------------------------------------------------ input
## Humans play through pads (device 0 for slot 0, device 1 for slot 1) because that is the hub's two-human path: two players cannot both be on the keyboard until a
## second device has joined. A pad's first press claims the first free slot, so each is claimed by a harmless button in order. Buttons are the arena layout's:
## west light, north heavy, east signature; the stick walks.

func _btn(dev: int, name: String, down: bool) -> void:
	var k: String = "%d:%s" % [dev, name]
	if down == held.has(k):
		return
	if down:
		held[k] = true
	else:
		held.erase(k)
	main.host.hub.pad_button(dev, name, down)


func _stick(dev: int, x: float) -> void:
	var k: String = "%d:stick" % dev
	var v: float = signf(x)
	if held.get(k, 0.0) == v:
		return
	held[k] = v
	main.host.hub.pad_stick(dev, v, 0.0)


func _release_all() -> void:
	held.clear()
	main.host.release_all()


## Both human slots claimed in order (a pad that has not joined cannot move a stick).
func _claim_pads(ai: Array) -> void:
	for dev in range(2):
		if not ai[dev]:
			main.host.hub.pad_button(dev, "back", true)
			main.host.hub.pad_button(dev, "back", false)
			main.host.take_players()


## A tap: down for the first two ticks of every `gap`, shifted by `phase`.
static func _tap(t: int, gap: int, phase: int) -> bool:
	return ((t + phase) % gap) < 2


func _walk(S: SimState, near: float) -> void:
	var dx: float = SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)   # b minus a: positive when fighter 1 is to the right
	var far: bool = absf(dx) > near
	_stick(0, signf(dx) if far else 0.0)
	_stick(1, -signf(dx) if far else 0.0)


func _drive(sc: String, t: int, S: SimState) -> void:
	match sc:
		"mash":
			_walk(S, 250.0)
			_btn(0, "west", _tap(t, 4, 0))
			_btn(1, "west", _tap(t, 4, 2))
			_btn(0, "north", t % 37 < 2)
			_btn(1, "north", t % 41 < 2)
		"clash":
			_walk(S, 1500.0)
			for f in S.fighters:
				f.ki = 100.0
			_btn(0, "east", t % 30 < 2)
			_btn(1, "east", t % 30 < 2)
		"signature":
			_walk(S, 1800.0)
			S.fighters[0].ki = 100.0
			_btn(0, "east", t % 90 < 2)
			_btn(0, "west", t % 90 > 40 and _tap(t, 6, 0))
		"transform":
			_ready_forms(S, t, [60, 500, 1000])
		"collapse":
			_stage_collapse(S, t)
		"ai":
			_ready_forms(S, t, FORM_TICKS)
			if t == 900:
				S.fighters[0].tier = 3.0
			if t == 1200:
				S.fighters[1].stage[1] = 2


## Forms ready at fixed ticks (hash_check does the same), so real `transform` events play, and tiers raised so the power effects are in view.
func _ready_forms(S: SimState, t: int, ticks: Array) -> void:
	if ticks.has(t):
		for f in S.fighters:
			f.act.formReady = true


## Both fighters set down beside the tallest tower (900 and 840 units to its left, on the ground), so the blasts that follow are on screen: at the start the nearest
## building is 18,000 units away, off screen for a pixel capture. Staged on the first tick, before anything is drawn.
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


## Collapses staged the way the sim makes them (a blast levels the buildings it reaches, WorldStructures.explode), a row of towers every 150 ticks, from the fighters' own
## neighbourhood outwards, so a collapse is on screen again and again for the whole run.
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
	events["staged_blast"] = int(events.get("staged_blast", 0)) + 1
	S.fighters[0].tier = 3.0
	WorldStructures.explode(S, b0.x, WorldTerrain.groundY(S, b0.x) + 40.0, 800.0, S.fighters[0])
