extends SceneTree
## landt.gd: GD 10-26 item 36 step 2, a trace of the rallies that end "landed", AI v AI with the copy's data (rally,
## launch anywhere on). For each, since the rally's last send: did the AI draw no link (its keyed chase draw failed; no
## ki; drawn but never started, with what held it 20 ticks after the send), did its chase arrive after the landing, or
## did the catch not send him (the plan's pick)? With the last send (opening or link, the planner's pick, "short" for a
## journey of 30 ticks or less, and how the journey ended), the flight's ticks (send to his first land contact), the
## chase's start, the answers (flips, wall kicks, counter-rushes), and links a rally by item 36's count (both hands,
## the turn's send one, 6 for 6 or more).
##   godot --headless --path . --script res://landt.gd -- <matches> <seed0>

func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 5
	var seed0: int = int(a[1]) if a.size() > 1 else 1
	var cap: int = 54000
	var r := {"matches": n, "ends": {}, "landed": {}, "flightToLand": [], "noLinkFlight": [], "lateStart": [], "lateLand": [], "plans": {},
		"flips": 0, "flipsInRally": 0, "wallKicks": 0, "counterRush": {}, "turns": 0, "noLinkWhy": {}, "notStarted": {}, "lastSend": {}, "journeys": [], "hist": {}}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {})
		var t: int = 0
		var sendT := [-1, -1]
		var landT := [-1, -1]
		var chS := [-1, -1]
		var chE := ["", ""]
		var plan := ["", ""]
		var ln := [0, 0]
		var open := [false, false]
		var snap := ["", ""]
		var jEnd := [-1, -1]
		var lastPlan := ["", ""]
		var opening := [false, false]
		var jk := ["", ""]
		var cur: int = 0
		var turnT: int = -1
		while t < cap and not (S.game.ko != null and S.game.koT > 3.0):
			SimCore.step(S, null)
			t += 1
			for A in range(2):
				if open[A] and sendT[A] >= 0 and jEnd[A] < 0 and S.fighters[1 - A].state != "launched":
					jEnd[A] = t
				if open[A] and sendT[A] >= 0 and chS[A] < 0 and t - sendT[A] == 20:
					var F = S.fighters[A]
					var D = S.fighters[1 - A]
					var ex = S.dirS.ex
					snap[A] = "D " + str(D.state) + "; A " + str(F.state) + (" brawl" if DirBrawl.inBrawl(S, F) else "") + (" zip" if DirZip.zipping(F) else "") + (" rush" if F.rush != null else "") + (" ex " + str(ex.kind) if ex != null else "") + "; seen " + str(DirChase._g(F, DirChase.CH_SEEN) == D.launchN + 1) + " at " + str(DirChase._g(F, DirChase.CH_AT)) + "; draw " + str(SimRng.keyed(int(S.game.seed), "chase.ai", D.launchN * 4 + A) < float(DirRally._ai().get("link", 0.0))) + "; ki " + str(int(F.ki / 10.0) * 10) + (" ln moved" if D.launchN != ln[A] else "")
			for e in S.out.fx:
				var ty: String = str(e.type)
				var who: int = int(e.actor)
				if who < 0 or who > 1:
					continue
				if ty == "land":
					var A: int = 1 - who
					if open[A] and sendT[A] >= 0 and landT[A] < 0:
						landT[A] = t
					continue
				if ty == "journey_end":
					if open[1 - who] and sendT[1 - who] >= 0:
						jk[1 - who] = str(e.kind)
					continue
				if ty == "launch_plan":
					plan[who] = str(e.chosen)
					continue
				if ty != "cue":
					continue
				var k: String = str(e.kind)
				var tx: String = str(e.text)
				if k == "rally_link":
					if tx != "send" or turnT == t:
						cur += 1
					else:
						cur = 0
					open[who] = true
					sendT[who] = t
					snap[who] = ""
					landT[who] = -1
					chS[who] = -1
					chE[who] = ""
					lastPlan[who] = plan[who]
					plan[who] = ""
					jEnd[who] = -1
					jk[who] = ""
					opening[who] = tx == "send"
					ln[who] = int(S.fighters[1 - who].launchN)
				elif k == "chase":
					if tx == "start":
						chS[who] = t
						chE[who] = ""
					else:
						chE[who] = tx
				elif k == "recoil" and tx == "flip":
					r.flips += 1
					if open[1 - who]:
						r.flipsInRally += 1
				elif k == "wall_kick":
					r.wallKicks += 1
				elif k == "counter_rush":
					var src: String = "wall_kick" if tx == "wall_kick" else "flip_or_tech"
					var key: String = src + (" in a rally" if open[1 - who] else "")
					r.counterRush[key] = int(r.counterRush.get(key, 0)) + 1
				elif k == "rally_turn":
					r.turns += 1
					turnT = t
				elif k == "rally_end":
					r.ends[tx] = int(r.ends.get(tx, 0)) + 1
					if tx != "turned":
						var hk: String = str(mini(cur, 6))
						r.hist[hk] = int(r.hist.get(hk, 0)) + 1
					if tx == "landed" and sendT[who] >= 0:
						var fl: int = landT[who] - sendT[who] if landT[who] >= 0 else -1
						r.flightToLand.append(fl)
						var cls: String
						if chS[who] < 0:
							cls = "no link drawn"
							var share: float = float(DirRally._ai().get("link", 0.0))
							var drew: bool = SimRng.keyed(int(S.game.seed), "chase.ai", ln[who] * 4 + who) < share
							var why: String = "draw failed" if not drew else ("no ki" if S.fighters[who].ki < 20.0 else "drawn, not started")
							r.noLinkWhy[why] = int(r.noLinkWhy.get(why, 0)) + 1
							if why == "drawn, not started":
								r.notStarted[snap[who]] = int(r.notStarted.get(snap[who], 0)) + 1
							if drew:
								r.noLinkFlight.append(fl)
						elif chE[who] == "landing":
							cls = "chase arrived after the landing"
							r.lateStart.append(chS[who] - sendT[who])
							r.lateLand.append(fl)
						elif chE[who] == "catch":
							cls = "caught, no send"
							r.plans[plan[who]] = int(r.plans.get(plan[who], 0)) + 1
						else:
							cls = "chase " + (chE[who] if chE[who] != "" else "still on")
						r.landed[cls] = int(r.landed.get(cls, 0)) + 1
						var jt: int = jEnd[who] - sendT[who] if jEnd[who] >= 0 else -1
						var sk: String = ("opening " if opening[who] else "link ") + lastPlan[who] + (" short" if jt >= 0 and jt <= 30 else "") + " (" + jk[who] + ")"
						r.lastSend[sk] = int(r.lastSend.get(sk, 0)) + 1
						r.journeys.append(jt)
					open[who] = false   # (a turned rally goes on in the other's hands: his send opens it)
					sendT[who] = -1
			S.out.fx.clear()
			S.out.feed.clear()
		SimCore.dispose(S)
	for key in ["journeys", "flightToLand", "noLinkFlight", "lateStart", "lateLand"]:
		var arr: Array = r[key]
		arr.sort()
		r[key + "Median"] = arr[arr.size() / 2] if arr.size() > 0 else -1
		r[key + "N"] = arr.size()
		r.erase(key)
	print(JSON.stringify(r))
	quit()
