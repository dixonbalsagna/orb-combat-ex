extends SceneTree
## Lake water check: water draws across a lake's whole interior, and only on a ring with lakes
## (render/shaders/water.gdshaderinc, PlanetView's lake_on; docs/rendering/biomes.md).
## 1. gen 2: the water material's lake_on is 1 on a planet with lakes, and the interior the old test left undrawn (a wet
##    column off the sea, not dug, not at sea level) is there. Planet 7's tundra column, the reported picture, is one.
## 2. gen 1 and the hand-made world: no lakes and lake_on 0, so the shader's new paths are shut.
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
		ok(_lake_on() == (0.0 if lakes.is_empty() else 1.0) and (lakes.is_empty() or undrawn > 0), "gen 2 planet %d: %d lakes and rivers, lake_on %d, %d interior columns the old test left undrawn" % [pl, lakes.size(), int(_lake_on()), undrawn])
		if pl == REPORTED_PLANET:
			var c: int = _fine_centre("tundra")
			ok(c >= 0 and S.water[c] >= WorldWater.MIN_DEPTH and S.base[c] >= WorldWater.RESERVOIR_BASE, "the reported picture: planet %d's tundra column %d is wet off the sea, %.1f deep" % [pl, c, S.water[c] if c >= 0 else 0.0])
	for pl in GEN1:
		var S: SimState = _start(1, {"planet": pl, "touch": 3, "intro": false})
		ok(_lake_on() == 0.0 and S.planetRing.get("lakes", []).is_empty(), "gen 1 planet %d: no lakes, lake_on 0" % pl)
	for sd in HAND:
		_start(sd, {"intro": false})
		ok(_lake_on() == 0.0, "the hand-made world, match seed %d: lake_on 0" % sd)
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
