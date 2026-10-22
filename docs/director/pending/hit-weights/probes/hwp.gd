extends SceneTree
## Probe: the director's hits by weight, AI v AI, hit-stop by weight on or off (the setup's "hitstop"). Each damage event
## with an attacker: the stop it held (ticks), counted by its ticks and by the blow's form; the frozen share of all
## ticks; matches to the KO or --ticks.
## -- <matches> <seed0> [--on] [--ticks=10800]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 10800
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	var on: bool = args.has("--on")
	var by := {}
	var frozen := 0
	var all := 0
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {"hitstop": on})
		for t in range(ticks):
			var t0: float = S.T
			SimCore.step(S)
			all += 1
			if S.T == t0:
				frozen += 1
			for e in S.out.fx:
				if String(e.type) == "damage" and float(e.attacker) >= 0.0:
					var st: int = int(e.get("stop")) if e.get("stop") != null else 0
					var w: String = str(st) + ":" + (String(e.mode) if String(e.mode) != "" else "planned")
					if not by.has(w):
						by[w] = [0, 0.0]
					by[w][0] += 1
					by[w][1] += float(st)
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				break
	var r := {"on": on, "matches": n, "frozenShare": snappedf(float(frozen) / maxf(1.0, float(all)), 0.001), "byWeight": {}}
	for w in by:
		r.byWeight[w] = [by[w][0], snappedf(float(by[w][1]) / maxf(1.0, float(by[w][0])), 0.1)]
	print(JSON.stringify(r))
	quit()
