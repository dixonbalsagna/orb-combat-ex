extends SceneTree
# The bake cache (World, sim/world/field_cache.gd): a hit gives the bits an uncached bake gives, any fault is a miss that bakes as before, the key is whole, the files are bounded.
#   godot --headless --path . --script res://sim/world/tools/field_cache_check.gd -- [--planet=7]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _fresh(seed: int) -> WorldField.Field:
	WorldPlanet.forget()
	WorldClimate.useGen(3)
	return WorldField.of(WorldPlanet.make(seed))


func _bake(F: WorldField.Field) -> void:
	while not WorldField.bakeStep(F, 100000):
		pass


func _rm_all(d: String) -> void:
	for fn in DirAccess.get_files_at(d):
		if fn.ends_with(".wfc") or fn.ends_with(".tmp"):
			DirAccess.remove_absolute(d + fn)


func _init() -> void:
	var planet: int = 7
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
	var d: String = "user://field-cache-check/"
	WorldFieldCache.dirOverride = d
	WorldFieldCache.enabledOverride = 1
	DirAccess.make_dir_recursive_absolute(d)
	_rm_all(d)
	# a miss, a bake, a store
	var F1: WorldField.Field = _fresh(planet)
	ok(not WorldFieldCache.load(F1), "an empty cache is a miss")
	var t0: int = Time.get_ticks_usec()
	_bake(F1)
	var bake_ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
	var H: String = F1.bakeHash
	WorldFieldCache.store(F1)
	var path: String = WorldFieldCache.pathOf(F1)
	ok(FileAccess.file_exists(path), "the bake is written (%d bytes)" % FileAccess.open(path, FileAccess.READ).get_length())
	# a hit: the same bits, the same hash, faster
	var F2: WorldField.Field = _fresh(planet)
	var t1: int = Time.get_ticks_usec()
	var hit: bool = WorldFieldCache.load(F2)
	print("  info the check itself (key, checksum, witnesses): %.0f ms" % (float(Time.get_ticks_usec() - t1) / 1000.0))
	var load_ms: float = float(Time.get_ticks_usec() - t1) / 1000.0
	var steps: int = 0
	while hit and not WorldField.bakeStep(F2, 250):
		steps += 1
	ok(hit and F2.bakeDone and F2.fromCache and F2.bakeHash == H, "a repeat visit reads the bake back with the same hash (%s) in %d slices of 250 units" % [F2.bakeHash, steps])
	ok(H == WorldField._hashBake(F1), "the hash folded in as the nodes were baked is the hash of the finished bake")
	print("  info bake %.0f ms, read back %.0f ms (native, this machine)" % [bake_ms, load_ms])
	var same: bool = true
	var idx: PackedInt32Array = WorldFieldCache._bakeIdx(F1)
	for k in range(idx.size()):
		if F1.h[idx[k]] != F2.h[idx[k]] or F1.b[idx[k]] != F2.b[idx[k]] or F1.f[idx[k]] != F2.f[idx[k]]:
			same = false
			break
	ok(same, "every bake node is the same bits as the uncached bake")
	# nodeFresh (Simulation's match key reads its sample through it): the planet's function now, whatever the cache holds
	var nf_ok: bool = true
	var P2c: WorldPlanet.Planet = F2.P
	for k in range(0, idx.size(), 3000):
		var ixf: int = idx[k]
		var ff: int = ixf / (F2.side * F2.side)
		var rf: int = ixf - ff * F2.side * F2.side
		var jf: int = rf / F2.side
		var jf_i: int = rf - jf * F2.side
		var fr: Array = WorldField.nodeFresh(P2c, ff, jf_i, jf)
		if fr[0] != F2.h[ixf] or fr[1] != F2.b[ixf] or fr[2] != F2.f[ixf]:
			nf_ok = false
	ok(nf_ok, "nodeFresh gives the cached bake's nodes (a fresh read of the planet's function agrees with the cache)")
	var Ftam: WorldField.Field = _fresh(planet)
	_bake(Ftam)
	Ftam.h[idx[3000]] += 1.0   # a corrupted held node
	ok(WorldField.nodeFresh(Ftam.P, idx[3000] / (Ftam.side * Ftam.side), (idx[3000] % (Ftam.side * Ftam.side)) % Ftam.side, (idx[3000] % (Ftam.side * Ftam.side)) / Ftam.side)[0] != Ftam.h[idx[3000]], "and it does not read the held nodes: a corrupted held node is caught")
	# and the ground a match stands on is the same: the canonical read of a cell between bake nodes after a hit
	var q: Array = WorldField.dirOf(1, 103, 211, F1.N)
	WorldField.sample(F1, q[0], q[1], q[2])
	var a: float = F1.oh
	WorldField.sample(F2, q[0], q[1], q[2])
	ok(a == F2.oh, "a read between bake nodes is the same after a hit")
	# faults are misses
	var raw: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var tampered := raw.duplicate()
	tampered[tampered.size() / 2] = (tampered[tampered.size() / 2] + 1) & 255
	var w := FileAccess.open(path, FileAccess.WRITE)
	w.store_buffer(tampered)
	w.close()
	var F3: WorldField.Field = _fresh(planet)
	ok(_faulty(F3, H), "a flipped byte is found by the checksum, a slice later, and the bake runs as before to the same hash")
	var cut := raw.slice(0, raw.size() - 100)
	w = FileAccess.open(path, FileAccess.WRITE)
	w.store_buffer(cut)
	w.close()
	ok(not WorldFieldCache.load(_fresh(planet)), "a truncated file is a miss")
	# a stale value with a right checksum (a code change the data hash cannot see): the witnesses catch it
	var stale := raw.duplicate()
	var n: int = F1.bakeN
	var head: int = 4 + 4 + WorldFieldCache.keyOf(F1).to_utf8_buffer().size() + 4
	var k0: int = (n * 1) / (2 * WorldFieldCache.WITNESSES)
	stale.encode_float(head + k0 * 4, stale.decode_float(head + k0 * 4) + 1.0)
	var body: PackedByteArray = stale.slice(0, stale.size() - 32)
	var sum: PackedByteArray = WorldFieldCache._sha(body)
	for i in range(32):
		stale[stale.size() - 32 + i] = sum[i]
	w = FileAccess.open(path, FileAccess.WRITE)
	w.store_buffer(stale)
	w.close()
	ok(_faulty(_fresh(planet), H), "a stale witness value with a right checksum is found by the witnesses and the bake runs as before to the same hash")
	# the key is whole: another seed, and a changed data hash (the salt stands for one), find nothing
	w = FileAccess.open(path, FileAccess.WRITE)
	w.store_buffer(raw)
	w.close()
	var F4: WorldField.Field = _fresh(planet)
	ok(WorldFieldCache.load(F4), "the untouched file is a hit again")
	ok(not WorldFieldCache.load(_fresh(planet + 1)), "another seed is a miss")
	WorldFieldCache.saltOverride = "other data"
	ok(not WorldFieldCache.load(_fresh(planet)), "another data hash is a miss")
	WorldFieldCache.saltOverride = ""
	# the switch
	WorldFieldCache.enabledOverride = 0
	ok(not WorldFieldCache.load(_fresh(planet)), "the switch off reads nothing")
	WorldFieldCache.enabledOverride = 1
	# the files are bounded: keep from the data
	var kp: int = WorldFieldCache.keep()
	for s in range(kp + 3):
		var Fx: WorldField.Field = _fresh(100 + s)
		_bake_small(Fx)
		WorldFieldCache.store(Fx)
	var count: int = 0
	for fn in DirAccess.get_files_at(d):
		if fn.ends_with(".wfc"):
			count += 1
	ok(count <= kp, "at most %d files are kept (%d now)" % [kp, count])
	_rm_all(d)
	DirAccess.remove_absolute(d)
	WorldFieldCache.dirOverride = ""
	WorldFieldCache.enabledOverride = -1
	print("FIELDCACHE: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)


## A bake made quickly for the bound test: a few nodes read, the rest zero, marked whole (only its file count matters there).
func _bake_small(F: WorldField.Field) -> void:
	for k in range(F.bakeN):
		var bs: int = F.N / F.stride + 1
		var face: int = k / (bs * bs)
		var r: int = k - face * bs * bs
		var idx: int = face * F.side * F.side + (r / bs) * F.stride * F.side + (r % bs) * F.stride
		F.b[idx] = 0
		F.h[idx] = 0.0
		F.f[idx] = 0
	F.bakeK = F.bakeN
	F.bakeHash = WorldField._hashBake(F)
	F.bakeDone = true


## Loads F from the cache and steps to the end as a load job does: true when the cache was given up (a fault found in a slice) and the bake ran as before to the hash `H`.
func _faulty(F: WorldField.Field, H: String) -> bool:
	var staged: bool = WorldFieldCache.load(F)
	var guard: int = 0
	while not WorldField.bakeStep(F, 250):
		guard += 1
		if guard > 5000:
			return false
	return staged and not F.fromCache and F.bakeHash == H
