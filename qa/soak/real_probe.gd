extends Node
## Real memory beside the census (QA; EP's hour-long run, 2026-11-26). Scratch only, never in the game: qa/soak/real-memory.mjs names it as an autoload in an override.cfg of a scratch copy of a commit,
## run with the EDITOR build headless, whose OS.get_static_memory_usage() works (a release program's reads 0).
## It plays computer-against-computer matches (--rm-cap sim seconds each, the next seed after each). 20 s into each match and at each match's end it prints the static memory, the census (soak_census.gd)
## and what the engine holds for the scene outside script values (mesh, multimesh, texture and audio data, by node and resource). Once, 20 s into the match named by --rm-final-match, or the first match
## that starts after --rm-final-after seconds, it takes the memory apart: every list, dictionary and packed array reachable from the match state, the recorder, the host, the scene and the scripts'
## statics is emptied one by one, deepest first, and the static memory each gives back is read; then the whole scene is freed and read; then it quits in the same frame. Destructive on purpose.

var cap: float = 600.0
var final_match: int = 0
var final_after: float = 0.0

var _t0: int = 0
var _main: Node = null
var _match: int = 1
var _census = null
var _statics: Array = []        # [[script, field, label]]
var _at: int = -1               # when the running match's start reading is due (msec)
var _over_since: int = -1
var _starting: bool = false
var _done: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 100000   # after the game's own work in a frame: nothing runs on an emptied game before the quit
	var names: String = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--rm-cap="):
			cap = float(a.substr(9))
		elif a.begins_with("--rm-final-match="):
			final_match = int(a.substr(17))
		elif a.begins_with("--rm-final-after="):
			final_after = float(a.substr(17))
		elif a.begins_with("--rm-names="):
			names = a.substr(11)
	_t0 = Time.get_ticks_msec()
	var here: String = get_script().resource_path.get_base_dir()
	_census = load(here.path_join("soak_census.gd")).new()
	_census.setup(FileAccess.get_file_as_string(names).split("\n", false))
	_statics = _census._statics


func _mib(n: int) -> float:
	return n / 1048576.0


func _secs() -> float:
	return (Time.get_ticks_msec() - _t0) / 1000.0


func _process(_d: float) -> void:
	if _done:
		return
	var now: int = Time.get_ticks_msec()
	if _main == null:
		var cs = get_tree().current_scene
		if cs != null and "host" in cs and cs.host != null and cs.host.S != null and cs.host.S.fighters.size() >= 2 and cs.host.match_job == null:
			_main = cs
			_at = now + 20000
			print("RM main t=%.0f" % _secs())
		return
	var host = _main.host
	if host.match_job != null or host.load_job != null or host.S.fighters.size() < 2:
		return
	var S = host.S
	var over: bool = S.game.ko != null or (_main.ui_hud != null and bool(_main.ui_hud.hub.no_contest))
	if _starting:
		if not over and float(S.T) < 5.0:
			_starting = false
			_at = now + 20000
		return
	if _at >= 0 and now >= _at:
		_at = -1
		var last: bool = (final_match > 0 and _match >= final_match) or (final_after > 0.0 and _secs() >= final_after)
		_read("start")
		if last:
			_done = true
			_take_apart()
			get_tree().quit(0)
		return
	if not over and float(S.T) < cap:
		_over_since = -1
		return
	if _over_since < 0:
		_over_since = now
		print("RM ended match=%d how=%s simSeconds=%.1f t=%.0f" % [_match, "ko" if S.game.ko != null else ("no-contest" if over else "capped"), float(S.T), _secs()])
		_read("end")
		return
	if now - _over_since < 4000:
		return
	_over_since = -1
	_starting = true
	_match += 1
	_main.start_match(_match)


## What the engine holds for the scene's nodes and resources outside script values (headless, so the dummy renderer's own copies): estimated bytes by kind. Each resource once.
func _engine_held() -> Dictionary:
	var out := {"meshes": 0, "multimeshes": 0, "textures": 0, "audio": 0, "nodes": 0}
	var seen: Dictionary = {}
	var todo: Array = [get_tree().root]
	while not todo.is_empty():
		var n = todo.pop_back()
		out.nodes += 1
		for c in n.get_children(true):
			todo.append(c)
		var res: Array = []
		if n is MeshInstance3D or n is MeshInstance2D:
			res.append(n.mesh)
		if n is MultiMeshInstance3D or n is MultiMeshInstance2D:
			res.append(n.multimesh)
		if n is AudioStreamPlayer or n is AudioStreamPlayer2D or n is AudioStreamPlayer3D:
			res.append(n.stream)
		for p in ["material_override", "material", "texture"]:
			if p in n:
				res.append(n.get(p))
		while not res.is_empty():
			var r = res.pop_back()
			if r == null or not (r is Resource) or seen.has(r.get_instance_id()):
				continue
			seen[r.get_instance_id()] = true
			if r is MultiMesh:
				out.multimeshes += r.instance_count * 4 * (12 + (4 if r.use_colors else 0) + (4 if r.use_custom_data else 0))
				res.append(r.mesh)
			elif r is ArrayMesh:
				for s in range(r.get_surface_count()):
					for a in r.surface_get_arrays(s):
						if a is PackedVector3Array:
							out.meshes += 12 * a.size()
						elif a is PackedColorArray:
							out.meshes += 16 * a.size()
						elif a is PackedVector2Array:
							out.meshes += 8 * a.size()
						elif a is PackedFloat32Array or a is PackedInt32Array:
							out.meshes += 4 * a.size()
						elif a is PackedByteArray:
							out.meshes += a.size()
			elif r is ImageTexture:
				var im: Image = r.get_image()
				if im != null:
					out.textures += im.get_data().size()
			elif r is ImageTextureLayered:
				var one: Image = r.get_layer_data(0)
				if one != null:
					out.textures += one.get_data().size() * r.get_layers()
			elif r is AudioStreamWAV:
				out.audio += r.data.size()
			elif r is ShaderMaterial and r.shader != null:
				for u in r.shader.get_shader_uniform_list():
					res.append(r.get_shader_parameter(u.name))
	return out


func _read(when: String) -> void:
	var stat: int = OS.get_static_memory_usage()
	var data: Dictionary = _census.take(_main)
	var engine: Dictionary = _engine_held()
	print("RM %s match=%d t=%.0f staticMiB=%.2f peakMiB=%.2f censusMiB=%.2f objects=%d nodes=%d resources=%d engine=%s data=%s" % [when, _match, _secs(), _mib(stat), _mib(OS.get_static_memory_peak_usage()),
		_mib(int(data.get("_total", 0))), int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		JSON.stringify(engine), JSON.stringify(data)])


func _script_vars(o: Object) -> Array:
	var names: Array = []
	for p in o.get_property_list():
		if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names.append(str(p.name))
	return names


## The object's class name, or "" for an inner class (its script has no name or path of its own): the caller then names it by where it was reached from.
func _class_of(o: Object) -> String:
	var sc = o.get_script()
	if sc == null:
		return o.get_class()
	var g: String = sc.get_global_name()
	return g if g != "" else sc.resource_path.get_file()


func _label(o: Object, reached: String) -> String:
	var c: String = _class_of(o)
	return c if c != "" else reached


## Every container reachable from the roots and the statics, with how deep it sits: [depth, label, holder object (or script), field, container].
func _targets() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	var host = _main.host
	var queue: Array = []   # [value, depth, label, holder, field]
	for root in [["match state", host.S], ["recorder", host.recorder], ["host", host], ["scene", _main]]:
		queue.append([root[1], 0, root[0], null, ""])
	for s in _statics:
		queue.append([s[0].get(s[1]), 1, "static " + s[2].trim_prefix("static "), s[0], s[1]])
	var head: int = 0
	while head < queue.size() and head < 4000000:
		var it: Array = queue[head]
		head += 1
		var v = it[0]
		var kind: int = typeof(v)
		if kind == TYPE_OBJECT:
			if v == null or not is_instance_valid(v) or seen.has(v.get_instance_id()) or v is Script:
				continue
			seen[v.get_instance_id()] = true
			if v.get_script() != null:
				var cls: String = _label(v, it[2])
				for f in _script_vars(v):
					var x = v.get(f)
					if typeof(x) >= TYPE_STRING:
						queue.append([x, it[1] + 1, cls + "." + f, v, f])
		elif kind >= TYPE_DICTIONARY:
			if it[3] != null:
				out.append([it[1], it[2], it[3], it[4], v])
			if kind == TYPE_ARRAY:
				for x in v:
					if typeof(x) >= TYPE_STRING:
						queue.append([x, it[1] + 1, it[2] + "[]", null, ""])
			elif kind == TYPE_DICTIONARY:
				for k in v:
					var x = v[k]
					if typeof(x) >= TYPE_STRING:
						queue.append([x, it[1] + 1, it[2] + "{}", null, ""])
	return out


func _take_apart() -> void:
	var before: int = OS.get_static_memory_usage()
	var targets: Array = _targets()
	targets.sort_custom(func(a, b): return a[0] > b[0])
	var sums: Dictionary = {}
	var base: int = OS.get_static_memory_usage()   # the list of targets itself is not the game's memory
	for t in targets:
		var m0: int = OS.get_static_memory_usage()
		var v = t[4]
		match typeof(v):
			TYPE_ARRAY, TYPE_DICTIONARY:
				if v.is_read_only():
					continue
				v.clear()
			TYPE_PACKED_BYTE_ARRAY:
				t[2].set(t[3], PackedByteArray())
			TYPE_PACKED_INT32_ARRAY:
				t[2].set(t[3], PackedInt32Array())
			TYPE_PACKED_INT64_ARRAY:
				t[2].set(t[3], PackedInt64Array())
			TYPE_PACKED_FLOAT32_ARRAY:
				t[2].set(t[3], PackedFloat32Array())
			TYPE_PACKED_FLOAT64_ARRAY:
				t[2].set(t[3], PackedFloat64Array())
			TYPE_PACKED_STRING_ARRAY:
				t[2].set(t[3], PackedStringArray())
			TYPE_PACKED_VECTOR2_ARRAY:
				t[2].set(t[3], PackedVector2Array())
			TYPE_PACKED_VECTOR3_ARRAY:
				t[2].set(t[3], PackedVector3Array())
			TYPE_PACKED_COLOR_ARRAY:
				t[2].set(t[3], PackedColorArray())
		v = null
		t[4] = null
		sums[t[1]] = int(sums.get(t[1], 0)) + (m0 - OS.get_static_memory_usage())
	var emptied: int = base - OS.get_static_memory_usage()
	var rows: Array = []
	for k in sums:
		if abs(sums[k]) >= 52428:
			rows.append([k, snappedf(_mib(sums[k]), 0.01)])
	rows.sort_custom(func(a, b): return a[1] > b[1])
	print("RM apart match=%d t=%.0f staticMiB=%.2f listsEmptiedMiB=%.2f targets=%d rows=%s" % [_match, _secs(), _mib(before), _mib(emptied), targets.size(), JSON.stringify(rows)])
	targets.clear()
	var s0: int = OS.get_static_memory_usage()
	var scene: Node = _main
	_main = null
	scene.get_parent().remove_child(scene)
	scene.free()
	var s1: int = OS.get_static_memory_usage()
	print("RM scene match=%d sceneFreedMiB=%.2f leftMiB=%.2f" % [_match, _mib(s0 - s1), _mib(s1)])
