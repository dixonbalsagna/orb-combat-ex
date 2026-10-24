extends SceneTree
# Game Design's ruling 12 (docs/design/rulings-2026-10-23b.md item 12): control returns at the stop on reference ground (the surface's own braking, grip and rough 1), whatever the ground's grip; lower grip only
# lengthens the slide, as a skate after control is back; higher grip and rough ground stop sooner and return control sooner. WorldContact.journeyControl is the lookahead that says where.
#   godot --headless --path . --script res://sim/world/tools/control_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func world(fine: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var nc: int = SimConst.NC
	S.base.fill(120.0)
	S.deform.fill(0.0)
	S.rubble.fill(0.0)
	S.buildings.clear()
	S.trees.clear()
	WorldWater.init(S)
	var pc := PackedByteArray()
	pc.resize(nc)
	pc.fill(1)
	var fc := PackedByteArray()
	fc.resize(nc)
	fc.fill(fine)
	WorldBiomes.planetCols = pc
	WorldBiomes.fineCols = fc
	WorldBiomes.worldId = WorldBiomes.claim()
	S.worldId = WorldBiomes.worldId
	return S


func control(S: SimState, vx: float, vy: float) -> Dictionary:
	return WorldContact.journeyControl(S, WorldContact.launchBody(2400.0 * SimConst.COL, 400.0, vx, vy, 1.0, 2.0))


func _init() -> void:
	var g: Array = WorldGround.data().grounds
	var res: Dictionary = {}
	for k in range(15):
		res[k] = control(world(k), 3000.0, -800.0)
	var P: Dictionary = res[1]
	var I: Dictionary = res[5]
	var W: Dictionary = res[11]
	var J: Dictionary = res[7]
	print("  (fast skid, ticks real / control / reference stop, skate units: plains %d/%d/%d/%.0f, ice sheet %d/%d/%d/%.0f, sea ice %d/%d/%d/%.0f, wetland %d/%d/%d/%.0f, jungle %d/%d/%d/%.0f)" % [P.ticks, P.ctrl, P.refTicks, P.skate, I.ticks, I.ctrl, I.refTicks, I.skate, res[6].ticks, res[6].ctrl, res[6].refTicks, res[6].skate, W.ticks, W.ctrl, W.refTicks, W.skate, J.ticks, J.ctrl, J.refTicks, J.skate])
	ok(P.skidAt > 0 and P.ctrl == P.ticks and P.refTicks == P.ticks and absf(P.skate) < 1.0e-9, "plains: the reference ground is itself, so control returns at its own stop (tick %d), with no skate" % P.ctrl)
	ok(I.refTicks > 0 and I.ctrl == I.refTicks and I.ctrl < I.ticks and I.skate > 100.0, "ice sheet: control returns at the stop on reference ground (tick %d), the body skating on to tick %d: a skate of %.0f units after control" % [I.ctrl, I.ticks, I.skate])
	ok(res[6].ctrl == res[6].refTicks and res[6].ctrl < res[6].ticks and res[6].skate > 100.0, "sea ice the same: control at tick %d, a skate of %.0f units" % [res[6].ctrl, res[6].skate])
	ok(W.ctrl == W.ticks and W.ticks < W.refTicks and W.skate == 0.0, "wetland (grip 1.5): it stops sooner than reference ground (tick %d against %d), and control returns at its own stop with no skate" % [W.ticks, W.refTicks])
	ok(J.ctrl == J.ticks and J.ticks <= J.refTicks, "jungle (rough 1.3, grip 1.25): control returns at its own, earlier stop (tick %d, reference %d): rough never ends a skid later than reference ground" % [J.ticks, J.refTicks])
	var never: bool = true
	var note: String = ""
	for k in range(15):
		var r: Dictionary = res[k]
		if r.refTicks >= 0 and r.ctrl > r.refTicks:
			never = false
			note += " " + String(g[k].name)
		if r.ctrl > r.ticks:
			never = false
	ok(never, "on all 15 fine biomes control returns no later than the reference stop and no later than the real stop%s" % note)
	# the reference run is the same skid on a world whose profile is 1: an ice sheet's reference stop is the stop a rock of grip 1 gives
	var Si: SimState = world(5)
	WorldContact.surfaceAt(Si, 0.0)   # builds the profile arrays (lazily) before they are swapped
	var gr: PackedFloat64Array = WorldContact._gGrip
	var ro: PackedFloat64Array = WorldContact._gRough
	var ones := PackedFloat64Array()
	ones.resize(gr.size())
	ones.fill(1.0)
	WorldContact._gGrip = ones
	WorldContact._gRough = ones
	var plain: Dictionary = WorldContact.journey(Si, WorldContact.launchBody(2400.0 * SimConst.COL, 400.0, 3000.0, -800.0, 1.0, 2.0))
	WorldContact._gGrip = gr
	WorldContact._gRough = ro
	ok(int(plain.ticks) == I.refTicks, "the reference stop is the stop the same ice with grip and rough 1 gives (%d ticks both ways)" % int(plain.ticks))
	var same: bool = true
	for k in [1, 5, 11]:
		var again: Dictionary = control(world(k), 3000.0, -800.0)
		if str(again) != str(res[k]):
			same = false
	ok(same, "journeyControl is a pure function: the same twice on plains, ice and wetland")
	# a hand-made gen 1 world: no profile, the reference run is the real one
	var S1 := SimCore.createSim()
	SimCore.newMatch(S1, 1, {}, {"intro": false})
	var h: Dictionary = WorldContact.journeyControl(S1, WorldContact.launchBody(30000.0, 400.0, 3000.0, -800.0, 1.0, 2.0))
	ok(h.ctrl == h.ticks and absf(float(h.skate)) < 1.0e-9, "on a gen 1 world control returns at the stop, no skate (the same two runs)")
	print("CONTROL: %d check(s) failed" % fails)
	quit()
