extends SceneTree
# Fires in the forests (docs/world/forest-fire.md; WorldFire, data/biomes/fire.json): the trees just beyond a blast's felled ring catch by the ground's flammability, burn, spread a little, burn out, and go out in
# water; never a harm to a fighter, a building or a person; nothing with the switch off.
#   godot --headless --path . --script res://sim/world/tools/fire_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func fresh(seed: int = 1) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false})
	S.out.fx.clear()
	return S


func burning(S: SimState) -> int:
	var n: int = 0
	for t in S.trees:
		if t.alive and t.burn > 0.0:
			n += 1
	return n


func burnt(S: SimState) -> int:
	var n: int = 0
	for t in S.trees:
		if not t.alive and t.burn >= 1.0:
			n += 1
	return n


## The x of the middle of the densest stretch of flammable trees (the most within 700 units).
func forestX(S: SimState) -> float:
	var best: float = -1.0
	var bn: int = 0
	for t in S.trees:
		if WorldFire.flammability(t.x) <= 0.0:
			continue
		var n: int = 0
		for u in S.trees:
			if absf(SimWrap.sdx(t.x, u.x)) < 700.0:
				n += 1
		if n > bn:
			bn = n
			best = t.x
	return best


func blast(S: SimState, x: float) -> void:
	WorldStructures.damageArea(S, x, 0.0, 600.0, 10.0, S.fighters[0])


func run(S: SimState, ticks: int) -> void:
	for k in range(ticks):
		S.tick += 1
		WorldFire.step(S)


func _init() -> void:
	ok(WorldFire.dataErrors().is_empty(), "fire.json is clean (%s)" % str(WorldFire.dataErrors()))
	ok(not WorldFire.on(), "fire.json ships with the fires off")
	var S0 := fresh()
	var fx: float = forestX(S0)
	ok(S0.trees.size() > 20 and fx >= 0.0, "the hand-made world has %d trees, the densest flammable stretch at x %.0f" % [S0.trees.size(), fx])
	var dryX: float = -1.0
	for c in range(0, SimConst.NC, 5):
		var x: float = (float(c) + 0.5) * SimConst.COL
		if WorldBiomes.fineNameAt(x) == "desert":
			dryX = x
			break
	ok(WorldFire.flammability(fx) == 1.0 and dryX >= 0.0 and WorldFire.flammability(dryX) == 0.0 and WorldFire.flammability(-1.0) >= 0.0, "forest burns (1), desert does not (0)")
	# off: a blast fells the trees inside its radius and nothing catches
	var Soff := fresh()
	blast(Soff, fx)
	run(Soff, 200)
	var felled: int = 0
	for t in Soff.trees:
		if not t.alive:
			felled += 1
	ok(burning(Soff) == 0 and burnt(Soff) == 0 and felled > 0, "with the fires off a blast fells %d trees and nothing catches" % felled)
	var hOff: String = str(SimHash.stateHash(Soff).gameplay)
	# on: the trees in the band beyond the felled ring catch
	WorldFire.setOn(true)
	var S1 := fresh()
	blast(S1, fx)
	var n0: int = burning(S1)
	var inBand: bool = true
	for t in S1.trees:
		if t.alive and t.burn > 0.0:
			var d: float = absf(SimWrap.sdx(fx, t.x))
			if d < 600.0 * WorldFire.K_BAND_LO or d >= 600.0 * WorldFire.K_BAND_HI or WorldFire.flammability(t.x) <= 0.0:
				inBand = false
	var hp0: float = S1.fighters[0].hp
	var hpOff: float = Soff.fighters[0].hp
	ok(n0 > 0 and inBand and n0 <= WorldFire.K_MAX, "with the fires on %d tree(s) just beyond the felled ring catch, all in the band and on flammable ground (the felled ones, inside it, are not burning)" % n0)
	ok(hp0 == hpOff and S1.world.casualties == Soff.world.casualties and S1.world.structuresLost == Soff.world.structuresLost, "a fire harms nobody: the fighters' hp, the casualties and the structures lost are the same as with it off")
	# burning, spreading, burning out
	var peak: int = n0
	for k in range(WorldFire.K_TICKS * 3):
		S1.tick += 1
		WorldFire.step(S1)
		peak = maxi(peak, burning(S1))
	var done: int = burnt(S1)
	var stuck: int = burning(S1)
	ok(done >= n0 and stuck == 0 and peak <= WorldFire.K_MAX, "after %d ticks every fire is out: %d tree(s) burnt (dead, burn 1) of the %d lit at the blast, at most %d burning at once" % [WorldFire.K_TICKS * 3, done, n0, peak])
	var onFlam: bool = true
	for t in S1.trees:
		if t.burn > 0.0 and WorldFire.flammability(t.x) <= 0.0:
			onFlam = false
	ok(onFlam, "no tree on unflammable ground burnt")
	# the same twice
	var S2 := fresh()
	blast(S2, fx)
	for k in range(WorldFire.K_TICKS * 3):
		S2.tick += 1
		WorldFire.step(S2)
	var S1b := fresh()
	blast(S1b, fx)
	for k in range(WorldFire.K_TICKS * 3):
		S1b.tick += 1
		WorldFire.step(S1b)
	ok(str(SimHash.stateHash(S2).gameplay) == str(SimHash.stateHash(S1b).gameplay) and burnt(S2) == burnt(S1b), "a burning forest is the same twice (%d burnt)" % burnt(S2))
	# water puts a fire out
	var S3 := fresh()
	blast(S3, fx)
	var lit: int = -1
	for i in range(S3.trees.size()):
		if S3.trees[i].alive and S3.trees[i].burn > 0.0:
			lit = i
			break
	var colq: int = int(floor(SimWrap.wrap(S3.trees[lit].x) / SimConst.COL)) % SimConst.NC
	S3.water[colq] = 5.0
	S3.tick += 1
	WorldFire.step(S3)
	ok(lit >= 0 and S3.trees[lit].burn == 0.0 and S3.trees[lit].alive, "a burning tree standing in water goes out and stands")
	# spreading, in a dense stand (made by hand: a tree every 50 units for 2,000 units on flammable ground)
	var S4 := fresh()
	S4.trees.clear()
	for k in range(40):
		var tr := SimState.TreeState.new()
		tr.x = fx - 1000.0 + float(k) * 50.0
		tr.h = 120.0
		tr.alive = true
		S4.trees.append(tr)
	S4.trees[20].burn = 1.0 / float(WorldFire.K_TICKS)
	var peak4: int = 1
	for k in range(WorldFire.K_TICKS * 6):
		S4.tick += 1
		WorldFire.step(S4)
		peak4 = maxi(peak4, burning(S4))
	var flam4: int = 0
	for t in S4.trees:
		if WorldFire.flammability(t.x) > 0.0:
			flam4 += 1
	ok(burnt(S4) >= 5 and burning(S4) == 0 and peak4 <= WorldFire.K_MAX and burnt(S4) <= flam4, "a fire in a dense stand spreads: one lit tree burns %d of its %d flammable neighbours (%d at the peak), then all is out" % [burnt(S4), flam4, peak4])
	# the idle forest costs nothing and is the same state
	var Sa := fresh()
	WorldFire.setOn(false)
	var Sb := fresh()
	WorldFire.setOn(true)
	run(Sa, 120)
	run(Sb, 120)
	ok(str(SimHash.stateHash(Sa).gameplay) == str(SimHash.stateHash(Sb).gameplay), "with no fire lit, the fires on or off leave the same state")
	# cost
	var Sc := fresh()
	blast(Sc, fx)
	var t0: int = Time.get_ticks_usec()
	for k in range(120):
		Sc.tick += 1
		WorldFire.step(Sc)
	var per: float = float(Time.get_ticks_usec() - t0) / 120.0
	ok(per < 2000.0, "a tick with fires burning costs %.0f us (%d trees in the world)" % [per, Sc.trees.size()])
	# --- the signature rows' tree modes (damageArea's treeMode): the fire cue belongs to "area" and "burn"; "fell", "snap" and "none" make no fire
	var litBy: Dictionary = {}
	for mode in ["area", "burn", "fell", "snap", "none"]:
		var Sm := fresh()
		WorldStructures.damageArea(Sm, fx, 0.0, 600.0, 10.0, Sm.fighters[0], false, 0.0, -1, 0.0, -1.0, mode)
		litBy[mode] = burning(Sm)
	ok(int(litBy.area) > 0 and int(litBy.burn) > 0 and int(litBy.fell) == 0 and int(litBy.snap) == 0 and int(litBy.none) == 0, "the fire follows the tree mode: area %d, burn %d, fell %d, snap %d, none %d tree(s) catch" % [litBy.area, litBy.burn, litBy.fell, litBy.snap, litBy.none])
	WorldFire.setOn(false)
	print("FIRE: %d check(s) failed" % fails)
	quit()
