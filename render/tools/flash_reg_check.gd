extends SceneTree
## Flash register check (headless): every full flash Rendering draws asks VFX's shared flash register first
## (docs/rendering/flash-sources.md; docs/legal/photosensitivity-note.md: at most three full flashes in any second
## across the whole screen, one under reduced flashing, never red). Through the real main scene:
## - three AI matches of 3,600 ticks: never more than 3 flashes granted in any 60 ticks, Rendering's and VFX's
##   together (the register's own running count, and its log);
## - a mash: one fighter is hit every 6 ticks for 4 seconds (the tool sets the hit's time on its own match). The
##   body whitens at most twice in any second, every other hit lights the outline instead, and the screen's count
##   still never passes 3;
## - the same mash under reduced flashing: the body never whitens;
## - the rule for Rendering's low sources (two of the three slots; a big event still gets the third), red refused;
## - a head flash's pulses: each swell asks; with none granted it shows once, calm.
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


func _run() -> void:
	await process_frame
	main.started = true
	var host: SimHost = main.host
	# 1. Real matches.
	for seed in seeds:
		main.start_match(seed, {"p1": true, "p2": true})
		var reg: VfxFlashRegistry = host.vfx.flashes
		var worst: int = 0
		while host.ticks < ticks:
			main.frame(1.0 / 60.0)
			worst = maxi(worst, reg.in_window())
		var sm: Dictionary = reg.summary()
		var mine: Array = []
		for src in ["body_hit", "head_flash", "guard_flash", "cue_flare", "beam", "beam_clash"]:
			mine.append("%s %d and %d" % [src, int(sm.granted_by.get(src, 0)), int(sm.refused_by.get(src, 0)) + int(host.flash_refused.get(src, 0))])
		_expect(worst <= 3 and int(sm.worst_running) <= 3 and int(sm.worst_second) <= 3, "seed %d, %d ticks: never more than 3 flashes in a second (worst %d); %d granted, %d refused by the register" % [seed, host.ticks, int(sm.worst_running), int(sm.granted), int(sm.refused)])
		print("     Rendering's, granted and refused: %s" % "; ".join(mine))
	# 2 and 3. A mash on fighter 1, then the same under reduced flashing.
	for reduced in [false, true]:
		main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
		host.vfx.reduced_flashing = reduced
		var S: SimState = host.S
		var v: FighterView = main.pane.fighter_views[1]
		var white_at: Array = []     # the ticks the body turned white
		var edges: int = 0           # frames the outline was lit instead
		var hits: int = 0
		var was: bool = false
		var worst2: int = 0
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
			worst2 = maxi(worst2, host.vfx.flashes.in_window())
		host.vfx.reduced_flashing = false
		if reduced:
			_expect(white_at.is_empty() and edges > 0 and worst2 <= 1, "reduced flashing, %d hits in 4 seconds: the body never whitens, the outline lights (%d frames); at most 1 flash a second on the screen (%d)" % [hits, edges, worst2])
		else:
			_expect(_worst(white_at) <= 2 and white_at.size() > 0 and white_at.size() < hits, "a mash, %d hits in 4 seconds: the body whitens %d times, never more than twice in a second (%d)" % [hits, white_at.size(), _worst(white_at)])
			_expect(edges > 0 and worst2 <= 3, "... the other hits light the outline (%d frames), and the screen never passes 3 flashes in a second (%d)" % [edges, worst2])
	# 4. The rule for Rendering's low sources, on a fresh register.
	main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
	main.frame(1.0 / 60.0)
	var a: bool = host.ask_flash("body_hit")
	var b: bool = host.ask_flash("guard_flash", Color(0.4, 0.8, 1.0))
	var c: bool = host.ask_flash("body_hit")
	var d: bool = host.ask_flash("beam", Color(0.4, 0.8, 1.0))
	var e: bool = host.ask_flash("beam", Color(0.4, 0.8, 1.0))
	_expect(a and b and not c and d and not e, "two low flashes are granted, a third is refused, a beam still gets the last slot, and a fourth flash is refused (%s %s %s %s %s)" % [a, b, c, d, e])
	for k in range(61):
		main.frame(1.0 / 60.0)
	_expect(not host.ask_flash("cue_flare", Color(1.0, 0.2, 0.15)) and host.ask_flash("cue_flare", Color(0.4, 0.8, 1.0)), "a second on, a red flare is refused and a cyan one is granted")
	for src in SimHost.FLASH_LOW:
		if not VfxFlashRegistry.LOW.has(src):
			print("     note: the register's LOW list does not name %s yet; the host keeps the low rule for it" % src)
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
	print("flash register check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)
