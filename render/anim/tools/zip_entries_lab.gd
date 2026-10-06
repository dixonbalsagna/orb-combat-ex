extends SceneTree
## Zip entries lab (docs/animation/zip.md): every entry of a fighter played at a zip's speed (`_entry_layer` with `fit`: the whole sequence squeezed into the zip's ticks), one frame a tick, to see
## whether it reads drawn the whole way (Legal RL-076) and to find the ones whose poses are too far apart for the time. One raw file (tools/gif.mjs and rgb_sheet.mjs read it): for each entry,
## frames 0 to N (N = --ticks, default 6), so `rgb_sheet.mjs out.png in.rgb --cols 7` is a sheet of a row an entry. The metrics go to the console: the largest turn of any bone between two
## ticks (rad) and the bone it was.
##   godot --no-window --path . -s res://render/anim/tools/zip_entries_lab.gd -- --fighter=protagonist --ticks=6 --out=a.rgb [--measure]
const DT := 1.0 / 60.0
const FIGHTERS := {"protagonist": "PROTAGONIST", "antihero": "RIVAL"}
var fighter: String = "protagonist"
var ticks: int = 6
var out: String = "zip_entries.rgb"
var measure: bool = false
var size := Vector2i(150, 170)
var main: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fighter="):
			fighter = a.substr(10)
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a == "--measure":
			measure = true
	var vpn := SubViewport.new()
	vpn.size = Vector2i(640, 360)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	AnimData.load_all()
	var key: String = AnimData.ensure_fighter(String(FIGHTERS[fighter]))
	var names: Array = AnimData.pair_lists[key].entries.keys()
	names.sort()
	var sv: SubViewport = null
	var body: AnimBody = null
	var fa: FileAccess = null
	if not measure:
		sv = SubViewport.new()
		sv.size = size
		sv.own_world_3d = true
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(sv)
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.13, 0.15, 0.22)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.8, 0.8, 0.85)
		var cam := Camera3D.new()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 105.0
		cam.environment = env
		sv.add_child(cam)
		cam.position = Vector3(0.0, 0.0, 300.0)
		cam.current = true
		var pal := {"body": Color("#3d8fdc"), "legs": Color("#1b1f2a"), "arms": Color("#e6b995"), "skin": Color("#efc7a2"), "gear": Color("#cdd6e4"), "accent": Color("#4fb9a8"), "hair": Color("#22c7a0")}
		if fighter == "antihero":
			pal = {"body": Color("#2a2043"), "legs": Color("#181228"), "arms": Color("#b98462"), "skin": Color("#b98462"), "gear": Color("#cbd3e2"), "accent": Color("#9a80d8"), "hair": Color("#1d1630")}
		var pv := Node3D.new()
		sv.add_child(pv)
		body = AnimBody.new()
		body.build(pal, false)
		pv.add_child(body)
		pv.position = Vector3(0.0, -40.0, 0.0)
		fa = FileAccess.open(out, FileAccess.WRITE)
		fa.store_32(size.x)
		fa.store_32(size.y)
		fa.store_32(names.size() * (ticks + 1))
	var af := AnimFighter.new(0)
	af.pair_key = key
	var base: AnimPose = AnimData.pose("stance.aggressive")
	var rows: Array = []
	for nm in names:
		var id: String = String(AnimData.pair_lists[key].entries[nm])
		var prev: Array[Quaternion] = []
		var worst: float = 0.0
		var wb: String = ""
		for k in range(ticks + 1):
			af.q = base.q.duplicate()
			af.hips = base.hips
			af.curl = base.curl
			af._base = base.q.duplicate()
			af._entry_layer(0.0, float(ticks) * DT, id, float(k) * DT, DT, 1.0, true)
			if not prev.is_empty():
				for b in range(1, AnimRig.N):
					var d: float = prev[b].angle_to(af.q[b])
					if d > worst:
						worst = d
						wb = String(AnimRig.BONES[b][0])
			prev = af.q.duplicate()
			if not measure:
				body.apply(af.q, af.hips, af.curl, Vector3.ZERO)
				for _w in range(3):
					await process_frame
				var img: Image = sv.get_texture().get_image()
				img.convert(Image.FORMAT_RGB8)
				fa.store_buffer(img.get_data())
		rows.append("%-16s %.2f rad (%s)" % [nm, worst, wb])
	if fa != null:
		fa.close()
		print("ENTRIES LAB ", out, " ", names.size(), " entries x ", ticks + 1, " frames")
	print("zip entries lab %s at %d ticks, the largest turn of a bone between two ticks:\n  %s" % [fighter, ticks, "\n  ".join(rows)])
	quit(0)
