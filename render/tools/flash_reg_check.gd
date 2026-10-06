extends SceneTree
## Flash register check (headless): every full flash Rendering draws asks VFX's shared flash register first
## (docs/rendering/flash-sources.md; docs/legal/photosensitivity-note.md). The register weighs a flash by the area it
## covers (docs/vfx/flash-registry.md): in any 60 ticks the granted weights sum to at most 2.5 (1.0 under reduced
## flashing), the low class's to at most 1.5 (none), with at most 3 flashes of half weight or more (1) and 6 of any
## weight (3); nothing red. Through the real main scene:
## - three AI matches of 3,600 ticks, in Camera's split screen as the game runs it: those four limits hold in every
##   second of the register's log, Rendering's, VFX's and the split divider's slam flash together;
## - a mash: one fighter is hit every 6 ticks for 4 seconds (the tool sets the hit's time on its own match). The
##   body whitens no more often than its weight allows, the other hits light the outline, and the limits hold;
## - the same mash with UI's Reduce flashing option on (main passes it to the register every frame): the body never
##   whitens, and the reduced limits hold;
## - the camera's scale reaches the register every frame, and Rendering's sources are weighed by what they cover;
## - the weighted rule through the host's ask: the low class's share, a guard flash taking what the low class may
##   not, the budget, a step too small to count, the two count ceilings, red refused;
## - a head flash's pulses: each swell asks; with none granted it shows once, calm;
## - UI's Reduce flashing option: the register is in its reduced mode, Rendering's low sources get nothing and its big
##   ones one a second between them; a groove's glow and char are drawn calm;
## - the divider's slam flash: the HUD's flash_fn is the host's and answers by the register (all or none);
## - Controls' two charge settings go from UI's options to the hub, a player at a time (once the hub has them);
## - a beam and a clash come and go once (one rise, one fall, nothing in between), a new beam asks the register, and
##   under reduced flashing it does not ask and is drawn calm;
## - the pan haze (off unless switched on): none at a slow pan, full within a tenth of a second of a fast one, cleared
##   after it, unmoved by a cut, and none with its switch off.
##   godot --headless --path . --script res://render/tools/flash_reg_check.gd -- [--seeds=12345,4,7] [--ticks=3600]

var seeds: Array = [12345, 4, 7]
var ticks: int = 3600
var main: Node
var fails: int = 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
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


## The worst of the register's log in any 60 ticks, for its four limits: [the granted weights' sum, the low class's
## sum, the flashes of half weight or more, the flashes of any weight]. Rows are VfxFlashRegistry.log_rows().
static func _worst_window(rows: Array) -> Array:
	var ev: Array = []
	for r in rows:
		if bool(r[3]) and str(r[4]) != "below_step":
			ev.append([int(r[0]), float(r[6]), VfxFlashRegistry.LOW.has(str(r[2]))])
	var out: Array = [0.0, 0.0, 0, 0]
	for i in range(ev.size()):
		var sum: float = 0.0
		var low: float = 0.0
		var big: int = 0
		var n: int = 0
		for j in range(i, ev.size()):
			if int(ev[j][0]) >= int(ev[i][0]) + VfxFlashRegistry.WINDOW:
				break
			sum += float(ev[j][1])
			low += float(ev[j][1]) if bool(ev[j][2]) else 0.0
			big += 1 if float(ev[j][1]) >= VfxFlashRegistry.BIG_W else 0
			n += 1
		out = [maxf(out[0], sum), maxf(out[1], low), maxi(out[2], big), maxi(out[3], n)]
	return out


## Whether a worst window is inside the register's limits (the reduced ones under reduced flashing).
static func _within(w: Array, reduced: bool) -> bool:
	var R := VfxFlashRegistry
	return float(w[0]) <= (R.BUDGET_REDUCED if reduced else R.BUDGET) + 0.001 and float(w[1]) <= (0.0 if reduced else R.LOW_BUDGET) + 0.001 \
		and int(w[2]) <= (R.BIG_CAP_REDUCED if reduced else R.BIG_CAP) and int(w[3]) <= (R.RATE_CAP_REDUCED if reduced else R.RATE_CAP)


## The most of `at` (tick numbers, ascending) inside any window of 60 ticks.
static func _worst(at: Array) -> int:
	var best: int = 0
	for i in range(at.size()):
		var k: int = 0
		for j in range(i, at.size()):
			if int(at[j]) < int(at[i]) + 60:
				k += 1
			else:
				break
		best = maxi(best, k)
	return best


## How many times a series changes direction (flat steps are neither).
static func _turns(v: Array) -> int:
	var n: int = 0
	var last: int = 0
	for i in range(1, v.size()):
		var d: int = signi(int(signf(float(v[i]) - float(v[i - 1]))))
		if d != 0:
			if last != 0 and d != last:
				n += 1
			last = d
	return n


## A beam put into the tool's own match for one ask: [how many times `beam` was asked of the register, whether its
## bright form was granted, the weight it was asked with, the weight its area should give at this camera's scale]. It is
## taken out again before the sim steps.
func _beam_asks(host: SimHost) -> Array:
	var before: int = _rows_of(host, "beam")
	var b := SimState.Beam.new()
	b.A = host.S.fighters[0]
	b.col = host.S.fighters[0].aura
	b.len = 3000.0
	b.w = 33.0
	host.S.beams.append(b)
	host._ask_beams()
	var rows: Array = host.vfx.flashes.log_rows()
	var res: Array = [_rows_of(host, "beam") - before, host.beam_flash(b), float(rows[-1][6]) if _rows_of(host, "beam") > before else 0.0, host.vfx.flashes.weight_of("beam", host.beam_px(b.len, b.w))]
	host.S.beams.erase(b)
	host._ask_beams()
	return res


func _rows_of(host: SimHost, source: String) -> int:
	var n: int = 0
	for row in host.vfx.flashes.log_rows():
		if str(row[2]) == source:
			n += 1
	return n


func _run() -> void:
	await process_frame
	main.started = true
	var host: SimHost = main.host
	var cyan := Color(0.4, 0.8, 1.0)
	# 1. Real matches, in the split screen (a tool's main has one view until a compositor is attached): UI's divider
	# flashes when a slam shuts the split, and asks the register through the host.
	var view := SplitView.new()
	main.add_child(view)
	view.attach(main)
	for seed in seeds:
		main.start_match(seed, {"p1": true, "p2": true})
		var reg: VfxFlashRegistry = host.vfx.flashes
		var slams: int = 0
		var slam_was: float = 0.0
		while host.ticks < ticks:
			main.frame(1.0 / 60.0)
			var slam_now: float = float(main._split_record().get("slam", 0.0))
			if slam_now > 0.5 and slam_was <= 0.5:
				slams += 1
			slam_was = slam_now
		var sm: Dictionary = reg.summary()
		var mine: Array = []
		for src in ["body_hit", "head_flash", "guard_flash", "cue_flare", "beam", "beam_clash"]:
			mine.append("%s %d and %d" % [src, int(sm.granted_by.get(src, 0)), int(sm.refused_by.get(src, 0))])
		var ww: Array = _worst_window(reg.log_rows())
		_expect(_within(ww, false) and float(sm.worst_weight_running) <= VfxFlashRegistry.BUDGET + 0.001 and reg.log.size() < VfxFlashRegistry.LOG_MAX, "seed %d, %d ticks: in every second the granted weights sum to at most 2.5 (worst %.2f) and the low class's to 1.5 (%.2f), with at most 3 flashes of half weight or more (%d) and 6 of any (%d); %d granted, %d refused" % [seed, host.ticks, ww[0], ww[1], ww[2], ww[3], int(sm.granted), int(sm.refused)])
		print("     Rendering's, granted and refused: %s" % "; ".join(mine))
		print("     the divider's slam flash (UI's): %d slams, %d granted and %d refused" % [slams, int(sm.granted_by.get("divider_slam", 0)), int(sm.refused_by.get("divider_slam", 0))])
	view.detach()   # one view for the rest, as after F9 (the panes stay in the compositor's viewports, so it stays in the tree)
	# 2 and 3. A mash on fighter 1, then the same under reduced flashing.
	for reduced in [false, true]:
		main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
		main.ui_hud.set_option("reduce_flashing", reduced)   # UI's option: main gives it to the register every frame
		var S: SimState = host.S
		var v: FighterView = main.pane.fighter_views[1]
		var white_at: Array = []     # the ticks the body turned white
		var edges: int = 0           # frames the outline was lit instead
		var hits: int = 0
		var was: bool = false
		for k in range(240):
			if k % 6 == 0:
				S.fighters[1].hurtT = S.T   # the tool's own match: a hit lands now
				hits += 1
			main.frame(1.0 / 60.0)
			if v._flash and not was:
				white_at.append(host.ticks)
			was = v._flash
			if v._edge:
				edges += 1
		main.ui_hud.set_option("reduce_flashing", false)
		var w2: Array = _worst_window(host.vfx.flashes.log_rows())
		if reduced:
			_expect(white_at.is_empty() and edges > 0 and _within(w2, true), "UI's Reduce flashing on, %d hits in 4 seconds: the body never whitens, the outline lights (%d frames), and the reduced limits hold (weights %.2f, %d flashes in the worst second)" % [hits, edges, w2[0], w2[3]])
		else:
			# A body's white is weighed by its size on the screen: it may whiten as often as the low class's share and the count ceiling allow.
			var wb: float = host.vfx.flashes.weight_of("body_hit", host.flash_px(RenderLook.FLASH_BODY_AREA * FighterView.HEIGHT * FighterView.HEIGHT))
			var may: int = mini(VfxFlashRegistry.RATE_CAP, int(floor(VfxFlashRegistry.LOW_BUDGET / maxf(wb, 0.001) + 0.001)))
			_expect(_worst(white_at) <= may and white_at.size() > 0 and white_at.size() < hits, "a mash, %d hits in 4 seconds: the body whitens %d times, never more than its weight allows in a second (%d of %d at weight %.2f)" % [hits, white_at.size(), _worst(white_at), may, wb])
			_expect(edges > 0 and _within(w2, false), "... the other hits light the outline (%d frames), and the limits hold (weights %.2f, %d flashes in the worst second)" % [edges, w2[0], w2[3]])
	# 4. The rule for Rendering's sources, on a fresh register.
	main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
	main.frame(1.0 / 60.0)
	# The camera's scale reaches the register, and Rendering's sources are weighed by what they cover.
	var reg4: VfxFlashRegistry = host.vfx.flashes
	var want_ppu: float = 768.0 * float(host.camera(1.0).z) / 720.0
	_expect(absf(host.vfx.px_per_unit - want_ppu) < 0.05 * want_ppu and is_equal_approx(reg4.ppu, host.vfx.px_per_unit), "the camera's scale reaches the register every frame: %.2f pixels a world unit at 1024 by 768 (the reference camera's %.2f)" % [reg4.ppu, want_ppu])
	var ppu_was: float = reg4.ppu
	reg4.ppu = 1.3   # the close framing VFX's own estimates are for
	var wts: Array = [reg4.weight_of("body_hit", host.flash_px(RenderLook.FLASH_BODY_AREA * FighterView.HEIGHT * FighterView.HEIGHT)), reg4.weight_of("head_flash", host.flash_px(PI * RenderLook.FLASH_HEAD_R * RenderLook.FLASH_HEAD_R)),
		reg4.weight_of("guard_flash", host.flash_px(RenderLook.GUARD_SIZE.x * RenderLook.GUARD_SIZE.y * RenderLook.FLASH_GUARD_FILL)), reg4.weight_of("beam", host.beam_px(3000.0, 60.0)), reg4.weight_of("beam", host.beam_px(3000.0, 33.0) * 0.0 + host.beam_px(40.0, 33.0))]
	reg4.ppu = 0.3   # a wide framing: the same beam is a thin strip
	var w_far: float = reg4.weight_of("beam", host.beam_px(3000.0, 33.0))
	reg4.ppu = ppu_was
	_expect(absf(wts[0] - 0.17) < 0.03 and absf(wts[1] - 0.07) < 0.02 and absf(wts[2] - 0.2) < 0.03 and wts[3] == 1.0 and wts[4] < 0.2 and w_far < 0.3, "at the close framing a body's white weighs %.2f, a head flash %.2f and a guard flash %.2f (VFX's estimates: 0.17, 0.07, 0.2); a tier 4 beam weighs %.0f, a short one %.2f, and a beam seen from far %.2f" % [wts[0], wts[1], wts[2], wts[3], wts[4], w_far])
	# The weighted rule through the host's ask, with areas given (A is a full-weight area; the register's clock is stepped by hand so the match adds nothing).
	var A: float = VfxFlashRegistry.AREA_FULL
	var a: bool = host.ask_flash("cue_flare", cyan, A, 0.5)             # low, weight 1
	var b: bool = host.ask_flash("body_hit", Color.WHITE, A, 0.5)       # low, weight 1: over the low class's 1.5
	var c: bool = host.ask_flash("head_flash", cyan, 0.5 * A, 0.5)      # low, weight 0.5: the low class is now full
	var d: bool = host.ask_flash("body_hit", Color.WHITE, 0.05 * A, 0.5)   # low, weight 0.05: refused
	var e: bool = host.ask_flash("guard_flash", cyan, 0.5 * A, 0.25)    # not low: it takes what the low class may not (sum 2.0)
	var f: bool = host.ask_flash("beam", cyan, A, 0.6)                  # weight 1: over the budget of 2.5
	var sum0: float = reg4.sum_in_window()
	var g: bool = host.ask_flash("beam", cyan, A, 0.05)                 # a step under a tenth: not a flash, costs nothing
	_expect(a and not b and c and not d and e and not f and g and is_equal_approx(sum0, 2.0) and is_equal_approx(reg4.sum_in_window(), 2.0), "by weight: the low class takes 1.5 and no more, a perfect block's guard flash takes what the low class may not, a full flash over the budget of 2.5 is refused, and a step under a tenth costs nothing (%s %s %s %s %s %s %s; the second holds %.1f)" % [a, b, c, d, e, f, g, reg4.sum_in_window()])
	for k in range(61):
		reg4.begin_tick(false)
	var small: Array = []
	for k in range(7):
		small.append(host.ask_flash("guard_flash", cyan, 0.1 * A, 0.25))
	for k in range(61):
		reg4.begin_tick(false)
	var big: Array = []
	for k in range(4):
		big.append(host.ask_flash("guard_flash", cyan, 0.5 * A, 0.25))
	_expect(small == [true, true, true, true, true, true, false] and big == [true, true, true, false], "by count: six small flashes in a second and no seventh; three of half weight or more and no fourth (%s, %s)" % [str(small), str(big)])
	for k in range(61):
		reg4.begin_tick(false)
	_expect(not host.ask_flash("cue_flare", Color(1.0, 0.2, 0.15), 0.2 * A, 0.5) and host.ask_flash("cue_flare", cyan, 0.2 * A, 0.5), "a red flare is refused and a cyan one is granted")
	var low_ok: bool = true
	for src in ["body_hit", "head_flash", "cue_flare"]:
		low_ok = low_ok and VfxFlashRegistry.LOW.has(src)
	_expect(low_ok and VfxFlashRegistry.LOW.has("divider_slam") and not VfxFlashRegistry.LOW.has("guard_flash") and not VfxFlashRegistry.LOW.has("beam"), "the register lists the body's white, head flashes, cue flares and the divider's slam as low, and not the guard flash or a beam")
	# 5. A head flash's pulses.
	var fv: FlashView = main.pane.fighter_views[0].flash_view
	var asked: Array = []
	fv.pulses_fn = func(n: int, _col: Color) -> int:
		asked.append(n)
		return 0
	fv._start("danger", host.S.T, NAN)
	_expect(asked == [3] and fv._calm() and fv._pulses() == 1, "a head flash asks for each of its pulses (%s); with none granted it shows once, calm" % str(asked))
	fv._end()
	fv.pulses_fn = func(_n: int, _col: Color) -> int: return 2
	fv._start("danger", host.S.T + 10.0, NAN)
	_expect(not fv._calm() and fv._pulses() == 2, "with two of three granted it swells twice")
	fv._end()
	fv.pulses_fn = main._flash_pulses
	# 6. UI's Reduce flashing option puts the register in its reduced mode, and Rendering's sources obey it.
	main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
	main.ui_hud.set_option("reduce_flashing", true)
	for k in range(3):
		main.frame(1.0 / 60.0)
	var r_on: bool = host.vfx.reduced_flashing and host.vfx.flashes.reduced
	var tm: ShaderMaterial = main.pane.planet._terrain_mat
	var calm_on: Array = [tm.get_shader_parameter("heat_gain"), tm.get_shader_parameter("char_gain")]
	var low_none: bool = not host.ask_flash("body_hit") and not host.ask_flash("head_flash", cyan) and not host.ask_flash("cue_flare", cyan)
	var big_one: bool = host.ask_flash("guard_flash", cyan) and not host.ask_flash("beam", cyan) and not host.ask_flash("beam_clash")
	_expect(r_on and low_none and big_one, "UI's Reduce flashing option puts the register in its reduced mode: no body white, head flash or cue flare, and one big flash a second (a guard flash granted, then a beam and a clash refused)")
	main.ui_hud.set_option("reduce_flashing", false)
	for k in range(3):
		main.frame(1.0 / 60.0)
	_expect(not host.vfx.reduced_flashing and not host.vfx.flashes.reduced, "... and the register is back to its full budget with the option off")
	_expect(calm_on == [RenderLook.HEAT_CALM, RenderLook.CHAR_CALM] and tm.get_shader_parameter("heat_gain") == 1.0 and tm.get_shader_parameter("char_gain") == 1.0, "under it a groove's glow and char are drawn calm (%s of their strength), and at full strength again with it off" % str(calm_on))
	# 7. The split divider's slam flash (UI draws it and asks once as a slam begins): the HUD's flash_fn is the host's.
	main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
	main.frame(1.0 / 60.0)
	var hf: Callable = main.ui_hud.flash_fn
	var s_room: float = float(hf.call("divider_slam", 0.9, 0.02)) if hf.is_valid() else -1.0
	host.ask_flash("beam", cyan)
	host.ask_flash("beam", cyan)
	var s_full: float = float(hf.call("divider_slam", 0.9, 0.02)) if hf.is_valid() else -1.0
	var logged: int = 0
	for row in host.vfx.flashes.log_rows():
		if str(row[2]) == "divider_slam":
			logged += 1
	_expect(s_room == 1.0 and s_full == 0.0 and logged == 2, "the divider's slam flash asks the register through the HUD's flash_fn: all of it with room in the second, none with the second full (%.1f, %.1f); both asks are in the register's log" % [s_room, s_full])
	# 8. Controls' two charge settings, from UI's options to the hub, a player at a time.
	var hub: Object = host.hub
	if hub.has_method("set_latch_charge") and hub.has_method("set_charges_off") and hub.has_method("latch_charge_of") and hub.has_method("charges_off_of"):
		var read: Callable = func() -> Array:
			return [bool(hub.call("latch_charge_of", 0)), bool(hub.call("latch_charge_of", 1)), bool(hub.call("charges_off_of", 0)), bool(hub.call("charges_off_of", 1))]
		var at0: Array = read.call()
		main.ui_hud.set_option("latch_charge", true)
		main.ui_hud.set_option("charges_off_p2", true)
		var at1: Array = read.call()
		main.ui_hud.set_option("latch_charge", false)
		main.ui_hud.set_option("charges_off_p2", false)
		main.ui_hud.set_option("latch_charge_p2", true)
		main.ui_hud.set_option("charges_off", true)
		var at2: Array = read.call()
		main.ui_hud.set_option("latch_charge_p2", false)
		main.ui_hud.set_option("charges_off", false)
		_expect(at0 == [false, false, false, false] and at1 == [true, false, false, true] and at2 == [false, true, true, false] and read.call() == at0, "Latched charge and Charges off go from UI's options to the hub for the player who set them, and off again (%s, %s)" % [str(at1), str(at2)])
	else:
		print("note  the hub has no set_latch_charge and set_charges_off yet (Controls' are not committed): UI's two charge settings are read and not passed on")
	# 9. A beam and a clash come and go once.
	var bs: Array = []
	var cs: Array = []
	for k in range(0, 100):
		bs.append(BeamView.strength(float(k) * SimConst.DT, 0.95))
		cs.append(BeamView.clash_strength(float(k) * SimConst.DT, 1.6))
	_expect(_turns(bs) == 1 and is_equal_approx(bs.max(), 1.0) and bs[0] == 0.0 and bs[57] == 0.0 and bs[1] < 0.2, "a beam's strength rises once and falls once (%d turn, peak %.2f, %.2f on its first tick, nothing at its end)" % [_turns(bs), bs.max(), bs[1]])
	_expect(_turns(cs) == 1 and is_equal_approx(cs.max(), 1.0) and cs[0] == 0.0 and cs[96] == 0.0, "a clash's flare and beams rise once and fall once (%d turn, peak %.2f)" % [_turns(cs), cs.max()])
	main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
	main.frame(1.0 / 60.0)
	var asked_normal: Array = _beam_asks(host)
	main.ui_hud.set_option("reduce_flashing", true)
	for k in range(3):
		main.frame(1.0 / 60.0)
	var asked_reduced: Array = _beam_asks(host)
	main.ui_hud.set_option("reduce_flashing", false)
	for k in range(3):
		main.frame(1.0 / 60.0)
	_expect(asked_normal[0] == 1 and asked_normal[1] == true and float(asked_normal[3]) > 0.0 and is_equal_approx(float(asked_normal[2]), float(asked_normal[3])) and asked_reduced[0] == 0 and asked_reduced[1] == false, "a new beam asks the register with its own weight and is granted its bright form; under UI's Reduce flashing it does not ask and is drawn calm (%s, %s)" % [str(asked_normal), str(asked_reduced)])
	# 10. The pan haze, fed this pane's camera a tick at a time (the sim does not move: the time is passed in).
	var pw: PaneWorld = main.pane
	var vp := Vector2(1280.0, 720.0)
	_expect(not RenderLook.PAN_HAZE_DEFAULT and not PaneWorld.pan_haze_on, "the pan haze ships off: a game started with no switch has none")
	PaneWorld.pan_haze_on = true   # as --panhaze
	var wide: float = 2.0 * pw.cam_rig.half_width(vp.x)
	var x: float = 5000.0
	var t: float = 100.0
	pw._pan_haze(host, t, x, vp)
	var slow_max: float = 0.0
	for k in range(60):   # 0.2 of a screen width a second
		t += 1.0
		x += 0.2 * wide * SimConst.DT
		pw._pan_haze(host, t, x, vp)
		slow_max = maxf(slow_max, pw.pan_haze)
	var fast: Array = []
	for k in range(12):   # two screen widths a second
		t += 1.0
		x += 2.0 * wide * SimConst.DT
		pw._pan_haze(host, t, x, vp)
		fast.append(pw.pan_haze)
	var sent: bool = is_equal_approx(pw.mats._haze, pw.pan_haze)
	t += 1.0
	pw._pan_haze(host, t, x + 5.0 * wide, vp)   # a cut: five screen widths in a tick
	var after_cut: float = pw.pan_haze
	x += 5.0 * wide
	var still: Array = []
	for k in range(60):
		t += 1.0
		pw._pan_haze(host, t, x, vp)
		still.append(pw.pan_haze)
	_expect(slow_max == 0.0 and fast[5] >= 0.99 and _turns(fast) == 0 and sent, "the pan haze: none at a fifth of a screen width a second, full within 6 ticks of two a second, and the materials have it (%.2f, %.2f)" % [slow_max, fast[5]])
	_expect(after_cut == fast[11] and still[59] == 0.0 and still[20] > 0.0 and _turns(still) == 0, "... a cut leaves it as it was (%.2f), and it clears in one fall once the camera stands (%.2f after 20 ticks, %.2f after 60)" % [after_cut, still[20], still[59]])
	PaneWorld.pan_haze_on = false
	for k in range(12):
		t += 1.0
		x += 2.0 * wide * SimConst.DT
		pw._pan_haze(host, t, x, vp)
	_expect(pw.pan_haze == 0.0, "... and with its switch off there is none")
	PaneWorld.pan_haze_on = RenderLook.PAN_HAZE_DEFAULT
	print("flash register check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)
