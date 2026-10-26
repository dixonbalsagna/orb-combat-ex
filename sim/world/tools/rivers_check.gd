extends SceneTree
# Planet generation 2's rivers (docs/world/rivers.md; WorldRivers, data/biomes/rivers.json): the flow field on the climate grid, a ring's crossings snapped to its valley and cut and planted as narrow shallow
# lakes, Game Design's row 13 spacing, never deep enough to hide in, nothing changed with the switch off.
#   godot --headless --path . --script res://sim/world/tools/rivers_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func setup(sd: int, touch: int, turn: bool = false) -> Dictionary:
	var arena: Dictionary = {"cols": 2400}
	if turn:
		arena["turn"] = true
	return {"planet": sd, "touch": touch, "arena": arena, "planetGen": 2, "intro": false}


func fresh(setup_: Dictionary) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, setup_)
	S.out.fx.clear()
	return S


## The river entries of a state's ring: the lake entries with a flow (a fifth element).
func riversOf(S: SimState) -> Array:
	var out: Array = []
	for lk in S.planetRing.get("lakes", []):
		if lk.size() > 4:
			out.append(lk)
	return out


func _init() -> void:
	ok(WorldRivers.dataErrors().is_empty(), "rivers.json is clean (%s)" % str(WorldRivers.dataErrors()))
	ok(not WorldRivers.enabled(), "rivers.json ships with the rivers off")
	ok(WorldRivers.depthOf(1.0e9) == WorldRivers.K_DMAX and WorldRivers.K_DMAX < WorldWater.HIDE_MIN_DEPTH, "the deepest river (%.0f units) is under the depth that hides a fighter (%.0f): a river is always waded" % [WorldRivers.K_DMAX, WorldWater.HIDE_MIN_DEPTH])
	WorldClimate.useGen(1)
	ok(WorldRivers.flowOf(WorldPlanet.make(7)) == null, "a gen 1 planet has no flow field")
	WorldClimate.useGen(2)
	# the flow field
	var drains: bool = true
	var mono: bool = true
	var det: bool = true
	var frac: Array = []
	var t0: int = Time.get_ticks_usec()
	for sd in [7, 3, 11, 25]:
		var P := WorldPlanet.make(sd)
		var G: WorldClimate.Grid = WorldClimate.gridOf(P)
		var tb: int = Time.get_ticks_usec()
		var F: WorldRivers.Flow = WorldRivers.flowOf(P)
		var tf: float = float(Time.get_ticks_usec() - tb) / 1000.0
		var n: int = F.w * F.h
		for i in range(n):
			if G.ht[i] < 0.0:
				continue
			var cur: int = i
			var steps: int = 0
			while cur >= 0 and G.ht[cur] >= 0.0 and steps < n:
				var rc: int = F.recv[cur]
				if rc >= 0 and F.flow[rc] + 1.0e-4 < F.flow[cur] and G.ht[rc] >= 0.0:
					mono = false
				cur = rc
				steps += 1
			if cur < 0 or G.ht[cur] >= 0.0:
				drains = false   # a land cell that never reaches the sea
		var F2 := WorldRivers.Flow.new(G)
		if F2.recv != F.recv or F2.flow != F.flow:
			det = false
		frac.append("%.1f%%" % (100.0 * float(F.rivers) / float(maxi(F.landCells, 1))))
		print("    planet %d: flow field %.0f ms, %d river cells of %d land cells" % [sd, tf, F.rivers, F.landCells])
	ok(drains, "every land cell's runoff reaches the sea (no dead end, no loop)")
	ok(mono, "the flow never falls downstream")
	ok(det, "the flow field is the same twice")
	print("    river cells of the land: %s" % str(frac))
	# a ring's rivers
	WorldRivers.setOn(true)
	var spansOk: bool = true
	var gapOk: bool = true
	var depthOk: bool = true
	var rings: int = 0
	var withRivers: int = 0
	var most: int = 0
	var tp: int = Time.get_ticks_usec()
	var gap: int = int(ceil(WorldRivers.K_GAP / SimConst.COL))
	for sd in [7, 3, 11, 25]:
		var P := WorldPlanet.make(sd)
		for touch in [0, 4, 8]:
			var S := fresh(setup(sd, touch))
			rings += 1
			var rv: Array = riversOf(S)
			if not rv.is_empty():
				withRivers += 1
			most = maxi(most, rv.size())
			var n: int = SimConst.NC
			for a in range(rv.size()):
				var e: Array = rv[a]
				if int(e[3]) < WorldRivers.K_MIN_COLS or int(e[3]) > WorldRivers.K_MAX_COLS or float(e[4]) <= 0.0:
					spansOk = false
				for b in range(a + 1, rv.size()):
					var d: int = absi(posmod(int(e[0]) + int(e[3]) / 2 - int(rv[b][0]) - int(rv[b][3]) / 2 + n / 2, n) - n / 2)
					if d < gap:
						gapOk = false
				# the bed: water to the flat level, never deeper than the data's deepest
				var deepest: float = 0.0
				for k in range(int(e[3])):
					var c: int = (int(e[0]) + k) % n
					deepest = maxf(deepest, S.water[c])
					if S.water[c] > 0.0 and absf(S.base[c] + S.water[c] - float(e[2])) > 0.01:
						spansOk = false
				if deepest > WorldRivers.K_DMAX + 0.01 or deepest <= 0.0:
					depthOk = false
	var perRing: float = float(Time.get_ticks_usec() - tp) / 1000.0 / float(rings)
	ok(rings == 12 and withRivers >= 4, "%d of %d rings (4 planets, 3 touch-downs) have a river in them (at most %d on one); a match starts in %.0f ms with them" % [withRivers, rings, most, perRing])
	ok(spansOk, "each river's water lies flat at its level in a channel of the data's width")
	ok(depthOk, "no river is deeper than %.0f units, and each holds water" % WorldRivers.K_DMAX)
	ok(gapOk, "at most one river in any %.0f units of the ring (Game Design 23b row 13: the strongest of a comb of crossings)" % WorldRivers.K_GAP)
	# a match with a river: no hiding, no trees in it, the same twice, and the switch off is the plain match
	var pick = null
	for sd in [7, 3, 11, 25]:
		for touch in range(0, 12):
			if pick == null and not riversOf(fresh(setup(sd, touch))).is_empty():
				pick = [sd, touch]
	ok(pick != null, "found a ring with a river to look at (planet %s, touch %s)" % [str(pick[0]) if pick != null else "-", str(pick[1]) if pick != null else "-"])
	if pick != null:
		var S1 := fresh(setup(pick[0], pick[1]))
		var S2 := fresh(setup(pick[0], pick[1]))
		var e0: Array = riversOf(S1)[0]
		var mid: float = (float(e0[0]) + float(e0[3]) * 0.5) * SimConst.COL
		ok(WorldWater.seaTop(S1, mid) == WorldWater.NO_SEA and not WorldTerrain.seaAt(S1, mid), "a river is not sea: a fighter in it is not below a surface that hides him (seaTop is none)")
		var treesIn: int = 0
		for t in S1.trees:
			var tc: int = int(floor(SimWrap.wrap(t.x) / SimConst.COL)) % SimConst.NC
			if posmod(tc - int(e0[0]), SimConst.NC) < int(e0[3]):
				treesIn += 1
		ok(treesIn == 0, "no tree grows in the river")
		ok(str(SimHash.stateHash(S1).gameplay) == str(SimHash.stateHash(S2).gameplay), "a match with a river is the same twice")
		WorldRivers.setOn(false)
		var off := fresh(setup(pick[0], pick[1]))
		var plain := fresh(setup(pick[0], pick[1]))
		ok(str(SimHash.stateHash(off).gameplay) == str(SimHash.stateHash(plain).gameplay) and str(SimHash.stateHash(off).gameplay) != str(SimHash.stateHash(S1).gameplay) and riversOf(off).is_empty(), "with the switch off there is no river and the match is the plain one; with it on the ground is different")
		WorldRivers.setOn(true)
		# a hole dug beside the river fills from it (water v2's rule: water already standing is a source), and the river's own bed stays level when dug
		var c0: int = int(e0[0]) + int(e0[3]) / 2
		for k in range(-6, 7):
			S1.deform[(c0 + k + SimConst.NC) % SimConst.NC] -= 50.0
		WorldWater.touched(S1, c0, 10, S1.base[c0] + S1.deform[c0])
		var flat: bool = true
		for k in range(int(e0[3])):
			var c: int = (int(e0[0]) + k) % SimConst.NC
			if S1.water[c] > 0.0 and absf(S1.base[c] + WorldTerrain.lowD(S1)[c] + S1.water[c] - float(e0[2])) > 0.5:
				flat = false
		ok(flat, "a crater dug in the river's bed leaves its surface flat (the lakes' refill rule)")
	# the calm turn plants the new ring's rivers where it is wholly new, and keeps the kept core's
	var St := SimCore.createSim()
	SimCore.newMatch(St, 1, {}, setup(7, 4, true))
	for t in range(30):
		SimCore.step(St)
	St.T = 100.0
	var px: float = 0.5 * (St.fighters[0].x + St.fighters[1].x)
	var cands: Array = WorldEpoch.ask(St, "test", px, 1, 0)
	var turnOk: bool = not cands.is_empty()
	if turnOk:
		WorldEpoch.choose(St, cands.size() - 1, 100000, 0.0)
		var g: int = 0
		while WorldEpoch.warmAngles(St).size() < St.epoch.warm.size() and g < 200:
			WorldEpoch.tick(St, false)
			g += 1
		g = 0
		while St.epoch.next != null and g < 40:
			WorldEpoch.tick(St, true)
			g += 1
		turnOk = St.epoch.next == null
	var flatT: bool = true
	var nT: int = SimConst.NC
	for lk in St.planetRing.get("lakes", []):
		for k in range(int(lk[3])):
			var c: int = (int(lk[0]) + k) % nT
			if St.water[c] > 0.0 and absf(St.base[c] + WorldTerrain.lowD(St)[c] + St.water[c] - float(lk[2])) > 0.5:
				flatT = false
	ok(turnOk and flatT, "after a calm turn every lake and river of the ring (%d river(s)) lies flat at its level" % riversOf(St).size())
	# the far land's layer (render-only): the river cells' own texels are marked, the sizes are 1 to 3, none with the switch off, the same twice
	WorldRivers.setOn(false)
	var P7 := WorldPlanet.make(7)
	var off := WorldFarMap.new(P7, 128)
	var offMarks: int = 0
	for v in off.rivers:
		offMarks += int(v)
	WorldRivers.setOn(true)
	var FM := WorldFarMap.new(P7, 128)
	var FM2 := WorldFarMap.new(P7, 128)
	var F7: WorldRivers.Flow = WorldRivers.flowOf(P7)
	var marked: int = 0
	var classOk: bool = true
	for v in FM.rivers:
		if int(v) > 0:
			marked += 1
		if int(v) > 3:
			classOk = false
	var hit: int = 0
	var cells: int = 0
	for i in range(F7.w * F7.h):
		if P7.grid.ht[i] >= 0.0 and F7.flow[i] >= WorldRivers.K_RIVER and F7.recv[i] >= 0:
			cells += 1
			if FM.river(F7.px[i], F7.py[i], F7.pz[i]) > 0:
				hit += 1
	ok(offMarks == 0 and marked > cells and hit == cells and classOk and FM.rivers == FM2.rivers, "the far map's river layer: nothing with the rivers off; on, %d texels marked for %d river cells, every river cell's own texel among them, sizes 1 to 3, the same twice" % [marked, cells])
	WorldRivers.setOn(false)
	print("RIVERS: %d check(s) failed" % fails)
	quit()
