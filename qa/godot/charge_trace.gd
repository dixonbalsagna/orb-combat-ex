extends SceneTree
## The charge-outcome read (EP brief 2026-11-08, the beam baseline; Orb: "charging up attacks can still feel like they're interrupted arbitrarily"): replays a black box file (the page's orb-first-play json) on the tree the page
## was built from and lists every charge of slot 0, how it ended and what ended it.
##   godot --headless --path <tree> --script res://qa/godot/charge_trace.gd -- <file.json>
## Two kinds of charge, by slot 0:
##  HEAVY: a held B or Y that went past its wind-up into a charge (cue windup:charge; DirBrawl._windTick). Its end is the cue windup:end, whose k says how: 1 thrown, 2 stopped by a blow, 3 lost to a stagger or the brawl's end,
##   4 a miss. When thrown, who threw it: the player (the button came up before the end) or the sim (the button was still down: the hold's maximum, charge.maxTicks). full: charge_full was seen.
##  STICK: a hold of the right stick (cue stick_start; stages by stick_stage). Its end is stick_release (the player let go), stick_refused (the reason is its source), a new stick_start, or slot 0 stunned (damage taken, a
##   stagger, a launch) before any of those.
## Rows start CHARGE; the last lines are SUMMARY counts. Read-only.

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	SimInputData.load_and_apply()
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
	var openH = null
	var openS = null
	var rows: Array = []
	var counts := {}
	var lastDown: int = -1000   # the last tick a heavy or signature button was down
	for t in range(int(rp.ticks)):
		while ti < rp.toggles.size() and int(rp.toggles[ti][0]) == t:
			SimCore.toggleAI(S, int(rp.toggles[ti][1]))
			ti += 1
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		var itx = cur[0]
		if itx != null and (itx.heavyHeld or itx.sigHeld):
			lastDown = t
		SimCore.step(S, cur)
		for e in S.out.fx:
			if e.type == "damage" and int(e.victim) == 0:
				for oc in [openH, openS]:
					if oc != null:
						oc.hits.append("%d:%s" % [t - int(oc.t0), str(e.kind)])
			elif e.type == "launch" and int(e.actor) == 0:
				for oc in [openH, openS]:
					if oc != null:
						oc.hits.append("%d:launched" % [t - int(oc.t0)])
			elif e.type == "cue" and int(e.actor) == 0:
				var k: String = str(e.kind)
				var tx: String = str(e.text)
				if k == "windup" and tx == "charge":
					openH = {"kind": "heavy", "t0": t, "full": -1, "hits": [], "lastDownAtStart": lastDown}
				elif k == "charge_full" and openH != null:
					openH.full = t
				elif k == "windup" and tx == "end" and openH != null:
					var how: int = int(e.k)
					var up: bool = lastDown < t - 1 or (itx != null and not (itx.heavyHeld or itx.sigHeld))
					var by: String = ""
					if how == 1:
						var heldFor: int = lastDown - int(openH.t0)   # the ticks the button stayed down after the charge began
						var mx: int = int(DirBrawl.cfg().heavy.charge.maxTicks)
						by = "the sim threw it at the maximum hold (%d ticks)" % mx if heldFor >= mx - 3 else "the player let go (after %d ticks of charge)" % heldFor
					else:
						by = ["", "thrown", "stopped by a blow", "lost to a stagger or the brawl's end", "a miss"][how] if how >= 1 and how <= 4 else "how %d" % how
					openH["end"] = t
					openH["how"] = how
					openH["by"] = by
					rows.append(openH)
					openH = null
				elif k == "stick_start":
					if openS != null:
						openS["end"] = t
						openS["by"] = "a new stick_start"
						rows.append(openS)
					openS = {"kind": "stick", "t0": t, "dir": tx, "stages": 0, "hits": []}
				elif k == "stick_stage" and openS != null:
					openS.stages = maxi(int(openS.stages), int(tx) if tx.is_valid_int() else int(openS.stages))
				elif (k == "stick_release" or k == "stick_refused" or k == "stick_hit" or k == "take_back" or k == "beam_stage") and openS != null:
					openS["end"] = t
					if k == "stick_release":
						openS["by"] = "the player let go (%s)" % tx
					elif k == "stick_refused":
						openS["by"] = "refused: %s %s" % [tx, str(e.get("source"))]
					elif k == "stick_hit":
						openS["by"] = "the blow landed (stick_hit %s)" % tx
					elif k == "take_back":
						openS["by"] = "taken back (%s)" % tx
					else:
						openS["by"] = "went on as a beam (stage %s)" % tx
					rows.append(openS)
					openS = null
		if openS != null and itx != null and not itx.rsHeld and t - int(openS.t0) > 3 and not itx.rsRelease:
			pass
		S.out.fx.clear()
		S.out.feed.clear()
	for r in rows:
		var dur: int = int(r["end"]) - int(r.t0)
		var key: String = "%s: %s" % [str(r.kind), str(r.by)]
		counts[key] = int(counts.get(key, 0)) + 1
		print("CHARGE %s t=%d (%.1fs) held %d ticks%s | ended by: %s%s | hits taken in it: %s" % [str(r.kind), int(r.t0), float(r.t0) / 60.0, dur,
			((", full at +%d" % (int(r.full) - int(r.t0))) if r.has("full") and int(r.full) >= 0 else (", stages %d" % int(r.stages) if r.has("stages") else ", never full")),
			str(r.by), ((" (how %d)" % int(r.how)) if r.has("how") else ""), (", ".join(r.hits) if not r.hits.is_empty() else "none")])
	print("SUMMARY " + JSON.stringify(counts))
	print("SUMMARY charges %d (heavy %d, stick %d)" % [rows.size(), rows.filter(func(r): return r.kind == "heavy").size(), rows.filter(func(r): return r.kind == "stick").size()])
	quit()
