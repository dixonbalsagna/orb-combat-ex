extends SceneTree
# the destruction hook, a match log: what a match does to buildings, and how near it stands to them.
# args: seed0 seed1 mode (default | crossing)   output: DM lines (per-match means) and DMD (distance histogram)
func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var mode: String = a[2] if a.size() > 2 else "default"
	var n: int = 0
	var cnt := {}
	var plans := {}
	var chainLen := {}
	var outc := {}
	var stg := {}
	var falls: float = 0.0
	var lenSum: float = 0.0
	var koN: int = 0
	var samples: int = 0
	var edges := [150.0, 400.0, 800.0, 1500.0, 3000.0, 6000.0, 12000.0]
	var within := [0, 0, 0, 0, 0, 0, 0]
	var spanSum: float = 0.0
	var civ: float = 0.0
	var lost: float = 0.0
	var firstHit: Array = []
	var tierHits := {}
	var civLost: float = 0.0
	var failWarn: float = 0.0
	var hurtPairs: float = 0.0
	var hurtDmg: float = 0.0
	var tips: float = 0.0
	var failFall: float = 0.0
	var chain2: float = 0.0
	var tb := [30.0, 60.0, 120.0, 240.0, 1.0e9]
	var tbN := [0, 0, 0, 0, 0]
	var tbNear := [0, 0, 0, 0, 0]
	for sd in range(int(a[0]), int(a[1])):
		var S := SimCore.createSim()
		var setup := {}
		if mode == "crossing":
			setup = {"start": "crossing"}
		SimCore.newMatch(S, sd, {}, setup)
		SimGolden.applyArm("default", S.fighters)
		var steps: int = 0
		var xmin: float = 1.0e30
		var xmax: float = -1.0e30
		var x0: float = (S.fighters[0].x + S.fighters[1].x) * 0.5
		var hit1: float = -1.0
		var lastLink: Dictionary = {}
		while S.game.ko == null and steps < 54000:
			SimCore.step(S, null)
			for e in S.out.fx:
				var t: String = str(e.type)
				if t == "launch_plan":
					plans[str(e.chosen)] = plans.get(str(e.chosen), 0) + 1
				elif t == "building_hit":
					cnt["building_hit"] = cnt.get("building_hit", 0) + 1
					outc[str(e.outcome)] = outc.get(str(e.outcome), 0) + 1
					if int(e.link) == 1 and hit1 < 0.0:
						hit1 = S.T
					chainLen[str(int(e.link))] = chainLen.get(str(int(e.link)), 0) + 1
					var bb = S.buildings[int(e.b)]
					var tw: String = "house" if bb.floors < 5 else "tower"
					var ow: int = int(e.owner)
					var tr: int = int(S.fighters[ow].tier) if ow >= 0 else 0
					var how: String = str(e.outcome)
					if how in ["punch", "collapse", "pancake", "heavy"] and float(e.keep) == 0.0:
						how = "lodge"
					var kk: String = "t%d %s %s" % [tr, tw, how]
					tierHits[kk] = tierHits.get(kk, 0) + 1
					if int(e.link) == 2:
						chain2 += 1.0
				elif t == "floor_hit":
					cnt["floor_" + str(e.outcome)] = cnt.get("floor_" + str(e.outcome), 0) + 1
					if str(e.outcome) == "punch":
						cnt["floors_punched"] = cnt.get("floors_punched", 0) + int(e.n)
				elif t == "building_failing":
					cnt["building_failing"] = cnt.get("building_failing", 0) + 1
					failWarn += float(e.t_warn)
					if int(e.n) != 0:
						tips += 1.0
					failFall += float(e.t_fall)
				elif t == "lodge":
					cnt["lodge"] = cnt.get("lodge", 0) + 1
				elif t == "floors_fall":
					cnt["pancakes"] = cnt.get("pancakes", 0) + 1
					cnt["floors_pancaked"] = cnt.get("floors_pancaked", 0) + int(e.n)
				elif t == "building_stage":
					var k: String = "%d>%d" % [int(e.from), int(e.to)]
					stg[k] = stg.get(k, 0) + 1
					cnt["stage_events"] = cnt.get("stage_events", 0) + 1
				elif t == "building_fall":
					falls += 1.0
			S.out.fx.clear()
			S.out.feed.clear()
			steps += 1
			if steps % 60 == 0:
				var mx: float = (S.fighters[0].x + S.fighters[1].x) * 0.5
				xmin = minf(xmin, mx)
				xmax = maxf(xmax, mx)
				var best: float = 1.0e30
				for b in S.buildings:
					if not b.alive:
						continue
					best = minf(best, maxf(absf(SimWrap.sdx(mx, b.x)) - b.w * 0.5, 0.0))
				samples += 1
				for q in range(tb.size()):
					if S.T <= tb[q]:
						tbN[q] += 1
						if best <= 1500.0:
							tbNear[q] += 1
						break
				for i in range(edges.size()):
					if best <= edges[i]:
						within[i] += 1
		if hit1 >= 0.0:
			firstHit.append(hit1)
		var gone: int = 0
		for b in S.buildings:
			if b.failHurt.size() >= 2:
				for q2 in range(2):
					if b.failHurt[q2] > 0.0:
						hurtPairs += 1.0
						hurtDmg += b.failHurt[q2]
			if not b.alive:
				gone += 1
		lost += float(gone)
		civLost += S.world.casualties / S.world.pop0
		lenSum += S.T
		spanSum += absf(SimWrap.sdx(x0, xmax)) + absf(SimWrap.sdx(x0, xmin))
		n += 1
		SimCore.dispose(S)
	var o := {}
	for k in cnt:
		o[k] = snappedf(float(cnt[k]) / n, 0.01)
	var p := {}
	for k in plans:
		p[k] = snappedf(float(plans[k]) / n, 0.01)
	print("DM mode %s matches %d  length %.0f s  structures lost %.1f  falls %.2f a match" % [mode, n, lenSum / n, lost / n, falls / n])
	print("DM events a match: ", o)
	print("DM launch plans a match: ", p)
	var th: Array = tierHits.keys()
	th.sort()
	var ths: Array = []
	for k in th:
		ths.append("%s %.2f" % [k, float(tierHits[k]) / n])
	print("DM body hits a match by the fighter's tier, kind and outcome: ", "; ".join(ths))
	print("DM failing: %.2f a match, warn %.2f s and fall %.2f s on average" % [float(cnt.get("building_failing", 0)) / n, failWarn / maxf(float(cnt.get("building_failing", 0)), 1.0), failFall / maxf(float(cnt.get("building_failing", 0)), 1.0)])
	print("DM fighters hurt by a falling stack %.2f a match (%.0f damage in all, per match %.1f); tipped %.0f%% of the failures" % [hurtPairs / n, hurtDmg, hurtDmg / n, 100.0 * tips / maxf(float(cnt.get("building_failing", 0)), 1.0)])
	print("DM people lost %.1f%%; chains of two buildings or more %.2f a match" % [100.0 * civLost / n, chain2 / n])
	print("DM hits by link (all matches): ", chainLen, "  outcomes: ", outc)
	print("DM stage events (all matches): ", stg)
	var pct: Array = []
	for i in range(edges.size()):
		pct.append("%.0f units %.0f%%" % [edges[i], 100.0 * float(within[i]) / float(maxi(samples, 1))])
	print("DMD share of the time the pair's middle is within: ", ", ".join(pct))
	print("DMD the pair's middle roams a total of %.0f units a match (x range both ways from the start)" % (spanSum / n))
	var tbs: Array = []
	var tl := ["0-30 s", "30-60 s", "1-2 min", "2-4 min", "4 min +"]
	for q in range(tb.size()):
		tbs.append("%s %.0f%%" % [tl[q], 100.0 * float(tbNear[q]) / float(maxi(tbN[q], 1))])
	print("DMD share of the time within 1,500 units of a building, by match time: ", ", ".join(tbs))
	firstHit.sort()
	if firstHit.size() > 0:
		print("DMD first building hit at %.0f s median (%d of %d matches have one)" % [firstHit[firstHit.size() / 2], firstHit.size(), n])
	else:
		print("DMD no match had a building hit")
	quit(0)
