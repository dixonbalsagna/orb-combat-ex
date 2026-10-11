extends SceneTree
## After-images against Legal's m12 (docs/legal/movegen-banned.json: at most five whole-figure ghosts round one fighter
## from all sources), and a bright beam's tail (headless, through the real main scene).
## After-images:
## - a real match with rushes in it (AI against AI, seed 7, the match whose tick 307 had six): on no tick are more than
##   RenderLook.AFTER_MAX drawn round a fighter, five are reached, and on every tick the number drawn is the number
##   VFX's tally reads for him (render/vfx/ghost_tally.gd, which gives VFX's own ghosts what is left of five);
## - more than five alive round one fighter (two sent in a tick): five are drawn, and the ones left out are the oldest;
## - one still within RenderLook.AFTER_CLEAR of its fighter is not drawn and takes no place of the five.
## A beam's tail (BeamView.tail_at):
## - a short beam's tail is where it always was, bright or calm;
## - a planet-crossing beam's bright tail uncovers no more than RenderLook.BEAM_TAIL_PX pixels a tick, at any zoom,
##   and its calm tail is where it always was.
##   godot --headless --path . --script res://render/tools/after_check.gd [-- --seed=7 --ticks=900]

const DT: float = 1.0 / 60.0

var main: Node
var fails: int = 0
var seed_n: int = 7
var ticks: int = 900


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed_n = int(a.substr(7))
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


func _views() -> Array:
	var out: Array = [main.pane.particles]
	for p in main.all_panes():
		if not out.has(p.particles):
			out.append(p.particles)
	return out


## The most after-images any pane drew round fighter s on the last frame.
func _drawn(s: int) -> int:
	var m: int = 0
	for pv in _views():
		if pv.after_count.size() > s:
			m = maxi(m, pv.after_count[s])
	return m


func _run() -> void:
	await process_frame
	main.started = true
	main.start_match(seed_n, {"p1": true, "p2": true}, {"intro": "skip"})
	var host: SimHost = main.host
	var S: SimState = host.S
	host.vfx.auto_quality = false
	host.vfx.force_reduced = false
	var peak: Array = [0, 0]
	var tally_peak: Array = [0, 0]
	var differ: int = 0
	var first: String = ""
	while host.ticks < ticks and S.game.ko == null:
		host.acc = DT * 0.9999
		main.frame(DT)
		for s in range(2):
			var d: int = _drawn(s)
			var t: int = int(host.vfx.ghosts.after_now[s])
			peak[s] = maxi(peak[s], d)
			tally_peak[s] = maxi(tally_peak[s], t)
			if d != mini(t, RenderLook.AFTER_MAX):
				differ += 1
				if first == "":
					first = "tick %d, fighter %d: %d drawn, the tally reads %d" % [host.ticks, s, d, t]
	var most: int = maxi(peak[0], peak[1])
	_expect(most <= RenderLook.AFTER_MAX and VfxGhostTally.after_ticks() == RenderLook.AFTER_MAX, "seed %d, %d ticks: at most %d after-images are drawn round a fighter on any tick (%s; the limit is %d), and VFX's tally takes one to be shown %d ticks" % [seed_n, host.ticks, most, str(peak), RenderLook.AFTER_MAX, VfxGhostTally.after_ticks()])
	_expect(most == RenderLook.AFTER_MAX, "the match has a rush in it: the five are reached (%d), so the limit is tried" % most)
	_expect(differ == 0, "on every tick the number drawn round each fighter is the number VFX's tally reads for him (its peaks %s)%s" % [str(tally_peak), "" if differ == 0 else ": %d differ, first at %s" % [differ, first]])
	# More than five alive round one fighter: eight in his colour, one a third of a tick older than the last, well off him.
	var f = S.fighters[0]
	host.fxv.parts.clear()
	var made: Array = []
	for i in range(8):
		var p := SimFxView.Part.new()
		p.type = "after"; p.life = 0.16; p.col = str(f.aura); p.face = f.face
		p.age = DT * (0.2 + 0.3 * float(i))
		p.x = SimWrap.wrap(f.x - 120.0 - 30.0 * float(i)); p.y = f.y
		host.fxv.parts.append(p)
		made.append(p)
	host.acc = 0.0
	main.frame(0.0)
	var pv: ParticleView = main.pane.particles
	var skipped_old: bool = pv._after_skip.size() == 3
	for i in range(8):
		skipped_old = skipped_old and pv._after_skip.has(made[i]) == (i >= 5)
	_expect(_drawn(0) == RenderLook.AFTER_MAX and skipped_old, "eight alive round one fighter: %d are drawn, and the three left out are the oldest" % _drawn(0))
	# One on its fighter takes no place: five off him and one within the clear distance.
	host.fxv.parts.clear()
	for i in range(6):
		var p := SimFxView.Part.new()
		p.type = "after"; p.life = 0.16; p.col = str(f.aura); p.face = f.face
		p.age = DT * (0.2 + 0.3 * float(i))
		p.x = SimWrap.wrap(f.x - (120.0 + 30.0 * float(i) if i > 0 else RenderLook.AFTER_CLEAR.x * 0.5)); p.y = f.y
		host.fxv.parts.append(p)
	host.acc = 0.0
	main.frame(0.0)
	_expect(_drawn(0) == 5 and pv._after_skip.is_empty(), "one within %.0f units of its fighter is not drawn and takes no place: the five off him are all drawn (%d)" % [RenderLook.AFTER_CLEAR.x, _drawn(0)])
	host.fxv.parts.clear()
	# A beam's tail.
	var b := SimState.Beam.new()
	b.len = 900.0; b.w = 60.0; b.life = 0.95; b.p = 1.0
	var same: bool = true
	var worst_px: float = 0.0
	for ppu in [0.25, 0.5, 0.85, 1.3, 2.0]:
		for k in range(1, 58):
			b.t = float(k) * DT
			var old: float = clampf((b.t - 0.4) / (b.life - 0.4), 0.0, 1.0) * b.len if b.t > 0.4 else 0.0
			same = same and is_equal_approx(BeamView.tail_at(b), old)
			if ppu <= 0.5:   # a beam this short on the screen is under the cap: as it was
				same = same and is_equal_approx(BeamView.tail_at(b, ppu), old)
	_expect(same, "a short beam's tail is where it always was (900 units at half a pixel a unit and wider views, bright), and a calm beam's at any size")
	b.len = 32058.0; b.life = 0.95 + 20.0 * DT
	var calm_same: bool = true
	var grows: bool = true
	for ppu in [0.25, 0.5, 0.85, 1.3, 2.0]:
		var last: float = 0.0
		for k in range(1, 78):
			b.t = float(k) * DT
			var old: float = clampf((b.t - 0.4) / (b.life - 0.4), 0.0, 1.0) * b.len if b.t > 0.4 else 0.0
			calm_same = calm_same and is_equal_approx(BeamView.tail_at(b), old)
			var now: float = BeamView.tail_at(b, ppu)
			grows = grows and now >= last and now <= old + 0.001
			worst_px = maxf(worst_px, (now - last) * ppu * b.w * float(BeamView.LAYERS[1][0]) * ppu)
			last = now
	_expect(worst_px <= RenderLook.BEAM_TAIL_PX * 1.001 and grows and calm_same, "a planet-crossing beam (32,058 units): its bright tail uncovers at most %.0f pixels a tick at any zoom (the cap is %.0f; it was %.0f in one tick at 0.85 pixels a unit), only ever moves away, and its calm tail is where it always was" % [worst_px, RenderLook.BEAM_TAIL_PX, 32058.0 / (b.life - 0.4) * DT * 0.85 * 60.0 * 1.3 * 0.85])
	print("after check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)
