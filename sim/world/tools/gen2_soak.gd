extends SceneTree
# Gen 2 matches played through (World, window 4): AI against AI on gen 2 planets (the whole of gen 2: climate, profiles, trees, landforms, sites), some with the calm-moment turn on, a few ticks each, to
# see that nothing errors and that a match is the same twice. Prints a line a match.
#   godot --headless --path . --script res://sim/world/tools/gen2_soak.gd -- --ticks=900     (--b: with land.json's b switch on for the run, window 12; --rivers: with rivers.json on, window 14; --fire: with fire.json on, window 18; --floor: with the floor of a lake or the sea on, and the surfacing rule it needs; --hand: the hand-made world, six seeds, instead of the planets)
func match_hash(setup: Dictionary, ticks: int, seed: int = 1) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, setup)
	var sea: Dictionary = {"sheet": 0, "waded": 0, "under": 0, "run": 0, "longest": 0, "runs": [0, 0]}
	if WorldFill.floorOn() and sea_start:
		for k in range(S.fighters.size()):
			var xs: float = sea_x(S, k)
			if not is_nan(xs):
				S.fighters[k].x = xs
				S.fighters[k].y = WorldWater.floorAt(S, xs) + 20.0
	for t in range(ticks):
		SimCore.step(S)
		if WorldFill.floorOn() and t >= SPAWN_TICKS:
			for k in range(S.fighters.size()):
				var f = S.fighters[k]
				var d: float = WorldWater.floorDepth(S, f.x, f.z)
				if d >= WorldFill.wadeBelow():
					sea.sheet += 1
				elif d > 0.0:
					sea.waded += 1
				var free: bool = f.state != "dropped" and f.state != "launched" and f.state != "down" and not DirWater.under(f)
				if free and f.y < WorldWater.floorAt(S, f.x, f.z) - 1.0e-3 and WorldWater.floorAt(S, f.x, f.z) > WorldTerrain.groundY(S, f.x, f.z) + 1.0e-3:
					sea.under += 1
					sea.runs[k] += 1
					sea.longest = maxi(sea.longest, sea.runs[k])
				else:
					sea.runs[k] = 0
	var fine: int = 0
	var kinds: Dictionary = {}
	for i in range(WorldBiomes.fineCols.size()):
		kinds[int(WorldBiomes.fineCols[i])] = true
	return [str(SimHash.stateHash(S).gameplay), S.trees.size(), S.buildings.size(), kinds.size(), int(S.epoch.n) if S.epoch != null else -1, sea]


var sea_start: bool = false


## A column of the open sea, a few hundred units apart for each fighter k; NAN if the ring has none.
func sea_x(S: SimState, k: int) -> float:
	var n: int = 0
	for i in range(SimConst.NC):
		if S.base[i] < WorldWater.RESERVOIR_BASE and S.base[(i + 8) % SimConst.NC] < WorldWater.RESERVOIR_BASE and S.base[(i + SimConst.NC - 8) % SimConst.NC] < WorldWater.RESERVOIR_BASE:
			n += 1
			if n == 40 + 6 * k:
				return (float(i) + 0.5) * SimConst.COL
	return NAN


const SPAWN_TICKS: int = 30   # a match starts the pair at y 60 (sim/core/sim.gd), which in a lake or the sea is under the floor: he rises by row 9's rate and his own flight for the first ticks, so these are not read
const LONGEST: int = 12   # the most ticks in a row a free fighter may start below his floor: row 9's rise takes at most riseTicks (10) over the deepest lift


## The floor's reading of a match, for its line (only with the floor on): ticks over the sheet (the sea 75 or more deep) and in the waded water, and the longest run below his floor.
func sea_line(sea: Dictionary) -> String:
	if not WorldFill.floorOn():
		return ""
	return ", sea sheet %d, waded %d, below the floor %d (longest run %d%s)" % [int(sea.sheet), int(sea.waded), int(sea.under), int(sea.longest), "" if int(sea.longest) <= LONGEST else ", OVER " + str(LONGEST)]


func _init() -> void:
	var ticks: int = 900
	var hand: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		if a == "--b":
			WorldLand.setB(true)
		if a == "--fire":
			WorldFire.setOn(true)   # the fires in the forests on for this run (window 18; the data stays off)
		if a == "--floor":
			WorldFill.setSurface(true)   # the floor of a lake or the sea on for this run (lake-floor.md; the data stays off)
			WorldFill.setFloor(true)
			DirInterrupt.data()["water"]["enabled"] = true   # and the drop's half of the surfacing rule, which the floor needs
		if a == "--hand":
			hand = true
		if a == "--sea":
			sea_start = true   # with --floor: both fighters start over the open sea, so the soak fights on the sea's floor
		if a == "--rivers":
			WorldRivers.setOn(true)   # the rivers on for this run (window 14; the data stays off)
	var bad: int = 0
	var over: int = 0
	var n: int = 0
	if hand:
		for sd in range(1, 7):
			var h1: Array = match_hash({"intro": false}, ticks, sd)
			var h2: Array = match_hash({"intro": false}, ticks, sd)
			if h1[0] != h2[0]:
				bad += 1
			print("hand-made world, run %d: hash %s%s%s" % [sd, h1[0], ", same twice" if h1[0] == h2[0] else ", NOT the same twice", sea_line(h1[5])])
			if int(h1[5].longest) > LONGEST:
				over += 1
			n += 1
		print("GEN2 SOAK: %d match(es), %d not the same twice%s" % [n, bad, (", %d with a fighter below his floor more than %d ticks in a row" % [over, LONGEST]) if WorldFill.floorOn() else ""])
		quit()
		return
	for sd in [7, 3, 11, 25]:
		for touch in [0, 1, 2]:
			var turn: bool = (touch % 2) == 1
			var arena: Dictionary = {"cols": 2400}
			if turn:
				arena["turn"] = true
			var setup: Dictionary = {"planet": sd, "touch": touch, "arena": arena, "planetGen": 2, "intro": false}
			var a: Array = match_hash(setup, ticks)
			var again: bool = false
			if n % 3 == 0:
				var b: Array = match_hash(setup, ticks)
				again = b[0] == a[0]
				if not again:
					bad += 1
			print("seed %d touch %d turn %s: hash %s, %d trees, %d buildings, %d fine biomes, epoch %d%s%s" % [sd, touch, str(turn), a[0], a[1], a[2], a[3], a[4], (", same twice" if again else ""), sea_line(a[5])])
			if int(a[5].longest) > LONGEST:
				over += 1
			n += 1
	print("GEN2 SOAK: %d match(es), %d not the same twice%s" % [n, bad, (", %d with a fighter below his floor more than %d ticks in a row" % [over, LONGEST]) if WorldFill.floorOn() else ""])
	quit()
