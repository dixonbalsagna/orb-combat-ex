class_name BeamView
extends Node3D
## Signature beams and beam clashes (prototype drawBeams): each beam is three additive cylinders (outer glow, body,
## white core) from its tail to its head, faded by age. A beam is laid out from its tail's camera-relative x along its
## direction, never by wrapping its head separately, so a beam that crosses the seam stays one straight piece.
## Reads S.beams and S.game.clash only. A beam, and a clash's flare, is a full flash: the host asks the shared flash
## register once as each starts (SimHost.beam_flash, clash_flash). Refused, and always under reduced flashing, a beam
## is drawn calm: a thin line in its own colour in place of the white core, and its glow at RenderLook.BEAM_SOFT of
## its strength; a calm clash has no flare and its two beams are the same.
## A beam comes and goes once: its strength rises over RenderLook.BEAM_RISE_S, holds and falls to nothing at its end
## (strength()), and a clash's flare and beams rise and fall the same way (clash_strength()). Nothing pulses.

const LAYERS: Array = [[2.4, 4.0, 0.25], [1.3, 3.0, 0.6], [0.5, 2.0, 0.95]]   # width factor, extra pixels, alpha

var _pool: Array = []       # per beam slot: 3 MeshInstance3D
var _flare: MeshInstance3D
var _cyl: CylinderMesh


func _ready() -> void:
	_cyl = CylinderMesh.new()
	_cyl.top_radius = 0.5
	_cyl.bottom_radius = 0.5
	_cyl.height = 1.0
	_cyl.radial_segments = 12
	_cyl.rings = 0
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	_flare = MeshInstance3D.new()
	_flare.mesh = s
	_flare.material_override = RenderMats.glow(Color.WHITE, 1.0, 1.4)
	add_child(_flare)


func update(S: SimState, cam_x: float, z: float, host: SimHost = null) -> void:
	var n: int = 0
	for b in S.beams:
		var k: float = strength(b.t, b.life)
		var s: float = b.p * b.len
		var tail: float = clampf((b.t - 0.4) / (b.life - 0.4), 0.0, 1.0) * b.len if b.t > 0.4 else 0.0
		var x0: float = SimWrap.sdx(cam_x, b.ox + b.ux * tail)
		var a := Vector2(x0, b.oy + b.uy * tail)
		var e := Vector2(x0 + b.ux * (s - tail), b.oy + b.uy * s)
		_beam(n, a, e, b.w, RenderLook.col(b.col), k, z, host == null or host.beam_flash(b))
		n += 1
	var c = S.game.clash
	var clash_ok: bool = host == null or host.clash_flash
	_flare.visible = c != null and clash_ok
	if c != null:
		var p: float = clampf((S.T - c.t0) / c.dur, 0.0, 1.0)
		var ck: float = clash_strength(S.T - c.t0, c.dur)
		var mid: float = 0.5 + (1.0 if c.aw else -1.0) * 0.35 * p
		var ax: float = SimWrap.sdx(cam_x, c.A.x)
		var dx: float = SimWrap.sdx(c.A.x, c.D.x)
		var m := Vector2(ax + dx * mid, c.A.y + 38.0 + (c.D.y - c.A.y) * mid)
		_beam(n, Vector2(ax, c.A.y + 38.0), m, 26.0 + c.A.tier * 8.0, RenderLook.col(c.A.aura), ck, z, clash_ok)
		_beam(n + 1, Vector2(ax + dx, c.D.y + 38.0), m, 26.0 + c.D.tier * 8.0, RenderLook.col(c.D.aura), ck, z, clash_ok)
		RenderMats.set_glow(_flare.material_override, Color.WHITE, ck)
		n += 2
		_flare.position = Vector3(m.x, m.y, RenderLook.Z_BEAMS + 2.0)
		_flare.scale = Vector3.ONE * 2.0 * (70.0 + 20.0 / z)
	for i in range(n, _pool.size()):
		for mi in _pool[i]:
			mi.visible = false


## A beam's strength at age t of its life: one rise, a hold, one fall.
static func strength(t: float, life: float) -> float:
	var fall: float = 1.0 if t < 0.3 else maxf(0.0, 1.0 - (t - 0.3) / (life - 0.3))
	return smoothstep(0.0, RenderLook.BEAM_RISE_S, t) * fall


## A clash's strength t seconds into its dur: up over CLASH_RISE_S, down over its last CLASH_FALL_S.
static func clash_strength(t: float, dur: float) -> float:
	return smoothstep(0.0, RenderLook.CLASH_RISE_S, t) * (1.0 - smoothstep(dur - RenderLook.CLASH_FALL_S, dur, t))


func _beam(i: int, a: Vector2, e: Vector2, w: float, c: Color, k: float, z: float, bright: bool = true) -> void:
	while _pool.size() <= i:
		var layers: Array = []
		for j in range(LAYERS.size()):
			var mi := MeshInstance3D.new()
			mi.mesh = _cyl
			mi.material_override = RenderMats.glow(Color.WHITE, 1.0, RenderLook.BEAM_EDGE[j])
			add_child(mi)
			layers.append(mi)
		_pool.append(layers)
	var d: Vector2 = e - a
	var l: float = d.length()
	for j in range(LAYERS.size()):
		var mi: MeshInstance3D = _pool[i][j]
		mi.visible = l > 0.01
		if not mi.visible:
			continue
		var u: Vector2 = d / l
		var th: float = w * LAYERS[j][0] + LAYERS[j][1] / z
		var cj: Color = Color.WHITE if j == 2 else c
		var aj: float = LAYERS[j][2] * k
		if not bright:
			if j == 2:   # the calm form: a thin line in the beam's own colour where the white core was
				th = w * LAYERS[j][0] * RenderLook.BEAM_LINE + LAYERS[j][1] / z
				cj = c.lerp(Color.WHITE, 0.35)
			else:
				aj *= RenderLook.BEAM_SOFT
		mi.transform = Transform3D(Basis(Vector3(u.y, -u.x, 0.0) * th, Vector3(u.x, u.y, 0.0) * (l + th * 0.5), Vector3(0.0, 0.0, th)), Vector3((a.x + e.x) * 0.5, (a.y + e.y) * 0.5, RenderLook.Z_BEAMS))
		RenderMats.set_glow(mi.material_override, cj, aj)
