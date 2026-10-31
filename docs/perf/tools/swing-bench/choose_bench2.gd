extends SceneTree
## Scratch (Performance, 2026-10-31): the AI match run to the tick of a launch hitch, then DirLaunch.chooseLaunch called directly on the line as it is (turned by the swings so far) and on the match's first line (S.frame0).
## Needs hook-11, 12 and 13 and, for the "field reads" and "new lattice nodes" lines, counters added by hand to sim/core/field.gd (n_col, us_col, n_nativeDepth, ng ... as in the scratch tree); delete those print lines to run without them.
var planet: int = 7
var ticks: int = 3100


func call_(S: SimState, label: String) -> void:
	var A = S.fighters[0]
	var D = S.fighters[1]
	for rep in range(3):
		DirSwing.pm.clear()
		SimField.ng = 0
		SimField.n_col = 0
		SimField.us_col = 0
		SimField.n_nativeDepth = 0
		SimField.us_nativeDepth = 0
		SimField.n_atDepth = 0
		SimField.us_atDepth = 0
		SimField.nb = 0
		SimField.nfine = 0
		SimField.nbus = 0
		SimField.nbx.clear()
		SimField.ngus = 0
		SimField.ngf = 0
		var r0: int = SimField._F.reads
		var s0: int = SimField._F.subReads
		var t0: int = Time.get_ticks_usec()
		DirLaunch.chooseLaunch(S, A, D, 1600.0, false, "", 0, false)
		var dt: int = Time.get_ticks_usec() - t0
		print("   biome parts: cliff %d, ice+marsh %d, tree line %d, skim %d, downhill %d" % [DirSwing.pm.get("B_cliff", 0), DirSwing.pm.get("B_ice_marsh", 0), DirSwing.pm.get("B_tree", 0), DirSwing.pm.get("B_skim", 0), DirSwing.pm.get("B_downhill", 0)])
		print("   props: near %d, vent %d, targets %d (%d props), flight %d" % [DirSwing.pm.get("B_propsNear", 0), DirSwing.pm.get("B_vent", 0), DirSwing.pm.get("B_propTargets", 0), DirSwing.pm.get("nProps", 0), DirSwing.pm.get("B_propFlight", 0)])
		print("   field reads: col %d (%d us), nativeDepth %d (%d us), atDepth %d (%d us)" % [SimField.n_col, SimField.us_col, SimField.n_nativeDepth, SimField.us_nativeDepth, SimField.n_atDepth, SimField.us_atDepth])
		print("%-22s call %d: %6d us, new lattice nodes %d, new sub-nodes %d, ground reads %d (%d on the bake) in %d us; biome reads %d + fine %d (%d distinct x) in %d us | biomeCands+mount %6d, brunt %6d, predict %6d (%d), score loop %d" % [label, rep + 1, dt, SimField._F.reads - r0, SimField._F.subReads - s0, SimField.ng, SimField.ngf, SimField.ngus, SimField.nb, SimField.nfine, SimField.nbx.size(), SimField.nbus, DirSwing.pm.get("L4_biome", 0), DirSwing.pm.get("L2_brunt", 0), DirSwing.pm.get("predict", 0), DirSwing.pm.get("predictN", 0), DirSwing.pm.get("L5_score", 0)])


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": true, "p2": true}, {"planet": planet, "touch": 1, "planetGen": 3, "intro": false})
	if SimField._F != null:
		WorldField.bakeStep(SimField._F, 1 << 40)
	print("after newMatch: bake done %s, nodes read %d" % [str(SimField._F.bakeDone), SimField._F.reads])
	for t in range(ticks):
		SimCore.step(S)
		S.out.fx.clear(); S.out.feed.clear()
	print("at tick %d: bake done %s, nodes read %d" % [ticks, str(SimField._F.bakeDone), SimField._F.reads])
	var A = S.fighters[0]
	var D = S.fighters[1]
	print("tick %d: A.x %.0f D.x %.0f D.y %.0f, swings so far %d, biome %s" % [S.tick, A.x, D.x, D.y, S.swing.n, WorldBiomes.biomeAt(D.x)])
	call_(S, "line as it is")
	var keep = S.frame
	S.frame = S.frame0.copy()
	print("first line: biome %s" % WorldBiomes.biomeAt(D.x))
	call_(S, "the first line")
	S.frame = keep
	quit(0)
