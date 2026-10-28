extends SceneTree
## The rollback core's cost (docs/net/rollback.md section 5): the sim's tick, a snapshot's take and restore and its
## size, and what a peer's frame costs over the loopback (net/loopback.gd) by network profile, input delay and save
## spacing, against the 16.7 ms frame and with an estimate for a device four times slower (a phone).
##   godot --headless --path . --script res://net/tools/rollback_bench.gd -- [--ticks=1800] [--seed=1] [--quick] [--planet]
## --planet plays a planet match (planet 7, touch-down 3) instead of the hand-made world.
## Run it on a quiet machine: a number taken while other work saturates the cores is not a measurement.

const BUDGET_US: float = 1000000.0 / 60.0
const PHONE: float = 4.0
const CONFIGS: Array = [
	["lan", 2, 1], ["p80j", 2, 1], ["p80j", 2, 4], ["p120", 2, 1], ["p120", 2, 4], ["p120", 3, 1], ["p200", 2, 1], ["p200", 2, 2], ["p200", 2, 4],
	["p200", 4, 1], ["p200c", 2, 1], ["far", 2, 1], ["far", 2, 4],
]
const QUICK: Array = [["lan", 2, 1], ["p200", 2, 1], ["p200", 2, 4]]


func _init() -> void:
	var ticks: int = 1800
	var seed: int = 1
	var configs: Array = CONFIGS
	var setup: Dictionary = {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--seed="):
			seed = int(a.substr(7))
		elif a == "--quick":
			configs = QUICK
		elif a == "--planet":
			setup = {"planet": 7, "touch": 3}
	print("Orb Combat EX rollback bench   Godot %s   %s   %d cores   seed %d   %d ticks   setup %s" % [Engine.get_version_info().string, OS.get_processor_name(), OS.get_processor_count(), seed, ticks, str(setup)])
	_baseline(seed, ticks, setup)
	print("")
	print("peer frame cost (both peers' frames of play; frame = received packets, any rollback and re-simulation, one tick)")
	print("profile delay save | rollbacks/s  resim/frame mean  p99  max | frame ms mean  p99   max | x%d p99  max  over-budget | step  save  restore ms/frame" % int(PHONE))
	for c in configs:
		_session(seed, ticks, c[0], c[1], c[2], setup)
	quit(0)


func _clock() -> int:
	return Time.get_ticks_usec()


static func _pct(a: PackedInt32Array, q: float) -> float:
	if a.is_empty():
		return 0.0
	var b: PackedInt32Array = a.duplicate()
	b.sort()
	return float(b[mini(b.size() - 1, int(floor(q * float(b.size()))))])


static func _mean(a: PackedInt32Array) -> float:
	var s: float = 0.0
	for v in a:
		s += float(v)
	return s / maxf(1.0, float(a.size()))


## The sim alone, the snapshot's cost and its size over one match of the bots' inputs.
func _baseline(seed: int, ticks: int, setup: Dictionary) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, setup)
	var bots: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
	var step := PackedInt32Array()
	var take := PackedInt32Array()
	var rest := PackedInt32Array()
	var pool := NetSnapshot.Pool.new()
	var ring: Array = []
	var sizes: Array = []
	for t in range(ticks):
		if t == 0 or t == ticks / 2 or t == ticks - 1:
			sizes.append([t, NetSnapshot.measure(S)])
		var t0: int = _clock()
		var snap := NetSnapshot.take(S, pool)
		take.append(_clock() - t0)
		ring.append(snap)
		if ring.size() > 8:
			pool.put(ring.pop_front())
		if t % 10 == 9:
			t0 = _clock()
			NetSnapshot.restore(S, snap)   # the state it was taken from: the match goes on unchanged
			rest.append(_clock() - t0)
		var ins: Array = []
		for k in range(2):
			ins.append(SimIntent.unpack(NetSession.NEUTRAL if t < 2 else bots[k].next()))
		t0 = _clock()
		SimCore.step(S, ins)
		step.append(_clock() - t0)
		S.out.feed.clear()
		S.out.fx.clear()
	var th := PackedInt32Array()
	for i in range(5):
		var t0: int = _clock()
		SimHash.stateHash(S)
		th.append(_clock() - t0)
	for s in ring:
		pool.put(s)
	pool.clear()
	SimCore.dispose(S)
	print("sim tick (SimCore.step, bots' inputs)   mean %.3f ms  p50 %.3f  p99 %.3f  max %.3f" % [_mean(step) / 1000.0, _pct(step, 0.5) / 1000.0, _pct(step, 0.99) / 1000.0, _pct(step, 1.0) / 1000.0])
	print("snapshot take (pooled)                  mean %.3f ms  p99 %.3f  max %.3f" % [_mean(take) / 1000.0, _pct(take, 0.99) / 1000.0, _pct(take, 1.0) / 1000.0])
	print("snapshot restore                        mean %.3f ms  p99 %.3f  max %.3f" % [_mean(rest) / 1000.0, _pct(rest, 0.99) / 1000.0, _pct(rest, 1.0) / 1000.0])
	print("SimHash.stateHash (not in the loop)     mean %.3f ms" % (_mean(th) / 1000.0))
	for e in sizes:
		var m: Dictionary = e[1]
		print("snapshot size at tick %4d: %d bytes payload (%d in packed arrays), %d objects, %d arrays, %d dictionaries, %d scalars" % [e[0], m.bytes, m.packedBytes, m.objects, m.arrays, m.dicts, m.scalars])
	var mstep: float = _mean(step)
	print("ticks a 16.7 ms frame holds (sim alone): %.0f natively, %.0f at x%d" % [BUDGET_US / mstep, BUDGET_US / (mstep * PHONE), int(PHONE)])


func _session(seed: int, ticks: int, pname: String, delay: int, every: int, setup: Dictionary) -> void:
	var L := NetLoopback.make(seed, setup, NetLoopback.PROFILES[pname], delay, seed, seed * 31 + 7)
	L.clock = _clock
	for p in L.peers:
		p.session.saveEvery = every
		p.session.clock = _clock
	L.run(ticks)
	var fus := PackedInt32Array()
	var resim := PackedInt32Array()
	var rb: int = 0
	var st: float = 0.0
	var sv: float = 0.0
	var rs: float = 0.0
	for k in range(2):
		fus.append_array(L.frameUs[k])
		var s: NetSession = L.peers[k].session
		resim.append_array(s.resimFrames)
		rb += s.rollbacks
		st += float(s.usStep)
		sv += float(s.usSave)
		rs += float(s.usRestore)
	var n: float = maxf(1.0, float(fus.size()))
	var over: int = 0
	for v in fus:
		if float(v) * PHONE > BUDGET_US:
			over += 1
	print("%-7s %5d %4d | %11.1f  %16.2f %4d %4d | %13.2f %5.2f %5.2f | x%d %5.1f %5.1f %10.1f%% | %5.2f %5.2f %7.2f" % [
		pname, delay, every, float(rb) / 2.0 / (float(ticks) / 60.0), _mean(resim), int(_pct(resim, 0.99)), int(_pct(resim, 1.0)),
		_mean(fus) / 1000.0, _pct(fus, 0.99) / 1000.0, _pct(fus, 1.0) / 1000.0, int(PHONE), _pct(fus, 0.99) * PHONE / 1000.0, _pct(fus, 1.0) * PHONE / 1000.0,
		100.0 * float(over) / n, st / n / 1000.0, sv / n / 1000.0, rs / n / 1000.0])
	L.close()
