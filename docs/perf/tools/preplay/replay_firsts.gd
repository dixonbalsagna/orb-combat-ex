extends SceneTree
## Pre-play read, half 2 (Performance and Platform, 2026-11-01): the first tick each kind of event happens in a recorded match.
## The page's black box (window.__bb_replay, a SimReplay dictionary) holds the seed, the setup and every press; this re-runs it headless with the same SimCore.step and prints, for every fx type and every feed tag
## (the first 24 characters), the tick it first appears and how often. Nothing is written but --out. The page itself needs no hook: preplay-read.mjs matches these ticks to its own frame record.
##   godot --headless --path <a tree that matches the page's build> --script res://docs/perf/tools/preplay/replay_firsts.gd -- --replay=<file.json> --out=<file.json>
## (copy this file into the tree's own folder first if the tree has no docs/: the script uses only SimCore, SimReplay and SimHash.)

func _init() -> void:
	var rp_path := ""
	var outp := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--replay="):
			rp_path = a.substr(9)
		elif a.begins_with("--out="):
			outp = a.substr(6)
	var txt := FileAccess.get_file_as_string(rp_path)
	var rp = JSON.parse_string(txt)
	if not (rp is Dictionary):
		printerr("replay_firsts: not a replay dictionary: ", rp_path)
		quit(2)
		return
	var packed: Array = []
	for inp in rp.get("inputs", []):
		var p: int = SimReplay.join(inp[2], inp[3])
		var it = null
		if p != -1:
			it = SimIntent.unpack(p) if p >= 0 else null
			if it != null and inp.size() == 5:
				SimIntent.unpack2(int(inp[4]), it)
		packed.append(it)
	var S := SimCore.createSim()
	SimCore.newMatch(S, int(rp.seed), rp.ai, rp.get("setup", {}))
	var cur: Array = []
	cur.resize(S.fighters.size())
	var fx_first := {}
	var fx_n := {}
	var feed_first := {}
	var feed_n := {}
	var ii := 0
	var ti := 0
	var toggles: Array = rp.get("toggles", [])
	var inputs: Array = rp.get("inputs", [])
	for t in range(int(rp.ticks)):
		while ti < toggles.size() and int(toggles[ti][0]) == t:
			SimCore.toggleAI(S, int(toggles[ti][1]))
			ti += 1
		while ii < inputs.size() and int(inputs[ii][0]) == t:
			cur[int(inputs[ii][1])] = packed[ii]
			ii += 1
		SimCore.step(S, cur)
		for e in S.out.fx:
			var k := String(e.type)
			if not fx_first.has(k):
				fx_first[k] = t
			fx_n[k] = int(fx_n.get(k, 0)) + 1
		for e in S.out.feed:
			var g := String(e.tag).substr(0, 24)
			if not feed_first.has(g):
				feed_first[g] = t
			feed_n[g] = int(feed_n.get(g, 0)) + 1
		S.out.fx.clear()
		S.out.feed.clear()
	var res := {"ticks": int(rp.ticks), "fx": {}, "feed": {}}
	for k in fx_first:
		res.fx[k] = {"first": fx_first[k], "n": fx_n[k]}
	for g in feed_first:
		res.feed[g] = {"first": feed_first[g], "n": feed_n[g]}
	SimCore.dispose(S)
	if outp != "":
		var f := FileAccess.open(outp, FileAccess.WRITE)
		f.store_string(JSON.stringify(res))
		f.close()
	print("replay_firsts: ", fx_first.size(), " fx types, ", feed_first.size(), " feed tags over ", int(rp.ticks), " ticks")
	quit(0)
