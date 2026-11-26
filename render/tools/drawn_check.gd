extends SceneTree
## drawn_at (RenderTileGround, Camera's drawn-ground sampler) against the foreground rule as the mesh's vertex stage applies it: on a gen 3 match through the
## game's main with the tile ground, at points round the pane's camera (in front of the fighter plane, at the lens and past it, and behind the plane):
##   twin      drawn_at equals tile_chart and tile_fore (render/shaders/tile_read.gdshaderinc) evaluated on the material's own uniforms: the frame (hd, sd,
##             pv), the camera (fore_cam), plane_span, fore_drop, the profile as the image the texture was made from (float32) and globe_r, within TOL;
##   behind    behind the fighter plane the ground is the field's, untouched;
##   under     nowhere is the drawn ground above the field's (the rule only lowers);
##   lowered   the rule lowers some of the points (else the check proves nothing).
## Headless: the GPU's vertex stage doesn't run here, so "what the mesh draws" is the shader's formula on the values the GPU is given, not a read-back.
## --negative-control: the independent evaluation reads the eye 200 units higher; the twin row must then fail.
##   godot --headless --path . --script res://render/tools/drawn_check.gd -- --tiles [--negative-control]

const TOL: float = 0.05
var main: Node
var negative: bool = false


func _initialize() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


## tile_chart, transcribed from the shader's text.
static func _chart(d: Vector3, h: Vector3, s: Vector3, p: Vector3, globe_r: float) -> Vector2:
	var x: float = d.dot(h)
	var z: float = d.dot(s)
	var q: float = sqrt(x * x + z * z)
	var k: float = atan2(q, d.dot(p)) / q if q > 1.0e-5 else 1.0
	return Vector2(x, z) * k * globe_r


## tile_fore, transcribed from the shader's text.
static func _fore(y: float, p: Vector2, fc: Vector3, span: float, drop: float, prof: PackedFloat32Array) -> float:
	if p.y <= 0.0:
		return y
	var t: float = minf(p.y / fc.z, 0.95)
	var pu: float = clampf((p.x / (1.0 - t) + span) / (2.0 * span), 0.0, 1.0) * 63.0
	var ua: int = int(pu)
	var pl: float = lerpf(prof[ua], prof[mini(ua + 1, 63)], pu - float(ua))
	return minf(y, lerpf(pl, fc.y, t) - drop * p.y)


func _run() -> void:
	await process_frame
	main.started = true
	if not RenderTileGround.on:
		print("drawn check FAILED: the tile ground is off (run with --tiles)")
		quit(1)
		return
	main.start_match(1, {"p1": true, "p2": true}, {"planet": 7, "touch": 3, "intro": "skip"})
	while main.host.loading():
		main.frame(1.0 / 60.0)
	for k in range(240):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var pane = main.pane
	var tg = pane._tiles
	if tg == null or tg.mat == null:
		print("drawn check FAILED: the pane has no tile ground")
		quit(1)
		return
	var tf: RenderTileField = tg.field
	var m: ShaderMaterial = tg.mat
	var hd: Vector3 = m.get_shader_parameter("hd")
	var sd: Vector3 = m.get_shader_parameter("sd")
	var pv: Vector3 = m.get_shader_parameter("pv")
	var fc: Vector3 = m.get_shader_parameter("fore_cam")
	var spv = m.get_shader_parameter("plane_span")
	var span: float = float(spv) if spv != null else 3000.0
	var fdv = m.get_shader_parameter("fore_drop")
	var drop: float = float(fdv) if fdv != null else RenderLook.FORE_DROP
	var prof: PackedFloat32Array = tg._prof_img.get_data().to_float32_array()
	var gr: float = tg._reff
	var fc_ind: Vector3 = fc + (Vector3(0.0, 200.0, 0.0) if negative else Vector3.ZERO)
	var fr = RenderTileGround._shown_frame(S)
	var cx: float = float(pane.view_cam_x)
	var n: int = 0
	var worst: float = 0.0
	var behind_bad: int = 0
	var above: int = 0
	var lowered: int = 0
	for dx in [-1500.0, -500.0, 0.0, 500.0, 1500.0]:
		for f in [-0.3, 0.0, 0.2, 0.5, 0.8, 1.0, 1.3]:
			var d: Vector3 = tf.dir_at(cx + dx, f * fc.z, fr)
			var h: float = tf.height_at(d)
			var twin: float = tg.drawn_at(d)
			var p: Vector2 = _chart(d, hd, sd, pv, gr)
			var ind: float = _fore(h, p, fc_ind, span, drop, prof)
			n += 1
			worst = maxf(worst, absf(twin - ind))
			if p.y <= 0.0 and absf(twin - h) > 1.0e-6:
				behind_bad += 1
			if twin > h + 1.0e-6:
				above += 1
			if twin < h - 0.5:
				lowered += 1
	var ok_twin: bool = worst <= TOL
	print("%s twin: drawn_at against tile_chart and tile_fore on the material's own uniforms at %d points, worst %.4f units (at most %.2f)%s" % ["ok  " if ok_twin else "FAIL", n, worst, TOL, " [negative control: the eye read 200 higher]" if negative else ""])
	print("%s behind: behind the fighter plane the ground is the field's (%d off)" % ["ok  " if behind_bad == 0 else "FAIL", behind_bad])
	print("%s under: the drawn ground is never above the field's (%d above)" % ["ok  " if above == 0 else "FAIL", above])
	print("%s lowered: the rule lowers %d of the %d points (eye %.0f at depth %.0f)" % ["ok  " if lowered > 0 else "FAIL", lowered, n, fc.y, fc.z])
	var ok: bool = ok_twin and behind_bad == 0 and above == 0 and lowered > 0
	print("drawn check %s" % ("passed" if ok else "FAILED"))
	quit(0 if ok else 1)
