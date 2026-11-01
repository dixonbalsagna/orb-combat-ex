extends SceneTree
## DirLocation's tables follow the line: after a turn, a bucket's biome is the biome under the line now, and a new planet in the same
## process doesn't read the last one's.
##   godot --headless --path . --script res://sim/director/tools/location_check.gd
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	_rows()
	print("LOCATION: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _stale() -> int:
	DirLocation._ensure()
	var bad: int = 0
	for k in range(DirLocation.BUCKETS):
		var want: int = DirLocation.BIOMES.find(WorldBiomes.biomeAt((float(k) + 0.5) * DirLocation.STEP))
		if DirLocation._bucketBiome[k] != want:
			bad += 1
	return bad


func _rows() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	SimCore.step(S, [SimIntent.new(), SimIntent.new()])
	_expect(_stale() == 0, "at the start, the buckets read the line")
	var before: PackedInt32Array = DirLocation._bucketBiome.duplicate()
	SimField.data()["limitOff"] = true
	SimSwing.ask(S, {"deg": 60.0, "cause": "launch"})
	var guard: int = 0
	while S.swing.active and guard < 900:
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
		S.out.fx.clear()
		S.out.feed.clear()
		guard += 1
	SimField.data()["limitOff"] = false
	_expect(guard < 900, "the turn rested (%d)" % guard)
	var n: int = _stale()
	_expect(n == 0, "after a turn, the buckets read the new line (%d stale)" % n)
	_expect(DirLocation._bucketBiome != before, "and they've changed")
	SimCore.dispose(S)
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 12, {"p1": false, "p2": false}, {"planet": 11, "touch": 0, "planetGen": 3, "intro": false})
	SimCore.step(S2, [SimIntent.new(), SimIntent.new()])
	n = _stale()
	_expect(n == 0, "another planet in the same process reads its own (%d stale)" % n)
	SimCore.dispose(S2)
