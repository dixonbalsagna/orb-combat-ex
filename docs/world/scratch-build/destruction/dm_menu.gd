extends SceneTree
# the destruction hook, the brunt menu: at sampled moments of a match, which BUILDING SMASH plans exist for each tier, how long a chain
# they make, what each link does (floors punched, what stops it). Pure lookahead (WorldBrunt.aim); nothing is changed.
# args: seed0 seed1 mode (default | crossing) force
func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var mode: String = a[2] if a.size() > 2 else "crossing"
	var force: float = float(a[3]) if a.size() > 3 else 2000.0
	var res := {}
	for t in [1, 2, 3, 4, 5]:
		res[t] = {"samples": 0, "withPlan": 0, "cands": 0, "plans": 0, "len": {}, "floors": 0, "deaths": 0.0, "stop": {"cap": 0, "building": 0, "no_next": 0}, "levelled": 0, "bestLen": 0, "links": {}, "ratio": 0.0, "nlinks": 0, "spN": 0.0, "keep": 0.0}
	for sd in range(int(a[0]), int(a[1])):
		var S := SimCore.createSim()
		var setup := {}
		if mode == "crossing":
			setup = {"start": "crossing"}
		SimCore.newMatch(S, sd, {}, setup)
		SimGolden.applyArm("default", S.fighters)
		var steps: int = 0
		while S.game.ko == null and steps < 7200:
			SimCore.step(S, null)
			S.out.fx.clear()
			S.out.feed.clear()
			steps += 1
			if steps % 180 != 0:
				continue
			for ai in range(2):
				var A = S.fighters[ai]
				var D = S.fighters[1 - ai]
				var cand: Array = WorldBrunt.candidates(S, D)
				for t in [1, 2, 3, 4, 5]:
					var tier: float = float(mini(t, 4))
					var fa := {"tier": tier}
					var tierF: float = 1.0 + A.ld.launch * (tier - 1.0)
					var r: Dictionary = res[t]
					r.samples += 1
					r.cands += cand.size()
					var best: Array = []
					var bestScore: float = -1.0
					for bi in cand:
						var plan = WorldBrunt.aim(S, fa, D, S.buildings[bi], force, tierF, t == 5)
						if plan == null:
							continue
						r.plans += 1
						var ch: Array = plan.brunt.chain
						var sc: float = float(ch.size()) * 1000.0 + plan.brunt.deaths
						if sc > bestScore:
							bestScore = sc
							best = ch
					if best.is_empty():
						continue
					r.withPlan += 1
					var L: int = best.size()
					r.len[str(L)] = r.len.get(str(L), 0) + 1
					var fl: int = 0
					for e in best:
						var oc: Dictionary = WorldBrunt.outcomeOf(S, S.buildings[e.b], e.y, e.spN, tier)
						var lk: String = ("T:" if S.buildings[e.b].floors >= WorldBrunt.FLOORS_MIN else "h:") + str(oc.outcome)
						r.links[lk] = r.links.get(lk, 0) + 1
						r.ratio += minf(float(oc.ratio), 20.0)
						r.nlinks += 1
						r.spN += e.spN
						r.keep += float(oc.keep)
						if oc.outcome == "punch":
							fl += oc.hit.size()
						if not oc.floors and oc.outcome in ["collapse", "heavy"]:
							r.levelled += 1
					r.floors += fl
					r.deaths += WorldBrunt.chainDeaths(best)
					var last: Dictionary = best[L - 1]
					if L >= WorldBrunt.chainCap(tier, t == 5) and last.keep > 0.0 and last.outcome in ["punch", "collapse", "heavy"]:
						r.stop["cap"] += 1
					elif last.outcome in ["dent", "crack", "wreck"]:
						r.stop["building"] += 1
					else:
						r.stop["no_next"] += 1
		SimCore.dispose(S)
	for t in [1, 2, 3, 4, 5]:
		var r: Dictionary = res[t]
		var nn: float = float(maxi(r.samples, 1))
		var wp: float = float(maxi(r.withPlan, 1))
		print("MENU tier %s (%s) force %.0f: samples %d, buildings in reach %.1f, plans %.2f; a plan exists %.0f%% of the time; of those: chain length %s; floors punched %.1f, deaths %.1f, ended by: %s" % [("finisher" if t == 5 else str(t)), mode, force, r.samples, float(r.cands) / nn, float(r.plans) / nn, 100.0 * float(r.withPlan) / nn, str(r.len), float(r.floors) / wp, r.deaths / wp, str(r.stop)])
		print("MENUL tier %s links (T = a tower of 5 floors or more, h = a building without floors): %s; mean speed %.0f, mean ratio %.1f, mean keep %.2f" % [("finisher" if t == 5 else str(t)), str(r.links), r.spN / maxf(float(r.nlinks), 1.0), r.ratio / maxf(float(r.nlinks), 1.0), r.keep / maxf(float(r.nlinks), 1.0)])
	quit(0)
