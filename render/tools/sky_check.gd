extends SceneTree
## Sky check, in two halves (QA's GB-002). The tool poses a fresh match's fighters by hand on open plains (its own
## state; no tick runs).
## The numbers (always, and all of it under --headless): what the pane hands the sky shader.
## - by default nothing parts: at tier 4, on the screen, the reaction's weight is 0 and the shader's parting is off;
## - main turns it on only for --skyreact, and the web page's URL may name it;
## - with it on: full at tier 4, half at tier 3, nothing for a fighter off the screen, nothing with reduced motion;
## - the cloud pattern's place wraps with the planet, and stands still with reduced motion.
## The dynamic sky (render/core/sky_drive.gd; Art's docs/art/dynamic-sky.md), numbers too:
## - at a match's start the pane hands the shader the sunset key to the bit: the colours and the stars it always had;
## - every key's colours are the key's own on its place of the lap, and the port agrees with Art's reference code at
##   places between the keys and at the mood's extremes;
## - nothing is fast: with the camera flying a quarter of a lap a second and turning back every 3 seconds for 3
##   minutes, no band's luminance changes by more than the place budget in any second; with the mood and the damage
##   slammed on and off as well, and with a driver that jumps, none by more than 0.05 and their weighted mean by no
##   more than 0.02;
## - the mood eases over Art's least durations, and with reduced motion the drift and the mood hold;
## - the switches (--staticsky, --sky, --skymood), and what a pane's sky costs a frame.
## The pictures (with a window only): with the reaction on, the clouds part and that is all the sky does (it once
## paled the sky in a tall opening down to the horizon, which read as a pale pillar from a high camera and hung in the
## sky for a fighter nobody could see). The sky is drawn with both at tier 1 and again with both at tier 4, from a low
## and a high camera, and the two pictures are compared above the horizon:
## - with the clouds off, nothing differs: the reaction draws nothing where there is no cloud;
## - with the clouds on, the last of the cloud band above the horizon does not differ: no pillar to the horizon;
## - with the clouds on, something does differ in at least one place round the planet: the check is not blind;
## - a tier 4 fighter off the screen changes nothing;
## - with reduced motion (PaneWorld.sky_calm) nothing differs.
##   godot --headless --path . --script res://render/tools/sky_check.gd -- [--out=DIR] [--s=4]

const SAME := 3.0      # the largest difference of a channel (of 255) between two draws of the same sky
const SEEN := 12.0     # ... and the least that counts as the clouds having parted

var out: String = ""
var seed: int = 4
var main: Node
var fails: int = 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--s="):
			seed = int(a.substr(4))
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	vpn.render_target_update_mode = SubViewport.UPDATE_ALWAYS
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
	main.start_match(seed)
	main.ui_hud.visible = false
	main.hud.visible = false
	# Only the sky is judged. Hidden: the fighters (their auras and streaks grow with the tier), VFX's effects, and the
	# planet (a building's cut-away round a fighter changes with his drawn size, and a roof can stand above the horizon).
	for name in ["Fighters", "Vfx", "Planet"]:
		main.pane.get_node(name).visible = false
	var S: SimState = main.host.S
	var vp: Vector2 = main.get_viewport().get_visible_rect().size
	_dynamic(S)
	main.start_match(seed)
	S = main.host.S
	_numbers(S, vp)
	if DisplayServer.get_name() == "headless":
		print("(the pictures need a window: not drawn under --headless)")
	else:
		PaneWorld.sky_react_on = true
		await _pictures(S, vp)
		PaneWorld.sky_react_on = false
	print("sky check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


# ------------------------------------------------------------------ the dynamic sky

## Art's reference code (art/concepts/sky/keys.mjs skyAt and moodSky) at places between the keys and at the mood's
## extremes: horizon, lower, upper, top.
const REF: Dictionary = {
	0.1: ["#f1deb2", "#6fac66", "#0060a1", "#182f73"], 0.25: ["#f6ca8d", "#dd8e6a", "#385595", "#162455"], 0.45: ["#6d6b74", "#5a485d", "#212651", "#090e27"],
	0.7: ["#207279", "#005857", "#0c2a4d", "#091028"], 0.92: ["#eed8b7", "#4fa168", "#005c93", "#152c67"],
}
const REF_MOOD: Array = [[0.33, 1.0, 0.0, ["#f2af74", "#c06a61", "#3b386e", "#0f1635"]], [0.33, 0.0, 1.0, ["#775940", "#6d423a", "#3f3759", "#171e38"]], [0.02, 1.0, 1.0, ["#726456", "#314354", "#243d5e", "#192a55"]]]
const REF_LAP_S: float = 48.68   # one lap at the limit, by the reference slewStep


## The largest difference of a channel, of 255, between four colours and four hex strings.
static func _off(cols: Array, hexes: Array) -> float:
	var worst: float = 0.0
	for i in range(4):
		var h := Color.html(str(hexes[i]))
		var c: Color = cols[i]
		worst = maxf(worst, 255.0 * maxf(absf(c.r - h.r), maxf(absf(c.g - h.g), absf(c.b - h.b))))
	return worst


## The worst change in any second (60 frames) of each band's luminance and of their weighted mean: [band, mean].
static func _worst_second(lums: Array) -> Array:
	var wb: float = 0.0
	var wm: float = 0.0
	for i in range(60, lums.size()):
		var a: Array = lums[i - 60]
		var b: Array = lums[i]
		for k in range(4):
			wb = maxf(wb, absf(float(b[k]) - float(a[k])))
		wm = maxf(wm, absf(SkyDrive.mean_of(b) - SkyDrive.mean_of(a)))
	return [wb, wm]


func _dynamic(S: SimState) -> void:
	var host: SimHost = main.host
	var sky: SkyDrive = host.sky
	var W: float = SimConst.W
	# The start: one frame as the game draws it.
	main.frame(1.0 / 60.0)
	var m: ShaderMaterial = main.pane._sky_mat
	var same: bool = SkyDrive.ok
	for i in range(4):
		same = same and m.get_shader_parameter(["sky_top", "sky_upper", "sky_lower", "sky_horizon"][i]) == RenderLook.col(RenderLook.SKY[i])
	var at: int = SkyDrive.key_at(sky.target(main.view_cam_x))
	_expect(same and float(m.get_shader_parameter("star_low")) == 0.25 and at >= 0 and str(SkyDrive.keys[at].id) == "sunset", "at a match's start the sky is the sunset key to the bit: the four colours and the stars' strength it always had (data read: %s)" % SkyDrive.ok)
	# Every key on its place, and the port against Art's reference.
	var x_of: Callable = func(phase: float) -> float: return SimWrap.wrap(sky.spawn_x + (phase - SkyDrive.start_phase) * W)
	var keys_ok: bool = SkyDrive.keys.size() == 5
	for k in SkyDrive.keys:
		var o: Dictionary = sky.pane({}, x_of.call(float(k.phase)), 0.0)
		keys_ok = keys_ok and o.cols == k.cols and absf(float(o.star_low) - minf(1.0, 0.25 * float(k.stars) / 0.15)) < 1e-9
	_expect(keys_ok, "each of the %d keys is its own colours on its place of the lap, and the stars follow the key" % SkyDrive.keys.size())
	var worst: float = 0.0
	for ph in REF.keys():
		worst = maxf(worst, _off(sky.pane({}, x_of.call(float(ph)), 0.0).cols, REF[ph]))
	var worst_mood: float = 0.0
	for r in REF_MOOD:
		sky.frenzy = float(r[1])
		sky.ruin = float(r[2])
		worst_mood = maxf(worst_mood, _off(sky.pane({}, x_of.call(float(r[0])), 0.0).cols, r[3]))
	sky.frenzy = 0.0
	sky.ruin = 0.0
	_expect(worst <= 1.5 and worst_mood <= 1.5, "between the keys and at the mood's extremes the port agrees with Art's reference code (off by %.2f and %.2f of 255 at most)" % [worst, worst_mood])
	var p: float = SkyDrive.start_phase
	var moved: float = 0.0
	var n: int = 0
	while moved < 1.0 and n < 60 * 400:
		var q: float = SkyDrive.slew(p, fposmod(p + 0.4, 1.0), 1.0 / 60.0)
		moved += fposmod(q - p, 1.0)
		p = q
		n += 1
	_expect(absf(float(n) / 60.0 - REF_LAP_S) < 1.0, "one lap at the limit takes %.1f s (the reference: %.1f)" % [float(n) / 60.0, REF_LAP_S])
	# Nothing fast. The camera flies a quarter of a lap a second and turns back every 3 seconds, for 3 minutes.
	var st: Dictionary = {}
	var lums: Array = []
	var x: float = sky.spawn_x
	for i in range(180 * 60):
		var t: float = float(i) / 60.0
		x = SimWrap.wrap(x + (0.25 * W / 60.0) * (1.0 if int(t / 3.0) % 2 == 0 else -1.0))
		var o: Dictionary = sky.pane(st, x, t)
		lums.append(o.cols.map(func(c): return SkyDrive.lum_of(c)))
	var w1: Array = _worst_second(lums)
	_expect(w1[0] <= SkyDrive.place_band + 1e-4 and w1[1] <= SkyDrive.place_mean + 1e-4, "the place alone, under that drive: no band changes by more than %.3f in a second (worst %.4f) and their mean by no more than %.3f (%.4f)" % [SkyDrive.place_band, w1[0], SkyDrive.place_mean, w1[1]])
	# The same with the mood and the damage slammed on and off (the tool's own match), then a driver that jumps.
	sky.reset(S)
	st = {}
	lums = []
	x = sky.spawn_x
	for i in range(180 * 60):
		var t: float = float(i) / 60.0
		x = SimWrap.wrap(x + (0.25 * W / 60.0) * (1.0 if int(t / 3.0) % 2 == 0 else -1.0))
		S.mood.band = 2 if int(t / 7.0) % 2 == 0 else 0
		S.world.casualties = S.world.pop0 if int(t / 11.0) % 2 == 0 else 0.0
		S.world.structuresLost = float(S.buildings.size()) if int(t / 11.0) % 2 == 0 else 0.0
		sky.advance(S, t)
		if i > 90 * 60 and i % 300 == 0:   # a driver this file did not foresee: the mood jumps
			sky.frenzy = 1.0 - sky.frenzy
			sky.ruin = 1.0 - sky.ruin
		var o: Dictionary = sky.pane(st, x, t)
		lums.append(o.cols.map(func(c): return SkyDrive.lum_of(c)))
	var w2: Array = _worst_second(lums)
	_expect(w2[0] <= SkyDrive.total_band + 1e-4 and w2[1] <= SkyDrive.total_mean + 1e-4, "with the mood and the damage slammed on and off, and a driver that jumps: no band changes by more than %.2f in a second (worst %.4f) and their mean by no more than %.2f (%.4f)" % [SkyDrive.total_band, w2[0], SkyDrive.total_mean, w2[1]])
	# The mood's least durations, and reduced motion.
	S.mood.band = 2
	S.world.casualties = S.world.pop0
	S.world.structuresLost = float(S.buildings.size())
	for b in S.buildings:
		b.alive = false
	sky.reset(S)
	var reached: Array = [-1.0, -1.0, -1.0]
	for i in range(130 * 60):
		var t: float = float(i) / 60.0
		sky.advance(S, t)
		if reached[0] < 0.0 and sky.frenzy >= 1.0:
			reached[0] = t
		if reached[1] < 0.0 and sky.ruin >= 1.0:
			reached[1] = t
		if reached[2] < 0.0 and not sky.towns.is_empty() and float(sky.towns[0].glow) >= 1.0:
			reached[2] = t
	_expect(reached[0] >= 30.0 - 0.05 and reached[0] < 31.0 and reached[1] >= 120.0 - 0.05 and reached[1] < 121.0 and reached[2] >= 50.0 - 0.05 and reached[2] < 51.5, "asked for all at once, frenzy is full after %.1f s, ruin after %.1f s and a wrecked town's glow after %.1f s (Art's least: 30, 120, 50); %d towns" % [reached[0], reached[1], reached[2], sky.towns.size()])
	sky.reset(S)
	sky.calm = true
	for i in range(60 * 60):
		sky.advance(S, float(i) / 60.0)
	var held: bool = sky.drift == 0.0 and sky.frenzy == 0.0 and sky.ruin == 0.0
	var st2: Dictionary = {}
	sky.pane(st2, sky.spawn_x, 0.0)
	sky.pane(st2, SimWrap.wrap(sky.spawn_x + 0.2 * W), 0.1)
	_expect(held and float(st2.p) != SkyDrive.start_phase, "with reduced motion the drift and the mood hold, and the place blend stays")
	sky.calm = false
	sky.advance(S, 3601.0 / 60.0)
	var d0: float = sky.drift
	sky.advance(S, 3601.0 / 60.0 + 0.5)
	_expect(d0 > 0.0 and absf(sky.drift - d0 - 0.5 * 0.0125 / 60.0) < 1e-9, "without it the sky drifts %.4f of a cycle a minute" % (SkyDrive.drift_per_s * 60.0))
	# The switches.
	sky.reset(S)
	sky.still = true
	var t_still: float = sky.target(SimWrap.wrap(sky.spawn_x + 0.4 * W))
	sky.still = false
	sky.hold_phase = 0.58
	var o_hold: Dictionary = sky.pane({}, sky.spawn_x, 0.0)
	sky.hold_phase = NAN
	var names: bool = main.URL_ARGS.has("staticsky") and main.URL_ARGS.has("sky") and main.URL_ARGS.has("skymood")
	_expect(t_still == SkyDrive.start_phase and o_hold.cols == SkyDrive.keys[3].cols and names, "--staticsky keeps the sunset everywhere, --sky holds a key (night's colours at the spawn), and the web page's URL may name them")
	# What a pane's sky costs a frame, while it is moving (the dearest case).
	st = {}
	x = sky.spawn_x
	sky.frenzy = 0.5
	var t0: int = Time.get_ticks_usec()
	for i in range(20000):
		x = SimWrap.wrap(x + 0.25 * W / 60.0)
		sky.frenzy = 0.5 + 0.4 * sin(float(i) * 0.001)
		sky.pane(st, x, float(i) / 60.0)
	var us: float = float(Time.get_ticks_usec() - t0) / 20000.0
	sky.frenzy = 0.0
	S.mood.band = 0
	S.world.casualties = 0.0
	S.world.structuresLost = 0.0
	for b in S.buildings:
		b.alive = true
	sky.reset(S)
	var st3: Dictionary = {}
	var worked: int = 0
	for i in range(600):   # ten seconds standing at the spawn: only the drift moves the sky
		sky.advance(S, 400.0 + float(i) / 60.0)
		if sky.pane(st3, sky.spawn_x, 400.0 + float(i) / 60.0).changed:
			worked += 1
	_expect(us < 400.0 and worked < 200, "a pane's sky costs %.0f microseconds a frame while it moves, on this machine, and is worked out on %d frames of 600 while it stands" % [us, worked])
	sky.reset(S)


## What the pane hands the sky shader for the two fighters at tiers ta and tb: the reaction's two weights, then the
## shader's cloud_part and cloud_shift. look 0 frames the point between them, 1 frames fighter A.
func _handed(S: SimState, ta: float, tb: float, vp: Vector2, look: int) -> Array:
	S.fighters[0].tier = ta
	S.fighters[1].tier = tb
	var zoom: float = 0.6
	var cam_x: float = S.fighters[0].x if look == 1 else SimWrap.wrap(S.fighters[0].x + SimWrap.sdx(S.fighters[0].x, S.fighters[1].x) * 0.5)
	main.pane._react_t = -1.0   # the reaction snaps to its value: no tick runs here
	main.pane.render(main.host, 1.0, cam_x, Vector3(0.0, S.fighters[0].y + 45.0 + 150.0 / zoom - 0.2 * vp.y / zoom, zoom), Vector2.ZERO)
	var m: ShaderMaterial = main.pane._sky_mat
	var r: Array = m.get_shader_parameter("sky_react")
	return [float(r[0].w), float(r[1].w), float(m.get_shader_parameter("cloud_part")), float(m.get_shader_parameter("cloud_shift"))]


func _numbers(S: SimState, vp: Vector2) -> void:
	var x0: float = 0.0
	for c in range(0, SimConst.NC, SimConst.NC / 12):
		x0 = float(c) * SimConst.COL
		if c > 0 and WorldWater.surfaceAt(S, x0) <= WorldTerrain.groundY(S, x0) + 0.5:
			break
	# main's switch: off unless --skyreact is given (the tool's own main has no such argument).
	main.frame(0.0)
	_expect(not PaneWorld.sky_react_on, "by default the reaction is off (main, with no --skyreact)")
	main.args["skyreact"] = "1"
	main.frame(0.0)
	_expect(PaneWorld.sky_react_on, "--skyreact turns it on")
	main.args.erase("skyreact")
	main.frame(0.0)
	_expect(not PaneWorld.sky_react_on and main.URL_ARGS.has("skyreact"), "... and off again without it; the web page's URL may name it")
	for lift in [0.0, 3000.0, 9000.0]:
		var cam_name: String = "camera %d up" % int(lift)
		_pose(S, x0, 260.0, lift, vp)
		PaneWorld.sky_react_on = false
		var off: Array = _handed(S, 4.0, 4.0, vp, 0)
		_expect(off[0] == 0.0 and off[1] == 0.0 and off[2] == 0.0, "%s, default: nothing parts at tier 4 (weights %.2f %.2f, parting %.0f)" % [cam_name, off[0], off[1], off[2]])
		PaneWorld.sky_react_on = true
		var on4: Array = _handed(S, 4.0, 4.0, vp, 0)
		_expect(on4[0] > 0.99 and on4[1] > 0.99 and on4[2] == 1.0, "%s, reaction on: full at tier 4 (%.2f %.2f)" % [cam_name, on4[0], on4[1]])
		var on3: Array = _handed(S, 3.0, 1.0, vp, 0)
		_expect(absf(on3[0] - 0.5) < 0.01 and on3[1] == 0.0, "%s, reaction on: half at tier 3, nothing at tier 1 (%.2f %.2f)" % [cam_name, on3[0], on3[1]])
		PaneWorld.sky_calm = true
		var calm: Array = _handed(S, 4.0, 4.0, vp, 0)
		PaneWorld.sky_calm = false
		_expect(calm[2] == 0.0, "%s, reaction on: with reduced motion the shader's parting is off" % cam_name)
		_pose(S, x0, 1500.0, lift, vp)
		var far: Array = _handed(S, 1.0, 4.0, vp, 1)
		_expect(far[0] == 0.0 and far[1] == 0.0, "%s, reaction on: nothing for a tier 4 fighter off the screen (%.2f %.2f)" % [cam_name, far[0], far[1]])
		PaneWorld.sky_react_on = false
	# The pattern's place: the same camera travel is the same step everywhere, across the planet's seam too.
	var step: float = RenderLook.CLOUD_PERIOD / SimConst.W
	var worst: float = 0.0
	for x in [1.0, 2400.0, SimConst.W - 1.0, SimConst.W - 0.001]:
		_pose(S, x, 0.0, 3000.0, vp)
		var a: float = float(_handed(S, 1.0, 1.0, vp, 1)[3])
		_pose(S, SimWrap.wrap(x + 2.0), 0.0, 3000.0, vp)
		var b: float = float(_handed(S, 1.0, 1.0, vp, 1)[3])
		worst = maxf(worst, absf(fposmod(b - a + 0.5 * RenderLook.CLOUD_PERIOD, RenderLook.CLOUD_PERIOD) - 0.5 * RenderLook.CLOUD_PERIOD - 2.0 * step))
	_expect(worst < 1e-5, "the cloud pattern moves the same for the same camera travel, across the planet's seam too (worst error %.7f cells)" % worst)
	_pose(S, x0, 260.0, 3000.0, vp)
	PaneWorld.sky_calm = true
	var still: float = float(_handed(S, 1.0, 1.0, vp, 1)[3])
	PaneWorld.sky_calm = false
	_expect(absf(still - SimWrap.wrap(S.fighters[0].x) * step) < 1e-5, "with reduced motion the clouds stand still (no wind in the pattern's place)")


## The pictures, with the reaction on (see the header).
func _pictures(S: SimState, vp: Vector2) -> void:
	var seen: float = 0.0
	# Places round the planet with dry ground under both fighters, so the clouds differ from place to place.
	var places: Array = []
	for c in range(0, SimConst.NC, SimConst.NC / 12):
		var x: float = float(c) * SimConst.COL
		if WorldWater.surfaceAt(S, x) <= WorldTerrain.groundY(S, x) + 0.5:
			places.append(x)
	for lift in [0.0, 3000.0]:
		var cam_name: String = "high" if lift > 0.0 else "low"
		var worst_off: float = 0.0
		var worst_low: float = 0.0
		var worst_far: float = 0.0
		var worst_calm: float = 0.0
		var most: float = 0.0
		for x0 in places:
			# Both on the screen.
			_pose(S, x0, 260.0, lift, vp)
			PaneWorld.clouds_on = false
			var off1: Image = await _sky(S, 1.0, 1.0, vp, 0)
			var off4: Image = await _sky(S, 4.0, 4.0, vp, 0)
			var top: int = _horizon_row(off1)
			var low: Rect2i = _low_band(top, vp)
			worst_off = maxf(worst_off, _peak(off1, off4, Rect2i(0, 0, int(vp.x), top)))
			PaneWorld.clouds_on = true
			var on1: Image = await _sky(S, 1.0, 1.0, vp, 0)
			var on4: Image = await _sky(S, 4.0, 4.0, vp, 0)
			var d: float = _peak(on1, on4, Rect2i(0, 0, int(vp.x), top))
			if d > most:
				most = d
				if out != "":
					on1.save_png("%s/sky-check-%s-tier1.png" % [out, cam_name])
					on4.save_png("%s/sky-check-%s-tier4.png" % [out, cam_name])
			if low.size.y > 0:
				worst_low = maxf(worst_low, _peak(on1, on4, low))
			PaneWorld.sky_calm = true
			var calm4: Image = await _sky(S, 4.0, 4.0, vp, 0)
			PaneWorld.sky_calm = false
			worst_calm = maxf(worst_calm, _peak(on1, calm4, Rect2i(0, 0, int(vp.x), top)))
			# Fighter B far off the screen, the camera on A at tier 1: B at tier 4 must change nothing.
			_pose(S, x0, 1500.0, lift, vp)
			var far1: Image = await _sky(S, 1.0, 1.0, vp, 1)
			var far4: Image = await _sky(S, 1.0, 4.0, vp, 1)
			worst_far = maxf(worst_far, _peak(far1, far4, Rect2i(0, 0, int(vp.x), int(vp.y))))
		seen = maxf(seen, most)
		_expect(worst_off <= SAME, "%s camera, clouds off: tier 4 draws nothing in the sky (%.0f of 255 at most, %d places)" % [cam_name, worst_off, places.size()])
		_expect(worst_low <= SAME, "%s camera: the last of the band above the horizon is left alone (%.0f)" % [cam_name, worst_low])
		_expect(worst_far <= SAME, "%s camera: a tier 4 fighter off the screen changes nothing (%.0f)" % [cam_name, worst_far])
		_expect(worst_calm <= SAME, "%s camera: with reduced motion nothing parts (%.0f)" % [cam_name, worst_calm])
		_expect(most >= SEEN, "%s camera: the clouds do part somewhere (%.0f of 255 at the most changed place)" % [cam_name, most])


## Both fighters at a place, `half` either side of it, `lift` above the ground.
func _pose(S: SimState, x0: float, half: float, lift: float, vp: Vector2) -> void:
	for i in range(2):
		var f = S.fighters[i]
		f.x = SimWrap.wrap(x0 + (-half if i == 0 else half))
		f.y = WorldTerrain.groundY(S, f.x) + 2.0 + lift
		f.z = 0.0
	for k in range(3):
		main.host.follow(vp.x, vp.y)


## The picture with the two tiers set; look 0 frames the point between the fighters, 1 frames fighter A.
func _sky(S: SimState, ta: float, tb: float, vp: Vector2, look: int) -> Image:
	S.fighters[0].tier = ta
	S.fighters[1].tier = tb
	var zoom: float = 0.6
	var cam_x: float = S.fighters[0].x if look == 1 else SimWrap.wrap(S.fighters[0].x + SimWrap.sdx(S.fighters[0].x, S.fighters[1].x) * 0.5)
	var cam := Vector3(0.0, S.fighters[0].y + 45.0 + 150.0 / zoom - 0.2 * vp.y / zoom, zoom)
	for k in range(2):
		main.pane.snap_occlusion()
		main.pane.render(main.host, 1.0, cam_x, cam, Vector2.ZERO)
		await RenderingServer.frame_post_draw
	return main.get_viewport().get_texture().get_image()


## The screen row of the sky's horizon line in a picture drawn with the planet hidden: below the line the sky is one
## colour (the horizon's), so it is the first row from the bottom, in the middle column, that is not.
static func _horizon_row(img: Image) -> int:
	var x: int = img.get_width() / 2
	var c0: Color = img.get_pixel(x, img.get_height() - 2)
	for y in range(img.get_height() - 3, 0, -1):
		var c: Color = img.get_pixel(x, y)
		if absf(c.r - c0.r) + absf(c.g - c0.g) + absf(c.b - c0.b) > 0.012:
			return y
	return 0


## The rows of the cloud band's last 0.09 above the horizon (the reaction begins at 0.14), in the middle half of the
## screen: a row is one height only near the screen's middle, since a line of equal elevation curves at the sides.
func _low_band(horizon_row: int, vp: Vector2) -> Rect2i:
	var m: ShaderMaterial = main.pane._sky_mat
	var thin: float = 1.0 + float(m.get_shader_parameter("sky_thin")) * float(m.get_shader_parameter("space"))
	var rows: int = int(0.09 * vp.y * 0.5 / thin)
	var top: int = maxi(0, horizon_row - rows)
	return Rect2i(int(vp.x * 0.25), top, int(vp.x * 0.5), horizon_row - top)


static func _peak(a: Image, b: Image, r: Rect2i) -> float:
	if r.size.x <= 0 or r.size.y <= 0:
		return 0.0
	return float(a.get_region(r).compute_image_metrics(b.get_region(r), false)["max"])
