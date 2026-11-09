extends SceneTree
## Easy matches the player's pace (ai.json levels.easy.brawl.paceMatch, off; docs/director/pending/pace-match/; gauntlet-plan.md section 6):
##   godot --headless --path . --script res://sim/director/tools/pace_check.gd
## - on: a player pressing every 20 ticks meets easy's strings at 20; every 40 (thumb pace), the ceiling 30; a masher (every 8), the floor 12
## - on: only guards, or one press in the window, the ceiling; presses older than the window don't count (the ceiling)
## - on: against another computer, noHuman (27)
## - off: as drawn (12), and nothing is written on the player
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	DirAI.level = "easy"
	var bl: Dictionary = DirAI.lv().get("brawl", {})
	var mp: Dictionary = bl.get("paceMatch", {})
	var was: bool = bool(mp.get("enabled", false))
	mp["enabled"] = true
	var r20: Array = _play(20, false, 0)
	var r40: Array = _play(40, false, 0)
	var r8: Array = _play(8, false, 0)
	var guards: Array = _play(40, true, 0)
	var one: Array = _play(170, false, 0)
	var old: Array = _play(10, false, 400)
	var ai: int = _vsComputer()
	mp["enabled"] = false
	var off: Array = _play(20, false, 0)
	mp["enabled"] = was
	DirAI.level = ""
	var tg: int = int(bl.get("tapGap", 12))
	print("      easy's gap against him (his recent gap): every 20 %s, 40 %s, 8 %s; guards only %s; one press %s; old presses %s; a computer %d; off %s" % [str(r20), str(r40), str(r8), str(guards), str(one), str(old), ai, str(off)])
	_expect(r20[1] == 20 and r20[0] == 20, "on: a player pressing every 20 ticks meets easy at 20")
	_expect(r40[1] == int(mp.get("ceiling", 30)), "on: at thumb pace (every 40) the ceiling, %d" % r40[1])
	_expect(r8[1] == int(mp.get("floor", 12)), "on: a masher (every 8) meets the floor, %d" % r8[1])
	_expect(guards[1] == int(mp.get("ceiling", 30)) and one[1] == int(mp.get("ceiling", 30)), "on: only guards, or one press in the window: the ceiling (never passive)")
	_expect(old[1] == int(mp.get("ceiling", 30)), "on: presses older than the window don't count")
	_expect(ai == int(mp.get("noHuman", 27)), "on: against another computer, noHuman (%d)" % ai)
	_expect(off[1] == tg and off[2] == off[3], "off: as drawn (%d), and nothing written on the player" % off[1])
	print("PACE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## A player (slot 0) presses every `every` ticks for 300 ticks (lights, or guard presses), then waits `idle` ticks: [his recent gap, easy's
## gap against him for a drawn tapGap, his dirI size before, after].
func _play(every: int, guard: bool, idle: int) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 3, {"p1": false, "p2": true}, {"intro": false})
	var P = S.fighters[0]
	var n0: int = P.act.dirI.size()
	for t in range(300 + idle):
		S.tick += 1
		P.input = SimIntent.new()
		if t < 300 and t % every == 0:
			if guard:
				P.input.guardPress = true
			else:
				P.input.light = true
		DirPace.note(S)
	var bl: Dictionary = DirAI.lv().get("brawl", {})
	var r: Array = [DirPace.recentGap(S, P, float(bl.get("paceMatch", {}).get("windowSec", 3.0))), DirPace.gap(S, P, int(bl.get("tapGap", 12)), bl), n0, P.act.dirI.size()]
	SimCore.dispose(S)
	return r


func _vsComputer() -> int:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 3, {"p1": true, "p2": true}, {"intro": false})
	var bl: Dictionary = DirAI.lv().get("brawl", {})
	var g: int = DirPace.gap(S, S.fighters[0], int(bl.get("tapGap", 12)), bl)
	SimCore.dispose(S)
	return g
