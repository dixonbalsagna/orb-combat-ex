class_name RenderBoot
extends Node
## The boot's shader compile, spread over frames (Performance's phone-freeze report, docs/perf/phone-freeze-2026-10-26.md
## sections 1 and 3: the game's first frame was one block of 15.6 s, the graphics driver compiling every shader the scene
## and the boot warm-up draw at once; it does not shrink with the CPU, and a phone shows a frozen splash all the while).
##
## While it runs the panes draw nothing. Each frame it draws the next few of the scene's materials, and the effects'
## shaders the warm-up has always drawn (RenderWarmup.SHADERS), on small quads in a viewport of its own far under the
## planet, so the driver compiles a few programs a frame and the page keeps drawing. A plain line and a thin bar say
## so (static: no fade, no spinner). When every one has been drawn once the panes are shown again, and their first
## frame has nothing left to compile. How many a frame: one at first, more while the frames stay short
## (RenderLook.BOOT_FRAME_MS), one again after a long one.
##
## It replaces the warm-up's single frame (render/core/warmup.gd) at the game's start; the warm-up's list is the same.
## Presentation only: it reads nothing of the sim (main holds the sim while it runs).

signal done

const DEPTH: float = -1.0e6           # as RenderWarmup.WARM_DEPTH: under the planet, outside every game camera's view
const KEEP: int = 2                    # a drawn quad is freed this many frames later (it has been compiled)
## The programs the driver takes longest over (seconds each on D3D; docs/rendering/boot.md): drawn last, so the line
## is up and the bar has moved through the quick ones first.
const HEAVY: Array = ["terrain", "water", "building", "cover"]

var jobs: Array = []                   # [material, kind, use_colors, use_custom_data]: each distinct program the boot draws
var progress: float = 0.0              # the share of the jobs drawn, 0 to 1
var frame_ms: Array = []               # each boot frame's length (the probe's record)
var _vp: SubViewport
var _quad := QuadMesh.new()
var _next: int = 0
var _per: int = 1
var _live: Array = []                  # [node, frame added]
var _frames: int = 0
var _t: int = 0
var _hidden: Array = []                # [node, was visible]
var _line: CanvasLayer
var _bar: ColorRect
var _bar_w: float = 0.0
var _begun: bool = false               # begin() has run and the boot is not done


## The line up and the panes hidden, at once: the first match is built behind it (main.gd), then compile() starts.
func begin(panes: Array, words: String) -> void:
	_hide(panes)
	_line = _make_line(words)
	add_child(_line)
	_begun = true


## Collect the programs to compile from every pane (main.all_panes()) and the warm-up's list, hide any pane not hidden
## yet, and start. world: the pane's World3D (the boot's viewport shares it, so its environment is the scene's).
func compile(panes: Array, world: World3D) -> void:
	if _vp != null or not _begun:
		return   # once, between begin() and the end: a match started meanwhile draws the same programs, and the bar's count never grows
	var seen: Dictionary = {}
	for p in panes:
		_collect(p, seen)
	for e in RenderWarmup.SHADERS:
		if not ResourceLoader.exists(str(e[0])):
			continue
		var sh: Shader = load(str(e[0]))
		if sh == null:
			continue
		var mat := ShaderMaterial.new()
		mat.shader = sh
		if str(e[1]) == "multimesh":
			for f in [[false, false], [true, false], [false, true], [true, true]]:
				_add(seen, mat, "multimesh", f[0], f[1])
		else:
			_add(seen, mat, str(e[1]), false, false)
	# The quick ones first, the heavy ones last (the order they were found in otherwise).
	var light: Array = []
	var heavy: Array = []
	for j in jobs:
		(heavy if _heavy(j[0]) else light).append(j)
	jobs = light + heavy
	_hide(panes)
	_vp = SubViewport.new()
	_vp.size = Vector2i(64, 64)
	_vp.world_3d = world
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, DEPTH, 0.0)
	cam.near = 0.05
	cam.far = 100.0
	_vp.add_child(cam)
	cam.current = true
	_quad.size = Vector2(1.0, 1.0)
	_t = Time.get_ticks_usec()


func _hide(panes: Array) -> void:
	for p in panes:
		var seen: bool = false
		for h in _hidden:
			seen = seen or h[0] == p
		if not seen:
			_hidden.append([p, p.visible])
			p.visible = false


## Whether the programs are being compiled (compile() has run and the boot is not done).
func compiling() -> bool:
	return _vp != null


## Whether the boot is still running: the first match being built, or the programs being compiled.
func running() -> bool:
	return _begun or _vp != null


func _process(_delta: float) -> void:
	if _vp == null:
		return
	var now: int = Time.get_ticks_usec()
	var ms: float = float(now - _t) / 1000.0
	_t = now
	_frames += 1
	if _frames > 1:
		frame_ms.append(ms)
		# More a frame while the frames stay short, one again after a long one.
		_per = 1 if ms > RenderLook.BOOT_FRAME_MS else mini(_per + 1, RenderLook.BOOT_PER_MAX)
	for i in range(_live.size() - 1, -1, -1):
		if _frames - int(_live[i][1]) >= KEEP:
			(_live[i][0] as Node).queue_free()
			_live.remove_at(i)
	if _frames == 1:
		return   # the first frame shows the line and draws nothing else, so it is up before any compile
	if _next >= jobs.size():
		if _live.is_empty():
			_finish()
		return
	for k in range(_per):
		if _next >= jobs.size():
			break
		_live.append([_draw(jobs[_next], _next), _frames])
		_next += 1
	progress = float(_next) / float(maxi(jobs.size(), 1))
	_set_line(progress)


func _finish() -> void:
	for h in _hidden:
		(h[0] as Node3D).visible = bool(h[1])
	_hidden.clear()
	_vp.queue_free()
	_vp = null
	_begun = false
	_line.queue_free()
	progress = 1.0
	done.emit()


## Every distinct program a pane draws: each mesh's and multimesh's material, with the multimesh's instance data flags.
func _collect(n: Node, seen: Dictionary) -> void:
	if n is MultiMeshInstance3D:
		var mmi := n as MultiMeshInstance3D
		var mm: MultiMesh = mmi.multimesh
		if mm != null:
			var mats: Array = [mmi.material_override] if mmi.material_override != null else _mesh_mats(mm.mesh)
			for m in mats:
				_add(seen, m, "multimesh", mm.use_colors, mm.use_custom_data)
	elif n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override != null:
			_add(seen, mi.material_override, "mesh", false, false)
		elif mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var m: Material = mi.get_active_material(s)
				if m != null:
					_add(seen, m, "mesh", false, false)
	for c in n.get_children():
		_collect(c, seen)


static func _heavy(m: Material) -> bool:
	var path: String = (m as ShaderMaterial).shader.resource_path if m is ShaderMaterial and (m as ShaderMaterial).shader != null else ""
	for h in HEAVY:
		if path.get_file().begins_with(h):
			return true
	return false


static func _mesh_mats(mesh: Mesh) -> Array:
	var out: Array = []
	if mesh != null:
		for s in range(mesh.get_surface_count()):
			if mesh.surface_get_material(s) != null:
				out.append(mesh.surface_get_material(s))
	return out


## One job per program: a shader material's shader (its materials share one), any other material itself, by how it is drawn.
func _add(seen: Dictionary, m: Material, kind: String, colors: bool, custom: bool) -> void:
	if m == null:
		return
	var who = (m as ShaderMaterial).shader if m is ShaderMaterial else m
	if who == null:
		return
	var key: String = "%d|%s|%d|%d" % [who.get_instance_id(), kind, int(colors), int(custom)]
	if seen.has(key):
		return
	seen[key] = true
	jobs.append([m, kind, colors, custom])


func _draw(j: Array, i: int) -> Node:
	var pos := Vector3(-4.0 + 0.25 * float(i % 32), DEPTH + 0.25 * float(i >> 5), -5.0)
	match str(j[1]):
		"multimesh":
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = bool(j[2])
			mm.use_custom_data = bool(j[3])
			mm.mesh = _quad
			mm.instance_count = 1
			mm.set_instance_transform(0, Transform3D.IDENTITY)
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.material_override = j[0]
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.position = pos
			_vp.add_child(mmi)
			return mmi
		"canvas":
			var r := ColorRect.new()
			r.size = Vector2(8.0, 8.0)
			r.material = j[0]
			_vp.add_child(r)
			return r
		_:
			var mi := MeshInstance3D.new()
			mi.mesh = _quad
			mi.material_override = j[0]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.position = pos
			_vp.add_child(mi)
			return mi


## The line under the splash: plain words and a thin bar, centred on a dark ground over the hidden panes and under UI's
## layer (the notice and the cards stay over it); the bar moves a whole percent at a time.
func _make_line(words: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 0   # over the 3D, under the HUD's layer (1): UI's notice and cards draw over it
	var bg := ColorRect.new()
	bg.color = RenderLook.col(RenderLook.BOOT_GROUND)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(centre)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(box)
	var label := Label.new()
	label.text = words
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", RenderLook.col(RenderLook.BOOT_INK))
	box.add_child(label)
	var track := ColorRect.new()
	track.custom_minimum_size = Vector2(RenderLook.BOOT_BAR.x, RenderLook.BOOT_BAR.y)
	track.color = RenderLook.col(RenderLook.BOOT_TRACK)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE   # the line never takes a click or a tap: UI's notice and cards have them all
	box.add_child(track)
	_bar = ColorRect.new()
	_bar.color = RenderLook.col(RenderLook.BOOT_INK)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.size = Vector2(0.0, RenderLook.BOOT_BAR.y)
	track.add_child(_bar)
	return layer


func _set_line(p: float) -> void:
	var w: float = floor(p * 100.0) / 100.0 * RenderLook.BOOT_BAR.x   # a whole percent: nothing redraws between
	if w != _bar_w:
		_bar_w = w
		_bar.size = Vector2(w, RenderLook.BOOT_BAR.y)
