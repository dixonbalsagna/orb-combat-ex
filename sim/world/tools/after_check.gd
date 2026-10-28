extends SceneTree
# What a beam leaves in the ground (docs/world/after.md, data/biomes/after.json, off by default): each of Combat's nine aftermath kinds and the ocean's parted sea, staged on a flat gen 2 world and shown applied;
# the switch off and on with nothing laid is the state it was; the same beam twice is the same state.
#   godot --headless --path . --script res://sim/world/tools/after_check.gd
var fails: int = 0
const COL: float = SimConst.COL


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func fid(name: String) -> int:
	var fine: Array = WorldClimate.data().get("fine", [])
	for k in range(fine.size()):
		if String(fine[k].name) == name:
			return k
	return -1


## A flat gen 2 world: the sea on columns 0 to 299 (floor at -300), plains at 30 from there on.
func world() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var nc: int = SimConst.NC
	S.base.fill(30.0)
	for i in range(300):
		S.base[i] = -300.0
	S.deform.fill(0.0)
	S.rubble.fill(0.0)
	S.scorch.fill(0.0)
	S.buildings.clear()
	S.trees.clear()
	S.craters.clear()
	WorldWater.init(S)
	var pc := PackedByteArray()
	pc.resize(nc)
	pc.fill(1)
	var fc := PackedByteArray()
	fc.resize(nc)
	fc.fill(1)
	for i in range(300):
		pc[i] = 0
		fc[i] = 0
	WorldBiomes.planetCols = pc
	WorldBiomes.fineCols = fc
	WorldBiomes.worldId = WorldBiomes.claim()
	S.worldId = WorldBiomes.worldId
	S.fighters[0].x = 40000.0
	S.fighters[1].x = 41000.0
	return S


func region(S: SimState, c0: int, c1: int, fine: int, base: float = NAN) -> void:
	var fc: PackedByteArray = WorldBiomes.fineCols
	for i in range(c0, c1 + 1):
		fc[i] = fine
		if not is_nan(base):
			S.base[i] = base
	WorldBiomes.fineCols = fc


## A beam's groove along columns c0 to c1: scorch samples every four columns, as the beam lays them. Returns [x of the first sample, x of the last].
func groove(S: SimState, c0: int, c1: int, P: float = 2.5) -> Array:
	var c: int = c0
	while c <= c1:
		WorldCrater.scorch(S, (float(c) + 0.5) * COL, P, "FIELD SCAR", null)
		c += 4
	return [(float(c0) + 0.5) * COL, (float(c - 4) + 0.5) * COL]


func stepN(S: SimState, n: int) -> void:
	for t in range(n):
		WorldWater.step(S)


func count(S: SimState, kind: int, c0: int = 0, c1: int = 2399) -> int:
	var n: int = 0
	if S.aftermath.size() != SimConst.NC:
		return 0
	for i in range(c0, c1 + 1):
		if S.aftermath[i] == kind:
			n += 1
	return n


func h(S: SimState) -> String:
	return str(SimHash.stateHash(S).gameplay)


func _init() -> void:
	ok(WorldAfter.dataErrors().is_empty(), "after.json is clean (%s)" % str(WorldAfter.dataErrors()))
	ok(not WorldAfter.on(), "the switch (data/biomes/after.json enabled) is off in the data")
	WorldAfter.K_ON = false
	# --- off: lay does nothing at all
	var S0: SimState = world()
	region(S0, 600, 760, fid("savanna"))
	var p0: Array = groove(S0, 640, 700)
	var h0: String = h(S0)
	var n0: int = WorldAfter.lay(S0, {"kind": "fireLine", "spreadTicks": 15, "durTicks": 240, "reachCols": 12, "hazard": true}, p0[0], p0[1], fid("savanna"))
	ok(n0 == 0 and S0.aftermath.size() == 0 and S0.aftermathJobs.is_empty() and h(S0) == h0, "off: lay() lays nothing, allocates nothing and leaves the state hash as it was")
	# --- on, nothing laid: the same state
	WorldAfter.K_ON = true
	ok(h(S0) == h0, "on, nothing laid: the same hash")
	var Sz := SimCore.createSim()
	SimCore.newMatch(Sz, 1, {}, {"intro": false})
	ok(Sz.aftermath.size() == SimConst.NC and Sz.aftermathT.size() == SimConst.NC and Sz.aftermathJobs.is_empty(), "on: a match's state is sized at its start (hand-made world), and no job runs")
	var vz: Array = SimHash.collect(Sz, "gameplay")
	ok(float(vz[vz.size() - 1]) == 0.0 and float(vz[vz.size() - 2]) == 0.0, "on, nothing set: the hash vector ends in two zeros")
	# --- the same beam twice is the same state; a different kind is a different one
	var ha: String = _fire_hash()
	var hb: String = _fire_hash()
	ok(ha == hb and ha != h0, "the same fire line laid twice is the same state, and not the state without it")
	# --- glaze: the strip reads ice, brakes as ice, and belongs to the biome the beam was in
	var Sg: SimState = world()
	region(Sg, 540, 700, fid("plains"))
	region(Sg, 600, 640, fid("ice_sheet"))
	var pg: Array = groove(Sg, 600, 640)
	var bef: float = WorldContact._brake(Sg, (620.5) * COL)
	var ng: int = WorldAfter.lay(Sg, {"kind": "glaze"}, pg[0], pg[1], fid("ice_sheet"))
	var inside: int = count(Sg, WorldAfter.GLAZE, 540, 700)
	ok(ng > 0 and inside == ng, "glaze: %d scorched columns of the ice sheet are glazed, none beyond (the plains the groove's flank crosses are plain)" % ng)
	var aft: float = WorldContact._brake(Sg, 620.5 * COL)
	ok(WorldContact.lookAt(Sg, 620.5 * COL) == "ice" and WorldContact.surfaceAt(Sg, 620.5 * COL) == "rock" and WorldContact.surfaceAt(Sg, 560.5 * COL) == "soil" and aft > 0.0, "glaze: the strip reads \"ice\" on rock (the plains beside it stay soil) (brake %.2f where it was %.2f)" % [aft, bef])
	# --- clearing: the trees in the strip are felled, the canopy gone for the match, the trunks listable
	var Sc: SimState = world()
	region(Sc, 540, 760, fid("forest"))
	for cc in [560, 600, 620, 640, 720, 750]:
		var tr := SimState.TreeState.new()
		tr.x = (float(cc) + 0.5) * COL
		tr.h = 400.0
		Sc.trees.append(tr)
	var pc2: Array = groove(Sc, 600, 640)
	var nc2: int = WorldAfter.lay(Sc, {"kind": "clearing"}, pc2[0], pc2[1], fid("forest"))
	var felled: int = 0
	for t in Sc.trees:
		if not t.alive:
			felled += 1
	var fh = Sc.fighters[0]
	fh.x = 620.5 * COL
	fh.y = WorldTerrain.groundY(Sc, fh.x) + 20.0
	var trunks: Array = WorldAfter.trunksIn(Sc, pc2[0], pc2[1])
	ok(nc2 > 0 and felled >= 2 and felled == trunks.size() and Sc.trees[0].alive and Sc.trees[5].alive, "clearing: %d trees in the strip are felled and listed as trunks; the trees outside stand" % felled)
	ok(WorldAfter.clearedAt(Sc, 620.5 * COL) and WorldCover.coverAt(Sc, fh) != "canopy", "clearing: a fighter low in the strip finds no canopy (cover there: %s)" % str(WorldCover.coverAt(Sc, fh)))
	# --- heave: the rim of the groove is thrown up
	var Sh: SimState = world()
	region(Sh, 540, 700, fid("tundra"))
	var ph: Array = groove(Sh, 600, 640)
	var rimBefore: float = Sh.deform[(WorldAfter._groove(Sh, ph[0], ph[1], fid("tundra"))[0]) - 1]
	var nh: int = WorldAfter.lay(Sh, {"kind": "heave", "rimMul": 2.0}, ph[0], ph[1], fid("tundra"))
	var g1: PackedInt32Array = WorldAfter._groove(Sh, ph[0], ph[1], fid("tundra"))
	var rimAfter: float = Sh.deform[g1[0] - 1]
	var rise: float = (Sh.deform[g1[0] - 1] - Sh.deform[g1[0]]) / COL
	var rise2: float = (Sh.deform[g1[0] - 2] - Sh.deform[g1[0] - 3]) / COL
	ok(nh > 0 and rimAfter > rimBefore + 1.0 and count(Sh, WorldAfter.PLATES) == 4 and rise > WorldSlide.WALL and rise2 > WorldSlide.WALL, "heave: a step of plates, 2 columns each side, marked PLATES (rim %.1f to %.1f; the rise %.2f in, %.2f out, over the wall rule's %.2f)" % [rimBefore, rimAfter, rise, rise2, WorldSlide.WALL])
	# --- fire line
	var Sf: SimState = world()
	region(Sf, 560, 800, fid("savanna"))
	region(Sf, 800, 860, fid("plains"))
	var pf: Array = groove(Sf, 700, 740)
	var row: Dictionary = {"kind": "fireLine", "spreadTicks": 15, "durTicks": 240, "reachCols": 12, "hazard": true}
	var nf: int = WorldAfter.lay(Sf, row, pf[0], pf[1], fid("savanna"))
	var gf: PackedInt32Array = WorldAfter._groove(Sf, pf[0], pf[1], fid("savanna"))
	var edgeR: int = gf[gf.size() - 1]
	ok(nf > 0 and WorldAfter.hazardAt(Sf, (float(gf[0]) + 0.5) * COL) and WorldAfter.kindAt(Sf, (float(edgeR + 6) + 0.5) * COL) == WorldAfter.NONE, "fire line: the groove burns at once (%d columns, hazard), the grass beyond has not caught" % nf)
	stepN(Sf, 15 * 6)
	var at6: int = WorldAfter.kindAt(Sf, (float(edgeR + 6) + 0.5) * COL)
	var at9: int = WorldAfter.kindAt(Sf, (float(edgeR + 9) + 0.5) * COL)
	ok(at6 == WorldAfter.BURNING and at9 == WorldAfter.NONE, "fire line: after 6 spreads the front is 6 columns out (column +6: %s, +9: %s)" % [WorldAfter.kindName(at6), WorldAfter.kindName(at9)])
	stepN(Sf, 15 * 12 + 240)
	var cb: int = count(Sf, WorldAfter.BURNT)
	ok(count(Sf, WorldAfter.BURNING) == 0 and WorldAfter.jobs(Sf) == 0 and WorldAfter.kindAt(Sf, (float(edgeR + 13) + 0.5) * COL) == WorldAfter.NONE and WorldAfter.lookAt(Sf, (float(edgeR + 6) + 0.5) * COL) == "ash", "fire line: all %d columns burnt out (ash), none past 12 columns, the window closed" % cb)
	var Sf2: SimState = world()
	region(Sf2, 560, 760, fid("savanna"))
	region(Sf2, 722, 780, fid("plains"))   # grass ends where the savanna does
	var pf2: Array = groove(Sf2, 680, 700)
	WorldAfter.lay(Sf2, row, pf2[0], pf2[1], fid("savanna"))
	stepN(Sf2, 15 * 14 + 300)
	ok(count(Sf2, WorldAfter.BURNT, 722, 800) == 0, "fire line: the burn stops at the biome's edge (no column of the next biome burns)")
	# --- ember
	var Se: SimState = world()
	region(Se, 540, 700, fid("volcanic"))
	var pe: Array = groove(Se, 600, 640)
	var ne: int = WorldAfter.lay(Se, {"kind": "ember", "durTicks": 600, "hazard": true}, pe[0], pe[1], fid("volcanic"))
	ok(ne > 0 and WorldAfter.hazardAt(Se, 620.5 * COL) and WorldContact.lookAt(Se, 620.5 * COL) == "crust" and WorldContact.surfaceAt(Se, 620.5 * COL) == "rock", "ember: the groove glows (hazard; Combat's stripLooks: it reads crust, on rock), %d columns" % ne)
	stepN(Se, 590)
	ok(WorldAfter.hazardAt(Se, 620.5 * COL), "ember: still glowing at 590 ticks")
	stepN(Se, 20)
	ok(not WorldAfter.hazardAt(Se, 620.5 * COL) and WorldContact.lookAt(Se, 620.5 * COL) == "crust" and count(Se, WorldAfter.EMBER) == 0 and WorldAfter.jobs(Se) == 0, "ember: after 600 ticks it reads crust, no hazard, the window closed")
	# --- trees on a path, by mode: area (today's), burn, fell, snap, none
	var modes: Dictionary = {}
	for mode in ["area", "burn", "fell", "snap", "none"]:
		var St: SimState = world()
		region(St, 540, 700, fid("forest"))
		for cc in [600, 610]:
			var tr2 := SimState.TreeState.new()
			tr2.x = (float(cc) + 0.5) * COL
			tr2.h = 400.0
			St.trees.append(tr2)
		var far2 := SimState.TreeState.new()
		far2.x = 3000.0 * COL / 2.0
		far2.h = 400.0
		St.trees.append(far2)
		St.out.fx.clear()
		WorldStructures.damageArea(St, 605.5 * COL, WorldTerrain.groundY(St, 605.5 * COL) + 20.0, 600.0, 10.0, St.fighters[0], true, 0.0, -1, 0.0, 1.0, mode)
		var fires: int = 0
		var debris: int = 0
		for e in St.out.fx:
			if e.type == "fire":
				fires += 1
			elif e.type == "debris":
				debris += 1
		modes[mode] = [St.trees[0].alive, St.trees[0].burn, fires, debris, St.trees[2].alive]
	ok(modes["area"] == [false, 0.0, 2, 0, true] and modes["burn"] == [false, 1.0, 2, 0, true] and modes["fell"] == [false, 0.0, 0, 0, true] and modes["snap"] == [false, 0.0, 0, 2, true] and modes["none"] == [true, 0.0, 0, 0, true], "trees on a path: area fells with the fire cue (today's), burn fells and chars (burn 1), fell fells with no fire, snap fells with a crown debris cue each, none leaves them standing; the far tree stands in all (%s)" % str(modes))
	# --- snow dump
	var Ss: SimState = world()
	region(Ss, 540, 700, fid("taiga"))
	var ps: Array = groove(Ss, 600, 640)
	var d0: float = Ss.deform[620]
	var ns: int = WorldAfter.lay(Ss, {"kind": "snowDump", "refill": 0.4, "durTicks": 120}, ps[0], ps[1], fid("taiga"))
	ok(ns > 0 and count(Ss, WorldAfter.SNOW) == ns, "snow dump: %d columns under the powder curtain" % ns)
	stepN(Ss, 130)
	var d1: float = Ss.deform[620]
	ok(absf(d1 - d0 * 0.6) < 0.5 and count(Ss, WorldAfter.SNOW) == 0 and WorldAfter.jobs(Ss) == 0, "snow dump: the groove's depth falls from %.1f to %.1f (40%% refilled), the curtain is gone" % [d0, d1])
	# --- flood: wetland to the water table, beach to the sea
	var Sw: SimState = world()
	region(Sw, 540, 760, fid("wetland"))
	var pw: Array = groove(Sw, 600, 640)
	var nw: int = WorldAfter.lay(Sw, {"kind": "flood", "source": "waterTable"}, pw[0], pw[1], fid("wetland"))
	var wl: float = Sw.base[620] - 6.0
	var surf: float = Sw.base[620] + Sw.deform[620] + Sw.water[620]
	ok(nw > 0 and Sw.water[620] > 0.0 and absf(surf - wl) < 0.01, "flood (wetland): the groove stands at the water table, 6 below the old ground (surface %.2f, table %.2f)" % [surf, wl])
	ok(WorldContact.lookAt(Sw, 620.5 * COL) == "water", "flood: the flooded groove reads \"water\" (Combat's stripLooks)")
	var Sb: SimState = world()
	region(Sb, 300, 560, fid("beach"), -10.0)
	var pb: Array = groove(Sb, 330, 370)
	var nb: int = WorldAfter.lay(Sb, {"kind": "flood", "source": "sea", "seaCols": 30}, pb[0], pb[1], fid("beach"))
	var sb: float = Sb.base[350] + Sb.deform[350] + Sb.water[350]
	ok(nb > 0 and absf(sb) < 0.01, "flood (beach): the groove fills to sea level where the floor is below it (surface %.2f)" % sb)
	var Sb2: SimState = world()
	region(Sb2, 300, 900, fid("beach"), 30.0)
	var pb2: Array = groove(Sb2, 800, 840)
	ok(WorldAfter.lay(Sb2, {"kind": "flood", "source": "sea", "seaCols": 30}, pb2[0], pb2[1], fid("beach")) == 0 or count(Sb2, WorldAfter.FLOODED) == 0, "flood (beach): no open water within 30 columns, or a floor above the sea, and nothing floods")
	# --- scree
	var Sr: SimState = world()
	region(Sr, 540, 760, fid("highland"))
	for i in range(540, 760):
		Sr.base[i] = 30.0 + 20.0 * float(i - 540)
	var pr: Array = groove(Sr, 640, 680)
	var bd: float = Sr.deform[660]
	var nr: int = WorldAfter.lay(Sr, {"kind": "scree", "minSlope": 0.25, "reachCols": 10, "durTicks": 180}, pr[0], pr[1], fid("highland"))
	ok(nr > 0 and WorldAfter.jobs(Sr) >= 1, "scree: %d columns on a slope steeper than 0.25 run rubble (%d windows)" % [nr, WorldAfter.jobs(Sr)])
	stepN(Sr, 200)
	var rubCols: int = 0
	for i in range(600, 720):
		if Sr.rubble[i] >= WorldContact.K_RUBBLE_MIN:
			rubCols += 1
	ok(rubCols >= 10 and WorldAfter.jobs(Sr) == 0 and count(Sr, WorldAfter.SCREE) >= rubCols, "scree: %d columns carry a rubble heap of at least rubbleMin, the run is over" % rubCols)
	var someRub: int = -1
	for i in range(600, 720):
		if Sr.rubble[i] >= WorldContact.K_RUBBLE_MIN:
			someRub = i
			break
	ok(someRub >= 0 and WorldContact.surfaceAt(Sr, (float(someRub) + 0.5) * COL) == "rubble", "scree: contact reads the strip as surface \"rubble\" (a slide over it tumbles)")
	var Sq: SimState = world()
	for i in range(540, 546):
		Sq.base[i] = 500.0 - 20.0 * float(i - 540)
	for i in range(546, 600):
		Sq.base[i] = 400.0
	ok(WorldAfter._runLimit(Sq, 540, 1, 0.25, 10) == 5 and WorldAfter._runLimit(Sq, 540, 1, 0.25, 3) == 3, "scree: the run stops where the slope flattens below minSlope (5 columns here), and never past reachCols (%d)" % WorldAfter._runLimit(Sq, 540, 1, 0.25, 10))
	# --- split
	var Si: SimState = world()
	region(Si, 300, 900, fid("ocean"))
	for i in range(300, 900):
		Si.base[i] = -300.0
	region(Si, 600, 700, fid("sea_ice"), 100.0)   # a floe the groove does not cut through
	WorldWater.init(Si)
	var pi: Array = groove(Si, 630, 670, 1.0)
	var ni: int = WorldAfter.lay(Si, {"kind": "split", "gapBh": 1.0}, pi[0], pi[1], fid("sea_ice"))
	var slot: int = count(Si, WorldAfter.SPLIT)
	var wet: bool = true
	for i in range(2400):
		if Si.aftermath[i] == WorldAfter.SPLIT and (Si.water[i] < WorldWater.MIN_DEPTH or Si.base[i] + Si.deform[i] >= 0.0):
			wet = false
	ok(ni > 0 and slot == 2 and wet, "split: the floe breaks at the path into two plates with a %d-column slot (1 bh), cut below the sea and filled with water" % slot)
	var Sd: SimState = world()
	region(Sd, 300, 900, fid("ocean"))
	for i in range(300, 900):
		Sd.base[i] = -300.0
	region(Sd, 600, 700, fid("sea_ice"), 100.0)
	WorldWater.init(Sd)
	var pd: Array = groove(Sd, 630, 670, 1.0)
	WorldAfter.lay(Sd, {"kind": "split", "gapBh": 1.0}, pd[0], pd[1], fid("sea_ice"), 0.0, 662.5 * COL)
	ok(Sd.aftermath[661] == WorldAfter.SPLIT or Sd.aftermath[662] == WorldAfter.SPLIT, "split: the floe the defender stands on breaks at his column (662), not at its middle")
	# --- part: the sea opens for 90 ticks, the wave pushes what is at the surface 2 bh along the beam, the shore runs wet, then it settles
	var Sp: SimState = world()
	var pp: Array = groove(Sp, 200, 240, 1.0)   # open sea, far from any shore
	var np: int = WorldAfter.lay(Sp, {"kind": "part", "openTicks": 90, "pushBh": 2.0, "shoreCols": 40}, pp[0], pp[1], 0)
	Sp.fighters[0].x = 220.5 * COL
	Sp.fighters[0].y = 0.0
	Sp.fighters[1].x = 220.5 * COL
	Sp.fighters[1].y = 400.0   # in the air: not at the surface
	var fx0: float = Sp.fighters[0].x
	var fx1: float = Sp.fighters[1].x
	ok(np > 0 and count(Sp, WorldAfter.OPEN) > 0 and WorldAfter.jobs(Sp) == 1, "part: the sea parts along the path (%d columns held open, one window)" % count(Sp, WorldAfter.OPEN))
	stepN(Sp, 60)
	var dry: int = 0
	for i in range(200, 240):
		if Sp.water[i] < WorldWater.MIN_DEPTH:
			dry += 1
	ok(dry >= 30, "part: at 60 ticks %d columns of the path stand dry, walled by water" % dry)
	var waves: int = 0
	for t in range(70):
		WorldWater.step(Sp)
		for e in Sp.out.fx:
			if e.type == "water_wave":
				waves += 1
		Sp.out.fx.clear()
	var back: int = 0
	for i in range(200, 240):
		if Sp.water[i] >= WorldWater.MIN_DEPTH:
			back += 1
	var pushed: float = Sp.fighters[0].x - fx0
	ok(waves == 1 and back >= 30 and pushed > 120.0 and pushed < 160.0 and absf(Sp.fighters[1].x - fx1) < 0.01, "part: the sea rushes back (one water_wave cue), the fighter at the surface is pushed %.0f along the beam (2 bh is 150), the one in the air is not" % pushed)
	stepN(Sp, 400)
	ok(WorldAfter.jobs(Sp) == 0 and count(Sp, WorldAfter.WET) == 0 and count(Sp, WorldAfter.OPEN) == 0, "part: the shore dried and the window closed")
	var Sp2: SimState = world()
	var pp2: Array = groove(Sp2, 250, 270, 1.0)   # the trench ends 16 columns from the shore (column 300)
	WorldAfter.lay(Sp2, {"kind": "part", "openTicks": 90, "pushBh": 2.0, "shoreCols": 40}, pp2[0], pp2[1], 0)
	stepN(Sp2, 140)
	ok(count(Sp2, WorldAfter.WET) > 0, "part: the wave ran up the shore (%d wet columns on the land within 40 columns)" % count(Sp2, WorldAfter.WET))
	# --- a match with the switch on and nothing laid plays as it did: the same vector, two zeros longer (the director does not call lay in this tree)
	WorldAfter.K_ON = false
	var off: Array = _play(1, 900)
	WorldAfter.K_ON = true
	var on: Array = _play(1, 900)
	WorldAfter.K_ON = false
	var same: bool = on.size() == off.size() + 2 and float(on[on.size() - 1]) == 0.0 and float(on[on.size() - 2]) == 0.0
	for k in range(off.size()):
		same = same and off[k] == on[k]
	ok(same, "a 900-tick match with the switch on and nothing laid is the match with it off: the same hash vector, and two zeros more")
	print("AFTER: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)


func _fire_hash() -> String:
	var S: SimState = world()
	region(S, 560, 800, fid("savanna"))
	var p: Array = groove(S, 640, 700)
	WorldAfter.lay(S, {"kind": "fireLine", "spreadTicks": 15, "durTicks": 240, "reachCols": 12, "hazard": true}, p[0], p[1], fid("savanna"))
	stepN(S, 200)
	return h(S)


func _play(seed: int, ticks: int) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false})
	for t in range(ticks):
		SimCore.step(S)
		S.out.fx.clear()
	return SimHash.collect(S, "gameplay")
