extends SceneTree
## X-17: beams that started by any input other than the right stick or RT + B (sprint A1, A-COMBAT-08; the aim is 0, and it must pass from A2). Replays black box files on the tree each was built from and counts, for slot 0 (the human), what started each beam:
##   stick  a `beam_stage` cue within 5 ticks before the charge (QA found the charge can follow the stage cue by 3 ticks) (the stick beam's own move: RB and the right stick, thrown on the release, late or not)
##   rtb    RT held (stance mask bit 4) at the charge, no stick beam: RT + B
##   other  anything else: B alone, B with the dodge or a stance held, a face-button combination, a stale queued signature
## Each `other` is listed with its tick and slot 0's last 12 ticks of buttons, so it can be read.
##   godot --headless --path <tree> --script res://qa/godot/x17_count.gd -- <file.json> [<file.json> ...]
## Lines: X17 <file> stick N, rtb N, other N, then OTHER lines; the last line is X17 TOTAL. Read-only.

func _init() -> void:
	SimInputData.load_and_apply()
	var tot := {"stick": 0, "rtb": 0, "other": 0}
	for path in OS.get_cmdline_user_args():
		var c: Dictionary = _count(path)
		for k in tot:
			tot[k] += int(c[k])
		print("X17 %s stick %d, rtb %d, other %d, ticks %d" % [path.get_file(), c.stick, c.rtb, c.other, c.ticks])
		for o in c.others:
			print("OTHER %s %s" % [path.get_file(), o])
	print("X17 TOTAL stick %d, rtb %d, other %d" % [tot.stick, tot.rtb, tot.other])
	quit()


func _count(path: String) -> Dictionary:
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
	var ii: int = 0
	var ti: int = 0
	var stageT: int = -100
	var hist: Array = []
	var res := {"stick": 0, "rtb": 0, "other": 0, "others": [], "ticks": int(rp.ticks)}
	for t in range(int(rp.ticks)):
		while ti < rp.toggles.size() and int(rp.toggles[ti][0]) == t:
			SimCore.toggleAI(S, int(rp.toggles[ti][1]))
			ti += 1
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		var itx = cur[0]
		var fl: Array = []
		if itx != null:
			for k in ["light", "heavy", "sig", "sigHeld", "dodge", "guard", "power", "powerPress", "context", "transform", "rsStart", "rsHeld", "rsRelease"]:
				if itx.get(k):
					fl.append(k)
			if int(itx.stanceMask) != 0:
				fl.append("mask%d" % int(itx.stanceMask))
		hist.append("%d:%s" % [t, "+".join(fl) if not fl.is_empty() else "-"])
		if hist.size() > 12:
			hist.pop_front()
		SimCore.step(S, cur)
		for e in S.out.fx:
			if e.type != "cue" or int(e.actor) != 0:
				continue
			var k2: String = str(e.kind)
			if k2 == "beam_stage":
				stageT = t
			elif k2 == "beam_charge" and str(e.text) == "start":
				if t - stageT <= 5:
					res.stick += 1
				elif (int(S.fighters[0].input.stanceMask) & 4) != 0:
					res.rtb += 1
				else:
					res.other += 1
					res.others.append("t=%d last 12 ticks: %s" % [t, " ".join(hist)])
		S.out.fx.clear()
		S.out.feed.clear()
	SimCore.dispose(S)
	return res
