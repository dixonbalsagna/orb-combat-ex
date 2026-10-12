extends SceneTree
## The re-laid city's shapes, looks and lanes (headless): what render/core/shapes.gd and lanes.gd make of the sim's
## buildings and lane table, and what the planet view hands the shaders. No picture is judged here (headless Godot
## compiles no shaders): the stills come from the web build (docs/rendering/lanes-look.md).
## - the lane table is the sim's, and fits the ground shader's arrays (strips, districts, avenues);
## - every look in the data has its table here (a look with none is drawn in the fallback, and named);
## - every one of the 20 shapes builds, the body first and on the ground, and a shape with no builder is the sim's box;
## - in a real match no part of any building stands higher than the sim's height, or wider than the sim's width but
##   for a roof's eaves;
## - a part as it stands: whole, scaled with the hit points, cut off with a tower's top floors (its caps gone), and as
##   a shell (roofs and caps gone, the body as tall as the sim says);
## - the planet view: an instance for every part, the body's the building's own; each part's texel carries its shape and
##   its look; a damaged tower's top is the sim's; a cut tower's skirt opens the same floors as its body;
## - the rows' haze: none on the front block, more on the back block, most on the scenery row; the ground shader has
##   the avenues and the two block lanes.
##   godot --headless --path . --script res://render/tools/shape_check.gd [-- --seed=1]

const SHAPES: Array = ["shaft", "stepped", "spire", "slab", "block", "warehouse", "chimney", "house", "shop", "hall", "shed", "crane", "lighthouse", "chapel", "crown", "terrace", "sawtooth", "thatch", "quay", "mast"]

var main: Node
var fails: int = 0
var seed_n: int = 1


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed_n = int(a.substr(7))
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	print("%s %s" % ["ok   " if ok else "FAIL ", what])
	if not ok:
		fails += 1


## The worst a building's parts do against the sim's box: [over the height, a wall over the width, a roof's eaves over the width (share of the width)].
static func _over(b, ps: Array) -> Vector3:
	var o := Vector3.ZERO
	for p in ps:
		o.x = maxf(o.x, float(p[RenderShapes.Y1]) - b.h)
		var half: float = absf(float(p[RenderShapes.X])) + 0.5 * float(p[RenderShapes.W]) * maxf(1.0, float(p[RenderShapes.TX]))
		if (int(p[RenderShapes.FLAGS]) & RenderShapes.ROOF) != 0:
			o.z = maxf(o.z, (half - 0.5 * b.w) / b.w)
		else:
			o.y = maxf(o.y, half - 0.5 * b.w)
	return o


func _run() -> void:
	await process_frame
	main.started = true
	main.start_match(seed_n, {"p1": true, "p2": true}, {"intro": "skip"})
	var host: SimHost = main.host
	var S: SimState = host.S
	main.frame(1.0 / 60.0)
	var P: PlanetView = main.planet
	# The lane table.
	var t: PackedFloat32Array = RenderLanes.table(S)
	_expect(t == S.lanes and t.size() >= RenderLanes.HEADER and int(t[2]) <= PlanetView.STREET_STRIPS and int(t[3]) <= PlanetView.STREET_SPANS and int(t[4]) <= PlanetView.STREET_AVENUES, "the lane table is the sim's (%d floats) and fits the ground shader: %d strips (%d at most), %d districts (%d), %d avenues (%d)" % [t.size(), int(t[2]), PlanetView.STREET_STRIPS, int(t[3]), PlanetView.STREET_SPANS, int(t[4]), PlanetView.STREET_AVENUES])
	var empty := SimState.new()
	_expect(RenderLanes.strips(RenderLanes.table(empty), 8).is_empty() and RenderLanes.districts(RenderLanes.table(empty), 16).is_empty() and RenderLanes.avenues(RenderLanes.table(empty), 12).is_empty() and RenderLanes.blocks(RenderLanes.table(empty)).is_empty(), "a world with no lane table paints nothing (no stand-in)")
	# The looks.
	var missing: Array = []
	for n in RenderShapes.look_names():
		if not RenderShapes.LOOK.has(str(n)):
			missing.append(str(n))
	_expect(missing.is_empty() and RenderShapes.look_names().size() <= RenderShapes.STONE, "every look in the data (%d) has its colours and windows here%s" % [RenderShapes.look_names().size(), "" if missing.is_empty() else ": none for %s (drawn as %s)" % [str(missing), RenderShapes.FALLBACK]])
	# Every shape builds.
	var bad: Array = []
	for sh in SHAPES + ["a shape nobody drew"]:
		for dims in [[260.0, 500.0, 6200.0, 41, 0], [300.0, 420.0, 380.0, 3, 0], [375.0, 338.0, 11250.0, 62, 1]]:
			var b := SimState.Building.new()
			b.shape = sh; b.w = dims[0]; b.d = dims[1]; b.h = dims[2]; b.floors = dims[3]; b.landmark = dims[4]; b.seed = 0.37; b.kind = "tower" if dims[2] > 1000.0 else "house"
			var ps: Array = RenderShapes.parts(b, RenderShapes.look(0))
			var o: Vector3 = _over(b, ps)
			if ps.is_empty() or float(ps[0][RenderShapes.Y0]) != 0.0 or o.x > 0.01 or o.y > 0.5 or o.z > 0.13 or (sh == "a shape nobody drew" and ps.size() != 1):
				bad.append("%s %s: %d parts, over %s" % [sh, str(dims), ps.size(), str(o)])
	_expect(bad.is_empty(), "each of the %d shapes builds at three sizes, the body first and on the ground, inside the sim's box (a roof's eaves at most 13%% of the width out); a shape with no builder is the sim's box%s" % [SHAPES.size(), "" if bad.is_empty() else ": " + str(bad.slice(0, 3))])
	# The real city.
	var worst := Vector3.ZERO
	var by: Dictionary = {}
	var total: int = 0
	for bi in range(S.buildings.size()):
		var b = S.buildings[bi]
		var o: Vector3 = _over(b, P._parts[bi])
		worst = Vector3(maxf(worst.x, o.x), maxf(worst.y, o.y), maxf(worst.z, o.z))
		by[str(b.shape)] = int(by.get(str(b.shape), 0)) + 1
		total += (P._parts[bi] as Array).size()
	_expect(worst.x <= 0.01 and worst.y <= 0.5 and worst.z <= 0.13, "seed %d: none of the %d buildings' %d parts stands higher than the sim's height (%.2f over), or wider than its width (%.2f) but for a roof's eaves (%.0f%% of the width)" % [seed_n, S.buildings.size(), total, worst.x, worst.y, 100.0 * worst.z])
	print("      shapes in this world: %s" % str(by))
	# A part as it stands.
	var tw := SimState.Building.new()
	tw.shape = "stepped"; tw.w = 300.0; tw.d = 500.0; tw.h = 6000.0; tw.floors = 40; tw.seed = 0.2; tw.kind = "tower"
	var tps: Array = RenderShapes.parts(tw, RenderShapes.look(0))
	var whole_ok: bool = true
	var cut_ok: bool = true
	var shell_ok: bool = true
	var scale_ok: bool = true
	for j in range(tps.size()):
		var p: Array = tps[j]
		var cap: bool = (int(p[RenderShapes.FLAGS]) & (RenderShapes.CAP | RenderShapes.ROOF)) != 0
		var w: Array = RenderShapes.span(p, j == 0, 6000.0, 6000.0, 0, false)
		whole_ok = whole_ok and not w.is_empty() and float(w[1]) <= 6000.0 + 0.01
		var c: Array = RenderShapes.span(p, j == 0, 2400.0, 6000.0, 2, true)
		cut_ok = cut_ok and (c.is_empty() if cap else (c.is_empty() or float(c[1]) <= 2400.0 + 0.01)) and (j > 0 or float(c[1]) == 2400.0)
		var s: Array = RenderShapes.span(p, j == 0, 3000.0, 6000.0, 1, false)
		scale_ok = scale_ok and not s.is_empty() and float(s[1]) <= 3000.0 + 0.01 and is_equal_approx(float(s[1]), float(p[RenderShapes.Y1]) * 0.5)
		var e: Array = RenderShapes.span(p, j == 0, 1800.0, 6000.0, 3, false)
		shell_ok = shell_ok and (e.is_empty() if cap else float(e[1]) <= 1800.0 + 0.01) and (j > 0 or float(e[1]) == 1800.0)
	_expect(whole_ok and scale_ok and cut_ok and shell_ok, "a stepped tower's parts: all show when it is whole; they scale with its hit points; with its top floors gone the caps go and nothing stands over its height; a shell has no cap and its body is as tall as the sim says")
	# The planet view.
	var inst_ok: bool = P._n_inst >= S.buildings.size()
	var texel_ok: bool = true
	var seen: Dictionary = {}
	for bi in range(S.buildings.size()):
		var ix: PackedInt32Array = P._inst[bi]
		var ps: Array = P._parts[bi]
		inst_ok = inst_ok and ix.size() == ps.size() and ix[0] == (P._row0[bi] if P._row0[bi] >= 0 else bi)
		var img: Image = (P._win0 if P._row0[bi] >= 0 else P._win)[0]
		for j in range(ix.size()):
			inst_ok = inst_ok and not seen.has([P._row0[bi] >= 0, ix[j]])
			seen[[P._row0[bi] >= 0, ix[j]]] = true
			var s: Color = img.get_pixel(ix[j], 2)
			var want_look: int = int(ps[j][RenderShapes.LOOKX]) if int(ps[j][RenderShapes.LOOKX]) >= 0 else RenderShapes.look_of(t, S.buildings[bi])
			texel_ok = texel_ok and is_equal_approx(s.r, float(ps[j][RenderShapes.TX])) and is_equal_approx(s.g, float(ps[j][RenderShapes.TZ])) and is_equal_approx(s.b, float(ps[j][RenderShapes.LEAN])) and int(round(s.a)) == want_look
	_expect(inst_ok and texel_ok and seen.size() == total, "the planet view: an instance for each of the %d parts (the body's is the building's own, none shared), and each part's texel carries its shape and its look" % total)
	# A damaged tower and a cut one.
	var tall: int = -1
	var step: int = -1
	for bi in range(S.buildings.size()):
		var b = S.buildings[bi]
		if int(b.row) == 1 and int(b.floors) >= 20 and int(b.landmark) == 0:
			if str(b.shape) == "stepped" and step < 0:
				step = bi
			elif str(b.shape) != "stepped" and tall < 0:
				tall = bi
	if tall >= 0 and step >= 0:
		var b = S.buildings[tall]
		b.hp = b.maxhp * 0.5
		var c = S.buildings[step]
		c.fmask = c.fmask & ~(0x7 << 3)   # floors 3, 4 and 5 out: a tunnel
		P.refresh(S, false)
		var base: float = WorldStructures.baseY(S, b)
		var cimg: Image = P._cut[0]
		var body_cut: Color = cimg.get_pixel(step, 0)
		var skirt_cut: Color = cimg.get_pixel((P._inst[step] as PackedInt32Array)[1], 0)
		_expect(is_equal_approx(P._top[tall], base + WorldStructures.curH(b)) and body_cut.a > 0.0 and skirt_cut.a == body_cut.a and skirt_cut.r == body_cut.r and int(skirt_cut.b / 16384.0) <= int(body_cut.b / 16384.0), "a tower at half its hit points is drawn to the sim's height (%.0f of %.0f); a stepped tower with three floors out opens them in its skirt as in its body" % [WorldStructures.curH(b), b.h])
	else:
		_expect(false, "this world has a tall tower and a stepped one in the front row to try")
	# The rows' haze, and the ground's avenues and lots.
	var hz: Vector3 = P._bld_mat.get_shader_parameter("row_haze")
	var rows: Array = [0.0, 0.0, 0.0]
	var off: int = int(t[10])
	for k in range(int(t[1])):
		var row: int = int(t[off + 4 * k + 3])
		if row >= 1 and row <= 3:
			rows[row - 1] = hz.x * clampf((-t[off + 4 * k] - hz.y) / maxf(hz.z - hz.y, 1.0), 0.0, 1.0)
	_expect(hz == RenderLook.ROW_HAZE and rows[0] == 0.0 and rows[1] > 0.05 and rows[2] > rows[1] + 0.1 and rows[2] <= 0.5, "the rows' haze: none on the front block, %.2f on the back block, %.2f on the scenery row" % [rows[1], rows[2]])
	var tm: ShaderMaterial = P._terrain_mat
	var lz: Vector4 = tm.get_shader_parameter("lot_z")
	var bl: Array = RenderLanes.blocks(t)
	_expect(int(tm.get_shader_parameter("avenue_n")) == int(t[4]) and int(tm.get_shader_parameter("street_n")) == int(t[2]) and bl.size() == 2 and lz == Vector4(bl[0].x, bl[0].y, bl[1].x, bl[1].y) and (tm.get_shader_parameter("lot_col") as Array).size() == 8, "the ground shader has the table's %d strips, its %d avenues and the two block lanes (%s)" % [int(t[2]), int(t[4]), str(lz)])
	print("shape check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)
