extends SceneTree
## Stage check (headless): a building is drawn at World's damage stage, read from the state and from nothing else
## (docs/rendering/building-stages.md). The look itself is the shader's and is judged in pictures; this guards what
## the shader is handed. The tool sets hit points and floors on its own fresh match's buildings (its own state; no
## tick runs) and reads back the stage PlanetView wrote for building.gdshader:
## - a house and a tower at 100, 80, 50 and 20% of their hit points are handed stages 0, 1, 2 and 3;
## - hit points put back (a replay seek) hand back stage 0: nothing is remembered;
## - a tower with a cut floor is handed stage 2 at full hit points, and its stage follows its hit points from there
##   though its height does not change;
## - a building that falls with no fall event stands no more at once, and is not placed again on later frames.
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
	print("stage check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


## The stage PlanetView wrote for the shader (win_tex's second texel, blue).
static func _stage(P: PlanetView, bi: int) -> int:
	var wt: Array = P._win0 if P._row0[bi] >= 0 else P._win
	return int(round((wt[0] as Image).get_pixel(P._row0[bi] if P._row0[bi] >= 0 else bi, 1).b))

