class_name BeamView
extends Node3D
## Signature beams and beam clashes (prototype drawBeams): each beam is three nested prisms (a sheath, a body and a core) from its tail to its
## head, faded by age. A beam is laid out from its tail's camera-relative x along its direction, never by wrapping its head separately, so a
## beam that crosses the seam stays one straight piece.
## Reads S.beams and S.game.clash only. A beam, and a clash's flare, is a full flash: the host asks the shared flash register once as each
## starts (SimHost.beam_flash, clash_flash). Refused, and always under reduced flashing, a beam is drawn calm: the same beam at a share of
## its strength with a slower rise (VfxBeamLook.calm), never a thin line; a calm clash has no flare and its two beams are the same.
## A beam comes and goes once: its strength rises over RenderLook.BEAM_RISE_S, holds and falls to nothing at its end (strength()), and a
## clash's flare and beams rise and fall the same way (clash_strength()). Nothing pulses.
## The layers' look is VFX's (render/vfx/beam_look.gd, shaders/beam*.gdshader, data/vfx/energy.json; docs/vfx/beam-look.md): a real width, a
## slow hue ripple at steady luminance, turbulence on the soft edge, no white core, and each fighter's own flavour. The register's decision
## (`bright`) only paces the tail and decides the rise.

const LAYER_COUNT: int = 3   # a sheath, a body and a core: their widths and looks are VfxBeamLook's

var _pool: Array = []       # per beam slot: 3 MeshInstance3D
var _flare: MeshInstance3D
var _cyl: CylinderMesh


func _ready() -> void:
	_cyl = CylinderMesh.new()
	_cyl.top_radius = 0.5
	_cyl.bottom_radius = 0.5
	_cyl.height = 1.0
	_cyl.radial_segments = 16
	_cyl.rings = 24            # rings along the beam: the width swells and thins along it (VfxBeamLook, the shader's `wob`)
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	_flare = MeshInstance3D.new()
	_flare.mesh = s
	_flare.material_override = RenderMats.glow(Color.WHITE, 1.0, 1.4)
	add_child(_flare)


func update(S: SimState, cam_x: float, z: float, host: SimHost = null) -> void:
	var n: int = 0
	# The scale a bright beam's tail is paced at: the flash register's (the closest pane's, so every pane draws one
	# beam's tail at the same place in the world); a tool's posed state has only this view's own.
	var ppu: float = host.vfx.px_per_unit if host != null else z
	for b in S.beams:
		var bright: bool = host == null or host.beam_flash(b)
		var k: float = strength(b.t, b.life, 0.0 if bright else VfxBeamLook.calm_rise())
		var s: float = b.p * b.len
		var tail: float = tail_at(b, ppu if bright else 0.0)
		var x0: float = SimWrap.sdx(cam_x, b.ox + b.ux * tail)
		var a := Vector2(x0, b.oy + b.uy * tail)
		var e := Vector2(x0 + b.ux * (s - tail), b.oy + b.uy * s)
		_beam(n, a, e, b.w, RenderLook.col(b.col), k, z, bright, b.oz + b.zs * tail, b.oz + b.zs * s, b.A, String(b.col), S.T, tail <= 0.5, VfxBeamLook.is_short(b))
		n += 1
	var c = S.game.clash
	var clash_ok: bool = host == null or host.clash_flash
	_flare.visible = c != null and clash_ok
	if c != null:
		var p: float = clampf((S.T - c.t0) / c.dur, 0.0, 1.0)
		var ck: float = clash_strength(S.T - c.t0, c.dur)
		var mid: float = 0.5 + (1.0 if c.aw else -1.0) * 0.35 * p
		var mid_v = c.get("mid")                  # Encounter's beam struggle: the meeting point it holds, 0 at A's hands to 1 at D's (Clash.mid; absent or -1: the glide above)
		if mid_v != null and float(mid_v) >= 0.0:
			mid = float(mid_v)
		var ax: float = SimWrap.sdx(cam_x, c.A.x)
		var dx: float = SimWrap.sdx(c.A.x, c.D.x)
		var m := Vector2(ax + dx * mid, c.A.y + 38.0 + (c.D.y - c.A.y) * mid)
		var mz: float = c.A.z + (c.D.z - c.A.z) * mid   # the fighters' depths (0 on the plane): the beams meet between them
		_beam(n, Vector2(ax, c.A.y + 38.0), m, 26.0 + c.A.tier * 8.0, RenderLook.col(c.A.aura), ck, z, clash_ok, c.A.z, mz, c.A, String(c.A.aura), S.T, true)
		_beam(n + 1, Vector2(ax + dx, c.D.y + 38.0), m, 26.0 + c.D.tier * 8.0, RenderLook.col(c.D.aura), ck, z, clash_ok, c.D.z, mz, c.D, String(c.D.aura), S.T, true)
		RenderMats.set_glow(_flare.material_override, Color.WHITE, ck)
		n += 2
		_flare.position = Vector3(m.x, m.y, RenderLook.Z_BEAMS + 2.0 + mz)
		_flare.scale = Vector3.ONE * 2.0 * (70.0 + 20.0 / z)
	for i in range(n, _pool.size()):
		for mi in _pool[i]:
			mi.visible = false


## How far along beam b its tail has drawn back from where it was fired, in world units. From 0.4 s the tail follows
## the head and reaches the beam's far end as its life ends. For the bright form (ppu above 0: the pixels a world unit)
## it goes no faster than uncovers RenderLook.BEAM_TAIL_PX pixels of beam a tick, the beam taken as wide as the flash
## register takes it (SimHost.beam_px): a beam whose tail was slower than that is as it was, and a long one leaves the
## firer a strip a tick while its strength falls; what the tail has not reached by its life's end has faded to nothing.
## The calm form (ppu 0: refused, or reduced flashing) goes as it always has: its thin line going at once is not a
## change the analyser counts, and held on screen under a moving camera it read worse (ai seed 1, reduced: 2.5 as it
## is, 3.5 capped).
static func tail_at(b, ppu: float = 0.0) -> float:
	if b.t <= 0.4:
		return 0.0
	var own: float = clampf((b.t - 0.4) / (b.life - 0.4), 0.0, 1.0) * b.len
	if ppu <= 0.0:
		return own
	var a_tick: float = RenderLook.BEAM_TAIL_PX / (b.w * VfxBeamLook.body_k(b.A, VfxBeamLook.is_short(b)) * ppu * ppu)
	return minf(own, (b.t - 0.4) / SimConst.DT * a_tick)


## A beam's strength at age t of its life: one rise, a hold, one fall.
static func strength(t: float, life: float, rise: float = 0.0) -> float:
	var fall: float = 1.0 if t < 0.3 else maxf(0.0, 1.0 - (t - 0.3) / (life - 0.3))
	return smoothstep(0.0, maxf(RenderLook.BEAM_RISE_S, rise), t) * fall


## A clash's strength t seconds into its dur: up over CLASH_RISE_S, down over its last CLASH_FALL_S.
static func clash_strength(t: float, dur: float) -> float:
	return smoothstep(0.0, RenderLook.CLASH_RISE_S, t) * (1.0 - smoothstep(dur - RenderLook.CLASH_FALL_S, dur, t))


## One beam from a to e (this view's x and the world's y). za, ze: the depth at each end (the sim's Beam.oz and zs; 0 on
## the fighter plane). A beam with no depth is placed exactly as it always was.
func _beam(i: int, a: Vector2, e: Vector2, w: float, c: Color, k: float, z: float, bright: bool = true, za: float = 0.0, ze: float = 0.0, who = null, hex: String = "", t: float = 0.0, at_heel: bool = true, short: bool = false) -> void:
	while _pool.size() <= i:
		var layers: Array = []
		for j in range(LAYER_COUNT):
			var mi := MeshInstance3D.new()
			mi.mesh = _cyl
			mi.material_override = VfxBeamLook.new_material(j)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
			layers.append(mi)
		_pool.append(layers)
	var d: Vector2 = e - a
	var l: float = d.length()
	for j in range(LAYER_COUNT):
		var mi: MeshInstance3D = _pool[i][j]
		mi.visible = l > 0.01
		if not mi.visible:
			continue
		var u: Vector2 = d / l
		var th: float = VfxBeamLook.thickness(who, w, j, z, short, l)
		if za == 0.0 and ze == 0.0:
			mi.transform = Transform3D(Basis(Vector3(u.y, -u.x, 0.0) * th, Vector3(u.x, u.y, 0.0) * (l + th * 0.5), Vector3(0.0, 0.0, th)), Vector3((a.x + e.x) * 0.5, (a.y + e.y) * 0.5, RenderLook.Z_BEAMS))
		else:
			# In depth: the same prism along its true line, its width still across the screen.
			var dir := Vector3(d.x, d.y, ze - za)
			var l3: float = dir.length()
			dir /= l3
			var side := Vector3(u.y, -u.x, 0.0)
			mi.transform = Transform3D(Basis(side * th, dir * (l3 + th * 0.5), side.cross(dir) * th), Vector3((a.x + e.x) * 0.5, (a.y + e.y) * 0.5, RenderLook.Z_BEAMS + (za + ze) * 0.5))
		VfxBeamLook.set_layer(mi.material_override, who, VfxAura.lane_color(hex) if hex != "" else c, j, k, not bright, t, l, at_heel, float(i), short)
