extends SceneTree
## Stage check (headless): a building is drawn at World's damage stage, read from the state and from nothing else
## (docs/rendering/building-stages.md). The look itself is the shader's and is judged in pictures; this guards what
## the shader is handed. The tool sets hit points and floors on its own fresh match's buildings (its own state; no
## tick runs) and reads back the stage PlanetView wrote for building.gdshader:
## - a house and a tower at 100, 80, 50 and 20% of their hit points are handed stages 0, 1, 2 and 3;
## - hit points put back (a replay seek) hand back stage 0: nothing is remembered;
## - a tower with a cut floor is handed stage 2 at full hit points, and its stage follows its hit points from there
##   though its height does not change;
## - a building that falls with no fall event stands no more at once, and is not placed again on later frames;
## - a held hit's mark and a stage that spreads (docs/rendering/destruction-look.md 3.1 and 3.7; rows 4 to 9 of the
##   window texture): floors damaged with no event are one mark, whole at once, on every part; damage put back leaves
##   none; with a wall slam's events the mark is on the side he came from and grows from that tick, and the stage
##   spreads from the stage before, from that edge at the hit's height; the spread is over after
##   RenderLook.SPREAD_TICKS; a heavier blow grows the mark from the share it had; the tick gone back settles
##   everything; a floor that breaks is no mark; a blast spreads a house's stage from its foot on the blast's side; a
##   lodge spreads it from where the body lies; a building that falls drops its spread. The tool makes its own events;
## - a second stage change while a spread is going is a second wave inside the first (row 10), which goes on alone when
##   the first is over; a top brought lower by a hit comes down at RenderLook.DROP_SPEED and is at its height at once
##   with no event; floors a blow-out puts out are kept from the first row's mask and go as a wave (rows 11 and 12).
## (A headless run cannot read an instance's place back from a MultiMesh, so the roof going at stage 3 is not checked
## here: it is in the stills.)
##   godot --headless --path . --script res://render/tools/stage_check.gd -- [--s=4]

var seed: int = 4
var main: Node
var fails: int = 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--s="):
			seed = int(a.substr(4))
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


func _run() -> void:
	await process_frame
	main.started = true
	main.start_match(seed)
	var S: SimState = main.host.S
	var P: PlanetView = main.pane.planet
	for kind in ["house", "tower"]:
		var bi: int = -1
		for i in range(S.buildings.size()):
			var c = S.buildings[i]
			if c.alive and String(c.kind) == kind and (kind == "house" or int(c.floors) >= WorldBrunt.FLOORS_MIN):
				bi = i
				break
		if bi < 0:
			_expect(false, "a standing %s to test" % kind)
			continue
		var b = S.buildings[bi]
		var got: Array = []
		for share in [1.0, 0.8, 0.5, 0.2]:
			b.hp = b.maxhp * share
			P.refresh(S, false)
			got.append(_stage(P, bi))
			if _stage(P, bi) != WorldStructures.stage(b):
				_expect(false, "%s at %d%%: drawn at World's stage (%d against %d)" % [kind, int(share * 100.0), _stage(P, bi), WorldStructures.stage(b)])
		_expect(got == [0, 1, 2, 3], "%s at 100, 80, 50 and 20%% of its hit points is handed stages 0 to 3 (%s)" % [kind, str(got)])
		b.hp = b.maxhp
		P.refresh(S, false)
		_expect(_stage(P, bi) == 0, "%s with its hit points put back is intact again: nothing is remembered" % kind)
		if kind == "tower":
			var full: int = int(b.fmask)
			b.fmask = full & ~0b10
			P.refresh(S, false)
			var h0: float = WorldStructures.curH(b)
			_expect(_stage(P, bi) == 2, "a tower with a cut floor is handed stage 2 at full hit points (%d)" % _stage(P, bi))
			b.hp = b.maxhp * 0.2
			P.refresh(S, false)
			_expect(_stage(P, bi) == 3 and WorldStructures.curH(b) == h0, "... and its stage follows its hit points though its height does not change (%d)" % _stage(P, bi))
			b.fmask = full
			b.hp = b.maxhp
			P.refresh(S, false)
		# It falls (no fall event, so no sink): it stands no more at once, and is left alone after.
		b.hp = 0.0
		b.alive = false
		P.refresh(S, false)
		var seen: Array = P._bld_seen[bi]
		P.refresh(S, false)
		P.refresh(S, false)
		_expect(P._top[bi] == -INF and not P._drawn[bi][2], "a fallen %s stands no more" % kind)
		_expect(is_same(P._bld_seen[bi], seen), "... and is not placed again on later frames")
	_marks_and_spread(S, P)
	print("stage check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


static func _ev(type: String, bi: int, props: Dictionary) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = type
	e.b = float(bi)
	for key in props:
		e.set(key, props[key])
	return e


## A standing building of this kind behind the fighter plane that the checks above have not touched (-1: none).
static func _fresh(S: SimState, P: PlanetView, kind: String, floors: int) -> int:
	for i in range(S.buildings.size()):
		var c = S.buildings[i]
		if c.alive and String(c.kind) == kind and int(c.floors) >= floors and P._row0[i] < 0 and c.hp == c.maxhp and c.fmask == (1 << int(c.floors)) - 1:
			return i
	return -1


func _marks_and_spread(S: SimState, P: PlanetView) -> void:
	var bi: int = _fresh(S, P, "tower", 8)
	var hi: int = _fresh(S, P, "house", 0)
	if bi < 0 or hi < 0:
		_expect(false, "a fresh tower of eight floors and a fresh house behind the plane to test")
		return
	var none := Color(0, 0, 0, 0)
	var b = S.buildings[bi]
	var F: int = int(b.floors)
	var img: Image = P._win[0]
	var ix: PackedInt32Array = P._inst[bi]
	var k0: int = ix[0]
	var ps: Array = P._parts[bi]
	var shx: float = float(ps[RenderShapes.shell(ps)][RenderShapes.X])
	var fh: float = WorldBrunt.floorH(b)
	var s3: float = WorldBrunt.floorStr(b, 3)
	var s4: float = WorldBrunt.floorStr(b, 4)
	# Floors damaged, no event (a seek, a late join).
	b.fdmg = PackedFloat32Array()
	b.fdmg.resize(F)
	b.fdmg.fill(0.0)
	b.fdmg[3] = 0.5 * s3
	b.fdmg[4] = 0.25 * s4
	b.hp -= 1.0
	P.refresh(S, false)
	var run: Color = img.get_pixel(k0, 6)
	_expect(_stage(P, bi) == 2 and img.get_pixel(k0, 4).b == 1.0 and int(run.r) % 64 == 3 and (int(run.r) >> 6) % 64 == 2 and absf(run.g - 0.5) < 0.001 and absf(run.b) == 1.0 and run.a < -1.0e5 and img.get_pixel(k0, 7) == none and img.get_pixel(k0, 5) == none and P._spread.is_empty() and P._busy.is_empty(), "a tower with two floors damaged and no event carries one mark, whole at once: floors 3 and 4, the heavier's share, and nothing spreads (%s)" % str(run))
	var same: bool = true
	for k in ix:
		same = same and img.get_pixel(k, 6) == run and img.get_pixel(k, 4).b == 1.0
	_expect(same, "... the same on each of its %d parts" % ix.size())
	b.fdmg.fill(0.0)
	b.hp = b.maxhp
	P.refresh(S, false)
	_expect(_stage(P, bi) == 0 and img.get_pixel(k0, 4).b == 0.0 and img.get_pixel(k0, 6) == none and not P._marks.has(bi), "its damage put back, the mark is gone: nothing is remembered")
	# A wall slam from the left, with its events.
	S.tick = 600
	var y: float = WorldStructures.baseY(S, b) + 4.0 * fh
	P.consume([_ev("floor_hit", bi, {"floor": 3, "outcome": "crack", "ux": 1.0, "y": y}), _ev("building_stage", bi, {"cx": b.x - 400.0}), _ev("building_hit", bi, {"outcome": "wall", "ux": 1.0, "y": y})], S.T)
	b.fdmg[3] = 0.5 * s3
	b.fdmg[4] = 0.25 * s4
	b.hp -= 1.0
	P.refresh(S, false)
	run = img.get_pixel(k0, 6)
	var sp: Color = img.get_pixel(k0, 5)
	_expect(img.get_pixel(k0, 4).b == 3.0 and run.b == -1.0 and run.a == 600.0 and int(run.r) >> 12 >= 1, "a wall slam from the left, with its events: the mark is on the left side and grows from this tick (%s)" % str(run))
	_expect(P._spread.has(bi) and absf(sp.r - (-0.5 * b.w - shx)) < 0.01 and absf(sp.g - 4.0 * fh) < 0.01 and sp.b == 600.0 and int(sp.a) % 4 == 0 and int(sp.a) >> 2 >= 1, "... and its stage spreads from the stage before (0), from the left edge at the hit's height (%s)" % str(sp))
	S.tick = 600 + RenderLook.SPREAD_TICKS
	P.refresh(S, false)
	_expect(img.get_pixel(k0, 4).b == 1.0 and img.get_pixel(k0, 5) == none and img.get_pixel(k0, 6).a < -1.0e5 and P._busy.is_empty() and P._spread.is_empty(), "after RenderLook.SPREAD_TICKS (%d) the spread is over: the building as it stands, its mark whole" % RenderLook.SPREAD_TICKS)
	# A heavier blow on the same floors.
	S.tick = 1000
	P.consume([_ev("floor_hit", bi, {"floor": 3, "outcome": "dent", "ux": 1.0, "y": y})], S.T)
	b.fdmg[3] = 0.8 * s3
	b.hp -= 1.0
	P.refresh(S, false)
	run = img.get_pixel(k0, 6)
	_expect(absf(run.g - 0.8) < 0.001 and absf(run.b + 1.5) < 0.001 and run.a == 1000.0 and not P._spread.has(bi) and P._busy.has(bi), "a heavier blow on the same floors: the mark grows from the share it had (0.5) to its new one (0.8) from this tick; its stage has not changed, so no stage spreads (%s)" % str(run))
	S.tick = 900
	P.refresh(S, false)
	run = img.get_pixel(k0, 6)
	_expect(P._busy.is_empty() and run.a < -1.0e5 and run.b == -1.0, "the tick gone back (a seek): everything settles at once (%s)" % str(run))
	# The floor breaks: World clears it and forgets its damage.
	b.fmask = int(b.fmask) & ~(1 << 3)
	b.fdmg[3] = 0.0
	P.refresh(S, false)
	run = img.get_pixel(k0, 6)
	_expect(int(run.r) % 64 == 4 and (int(run.r) >> 6) % 64 == 1 and absf(run.g - 0.25) < 0.001 and run.b == -1.0 and img.get_pixel(k0, 7) == none, "a floor that breaks is a cleared floor, not a mark: the mark is the floor that still stands (%s)" % str(run))
	# A lodge: the body's place.
	S.tick = 3000
	P.consume([_ev("building_hit", bi, {"outcome": "punch", "ux": 1.0, "y": y}), _ev("building_stage", bi, {"cx": b.x}), _ev("lodge", bi, {"x": b.x + 0.2 * b.w, "y": y})], S.T)
	b.hp = b.maxhp * 0.2
	P.refresh(S, false)
	sp = img.get_pixel(k0, 5)
	_expect(_stage(P, bi) == 3 and absf(sp.r - (0.2 * b.w - shx)) < 0.01 and absf(sp.g - 4.0 * fh) < 0.01 and sp.b == 3000.0 and int(sp.a) % 4 == 2, "a lodge that takes it to a shell: the stage spreads from where the body lies, from the stage before (2) (%s)" % str(sp))
	# A blast beside a house.
	var hb = S.buildings[hi]
	var hk: int = (P._inst[hi] as PackedInt32Array)[0]
	var hps: Array = P._parts[hi]
	var hshx: float = float(hps[RenderShapes.shell(hps)][RenderShapes.X])
	S.tick = 3100
	P.consume([_ev("building_stage", hi, {"cx": hb.x + 1000.0})], S.T)
	hb.hp = hb.maxhp * 0.2
	P.refresh(S, false)
	sp = img.get_pixel(hk, 5)
	_expect(_stage(P, hi) == 3 and img.get_pixel(hk, 4).b == 2.0 and absf(sp.r - (0.5 * hb.w - hshx)) < 0.01 and sp.g == 0.0 and sp.b == 3100.0 and int(sp.a) % 4 == 0 and int(sp.a) >> 2 == 1, "a blast to the right of a house takes it to a shell: the stage spreads from its right edge at its foot, with the whole area a tick though the tower's spread is still going (%s)" % str(sp))
	hb.hp = 0.0
	hb.alive = false
	P.refresh(S, false)
	_expect(not P._spread.has(hi) and not P._busy.has(hi), "... and when it falls its spread is dropped")
	# Two stage changes three ticks apart (a blast and its second): the second spreads inside the first.
	var ti: int = _fresh(S, P, "tower", 8)
	if ti < 0:
		_expect(false, "a second fresh tower to test")
		return
	var t = S.buildings[ti]
	var tk: int = (P._inst[ti] as PackedInt32Array)[0]
	var h_full: float = WorldStructures.curH(t)
	S.tick = 5000
	P.consume([_ev("building_stage", ti, {"cx": t.x - 900.0})], S.T)
	t.hp = t.maxhp * 0.8
	P.refresh(S, false)
	var w1: Color = img.get_pixel(tk, 5)
	_expect(_stage(P, ti) == 1 and img.get_pixel(tk, 4).b == 2.0 and w1.b == 5000.0 and int(w1.a) % 4 == 0 and img.get_pixel(tk, 10) == none, "a blast takes a tower to stage 1: one wave from the stage before (0) (%s)" % str(w1))
	_expect(P._drops.has(ti) and absf(float(P._drawn[ti][0]) - h_full) < 0.01 and WorldStructures.curH(t) < h_full - 50.0, "... and its top, which the sim brought %.0f units lower, is still where it was: it comes down at a set speed" % (h_full - WorldStructures.curH(t)))
	S.tick = 5003
	var blast_y: float = WorldStructures.baseY(S, t) + 220.0
	P.consume([_ev("building_stage", ti, {"cx": t.x - 900.0}), _ev("crater", -1, {"x": t.x - 900.0, "y": blast_y})], S.T)
	t.hp = t.maxhp * 0.5
	P.refresh(S, false)
	var w2: Color = img.get_pixel(tk, 10)
	_expect(_stage(P, ti) == 2 and img.get_pixel(tk, 4).b == 6.0 and img.get_pixel(tk, 5) == w1 and w2.b == 5003.0 and int(w2.a) % 4 == 1 and absf(w2.g - 220.0) < 0.01 and w1.g == 0.0, "its second three ticks later, with its crater: the first wave is kept as it was, and the new stage spreads inside it as a second wave from the stage between (1), from the blast's own height (%s)" % str(w2))
	var d3: float = PlanetView.dropped(3.0, false)
	_expect(absf(float(P._drawn[ti][0]) - (h_full - d3)) < 0.01 and d3 > 0.0 and d3 < 15.0, "... and its top has come down %.2f units in three ticks, on the way to its new height" % d3)
	S.tick = 5000 + RenderLook.SPREAD_TICKS
	P.refresh(S, false)
	_expect(img.get_pixel(tk, 4).b == 2.0 and img.get_pixel(tk, 5).b == 5003.0 and int(img.get_pixel(tk, 5).a) % 4 == 1 and img.get_pixel(tk, 10) == none and P._busy.has(ti), "the first wave over, the second goes on alone")
	S.tick = 5003 + RenderLook.SPREAD_TICKS
	P.refresh(S, false)
	_expect(img.get_pixel(tk, 4).b == 0.0 and img.get_pixel(tk, 5) == none and not P._busy.has(ti) and not P._drops.has(ti) and absf(float(P._drawn[ti][0]) - WorldStructures.curH(t)) < 0.01, "... and when that is over the tower is as it stands, at its own height")
	t.hp = t.maxhp * 0.3
	P.refresh(S, false)
	_expect(not P._drops.has(ti) and absf(float(P._drawn[ti][0]) - WorldStructures.curH(t)) < 0.01 and not P._spread.has(ti), "hit points lowered with no event (a seek): its height and its stage change at once")
	# A blow-out: the floors it puts out go as a wave.
	S.tick = 6000
	var before: Color = img.get_pixel(tk, 0)
	P.blow_windows(S, [{"b": ti, "at": S.T, "strength": 0.5, "lo": 0, "hi": 0}])
	var fresh: Color = img.get_pixel(tk, 11)
	var bw: Color = img.get_pixel(tk, 12)
	_expect(P._blowing.has(ti) and img.get_pixel(tk, 0) == before and fresh.r + fresh.g + fresh.b > 0.0 and img.get_pixel(tk, 4).b == 8.0 and bw.b == 6000.0 and P._blown[ti] != 0, "a blow-out's floors are kept from the first row's mask and written as a wave from this tick (%s, %s)" % [str(fresh), str(bw)])
	S.tick = 6000 + RenderLook.SPREAD_TICKS
	P.refresh(S, false)
	var after: Color = img.get_pixel(tk, 0)
	_expect(not P._blowing.has(ti) and after.r == fresh.r and after.g == fresh.g and after.b == fresh.b and img.get_pixel(tk, 11) == none and img.get_pixel(tk, 4).b == 0.0, "... and when the wave is over they are in the first row's mask")


## The stage PlanetView wrote for the shader (win_tex's second texel, blue).
static func _stage(P: PlanetView, bi: int) -> int:
	var wt: Array = P._win0 if P._row0[bi] >= 0 else P._win
	return int(round((wt[0] as Image).get_pixel(P._row0[bi] if P._row0[bi] >= 0 else bi, 1).b))

