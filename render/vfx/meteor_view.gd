class_name VfxMeteorView
extends Node3D
## Draws the meteor trail of one pane (docs/vfx/meteor-trail.md): each fighter's runs (meteor.gd) as a ribbon of three nested layers, one mesh a fighter, rebuilt each frame from the points in view. Widths are
## kept to a PIXEL floor and ceiling (data/vfx/meteor.json, for a 1,280-wide screen, growing with width) so the trail never thins out at a wide zoom; below the floor it stops thinning and dims by the root
## of the shortfall, never under 0.6. The pane supplies its camera x, zoom and depth. Reads only: draws no random number, writes nothing of the sim; the pattern's clock is the sim's (`S.T`).

var last: Dictionary = {}                  # the last frame's numbers, for the tests: runs, points, verts, px of the widest core
var verts_drawn: int = 0
var _mi: Array = []
var _mesh: Array = []
var _mat: Array = []
var _pan_t: float = -1.0           # the sim clock at the last camera reading (the camera's speed is read once a tick)
var _pan_x: float = 0.0
var _pan_w: float = 0.0            # the camera's speed across the world, in screen widths a second


func _ready() -> void:
	for i in range(2):
		var mesh := ArrayMesh.new()
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://render/vfx/shaders/meteor.gdshader")
		mat.render_priority = 1
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.custom_aabb = AABB(Vector3(-90000.0, -30000.0, -200.0), Vector3(180000.0, 90000.0, 400.0))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.name = "Slot%d" % i
		add_child(mi)
		_mesh.append(mesh)
		_mat.append(mat)
		_mi.append(mi)


## a: the frame's interpolation between the last two ticks. zoom: this pane's pixels per unit on the fighter plane; half_w: half the visible width in world units; cam_dist: the camera's distance to that plane.
func update(hub: VfxHub, host, a: float, cam_x: float, zoom: float, half_w: float, cam_dist: float) -> void:
	var m: VfxMeteor = hub.meteor
	var calm: bool = hub.reduced_motion or hub.reduced_flashing
	var q: int = clampi(hub.quality, 0, 2)
	var vw: float = half_w * 2.0 * zoom
	var sc: float = vw / VfxMeteor.fp("px_ref")
	var floor_sc: float = maxf(sc, 1.0)
	var ceil_sc: float = maxf(sc, 0.5)
	var cap: int = int(VfxMeteor.fa("draw_pts")[q])
	var lim: float = half_w * 1.5 + 1500.0
	var verts_total: int = 0
	var pts_total: int = 0
	var runs_total: int = 0
	var core_px: float = 0.0
	var layer_k: Array = VfxMeteor.fa("layer_k")
	var layer_a: Array = VfxMeteor.fa("layer_alpha")
	var floor_px: Array = VfxMeteor.fa("floor_px")
	var ceil_px: Array = VfxMeteor.fa("ceil_px")
	var wf_mul: Array = VfxMeteor.fa("wfloor_mul")
	var wf_hot: float = lerpf(1.0, VfxMeteor.fp("wfloor_hot"), smoothstep(VfxMeteor.fp("wfloor_from"), VfxMeteor.fp("wfloor_to"), half_w * 2.0))   # at the peak width a point's colour and alpha cool by only this share of its age: the trail stays hot along its length
	var wf: float = smoothstep(VfxMeteor.fp("wfloor_from"), VfxMeteor.fp("wfloor_to"), half_w * 2.0)   # how far the view is out toward the peak shot's width: the floors grow with it, since the fighters shrink to about 2 px there and the trail carries the picture
	var base_w: float = VfxMeteor.fp("base_w")
	var z_off: float = VfxMeteor.fp("z_off")
	var end_n: int = maxi(int(VfxMeteor.fp("end_taper_pts")), 1)
	var strength: float = VfxMeteor.fp("calm_strength") if calm else 1.0
	# A world-anchored ribbon crossing the pane fast (the camera riding along a launch, a whip) is a bright band sweeping the whole pane: it dims with the camera's speed across the world (`pan_k` is its share at `pan_to` screen widths a second). The flash reading follows motion as well as area.
	var t_now: float = host.S.T
	if t_now != _pan_t:
		if _pan_t >= 0.0 and t_now > _pan_t:
			_pan_w = absf(SimWrap.sdx(_pan_x, cam_x)) / maxf(half_w * 2.0, 1.0) / (t_now - _pan_t)
		_pan_t = t_now
		_pan_x = cam_x
	var pan_k: float = VfxMeteor.fp("pan_k")
	if hub.flight_enabled and not hub.meteor_burn_enabled:
		pan_k = maxf(pan_k, VfxMeteor.flp("pan_k"))     # a flight line is laid along the path the camera follows: it is not a band sweeping the pane, so the camera's speed dims it less
	strength *= lerpf(1.0, pan_k, smoothstep(VfxMeteor.fp("pan_from"), VfxMeteor.fp("pan_to"), _pan_w))
	var wide_k: float = VfxMeteor.fp("wide_k")
	var bright_k: float = VfxMeteor.fp("bright_k")
	var wide_from: float = VfxMeteor.fp("wide_from")
	var wide_to: float = VfxMeteor.fp("wide_to")
	for slot in range(2):
		var vtx := PackedVector3Array()
		var col := PackedColorArray()
		var uv := PackedVector2Array()
		var uv2 := PackedVector2Array()
		var idx := PackedInt32Array()
		var look: Dictionary = {}
		for r in m.runs:
			if r.slot != slot or r.x.size() == 0:
				continue
			var n: int = r.x.size()
			var head: bool = r.live and m.cur[slot] == r and slot < host.S.fighters.size()
			# The points in view (and one beyond each side so the ribbon runs off the screen), then a stable thinning: every stride-th point by its number, never by its place in the list.
			var inside := PackedByteArray()
			inside.resize(n)
			var any: bool = false
			for j in range(n):
				var vj: float = absf(SimWrap.sdx(cam_x, r.x[j]))
				if vj <= lim:
					inside[j] = 1
					any = true
			var hx: float = 0.0
			var hy: float = 0.0
			var hz: float = 0.0
			if head:
				hx = host.fighter_x(slot, a)
				hy = host.fighter_pose(slot, a).y + VfxMeteor.fp("chest_y")
				hz = host.fighter_z(slot, a)
				if absf(SimWrap.sdx(cam_x, hx)) <= lim:
					any = true
			if not any:
				continue
			var pick: Array = []
			for j in range(n):
				if inside[j] == 1 or (j > 0 and inside[j - 1] == 1) or (j < n - 1 and inside[j + 1] == 1):
					pick.append(j)
			var stride: int = 1
			while pick.size() / stride > cap:
				stride *= 2
			var pos := PackedVector2Array()
			var pz := PackedFloat32Array()
			var ps := PackedFloat64Array()
			var page := PackedFloat32Array()
			var pb := PackedFloat32Array()
			var pw := PackedFloat32Array()
			var pe := PackedFloat32Array()
			var plife := PackedFloat32Array()        # each point's life: the run's times its altitude length
			for k in range(pick.size()):
				var j: int = pick[k]
				var last_pt: bool = k == pick.size() - 1
				if not (last_pt or (r.base + j) % stride == 0):
					continue
				pos.append(Vector2(SimWrap.sdx(cam_x, r.x[j]), r.y[j]))
				pz.append(r.z[j])
				ps.append(r.s[j])
				page.append(m.clock - r.born[j])
				pb.append(r.b[j])
				pw.append(r.w[j])
				plife.append(r.life * r.lk[j])
				# the burn-out end of a run that is no longer laid narrows to a point over its last few points
				var from_end: int = n - 1 - j
				pe.append(1.0 if (r.live or from_end >= end_n) else float(from_end) / float(end_n))
			if head and pos.size() > 0:
				pos.append(Vector2(SimWrap.sdx(cam_x, hx), hy))
				pz.append(hz)
				ps.append(r.acc)
				page.append(0.0)
				pb.append(m.kb[slot])
				pw.append(pw[pw.size() - 1])
				plife.append(plife[plife.size() - 1])
				pe.append(1.0)
			# The ribbon is sampled finer near the body: the head's width cap bends the outline over a few body heights, and a knot every few hundred units would draw it as one kink.
			if head and pos.size() > 2:
				var lim_s: float = VfxMeteor.fp("head_len_bh") * VfxLook.BH * 1.5
				var hs: float = ps[ps.size() - 1]
				var pos2 := PackedVector2Array()
				var pz2 := PackedFloat32Array()
				var ps2 := PackedFloat64Array()
				var page2 := PackedFloat32Array()
				var pb2 := PackedFloat32Array()
				var pw2 := PackedFloat32Array()
				var pe2 := PackedFloat32Array()
				var plife2 := PackedFloat32Array()
				for k in range(pos.size()):
					pos2.append(pos[k])
					pz2.append(pz[k])
					ps2.append(ps[k])
					page2.append(page[k])
					pb2.append(pb[k])
					pw2.append(pw[k])
					pe2.append(pe[k])
					plife2.append(plife[k])
					if k < pos.size() - 1 and hs - ps[k] < lim_s:
						for sub in range(1, 4):
							var tt: float = float(sub) / 4.0
							pos2.append(pos[k].lerp(pos[k + 1], tt))
							pz2.append(lerpf(pz[k], pz[k + 1], tt))
							ps2.append(lerpf(ps[k], ps[k + 1], tt))
							page2.append(lerpf(page[k], page[k + 1], tt))
							pb2.append(lerpf(pb[k], pb[k + 1], tt))
							pw2.append(lerpf(pw[k], pw[k + 1], tt))
							pe2.append(lerpf(pe[k], pe[k + 1], tt))
							plife2.append(lerpf(plife[k], plife[k + 1], tt))
				pos = pos2
				pz = pz2
				ps = ps2
				page = page2
				pb = pb2
				pw = pw2
				pe = pe2
				plife = plife2
			var np: int = pos.size()
			if np < 2:
				continue
			runs_total += 1
			pts_total += np
			look = r.look
			var cols: Array = look.get("cols", [Color.WHITE, Color.WHITE, Color.WHITE])
			var width_k: float = float(look.get("width_k", 1.0))
			var wc: float = float(look.get("w_cool", -1.0))
			var ws: float = float(look.get("w_smoulder", -1.0))
			var dk: float = float(look.get("deep_dark", -1.0))
			# A line that has stopped being laid and draws tight (the Empress's): it straightens toward its two ends, from the tail to where she stopped, over `settle_s`.
			var settle: float = float(look.get("settle", 0.0))
			if settle > 0.0 and not r.live and r.ended >= 0.0 and np > 2:
				var tset: float = settle * smoothstep(0.0, VfxMeteor.flp("settle_s"), m.clock - r.ended)
				pos = VfxMeteor.settle(pos, tset)
			for li in range(3):
				var v0: int = vtx.size()
				for k in range(np):
					var p: Vector2 = pos[k]
					var d: Vector2
					if k == 0:
						d = pos[1] - p
					elif k == np - 1:
						d = p - pos[k - 1]
					else:
						d = pos[k + 1] - pos[k - 1]
					if d.length() < 1e-6:
						d = Vector2.RIGHT
					d = d.normalized()
					var nrm := Vector2(-d.y, d.x)
					var ds: float = cam_dist / maxf(cam_dist - pz[k], 1.0)
					var age: float = page[k]
					var w_true: float = base_w * float(layer_k[li]) * width_k * pw[k] * VfxMeteor.phase_w(age, plife[k], wc, ws)
					var px_true: float = w_true * zoom * ds
					var fl: float = float(floor_px[li]) * floor_sc * lerpf(1.0, float(wf_mul[li]), wf)
					var cap_px: float = maxf(float(ceil_px[li]) * ceil_sc, fl)
					if head:
						cap_px = maxf(VfxMeteor.head_cap_px(ps[np - 1] - ps[k], VfxLook.BH * zoom * ds, float(ceil_px[li]) / maxf(float(ceil_px[0]), 1.0), cap_px), fl)   # near the body the ribbon never reads as a body-wide flame (RL-222)
					var px: float = clampf(px_true, fl, cap_px)
					var fl0: float = float(floor_px[li]) * floor_sc       # the floor before it grew with the view's width: the dim for being thin is measured against it, so the wider trail is not a dimmer one
					var comp: float = 1.0 if px_true >= fl0 else clampf(sqrt(maxf(px_true, 0.0) / fl0), 0.6, 1.0)
					comp *= lerpf(1.0, wide_k, smoothstep(wide_from, wide_to, px / fl))   # a ribbon that covers many pixels is dimmer: the flash reading follows area, a thin far one keeps its full strength
					if li == 2:
						core_px = maxf(core_px, px)
					var w_world: float = px / maxf(zoom * ds, 1e-6) * VfxMeteor.taper_at(age, plife[k]) * pe[k]
					var c: Color = VfxMeteor.heat(cols[li], age * wf_hot, plife[k], dk)
					c.a = float(layer_a[li]) * clampf(pb[k] * bright_k, 0.0, 1.0) * VfxMeteor.alpha_at(age * wf_hot, plife[k]) * comp * strength
					var zz: float = pz[k] + z_off
					var half: Vector2 = nrm * w_world * 0.5
					vtx.append(Vector3(p.x + half.x, p.y + half.y, zz))
					vtx.append(Vector3(p.x - half.x, p.y - half.y, zz))
					col.append(c)
					col.append(c)
					uv.append(Vector2(ps[k], 1.0))
					uv.append(Vector2(ps[k], -1.0))
					var u2 := Vector2(float(li), age / maxf(plife[k], 1e-6))
					uv2.append(u2)
					uv2.append(u2)
				for k in range(np - 1):
					var b0: int = v0 + k * 2
					idx.append(b0)
					idx.append(b0 + 1)
					idx.append(b0 + 2)
					idx.append(b0 + 1)
					idx.append(b0 + 3)
					idx.append(b0 + 2)
		var mesh: ArrayMesh = _mesh[slot]
		mesh.clear_surfaces()
		if vtx.size() > 0:
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vtx
			arrays[Mesh.ARRAY_COLOR] = col
			arrays[Mesh.ARRAY_TEX_UV] = uv
			arrays[Mesh.ARRAY_TEX_UV2] = uv2
			arrays[Mesh.ARRAY_INDEX] = idx
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			verts_total += vtx.size()
			var mat: ShaderMaterial = _mat[slot]
			var front: float = float(VfxMeteor.name_id("fronts", String(look.get("front", "wall"))))
			var tex: float = float(VfxMeteor.name_id("textures", String(look.get("texture", "none"))))
			mat.set_shader_parameter("look", Vector4(front, tex, float(look.get("scale", 100.0)), float(look.get("braid", 0.0)) * (0.0 if q == 0 else 1.0)))   # the lowest level drops the braid and the sparks first
			mat.set_shader_parameter("hue", float(look.get("hue", 0.08)))
			mat.set_shader_parameter("hz", VfxMeteor.fp("hz_calm") if calm else VfxMeteor.fp("hz"))
			mat.set_shader_parameter("flow", 0.0 if hub.reduced_motion else VfxMeteor.fp("pattern_flow"))
			mat.set_shader_parameter("glow_cap", VfxMeteor.fp("glow_cap"))
			mat.set_shader_parameter("time", host.S.T)
			mat.set_shader_parameter("fx", Vector4(float(look.get("gaps", 1.0)), float(look.get("dull", 0.0)), float(look.get("spark", 0.0)) * (0.0 if q == 0 else 1.0), float(look.get("gap_lo", 0.30))))
			var rc: Color = look.get("rim_c", Color.BLACK)
			mat.set_shader_parameter("rimc", Vector4(rc.r, rc.g, rc.b, float(look.get("rim_k", 0.9)) if look.has("rim_c") else 0.0))
	verts_drawn = verts_total
	last = {"runs": runs_total, "points": pts_total, "verts": verts_total, "core_px": core_px, "hot": wf_hot}
