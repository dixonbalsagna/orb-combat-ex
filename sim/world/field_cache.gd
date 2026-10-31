class_name WorldFieldCache
extends RefCounted
## A cache of a gen 3 planet's bake (docs/world/gen3-field.md; the EP's order of 2026-11-01: a warm visit under 10 s). The bake is 34,656 nodes of the planet's function, 1.7 s native, 5 to 7 s on a loaded web page
## and 6 to 11 s on the old laptop; it is a pure function of the planet's data and seed, so a repeat visit can read it back.
##
## Where: user://field-cache/, which is the page origin's IndexedDB on the web and a folder on disk natively. user:// is one folder for every copy of the project on a PC, so a file's name and its content both
## carry the WHOLE key: the data hash (WorldPlanet.dataHash(3): planet, climate, land, sites, rivers and field data), the Godot version, the seed, the generation, the cell count and the bake stride. A file is used only when
##   - its magic and its key text are exactly this key (the name is a hash of the key; the text inside is compared, so a collision is not a hit),
##   - its length and its SHA-256 checksum are right,
##   - six witness nodes, read fresh from the planet's function now, equal the file's values bit for bit (this catches a code change that the data hash cannot see),
##   - and the bake hash it rebuilds is the one an uncached bake gives (the hash is the same function of the same bits: it joins the match key, so a build whose cache disagreed would be refused at the handshake).
## Anything else is a miss and the bake runs as it always did; a bad read never fails a load. Files are written whole to a temporary name and renamed. At most `keep` files are kept (the oldest go).

const MAGIC := "WFC1"
const WITNESSES: int = 6
const CHUNK: int = 32768             # bytes of the checksum a slice takes

static var dirOverride: String = ""      # a tool's folder (set before use); "" the real one
static var enabledOverride: int = -1     # a tool's choice: -1 the data's, 0 off, 1 on
static var saltOverride: String = ""     # a tool's extra key text, to stand for a changed data hash
static var hits: int = 0
static var misses: int = 0
static var stores: int = 0


static func enabled() -> bool:
	if enabledOverride >= 0:
		return enabledOverride == 1
	return bool(WorldField.data().get("cache", {}).get("enabled", false))


static func keep() -> int:
	return int(WorldField.data().get("cache", {}).get("keep", 8))


static func dir() -> String:
	return dirOverride if dirOverride != "" else "user://field-cache/"


static func keyOf(F: WorldField.Field) -> String:
	var v: Dictionary = Engine.get_version_info()
	return "%s|%s|seed %d|gen 3|cells %d|stride %d|godot %s %s|%s" % [MAGIC, WorldPlanet.dataHash(3), F.seed, F.N, F.stride, str(v.get("string", "")), str(v.get("hash", "")), saltOverride]


static func _name(key: String) -> String:
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(key.to_utf8_buffer())
	return hc.finish().hex_encode().substr(0, 40) + ".wfc"


static func pathOf(F: WorldField.Field) -> String:
	return dir() + _name(keyOf(F))


static func _sha(b: PackedByteArray) -> PackedByteArray:
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(b)
	return hc.finish()


## The bake's nodes in bake order (face, j, i): their canonical indices.
static func _bakeIdx(F: WorldField.Field) -> PackedInt32Array:
	var bs: int = F.N / F.stride + 1
	var out := PackedInt32Array()
	out.resize(F.bakeN)
	var k: int = 0
	for face in range(6):
		for j in range(bs):
			for i in range(bs):
				out[k] = face * F.side * F.side + j * F.stride * F.side + i * F.stride
				k += 1
	return out


## Reads the planet's bake from the cache into F; true when F's bake is whole and hashed. False (and F untouched) for any miss or fault.
static func load(F: WorldField.Field) -> bool:
	if not enabled() or F.bakeDone:
		return false
	var path: String = pathOf(F)
	if not FileAccess.file_exists(path):
		misses += 1
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		misses += 1
		return false
	var all: PackedByteArray = f.get_buffer(f.get_length())
	f.close()
	var n: int = F.bakeN
	var key: String = keyOf(F)
	var kb: PackedByteArray = key.to_utf8_buffer()
	var head: int = 4 + 4 + kb.size() + 4
	var need: int = head + n * 4 + n + n + 32
	if all.size() != need or all.slice(0, 4).get_string_from_ascii() != MAGIC:
		misses += 1
		return false
	if all.decode_u32(4) != kb.size() or all.slice(8, 8 + kb.size()) != kb or all.decode_u32(8 + kb.size()) != n:
		misses += 1
		return false
	# the rest of the checks are WorldField.bakeStep's, a slice at a time (advance): the checksum in chunks, then the witnesses, then the copy and the hash
	F.cbytes = all
	F.cpos = 0
	F.csha = HashingContext.new()
	F.csha.start(HashingContext.HASH_SHA256)
	F.cstage = 1
	return true


## One slice of a staged load: the next chunk of the checksum; then, when it is whole and right, the witnesses and the set-up of the copy (F.pend). Returns true while staged or copying, false when the load was
## given up (a fault found): the bake then runs as if there had been no cache.
static func advance(F: WorldField.Field) -> bool:
	var n: int = F.bakeN
	var kb_len: int = F.cbytes.decode_u32(4)
	var head: int = 4 + 4 + kb_len + 4
	var need: int = F.cbytes.size()
	if F.cstage == 1:
		var upto: int = mini(F.cpos + CHUNK, need - 32)
		F.csha.update(F.cbytes.slice(F.cpos, upto))
		F.cpos = upto
		if F.cpos < need - 32:
			return true
		if F.csha.finish() != F.cbytes.slice(need - 32, need):
			_abort(F)
			return false
		F.cstage = 2
		return true
	# stage 2: the witnesses, then hand the arrays to the copy
	var hf: PackedFloat32Array = F.cbytes.slice(head, head + n * 4).to_float32_array()
	var bp: PackedByteArray = F.cbytes.slice(head + n * 4, head + n * 5)
	var fp: PackedByteArray = F.cbytes.slice(head + n * 5, head + n * 6)
	for w in range(WITNESSES):
		var k: int = mini((n * (2 * w + 1)) / (2 * WITNESSES) + 17 * w, n - 1)
		var ix: int = WorldField.bakeIdxOf(F, k)
		var face: int = ix / (F.side * F.side)
		var rem: int = ix - face * F.side * F.side
		var j: int = rem / F.side
		var i: int = rem - j * F.side
		WorldField._read(F, WorldField.dirOf(face, i, j, F.N))
		var fresh := PackedFloat32Array([WorldField._vh])
		if fresh[0] != hf[k] or WorldField._vb != bp[k] or WorldField._vf != fp[k]:
			_abort(F)
			return false
	F.pH = hf
	F.pB = bp
	F.pF = fp
	F.hasher = WorldField._newHasher(F)
	F.bakeK = 0
	F.pend = true
	F.cstage = 0
	F.cbytes = PackedByteArray()
	F.csha = null
	hits += 1
	return true


static func _abort(F: WorldField.Field) -> void:
	F.cstage = 0
	F.cbytes = PackedByteArray()
	F.csha = null
	F.pend = false
	misses += 1


## Writes F's whole bake to the cache (atomically), and drops the oldest files past `keep`. Nothing happens when the cache is off or the bake is not whole; a write that fails is ignored.
static func store(F: WorldField.Field) -> void:
	if not enabled() or not F.bakeDone:
		return
	DirAccess.make_dir_recursive_absolute(dir())
	var n: int = F.bakeN
	var key: String = keyOf(F)
	var kb: PackedByteArray = key.to_utf8_buffer()
	var idx: PackedInt32Array = _bakeIdx(F)
	var out := PackedByteArray()
	out.append_array(MAGIC.to_ascii_buffer())
	var tmp := PackedByteArray()
	tmp.resize(4)
	tmp.encode_u32(0, kb.size())
	out.append_array(tmp)
	out.append_array(kb)
	tmp.encode_u32(0, n)
	out.append_array(tmp)
	var hp := PackedByteArray()
	hp.resize(n * 4)
	var bp := PackedByteArray()
	bp.resize(n)
	var fp := PackedByteArray()
	fp.resize(n)
	for k in range(n):
		hp.encode_float(k * 4, F.h[idx[k]])
		bp[k] = F.b[idx[k]]
		fp[k] = F.f[idx[k]]
	out.append_array(hp)
	out.append_array(bp)
	out.append_array(fp)
	out.append_array(_sha(out))
	var path: String = pathOf(F)
	if OS.has_feature("web"):   # the page's IndexedDB is synced when a file is closed, not when one is renamed: write the final name directly (a torn write fails the checksum and is a miss)
		var wf := FileAccess.open(path, FileAccess.WRITE)
		if wf == null:
			return
		wf.store_buffer(out)
		wf.close()
		stores += 1
		_evict()
		return
	var w := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if w == null:
		return
	w.store_buffer(out)
	w.close()
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		DirAccess.remove_absolute(path + ".tmp")
		return
	stores += 1
	_evict()


## Keeps the newest `keep` files of the folder (by modified time) and removes the rest. Only files this module names (`*.wfc`) are touched.
static func _evict() -> void:
	var names: Array = []
	for fn in DirAccess.get_files_at(dir()):
		if fn.ends_with(".wfc"):
			names.append(fn)
	if names.size() <= keep():
		return
	names.sort_custom(func(a, b): return FileAccess.get_modified_time(dir() + a) > FileAccess.get_modified_time(dir() + b) or (FileAccess.get_modified_time(dir() + a) == FileAccess.get_modified_time(dir() + b) and a < b))
	for k in range(keep(), names.size()):
		DirAccess.remove_absolute(dir() + String(names[k]))


## ===================================================================== blobs: the same envelope for the other cached pieces (the made planet, the node pool)
## A blob is one file: MAGIC, the key text, the payload's length, the payload, then the SHA-256 of all before it. `readBlob` returns the payload, or an empty array for any miss or fault; `writeBlob` writes it whole
## (a rename natively, the final name on the web, as `store` does) and evicts. The key must carry its own kind and everything the payload depends on.
static func _blobPath(key: String) -> String:
	return dir() + _name(key)


static func readBlob(key: String) -> PackedByteArray:
	if not enabled():
		return PackedByteArray()
	var path: String = _blobPath(key)
	if not FileAccess.file_exists(path):
		misses += 1
		return PackedByteArray()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		misses += 1
		return PackedByteArray()
	var all: PackedByteArray = f.get_buffer(f.get_length())
	f.close()
	var kb: PackedByteArray = key.to_utf8_buffer()
	var head: int = 4 + 4 + kb.size() + 4
	if all.size() < head + 32 or all.slice(0, 4).get_string_from_ascii() != MAGIC or all.decode_u32(4) != kb.size() or all.slice(8, 8 + kb.size()) != kb:
		misses += 1
		return PackedByteArray()
	var plen: int = all.decode_u32(8 + kb.size())
	if all.size() != head + plen + 32 or _sha(all.slice(0, head + plen)) != all.slice(head + plen, head + plen + 32):
		misses += 1
		return PackedByteArray()
	return all.slice(head, head + plen)


static func writeBlob(key: String, payload: PackedByteArray) -> void:
	if not enabled():
		return
	DirAccess.make_dir_recursive_absolute(dir())
	var kb: PackedByteArray = key.to_utf8_buffer()
	var out := PackedByteArray()
	out.append_array(MAGIC.to_ascii_buffer())
	var tmp := PackedByteArray()
	tmp.resize(4)
	tmp.encode_u32(0, kb.size())
	out.append_array(tmp)
	out.append_array(kb)
	tmp.encode_u32(0, payload.size())
	out.append_array(tmp)
	out.append_array(payload)
	out.append_array(_sha(out))
	var path: String = _blobPath(key)
	if OS.has_feature("web"):
		var wf := FileAccess.open(path, FileAccess.WRITE)
		if wf == null:
			return
		wf.store_buffer(out)
		wf.close()
	else:
		var w := FileAccess.open(path + ".tmp", FileAccess.WRITE)
		if w == null:
			return
		w.store_buffer(out)
		w.close()
		if DirAccess.rename_absolute(path + ".tmp", path) != OK:
			DirAccess.remove_absolute(path + ".tmp")
			return
	stores += 1
	_evict()


## The key text common to every blob: data hash, Godot version, and any tool salt.
static func baseKey() -> String:
	var v: Dictionary = Engine.get_version_info()
	return "%s|%s|gen 3|godot %s %s|%s" % [MAGIC, WorldPlanet.dataHash(3), str(v.get("string", "")), str(v.get("hash", "")), saltOverride]
