extends SceneTree
## Stray stick beams in a saved play (EP brief 2026-11-13, Encounter's stray-beams acceptance 3; A-COMBAT-05): replays a black box file (the page's orb-first-play json) on the tree it was built from and counts, for slot 0, the stick
## beams that waited and fired after a new press, and the refusals beside them. The park's `ownMove.dropOnPress` is set for the run, so one tree gives both arms.
##   godot --headless --path <tree> --script res://qa/godot/stray_count.gd -- <file.json> --drop=0|1
## A stick beam is slot 0's `beam_stage` cue; LATE = slot 0 pressed anything else after the stick came to rest and before the beam fired (a face button, the guard, a dodge, RT, a new stick strike, the context, the transform, Escape).
## Lines: FIRE (every stick beam of slot 0: tick, the release tick, the gap, the presses between), REFUSED (every `stick_refused` beam cue of slot 0 by its source), SUMMARY. With drop=1 the run leaves the saved match at the first press that
## the rule changes (the world differs from there on); the counts after that are the same inputs on a different match and are marked.
## Read-only with respect to sim/: it sets one data key and nothing else.

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var drop: bool = false
	for a in args:
		if a.begins_with("--drop="):
			drop = a.substr(7) == "1"
	SimInputData.load_and_apply()
	DirBeamPlay.frontCfg()["ownMove"]["dropOnPress"] = drop
	var rp = JSON.parse_string(FileAccess.open(args[0], FileAccess.READ).get_as_text())
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
	var ii: int = 0
	var ti: int = 0
	var rel: int = -1
	var held: bool = false
	var presses: Array = []   # [tick, name] since the last release
	var fires: int = 0
	var late: int = 0
	var refs := {}
	var gaps: Array = []
	var lines: Array = []
	for t in range(int(rp.ticks)):
		while ti < rp.toggles.size() and int(rp.toggles[ti][0]) == t:
			SimCore.toggleAI(S, int(rp.toggles[ti][1]))
			ti += 1
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		var itx = cur[0]
		if itx != null:
			if itx.rsHeld:
				held = true
			elif held:
				held = false
				rel = t
				presses.clear()
			if rel >= 0 and not itx.rsHeld:
				for k in ["light", "heavy", "sig", "guardPress", "dodge", "powerPress", "context", "transform", "escape", "rsStart"]:
					if itx.get(k):
						presses.append("%d:%s" % [t, k])
		SimCore.step(S, cur)
		for e in S.out.fx:
			if e.type != "cue" or int(e.actor) != 0:
				continue
			var k2: String = str(e.kind)
			if k2 == "stick_refused" and str(e.text) == "beam":
				var src: String = str(e.get("source"))
				refs[src] = int(refs.get(src, 0)) + 1
				lines.append("REFUSED t=%d source=%s" % [t, src])
			elif k2 == "beam_stage":
				fires += 1
				var is_late: bool = rel >= 0 and not presses.is_empty() and t - rel > 3
				if is_late:
					late += 1
					gaps.append(t - rel)
				lines.append("FIRE t=%d stage=%s release=%d gap=%d presses between=[%s]%s" % [t, str(e.text), rel, t - rel if rel >= 0 else -1, ", ".join(presses), " LATE" if is_late else ""])
		S.out.fx.clear()
		S.out.feed.clear()
	for l in lines:
		print(l)
	print("SUMMARY drop=%s ticks=%d stick beams %d, late after a new press %d, gaps %s, refusals by source %s" % [str(drop), int(rp.ticks), fires, late, str(gaps), JSON.stringify(refs)])
	quit()
