extends SceneTree
## Simulation's half of buildings at every place (docs/architecture/field-ground.md): godot --headless --path . --script res://sim/core/tools/places_check.gd
## The index holds exactly the band, through swings, a rest and a rollback; the far poses arrive; the hash skips only what nothing has touched; a beam's cap is the first ring's.

var fails: int = 0


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func _start(on: bool, planet: int = 7) -> SimState:
	WorldClimate.useGen(3)
	WorldPlan.everywhereOverride = 1 if on else 0
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": false, "p2": false}, {"intro": false, "planet": planet, "touch": 1, "planetGen": 3})
	for f in S.fighters:
		f.y = 3000.0
	return S


## The index against a walk of them all: every building in the band in the bucket of its pose, once, in order, and none else.
func _indexBad(S: SimState) -> int:
	var bad: int = 0
	var seen: Dictionary = {}
	var bw: float = SimConst.W / 128.0
	for k in range(S.bIdx.size()):
		var last: int = -1
		for i in S.bIdx[k]:
			if i <= last or seen.has(i):
				bad += 1
			last = i
			seen[i] = true
			if not WorldStructures.inBand(S, S.bZ[i], S.buildings[i].d) or mini(int(SimWrap.wrap(S.bX[i]) / bw), WorldStructures.BUCKETS - 1) != k:
				bad += 1
	for i in range(S.buildings.size()):
		if WorldStructures.inBand(S, S.bZ[i], S.buildings[i].d) and not seen.has(i):
			bad += 1
	return bad


func _swing(S: SimState, deg: float) -> int:
	SimSwing.ask(S, {"deg": deg, "cause": "launch"})
	var n: int = 0
	while S.swing.active and n < 800:
		SimSwing.tick(S)
		S.tick += 1
		n += 1
	return n


func _index() -> void:
	var S := _start(true)
	var n: int = S.buildings.size()
	ok(S.bFirst > 0 and n > S.bFirst * 5, "on: the first ring's %d of %d" % [S.bFirst, n])
	ok(_indexBad(S) == 0, "the index holds the band at the start (%d off)" % _indexBad(S))
	var biggest: int = 0
	for b in S.bIdx:
		biggest = maxi(biggest, b.size())
	print("index: %d buildings, biggest bucket %d" % [n, biggest])
	_swing(S, 35.0)
	ok(S.swing.poseK == 0, "a rest starts the far poses")
	var t: int = 0
	var worst: int = 0
	while S.swing.poseK >= 0 and t < 200:
		var a: int = Time.get_ticks_usec()
		SimSwing.tick(S)
		worst = maxi(worst, Time.get_ticks_usec() - a)
		S.tick += 1
		t += 1
	print("far poses: %d ticks, worst %d us" % [t, worst])
	ok(t * int(SimSwing.data().posesRestPerTick) >= n, "they cover them all in %d ticks" % t)
	ok(_indexBad(S) == 0, "the index holds the band after a swing and its far poses (%d off)" % _indexBad(S))
	var off: int = 0
	for i in range(n):
		SimField.strip(S, S.bDir[i * 3], S.bDir[i * 3 + 1], S.bDir[i * 3 + 2])
		if absf(S.bX[i] - SimField.sx) > 1e-6 or absf(S.bZ[i] - SimField.sz) > 1e-6:
			off += 1
	ok(off == 0, "every pose is right once they're done (%d stale)" % off)
	# a swing that cuts the far poses short, then a rollback across another
	SimSwing.ask(S, {"deg": -20.0, "cause": "launch"})
	var snap: NetSnapshot = NetSnapshot.take(S)
	var h0: String = SimHash.stateHash(S).gameplay
	_swing(S, -20.0)
	for k in range(5):
		SimSwing.tick(S)
		S.tick += 1
	var kMid: int = S.swing.poseK
	ok(kMid > 0, "the far poses are part way (%d)" % kMid)
	NetSnapshot.restore(S, snap)
	ok(SimHash.stateHash(S).gameplay == h0, "a restore gives the hash back")
	ok(_indexBad(S) == 0, "a restore gives the index back (%d off)" % _indexBad(S))
	_swing(S, -20.0)
	for k in range(5):
		SimSwing.tick(S)
		S.tick += 1
	ok(S.swing.poseK == kMid, "the re-run reaches the same place")
	SimCore.dispose(S)


func _queries() -> void:
	var S := _start(true)
	var f = S.fighters[0]
	var missed: int = 0
	var ahead: int = 0   # World's front limit (docs/world/front-limit.md): in front of it a building isn't struck, on purpose
	var ring: int = 0
	var who: Dictionary = {}
	for q in range(40):
		var x: float = SimWrap.wrap(f.x + float(q) * 1900.0)
		var got: Dictionary = {}
		for i in WorldStructures.near(S, x, 500.0):
			got[i] = true
		for i in range(S.buildings.size()):
			if absf(S.bZ[i]) <= 2500.0 and absf(SimWrap.sdx(x, S.bX[i])) <= 500.0 and not got.has(i):
				if WorldStructures.inBand(S, S.bZ[i], S.buildings[i].d):
					missed += 1
				else:
					ahead += 1
					who[i] = true
					if i < S.bFirst:
						ring += 1
	var past: int = 0
	for i in who:
		if S.bZ[i] + 0.5 * S.buildings[i].d <= WorldPlan.indexFront():
			past += 1
	print("near: %d left out, %d buildings, all in front of the limit: %s; first ring's %d" % [ahead, who.size(), str(past == 0), ring])
	ok(missed == 0, "near() finds every building a fight in the band could touch (%d missed)" % missed)
	ok(ahead > 0 and past == 0, "what it leaves out is in front of the front limit (%d left out, %d behind it)" % [ahead, past])
	ok(ring == 0, "and none of those is the first ring's (%d)" % ring)
	SimCore.dispose(S)


func _hash() -> void:
	var S := _start(true)
	var a: String = SimHash.stateHash(S).gameplay
	ok(a == SimHash.stateHash(S).gameplay, "the hash holds still")
	var i: int = S.buildings.size() - 3
	ok(SimHash.pristine(S, i), "a free building starts pristine")
	var hp: float = S.bHp[i]
	S.bHp[i] = hp - 1.0
	ok(not SimHash.pristine(S, i), "damaged, it isn't")
	var b: String = SimHash.stateHash(S).gameplay
	ok(a != b, "a free building's damage is in the hash")
	var d0: String = NetDesync.digest(S)
	S.bHp[i] = hp - 2.0
	ok(NetDesync.digest(S) != d0, "... and in the digest")
	ok(SimHash.stateHash(S).gameplay != b, "... by how much")
	S.bHp[i] = hp
	ok(SimHash.stateHash(S).gameplay == a, "healed, the hash is back")
	S.bAlive[i] = 0
	ok(SimHash.stateHash(S).gameplay != a, "a free building's fall is in the hash")
	S.bAlive[i] = 1
	ok(SimHash.stateHash(S).gameplay == a, "standing again, the hash is back")
	var pop: float = S.bPopAlive[i]
	S.bPopAlive[i] = pop + 3.0
	ok(SimHash.pristine(S, i), "people waking don't end the skip")
	ok(SimHash.stateHash(S).gameplay != a, "... and they're in the hash")
	S.bPopAlive[i] = pop
	var j: int = S.bFirst - 1
	var hj: float = S.bHp[j]
	S.bHp[j] = hj - 1.0
	ok(SimHash.stateHash(S).gameplay != a, "a first-ring building's is too")
	S.bHp[j] = hj
	var t0: int = Time.get_ticks_usec()
	SimHash.stateHash(S)
	print("hash: %d us with %d buildings" % [Time.get_ticks_usec() - t0, S.buildings.size()])
	SimCore.dispose(S)


func _caps() -> void:
	var S := _start(true)
	ok(WorldStructures.ringCount(S) == S.bFirst, "on: a share counts the first ring")
	SimCore.dispose(S)
	var O := _start(false)
	ok(O.bFirst == 0, "off: no free buildings")
	ok(WorldStructures.ringCount(O) == O.buildings.size(), "off: a share counts them all")
	ok(_indexBad(O) == 0, "off: the index holds them all")
	_swing(O, 30.0)
	ok(O.swing.poseK == -1, "off: a rest poses them all at once")
	ok(_indexBad(O) == 0, "off: and the index is right after it")
	SimCore.dispose(O)


## Two runs of an AI fight with swings, one hash; a run across a rollback, the same each tick.
func _fight() -> String:
	var S := SimCore.createSim()
	WorldClimate.useGen(3)
	WorldPlan.everywhereOverride = 1
	WorldPlanet.forget()
	SimCore.newMatch(S, 77, {"p1": true, "p2": true}, {"intro": false, "planet": 7, "touch": 2, "planetGen": 3})
	var hs: Array = []
	var snap: NetSnapshot = null
	for t in range(1500):
		if t == 900:
			snap = NetSnapshot.take(S)
		var a = S.fighters[0]
		if (a.state == "launched" or S.fighters[1].state == "launched") and not S.swing.active and S.beams.is_empty():
			SimSwing.ask(S, {"deg": 35.0 if t % 2 == 0 else -35.0, "cause": "launch"})
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		if t >= 900 and t % 30 == 0:
			hs.append(SimHash.stateHash(S).gameplay)
	var end: String = SimHash.stateHash(S).gameplay
	SimCore.dispose(S)
	return end


func _init() -> void:
	_index()
	_queries()
	_hash()
	_caps()
	ok(_fight() == _fight(), "two AI fights with swings give one hash")
	WorldPlan.everywhereOverride = -1
	print("PLACES: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
