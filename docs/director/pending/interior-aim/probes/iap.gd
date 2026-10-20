extends SceneTree
## Probe: the interior aim, AI v AI, with World's interior chain on in memory (brunt.json interiorChain 1) and
## launch.json interiorAim on (--aim=off: as the data has it). Each match runs to its KO or --ticks. Reads, by the
## fighter sent: building sends (launch_plan BUILDING SMASH), interior chains started (a launch number with an
## interior_contact), interior contacts, and the share of building sends that start a chain.
## --city: each match starts with both in the city (match m in the city's m-th tenth), so towers are near.
## -- <matches> <seed0> [--ticks=10800] [--aim=on|off] [--city]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 10800
	var aim := true
	var city: bool = args.has("--city")
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
		elif s == "--aim=off":
			aim = false
	WorldBrunt.cfg()["interiorChain"] = 1
	if aim:
		DirLaunch.data()["interiorAim"]["enabled"] = true
	var r := {"aim": aim, "interiorAimOn": bool(DirLaunch.data().get("interiorAim", {}).get("enabled", false)), "matches": n,
		"minutes": 0.0, "bruntSends": [0, 0], "chains": [0, 0], "contacts": [0, 0], "kos": 0}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {})
		if city:
			var xs := []
			var x := 0.0
			while x < 153600.0:
				if WorldBiomes.biomeAt(x) == "city":
					xs.append(x)
				x += 200.0
			if xs.size() > 0:
				var x0: float = float(xs[(m * xs.size()) / maxi(1, n) % xs.size()])
				S.fighters[0].x = x0
				S.fighters[1].x = SimWrap.wrap(x0 + 300.0)
				r["cityX"] = r.get("cityX", []) + [int(x0)]
		var seen := {}
		for t in range(ticks):
			SimCore.step(S)
			for e in S.out.fx:
				var ty: String = String(e.type)
				if ty == "launch_plan" and String(e.chosen) == "BUILDING SMASH":
					var sent: int = int(e.target)
					if sent >= 0 and sent < 2:
						r.bruntSends[sent] += 1
				elif ty == "interior_contact":
					var a: int = int(e.actor)
					if a >= 0 and a < 2:
						r.contacts[a] += 1
						var key: String = str(a) + ":" + str(int(e.n))
						if not seen.has(key):
							seen[key] = true
							r.chains[a] += 1
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				r.kos += 1
				break
		r.minutes += S.T / 60.0
	r["minutes"] = snappedf(r.minutes, 0.01)
	r["chainShare"] = snappedf(float(r.chains[0] + r.chains[1]) / maxf(1.0, float(r.bruntSends[0] + r.bruntSends[1])), 0.001)
	print(JSON.stringify(r))
	quit()
