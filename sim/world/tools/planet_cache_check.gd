extends SceneTree
# The made-planet cache (World, sim/world/planet_cache.gd): a hit gives the grid and the places bit for bit, a fault is a miss that builds as before, the job finishes at once on a hit, and the code that makes a
# planet has not changed under the cache's CODE_REV (the digests below are the made planet's, held in planet_cache_vectors.json under the rev).
#   godot --headless --path . --script res://sim/world/tools/planet_cache_check.gd -- [--write]     (--write prints the vectors for the file; update them and bump WorldPlanetCache.CODE_REV together)
const VECTORS := "res://sim/world/tools/planet_cache_vectors.json"
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _made(seed: int) -> WorldPlanet.Planet:
	WorldPlanet.forget()
	WorldClimate.useGen(3)
	return WorldPlanet.make(seed)


func _init() -> void:
	var write: bool = "--write" in OS.get_cmdline_user_args()
	var seeds: Array = [7, 3]
	# fresh planets with the cache off: their digests
	WorldFieldCache.enabledOverride = 0
	var dig: Dictionary = {}
	for s in seeds:
		dig[s] = WorldPlanetCache.digest(_made(s))
	if write:
		print("VECTORS ", JSON.stringify({"rev": WorldPlanetCache.CODE_REV, "digests": {"7": dig[7], "3": dig[3]}}))
	var vj = JSON.parse_string(FileAccess.get_file_as_string(VECTORS))
	if vj is Dictionary:
		ok(int(vj.rev) == WorldPlanetCache.CODE_REV, "the vectors are for CODE_REV %d (the file's %d)" % [WorldPlanetCache.CODE_REV, int(vj.rev)])
		for s in seeds:
			ok(str(vj.digests.get(str(s), "")) == dig[s], "the made planet %d is the vectors' (%s): if this fails the planet's code changed, so update the vectors and bump WorldPlanetCache.CODE_REV" % [s, dig[s]])
	else:
		ok(false, "planet_cache_vectors.json loads")
	# the cache, in a folder of its own
	var d: String = "user://planet-cache-check/"
	WorldFieldCache.dirOverride = d
	WorldFieldCache.enabledOverride = 1
	DirAccess.make_dir_recursive_absolute(d)
	for fn in DirAccess.get_files_at(d):
		DirAccess.remove_absolute(d + fn)
	ok(WorldPlanetCache.enabled(), "the planet cache is on in field.json")
	var P1 := _made(7)   # a miss: built, then stored
	ok(not DirAccess.get_files_at(d).is_empty(), "a made planet is written")
	var t0: int = Time.get_ticks_usec()
	var P2 := _made(7)   # a hit
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
	ok(WorldPlanetCache.digest(P2) == dig[7] and P2.n == P1.n, "a repeat visit has the same planet: %d places, digest %s (%.0f ms here)" % [P2.n, WorldPlanetCache.digest(P2), ms])
	var same: bool = true
	for k in range(P1.n):
		if P1.px[k] != P2.px[k] or P1.py[k] != P2.py[k] or P1.pz[k] != P2.pz[k] or P1.rad[k] != P2.rad[k] or P1.kind[k] != P2.kind[k] or P1.people[k] != P2.people[k]:
			same = false
	for k in range(P1.grid.adv.size()):
		if P1.grid.adv[k] != P2.grid.adv[k] or P1.grid.ht[k] != P2.grid.ht[k]:
			same = false
			break
	ok(same, "every place and every grid cell is the same bits")
	# the biome a hit gives at a point is the biome a build gives (the grid is what climate reads)
	var q: Array = WorldField.dirOf(2, 91, 130, 300)
	WorldPlanet.surfAt(P1, q[0], q[1], q[2])
	var b1: int = P1.outB
	var h1: float = P1.outH
	WorldPlanet.surfAt(P2, q[0], q[1], q[2])
	ok(b1 == P2.outB and h1 == P2.outH, "the ground at a point is the same from a cached planet")
	# the planet job finishes at once on a hit
	WorldPlanet.forget()
	var job: WorldPlanet.PlanetJob = WorldPlanet.makeJob(7)
	ok(job.done, "the planet job is done at its start on a hit")
	# a fault is a miss: a flipped byte
	var files: PackedStringArray = DirAccess.get_files_at(d)
	var path: String = d + String(files[0])
	var raw: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var bad := raw.duplicate()
	bad[bad.size() / 3] = (bad[bad.size() / 3] + 1) & 255
	var w := FileAccess.open(path, FileAccess.WRITE)
	w.store_buffer(bad)
	w.close()
	var P3 := _made(7)
	ok(WorldPlanetCache.digest(P3) == dig[7], "a flipped byte is a miss and the planet is built as before")
	# a stale height with a right checksum: the witness refuses it
	WorldPlanet.forget()
	var Pw := _made(7)   # rewrites a good file
	var payload: PackedByteArray = WorldPlanetCache.pack(Pw)
	var n: int = payload.decode_u32(0)
	payload.encode_float(12 + n * 4 + 0, payload.decode_float(12 + n * 4) + 5.0)   # ht[0]
	WorldFieldCache.writeBlob(WorldPlanetCache.keyOf(7), payload)
	var P4 := _made(7)
	ok(WorldPlanetCache.digest(P4) == dig[7], "a stale height with a right checksum is a miss (the witness cells)")
	# the key is whole
	WorldFieldCache.saltOverride = "other data"
	var P5 := _made(7)
	ok(WorldPlanetCache.digest(P5) == dig[7], "another data hash finds nothing and builds")
	WorldFieldCache.saltOverride = ""
	for fn in DirAccess.get_files_at(d):
		DirAccess.remove_absolute(d + fn)
	DirAccess.remove_absolute(d)
	WorldFieldCache.dirOverride = ""
	WorldFieldCache.enabledOverride = -1
	print("PLANETCACHE: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
