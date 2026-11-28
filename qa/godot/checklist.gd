extends SceneTree
## The Alpha match checklist (X-13) on saved play files: replays each black box file on the tree it was built from and prints which of the criterion's ten things the match showed (qa/godot/checklist_core.gd has the test of each).
##   bash tools/godot-run.sh --path <tree> --script res://qa/godot/checklist.gd -- <file.json> [<file.json> ...]
## Lines: CHECKLIST <file> <ticks> ticks (<minutes> min), then one ITEM line each: seen or NOT SEEN, the tick it was first seen and a detail; then CHECKLIST_SUMMARY with the count seen. Scripted matches use orbs_player.gd, which prints the same items. Read-only.
const Core = preload("res://qa/godot/checklist_core.gd")


func _init() -> void:
	SimInputData.load_and_apply()
	for path in OS.get_cmdline_user_args():
		var rp = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
		if rp.has("replay"):
			rp = rp.replay
		var packed: Array = []
		for inp in rp.inputs:
			var it = null
			var p: int = SimReplay.join(inp[2], inp[3])
			if p != -1:
				it = SimIntent.unpack(p)
				if inp.size() == 5 and it != null:
					SimIntent.unpack2(int(inp[4]), it)
			packed.append(it)
		var S := SimCore.createSim()
		SimCore.newMatch(S, int(rp.seed), rp.ai, rp.get("setup", {}))
		var cur: Array = []
		cur.resize(SimStage.slotCount(S))
		var chk = Core.new()
		chk.begin(S)
		var ii: int = 0
		var ti: int = 0
		for t in range(int(rp.ticks)):
			while ti < rp.toggles.size() and int(rp.toggles[ti][0]) == t:
				SimCore.toggleAI(S, int(rp.toggles[ti][1]))
				ti += 1
			while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
				cur[int(rp.inputs[ii][1])] = packed[ii]
				ii += 1
			SimCore.step(S, cur)
			chk.feed(S, t, cur)
			S.out.fx.clear()
			S.out.feed.clear()
		var winner: String = "no KO by the last tick"
		if S.game.ko != null:
			winner = "slot %d won (slot %d was knocked out)" % [1 - S.fighters.find(S.game.ko), S.fighters.find(S.game.ko)]
		var r: Dictionary = chk.result()
		print("CHECKLIST %s %d ticks (%.1f min); %s" % [path.get_file(), int(rp.ticks), float(rp.ticks) / 3600.0, winner])
		var n: int = 0
		for k in ["lap", "stances", "beam_off", "signatures", "launch", "well", "crater", "building", "bystanders", "transform"]:
			var it2: Dictionary = r[k]
			if bool(it2.seen):
				n += 1
			print("ITEM %s %s: %s%s" % [path.get_file(), k, "seen at tick %d" % int(it2.tick) if bool(it2.seen) else "NOT SEEN", (" (" + str(it2.detail) + ")") if str(it2.detail) != "" else ""])
		print("CHECKLIST_SUMMARY %s %d of 10 seen" % [path.get_file(), n])
		SimCore.dispose(S)
	quit()
