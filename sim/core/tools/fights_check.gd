extends SceneTree
## Two fights on one line (sim/core/stage.gd): godot --headless --path . --script res://sim/core/tools/fights_check.gd
## Run twice, its digest line says two processes agree.
## - fight 0 of a four-fighter match against a plain 1v1 of the seed, tick by tick, while the fights are apart
## - each fight's holds stop only its own clock, and fight 1 really fights
## - two runs one hash, and a rollback across holds the same on every tick, by hash and by digest
## - a trade of bodies between fights keeps what each had left on his times
## - the apart rule: no swing while apart, a swing when together, and one under way rests when they part
## - the second fight doesn't hang on the first
## --negative-control plants one draw from the wrong stream, and each comparison has to see it.

var fails: int = 0
const FIELD: Dictionary = {"intro": false, "planet": 7, "touch": 1, "planetGen": 3}
const WORLDS: Array = [{"intro": false}, FIELD, {"intro": false, "planet": 12, "touch": 1, "planetGen": 3}]
const SEEDS: Array = [77, 5, 101]
var ticks: int = 1800       # --long: 3600
var negative: bool = false  # --negative-control: the check catches a fight that hangs on the other
const APART: float = 8000.0   # fights closer than this aren't apart in the comparison: a blow's blast has this much room


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func _new(seed: int, world: Dictionary, fights: bool, ai: bool = true) -> SimState:
	var su: Dictionary = world.duplicate()
	if fights:
		su["fights"] = 2
	var S := SimCore.createSim()
	var who: Dictionary = {"p1": ai, "p2": ai}
	if fights:
		who["p3"] = ai
		who["p4"] = ai
	SimCore.newMatch(S, seed, who, su)
	return S


func _row(S: SimState) -> Array:
	var a = S.fighters[0]
	var b = S.fighters[1]
	return [S.T, S.dirS.stop, S.rng.a, a.x, a.y, a.z, a.hp, a.ki, a.state, b.x, b.y, b.z, b.hp, b.ki, b.state]


func _drain(S: SimState) -> void:
	S.out.fx.clear()
	S.out.feed.clear()


## Fight 0 inside the match against a plain 1v1. Past the first tick the fights come close nothing is promised.
func _same(seed: int, world: Dictionary) -> void:
	var R := _new(seed, world, false)
	var rows: Array = []
	for t in range(ticks):
		SimCore.step(R)
		_drain(R)
		rows.append(_row(R))
	SimCore.dispose(R)
	var S := _new(seed, world, true)
	var first: int = -1
	var close: int = -1
	var held: Array = [0, 0]
	var blows: Array = [0, 0]
	var stopped: Array = [0, 0]   # ticks one fight was held while the other's clock ran
	for t in range(ticks):
		var r1 = S.stage.fights[1]
		var t0: float = S.T
		var t1: float = r1.T
		SimCore.step(S)
		for e in S.out.fx:
			if e.type == "damage":
				blows[0] += 1
		for e in r1.out.fx:
			if e.type == "damage":
				blows[1] += 1
		_drain(S)
		if S.T == t0:
			held[0] += 1
			if r1.T != t1:
				stopped[0] += 1
		if r1.T == t1:
			held[1] += 1
			if S.T != t0:
				stopped[1] += 1
		if close < 0 and SimStage.gap(S) < APART:
			close = t
		if first < 0 and _row(S) != rows[t]:
			first = t
			if close < 0:
				print("  first difference at tick %d:\n    %s\n    %s" % [t, str(_row(S)), str(rows[t])])
	var r = S.stage.fights[1]
	print("same: seed %d %s: first difference %d, fights first close %d; held %d and %d, each alone %d and %d; blows %d and %d; clocks %.2f and %.2f" % [seed, world.get("planet", "flat"), first, close, held[0], held[1], stopped[0], stopped[1], blows[0], blows[1], S.T, r.T])
	ok(first < 0 or (close >= 0 and first >= close), "seed %d %s: fight 0 is the 1v1 while apart (differs at %d, close at %d)" % [seed, world.get("planet", "flat"), first, close])
	ok(blows[1] > 0, "seed %d %s: fight 1 fights (%d blows)" % [seed, world.get("planet", "flat"), blows[1]])
	ok(stopped[0] > 0 and stopped[1] > 0, "seed %d %s: a hold stops only its own fight (%d, %d)" % [seed, world.get("planet", "flat"), stopped[0], stopped[1]])
	SimCore.dispose(S)


func _hash(world: Dictionary) -> String:
	var A := _new(77, world, true)
	for t in range(1500):
		SimCore.step(A)
		_drain(A)
	var h: String = "%s %s" % [str(SimHash.stateHash(A).gameplay), NetDesync.digest(A)]
	SimCore.dispose(A)
	return h


## Two runs one hash, then a rollback across holds in both fights: every tick of the re-run the same, by hash and digest.
func _rollback(world: Dictionary) -> String:
	var h: String = _hash(world)
	ok(h == _hash(world), "two runs give one hash (%s)" % world.get("planet", "flat"))
	var S := _new(77, world, true)
	var snap: NetSnapshot = null
	var hs: Array = []
	var held: Array = [0, 0]
	for t in range(1400):
		if t == 700:
			snap = NetSnapshot.take(S)
		var r = S.stage.fights[1]
		var t0: float = S.T
		var t1: float = r.T
		SimCore.step(S)
		_drain(S)
		if t >= 700:
			hs.append("%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)])
			held[0] += 1 if S.T == t0 else 0
			held[1] += 1 if r.T == t1 else 0
	NetSnapshot.restore(S, snap)
	ok(S.stage.cur == 0 and S.stage.fights.size() == 2 and S.fighters.size() == 2, "a restore brings the fights back")
	var bad: int = 0
	for t in range(700, 1400):
		SimCore.step(S)
		_drain(S)
		if "%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)] != hs[t - 700]:
			bad += 1
	print("rollback %s: %d ticks, held %d and %d, %d differ" % [world.get("planet", "flat"), hs.size(), held[0], held[1], bad])
	ok(bad == 0 and held[0] > 0 and held[1] > 0, "a rollback across holds is the same on every tick (%d differ, held %d and %d)" % [bad, held[0], held[1]])
	SimCore.dispose(S)
	return h


## The hash has to see the second fight, or a check above says nothing.
func _seen() -> void:
	var S := _new(77, WORLDS[0], true)
	for t in range(300):
		SimCore.step(S)
		_drain(S)
	var h0: String = str(SimHash.stateHash(S).gameplay)
	var d0: String = NetDesync.digest(S)
	var f = S.stage.fights[1].fighters[0]
	f.x += 0.5
	ok(str(SimHash.stateHash(S).gameplay) != h0, "the hash sees fight 1's fighters")
	ok(NetDesync.digest(S) != d0, "the digest sees fight 1's fighters")
	f.x -= 0.5
	S.stage.fights[1].T += 0.5
	ok(str(SimHash.stateHash(S).gameplay) != h0, "the hash sees fight 1's clock")
	ok(NetDesync.digest(S) != d0, "the digest sees fight 1's clock")
	S.stage.fights[1].T -= 0.5
	ok(str(SimHash.stateHash(S).gameplay) == h0 and NetDesync.digest(S) == d0, "and they read without writing")
	SimCore.dispose(S)


## Clocks a few seconds apart, a body with a rush under way and a cooldown running: trade him, and the same is left.
func _trade() -> void:
	var run := func(mode: int) -> Array:
		var S := _new(77, WORLDS[0], true, false)
		for k in range(10):
			SimCore.step(S)
		S.dirS.stop = 3.0   # fight 0 waits, fight 1 runs on
		for t in range(240):
			SimCore.step(S)
			_drain(S)
		var r = S.stage.fights[1]
		var drift: float = r.T - S.T
		var f = r.fighters[0]
		var g = S.fighters[0]
		var ru := SimState.Rush.new()
		ru.px = f.x + 3000.0
		ru.py = f.y
		ru.end = r.T + 1.0
		f.rush = ru
		f.sigReadyT = r.T + 2.0
		f.hurtT = r.T - 0.5
		var left: float = 0.0
		if mode == 1:
			ok(SimStage.trade(S, f, g), "a trade between quiet fights goes through")
			ok(SimStage.fightOf(S, f) == 0 and SimStage.fightOf(S, g) == 1 and S.fighters.size() == 2 and r.fighters.size() == 2, "each has the other's slot")
			left = f.sigReadyT - S.T
		var n: int = 0
		while f.rush != null and n < 2000:
			SimCore.step(S)
			_drain(S)
			n += 1
		var out: Array = [drift, n, f.sigReadyT - (S.T if SimStage.fightOf(S, f) == 0 else r.T), left]
		SimCore.dispose(S)
		return out
	var a: Array = run.call(0)
	var b: Array = run.call(1)
	print("trade: drift %.2f s; the rush's ticks left: stayed %d, traded %d; the cooldown left after %.3f, %.3f" % [a[0], a[1], b[1], a[2], b[2]])
	ok(absf(a[0]) > 1.0, "the clocks have drifted (%.2f s)" % a[0])
	ok(a[1] == b[1], "a rush ends on its tick, traded (%d against %d)" % [a[1], b[1]])
	ok(absf(b[3] - 2.0) < 1.0e-9, "his cooldown has what it had left (%.6f)" % b[3])
	# refused while an exchange is open: run an AI match until one is
	var S := _new(77, WORLDS[0], true)
	var n: int = 0
	while S.dirS.ex == null and n < 3000:
		SimCore.step(S)
		_drain(S)
		n += 1
	ok(S.dirS.ex != null, "an exchange opened")
	var f = S.stage.fights[1].fighters[0]
	var g = S.fighters[0]
	var x: bool = SimStage.trade(S, f, g)
	ok(not x and SimStage.fightOf(S, f) == 1, "a trade is refused in an exchange")
	SimCore.dispose(S)


func _gather(S: SimState, at: float) -> void:
	var i: int = 0
	for f in SimStage.bodies(S):
		f.x = SimWrap.wrap(at + 300.0 * float(i))
		f.y = 3000.0
		i += 1


## The apart rule.
func _apart() -> void:
	var S := _new(77, FIELD, true, false)
	for t in range(30):
		SimCore.step(S)
		_drain(S)
	ok(not SimStage.together(S), "half a ring apart isn't together")
	ok(not SimSwing.ask(S, {"deg": 30.0, "cause": "launch"}), "no swing while apart")
	ok(not S.swing.active, "and nothing runs")
	_gather(S, S.fighters[0].x)
	ok(SimStage.together(S), "gathered is together")
	ok(SimSwing.ask(S, {"deg": 30.0, "cause": "launch"}), "a swing when together")
	for t in range(20):
		SimCore.step(S)
		_drain(S)
	ok(S.swing.active and S.swing.rate > 0.0, "it turns (rate %.2f)" % S.swing.rate)
	var far = S.stage.fights[1].fighters[1]
	far.x = SimWrap.wrap(far.x + 30000.0)
	var n: int = 0
	while S.swing.active and n < 200:
		SimCore.step(S)
		_drain(S)
		n += 1
	ok(not S.swing.active, "one under way rests when they part (%d ticks)" % n)
	print("apart: a swing under way rested %d ticks after a fighter left" % n)
	SimCore.dispose(S)


## With the director's swing switch on, every other reason to swing is there: fight 0 still matches a plain 1v1 without it.
func _switchOn() -> void:
	var R := _new(77, FIELD, false)
	var rows: Array = []
	for t in range(ticks):
		SimCore.step(R)
		_drain(R)
		rows.append(_row(R))
	SimCore.dispose(R)
	var was = DirSwing._force
	DirSwing._force = 1
	var S := _new(77, FIELD, true)
	var first: int = -1
	var close: int = -1
	var swung: int = 0
	for t in range(ticks):
		SimCore.step(S)
		if S.swing.active:
			swung += 1
		_drain(S)
		if close < 0 and SimStage.gap(S) < APART:
			close = t
		if first < 0 and _row(S) != rows[t]:
			first = t
	DirSwing._force = was
	print("switch on: first difference %d, close %d, %d ticks of swing" % [first, close, swung])
	ok(first < 0 or (close >= 0 and first >= close), "swings rest while apart: fight 0 is the 1v1 (differs at %d, close at %d)" % [first, close])
	SimCore.dispose(S)


## The second fight doesn't hang on the first: with the first fighting or standing idle, the second's every number is the
## same. A static a tick's reads leave behind (a memo keyed by the match and the tick) shows here. The line's numbers at
## rest are put back on the first fight's pair as it travels, which moves a far ground read in its last digits, so the
## anchor is off for this: it's the one thing the fights share by design that a read can tell.
func _independent(seed: int, world: Dictionary) -> void:
	SimSwing.anchorBlind = true
	var run := func(idle: bool) -> Array:
		var su: Dictionary = world.duplicate()
		su["fights"] = 2
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed, {"p1": not idle, "p2": not idle, "p3": true, "p4": true}, su)
		var rows: Array = []
		for t in range(ticks):
			SimCore.step(S)
			_drain(S)
			var r = S.stage.fights[1]
			var a = r.fighters[0]
			var b = r.fighters[1]
			rows.append([r.T, r.dirS.stop, r.rng.a, a.x, a.y, a.z, a.hp, a.ki, a.state, b.x, b.y, b.z, b.hp, b.ki, b.state])
		SimCore.dispose(S)
		return rows
	var x: Array = run.call(false)
	var y: Array = run.call(true)
	SimSwing.anchorBlind = false
	var first: int = -1
	for t in range(x.size()):
		if x[t] != y[t]:
			first = t
			print("  fight 1 first differs at tick %d:\n    %s\n    %s" % [t, str(x[t]), str(y[t])])
			break
	print("alone: seed %d %s: fight 1 with fight 0 fighting or idle: first difference %d" % [seed, world.get("planet", "flat"), first])
	ok(first < 0, "seed %d %s: fight 1 doesn't hang on fight 0 (differs at %d)" % [seed, world.get("planet", "flat"), first])


## A rollback across a swing: the line is everyone's, and it's the same the second time.
func _swingRollback() -> void:
	var S := _new(77, FIELD, true, false)
	for t in range(30):
		SimCore.step(S)
		_drain(S)
	_gather(S, S.fighters[0].x)
	ok(SimSwing.ask(S, {"deg": 30.0, "cause": "launch"}), "a swing for the rollback")
	for t in range(10):
		SimCore.step(S)
		_drain(S)
	var snap: NetSnapshot = NetSnapshot.take(S)
	var hs: Array = []
	var ran: int = 0
	for t in range(60):
		SimCore.step(S)
		_drain(S)
		ran += 1 if S.swing.active else 0
		hs.append("%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)])
	NetSnapshot.restore(S, snap)
	var bad: int = 0
	for t in range(60):
		SimCore.step(S)
		_drain(S)
		if "%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)] != hs[t]:
			bad += 1
	print("swing rollback: %d ticks of swing in 60, %d differ" % [ran, bad])
	ok(ran > 10 and bad == 0, "a rollback across a swing (%d of swing, %d differ)" % [ran, bad])
	SimCore.dispose(S)


## The line's numbers at rest are on fight 0, so the far end of the strip's wrap is under fight 1: a read across it doesn't jump.
func _seam() -> void:
	var S := _new(77, FIELD, true, false)
	for t in range(30):
		SimCore.step(S)
		_drain(S)
	var x: float = SimWrap.wrap(S.frame.x0 + SimConst.W * 0.5)
	SimField.pointIn(S.frame, SimWrap.wrap(x - 0.001))
	var ax: float = SimField.ox
	var ay: float = SimField.oy
	var az: float = SimField.oz
	SimField.pointIn(S.frame, SimWrap.wrap(x + 0.001))
	var worst: float = absf(ax - SimField.ox) + absf(ay - SimField.oy) + absf(az - SimField.oz)
	var worstG: float = absf(SimField.groundIn(S, S.frame, SimWrap.wrap(x - 0.001), false) - SimField.groundIn(S, S.frame, SimWrap.wrap(x + 0.001), false))
	print("wrap: across it a point moves %.9f, the ground %.4f" % [worst, worstG])
	ok(worst < 1.0e-6 and worstG < 1.0, "a read across the strip's wrap doesn't jump (%.9f, %.4f)" % [worst, worstG])
	var f = S.stage.fights[1].fighters[0]
	f.x = SimWrap.wrap(x - 40.0)
	f.y = SimFighter.floorFor(S, f, f.x, f.z)
	var i := SimIntent.new()
	i.mx = 1.0
	var big: float = 0.0
	var crossed: bool = false
	for t in range(120):
		var was: float = f.y
		var gone: float = SimWrap.sdx(x, f.x)
		SimCore.step(S, [null, null, i, null])
		_drain(S)
		if gone < 0.0 and SimWrap.sdx(x, f.x) >= 0.0:
			crossed = true
		big = maxf(big, absf(f.y - was))
	print("wrap: a fighter walked across it: %s; his most height in a tick %.2f" % [str(crossed), big])
	ok(crossed, "a fighter walks across the wrap")
	SimCore.dispose(S)


## The break: a draw from fight 0's stream while fight 1 is in S, once. _row's comparison and the rollback's must see it.
func _negative() -> void:
	var R := _new(77, WORLDS[0], false)
	var rows: Array = []
	for t in range(400):
		SimCore.step(R)
		_drain(R)
		rows.append(_row(R))
	SimCore.dispose(R)
	var S := _new(77, WORLDS[0], true)
	var first: int = -1
	for t in range(400):
		if t == 100:
			S.rng.next()
		SimCore.step(S)
		_drain(S)
		if first < 0 and _row(S) != rows[t]:
			first = t
	SimCore.dispose(S)
	print("negative: the planted draw shows at tick %d" % first)
	ok(first >= 100, "the comparison sees a planted draw (%d)" % first)
	var A := _new(77, WORLDS[0], true)
	for t in range(100):
		SimCore.step(A)
		_drain(A)
	var snap: NetSnapshot = NetSnapshot.take(A)
	SimCore.step(A)
	_drain(A)
	var h: String = "%s %s" % [str(SimHash.stateHash(A).gameplay), NetDesync.digest(A)]
	NetSnapshot.restore(A, snap)
	A.stage.fights[1].rng.next()
	SimCore.step(A)
	_drain(A)
	ok(h != "%s %s" % [str(SimHash.stateHash(A).gameplay), NetDesync.digest(A)], "the hash and digest see a planted draw in fight 1 after a restore")
	SimCore.dispose(A)
	print("FIGHTS negative control: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--long":
			ticks = 3600
		elif a == "--negative-control":
			negative = true
	if negative:
		_negative()
		return
	_trade()
	_apart()
	_swingRollback()
	_seam()
	_seen()
	for w in WORLDS:
		for sd in SEEDS:
			_same(sd, w)
	_switchOn()
	for w in WORLDS:
		_independent(77, w)
		_independent(5, w)
	var d0: String = _rollback(WORLDS[0])
	var d1: String = _rollback(FIELD)
	print("FIGHTS digest %s %s" % [d0, d1])
	print("FIGHTS: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
