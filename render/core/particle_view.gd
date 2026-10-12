class_name ParticleView
extends MultiMeshInstance3D
## The reference fx consumer's particles (sim/core/view/fx.gd parts) and the render-side impact effects (ImpactFx),
## drawn as one MultiMesh of quads in a single draw call. Sizes follow the prototype's drawParts, which sets them in
## screen pixels, so each is divided by the zoom. Ripples and shock rings lie flat on the water or the ground.
## An afterimage is the thin outline of a figure, never a fill: it stands behind the fighter's depth, shows only once
## he has moved off the spot, and is gone in RenderLook.AFTER_LIFE (it used to be a flat block in front of him).
## Per frame it rewrites one float buffer: 12 transform, 4 colour and 4 custom floats per particle.
## Reads the consumer's particles only.

const CAP := 2401 + ImpactFx.CAP   # the consumer's cap (fx.gd _P lets 2401 in) plus the impact effects'
const STRIDE := 20
const SHAPE := {"spark": 0.0, "deb": 0.0, "after": 4.0, "flame": 1.0, "splash": 1.0, "ring": 2.0, "dust": 3.0, "ripple": 2.0, "shock": 2.0}

static var after_on: bool = true   # afterimages; the reduced version drops them (main sets it from VFX's quality)
var after_count := PackedInt32Array()   # per fighter of this pane: the after-images drawn round him this frame (at most RenderLook.AFTER_MAX)
var _after_skip: Dictionary = {}        # the after-images past a fighter's five this frame: not drawn

var _buf := PackedFloat32Array()
var count: int = 0
var deep: bool = false                  # a match with depth on (the pane sets it): particles are drawn at the depth they were made at. With depth off they stay on the plane, as ever (a brunt launch's events carry a depth too)


func _ready() -> void:
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = q
	mm.instance_count = CAP
	mm.visible_instance_count = 0
	mm.custom_aabb = AABB(Vector3(-20000.0, -8000.0, -100.0), Vector3(40000.0, 16000.0, 200.0))
	multimesh = mm
	var m := ShaderMaterial.new()
	m.shader = preload("res://render/shaders/particle.gdshader")
	m.render_priority = 2          # after the water, so ripples sit on top of it
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_buf.resize(CAP * STRIDE)


## half_w: half the visible width in world units, for culling. views: the pane's fighter views as placed this frame
## (an afterimage is drawn behind its fighter, and not while he stands on it).
func update(V: SimFxView, I: ImpactFx, cam_x: float, z: float, half_w: float, views: Array = []) -> void:
	_after_budget(V.parts, cam_x, views)
	var n: int = _fill(V.parts, 0, cam_x, z, half_w + 80.0, views)
	if I != null:
		n = _fill(I.parts, n, cam_x, z, half_w + 80.0, views)
	count = n
	multimesh.visible_instance_count = n
	if n > 0:
		multimesh.buffer = _buf


## Whose after-image a particle is: the nearest fighter in its colour (any fighter, if none has it). Returns his index
## in views and his distance from it, or [-1, INF] with no fighters.
static func _after_owner(c: Color, vx: float, y: float, views: Array) -> Array:
	var idx: int = -1
	var best: float = INF
	var mine: bool = false
	for i in range(views.size()):
		var v = views[i]
		var own: bool = (v._aura_col as Color).is_equal_approx(c)
		var d: float = Vector2(vx - v.position.x, y - v.position.y).length()
		if (own and not mine) or (own == mine and d < best):
			best = d
			mine = own
			idx = i
	return [idx, best]


## Legal's m12: at most RenderLook.AFTER_MAX after-images round one fighter at once. A rush sends one a tick and each
## is shown five ticks, so there are five; if anything ever sends more (two in a tick), the oldest past five are not
## drawn. One still within RenderLook.AFTER_CLEAR of its fighter is not shown and takes no place.
func _after_budget(list: Array, cam_x: float, views: Array) -> void:
	_after_skip.clear()
	after_count.resize(views.size())
	after_count.fill(0)
	if not after_on:
		return
	var by: Dictionary = {}
	for p in list:
		if p.type != "after" or p.age >= minf(p.life, RenderLook.AFTER_LIFE):
			continue
		var own: Array = _after_owner(RenderLook.col(p.col), SimWrap.sdx(cam_x, p.x), p.y, views)
		if float(own[1]) <= RenderLook.AFTER_CLEAR.x:
			continue
		if not by.has(own[0]):
			by[own[0]] = []
		by[own[0]].append(p)
	for o in by:
		var a: Array = by[o]
		if a.size() > RenderLook.AFTER_MAX:
			a.sort_custom(func(p, q): return p.age < q.age)
			for k in range(RenderLook.AFTER_MAX, a.size()):
				_after_skip[a[k]] = true


func _fill(list: Array, n: int, cam_x: float, z: float, lim: float, views: Array) -> int:
	var zz: float = RenderLook.Z_PARTICLES
	for p in list:
		if n >= CAP:
			break
		var vx: float = SimWrap.sdx(cam_x, p.x)
		if absf(vx) > lim:
			continue
		var k: float = 1.0 - p.age / p.life
		var c: Color = RenderLook.col(p.col)
		var sx: float
		var sy: float
		var rot: float = 0.0
		var cx: float = vx
		var cy: float = p.y
		var inner: float = 0.0
		var flat: bool = false
		var pz: float = zz + (p.z if deep else 0.0)   # the depth it was made at (SimFxView.Part.z; 0 on the fighter plane)
		var cz: float = 0.0
		var cw: float = 0.0
		match p.type:
			"spark":
				var v := Vector2(p.vx, p.vy)
				sx = maxf(v.length() * 0.03, 0.5 / z)
				sy = maxf(1.0, p.size * maxf(0.6, z)) / z
				rot = atan2(p.vy, p.vx)
				cx -= p.vx * 0.015
				cy -= p.vy * 0.015
				c.a = k
			"ring", "ripple", "shock":
				var lw: float = maxf(1.5, 5.0 * k * z + 1.0) / z
				var r: float = maxf(1.0, p.r * z) / z
				sx = 2.0 * (r + lw * 0.5)
				sy = sx
				inner = (r - lw * 0.5) / (r + lw * 0.5)
				c.a = k * (0.9 if p.type == "ring" else 0.7)
				flat = p.type != "ring"
			"deb":
				sx = maxf(1.5, p.size * z * 1.4) / z
				sy = sx
				c.a = minf(1.0, k * 2.0)
			"dust":
				sx = 2.0 * maxf(2.0, p.size * z * (1.5 - k * 0.5)) / z
				sy = sx
				c.a = 0.35 * k
			"flame":
				sx = 2.0 * maxf(1.5, p.size * z * k * 1.4) / z
				sy = sx
				c.a = 0.8 * k
			"splash":
				sx = 2.0 * maxf(1.5, p.size * maxf(0.7, z)) / z
				sy = sx
				c.a = k
			"after":
				var shown: float = minf(p.life, RenderLook.AFTER_LIFE)
				if not after_on or p.age >= shown or _after_skip.has(p):
					continue
				# Whose it is: the nearest fighter in its colour (any fighter, if none has it). It stands behind him
				# and shows only as far as he has moved off it, so a fighter who steps in and strikes wears nothing.
				var away: float = 1.0
				var own: Array = _after_owner(c, vx, p.y, views)
				var best: float = own[1]
				if int(own[0]) >= 0:
					var v = views[int(own[0])]
					pz = v.position.z - RenderLook.AFTER_BEHIND
					# A rush's trail (the short-lived ones, one a tick) lies head first along the way he went;
					# a dodge's or an escape's stands as he stands.
					if p.life < 0.3 and best > 1.0:
						rot = atan2(v.position.y - p.y, v.position.x - vx) - PI * 0.5
					else:
						rot = v.pivot.rotation.z
				if best < INF:
					away = smoothstep(RenderLook.AFTER_CLEAR.x, RenderLook.AFTER_CLEAR.y, best)
				if away <= 0.0:
					continue
				if int(own[0]) >= 0 and int(own[0]) < after_count.size():
					after_count[int(own[0])] += 1
				sx = RenderLook.AFTER_SIZE.x
				sy = RenderLook.AFTER_SIZE.y
				cy += 38.0
				c.a = RenderLook.AFTER_ALPHA * (1.0 - p.age / shown) * away
				inner = 1.0 if p.face == null or float(p.face) >= 0.0 else -1.0
				cz = sx
				cw = sy
			_:
				continue
		var o: int = n * STRIDE
		if flat:
			# Lying on the ground or water: the quad's x across, its y into the depth, its normal up.
			_buf[o] = sx
			_buf[o + 1] = 0.0
			_buf[o + 2] = 0.0
			_buf[o + 3] = cx
			_buf[o + 4] = 0.0
			_buf[o + 5] = 0.0
			_buf[o + 6] = 1.0
			_buf[o + 7] = cy
			_buf[o + 8] = 0.0
			_buf[o + 9] = sy
			_buf[o + 10] = 0.0
			_buf[o + 11] = 0.0
		else:
			var cs: float = cos(rot)
			var sn: float = sin(rot)
			_buf[o] = cs * sx
			_buf[o + 1] = -sn * sy
			_buf[o + 2] = 0.0
			_buf[o + 3] = cx
			_buf[o + 4] = sn * sx
			_buf[o + 5] = cs * sy
			_buf[o + 6] = 0.0
			_buf[o + 7] = cy
			_buf[o + 8] = 0.0
			_buf[o + 9] = 0.0
			_buf[o + 10] = 1.0
			_buf[o + 11] = pz
		_buf[o + 12] = c.r
		_buf[o + 13] = c.g
		_buf[o + 14] = c.b
		_buf[o + 15] = c.a
		_buf[o + 16] = SHAPE[p.type]
		_buf[o + 17] = inner
		_buf[o + 18] = cz
		_buf[o + 19] = cw
		n += 1
	return n
