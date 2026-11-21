extends SceneTree
## The feet check (Rendering, A1 clipping; the stand-in's planet design §6): a fighter's feet as drawn against the ground as drawn,
## computer against computer on the tile ground, through the game's own main with its own setup (so the opening plays), every frame
## for each fighter standing (his y within 1 unit of the sim's ground):
##   the ground drawn under him: the finest tile (RenderTileField.height_at; it carries the store's grooves), the strip rows' offset
##   (GroundField.offset_at), and the store's bowls read from the tile material itself (tile_bowls, opening included);
##   his feet as drawn: the sim's y plus the lift the shared placement gives him (RenderTileField.lift, the shader's twin).
## Passes when no sample is more than WORST units off either way and at most SHARE of them are more than OVER off.
## Needs the tile ground on (the globe ground by default, or --tiles). A long gate: about 20 minutes, run it at below-normal priority.
##   godot --headless --path . --script res://render/tools/feet_check.gd [-- --seeds=1,2,... --ticks=1800]

var main: Node
var seeds: Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
var ticks: int = 1800
var SIZE: String = ""   # SCRATCH: the planet size to play (World's setup key planetSize)
var SPLIT: bool = false   # SCRATCH: the split screen attached, as the game has it (main attaches it unless --nosplit); each fighter read through the pane nearest him
const OVER: float = 8.0
const WORST: float = 25.0
const SHARE: float = 0.03   # a ratchet (the EP, 2026-11-14): 4% while feet stood on grooves the tiles didn't draw, 3% once a body's own column took his own lift, then lower


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--size="):
			SIZE = a.substr(7)
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a == "--split":
			SPLIT = true
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


## tile_read.gdshaderinc tile_bowls, from the tile material's own uniforms.
func _bowls(tg, d: Vector3) -> float:
	var m: ShaderMaterial = tg.mat
	var n: int = int(m.get_shader_parameter("cb_n"))
	if n <= 0:
		return 0.0
	var A = m.get_shader_parameter("cb_a")
	var B = m.get_shader_parameter("cb_b")
	var now: float = float(m.get_shader_parameter("cb_now"))
	var opn: float = float(m.get_shader_parameter("cb_open"))
	var rim: Vector2 = m.get_shader_parameter("cb_rim")
	var R: float = float(tg._reff)
	var s: float = 0.0
	for k in range(n):
		var a: Vector4 = A[k]
		var b: Vector4 = B[k]
		var u: float = (d - Vector3(a.x, a.y, a.z)).length() * R / a.w
		if u >= 1.0 + rim.y:
			continue
		var h: float = 0.0
		if u < 1.0:
			var t: float = 1.0 - u * u
			h = -b.x * t * t
			var lo: float = 1.0 - rim.x
			if u > lo:
				var q: float = (u - lo) / rim.x
				h += b.y * q * q * (3.0 - 2.0 * q)
		else:
			var w: float = (u - 1.0) / rim.y
			h = b.y * (1.0 - w * w * (3.0 - 2.0 * w))
		var o: float = clampf((now - b.z) / opn, 0.0, 1.0)
		s += h * o * o * (3.0 - 2.0 * o)
	return s


func _run() -> void:
	await process_frame
	main.started = true
	if not RenderTileGround.on:
		print("feet check FAILED: the tile ground is off (it needs the globe ground on, or --tiles)")
		quit(1)
		return
	if SPLIT:
		main.split_view = SplitView.new()
		main.add_child(main.split_view)
		main.split_view.attach(main)
	var n_all: int = 0
	var n_over: int = 0
	var worst: float = 0.0
	for seed in seeds:
		main.start_match(seed, {"p1": true, "p2": true}, {"planetSize": SIZE} if SIZE != "" else null)
		while main.host.loading():
			main.frame(1.0 / 60.0)
		var S: SimState = main.host.S
		var pane = main.pane
		var P: PlanetView = pane.planet
		var tf: RenderTileField = P.tile_field
		var t_end: int = main.host.ticks + ticks
		var n: int = 0
		var over: int = 0
		var w: float = 0.0
		var off_pane: int = 0   # --split: samples of a fighter outside every rendered pane's view (no picture shows his feet)
		while main.host.ticks < t_end and not (S.game.ko != null and S.game.koT > 3.0):
			main.frame(1.0 / 60.0)
			if main.host.loading() or S != main.host.S:
				break
			var fr = RenderTileGround._shown_frame(S)
			for F in S.fighters:
				var x: float = float(F.x)
				var foot: float = float(F.y)
				var z: float = float(F.z) if "z" in F else 0.0
				if absf(foot - WorldTerrain.groundY(S, x)) > 1.0:
					continue
				if SPLIT:
					# the pane whose camera is nearest him, of the panes the split renders this frame (SplitFrame.active): a pane not rendered keeps its last
					# camera and bowls, perhaps a match old
					var bd: float = INF
					var lf = main.split_view.last_frame
					for k in range(main.panes.size()):
						var pw = main.panes[k]
						if pw == null or pw._tiles == null or (lf != null and k < lf.active.size() and not bool(lf.active[k])):
							continue
						var dd: float = absf(SimWrap.sdx(pw.view_cam_x, x))
						if dd < bd:
							bd = dd
							pane = pw
					if bd > pane.cam_rig.half_width(1280.0) * 1.25:
						off_pane += 1
						continue
					P = pane.planet
					tf = P.tile_field
				var tg = pane._tiles
				if tg == null or tf == null:
					continue
				var d: Vector3 = tf.dir_at(x, z, fr)
				var xw: float = SimWrap.wrap(x)
				var col: int = int(xw / SimConst.COL) % SimConst.NC
				var drawn: float = tf.height_at(d) + P.ground.offset_at(S, col, xw, z) + _bowls(tg, d)
				var gap: float = absf(drawn - (foot + tf.lift(x, foot, z)))
				n += 1
				w = maxf(w, gap)
				if gap > OVER:
					over += 1
		print("%s seed %d: %d standing samples, %d over %.0f units, the worst %.1f%s" % ["ok  " if (w <= WORST and float(over) <= SHARE * float(maxi(n, 1))) else "FAIL", seed, n, over, OVER, w, (" (%d outside every pane, not read)" % off_pane) if SPLIT else ""])
		n_all += n
		n_over += over
		worst = maxf(worst, w)
	var ok: bool = worst <= WORST and float(n_over) <= SHARE * float(maxi(n_all, 1))
	print("%s %d seeds: %d standing samples, %d over %.0f units (%.1f%%, at most %.0f%%), the worst %.1f (at most %.0f)" % ["ok  " if ok else "FAIL", seeds.size(), n_all, n_over, OVER, 100.0 * float(n_over) / float(maxi(n_all, 1)), 100.0 * SHARE, worst, WORST])
	print("feet check %s" % ("passed" if ok else "FAILED"))
	quit(0 if ok else 1)
