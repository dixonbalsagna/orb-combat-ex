extends SceneTree
## Props check: the match's props (render/core/prop_view.gd; docs/rendering/props.md), drawn from World's
## WorldGround.matchProps with Combat's biome block on, and a prop a launch breaks gone from the view.
## 1. off: with the biome block off (as on main) a gen 2 match lays no props and its copies carry none, through a match
##    of AI play: nothing is added to the picture. With it on, the hand-made world (no fine ground) lays none either.
## 2. laid: with it on, a gen 2 match lays every prop matchProps gives the ring that has an Art shape (the others listed),
##    each at its x and standing, and every prop copy carries them; sized as Art ruled (a flat kind by its width, the
##    small kinds under their caps, the rest at World's size).
## 3. broken: PROP SMASH launches, staged as World's flighthooks_probe stages them (a gen 2 spot where the planner offers
##    it; the launch beat when it picks it, else the planner's own plan), played through the game's own frames. On the
##    frame the director's broken columns change, the prop the launch broke is gone from the view and the column draws
##    exactly what matchProps says stands there; every other prop is as it was laid.
## 4. control: the props' update switched off (RenderProps.ctl_frozen): the broken prop stays drawn, so check 3 must fail.
##   godot --headless --path . --script res://render/tools/props_check.gd [-- --spots=6]

const SEEDS: Array = [7, 3, 11, 25, 1, 2, 5, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
const SPACE: int = 40     # columns between two spots
const TRIES: int = 4
const FLY: int = 900      # ticks a launch is followed at most
const PER_WORLD: int = 2  # spots taken from one planet's ring, so the spots spread over planets

var n_spots: int = 6
var main: Node
var fails: int = 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--spots="):
			n_spots = int(a.substr(8))
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("ok    " if cond else "FAIL  ") + what)


func _run() -> void:
	await process_frame
	main.started = true
	_off()
	_laid()
	var spots: Array = _spots()
	ok(spots.size() > 0, "spots: PROP SMASH offered at %d gen 2 spots" % spots.size())
	var r: Dictionary = _broken(spots)
	ok(int(r.breaks) > 0 and int(r.gone) == int(r.breaks) and int(r.bad) == 0, "broken: %d PROP SMASH launches played, %d broke a prop; on the frame each broke, the prop was gone from the view %d times and its column drew what matchProps says stands there; no other prop changed (%d differences)%s" % [int(r.plays), int(r.breaks), int(r.gone), int(r.bad), "" if String(r.first) == "" else "; first: " + String(r.first)])
	RenderProps.ctl_frozen = true
	var c: Dictionary = _broken(spots)
	RenderProps.ctl_frozen = false
	ok(int(c.breaks) > 0 and int(c.gone) < int(c.breaks), "control: with the props' update switched off, %d of %d broken props were gone on their frame (check 3 sees it)" % [int(c.gone), int(c.breaks)])
	DirLaunch.forceBiome = -1
	print("props check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


static func _setup(sd: int, touch: int) -> Dictionary:
	return {"planet": sd, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}


func _start(seed: int, ai: Dictionary, setup: Dictionary) -> SimState:
	main.start_match(seed, ai, setup)
	while main.host.loading():
		main.frame(1.0 / 60.0)
	return main.host.S


## Prop copies carrying the props' meshes.
func _copies_with_props() -> int:
	var n: int = 0
	for c in main.planet.copies():
		for ch in (c as Node).get_children():
			if String(ch.name).begins_with("Props_"):
				n += 1
				break
	return n


func _off() -> void:
	DirLaunch.forceBiome = 0
	var S: SimState = _start(1, {"p1": true, "p2": true}, _setup(7, 3))
	var P: PlanetView = main.planet
	var most: int = 0
	for t in range(600):
		main.frame(1.0 / 60.0)
		most = maxi(most, P.props.count + P.props.meshes.size() + _copies_with_props())
	ok(P.props.count == 0 and most == 0, "off: with the biome block off, gen 2 planet 7 lays no props and no copy carries any, through 600 ticks of AI play (the ring has %d)" % WorldGround.matchProps(S, 0.0, SimConst.W).size())
	DirLaunch.forceBiome = 1
	_start(4, {"p1": true, "p2": true}, {"intro": "skip"})
	ok(main.planet.props.count == 0 and _copies_with_props() == 0, "off: with it on, the hand-made world (no fine ground) lays none")


func _laid() -> void:
	DirLaunch.forceBiome = 1
	for sd in [7, 47]:
		var S: SimState = _start(1, {"p1": true, "p2": true}, _setup(sd, 3))
		var P: RenderProps = main.planet.props
		var raw: Array = WorldGround.matchProps(S, 0.0, SimConst.W)
		var want: int = 0
		var left: Dictionary = {}
		var placed_ok: bool = true
		for p in raw:
			if bool(p.get("cell", false)):
				continue
			if String(p.kind) == RenderProps.LONE_TREE or RenderProps.KINDS.has(String(p.kind)):
				want += 1
			else:
				left[String(p.kind)] = int(left.get(String(p.kind), 0)) + 1
		for i in range(P.count):
			placed_ok = placed_ok and P.shown[i] == 1 and P.placed[i] == P._xf[i]
		var np: int = PlanetView.prop_copies_each_side() * 2 + 1
		ok(P.count == want and placed_ok and _copies_with_props() == np, "laid: gen 2 planet %d lays %d props of the ring's %d (%s not drawn: no Art shape), all standing, in all %d prop copies" % [sd, P.count, raw.size(), str(left), np])
		_sized(P, raw, sd)


## Art's sizes (docs/art/props-review.md): a flat kind's drawn width is World's size, a capped kind's drawn height is
## at most its cap and in proportion to World's size (one ratio a World kind), any other kind's height is World's size.
func _sized(P: RenderProps, raw: Array, sd: int) -> void:
	var size: Dictionary = {}
	for p in raw:
		size[[float(p.x), String(p.kind)]] = float(p.size)
	var by_mesh: Dictionary = {}
	for k in RenderCoverMeshes.kinds():
		by_mesh[RenderCoverMeshes.mesh(k, false)] = k
	var bad: Array = []
	var ratio: Dictionary = {}    # World kind -> drawn height over World's, for the capped kinds
	var tall: Dictionary = {}     # capped cover kind -> the tallest drawn, in fighter heights
	var n: Dictionary = {"flat": 0, "capped": 0, "other": 0}
	for i in range(P.count):
		var ck: String = String(by_mesh.get((P._mm[i] as MultiMesh).mesh, ""))
		var want: float = float(size.get([P._x[i], P._kind[i]], -1.0)) * WorldGround.BH
		var s: float = (P._xf[i] as Transform3D).basis.y.length()
		var h: float = s / RenderCoverMeshes.height_scale(ck)
		var err: String = ""
		if ck == "" or want < 0.0:
			err = "no kind or size"
		elif RenderProps.FLAT.has(ck):
			n.flat += 1
			var w: float = RenderCoverMeshes.mesh(ck, false).get_aabb().size.x * s
			if absf(w - want) > 0.01:
				err = "flat %s %s wide, World's %s" % [ck, str(w), str(want)]
		elif RenderProps.CAPS.has(ck):
			n.capped += 1
			var r: float = h / want
			if h > float(RenderProps.CAPS[ck]) * WorldGround.BH + 0.01 or absf(r - float(ratio.get(P._kind[i], r))) > 0.000001:
				err = "capped %s %s tall (ratio %s)" % [ck, str(h), str(r)]
			ratio[P._kind[i]] = r
			tall[ck] = maxf(float(tall.get(ck, 0.0)), h / WorldGround.BH)
		else:
			n.other += 1
			if absf(h - want) > 0.01:
				err = "%s %s tall, World's %s" % [ck, str(h), str(want)]
		if err != "":
			bad.append("%s at %s: %s" % [P._kind[i], str(P._x[i]), err])
	ok(bad.is_empty() and n.flat + n.capped + n.other == P.count, "sized: planet %d's %d flat props as wide as World's size, %d capped props in proportion under their caps (tallest %s heights), %d others as tall as World's size%s" % [sd, n.flat, n.capped, str(tall), n.other, "" if bad.is_empty() else "; %d wrong, first: %s" % [bad.size(), bad[0]]])


## PROP SMASH's spots, as the probe finds them (at most PER_WORLD a ring): [planet, touch, x, side].
func _spots() -> Array:
	var out: Array = []
	for sd in SEEDS:
		for touch in [0, 1]:
			if out.size() >= n_spots:
				return out
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, _setup(sd, touch))
			var last: int = -999
			var here: int = 0
			for col in range(0, SimConst.NC, 4):
				if out.size() >= n_spots or here >= PER_WORLD:
					break
				var x: float = (float(col) + 0.5) * SimConst.COL
				for sg in [1.0, -1.0]:
					_pose(S, x, sg)
					if _offered(S).has("PROP SMASH") and col - last >= SPACE:
						out.append([sd, touch, x, sg])
						last = col
						here += 1
						break
			SimCore.dispose(S)
	return out


static func _pose(S: SimState, x: float, sg: float) -> void:
	var A = S.fighters[0]
	var D = S.fighters[1]
	for f in S.fighters:
		f.ai = null
		f.rush = null
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	var g: float = WorldTerrain.groundY(S, x)
	D.x = SimWrap.wrap(x)
	D.y = (WorldWater.seaTop(S, x) + 40.0) if WorldTerrain.seaAt(S, x) else g + 2.0
	A.x = SimWrap.wrap(x - sg * 200.0)
	A.y = D.y
	A.face = sg
	D.face = -sg


static func _force() -> float:
	return float(DirBrawl.cfg().get("heavy", {}).get("force", 1.0))


static func _offered(S: SimState) -> Array:
	var c: Array = []
	DirLaunch._biomeCands(S, S.fighters[0], S.fighters[1], c, false, not DirData.contact().is_empty(), _force() * SimForms.launchMul(S, S.fighters[0]))
	return c.map(func(k): return String(k.name))


## Every spot's launch through the game's frames, the view checked on each frame: {plays, breaks, gone, bad, first}.
func _broken(spots: Array) -> Dictionary:
	var out := {"plays": 0, "breaks": 0, "gone": 0, "bad": 0, "first": ""}
	for sp in spots:
		var got: bool = false
		for t in range(TRIES * 2):
			if _play(sp, float(sp[3]) * (1.0 if t % 2 == 0 else -1.0), 7 * t, true, out):
				got = true
				break
		if not got:
			_play(sp, float(sp[3]), 0, false, out)   # the planner's own plan, as the probe does when the beat picks another
	return out


## One launch at spot sp: true when PROP SMASH was launched there (by the launch beat when it picks it, or by doLaunch).
func _play(sp: Array, sg: float, pre: int, beat: bool, out: Dictionary) -> bool:
	var S: SimState = _start(1, {}, _setup(int(sp[0]), int(sp[1])))
	for i in range(pre):
		main.frame(1.0 / 60.0)
	_pose(S, float(sp[2]), sg)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var ex = DirExchange.newEx(A, D, "props check")
	S.dirS.ex = ex
	D.state = "locked"
	if beat:
		DirMelee.launchBeat(S, ex, A, D, _force(), false, {"forced": true, "why": "props check"})
		var chosen: String = ""
		for e in S.out.fx:
			if String(e.type) == "launch_plan":
				chosen = String(e.chosen)
		if chosen != "PROP SMASH" or D.state != "launched":
			return false
	else:
		var used: Dictionary = {}
		for k in DirLaunch.chooseLaunch(S, A, D, _force()).all:
			if String(k.name) == "PROP SMASH":
				used = k
		if used.is_empty():
			return false
		DirLaunch.doLaunch(S, A, D, used, _force())
		if D.state != "launched":
			return false
	out.plays = int(out.plays) + 1
	var P: RenderProps = main.planet.props
	var was: PackedInt32Array = SimDir.brokenProps(S)
	for t in range(FLY):
		if D.state != "launched" and D.skateV <= 0.0:
			break
		main.frame(1.0 / 60.0)
		var br: PackedInt32Array = SimDir.brokenProps(S)
		if br == was:
			continue
		var cols: Dictionary = {}
		for c in br:
			if not was.has(c):
				cols[c] = true
		was = br
		for c in cols:
			out.breaks = int(out.breaks) + 1
			# What stands in the column now, as the sim has it, against what the view draws there.
			var want: Array = []
			for p in WorldGround.matchProps(S, float(c) * SimConst.COL, float(c) * SimConst.COL, br):
				if not bool(p.get("cell", false)) and (String(p.kind) == RenderProps.LONE_TREE or RenderProps.KINDS.has(String(p.kind))):
					want.append([float(p.x), String(p.kind)])
			var raw: int = 0
			for p in WorldGround.matchProps(S, float(c) * SimConst.COL, float(c) * SimConst.COL):
				if not bool(p.get("cell", false)) and (String(p.kind) == RenderProps.LONE_TREE or RenderProps.KINDS.has(String(p.kind))):
					raw += 1
			var have: Array = P.standing(c)
			want.sort()
			have.sort()
			if have == want and want.size() == raw - 1:
				out.gone = int(out.gone) + 1
			elif String(out.first) == "":
				out.first = "planet %d column %d: the view draws %s, the sim has %s standing" % [int(sp[0]), c, str(have), str(want)]
		# Every prop outside a broken column is as it was laid.
		for i in range(P.count):
			var col: int = posmod(int(floor(P._x[i] / SimConst.COL)), SimConst.NC)
			if br.has(col):
				continue
			if P.shown[i] != 1 or P.placed[i] != P._xf[i]:
				out.bad = int(out.bad) + 1
				if String(out.first) == "":
					out.first = "a prop at x %.0f outside the broken columns changed" % P._x[i]
	return true
