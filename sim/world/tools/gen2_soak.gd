extends SceneTree
# Gen 2 matches played through (World, window 4): AI against AI on gen 2 planets (the whole of gen 2: climate, profiles, trees, landforms, sites), some with the calm-moment turn on, a few ticks each, to
# see that nothing errors and that a match is the same twice. Prints a line a match.
#   godot --headless --path . --script res://sim/world/tools/gen2_soak.gd -- --ticks=900     (--b: with land.json's b switch on for the run, window 12; --rivers: with rivers.json on, window 14; --fire: with fire.json on, window 18; --floor: with the floor of a lake or the sea on, and the surfacing rule it needs; --hand: the hand-made world, six seeds, instead of the planets)
func match_hash(setup: Dictionary, ticks: int, seed: int = 1) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, setup)
	for t in range(ticks):
		SimCore.step(S)
	var fine: int = 0
	var kinds: Dictionary = {}
	for i in range(WorldBiomes.fineCols.size()):
		kinds[int(WorldBiomes.fineCols[i])] = true
	return [str(SimHash.stateHash(S).gameplay), S.trees.size(), S.buildings.size(), kinds.size(), int(S.epoch.n) if S.epoch != null else -1]


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
		if a == "--rivers":
			WorldRivers.setOn(true)   # the rivers on for this run (window 14; the data stays off)
	var bad: int = 0
	var n: int = 0
	if hand:
		for sd in range(1, 7):
			var h1: Array = match_hash({"intro": false}, ticks, sd)
			var h2: Array = match_hash({"intro": false}, ticks, sd)
			if h1[0] != h2[0]:
				bad += 1
			print("hand-made world, run %d: hash %s%s" % [sd, h1[0], ", same twice" if h1[0] == h2[0] else ", NOT the same twice"])
			n += 1
		print("GEN2 SOAK: %d match(es), %d not the same twice" % [n, bad])
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
			print("seed %d touch %d turn %s: hash %s, %d trees, %d buildings, %d fine biomes, epoch %d%s" % [sd, touch, str(turn), a[0], a[1], a[2], a[3], a[4], (", same twice" if again else "")])
			n += 1
	print("GEN2 SOAK: %d match(es), %d not the same twice" % [n, bad])
	quit()
