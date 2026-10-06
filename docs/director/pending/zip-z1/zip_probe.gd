extends SceneTree
## Read-only probe for the zip (slice Z1; docs/design/melee-press-feel.md section 2c, "For QA, on zips").
## Matches of the AI against itself, or of a scripted zipper (slot 0: he keeps the mid band and presses LT with X or
## Y every `every` ticks, with a stick drawn for the exit) against the AI. It reports:
##  - zips started, by button and by level of ending: done, stopped, outrun, shot, down, caught, countered;
##  - of the zips that reached the rival: the blow landed clean, was blocked, or never came (countered, or caught first);
##  - the hard tests: a zip's price and its ticks in reach against the table; a way in or out under Legal's floor;
##    an exit point over the cap from the rival, or inside the ground or a building; a brawl announced as caught or
##    countered with no zip ending that way on the same tick;
##  - zips a minute, the ki spent on zips as a share of all ki spent, and the match's length.
## godot --headless --path . --script res://sim/director/tools/zip_probe.gd -- <matches> <baseSeed> [--level=medium]
##   [--me=ai|zipper] [--every=90] [--btn=x|y|mix] [--max=900]
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
	var base: int = int(args[1]) if args.size() > 1 else 1
	var level := "medium"
	var meAi := true
	var every := 90
	var btn := "mix"
	var maxT := 900.0
	for a in args:
		if a.begins_with("--level="):
			level = a.substr(8)
		if a.begins_with("--me="):
			meAi = a.substr(5) == "ai"
		if a.begins_with("--every="):
			every = int(a.substr(8))
		if a.begins_with("--btn="):
			btn = a.substr(6)
		if a.begins_with("--max="):
			maxT = float(a.substr(6))
	load("res://sim/director/ai.gd").set("level", level)
	var Z = load("res://sim/director/zip.gd")
	var cz: Dictionary = Z.cfg()
	var started := {"x": 0, "y": 0}
	var ends: Dictionary = {}
	var arrived := 0
	var clean := 0
	var blocked := 0
	var badPrice := 0
	var badReach := 0
	var underFloor := 0
	var badExit := 0
	var badBrawl := 0
	var homeInside := 0
	var kiZip := 0.0
	var kiAll := 0.0
	var secs := 0.0
	var wins := 0
	var lens: Array = []
	var exits: Dictionary = {}
	var passes: Dictionary = {}
	var reads: Dictionary = {}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, base + m, {"p1": meAi, "p2": true}, {"v2": [not meAi, false]})
		var fs: Array = S.fighters
		var kiPrev: Array = [fs[0].ki, fs[1].ki]
		var phPrev: Array = ["", ""]
		var reachTicks: Array = [0, 0]
		var blowSeen: Array = [false, false]
		var pressAt := -100000
		var ticks := 0
		var stickPick := 0
		while S.T < maxT and not (S.game.ko != null and S.game.koT > 3.0) and ticks < 400000:
			ticks += 1
			var it = null
			if not meAi:
				it = SimIntent.new()
				var me = fs[0]
				var ai = fs[1]
				var dx: float = SimWrap.sdx(me.x, ai.x)
				var dy: float = ai.y - me.y
				var d: float = SimDetMath.hypot(dx, dy) / 75.0
				if me.act.formReady:
					it.transform = true
				if Z.zipping(me):
					it.stanceMask = 8
					var tx: float = signf(dx)
					if stickPick == 1:
						it.mx = tx
					elif stickPick == 2:
						it.my = 1.0
					elif stickPick == 3:
						it.mx = -tx
				elif S.dirS.ex == null:
					it.mx = signf(dx) if d > 7.5 else (-signf(dx) if d < 5.0 else 0.0)
					it.my = signf(dy) if absf(dy) > 40.0 else 0.0
					if S.tick - pressAt >= every and d >= 4.0 and d <= 9.0 and me.state == "free" and me.stunTicks == 0:
						var heavy: bool = btn == "y" or (btn == "mix" and (SimRng.keyed(base + m, "probe.zip", ticks) < 0.3))
						it.stanceMask = 8
						it.heavy = heavy
						it.light = not heavy
						pressAt = S.tick
						stickPick = int(SimRng.keyed(base + m, "probe.exit", ticks) * 4.0) % 4
				else:
					# caught or countered: he mashes, as a player in a brawl would
					it.light = ticks % 8 == 0
					it.mx = signf(dx) if absf(dx) > 110.0 else 0.0
			var ki0: Array = [fs[0].ki, fs[1].ki]
			SimCore.step(S, [it, null])
			var endNow: Dictionary = {}
			for e in S.out.fx:
				if e.type != "cue":
					continue
				var who: int = int(e.actor)
				if e.kind == "zip_light" or e.kind == "zip_heavy":
					var k: String = "y" if e.kind == "zip_heavy" else "x"
					started[k] = int(started[k]) + 1
					var price: float = float((cz.heavy if k == "y" else cz.strike).ki)
					kiZip += price
					if absf((float(ki0[who]) - fs[who].ki) - price) > 1.5:
						badPrice += 1
					reachTicks[who] = 0
					blowSeen[who] = false
				elif e.kind == "zip_end":
					ends[e.text] = int(ends.get(e.text, 0)) + 1
					endNow[e.text] = true
				elif e.kind == "zip_out":
					exits[e.text] = int(exits.get(e.text, 0)) + 1
					var o = fs[1 - who]
					var dd: float = SimDetMath.hypot(SimWrap.sdx(o.x, e.x), e.y - o.y) / 75.0
					# the cap is for an exit the stick picked; home is where he started, wherever the rival is by now
					var inside: bool = WorldStructures.blockedAt(S, e.x, e.y + 75.0, 0.0, 0.0)
					if e.text == "home":
						if inside:
							homeInside += 1   # he started inside a building's reach, and goes back there
					elif dd > float(cz.exit.capBh) + 0.05 or inside:
						badExit += 1
				elif e.kind == "brawl_start" and (e.text == "caught" or e.text == "countered") and not endNow.has(e.text):
					badBrawl += 1
			for e in S.out.fx:
				if e.type == "damage" and e.amount > 0.0:
					var at: int = int(e.attacker)
					if phPrev[at] == "reach" or (not Z.read(S, fs[at]).is_empty() and Z.read(S, fs[at]).phase == "reach"):
						if not blowSeen[at]:
							blowSeen[at] = true
							if e.kind == "guard":
								blocked += 1
							else:
								clean += 1
			for s in range(2):
				var rd: Dictionary = Z.read(S, fs[s])
				var ph: String = String(rd.get("phase", ""))
				if ph == "reach" and phPrev[s] != "reach":
					arrived += 1
					reads[rd.reading] = int(reads.get(rd.reading, 0)) + 1
					# Legal's floor on the way in: the ticks flown against the distance flown
					if int(rd["in"]) < maxi(int(cz.floor.minTicks), int(ceil((float(rd.dist_bh) - 1.0) / float(cz.floor.bhPerTick)))):
						underFloor += 1
				if ph == "out" and phPrev[s] != "out":
					passes[String(rd.pass) if String(rd.pass) != "" else "straight"] = int(passes.get(String(rd.pass) if String(rd.pass) != "" else "straight", 0)) + 1
					var path: float = SimDetMath.hypot(SimWrap.sdx(fs[s].x, float(rd.x)), float(rd.y) - fs[s].y) / 75.0
					if int(rd.out) < maxi(int(cz.floor.minTicks), int(ceil(path / float(cz.floor.bhPerTick)))):
						underFloor += 1
				phPrev[s] = ph
				if fs[s].ki < float(ki0[s]):
					kiAll += float(ki0[s]) - fs[s].ki
			S.out.fx.clear()
			S.out.feed.clear()
		secs += S.T
		lens.append(S.T)
		if S.game.ko != null and S.game.ko == fs[1]:
			wins += 1
	lens.sort()
	var total: int = int(started.x) + int(started.y)
	print(JSON.stringify({
		"n": n, "level": level, "me": "ai" if meAi else "zipper", "wins": wins, "medianSec": snappedf(float(lens[lens.size() / 2]), 0.1),
		"zips": total, "byButton": started, "zipsPerMin": snappedf(float(total) / maxf(1.0, secs) * 60.0, 0.01),
		"ends": ends, "arrived": arrived, "clean": clean, "blocked": blocked, "readings": reads, "exits": exits, "passes": passes,
		"cleanShareOfArrived": snappedf(float(clean) / maxf(1.0, float(arrived)), 0.001),
		"cleanShare": snappedf(float(clean) / maxf(1.0, float(total)), 0.001),
		"blockedShare": snappedf(float(blocked) / maxf(1.0, float(total)), 0.001),
		"shotShare": snappedf(float(int(ends.get("shot", 0))) / maxf(1.0, float(total)), 0.001),
		"stoppedShare": snappedf(float(int(ends.get("stopped", 0))) / maxf(1.0, float(total)), 0.001),
		"counteredShare": snappedf(float(int(ends.get("countered", 0))) / maxf(1.0, float(total)), 0.001),
		"caughtShare": snappedf(float(int(ends.get("caught", 0))) / maxf(1.0, float(total)), 0.001),
		"kiOnZipsShare": snappedf(kiZip / maxf(1.0, kiAll), 0.001),
		"hard": {"price": badPrice, "underFloor": underFloor, "badExit": badExit, "brawlWithoutCatch": badBrawl}, "homeExitsInsideABuilding": homeInside,
	}))
	quit()
