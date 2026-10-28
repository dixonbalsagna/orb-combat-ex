extends SceneTree
## The gameplay state hash after every tick of seeded matches, one line a tick, for comparing two builds of the director
## tick by tick (an equivalence check: the same draws, in the same order, to the same state).
##   godot --headless --path . --script res://sim/director/tools/tick_hash.gd -- --out=<file> [--ticks=3600] [--run=k]
## Matches: AI against AI and net/'s scripted players (the human path), each on the hand-made world (seeds 1 to 3),
## a gen 2 planet (planet 7, touch-down 3, arena 2400) and the hand-made world with the intro playing. Each line also
## carries a hash of the tick's feed lines and fx events (the cues). --run=k plays only the k-th of those 12 matches
## (0 to 11, AI first), so they can run side by side. Compare two outputs with diff or cmp.

func _init() -> void:
	var ticks: int = 3600
	var out: String = ""
	var only: int = -1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--run="):
			only = int(a.substr(6))
	if out == "":
		push_error("tick_hash: --out=<file> is needed")
		quit(2)
		return
	var gen2: Dictionary = {"planet": 7, "touch": 3, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}
	var runs: Array = [
		["hand 1", 1, {}], ["hand 2", 2, {}], ["hand 3", 3, {}],
		["gen2 7", 7, gen2], ["gen2 11", 11, gen2],
		["intro 4", 4, {"intro": true}],
	]
	var fa := FileAccess.open(out, FileAccess.WRITE)
	var n: int = 0
	var k: int = -1
	for bots in [false, true]:
		for r in runs:
			k += 1
			if only >= 0 and k != only:
				continue
			var seed: int = int(r[1])
			var S := SimCore.createSim()
			SimCore.newMatch(S, seed, {"p1": not bots, "p2": not bots}, r[2])
			var nb: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
			for tk in range(ticks):
				var ins = null
				if bots:
					ins = []
					for j in range(2):
						ins.append(SimIntent.unpack(NetSession.NEUTRAL if tk < 2 else nb[j].next()))
				SimCore.step(S, ins)
				var ev: String = ""
				for e in S.out.feed:
					ev += str(inst_to_dict(e))
				for e in S.out.fx:
					ev += str(inst_to_dict(e))
				S.out.feed.clear()
				S.out.fx.clear()
				fa.store_line("%s %s %d %s %d" % [r[0], "bots" if bots else "AI", tk, str(SimHash.stateHash(S).gameplay), ev.hash()])
				n += 1
			SimCore.dispose(S)
	fa.close()
	print("tick_hash: %d ticks hashed into %s" % [n, out])
	quit(0)
