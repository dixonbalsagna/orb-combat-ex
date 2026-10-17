extends SceneTree
## Probe: UI's run on the blow cue. The AI on both sides. It counts the brawl's blow cues by their run (0 to run_to), and
## for each flurry close (a stagger cue with text flurry) whether the striker's last blow cue before it read his gauge
## full (run == run_to). -- <matches> <seed0>


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 3
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var r := {"matches": n, "blows": 0, "withRun": 0, "byRun": {}, "runTo": {}, "closes": 0, "closeAfterFull": 0}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {"p1": true, "p2": true}, {"v2": [true, true]})
		var last := {}
		while S.tick < 18000 and S.game.ko == null:
			SimCore.step(S, null)
			for e in S.out.fx:
				if e.type != "cue":
					continue
				if String(e.kind) == "blow":
					r.blows += 1
					if int(e.run_to) > 0:
						r.withRun += 1
						r.byRun[str(e.run)] = int(r.byRun.get(str(e.run), 0)) + 1
						r.runTo[str(e.run_to)] = int(r.runTo.get(str(e.run_to), 0)) + 1
						last[int(e.actor)] = int(e.run) == int(e.run_to)
				elif String(e.kind) == "stagger" and String(e.text) == "flurry":
					r.closes += 1
					if bool(last.get(int(e.target), false)):
						r.closeAfterFull += 1
			S.out.fx.clear()
			S.out.feed.clear()
	print(JSON.stringify(r))
	quit()
