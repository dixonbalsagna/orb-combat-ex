extends SceneTree
## Sweep check: the building sweep by view (PlanetView.pane_sweep; docs/rendering/view-update.md) leaves the picture as
## the whole sweep draws it, at every frame, wherever a pane can see. A twin planet view, built from the same match and
## fed the same events, sweeps every building every frame. After every frame the check compares the two:
## 1. every building that can draw in any pane's view this frame (the views the sweep took, as far as the props reach
##    from them): the last transform and colour written to each of its instances, its cut floors' and windows' texels,
##    its drawn height, stage, top and footing, its marks, spread, drop and sink, and its figures at home (how many,
##    and each one's last transform and colour); and every runner, wherever it is (when it started, where it runs, its
##    last transform and colour). Headless keeps no MultiMesh data, so both views record what they write
##    (PlanetView.record_writes, RenderCrowdChunks.record).
## 2. the views themselves, with geometry of their own: a building whose parts or figures' spots overlap a pane camera's
##    frustum seen from above (its eight corners' hull, every height) must be in that pane's view.
## Scenes: the hand-made world with the pair set down beside its tallest tower at tier 3 (the collapse clip's start: the
## city comes down in view, its people flee and shelter), and gen 2's planet 7 (touch 3) as it plays; AI against AI,
## with the split attached (a second pane's view is swept in its own draw), at 1 and at 4 ticks a frame. Then two
## failing controls, which must fail: the sweep cut to its slice alone (PlanetView.ctl_slice_only; check 1 must see
## the difference), and with the props' depths narrowed (check 2 must see the buildings the view leaves out).
##   godot --headless --path . --script res://render/tools/sweep_check.gd [-- --ticks=2400 --seeds=4,12345]

const FIG_PAD: float = 60.0   # check 2: a figure as a square this far round its spot

var ticks: int = 2400
var seeds: Array = [4, 12345]
var main: Node
var twin: PlanetView = null
var fails: int = 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	main.started = true
	main.host.drained.connect(_on_drained)   # after main's own: the twin takes the same events
	var view := SplitView.new()
	main.add_child(view)
	view.attach(main)
	PlanetView.record_writes = true
	RenderCrowdChunks.record = true
	var city: Dictionary = {"intro": "skip", "city": true}
	var gen2: Dictionary = {"planet": 7, "planetGen": 2, "touch": 3, "intro": false}
	for seed in seeds:
		for per in [1, 4]:
			_scene("the city at tier 3, seed %d, %d tick%s a frame" % [seed, per, "" if per == 1 else "s"], seed, city, per, ticks, "")
			_scene("gen 2 planet 7, seed %d, %d tick%s a frame" % [seed, per, "" if per == 1 else "s"], seed, gen2, per, ticks, "")
	# The failing controls: each must find what it was built to miss.
	_scene("control A: the sweep cut to its slice", seeds[0], city, 1, mini(ticks, 1800), "slice")
	_scene("control B: the props' depths narrowed", seeds[0], gen2, 1, mini(ticks, 600), "depth")
	PlanetView.record_writes = false
	RenderCrowdChunks.record = false
	if twin != null:
		twin.free()
		twin = null
	view.detach()
	print("sweep check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


func _on_drained(events: Array, _lines: Array) -> void:
	if twin != null:
		twin.consume(events, main.host.S.T)


## One match: [in-view differences, view misses, frames, frames with a second pane, the most out-of-view buildings
## behind at once, buildings visited a frame on average].
func _scene(label: String, seed: int, setup, per: int, n_ticks: int, ctl: String) -> void:
	for p in main.all_panes():
		p.planet.writes.clear()   # the build writes every instance again, recorded
	var su: Dictionary = (setup as Dictionary).duplicate()
	var to_city: bool = bool(su.get("city", false))
	su.erase("city")
	main.start_match(seed, {"p1": true, "p2": true}, su)
	while main.host.loading():
		main.frame(1.0 / 60.0)
	var host: SimHost = main.host
	var S: SimState = host.S
	if to_city:
		var tall = null
		for b in S.buildings:
			if b.alive and (tall == null or b.h > tall.h):
				tall = b
		for i in range(2):
			var f = S.fighters[i]
			f.x = SimWrap.wrap(tall.x - 900.0 + 60.0 * float(i))
			f.y = WorldTerrain.groundY(S, f.x) + 10.0
			f.vx = 0.0
			f.vy = 0.0
			f.tier = 3.0
	var P: PlanetView = main.planet
	if twin != null:
		twin.free()
	twin = PlanetView.new()
	twin.mats = RenderMats.new()
	twin.build(S)
	twin._calm = P._calm
	var t0: float = S.T
	var reach: float = P._reach   # the views as the props reach from them
	PlanetView.ctl_slice_only = ctl == "slice"
	if ctl == "depth":
		P._zspan = Vector2(P._zspan.y - 50.0, P._zspan.y)
	var bad: int = 0
	var missed: int = 0
	var frames: int = 0
	var two: int = 0
	var lag_most: int = 0
	var swept: int = 0
	var seen_n: int = 0     # buildings in view, summed over frames
	var changes: int = 0    # buildings whose drawn state changed in a frame (the twin's), summed
	var was: Array = twin._bld_seen.duplicate(true)
	var first: String = ""
	var t_end: int = host.ticks + n_ticks
	while host.ticks < t_end and not (S.game.ko != null and S.game.koT > 3.0):
		main.frame(float(per) / 60.0)
		if host.loading() or S != host.S:
			break
		twin._calm = P._calm
		if host.vfx.enabled and host.vfx.react_enabled:
			twin.blow_windows(S, host.vfx.react.blowouts)
		twin.update(S, main.pane.view_cam_x, host.impact.heat, true)
		frames += 1
		swept += P.swept
		var cams: Array = _cams()
		if cams.size() > 1:
			two += 1
		var inview: Dictionary = {}
		for sp in P.views:
			var c := PackedInt32Array()
			if (sp as PackedFloat64Array).is_empty():
				c = P._xs_i
			elif sp[1] >= 0.0:
				P._along_x(sp[0] - reach, sp[1] + 2.0 * reach, c)
			for bi in c:
				inview[bi] = true
		seen_n += inview.size()
		for bi in range(S.buildings.size()):
			if twin._bld_seen[bi] != was[bi] or twin._shown[bi] != P._shown[bi]:
				changes += 1
		was = twin._bld_seen.duplicate(true)
		var lag: int = 0
		for bi in range(S.buildings.size()):
			var why: String = _differs(P, twin, bi)
			if why == "":
				continue
			if inview.has(bi) or P.views.is_empty():
				bad += 1
				if first == "":
					first = "tick %d, building %d (x %.0f): %s" % [host.ticks, bi, S.buildings[bi].x, why]
			else:
				lag += 1
		lag_most = maxi(lag_most, lag)
		var rw: String = _runners(P, twin, t0)
		if rw != "":
			bad += 1
			if first == "":
				first = "tick %d: %s" % [host.ticks, rw]
		if frames % 3 == 0 or ctl == "depth":
			for cv in cams:
				var m: Array = _view_misses(P, S, cv, inview)
				missed += int(m[0])
				if int(m[0]) > 0 and first == "":
					first = "tick %d: the view left out building %d, which a camera can see" % [host.ticks, int(m[1])]
	PlanetView.ctl_slice_only = false
	var stats: String = "%d frames (%d with a second pane), %d buildings, %.0f in view and %.1f visited a frame, %d building changes, at most %d out of view behind at once" % [frames, two, S.buildings.size(), float(seen_n) / maxf(frames, 1), float(swept) / maxf(frames, 1), changes, lag_most]
	if ctl == "":
		if bad == 0 and missed == 0 and frames > 0:
			print("ok    %s: %s" % [label, stats])
		else:
			fails += 1
			print("FAIL  %s: %d differences in view, %d buildings a view left out; first: %s (%s)" % [label, bad, missed, first, stats])
	elif ctl == "slice":
		if bad > 0:
			print("ok    %s: %d differences in view found (first: %s)" % [label, bad, first])
		else:
			fails += 1
			print("FAIL  %s: no difference found, so check 1 sees nothing (%s)" % [label, stats])
	else:
		if missed > 0:
			print("ok    %s: %d buildings a view left out found (first: %s)" % [label, missed, first])
		else:
			fails += 1
			print("FAIL  %s: no building left out found, so check 2 sees nothing (%s)" % [label, stats])


## The panes drawn this frame: [camera, the pane's planet, its camera x].
func _cams() -> Array:
	var out: Array = []
	var fr = main.split_frame
	for i in range(main.panes.size()):
		var pw: PaneWorld = main.panes[i]
		if fr == null and i > 0:
			break
		if fr != null and i > 0 and not fr.shows(i):
			continue
		out.append([pw.cam_rig, pw.planet, pw.view_cam_x])
	return out


## What differs between the sweep's drawing of building bi and the twin's ("" for nothing).
func _differs(P: PlanetView, T: PlanetView, bi: int) -> String:
	if P._drawn[bi] != T._drawn[bi]:
		return "drawn %s against %s" % [str(P._drawn[bi]), str(T._drawn[bi])]
	if P._bld_seen[bi] != T._bld_seen[bi]:
		return "set as %s against %s" % [str(P._bld_seen[bi]), str(T._bld_seen[bi])]
	if P._top[bi] != T._top[bi] or P._foot[bi] != T._foot[bi]:
		return "top or footing"
	if P._shown[bi] != T._shown[bi]:
		return "%d figures at home against %d" % [P._shown[bi], T._shown[bi]]
	for d in ["_marks", "_spread", "_busy", "_drops", "_falls"]:
		if (P.get(d) as Dictionary).get(bi) != (T.get(d) as Dictionary).get(bi):
			return d
	var front: bool = P._row0[bi] >= 0
	var cut: Image = (P._cut0 if front else P._cut)[0]
	var cut_t: Image = (T._cut0 if front else T._cut)[0]
	var win: Image = (P._win0 if front else P._win)[0]
	var win_t: Image = (T._win0 if front else T._win)[0]
	for k in P._inst[bi]:
		var key := Vector2i(1 if front else 0, k)
		if P.writes.get(key) != T.writes.get(key):
			return "instance %d written %s against %s" % [k, str(P.writes.get(key)), str(T.writes.get(key))]
		if cut.get_pixel(k, 0) != cut_t.get_pixel(k, 0):
			return "instance %d's cut floors" % k
		for r in range(win.get_height()):
			if win.get_pixel(k, r) != win_t.get_pixel(k, r):
				return "instance %d's windows, row %d" % [k, r]
	for ci in range(P._crowd_first[bi], P._crowd_first[bi + 1]):
		if not P.flight.running(ci) and P._crowd.rec.get(ci) != T._crowd.rec.get(ci):
			return "figure %d" % ci
	return ""


## Every runner of the match since the twin was built, in both: the same runs, placed the same ("" when they are).
func _runners(P: PlanetView, T: PlanetView, t0: float) -> String:
	var a: Dictionary = P.flight._runs
	var b: Dictionary = T.flight._runs
	for ci in a:
		var r: CrowdFlight.Run = a[ci]
		if r.t0 < t0:
			continue
		if not b.has(ci):
			return "runner %d runs only in the sweep's view" % ci
	for ci in b:
		var q: CrowdFlight.Run = b[ci]
		if not a.has(ci):
			return "runner %d runs only in the twin" % ci
		var r: CrowdFlight.Run = a[ci]
		if r.t0 != q.t0 or r.x0 != q.x0 or r.dir != q.dir or r.speed != q.speed or r.dest != q.dest:
			return "runner %d runs differently" % ci
		if P._crowd.rec.get(ci) != T._crowd.rec.get(ci):
			return "runner %d placed differently" % ci
	return ""


## Check 2 for one pane: the buildings a camera can see that its view (inview) leaves out. Its frustum's eight corners
## in the pane planet's space, seen from above, make a convex polygon; a part's box (every height) or a figure's
## square that overlaps it can draw. [how many were left out, the first].
func _view_misses(P: PlanetView, S: SimState, cv: Array, inview: Dictionary) -> Array:
	var cam: Camera3D = cv[0]
	var node: Node3D = cv[1]
	var cam_x: float = float(cv[2])
	var vs: Vector2 = cam.get_viewport().get_visible_rect().size
	var inv: Transform3D = node.global_transform.affine_inverse()
	var pts: Array = []
	for d in [cam.near, cam.far]:
		for s in [Vector2.ZERO, Vector2(vs.x, 0.0), Vector2(vs.x, vs.y), Vector2(0.0, vs.y)]:
			var p: Vector3 = inv * cam.project_position(s, d)
			pts.append(Vector2(p.x, p.z))
	var hull: PackedVector2Array = Geometry2D.convex_hull(PackedVector2Array(pts))
	var W: float = SimConst.W
	var np: int = PlanetView.prop_copies_each_side()
	var n_miss: int = 0
	var first: int = -1
	for bi in range(S.buildings.size()):
		if inview.has(bi):
			continue
		var b: SimState.Building = S.buildings[bi]
		var zc: float = PlanetView._depth(b).x
		var seen: bool = false
		for k in range(-np, np + 1):
			var ox: float = b.x + float(k) * W - cam_x
			for p in P._parts[bi]:
				var hw: float = 0.5 * float(p[RenderShapes.W])
				var hd: float = 0.5 * float(p[RenderShapes.D])
				var cx: float = ox + float(p[RenderShapes.X])
				var cz: float = zc + float(p[RenderShapes.Z])
				if _overlaps(hull, cx - hw, cx + hw, cz - hd, cz + hd):
					seen = true
					break
			if seen:
				break
			for ci in range(P._crowd_first[bi], P._crowd_first[bi + 1]):
				var fx: float = P._crowd_x[ci] + float(k) * W - cam_x
				if _overlaps(hull, fx - FIG_PAD, fx + FIG_PAD, P._crowd_z[ci] - FIG_PAD, P._crowd_z[ci] + FIG_PAD):
					seen = true
					break
			if seen:
				break
		if seen:
			n_miss += 1
			if first < 0:
				first = bi
	return [n_miss, first]


## Whether a convex polygon and the rectangle [x0, x1] x [z0, z1] overlap (the separating axes: the rectangle's two
## and the polygon's edges' normals).
static func _overlaps(hull: PackedVector2Array, x0: float, x1: float, z0: float, z1: float) -> bool:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for v in hull:
		lo = Vector2(minf(lo.x, v.x), minf(lo.y, v.y))
		hi = Vector2(maxf(hi.x, v.x), maxf(hi.y, v.y))
	if hi.x < x0 or lo.x > x1 or hi.y < z0 or lo.y > z1:
		return false
	var rect: Array = [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]
	for i in range(hull.size()):
		var e: Vector2 = hull[(i + 1) % hull.size()] - hull[i]
		var nrm := Vector2(-e.y, e.x)
		if nrm.length_squared() < 1.0e-12:
			continue
		var pmin: float = INF
		var pmax: float = -INF
		for v in hull:
			pmin = minf(pmin, nrm.dot(v))
			pmax = maxf(pmax, nrm.dot(v))
		var rmin: float = INF
		var rmax: float = -INF
		for v in rect:
			rmin = minf(rmin, nrm.dot(v))
			rmax = maxf(rmax, nrm.dot(v))
		if pmax < rmin or rmax < pmin:
			return false
	return true
