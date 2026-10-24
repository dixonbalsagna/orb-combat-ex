extends SceneTree
# Planet generation 2, window 2: the ground profiles (WorldGround, data/biomes/ground.json), trees, cover, props, and the turn carrying them. Generation 1 is proved bit for bit against
# match hashes recorded before this window (base_hash.gd, on HEAD plus window 1).
#   godot --headless --path . --script res://sim/world/tools/ground_check.gd
var fails: int = 0

# gen 1 gameplay hashes at the given ticks, recorded before window 2 (base_hash.gd)
const BASE: Dictionary = {
	"planet7/2400": "9c7181701205ae71",
	"planet3/1200": "cb3ca643cea700b8",
	"planet25/4800": "754246e9ace48ce5",
	"planet11/2400": "2198f110e8d41b12",
	"handmade": "597d3daf6d12ba62",
	"turn": "n=1 4882e3577ea0c491",
}


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func run(setup: Dictionary, ticks: int) -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, setup)
	for t in range(ticks):
		SimCore.step(S)
	return str(SimHash.stateHash(S).gameplay)


func turn_match(extra: Dictionary) -> SimState:
	var Se := SimCore.createSim()
	var setup: Dictionary = {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}, "intro": false}
	setup.merge(extra)
	SimCore.newMatch(Se, 1, {}, setup)
	for t in range(30):
		SimCore.step(Se)
	Se.T = 100.0
	var mid: float = 0.5 * (Se.fighters[0].x + Se.fighters[1].x)
	if not WorldEpoch.ask(Se, "t", mid, 1, 0).is_empty():
		WorldEpoch.choose(Se, 3)
		Se.epoch.next.k = 100000
		var warmG: int = 0
		while WorldEpoch.warmAngles(Se).size() < Se.epoch.warm.size() and warmG < 100:
			WorldEpoch.tick(Se, false)
			warmG += 1
		WorldEpoch.tick(Se, true)
	for t in range(60):
		SimCore.step(Se)
	return Se


## Every tree stands on dry, treed ground of the current fine biomes (the invariant a turn must keep).
func trees_on_treed_ground(S: SimState) -> bool:
	var fc: PackedByteArray = WorldBiomes.fineCols
	var pc: PackedByteArray = WorldBiomes.planetCols
	var NC: int = SimConst.NC
	for t in S.trees:
		var col: int = int(floor(SimWrap.wrap(t.x) / SimConst.COL)) % NC
		var g: Dictionary = WorldGround.data().grounds[int(fc[col])]
		if g.trees == null or int(pc[col]) >= 7:
			return false
		if t.h < float(g.trees.h[0]) * SimConst.WS - 0.01 or t.h > float(g.trees.h[1]) * SimConst.WS + 0.01:
			return false
	return true


func _init() -> void:
	# --- the data
	var errs: Array = WorldGround.dataErrors()
	var fine: Array = WorldClimate.data().fine
	var g: Array = WorldGround.data().grounds
	ok(errs.is_empty() and g.size() == fine.size() and g.size() >= 15, "ground.json is clean and has a profile for each of the %d fine biomes (%s)" % [fine.size(), str(errs)])
	var gentle: bool = true
	var named: Array = []
	for k in range(g.size()):
		if g[k].name != fine[k].name:
			gentle = false
		if g[k].surface != WorldContact.data().biomeSurface.get(WorldBiomes_alias_name(k), g[k].surface) and k < 5:
			gentle = false   # the stored biomes keep the surface contact.json gives them (ice sheet and sea ice are the gen 2 exceptions: ice is rock)
		named.append("%s %.2f/%.2f/%.2f/%.2f" % [g[k].name, g[k].grip, g[k].absorb, g[k].rough, g[k].furrow])
	ok(gentle, "the profiles follow climate.json's order; plains, forest, desert and mountains keep their old surfaces; grip/absorb/rough/furrow: %s" % ", ".join(named))

	# --- generation 1 is bit for bit what it was (the same hashes as before this window)
	var h7: String = run({"planet": 7, "touch": 3, "arena": {"cols": 2400}, "intro": false}, 180)
	var h3: String = run({"planet": 3, "touch": 5, "arena": {"cols": 1200}, "intro": false}, 180)
	var h25: String = run({"planet": 25, "touch": 2, "arena": {"cols": 4800}, "intro": false}, 120)
	var h11: String = run({"planet": 11, "touch": 9, "arena": {"cols": 2400}, "intro": false}, 180)
	var hh: String = run({"intro": false}, 180)
	var Ht := turn_match({})
	var ht: String = "n=%d %s" % [int(Ht.epoch.n), str(SimHash.stateHash(Ht).gameplay)]
	ok(h7 == BASE["planet7/2400"] and h3 == BASE["planet3/1200"] and h25 == BASE["planet25/4800"] and h11 == BASE["planet11/2400"], "gen 1 planet matches (seeds 7, 3, 25, 11; rings of 2400, 1200, 4800, 2400) hash as they did before window 2")
	ok(hh == BASE["handmade"] and ht == BASE["turn"], "the hand-made world and a gen 1 turn hash as before (turn: %s)" % ht)
	ok(WorldBiomes.fineCols.size() == 0 and Ht.trees.size() == 0 and not WorldGround.live(), "a gen 1 planet has no fine columns and no trees, as before")

	# --- a gen 2 planet match: fine columns, trees, the profile in the surface
	var t0: int = Time.get_ticks_usec()
	var S2: SimState = null
	var pick: int = -1
	for touch in range(0, 16):
		var Sx := SimCore.createSim()
		SimCore.newMatch(Sx, 1, {}, {"planet": 7, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
		if Sx.trees.size() >= 25 and S2 == null:
			S2 = Sx
			pick = touch
			break
	var build_ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
	ok(S2 != null, "a gen 2 planet match (seed 7, touch %d, 2400 columns) grows trees (%d) and was built in %.0f ms with the tries before it" % [pick, S2.trees.size() if S2 != null else 0, build_ms])
	if S2 == null:
		print("GROUND: %d check(s) failed" % fails)
		quit()
		return
	var NC: int = SimConst.NC
	var fc: PackedByteArray = WorldBiomes.fineCols
	var pc: PackedByteArray = WorldBiomes.planetCols
	var aliasOk: bool = fc.size() == NC and pc.size() == NC and WorldGround.live()
	var kinds: Dictionary = {}
	for i in range(NC):
		if aliasOk and int(pc[i]) < 7 and int(pc[i]) != WorldClimate.aliasOf(int(fc[i])):
			aliasOk = false
		kinds[int(fc[i])] = true
	ok(aliasOk, "the stored columns are the fine ones' aliases (a town's or a city's ground aside); %d fine biomes on this ring" % kinds.size())
	ok(trees_on_treed_ground(S2), "every tree stands on dry, treed ground of its column's fine biome, at a height inside that biome's range")
	var hashA: String = str(SimHash.stateHash(S2).gameplay)
	var S2b := SimCore.createSim()
	SimCore.newMatch(S2b, 1, {}, {"planet": 7, "touch": pick, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	ok(hashA == str(SimHash.stateHash(S2b).gameplay) and S2.trees.size() == S2b.trees.size(), "a gen 2 match is a pure function of its setup (the same hash and trees twice)")
	for t in range(240):
		SimCore.step(S2)
		SimCore.step(S2b)
	ok(str(SimHash.stateHash(S2).gameplay) == str(SimHash.stateHash(S2b).gameplay), "...and two gen 2 matches stay the same for 240 ticks")

	# the surface classes follow the profile
	var surfOk: bool = true
	var bad: String = ""
	WorldContact.surfaceAt(S2, 0.0)
	for i in range(0, NC, 3):
		if int(pc[i]) >= 7:
			continue
		var want: String = String(g[int(fc[i])].surface)
		var got: String = WorldContact.surfaceAt(S2, (float(i) + 0.5) * SimConst.COL)
		if got != want and got != "rubble":
			surfOk = false
			bad = "col %d fine %s wants %s got %s" % [i, g[int(fc[i])].name, want, got]
			break
	ok(surfOk, "contact's surface on natural ground is the fine biome's profile surface %s" % bad)

	# --- synthetic ground: one block of each fine biome, to read the multipliers out of contact and cover
	var Sy := SimCore.createSim()
	SimCore.newMatch(Sy, 1, {}, {"intro": false})   # the hand-made world, then its biome columns are replaced below
	var NCy: int = SimConst.NC   # the hand-made world's 4,800 (the ring above had 2,400)
	var pcs := PackedByteArray()
	pcs.resize(NCy)
	pcs.fill(1)
	var fcs := PackedByteArray()
	fcs.resize(NCy)
	for i in range(NCy):
		fcs[i] = (i / 100) % 15   # a hundred columns of each fine biome in turn
	WorldBiomes.planetCols = pcs
	WorldBiomes.fineCols = fcs
	WorldBiomes.worldId = WorldBiomes.claim()
	Sy.worldId = WorldBiomes.worldId
	Sy.planetCols = pcs
	var D: Dictionary = WorldContact.data()
	var braked: bool = true
	var seen: Array = []
	for k in range(15):
		var x: float = (float(k * 100 + 50) + 0.5) * SimConst.COL
		var surf: String = WorldContact.surfaceAt(Sy, x)
		var want2: float = float(D.surfaces[String(g[k].surface)].brake) * float(g[k].grip) * float(g[k].rough)
		var got2: float = WorldContact._brake(Sy, x)
		if absf(want2 - got2) > 1.0e-9 or surf != String(g[k].surface):
			braked = false
			seen.append("%s: %s %.3f vs %.3f" % [g[k].name, surf, got2, want2])
	ok(braked, "the brake on each fine biome is the surface's own times the profile's grip and rough (wetland %.2f, ice sheet %.2f, plains %.2f)%s" % [WorldContact._brake(Sy, (11.0 * 100.0 + 50.5) * SimConst.COL), WorldContact._brake(Sy, (5.0 * 100.0 + 50.5) * SimConst.COL), WorldContact._brake(Sy, (1.0 * 100.0 + 50.5) * SimConst.COL), " " + str(seen) if not seen.is_empty() else ""])
	var pfOk: bool = true
	for k in range(15):
		var xk: float = (float(k * 100 + 50) + 0.5) * SimConst.COL
		if absf(WorldContact._pf(WorldContact._gAbs, xk) - float(g[k].absorb)) > 1.0e-9 or absf(WorldContact._pf(WorldContact._gRough, xk) - float(g[k].rough)) > 1.0e-9 or absf(WorldContact._pf(WorldContact._gFur, xk) - float(g[k].furrow)) > 1.0e-9:
			pfOk = false
	ok(pfOk, "the bounce's keep, the tumble band and the trench read each fine biome's absorb, rough and furrow")
	# a town keeps contact's own rule and a multiplier of 1
	pcs[1150] = 8
	WorldBiomes.planetCols = pcs
	WorldBiomes.worldId = WorldBiomes.claim()
	Sy.worldId = WorldBiomes.worldId
	ok(WorldContact.surfaceAt(Sy, 1150.5 * SimConst.COL) in ["paving", "soil"] and absf(WorldContact._pf(WorldContact._gFur, 1150.5 * SimConst.COL) - 1.0) < 1.0e-12, "a city column keeps the old rule and a multiplier of 1")

	# the look class and the fine name, read per column
	var looksOk: bool = true
	var namesOk: bool = true
	for k in range(15):
		var xl: float = (float(k * 100 + 20) + 0.5) * SimConst.COL
		if WorldContact.lookAt(Sy, xl) != String(g[k].look):
			looksOk = false
		if WorldBiomes.fineNameAt(xl) != String(g[k].name):
			namesOk = false
	var settled: float = 1150.5 * SimConst.COL
	var lk: String = ""
	for k in [5, 11, 7, 14, 12]:
		lk += "%s %s, " % [g[k].name, WorldContact.lookAt(Sy, (float(k * 100 + 20) + 0.5) * SimConst.COL)]
	ok(looksOk and WorldContact.lookAt(Sy, settled) in ["paving", "soil"], "WorldContact.lookAt gives each fine biome's look class (%sa city column its paving)" % lk)
	ok(namesOk and WorldBiomes.fineNameAt(settled) == "city", "WorldBiomes.fineNameAt gives the fine name of a column (a city column reads city: the stored 8 is not the fine 8, savanna)")
	# rough ground never lengthens a skid (Game Design, rulings 2026-10-23b item 11): the same launch with rough set to 1 runs at least as far
	var roughOk: bool = true
	var roughNote: String = ""
	var Sr := SimCore.createSim()
	SimCore.newMatch(Sr, 1, {}, {"intro": false})
	Sr.base.fill(120.0)
	Sr.deform.fill(0.0)
	Sr.rubble.fill(0.0)
	Sr.buildings.clear()
	Sr.trees.clear()
	WorldWater.init(Sr)
	var oneP := PackedByteArray()
	oneP.resize(SimConst.NC)
	oneP.fill(1)
	WorldBiomes.planetCols = oneP
	for k in range(15):
		var onek := PackedByteArray()
		onek.resize(SimConst.NC)
		onek.fill(k)
		WorldBiomes.fineCols = onek
		WorldBiomes.worldId = WorldBiomes.claim()
		Sr.worldId = WorldBiomes.worldId
		var x0r: float = 2400.0 * SimConst.COL
		var jr: Dictionary = WorldContact.journey(Sr, WorldContact.launchBody(x0r, 400.0, 3000.0, -800.0, 1.0, 2.0))
		var keepR: PackedFloat64Array = WorldContact._gRough
		var flat := PackedFloat64Array()
		flat.resize(keepR.size())
		flat.fill(1.0)
		WorldContact._gRough = flat
		var jf: Dictionary = WorldContact.journey(Sr, WorldContact.launchBody(x0r, 400.0, 3000.0, -800.0, 1.0, 2.0))
		WorldContact._gRough = keepR
		if float(jr.dist) > float(jf.dist) + 1.0e-6:
			roughOk = false
			roughNote += " %s %.0f vs %.0f" % [g[k].name, float(jr.dist), float(jf.dist)]
		if k == 7:
			roughNote += " (jungle runs %.0f, %.0f with rough 1)" % [float(jr.dist), float(jf.dist)]
	ok(roughOk, "rough ground never lengthens a skid: the same launch on each fine biome runs no farther than with rough set to 1%s" % roughNote)
	WorldBiomes.planetCols = pcs
	WorldBiomes.fineCols = fcs
	WorldBiomes.worldId = WorldBiomes.claim()
	Sy.worldId = WorldBiomes.worldId

	# cover on the synthetic ground: jungle needs a tree near, highland hides low on the rock, savanna nothing; water first
	pcs[1150] = 1
	WorldBiomes.planetCols = pcs
	WorldBiomes.worldId = WorldBiomes.claim()
	var coverOk: bool = true
	var cvNote: String = ""
	Sy.trees.clear()
	var jx: float = (7.0 * 100.0 + 50.5) * SimConst.COL
	var hx: float = (13.0 * 100.0 + 50.5) * SimConst.COL
	var sx: float = (8.0 * 100.0 + 50.5) * SimConst.COL
	var fj = {"x": jx, "y": WorldTerrain.groundY(Sy, jx) + 10.0}
	var fh = {"x": hx, "y": WorldTerrain.groundY(Sy, hx) + 10.0}
	var fs = {"x": sx, "y": WorldTerrain.groundY(Sy, sx) + 10.0}
	var c0 = WorldCover.coverAt(Sy, fj)
	var tr := SimState.TreeState.new()
	tr.x = jx
	tr.h = 500.0
	Sy.trees.append(tr)
	var c1 = WorldCover.coverAt(Sy, fj)
	fj.y = WorldTerrain.groundY(Sy, jx) + 91.0 * SimConst.WS
	var c2 = WorldCover.coverAt(Sy, fj)
	var c3 = WorldCover.coverAt(Sy, fh)
	fh.y = WorldTerrain.groundY(Sy, hx) + 41.0 * SimConst.WS
	var c4 = WorldCover.coverAt(Sy, fh)
	var c5 = WorldCover.coverAt(Sy, fs)
	cvNote = "jungle bare %s, jungle with a tree %s, jungle above 90 %s, highland low %s, highland above 40 %s, savanna %s" % [str(c0), str(c1), str(c2), str(c3), str(c4), str(c5)]
	coverOk = c0 == null and c1 == "canopy" and c2 == null and c3 == "ridge" and c4 == null and c5 == null
	ok(coverOk, "cover on gen 2 ground: " + cvNote)
	var nc = WorldCover.nearestCover(sx)   # the finder: savanna is not cover; the next block that is (taiga at 10, 300 columns on) or the ocean behind
	ok(nc != null and (nc.b == "forest" or nc.b == "mountains" or nc.b == "ocean"), "the cover finder on gen 2 ground names a forest, a mountain or the ocean from its cover profiles: %s" % str(nc))
	# the stale-fine guard: a hand-made match after a gen 2 one has no fine ground
	var Sh2 := SimCore.createSim()
	SimCore.newMatch(Sh2, 1, {}, {"intro": false})
	ok(WorldBiomes.fineCols.size() == 0 and not WorldGround.live(), "a hand-made match built after a gen 2 one starts with no fine columns (newMatch clears them), so live() is false")
	var Sg1 := SimCore.createSim()
	SimCore.newMatch(Sg1, 1, {}, {"planet": 7, "touch": pick, "arena": {"cols": 2400}, "intro": false})
	ok(WorldBiomes.fineCols.size() == 0 and Sg1.trees.size() == 0 and WorldClimate.genNow() == 1, "a gen 1 planet match after a gen 2 one resets the fine columns, has no trees and the data's generation")

	# --- trees and props are pure functions
	var Sp := SimCore.createSim()
	SimCore.newMatch(Sp, 1, {}, {"planet": 7, "touch": pick, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	var fcp: PackedByteArray = WorldBiomes.fineCols
	var pcp: PackedByteArray = WorldBiomes.planetCols
	var ta: Array = WorldGround.layTrees(fcp, pcp, Sp.base, 12345)
	var tb: Array = WorldGround.layTrees(fcp, pcp, Sp.base, 12345)
	var tc: Array = WorldGround.layTrees(fcp, pcp, Sp.base, 54321)
	var same: bool = ta.size() == tb.size() and ta.size() > 0
	for k in range(mini(ta.size(), tb.size())):
		if ta[k].x != tb[k].x or ta[k].h != tb[k].h:
			same = false
	ok(same and (tc.size() != ta.size() or tc[0].x != ta[0].x),"layTrees is a pure function of the columns, the ground and the seed (%d trees; another seed makes %d)" % [ta.size(), tc.size()])
	var pr: Array = WorldGround.propsIn(fcp, pcp, Sp.base, 777, 0, NC)
	var pr2: Array = WorldGround.propsIn(fcp, pcp, Sp.base, 777, 0, NC)
	var kindOk: bool = pr.size() > 50 and pr.size() == pr2.size()
	for p in pr:
		var names: Array = []
		for q in g[int(fcp[int(p.col)])].props:
			names.append(q.kind)
		if not names.has(p.kind) or int(p.col) < 0 or float(p.x) < float(p.col) * SimConst.COL or float(p.x) > float(p.col + 1) * SimConst.COL:
			kindOk = false
	ok(kindOk, "props are laid per column from a keyed draw, each of a kind its fine biome lists, inside its column, the same twice (%d on this ring)" % pr.size())
	var tt0: int = Time.get_ticks_usec()
	for k in range(20):
		WorldGround.layTrees(fcp, pcp, Sp.base, k)
	var lay_us: float = float(Time.get_ticks_usec() - tt0) / 20.0
	print("  (layTrees over 2400 columns: %.0f us; %d trees)" % [lay_us, ta.size()])

	# --- what it does to a fight: the same two launches over flat ground of each fine biome in turn
	var Sf := SimCore.createSim()
	SimCore.newMatch(Sf, 1, {}, {"intro": false})
	var NCf: int = SimConst.NC
	Sf.base.fill(120.0)
	Sf.deform.fill(0.0)
	Sf.rubble.fill(0.0)
	Sf.buildings.clear()
	Sf.trees.clear()
	WorldWater.init(Sf)
	var plainsC := PackedByteArray()
	plainsC.resize(NCf)
	plainsC.fill(1)
	WorldBiomes.planetCols = plainsC
	var rows: Array = []
	var dists: Dictionary = {}
	for k in range(15):
		var one := PackedByteArray()
		one.resize(NCf)
		one.fill(k)
		WorldBiomes.fineCols = one
		WorldBiomes.worldId = WorldBiomes.claim()
		Sf.worldId = WorldBiomes.worldId
		var x0: float = 2400.0 * SimConst.COL
		var ja: Dictionary = WorldContact.journey(Sf, WorldContact.launchBody(x0, 400.0, 3000.0, -800.0, 1.0, 2.0))   # shallow and fast: a long skid, to read the grip
		var jb: Dictionary = WorldContact.journey(Sf, WorldContact.launchBody(x0, 140.0, 1000.0, -400.0, 1.0, 2.0))   # shallow and slow (1,077): a skid on smooth ground, a tumble on rough
		var jc: Dictionary = WorldContact.journey(Sf, WorldContact.launchBody(x0, 140.0, 1000.0, -1100.0, 1.0, 2.0))   # steep: bounces, to read the absorb
		var first: String = String(jb.contacts[0].kind) if jb.contacts.size() > 0 else "-"
		dists[k] = [float(ja.dist), first, int(jc.bounces), float(jc.dist)]
		rows.append("%s %.0f/%s/%d x %.0f" % [g[k].name, float(ja.dist), first, int(jc.bounces), float(jc.dist)])
	print("  (fast skid distance / slow launch's first contact / steep launch's bounces x its distance, over flat ground of each biome: %s)" % ", ".join(rows))
	ok(float(dists[5][0]) > float(dists[1][0]) * 1.3 and float(dists[11][0]) < float(dists[1][0]) * 0.9, "over the same flat ground a fast skid runs %.0f on ice, %.0f on plains and %.0f in a wetland" % [float(dists[5][0]), float(dists[1][0]), float(dists[11][0])])
	var noTumble: bool = true
	for k in range(15):
		if dists[k][1] != "skid":
			noTumble = false
	ok(noTumble, "no biome makes a tumble: a slow launch's first contact is a skid on all 15 fine biomes, rough ground included (jungle %s, volcanic %s, plains %s); a tumble stays what the knocked-about rules make it (Game Design, rulings 2026-10-23b item 11)" % [dists[7][1], dists[14][1], dists[1][1]])
	ok(float(dists[11][3]) < float(dists[1][3]) * 0.95 and float(dists[12][3]) < float(dists[1][3]), "soft ground eats a bounce (the steep launch goes %.0f over a wetland, %.0f on a beach, %.0f on plains)" % [float(dists[11][3]), float(dists[12][3]), float(dists[1][3])])

	# --- the turn carries the fine biomes and the trees over
	var Tg := turn_match({"planetGen": 2})
	var Tg2 := turn_match({"planetGen": 2})
	ok(int(Tg.epoch.n) == 1, "a gen 2 match turns its arena (the swap landed)")
	ok(WorldGround.live() and WorldBiomes.fineCols.size() == SimConst.NC and Tg.planetRing.has("fine") and Tg.planetRing.fine.size() == SimConst.NC, "after the turn the fine columns are the new ring's, and S.planetRing carries them")
	var aliasT: bool = true
	for i in range(SimConst.NC):
		if int(WorldBiomes.planetCols[i]) < 7 and int(WorldBiomes.planetCols[i]) != WorldClimate.aliasOf(int(WorldBiomes.fineCols[i])):
			aliasT = false
	ok(aliasT and trees_on_treed_ground(Tg), "after the turn the stored columns are still the fine ones' aliases and every tree stands on dry, treed ground of the new fine biomes (%d trees)" % Tg.trees.size())
	ok(str(SimHash.stateHash(Tg).gameplay) == str(SimHash.stateHash(Tg2).gameplay), "the gen 2 turn is a pure function of the setup (the same hash twice, %s)" % str(SimHash.stateHash(Tg).gameplay))
	print("GROUND: %d check(s) failed" % fails)
	quit()


func WorldBiomes_alias_name(k: int) -> String:
	return ["ocean", "plains", "forest", "desert", "mountains", "mountains", "plains"][k] if k < 7 else ""
