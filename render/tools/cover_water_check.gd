extends SceneTree
## Cover water check: no land cover stands in the water of a river or a lake as the water shader draws it
## (render/core/cover_view.gd, GroundField.flooded; docs/rendering/biomes.md).
## 1. rivers and lakes: on gen 2 planets, no land shape the cover places stands where the sheet of a lake or a river is
##    drawn: on a column with its water, or on dry land up to RenderLook.SHORE_FLOOD below the level beside it (the same
##    row the water shader reads). At least one world keeps some out.
## 2. Art's shape: planet 21's krummholz at column 2440 (a dry hollow behind the lake's lip, 5.5 units under its level)
##    stood under the sheet. The lip draws no sheet there now, so it stands, on dry land, with the rule on and off.
## 3. nothing else moves: with the rule off (CoverView.ctl_in_water) the same world places the same shapes, in the same
##    order at the same places, plus those it kept out. So the control sees shapes in the water (check 1 can fail).
## 4. gen 1 and the hand-made world: no lakes, nothing kept out, the same shapes with the rule on and off.
## 5. no flip: on gen 2 no krummholz is mirrored (CoverView.NO_FLIP: its lean is its shape), and other kinds still are.
##   godot --headless --path . --script res://render/tools/cover_water_check.gd

const GEN2: Array = [21, 7, 47, 3, 11]
const GEN1: Array = [7, 21]
const HAND: Array = [1, 12345]
const ART_PLANET: int = 21
const ART_COL: int = 2440

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
	CoverView.record = true
	var kept: int = 0
	var in_control: int = 0
	var krummholz: int = 0
	var mirrored: int = 0
	var others_mirrored: int = 0
	for pl in GEN2:
		var r: Dictionary = _both(1, {"planet": pl, "touch": 3, "planetGen": 2, "intro": false})
		kept += int(r.in_water)
		for e in main.planet.cover.laid:
			if String(e[2]) == "krummholz":
				krummholz += 1
				mirrored += 1 if float(e[3]) < 0.0 else 0
			elif float(e[3]) < 0.0:
				others_mirrored += 1
		in_control += int(r.control_bad)
		ok(int(r.bad) == 0 and int(r.control_bad) == int(r.in_water) and bool(r.rest_same), "gen 2 planet %d: %d lakes and rivers; of %d shapes %d stand in their water with the rule off (%d of them on dry columns under the sheet), none with it on; every other shape is where it was" % [pl, int(r.lakes), int(r.control_count), int(r.control_bad), int(r.control_dry)])
		if pl == ART_PLANET:
			ok(int(r.art_off) > 0 and int(r.art_on) == int(r.art_off) and bool(r.art_dry), "Art's shape: planet %d's krummholz on column %d, behind the lake's lip: no sheet over it, %d with the rule off, %d with it on" % [pl, ART_COL, int(r.art_off), int(r.art_on)])
	ok(kept > 0 and in_control == kept, "rivers and lakes: %d land shapes kept out across %d gen 2 worlds; the control sees them all (%d)" % [kept, GEN2.size(), in_control])
	ok(krummholz > 0 and mirrored == 0 and others_mirrored > 0, "no flip: of %d krummholz across the gen 2 worlds %d are mirrored; %d shapes of other kinds are" % [krummholz, mirrored, others_mirrored])
	for pl in GEN1:
		var r: Dictionary = _both(1, {"planet": pl, "touch": 3, "intro": false})
		ok(int(r.lakes) == 0 and int(r.in_water) == 0 and bool(r.same), "gen 1 planet %d: no lakes, nothing kept out, the same %d shapes with the rule on and off" % [pl, int(r.control_count)])
	for sd in HAND:
		var r: Dictionary = _both(sd, {"intro": false})
		ok(int(r.lakes) == 0 and int(r.in_water) == 0 and bool(r.same), "the hand-made world, match seed %d: no lakes, nothing kept out, the same %d shapes with the rule on and off" % [sd, int(r.control_count)])
	CoverView.record = false
	print("cover water check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


## One world's cover with the rule on, then off.
func _both(seed: int, setup: Dictionary) -> Dictionary:
	var S: SimState = _start(seed, setup)
	var C: CoverView = main.planet.cover
	var on: Array = C.laid.duplicate()
	var in_water: int = C.in_water
	var lakes: Array = S.planetRing.get("lakes", []) if S.planetRing is Dictionary else []
	var bad: int = _in_lakes(S, on, lakes)
	var art_on: int = _art(on)
	var art_dry: bool = not main.planet.ground.flooded(S, ART_COL)
	CoverView.ctl_in_water = true
	var S2: SimState = _start(seed, setup)
	var off: Array = main.planet.cover.laid.duplicate()
	CoverView.ctl_in_water = false
	var control_bad: int = _in_lakes(S2, off, lakes)
	var rest: Array = []
	var dry: int = 0
	for e in off:
		if not _stands_in_lake(S2, e, lakes):
			rest.append(e)
		elif S2.water[_col(e)] < WorldWater.MIN_DEPTH:
			dry += 1
	return {"lakes": lakes.size(), "in_water": in_water, "bad": bad, "control_bad": control_bad, "control_dry": dry, "control_count": off.size(), "rest_same": rest == on, "same": on == off, "art_on": art_on, "art_off": _art(off), "art_dry": art_dry}


func _start(seed: int, setup: Dictionary) -> SimState:
	main.start_match(seed, {"p1": true, "p2": true}, setup)
	while main.host.loading():
		main.frame(1.0 / 60.0)
	return main.host.S


func _art(list: Array) -> int:
	var n: int = 0
	for e in list:
		if String(e[2]) == "krummholz" and _col(e) == ART_COL:
			n += 1
	return n


func _col(e: Array) -> int:
	return posmod(int(float(e[0]) / SimConst.COL), SimConst.NC)


func _in_lakes(S: SimState, list: Array, lakes: Array) -> int:
	var n: int = 0
	for e in list:
		if _stands_in_lake(S, e, lakes):
			n += 1
	return n


## A land shape where the sheet of a lake or a river is drawn, read as water.gdshaderinc reads it: row 20's level is a
## lake's, and the column has water or its ground is up to SHORE_FLOOD under that level.
func _stands_in_lake(S: SimState, e: Array, lakes: Array) -> bool:
	if CoverView.WATER_KINDS.has(String(e[2])):
		return false
	var col: int = _col(e)
	var lv: float = main.planet.ground.shore[col]
	var at_lake: bool = false
	for lk in lakes:
		at_lake = at_lake or absf(float(lk[2]) - lv) < 1.0
	if not at_lake:
		return false
	var below: float = lv - (S.base[col] + S.deform[col])
	return S.water[col] >= WorldWater.MIN_DEPTH or (below > 0.0 and below <= RenderLook.SHORE_FLOOD)
