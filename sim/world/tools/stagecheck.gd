extends SceneTree
# Slice 1 of docs/world/staged-destruction.md: the stage function, its data, the building_stage event.
var fails: int = 0
func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1
func fresh() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	S.out.fx.clear()
	return S
func stages(S: SimState) -> Array:
	var out: Array = []
	for e in S.out.fx:
		if e.type == "building_stage":
			out.append([int(e.b), int(e.from), int(e.to), int(e.n)])
	return out
func pick(S: SimState, kind: String):
	for b in S.buildings:
		if b.kind == kind and b.alive and b.row == 1.0:
			return b
	return null
func _init() -> void:
	print("== building stages ==")
	ok(WorldStructures.stagesErrors().is_empty(), "the data loads (%s)" % str(WorldStructures.stagesErrors()))
	var S := fresh()
	var h = pick(S, "house")
	var t = pick(S, "tower")
	# the function by hit points
	var got: Array = []
	for f in [1.0, 0.95, 0.89, 0.7, 0.64, 0.5, 0.36, 0.34, 0.1]:
		h.hp = h.maxhp * f
		got.append(WorldStructures.stage(h))
	ok(got == [0, 0, 1, 1, 2, 2, 2, 3, 3], "stage by hit points 1.0 .95 .89 .7 .64 .5 .36 .34 .1 gives %s" % str(got))
	h.hp = h.maxhp
	h.alive = false
	ok(WorldStructures.stage(h) == 4, "a building that is not alive is stage 4")
	h.alive = true
	# a cut floor puts a tower in stage 2 at least
	ok(WorldStructures.stage(t) == 0, "a whole tower is stage 0")
	t.fmask = t.fmask & ~(1 << 3)
	ok(WorldStructures.stage(t) == 2, "a tower with a cut floor is stage 2 (%d)" % WorldStructures.stage(t))
	# an event on a change of stage, one for a blast that crosses two thresholds, none on a miss
	var S2 := fresh()
	var h2 = pick(S2, "house")
	WorldStructures.damageBuilding(S2, h2, h2.maxhp * 0.05, S2.fighters[0], "burst", h2.x, 0.0)
	ok(stages(S2).is_empty(), "5% of the hit points is no change of stage, so no event")
	WorldStructures.damageBuilding(S2, h2, h2.maxhp * 0.1, S2.fighters[0], "burst", h2.x, 0.0)
	ok(stages(S2) == [[h2.idx, 0, 1, 0]], "crossing 90%% sends one event 0 to 1 (%s)" % str(stages(S2)))
	S2.out.fx.clear()
	WorldStructures.damageBuilding(S2, h2, h2.maxhp * 0.6, S2.fighters[0], "burst", h2.x, 0.0)
	ok(stages(S2) == [[h2.idx, 1, 3, 0]], "a blow past two thresholds sends one event 1 to 3 (%s)" % str(stages(S2)))
	S2.out.fx.clear()
	WorldStructures.damageBuilding(S2, h2, h2.maxhp, S2.fighters[0], "implode", h2.x, 0.0)
	ok(stages(S2) == [[h2.idx, 3, 4, 0]], "the last blow sends one event 3 to 4 (%s)" % str(stages(S2)))
	var S3 := fresh()
	var h3 = pick(S3, "house")
	WorldStructures.damageBuilding(S3, h3, 1.0e9, S3.fighters[0], "implode", h3.x, 0.0)
	ok(stages(S3) == [[h3.idx, 0, 4, 0]], "a building levelled at once is one event 0 to 4 (%s)" % str(stages(S3)))
	# a shot through the floors of a tower: one event, the floors lost counted
	var S4 := fresh()
	S4.fighters[0].tier = 4.0
	var t4 = pick(S4, "tower")
	var oc: Dictionary = WorldBrunt.outcomeDmg(S4, t4, WorldStructures.baseY(S4, t4) + t4.h * 0.9, 4000.0)
	var s0: int = WorldStructures.stage(t4)
	var r: Dictionary = WorldBrunt.applyFloors(S4, t4, oc, S4.fighters[0], 0.0, t4.x, S4.fighters[1], WorldStructures.baseY(S4, t4) + t4.h * 0.9)
	var ev: Array = stages(S4)
	ok(ev.size() == 1 and ev[0][1] == s0, "floors punched out of a tower: one event from stage %d (%s)" % [s0, str(ev)])
	# the event is cheap and deterministic: no rng
	var S5 := fresh()
	var rng0: int = S5.rng.state_i32()
	var h5 = pick(S5, "house")
	WorldStructures.damageBuilding(S5, h5, h5.maxhp * 0.5, S5.fighters[0], "burst", h5.x, 0.0)
	ok(S5.rng.state_i32() == rng0, "the stage change draws nothing from the rng")
	# the cap: a blast cannot finish a standing building; a second one does; a beam is not capped
	var lf: float = WorldStructures.leaveFrac()
	ok(lf > 0.0, "the cap is on (leaveFrac %.2f)" % lf)
	var S6 := fresh()
	var h6 = pick(S6, "house")
	WorldStructures.damageArea(S6, h6.x, WorldStructures.baseY(S6, h6) + 50.0, 400.0, 1.0e6, S6.fighters[0])
	ok(h6.alive and absf(h6.hp - lf * h6.maxhp) < 0.01, "a huge blast leaves the house at %.0f%% of its hit points (alive %s, hp %.1f of %.1f)" % [lf * 100.0, str(h6.alive), h6.hp, h6.maxhp])
	WorldStructures.damageArea(S6, h6.x, WorldStructures.baseY(S6, h6) + 50.0, 400.0, 1.0e6, S6.fighters[0])
	ok(not h6.alive, "the second blast finishes it")
	var S7 := fresh()
	var h7 = pick(S7, "house")
	WorldStructures.damageArea(S7, h7.x, WorldStructures.baseY(S7, h7) + 50.0, 400.0, 1.0e6, S7.fighters[0], true)
	ok(not h7.alive, "a beam is not capped: one pass levels it")
	var S8 := fresh()
	var h8 = pick(S8, "house")
	h8.hp = h8.maxhp * 0.05
	WorldStructures.damageArea(S8, h8.x, WorldStructures.baseY(S8, h8) + 50.0, 400.0, 1.0e6, S8.fighters[0])
	ok(not h8.alive, "a building already under the share is finished by one blast")
	# the float edge: a building left a hair above the cap (the last bit of what the first blast left) is finished by the next blast
	var S9 := fresh()
	var h9 = pick(S9, "house")
	h9.hp = lf * h9.maxhp * (1.0 + 1.0e-12)
	WorldStructures.damageArea(S9, h9.x, WorldStructures.baseY(S9, h9) + 50.0, 400.0, 1.0e6, S9.fighters[0])
	ok(not h9.alive, "a house a hair above the cap (hp %s of cap %s) is finished by the next blast" % [str(h9.hp), str(lf * h9.maxhp)])
	# and across many first blasts: the second one always finishes what the first left
	var stuck: int = 0
	for sd in range(1, 41):
		var Sx := fresh()
		for b in Sx.buildings:
			if b.alive and b.kind == "house" and WorldStructures.dz(b) <= WorldStructures.Z_REACH:
				b.maxhp = b.maxhp * (1.0 + float(sd) * 0.0137)   # a different hit-point value for each trial, so the rounding differs
				b.hp = b.maxhp
				WorldStructures.damageArea(Sx, b.x, WorldStructures.baseY(Sx, b) + 50.0, 400.0, 1.0e6, Sx.fighters[0])
				WorldStructures.damageArea(Sx, b.x, WorldStructures.baseY(Sx, b) + 50.0, 400.0, 1.0e6, Sx.fighters[0])
				if b.alive:
					stuck += 1
				break
	ok(stuck == 0, "40 houses of different hit points: the second blast finishes every one the first left (%d left standing)" % stuck)
	print("STAGE: %d check(s) failed" % fails)
	quit()
