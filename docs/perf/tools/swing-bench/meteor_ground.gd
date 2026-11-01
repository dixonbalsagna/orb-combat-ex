extends SceneTree
## Scratch bench (Performance, 2026-10-31): is the far ground ready for the meteor's landing, and what does a read there cost in a tick, in the sim and on the tile ground?
##   godot --headless --path . --script res://sim/core/tools/meteor_ground.gd -- --planet=7 --deg=60 [--side=1]
## One fresh process per (planet, angle): the nodes of a field world are built on first read and kept, so a cold read is only the first in a process.
## Distances: the meteor's curve lands D = 1.551 H from the send (meteor-arc.md: 36 degrees round = 15,355 u, 59.6 degrees = 25,436 u); D for another angle scales with it (ring of 153,550 u at 36 deg = a tenth).
## Prints (microseconds; "new nodes" = WorldField nodes built by the read, SimField._F.reads):
##   SIM   the landing's ground read on the far scope (the 512 bake) and on the near scope (fine nodes, computed on the spot), cold then warm; the descent check Research suggests (a read every 500 u over the last 12,500 u, 25 reads), both scopes.
##   TILES the tiles of levels 0, 1 and 2 under the landing (the camera's footprint +-4,500 u along the line), wanted and filled with a big budget: how many are missing, the microseconds and new nodes to fill them, and the frames that is at the game's slice (RenderLook.TILE_FILL_US 1,500, urgent x3 within 3,000 u of the camera).

var planet: int = 7
var deg: float = 60.0
var side: float = 1.0


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--deg="):
			deg = float(a.substr(6))
		elif a.begins_with("--side="):
			side = float(a.substr(7))
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": true, "p2": true}, {"planet": planet, "touch": 1, "planetGen": 3, "intro": false})
	if SimField._F != null:
		WorldField.bakeStep(SimField._F, 1 << 40)
	var F = SimField._F
	var x0: float = float(S.fighters[0].x)
	var D: float = 15355.0 * deg / 36.0
	var xl: float = SimWrap.wrap(x0 + side * D)
	print("CASE planet %d, %.0f degrees round, D = %.0f u, from x %.0f to x %.0f, side %+d" % [planet, deg, D, x0, xl, int(side)])
	# the tile field the way the host builds it: level 0 at the load, the near tiles of the fight
	var fd := RenderTileField.new()
	fd.begin(S)
	var tb: int = Time.get_ticks_usec()
	var nb: int = F.reads
	while not fd.boot(100000):
		pass
	while not fd.boot_near(100000):
		pass
	print("LOAD  tile level 0 and the fight's near tiles: %d us, %d new nodes" % [Time.get_ticks_usec() - tb, F.reads - nb])
	# the sim's reads
	for scope in ["far", "near"]:
		if scope == "far":
			SimField.far()
		else:
			SimField.near()
		for pass_ in ["cold", "warm"]:
			var r0: int = F.reads
			var t: int = Time.get_ticks_usec()
			var g: float = WorldTerrain.groundY(S, xl)
			var s1: bool = WorldTerrain.seaAt(S, xl)
			var t1: int = Time.get_ticks_usec() - t
			var n1: int = F.reads - r0
			r0 = F.reads
			t = Time.get_ticks_usec()
			var acc: float = 0.0
			for k in range(25):
				acc += WorldTerrain.groundY(S, SimWrap.wrap(xl - side * float(k) * 500.0))
			var t2: int = Time.get_ticks_usec() - t
			var n2: int = F.reads - r0
			print("SIM   %-4s %-4s | landing read (groundY + seaAt): %6d us, %3d new nodes | descent check, 25 reads / 500 u: %7d us, %4d new nodes | ground %.0f sea %s" % [scope, pass_, t1, n1, t2, n2, g, str(s1)])
	SimField.near()
	# the fight arrives: both fighters put on the landing (standing, 300 apart) and 90 ticks stepped, cold: the first ticks of the new place
	var land_r0: int = F.reads
	S.fighters[0].x = SimWrap.wrap(xl - 150.0)
	S.fighters[1].x = SimWrap.wrap(xl + 150.0)
	for f in S.fighters:
		f.y = WorldTerrain.groundY(S, f.x)
		f.vx = 0.0
		f.vy = 0.0
	var worst: int = 0
	var over: int = 0
	var first: String = ""
	var tot: int = 0
	for t in range(90):
		var n0: int = F.reads
		var a0: int = Time.get_ticks_usec()
		SimCore.step(S)
		var us: int = Time.get_ticks_usec() - a0
		S.out.fx.clear()
		S.out.feed.clear()
		worst = maxi(worst, us)
		if us > 16000:
			over += 1
		tot += us
		if t < 10:
			first += " [%d us, %d nodes]" % [us, F.reads - n0]
	print("LAND  fight put on the landing, 90 ticks: mean %d us, worst %d us, %d ticks over 16 ms, %d new nodes in all |%s" % [tot / 90, worst, over, F.reads - land_r0, first])
	# the tiles under the landing
	var fr = S.frame
	var want: Dictionary = {}
	for L in [0, 1, 2]:
		var keys := {}
		var xs: float = xl - 4500.0
		while xs <= xl + 4500.0:
			for dz in [-1600.0, 0.0, 1600.0]:
				var d: Vector3 = fd.dir_at(SimWrap.wrap(xs), dz, fr)
				keys[RenderTileField.key_at(d, L)] = true
			xs += 250.0
		want[L] = keys.keys()
	for L in [0, 1, 2]:
		var missing: Array = []
		for k in want[L]:
			if not fd.has(k):
				missing.append(k)
		var r0: int = F.reads
		var t: int = Time.get_ticks_usec()
		var rounds: int = 0
		for k in missing:
			fd.want(k, 5000.0)
		while rounds < 100000:
			fd.fill(100000000)
			rounds += 1
			var left: int = 0
			for k in missing:
				if not fd.has(k):
					left += 1
			if left == 0:
				break
			for k in missing:
				if not fd.has(k):
					fd.want(k, 5000.0)
		var us: int = Time.get_ticks_usec() - t
		var nn: int = F.reads - r0
		print("TILES level %d | %2d tiles under the landing, %2d missing | fill: %8d us, %5d new nodes | at the game's slice (1,500 us a frame): %5.1f frames; urgent (4,500): %5.1f frames" % [L, want[L].size(), missing.size(), us, nn, float(us) / 1500.0, float(us) / 4500.0])
	quit(0)
