extends SceneTree
# What a rollback that runs a calm turn's swap again costs (World W8). A turn is decided at tick 30 (two_states_check's "turn" setup: a Half ring, planet 7, touch 3), the tick before the swap is saved, and the swap tick
# is timed straight and then twice more after a restore, each with its state hash. The swap's ring job and preparation are kept KEEP_TICKS ticks, so the re-run finds them; before that change the swap dropped them and the
# re-run read the ring again on the rollback frame. For a reference it also times an ordinary tick (40) after a restore, which pays the structures' rebinding whatever World does.
#   godot --headless --path . --script res://sim/world/tools/rerun_cost.gd -- [--seed=1]
func _init() -> void:
	var seed: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed = int(a.substr(7))
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}})
	var pool := NetSnapshot.Pool.new()
	var snap: NetSnapshot = null
	var snap40: NetSnapshot = null
	var swapAt: int = -1
	var straightUs: int = 0
	var straightHash: String = ""
	var ordinary: Array = []
	for t in range(400):
		if t == 30:
			S.epoch.lastT = S.T - float(WorldEpoch.data().gapSeconds)
			WorldEpoch.ask(S, "rerun cost", 0.5 * (S.fighters[0].x + S.fighters[1].x), 1, 0)
			WorldEpoch.choose(S, 2, 64, 2.5)
		if t == 40:
			snap40 = NetSnapshot.take(S, pool)
		if int(S.epoch.n) == 0:
			if snap != null:
				pool.put(snap)
			snap = NetSnapshot.take(S, pool)
		var t0: int = Time.get_ticks_usec()
		SimCore.step(S)
		var dt: int = Time.get_ticks_usec() - t0
		if int(S.epoch.n) == 1:
			swapAt = t
			straightUs = dt
			straightHash = str(SimHash.stateHash(S).gameplay)
			break
		ordinary.append(dt)
	ordinary.sort()
	print("swap at tick %d; an ordinary tick: median %d us" % [swapAt, ordinary[ordinary.size() / 2]])
	print("straight swap tick: %d us   state %s" % [straightUs, straightHash.substr(0, 12)])
	for k in range(2):
		NetSnapshot.restore(S, snap, pool)
		var held: String = "%d ring job(s) and %d preparation(s) held" % [WorldEpoch._jobs.size(), WorldEpoch._plans.size()]
		var cold0: int = WorldEpoch.coldCount
		var unprep0: int = WorldEpoch.unprepCount
		var t1: int = Time.get_ticks_usec()
		SimCore.step(S)
		var du: int = Time.get_ticks_usec() - t1
		var h: String = str(SimHash.stateHash(S).gameplay)
		print("re-run %d: %d us   state %s %s   (%s; cold +%d, unprep +%d)" % [k + 1, du, h.substr(0, 12), "= the straight run's" if h == straightHash else "DIFFERS", held, WorldEpoch.coldCount - cold0, WorldEpoch.unprepCount - unprep0])
	NetSnapshot.restore(S, snap40, pool)
	var t2: int = Time.get_ticks_usec()
	SimCore.step(S)
	print("reference: an ordinary tick (40) after a restore: %d us" % (Time.get_ticks_usec() - t2))
	pool.clear()
	SimCore.dispose(S)
	quit()
