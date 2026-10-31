class_name RenderWarmup
extends Node
## A warm-up draw at boot (Performance's audit, docs/perf/audit-2026-10-16.md 3.6: single frames of 150 to 510 ms at the
## same ticks of every match). Each of those ticks is the first time a shader is drawn in the match (Rendering's
## first-draw probe, docs/rendering/warmup.md): VFX's trail at the beam scene's tick 427; in the ring, VFX's crack at 211
## and the beam, its glow and Camera's inset mask at 279. The graphics driver compiles a shader the first time it is
## drawn. So at boot, behind the flashing-effects notice, every effect's shader is drawn once here, and no first draw
## is left for a fight.
##
## Nothing the game shows changes. The warm-up draws into its own small viewport, which no one shows, sharing the
## pane's world so the shaders are built as the game builds them. Its camera and quads stand WARM_DEPTH under the
## planet, far outside every game camera's view, and are freed WARM_FRAMES frames after the first draw. Presentation
## only: it reads nothing of the sim.

## [shader, how the game draws it]: "mesh" (a MeshInstance3D), "multimesh" (a MultiMeshInstance3D, drawn with each
## mix of instance colours and custom data, as the effects' pools differ), "canvas" (a CanvasItem). Another director's
## effect is added here when it is new (Performance's budget table: "no new first-use hitch").
const SHADERS: Array = [
	["res://render/vfx/shaders/beam.gdshader", "mesh"],          # VFX: the beams (ring tick 279)
	["res://render/vfx/shaders/beam_glow.gdshader", "mesh"],
	["res://render/vfx/shaders/crack.gdshader", "mesh"],         # VFX: ground cracks (ring tick 211)
	["res://render/vfx/shaders/trail.gdshader", "multimesh"],    # VFX: trails (beam scene tick 427)
	["res://render/vfx/shaders/shard.gdshader", "multimesh"],    # VFX: shards
	["res://render/vfx/shaders/transform.gdshader", "multimesh"],   # VFX: shots and the transformation
	["res://render/vfx/shaders/hole.gdshader", "multimesh"],     # VFX: holes in facades (VFX's warm-up.md)
	["res://render/vfx/shaders/dust.gdshader", "multimesh"],     # VFX: the tremor's dust curtains (dust_view.gd)
	["res://render/vfx/shaders/beam_scar.gdshader", "multimesh"],  # VFX: the scar a beam leaves in the air (scar_view.gd)
	["res://render/vfx/shaders/cloud.gdshader", "multimesh"],    # VFX: the blast cloud's body (docs/vfx/blast-cloud.md)
	["res://render/vfx/shaders/cloud_core.gdshader", "multimesh"], # VFX: the blast cloud's fireball (additive)
	["res://render/shaders/particle.gdshader", "multimesh"],     # Rendering: particles
	["res://render/shaders/flash.gdshader", "multimesh"],        # Rendering: hit flashes
	["res://render/shaders/glow.gdshader", "mesh"],              # Rendering: glows
	["res://render/shaders/guard.gdshader", "mesh"],             # Rendering: the guard's look
	["res://render/shaders/fighter_under.gdshader", "mesh"],     # Rendering: a fighter under deep water
	["res://render/shaders/fighter_hull_under.gdshader", "mesh"],
	["res://render/camera/panel_mask.gdshader", "canvas"],       # Camera: the inset panel (ring tick 279)
	["res://render/camera/split_mask.gdshader", "canvas"],       # Camera: the split
]
const WARM_DEPTH: float = -1.0e6
const WARM_FRAMES: int = 3

var _vp: SubViewport
var _frames: int = 0
var drawn: Array = []        # the shaders drawn (for the checks)


## Draws the warm-up into world (the pane's) and frees itself WARM_FRAMES frames later. A shader file that is missing
## is skipped.
func start(world: World3D) -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(64, 64)
	_vp.world_3d = world
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, WARM_DEPTH, 0.0)
	cam.near = 0.05
	cam.far = 100.0
	_vp.add_child(cam)
	cam.current = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var x: float = -4.0
	for e in SHADERS:
		if not ResourceLoader.exists(str(e[0])):
			continue
		var sh: Shader = load(str(e[0]))
		if sh == null:
			continue
		var mat := ShaderMaterial.new()
		mat.shader = sh
		match str(e[1]):
			"mesh":
				var mi := MeshInstance3D.new()
				mi.mesh = quad
				mi.material_override = mat
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mi.position = Vector3(x, WARM_DEPTH, -5.0)
				_vp.add_child(mi)
			"multimesh":
				for flags in [[false, false], [true, false], [false, true], [true, true]]:
					var mm := MultiMesh.new()
					mm.transform_format = MultiMesh.TRANSFORM_3D
					mm.use_colors = flags[0]
					mm.use_custom_data = flags[1]
					mm.mesh = quad
					mm.instance_count = 1
					mm.set_instance_transform(0, Transform3D.IDENTITY)
					var mmi := MultiMeshInstance3D.new()
					mmi.multimesh = mm
					mmi.material_override = mat
					mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					mmi.position = Vector3(x, WARM_DEPTH, -5.0)
					_vp.add_child(mmi)
			"canvas":
				var r := ColorRect.new()
				r.size = Vector2(8.0, 8.0)
				r.material = mat
				_vp.add_child(r)
		drawn.append(str(e[0]))
		x += 0.5


func _process(_delta: float) -> void:
	if _vp == null:
		return
	_frames += 1
	if _frames >= WARM_FRAMES:
		queue_free()
