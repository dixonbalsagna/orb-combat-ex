extends SceneTree
## A rolled-back branch must leave nothing behind in a process-wide static (docs/architecture/fork-check.md): godot --headless --path . --script res://sim/core/tools/fork_check.gd
## rollback_check can't see this: its two sims share the process's statics. So this runs fresh processes on one real timeline, a rematch on a field world, and compares them:
##   real     the match's own timeline only
##   predict  the same, but first a 30-tick predicted branch sends a fighter into the ground, then a rollback to before it
## The line turns between that branch and the real timeline's first surface read. They must agree on the surface of every column and on the state after landings.
##   --negative-control  the predict process also moves a fighter by a unit: the compare must catch it.
##   --location          also compares DirLocation's table of biomes (Encounter's), which fills on first use too.

const PLANETS: Array = [7, 12, 3]
const LANDINGS: int = 8


func _init() -> void:
	var a: Dictionary = {}
	for s in OS.get_cmdline_user_args():
		var kv := s.trim_prefix("--").split("=", true, 1)
		a[kv[0]] = kv[1] if kv.size() > 1 else true
	if a.has("child"):
		quit(_child(int(a.child), String(a.mode), a.has("nudge"), a.has("location")))
		return
	var fails: int = 0
	var neg: bool = a.has("negative-control")
	for p in PLANETS:
		var r: Dictionary = _run(p, "real", false, a.has("location"))
		var q: Dictionary = _run(p, "predict", neg, a.has("location"))
		var same: bool = not r.is_empty() and not q.is_empty()
		for k in r:
			if q.has(k) and r[k] != q[k]:
				same = false
				fails += 1
				print(("-- planet %d: %s differs (%s, %s)" if neg else "FAIL  planet %d: %s differs (%s, %s)") % [p, k, r[k], q[k]])
		if r.is_empty() or q.is_empty():
			fails += 1
			print("FAIL  planet %d: a child process gave no result" % p)
		elif same:
			print("planet %d: the same, %s" % [p, str(r)])
	if neg:
		print("FORK: %d check(s) failed" % (0 if fails >= PLANETS.size() else 1))
		print("negative control: %d of %d planets caught" % [fails, PLANETS.size()])
		quit(0 if fails >= PLANETS.size() else 1)
		return
	print("FORK: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)


func _run(planet: int, mode: String, nudge: bool, location: bool) -> Dictionary:
	var args: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://sim/core/tools/fork_check.gd", "--", "--child=%d" % planet, "--mode=" + mode]
	if nudge:
		args.append("--nudge")
	if location:
		args.append("--location")
	var out: Array = []
	OS.execute(OS.get_executable_path(), args, out, true)
	var res: Dictionary = {}
	for l in String(out[0]).split("\n"):
		if l.begins_with("RESULT "):
			var p := l.strip_edges().split(" ")
			res[p[1]] = p[2]
		if l.contains("SCRIPT ERROR"):
			print("FAIL  " + l)
	return res


func _send(S: SimState, f, vx: float) -> void:
	f.state = "launched"
	f.launchT = 1.0
	f.stateT = 0.0
	f.vx = vx
	f.vy = -1500.0
	f.y = WorldTerrain.groundY(S, f.x, f.z) + 40.0


func _step(S: SimState, n: int) -> void:
	for t in range(n):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()


func _child(planet: int, mode: String, nudge: bool, location: bool) -> int:
	var first := SimCore.createSim()   # a rematch: another match came first in this process
	SimCore.newMatch(first, 5, {"p1": false, "p2": false}, {"planet": planet, "touch": 2, "planetGen": 3, "intro": false})
	_step(first, 5)
	SimCore.dispose(first)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": false, "p2": false}, {"planet": planet, "touch": 1, "planetGen": 3, "intro": false})
	for f in S.fighters:
		f.y = 3000.0
	var pivot: float = SimWrap.wrap(S.fighters[0].x + 9000.0)
	_step(S, 10)
	if mode == "predict":
		var snap: NetSnapshot = NetSnapshot.take(S)
		_send(S, S.fighters[0], 2000.0)
		if location:
			DirLocation.roam(S, S.fighters[0])
		_step(S, 30)
		NetSnapshot.restore(S, snap)
		if nudge:
			S.fighters[1].x += 1.0
	SimSwing.ask(S, {"deg": 40.0, "cause": "launch", "pivotX": pivot})
	var n: int = 0
	while S.swing.active and n < 600:
		_step(S, 1)
		n += 1
	var h := SimHash.Hasher.new()
	for i in range(SimConst.NC):
		h.text(WorldContact.surfaceAt(S, (float(i) + 0.5) * SimConst.COL))
	print("RESULT surface %s" % h.hex())
	if location:
		DirLocation.roam(S, S.fighters[0])
		var hl := SimHash.Hasher.new()
		for b in DirLocation._bucketBiome:
			hl.num(float(b))
		print("RESULT location %s" % hl.hex())
	var f = S.fighters[0]
	var step: int = SimConst.NC / LANDINGS
	for k in range(LANDINGS):
		f.x = (float(k * step) + 0.5) * SimConst.COL
		_send(S, f, 400.0)
		_step(S, 120)
		f.state = "free"
		f.rush = null
		f.y = 3000.0
		f.vx = 0.0
		f.vy = 0.0
	print("RESULT state %s" % str(SimHash.stateHash(S).gameplay))
	SimCore.dispose(S)
	return 0
