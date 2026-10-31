extends SceneTree
## Lake water check: water draws across a lake's whole interior, and only on a ring with lakes
## (render/shaders/water.gdshaderinc, PlanetView's lake_on; docs/rendering/biomes.md).
## 1. gen 2: the water material's lake_on is 1, and the interior the old test left undrawn (a wet
##    column off the sea, not dug, not at sea level) is there. Planet 7's tundra column, the reported picture, is one.
## 2. gen 1 and the hand-made world: no lakes and lake_on 0, so the shader's new paths are shut.
## 2b. A lake's lip: on gen 2, no column past a lake's first land at its level has that level unless the land stands above
##    it, on the two sweeps and on the one-column answer alike, which agree everywhere. Gen 1 floods on as ever.
## 2c. A fighter under deep water: GroundField.under_level gives the level only on gen 2, in water from the first step, below
##    the level; AnimBody attaches his passes there and takes them off again; both are in the warm-up's list.
## 3. The bands read the ruling: LAKE_BANDS.y is data/biomes/water.json's wade.below and .x half of it.
##   godot --headless --path . --script res://render/tools/lake_water_check.gd
## (A headless run draws nothing: the picture itself is the look gate's stills, docs/rendering/tools/lake-hook.mjs.)

const GEN2: Array = [21, 7, 47, 3, 11]
const GEN1: Array = [7, 21]
const HAND: Array = [1, 12345]
const REPORTED_PLANET: int = 7

var main: Node
var fails: int = 0


func _initialize() -> void:
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("ok    " if cond else "FAIL  ") + what)


func _run() -> void:
	await process_frame
	main.started = true
	for pl in GEN2:
		var S: SimState = _start(1, {"planet": pl, "touch": 3, "planetGen": 2, "intro": false})
		var lakes: Array = S.planetRing.get("lakes", [])
		var undrawn: int = _old_test_left(S)
		ok(_lake_on() == 1.0 and (lakes.is_empty() or undrawn > 0), "gen 2 planet %d: %d lakes and rivers, lake_on %d, %d interior columns the old test left undrawn" % [pl, lakes.size(), int(_lake_on()), undrawn])
		_lips(S, pl)
		if pl == REPORTED_PLANET:
			_under(S)
			var c: int = _fine_centre("tundra")
			ok(c >= 0 and S.water[c] >= WorldWater.MIN_DEPTH and S.base[c] >= WorldWater.RESERVOIR_BASE, "the reported picture: planet %d's tundra column %d is wet off the sea, %.1f deep" % [pl, c, S.water[c] if c >= 0 else 0.0])
	for pl in GEN1:
		var S: SimState = _start(1, {"planet": pl, "touch": 3, "intro": false})
		ok(_lake_on() == 0.0 and S.planetRing.get("lakes", []).is_empty() and GroundField.under_level(S, S.fighters[0].x, -1.0e6) == GroundField.NO_SHORE, "gen 1 planet %d: no lakes, lake_on 0, and no one is under" % pl)
	for sd in HAND:
		var Sh: SimState = _start(sd, {"intro": false})
		ok(_lake_on() == 0.0 and GroundField.under_level(Sh, Sh.fighters[0].x, -1.0e6) == GroundField.NO_SHORE, "the hand-made world, match seed %d: lake_on 0, and no one is under" % sd)
	var w = JSON.parse_string(FileAccess.get_file_as_string("res://data/biomes/water.json"))
	var below: float = float(w.wade.below)
	ok(RenderLook.LAKE_BANDS.y == below and RenderLook.LAKE_BANDS.x == below * 0.5, "the bands read the ruling: the bed hides from %.1f, opaque from %.1f (wade.below %.1f)" % [RenderLook.LAKE_BANDS.x, RenderLook.LAKE_BANDS.y, below])
	print("lake water check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


func _start(seed: int, setup: Dictionary) -> SimState:
	main.start_match(seed, {"p1": true, "p2": true}, setup)
	while main.host.loading():
		main.frame(1.0 / 60.0)
	main.frame(1.0 / 60.0)
	return main.host.S


func _lake_on() -> float:
	var v = main.planet._water_mat.get_shader_parameter("lake_on")
	return 0.0 if v == null else float(v)


## A body at a deep column, under its level and over it; a shallow column; his passes on and off.
func _under(S: SimState) -> void:
	var deep: int = -1
	var thin: int = -1
	for i in range(SimConst.NC):
		if S.water[i] >= RenderLook.LAKE_BANDS.y and deep < 0:
			deep = i
		if S.water[i] >= WorldWater.MIN_DEPTH and S.water[i] < RenderLook.LAKE_BANDS.x and thin < 0:
			thin = i
	var x: float = (float(deep) + 0.5) * SimConst.COL
	var lv: float = S.base[deep] + S.deform[deep] + S.water[deep]
	ok(GroundField.under_level(S, x, lv - 10.0) == lv and GroundField.under_level(S, x, lv + 10.0) == GroundField.NO_SHORE, "under_level: column %d, %.1f deep: the level below it, none above it" % [deep, S.water[deep]])
	ok(thin < 0 or GroundField.under_level(S, (float(thin) + 0.5) * SimConst.COL, -1.0e6) == GroundField.NO_SHORE, "under_level: none in water under the first step")
	var b := AnimBody.new()
	root.add_child(b)
	var c := Color(0.5, 0.5, 0.5)
	b.build({"body": c, "legs": c, "arms": c, "skin": c, "gear": c, "accent": c, "hair": c})
	b.set_under(true, lv)
	var on: bool = b._hull.next_pass != null and float(b._hull.next_pass.get_shader_parameter("under_level")) == lv and b._hull.next_pass.render_priority == 1 and b._hull.next_pass.next_pass != null
	b.set_under(false, 0.0)
	ok(on and b._hull.next_pass == null, "AnimBody.set_under: his two passes after the water go on with the level and come off")
	b.free()
	var listed: int = 0
	for e in RenderWarmup.SHADERS:
		if str(e[0]).ends_with("fighter_under.gdshader") or str(e[0]).ends_with("fighter_hull_under.gdshader"):
			listed += 1
	ok(listed == 2, "both passes are in the boot's warm-up")


## The lip: the sweeps' and the one-column answer agree, and low land past a lip has no lake level.
func _lips(S: SimState, pl: int) -> void:
	var f: GroundField = main.planet.ground
	var differ: int = 0
	var wrong: int = 0
	for i in range(SimConst.NC):
		if absf(f.shore[i] - f._shore_at(S, i)) > 0.001:
			differ += 1
		if S.water[i] >= WorldWater.MIN_DEPTH:
			continue
		var g: float = S.base[i] + S.deform[i]
		var lv: float = f.shore[i]
		if lv > GroundField.NO_SHORE * 0.5 and absf(lv) >= WorldWater.MIN_DEPTH and g < lv:
			# Low land under a lake's level: it must be on the lake's side of every lip, on the side it took the level from.
			var open: bool = false
			for dir in [1, -1]:
				for d in range(1, RenderLook.SHORE_COLS + 1):
					var j: int = posmod(i + dir * d, SimConst.NC)
					if S.water[j] >= WorldWater.MIN_DEPTH:
						open = open or absf(S.base[j] + S.deform[j] + S.water[j] - lv) < 0.001
						break
					if S.base[j] + S.deform[j] >= lv:
						break
			if not open:
				wrong += 1
	ok(differ == 0 and wrong == 0, "gen 2 planet %d's lips: the sweeps and the one-column answer differ on %d columns, %d low columns hold a level past a lip" % [pl, differ, wrong])


## The columns the shader's old test failed: wet, off the sea, not dug, not at sea level.
func _old_test_left(S: SimState) -> int:
	var n: int = 0
	for i in range(SimConst.NC):
		if S.water[i] >= WorldWater.MIN_DEPTH and S.base[i] >= WorldWater.RESERVOIR_BASE and S.deform[i] >= -WorldWater.MIN_DEPTH and absf(S.base[i] + S.deform[i] + S.water[i]) >= WorldWater.MIN_DEPTH:
			n += 1
	return n


## The middle of the ring's longest stretch of a fine biome (how the pb scene sets the pair down).
func _fine_centre(want: String) -> int:
	var best_len: int = 0
	var best_c: int = -1
	var run: int = 0
	for i in range(SimConst.NC):
		if WorldBiomes.fineNameAt((float(i) + 0.5) * SimConst.COL) == want:
			run += 1
			if run > best_len:
				best_len = run
				best_c = i - run / 2
		else:
			run = 0
	return best_c
