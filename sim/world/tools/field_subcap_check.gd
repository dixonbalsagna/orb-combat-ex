extends SceneTree
# The sub-node tables are a bounded cache (World, 2026-11-26; sim/world/field.gd, _turnSubs). From the repo root:
#   godot --headless --path . --script res://sim/world/tools/field_subcap_check.gd -- [--negative-control]
# QA's hour run found Field.sh and Field.sb growing without end (19 MiB each after one 600 s match): every sub-node ever read stayed. They are now held in two generations of at most SUB_GEN entries, the older
# dropped. Proves: with a very small generation the ground read at every point is bit for bit what it is with nothing ever dropped, read twice over (so dropped nodes read again are the same); the tables stay
# within two generations while the unbounded ones keep growing; the pool's own list and values are right whatever the tables forgot; and two matches, one turning constantly, one never, are the same state.
# --negative-control never turns: the size row must then fail.
var fails: int = 0
var negative: bool = false
const SMALL: int = 400           # a generation small enough that the walk below turns many times
const NEVER: int = 1 << 30
const CELLS: int = 500           # refined cells walked


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func _field() -> WorldField.Field:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	WorldField.forget()
	return WorldField.of(WorldPlanet.make(7))


## Refined cells of the planet's six faces, in a fixed order.
func _cells(F: WorldField.Field) -> Array:
	var out: Array = []
	for face in range(6):
		var n: int = 0
		for j in range(1, F.N - 2, 3):
			for i in range(1, F.N - 2, 3):
				if n < CELLS / 6 + 1 and WorldField.cellRefined(F, face, i, j):
					out.append([face, i, j])
					n += 1
	return out


## The ground at points inside each refined cell and in the plain cell beside it (which reads the shared edge: _edgeDelta), twice over in the same order.
func _walk(F: WorldField.Field, cells: Array) -> Array:
	var out: Array = []
	var peak: Array = [0, 0]
	for pass_ in range(2):
		for c in cells:
			var face: int = c[0]
			for p in [[0.13, 0.31], [0.62, 0.44], [0.91, 0.87], [1.5, 0.5], [0.5, -0.5]]:
				var d: Array = WorldField.dirOf(face, int((float(c[1]) + p[0]) * 16.0), int((float(c[2]) + p[1]) * 16.0), F.N * 16)
				WorldField.sample(F, d[0], d[1], d[2])
				out.append(F.oh)
				out.append(F.ob)
				out.append(F.ofine)
				peak[0] = maxi(peak[0], F.sh.size())
				peak[1] = maxi(peak[1], F.sh.size() + F.shOld.size())
	return [out, peak]


## The key's own value read fresh from the planet's function, as the tables and the pool hold it.
func _fresh(F: WorldField.Field, key: int) -> Array:
	var i4: int = key % F.S4
	var r: int = key / F.S4
	var j4: int = r % F.S4
	var face: int = r / F.S4
	if i4 % F.sub == 0 and j4 % F.sub == 0:
		return []
	WorldField._read(F, WorldField.dirOf(face, i4, j4, F.N * F.sub))
	return [PackedFloat32Array([WorldField._vh])[0], WorldField._vb | (WorldField._vf << 8)]


func _poolOk(F: WorldField.Field) -> bool:
	if F.extraSub.size() != F.extraSubH.size() or F.extraSub.size() != F.extraSubB.size():
		return false
	var seen: Dictionary = {}
	for k in range(F.extraSub.size()):
		var key: int = F.extraSub[k]
		if seen.has(key):
			return false
		seen[key] = true
		if k % 7 == 0:
			var f: Array = _fresh(F, key)
			if f.is_empty() or F.extraSubH[k] != f[0] or F.extraSubB[k] != f[1]:
				return false
	return true


func _matchHash(gen: int) -> Array:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	WorldField.forget()
	WorldField.subGenOverride = gen
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": true, "p2": true}, {"intro": false, "planet": 7, "touch": 3, "planetGen": 3})
	for t in range(900):
		SimCore.step(S)
	var F = WorldField.of(WorldPlanet.make(7))
	var out: Array = [str(SimHash.stateHash(S).gameplay), int(F.turns), int(F.subReads)]
	SimCore.dispose(S)
	return out


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	ok(WorldField.dataErrors().is_empty() and bool(WorldField.data().refine.enabled) and WorldField.SUB_GEN >= 10000, "the records are on, and a generation is %d entries as shipped" % WorldField.SUB_GEN)
	print("the ground, with nothing dropped and with a generation of %d" % SMALL)
	WorldField.subGenOverride = NEVER
	var A: WorldField.Field = _field()
	var cells: Array = _cells(A)
	var a: Array = _walk(A, cells)
	var grown: int = A.sh.size()
	ok(cells.size() > 100 and grown > 6 * SMALL and A.turns == 0, "control: unbounded, the walk of %d refined cells leaves %d entries in sh and never turns" % [cells.size(), grown])
	ok(_poolOk(A), "... and the pool's list holds each of its %d nodes once, with the planet's own values (so the pool file is what it was)" % A.extraSub.size())
	WorldField.subGenOverride = NEVER if negative else SMALL
	var B: WorldField.Field = _field()
	_cells(B)
	var b: Array = _walk(B, cells)
	var diff: int = 0
	for i in range(a[0].size()):
		if a[0][i] != b[0][i]:
			diff += 1
	ok(a[0].size() == b[0].size() and diff == 0, "every height, biome and fine biome is bit for bit the same, both passes (%d of %d values differ; %d turns, %d sub-node reads against %d)" % [diff, a[0].size(), B.turns, B.subReads, A.subReads])
	ok(b[1][0] <= SMALL + 24 and b[1][1] <= 2 * SMALL + 48 and B.turns >= 4, "the tables stay within two generations: at most %d in sh and %d in sh and the old one (unbounded: %d), %d turns" % [b[1][0], b[1][1], grown, B.turns])
	ok(_poolOk(B), "... and the pool's list is whole and right whatever the tables forgot (%d nodes, those of the first generation)" % B.extraSub.size())
	print("two matches")
	var m1: Array = _matchHash(NEVER)
	var m2: Array = _matchHash(50)
	ok(m1[0] == m2[0] and m1[1] == 0 and m2[1] > 0, "900 ticks with nothing dropped and with a generation of 50 end in the same state (%d turns; %d sub-node reads against %d)" % [m2[1], m2[2], m1[2]])
	WorldField.subGenOverride = 0
	print("SUBCAP: %d check(s) failed%s" % [fails, " (negative control)" if negative else ""])
	quit(0)
