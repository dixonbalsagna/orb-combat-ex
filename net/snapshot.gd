class_name NetSnapshot
extends RefCounted
## A snapshot of a whole SimState, and its restore (docs/net/rollback.md section 3). The sim keeps no snapshot API of
## its own, so this is a wrapper in net/ that copies the state graph by reflection: every script variable of every
## object reachable from S, with object identity kept (a fighter that game.ko, a clash, an exchange and a rush all point
## at is one fighter in the copy too), arrays and dictionaries copied deep, packed arrays duplicated.
##
## What is not copied:
##   - data definitions (FighterData's WoundsDef, MetersDef, LadderDef, SimForms' FormsDef): read-only after load, so
##     the copy points at the same object, as the live state does;
##   - S.out (the feed and the fx events): output for the host, drained every tick. restore() clears it.
##   - the fields a class names in its SNAPSHOT constant ({"share": [...], "skip": [...]}): a "share" field is a per-match
##     constant the copy points at, as the live state does (SimState's base and bIdx, a building's and a tree's generation
##     record `g`); a "skip" field is a view of another (a building's x reads its g.x) and is not a field of the copy at all.
##     Neither is counted by measure() or walked by aliasAudit(). The sim keeps a shared one unchanged (sim/core/state.gd).
##     A "shallow" field (an Array of packed arrays or sealed records: SimState's bFdmg, bG, tG) is copied one level
##     deep, its elements shared. A class whose SNAPSHOT says {"shared": true} (a building, a tree, their Hold and
##     generation records) is shared wherever it is met, as a data definition is: a building's per-tick fields are
##     SimState's packed arrays, which are copied, and restore() calls S.afterRestore() to point the records at them.
## Plain arrays and dictionaries are copied by value, so two fields that share one Array would come back as two arrays.
## aliasAudit() checks the live state has no such sharing (net/tools/rollback_check.gd runs it).
##
## restore() writes the copy into the same SimState object, so a host's reference to S stays good; references the host
## kept to objects inside S (a fighter, a building) do not: it reads them from S again after a rollback.
##
## Speed: reading and writing fields by name (Object.get/set) costs about a microsecond a field, and a match holds some
## 5,000 of them (a building alone has about thirty). So on first use the copier writes a GDScript with one typed copy
## function per class of the state (SimState's inner classes, SimRng, SimIntent), compiles it and dispatches to it; a
## typed field copies as a plain member assignment. It is built from the classes' own property lists each run, so a field
## the sim adds is copied with no change here. A class the generated code does not know (none today) and every run where
## compiling fails fall back to the reflective copy, which gives the same result. generatedSource() shows the code.

const SKIP_ROOT: Array = ["out"]   # SimState fields a snapshot leaves alone

static var _props: Dictionary = {}   # Script -> PackedStringArray of its script variables
static var _share: Dictionary = {}   # Script -> true: data definitions shared, never copied
static var _rules: Dictionary = {}   # Script -> its SNAPSHOT rule's "share" names (PackedStringArray)
static var _shallow: Dictionary = {} # Script -> its SNAPSHOT rule's "shallow" names (PackedStringArray)
static var _gen = null               # the compiled copy script (GDScript), or false when it could not be built
static var _genSrc: String = ""
static var reflectOnly: bool = false # tests: force the reflective copy
const SCALARS: Array = [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME]

var root: SimState = null   # the copy (never stepped)
var tick: int = 0           # the sim's S.tick when it was taken
var objs: Array = []        # every object of the copy but root, for the pool when the snapshot is dropped


## Copy S. With a pool, the copy is written into the objects of snapshots dropped earlier (Pool.put): a new object of
## the state's classes costs more than copying its fields, so a rollback loop that recycles allocates almost nothing.
static func take(S: SimState, pool: Pool = null) -> NetSnapshot:
	var snap := NetSnapshot.new()
	var c := Copier.new()
	c.pool = pool
	c.objs = snap.objs
	snap.root = pool.pop(SimState) if pool != null else null
	if snap.root == null:
		snap.root = SimState.new()
	c.map[S] = snap.root
	c.fill(S, snap.root, true)
	snap.tick = S.tick
	return snap


## Make S the state the snapshot holds. The snapshot itself stays as it was (it can be restored again). S's own
## objects are dropped: SimCore.dispose breaks their reference cycles first, so they are freed. With a pool, the
## restored objects are the pool's.
static func restore(S: SimState, snap: NetSnapshot, pool: Pool = null) -> void:
	SimCore.dispose(S)
	var c := Copier.new()
	c.pool = pool
	c.map[snap.root] = S
	c.fill(snap.root, S, true)
	S.afterRestore()   # the shared buildings and trees read the restored arrays
	S.out.feed.clear()
	S.out.fx.clear()


## Objects of dropped snapshots, by class, for the next take() to write into. clear() frees them.
class Pool:
	var free: Dictionary = {}   # Script -> Array of objects

	func put(snap: NetSnapshot) -> void:
		for o in snap.objs:
			var s: Script = o.get_script()
			if not free.has(s):
				free[s] = []
			free[s].append(o)
		if not free.has(SimState):
			free[SimState] = []
		free[SimState].append(snap.root)
		snap.objs = []
		snap.root = null

	func pop(s: Script) -> Object:
		var a = free.get(s)
		return a.pop_back() if a != null and not a.is_empty() else null

	## Free everything: the pooled objects can point at each other (a fighter's launchBy), so their object fields are
	## cleared first (reference counting does not free a cycle).
	func clear() -> void:
		for s in free:
			for o in free[s]:
				for k in NetSnapshot.props(o):
					if typeof(o.get(k)) == TYPE_OBJECT:
						o.set(k, null)
		free.clear()


## The script variables of an object's class, cached per script, less its SNAPSHOT "skip" names.
static func props(o: Object) -> PackedStringArray:
	var s: Script = o.get_script()
	if _props.has(s):
		return _props[s]
	var skip: Array = _rule(s).get("skip", [])
	var names := PackedStringArray()
	for p in o.get_property_list():
		if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and not skip.has(p.name):
			names.append(p.name)
	_props[s] = names
	return names


## A class's SNAPSHOT constant ({} when it has none).
static func _rule(s: Script) -> Dictionary:
	var r = s.get_script_constant_map().get("SNAPSHOT") if s is GDScript else null
	return r if r is Dictionary else {}


## The fields of an object's class that a snapshot shares (its SNAPSHOT "share" names), cached per script.
static func shareOf(o: Object) -> PackedStringArray:
	var s: Script = o.get_script()
	if not _rules.has(s):
		_rules[s] = PackedStringArray(_rule(s).get("share", []))
	return _rules[s]


## The fields of an object's class that a snapshot copies one level deep (its SNAPSHOT "shallow" names), cached per script.
static func shallowOf(o: Object) -> PackedStringArray:
	var s: Script = o.get_script()
	if not _shallow.has(s):
		_shallow[s] = PackedStringArray(_rule(s).get("shallow", []))
	return _shallow[s]


static func shared(o: Object) -> bool:
	_shareInit()
	return _share.has(o.get_script())


static func _shareInit() -> void:
	if _share.is_empty():
		for s in [FighterData.WoundsDef, FighterData.MetersDef, FighterData.LadderDef, SimForms.FormsDef]:
			_share[s] = true
		var m: Dictionary = SimState.new().get_script().get_script_constant_map()
		for k in m:
			if m[k] is GDScript and _rule(m[k]).get("shared", false):
				_share[m[k]] = true


## The classes the generated copier covers: SimState, its inner classes but the shared ones (a building, a tree: never
## copied), SimRng and SimIntent. [script, the expression that names it in GDScript].
static func _classes() -> Array:
	var out: Array = []
	var m: Dictionary = SimState.new().get_script().get_script_constant_map()
	var keys: Array = m.keys()
	keys.sort()
	for k in keys:
		if m[k] is GDScript and not _rule(m[k]).get("shared", false):
			out.append([m[k], "SimState." + String(k)])
	out.append([SimRng, "SimRng"])
	out.append([SimIntent, "SimIntent"])
	out.append([SimState, "SimState"])
	return out


## The generated copier's source: fill(s, d, m) copies s into d when it knows s's class (true), else returns false.
static func generatedSource() -> String:
	var head: String = "extends RefCounted\n## Generated by NetSnapshot (net/snapshot.gd) from the state's property lists. Do not edit.\n\n\nstatic func fill(s, d, m) -> bool:\n"
	var body: String = ""
	var i: int = 0
	for c in _classes():
		var script: GDScript = c[0]
		var name: String = c[1]
		var probe: Object = script.new() if script != SimRng else SimRng.new(0)
		head += "\tif s is %s:\n\t\t_c%d(s, d, m)\n\t\treturn true\n" % [name, i]
		body += "\n\nstatic func _c%d(s: %s, d: %s, m) -> void:\n" % [i, name, name]
		var n: int = 0
		var skip: Array = _rule(script).get("skip", [])
		var share: Array = _rule(script).get("share", [])
		var shallow: Array = _rule(script).get("shallow", [])
		for p in probe.get_property_list():
			if not (int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			var k: String = p.name
			if (script == SimState and SKIP_ROOT.has(k)) or skip.has(k):
				continue
			var t: int = int(p.type)
			if SCALARS.has(t) or share.has(k):
				body += "\td.%s = s.%s\n" % [k, k]
			elif t >= TYPE_PACKED_BYTE_ARRAY or shallow.has(k):
				body += "\td.%s = s.%s.duplicate()\n" % [k, k]
			else:
				body += "\td.%s = m.value(s.%s)\n" % [k, k]
			n += 1
		if n == 0:
			body += "\tpass\n"
		i += 1
	return head + "\treturn false\n" + body


static func _generated():
	if _gen == null:
		_genSrc = generatedSource()
		var g := GDScript.new()
		g.source_code = _genSrc
		_gen = g if g.reload() == OK else false
		if _gen is bool:
			push_error("NetSnapshot: the generated copier did not compile; the reflective copy is used")
	return _gen


## One copy pass: map holds every object already copied (source -> copy), so shared references stay shared.
class Copier:
	var map: Dictionary = {}
	var gen = null
	var pool: Pool = null
	var objs = null   # Array that collects the copies made, or null

	var share: Dictionary

	func _init() -> void:
		gen = null if NetSnapshot.reflectOnly else NetSnapshot._generated()
		if gen is bool:
			gen = null
		NetSnapshot._shareInit()
		share = NetSnapshot._share

	func fill(src: Object, dst: Object, isRoot: bool = false) -> void:
		if gen != null and gen.fill(src, dst, self):
			return
		var sh: PackedStringArray = NetSnapshot.shareOf(src)
		var sl: PackedStringArray = NetSnapshot.shallowOf(src)
		for k in NetSnapshot.props(src):
			if isRoot and NetSnapshot.SKIP_ROOT.has(k):
				continue
			if sh.has(k):
				dst.set(k, src.get(k))
			elif sl.has(k):
				dst.set(k, src.get(k).duplicate())
			else:
				dst.set(k, value(src.get(k)))

	func value(v):
		match typeof(v):
			TYPE_OBJECT:
				if v == null:
					return null
				var o = map.get(v)
				if o != null:
					return o
				var sc: Script = v.get_script()
				if share.has(sc):
					return v
				if pool != null:
					var fl = pool.free.get(sc)
					if fl != null and not fl.is_empty():
						o = fl.pop_back()
				if o == null:
					o = sc.new()
				map[v] = o
				if objs != null:
					objs.append(o)
				fill(v, o)
				return o
			TYPE_ARRAY:
				var a: Array = v.duplicate(false)   # keeps a typed array's type
				if a.is_typed() and a.get_typed_builtin() != TYPE_OBJECT and a.get_typed_builtin() < TYPE_DICTIONARY:
					return a   # numbers or strings only
				if a.size() >= 8:   # an untyped array of plain numbers (a style's buckets): the engine checks it, not a loop here
					var t0: int = typeof(a[0])
					if (t0 == TYPE_INT and Array(PackedInt64Array(a)) == a) or (t0 == TYPE_FLOAT and Array(PackedFloat64Array(a)) == a):
						return a   # (the comparison is strict on type, so a single non-number, or a NaN, takes the loop)
				for i in range(a.size()):
					var e = a[i]
					var t: int = typeof(e)
					if t == TYPE_OBJECT or t == TYPE_ARRAY or t == TYPE_DICTIONARY or t >= TYPE_PACKED_BYTE_ARRAY:
						a[i] = value(e)
				return a
			TYPE_DICTIONARY:
				var d: Dictionary = v.duplicate(false)
				for key in d:
					var e = d[key]
					var t: int = typeof(e)
					if t == TYPE_OBJECT or t == TYPE_ARRAY or t == TYPE_DICTIONARY or t >= TYPE_PACKED_BYTE_ARRAY:
						d[key] = value(e)
				return d
			_:
				if typeof(v) >= TYPE_PACKED_BYTE_ARRAY:
					return v.duplicate()
				return v


## Size and shape of a state: {objects, arrays, dicts, packed, scalars, bytes}. bytes estimates the payload a compact
## encoding would carry: 8 a number, 1 a bool, a string's UTF-8 length, a packed array's own bytes; containers free.
static func measure(S: SimState) -> Dictionary:
	var m := {"objects": 0, "arrays": 0, "dicts": 0, "packed": 0, "packedBytes": 0, "scalars": 0, "bytes": 0}
	var seen: Dictionary = {}
	seen[S] = true
	m.objects += 1
	var sh: PackedStringArray = shareOf(S)
	for k in props(S):
		if not SKIP_ROOT.has(k) and not sh.has(k):
			_measure(S.get(k), m, seen)
	return m


static func _measure(v, m: Dictionary, seen: Dictionary) -> void:
	match typeof(v):
		TYPE_NIL:
			m.scalars += 1
		TYPE_BOOL:
			m.scalars += 1
			m.bytes += 1
		TYPE_INT, TYPE_FLOAT:
			m.scalars += 1
			m.bytes += 8
		TYPE_STRING, TYPE_STRING_NAME:
			m.scalars += 1
			m.bytes += String(v).to_utf8_buffer().size()
		TYPE_OBJECT:
			if v == null or seen.has(v) or shared(v):
				return
			seen[v] = true
			m.objects += 1
			var sh: PackedStringArray = shareOf(v)
			for k in props(v):
				if not sh.has(k):
					_measure(v.get(k), m, seen)
		TYPE_ARRAY:
			m.arrays += 1
			for e in v:
				_measure(e, m, seen)
		TYPE_DICTIONARY:
			m.dicts += 1
			for key in v:
				_measure(v[key], m, seen)
		_:
			if typeof(v) >= TYPE_PACKED_BYTE_ARRAY:
				m.packed += 1
				var n: int = 0
				match typeof(v):
					TYPE_PACKED_BYTE_ARRAY:
						n = v.size()
					TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_FLOAT32_ARRAY:
						n = v.size() * 4
					TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
						n = v.size() * 8
					_:
						n = var_to_bytes(v).size()
				m.packedBytes += n
				m.bytes += n


## Arrays, dictionaries or packed arrays reachable from S by two paths: a snapshot would split them in two (a packed array
## in a field or an element is a reference too). Returns a list of "path and path" strings, empty when there is no
## sharing. Slow (a test tool, not for the tick).
static func aliasAudit(S: SimState) -> Array:
	var found: Array = []
	var bySize: Dictionary = {}   # size -> [[container, path], ...]
	var seen: Dictionary = {}
	seen[S] = true
	var sh: PackedStringArray = shareOf(S)
	for k in props(S):
		if not SKIP_ROOT.has(k) and not sh.has(k):
			_audit(S.get(k), "S." + k, seen, bySize, found)
	return found


static func _audit(v, path: String, seen: Dictionary, bySize: Dictionary, found: Array) -> void:
	match typeof(v):
		TYPE_OBJECT:
			if v == null or seen.has(v) or shared(v):
				return
			seen[v] = true
			var sh: PackedStringArray = shareOf(v)
			for k in props(v):
				if not sh.has(k):
					_audit(v.get(k), path + "." + k, seen, bySize, found)
		_:
			if typeof(v) < TYPE_DICTIONARY:
				return
			var key: String = "%d:%d" % [typeof(v), v.size()]
			var same: Array = bySize.get(key, [])
			for e in same:
				if is_same(e[0], v):
					found.append(e[1] + " and " + path)
					return
			same.append([v, path])
			bySize[key] = same
			if typeof(v) >= TYPE_PACKED_BYTE_ARRAY:
				return
			if typeof(v) == TYPE_ARRAY:
				for i in range(v.size()):
					_audit(v[i], "%s[%d]" % [path, i], seen, bySize, found)
			else:
				for key2 in v:
					_audit(v[key2], "%s[%s]" % [path, str(key2)], seen, bySize, found)
