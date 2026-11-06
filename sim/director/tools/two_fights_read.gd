extends SceneTree
## 2v2's read, Game Design's QA rows (docs/design/two-v-two.md, "What brings the fights together"): four computer fighters in two fights
## on the page's planet, cross and the director's 2v2 on (outside.enabled). Per match: how long all four are within spreadUnits of each
## other, the rescue flights (a computer fighter going to the other fight while its partner's on the brink), the brink's calls, blows
## from outside, beams stopped on someone else, rejoins, how it ended. Read only: it changes no data. Prints one ROW line a match, then
## a TOTAL line.
##   godot --headless --path . --script res://sim/director/tools/two_fights_read.gd -- <matches> <baseSeed> [--cap=36000] [--spread=15000]

func _init() -> void:
	var pos: Array = []
	var cap: int = 36000
	var spread: float = 15000.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cap="):
			cap = int(a.substr(6))
		elif a.begins_with("--spread="):
			spread = float(a.substr(9))
		else:
			pos.append(a)
	var n: int = int(pos[0]) if pos.size() > 0 else 2
	var seed0: int = int(pos[1]) if pos.size() > 1 else 1
	DirOutside.setForce(1)
	WorldClimate.useGen(3)
	WorldField.bakeStep(WorldField.of(WorldPlanet.make(7)), 1 << 40)
	var tot: Dictionary = {"matches": 0, "ticks": 0, "close": 0, "rescues": 0, "calls": 0, "hits": 0, "stops": 0, "rejoins": 0, "winnerFlights": 0}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {"p1": true, "p2": true, "p3": true, "p4": true}, {"intro": false, "fights": 2, "cross": true, "planet": 7, "planetGen": 3})
		var row: Dictionary = {"ticks": 0, "close": 0, "rescues": 0, "calls": 0, "hits": 0, "stops": 0, "winnerFlights": 0, "ended": ""}
		var going: Dictionary = {}   # keys -> 1 while that body's on a rescue, 2 while on a winner's flight
		for t in range(cap):
			SimCore.step(S)
			row.ticks += 1
			var bodies: Array = SimStage.bodies(S)
			var mid: float = SimStage.middle(S)
			var lo: float = INF
			var hi: float = -INF
			for f in bodies:
				var d: float = SimWrap.sdx(mid, f.x)
				lo = minf(lo, d)
				hi = maxf(hi, d)
			if hi - lo <= spread:
				row.close += 1
			var outs: Array = [S.out]
			for r in S.stage.fights:
				if r.out != null and r.out != S.out:
					outs.append(r.out)
			for o in outs:
				for e in o.fx:
					if String(e.type) != "cue":
						continue
					var k: String = String(e.kind)
					if k == "brink_call":
						row.calls += 1
					elif k == "outside" and String(e.text) == "hit":
						row.hits += 1
					elif k == "beam_stopped":
						row.stops += 1
				o.fx.clear()
				o.feed.clear()
			for f in bodies:
				var mode: int = 0
				if not f.out and f.state == "free":
					var P = DirOutside.partnerOf(S, f)
					var fi: int = SimStage.fightOf(S, f)
					var fight = S if fi == S.stage.cur else S.stage.fights[fi]
					if fight.game != null and fight.game.ko != null:
						mode = 2
					elif P != null and P.brink and SimStage.fightOf(S, P) != fi:
						mode = 1
				# Counted once a brink of his partner's (a rescue) and once a finished fight (a winner's flight), however it flickers.
				var P2 = DirOutside.partnerOf(S, f)
				var ep: String = f.keys + ":" + ("brink" if P2 != null and P2.brink else "")
				if mode == 1 and not going.has(ep):
					row.rescues += 1
					going[ep] = 1
				if P2 != null and not P2.brink:
					going.erase(f.keys + ":brink")
				if mode == 2 and not going.has(f.keys + ":won"):
					row.winnerFlights += 1
					going[f.keys + ":won"] = 1
			if SimCore.ended(S):
				row.ended = "team %s out at %.0f s" % [str(S.stage.over), float(row.ticks) / 60.0]
				break
		var rj: int = int(S.stage.rejoined)
		print("ROW match %d seed %d: %.0f s; all four within %.0f for %.1f%%; rescue flights %d, winner flights %d; brink calls %d; blows from outside %d; beams stopped %d; rejoins %d; %s" % [m, seed0 + m, float(row.ticks) / 60.0, spread, 100.0 * float(row.close) / maxf(1.0, float(row.ticks)), row.rescues, row.winnerFlights, row.calls, row.hits, row.stops, rj, row.ended if row.ended != "" else "not ended by the cap"])
		tot.matches += 1
		for k in ["ticks", "close", "rescues", "calls", "hits", "stops", "winnerFlights"]:
			tot[k] += int(row[k])
		tot.rejoins += rj
		SimCore.dispose(S)
	print("TOTAL %d matches: all four within %.0f for %.1f%% (Game Design: 25 to 50); rescue flights %.1f a match (2 to 4); winner flights %.1f; brink calls %.1f; blows from outside %.1f; beams stopped %.1f; rejoins %.1f" % [tot.matches, spread, 100.0 * float(tot.close) / maxf(1.0, float(tot.ticks)), float(tot.rescues) / float(tot.matches), float(tot.winnerFlights) / float(tot.matches), float(tot.calls) / float(tot.matches), float(tot.hits) / float(tot.matches), float(tot.stops) / float(tot.matches), float(tot.rejoins) / float(tot.matches)])
	DirOutside.setForce(-1)
	quit(0)
