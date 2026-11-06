extends SceneTree
## SimField's kept ground (World's request, docs/world/pending/field-static-memo/request.md): godot --headless --path . --script res://sim/core/tools/field_static_check.gd
## - every read of a column through the memos, fine and far, is the ground read whole, bit for bit, through a match of
##   computer fighters with craters dug every 1.5 s and two swings, on two planets
## - the same matches with the kept ground and without it: the same hash on every tick
## - re-reads after a dig find the kept ground; rough: what a re-read costs, kept against whole
## --negative-control reads a kept ground without the store's delta, and the comparison must see it.

var fails: int = 0
const WORLDS: Array = [{"intro": false, "planet": 7, "touch": 3, "planetGen": 3}, {"intro": false, "planet": 12, "touch": 3, "planetGen": 3}]
const TICKS: int = 1500


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func _new(world: Dictionary) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": true, "p2": true}, world)
	return S


func _whole(S: SimState, i: int, far: bool) -> float:
	SimField.pointAt(S, float(i) * SimConst.COL)
	return SimField._ground(S, SimField._stride if far else 1)


## A crater of 260 units at strip x.
func _dig(S: SimState, x: float) -> void:
	SimField.pointAt(S, x)
	WorldStore.add(S, SimField.ox, SimField.oy, SimField.oz, 260.0, 90.0, 20.0, 1.0, 0, 0, S.T, 0)


## Columns around the pair through the memos, and far ones on the stride, each against the ground read whole. [reads, differ]
func _compare(S: SimState) -> Array:
	var n: int = 0
	var bad: int = 0
	var c0: int = int(floor(S.fighters[0].x / SimConst.COL))
	for d in range(-150, 151, 3):
		var i: int = posmod(c0 + d, SimConst.NC)
		var a: float = SimField.col(S, i)
		n += 1
		if a != _whole(S, i, false):
			bad += 1
	var st: int = SimField._st
	SimField.far()
	var k: int = posmod(c0 - c0 % st, SimConst.NC)
	for j in range(40):
		var c: int = posmod(k + (j - 20) * st * 3, SimConst.NC)
		c -= c % st
		var a: float = SimField.col(S, c)
		n += 1
		if a != _whole(S, c, true):
			bad += 1
	SimField.near()
	return [n, bad]


func _match(world: Dictionary, splitOff: bool, compare: bool) -> Dictionary:
	SimField.splitOff = splitOff
	SimField.kept = 0
	var S := _new(world)
	var hs: Array = []
	var n: int = 0
	var bad: int = 0
	var swung: int = 0
	for t in range(TICKS):
		if t % 90 == 45:
			_dig(S, S.fighters[(t / 90) % 2].x + 250.0 * float(1 - 2 * ((t / 180) % 2)))
		if t == 400 or t == 900:
			if SimSwing.ask(S, {"deg": 20.0 if t == 400 else -25.0, "cause": "launch"}):
				swung += 1
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		hs.append(str(SimHash.stateHash(S).gameplay))
		if compare and t % 10 == 0:
			var r: Array = _compare(S)
			n += r[0]
			bad += r[1]
	var out: Dictionary = {"hs": hs, "n": n, "bad": bad, "kept": SimField.kept, "swung": swung, "store": S.storeN}
	SimCore.dispose(S)
	SimField.splitOff = false
	return out


## Rough, a loaded PC: columns read, then dug, then read again kept, and the same columns read whole, in turn.
func _time(world: Dictionary) -> Array:
	var S := _new(world)
	for t in range(60):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
	var kept: int = 0
	var whole: int = 0
	var cols: int = 0
	for r in range(8):
		var x: float = S.fighters[0].x + 700.0 * float(r + 1)
		var c: int = int(floor(x / SimConst.COL))
		for d in range(-25, 26):
			SimField.col(S, posmod(c + d, SimConst.NC))
		_dig(S, x)
		var t0: int = Time.get_ticks_usec()
		for d in range(-25, 26):
			SimField.col(S, posmod(c + d, SimConst.NC))
		var t1: int = Time.get_ticks_usec()
		for d in range(-25, 26):
			_whole(S, posmod(c + d, SimConst.NC), false)
		var t2: int = Time.get_ticks_usec()
		kept += t1 - t0
		whole += t2 - t1
		cols += 51
	SimCore.dispose(S)
	return [float(kept) / float(cols), float(whole) / float(cols)]


func _init() -> void:
	WorldClimate.useGen(3)
	if OS.get_cmdline_user_args().has("--negative-control"):
		SimField.blindStore = true
		var r: Dictionary = _match(WORLDS[0], false, true)
		SimField.blindStore = false
		print("negative: a kept ground read without the store's delta: %d of %d reads differ" % [r.bad, r.n])
		ok(r.bad > 0, "the comparison sees the store's delta left out")
		print("FIELDSTATIC negative control: %d check(s) failed" % fails)
		quit(1 if fails > 0 else 0)
		return
	for w in WORLDS:
		var a: Dictionary = _match(w, false, true)
		var b: Dictionary = _match(w, true, false)
		var first: int = -1
		for t in range(TICKS):
			if a.hs[t] != b.hs[t]:
				first = t
				break
		print("planet %d: %d reads through the memos, %d differ from the ground read whole; %d found a kept ground; %d store records, %d swings" % [w.planet, a.n, a.bad, a.kept, a.store, a.swung])
		ok(a.bad == 0, "planet %d: every memo read is the ground read whole (%d differ)" % [w.planet, a.bad])
		ok(a.kept > 0, "planet %d: re-reads found the kept ground (%d)" % [w.planet, a.kept])
		ok(a.swung > 0, "planet %d: the line swung (%d)" % [w.planet, a.swung])
		ok(first < 0, "planet %d: the same hash on every tick, kept or not (first differs at %d)" % [w.planet, first])
		var tm: Array = _time(w)
		print("  rough, a re-read of a column a dig forgot: kept %.1f us, whole %.1f us" % [tm[0], tm[1]])
	print("FIELDSTATIC: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
