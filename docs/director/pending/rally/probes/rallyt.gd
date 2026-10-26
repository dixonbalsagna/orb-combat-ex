extends SceneTree
## rallyt.gd: Game Design's rally rows (rulings-2026-10-23d §7), AI v AI with the copy's data (rally.enabled and launch
## anywhere on), to the KO or --ticks. From a copy's root: godot --headless --path . --script res://rallyt.gd -- <matches> <seed0>
## Reads, from the cues: dazes a match and by source; sells; rallies a match (opened, and turns); links a rally (the
## median) and by kind; two links of one kind in a row (share of links); rallies that ended right after a tech by itself
## (item 8's repetition); rallies that turned at least once; the time in rallies against match time; and match lengths.

func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 5
	var seed0: int = int(a[1]) if a.size() > 1 else 1
	var cap: int = 54000
	for s in a:
		if s.begins_with("--ticks="):
			cap = int(s.substr(8))
	var r := {"matches": n, "dazes": 0, "dazeBy": {}, "sells": 0, "rallies": 0, "turnSends": 0, "links": 0, "linkKinds": {}, "repeatLinks": 0,
		"techs": 0, "autoTechs": 0, "chases": {}, "ends": {}, "endsAfterAuto": 0, "ralliesTurned": 0, "rallyTicks": 0, "ticks": 0, "kos": 0, "lens": [], "perRally": []}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {})
		var t: int = 0
		var lastKind := ["", ""]
		var lastAuto := [false, false]
		var turnedAt := [-1, -1]
		while t < cap and not (S.game.ko != null and S.game.koT > 3.0):
			SimCore.step(S, null)
			t += 1
			for e in S.out.fx:
				if String(e.type) != "cue":
					continue
				var k: String = String(e.kind)
				var tx: String = String(e.text)
				var who: int = int(e.actor)
				if k == "daze" and tx == "start":
					r.dazes += 1
					var src: String = String(e.source)
					r.dazeBy[src] = int(r.dazeBy.get(src, 0)) + 1
				elif k == "chase":
					r.chases[tx] = int(r.chases.get(tx, 0)) + 1   # start, catch, landing, stopped (every chase, in a rally or not)
				elif k == "sell":
					r.sells += 1
				elif k == "rally_turn":
					if who >= 0 and who < 2:
						turnedAt[who] = t   # the rally_link send that follows at this tick is the turn's
				elif k == "rally_link":
					if tx == "send":   # the opening send (n 0), or the turn's
						if who >= 0 and who < 2 and turnedAt[who] == t:
							r.turnSends += 1   # the same rally, changing hands
						else:
							r.rallies += 1
						if who >= 0 and who < 2:
							lastKind[who] = ""
							lastAuto[who] = false
					else:
						r.links += 1
						var lk: String = String(e.source) if String(e.source) != "" else tx   # an own link is its own kind
						r.linkKinds[lk] = int(r.linkKinds.get(lk, 0)) + 1
						if who >= 0 and who < 2:
							if lastKind[who] == lk:
								r.repeatLinks += 1
							lastKind[who] = lk
				elif k == "rally_tech":
					r.techs += 1
					var att: int = int(e.target)
					if float(e.k) > 0.0:
						r.autoTechs += 1
						if att >= 0 and att < 2:
							lastAuto[att] = true
				elif k == "rally_end":
					var why: String = tx
					r.ends[why] = int(r.ends.get(why, 0)) + 1
					r.rallyTicks += int(e.dur)
					if why == "turned":
						continue   # it goes on in the other's hands
					r.perRally.append(int(e.n))   # (the last hands' links)
					if int(e.k) > 0:
						r.ralliesTurned += 1
					if why == "teched" and who >= 0 and who < 2 and lastAuto[who]:
						r.endsAfterAuto += 1
					if who >= 0 and who < 2:
						lastAuto[who] = false
			S.out.fx.clear()
			S.out.feed.clear()
		r.ticks += t
		r.lens.append(snappedf(float(t) / 60.0, 1.0))
		if S.game.ko != null:
			r.kos += 1
		SimCore.dispose(S)
	r.perRally.sort()
	var nr: int = r.perRally.size()
	r["linksMedian"] = r.perRally[nr / 2] if nr > 0 else 0
	r["dazesAMatch"] = snappedf(float(r.dazes) / float(n), 0.1)
	r["ralliesAMatch"] = snappedf(float(r.rallies) / float(n), 0.1)
	r["repeatShare"] = snappedf(float(r.repeatLinks) / maxf(1.0, float(r.links)), 0.001)
	r["endedByRepetition"] = snappedf(float(r.endsAfterAuto) / maxf(1.0, float(nr)), 0.001)
	r["turnedShare"] = snappedf(float(r.ralliesTurned) / maxf(1.0, float(nr)), 0.001)
	r["rallyTimeShare"] = snappedf(float(r.rallyTicks) / maxf(1.0, float(r.ticks)), 0.001)
	r["minutes"] = snappedf(float(r.ticks) / 3600.0, 0.1)
	r.erase("perRally")
	print(JSON.stringify(r))
	quit()
