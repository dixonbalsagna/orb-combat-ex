extends SceneTree
## Replays a black box file (the page's orb-first-play json, or a bare replay) through the sim as SimReplay.play does, on the tree the page was built from, and traces slot 0: the intent it was fed and what it did.
##   godot --headless --path <tree> --script res://qa/godot/trace_replay.gd -- <file.json> <from tick> <to tick>
## TRACE lines for ticks in the range where slot 0 did something or its intent was not neutral; AFTERRELEASE: slot 0 blows, stick strikes and chases more than 20 ticks after every control was let go (a stuck-input or auto-attack check); UNPROMPTED: the same 90 ticks after a press. Read-only.

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = args[0]
	var t0: int = int(args[1])
	var t1: int = int(args[2])
	SimInputData.load_and_apply()
	var f := FileAccess.open(path, FileAccess.READ)
	var rp = JSON.parse_string(f.get_as_text())
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
	var slots: int = SimStage.slotCount(S)
	var cur: Array = []
	cur.resize(slots)
	var ii: int = 0
	var ti: int = 0
	var kinds := {}
	var held := {}
	var lastPress: int = -1000
	var lastRs: int = -1000
	var unprompted: Array = []
	var lastDown: int = -1000
	var afterRelease: Array = []
	for t in range(int(rp.ticks)):
		while ti < rp.toggles.size() and int(rp.toggles[ti][0]) == t:
			SimCore.toggleAI(S, int(rp.toggles[ti][1]))
			ti += 1
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		SimCore.step(S, cur)
		var itx = cur[0]
		if itx != null and (itx.light or itx.heavy or itx.sig or itx.dodge or itx.rsStart or itx.guardPress):
			lastPress = t
		if itx != null and itx.rsHeld:
			lastRs = t
		if itx != null and (itx.lightHeld or itx.heavyHeld or itx.sigHeld or itx.rsHeld or itx.light or itx.heavy or itx.sig or itx.dodge or itx.guard or itx.rsStart):
			lastDown = t
		for e in S.out.fx:
			if e.type == "cue" and int(e.actor) == 0 and str(e.kind) in ["blow", "stick_start", "stick_release", "chase"] and t - lastDown > 20:
				afterRelease.append("%d:%s:%s(+%d)" % [t, str(e.kind), str(e.text), t - lastDown])
			if e.type == "cue" and int(e.actor) == 0 and str(e.kind) in ["blow", "stick_start", "chase", "driver_fire", "arc_send"] and t - lastPress > 90 and t - lastRs > 90:
				unprompted.append("%d:%s:%s(+%d)" % [t, str(e.kind), str(e.text), t - lastPress])
		if t >= t0 and t <= t1:
			var it = cur[0]
			var ins: Array = []
			if it != null:
				for k in ["light", "heavy", "sig", "dodge", "guard", "lightHeld", "heavyHeld", "sigHeld", "rsStart", "rsHeld", "rsRelease", "transform"]:
					if it.get(k):
						ins.append(k)
				if absf(it.mx) > 0.1 or absf(it.my) > 0.1:
					ins.append("move %.1f,%.1f" % [it.mx, it.my])
				if int(it.stanceMask) != 0 or int(it.rsMask) != 0:
					ins.append("mask %d rsMask %d" % [int(it.stanceMask), int(it.rsMask)])   # RB is the energy bit (2); LT the manoeuvre bit; 0 is no layer held
				if int(it.rsDir) != 0:
					ins.append("rsDir %d lvl %d" % [int(it.rsDir), int(it.rsLevel)])
			var evs: Array = []
			for e in S.out.fx:
				if e.type == "cue" and int(e.actor) == 0:
					evs.append("%s:%s" % [str(e.kind), str(e.text)])
				elif e.type in ["damage", "launch", "slide"] and (int(e.get("attacker")) == 0 or int(e.get("actor")) == 0):
					evs.append("%s:%s" % [e.type, str(e.get("kind"))])
			if not ins.is_empty() or not evs.is_empty():
				print("TRACE t=%d state=%s in=[%s] ev=[%s]" % [t, S.fighters[0].state, ", ".join(ins), ", ".join(evs)])
			for e in evs:
				kinds[e] = int(kinds.get(e, 0)) + 1
			for i in ins:
				held[i] = int(held.get(i, 0)) + 1
		S.out.fx.clear()
		S.out.feed.clear()
	print("AFTERRELEASE " + str(afterRelease.size()) + " " + ", ".join(afterRelease.slice(0, 100)))
	print("UNPROMPTED " + str(unprompted.size()) + " " + ", ".join(unprompted.slice(0, 80)))
	print("SUMMARY events " + JSON.stringify(kinds))
	print("SUMMARY inputs-ticks " + JSON.stringify(held))
	quit()
