extends RefCounted
## The store census of the soak (qa/soak/soak.mjs --census; EP's faster hunt, 2026-11-26). Scratch only, like the probe. It READS: every field of the match state, of the replay recorder, of the host and of
## the game's main scene, and every top-level static var of the game's scripts, and adds up what each holds (elements and an estimate of bytes), so that what grows from one match to the next can be named.
## The byte figures are estimates (packed arrays by their element size; a plain Array 24 bytes a slot, a Dictionary 64 an entry, an object 128 plus its script fields): they rank and compare, they do not
## add up to the process's memory. An object is counted once, by the first root that reaches it. Memory the engine holds outside script values (renderer, audio server, physics) is not seen.

const DEPTH: int = 12
const BUDGET: int = 6000000
const KEEP: int = 4096   # only entries of at least this many estimated bytes are printed

var _seen: Dictionary = {}
var _left: int = BUDGET
var _statics: Array = []   # [[script, field, label]]
var _names: Dictionary = {}   # a script -> its field names, read once


## `names`: lines of "res://path.gd|name", the static vars of the build's commit.
func setup(names: PackedStringArray) -> int:
	for line in names:
		var kv: PackedStringArray = line.strip_edges().split("|")
		if kv.size() != 2 or not ResourceLoader.exists(kv[0]):
			continue
		var sc = load(kv[0])
		if sc != null:
			_statics.append([sc, kv[1], "static %s:%s" % [kv[0].trim_prefix("res://"), kv[1]]])
	return _statics.size()


func _fields(o: Object) -> PackedStringArray:
	var out := PackedStringArray()
	for p in o.get_property_list():
		if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out.append(str(p.name))
	return out


## [estimated bytes, elements] are added to _b and _c: no array is made per value, so the walk itself allocates little.
var _b: int = 0
var _c: int = 0


func _size(v, depth: int) -> void:
	_left -= 1
	if _left < 0 or depth > DEPTH:
		return
	match typeof(v):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT:
			_b += 24
			_c += 1
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			_b += 32 + 4 * str(v).length()
			_c += 1
		TYPE_PACKED_BYTE_ARRAY:
			_b += v.size()
			_c += v.size()
		TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_FLOAT32_ARRAY:
			_b += 4 * v.size()
			_c += v.size()
		TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_VECTOR2_ARRAY:
			_b += 8 * v.size()
			_c += v.size()
		TYPE_PACKED_VECTOR3_ARRAY:
			_b += 12 * v.size()
			_c += v.size()
		TYPE_PACKED_COLOR_ARRAY, TYPE_PACKED_VECTOR4_ARRAY:
			_b += 16 * v.size()
			_c += v.size()
		TYPE_PACKED_STRING_ARRAY:
			for s in v:
				_b += 32 + 4 * s.length()
			_c += v.size()
		TYPE_ARRAY:
			_b += 24 * v.size()
			_c += v.size()
			for x in v:
				if typeof(x) >= TYPE_STRING:
					_size(x, depth + 1)
		TYPE_DICTIONARY:
			_b += 64 * v.size()
			_c += v.size()
			for k in v:
				if typeof(k) >= TYPE_STRING:
					_size(k, depth + 1)
				var x = v[k]
				if typeof(x) >= TYPE_STRING:
					_size(x, depth + 1)
		TYPE_OBJECT:
			if v == null or not is_instance_valid(v):
				return
			var id: int = v.get_instance_id()
			if _seen.has(id) or v is Script:
				return
			_seen[id] = true
			_c += 1
			if v is Image:
				_b += v.get_data().size()
				return
			if v is AudioStreamWAV:
				_b += v.data.size()
				return
			_b += 128
			var sc = v.get_script()
			if sc != null:
				if not _names.has(sc):
					_names[sc] = _fields(v)
				for f in _names[sc]:
					_size(v.get(f), depth + 1)
		_:
			_b += 24
			_c += 1


## One root: its bytes, elements, and (a container) how many entries it holds at the top.
func _add(out: Dictionary, label: String, v) -> void:
	_b = 0
	_c = 0
	_size(v, 0)
	out["_total"] = int(out.get("_total", 0)) + _b
	if _b >= KEEP:
		var top: int = v.size() if typeof(v) == TYPE_ARRAY or typeof(v) == TYPE_DICTIONARY or typeof(v) >= TYPE_PACKED_BYTE_ARRAY else -1
		out[label] = [_b, _c, top]


## The census of one moment. `main` is the game's main scene.
func take(main) -> Dictionary:
	_seen.clear()
	_left = BUDGET
	var out: Dictionary = {}
	var host = main.host
	var roots: Array = [["S.", host.S, []], ["recorder.", host.recorder, []], ["host.", host, ["S", "recorder"]], ["main.pane.", main.pane, []], ["main.", main, ["host", "pane"]]]
	for root in roots:
		_seen[root[1].get_instance_id()] = true
	for root in roots:
		for f in _fields(root[1]):
			if not root[2].has(f):
				_add(out, root[0] + f, root[1].get(f))
	for s in _statics:
		_add(out, s[2], s[0].get(s[1]))
	if _left < 0:
		out["_truncated"] = true
	return out
