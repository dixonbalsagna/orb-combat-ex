extends SceneTree
## Replays a black box file (the page's orb-first-play json) on the tree the page was built from and lists every launch: who sent whom, the director's plan, the sent body's direction as the sim set it (ux, uy), where he actually went
## (his displacement over the next ticks, wrapped) and what slot 0's controls said around the blow (left stick, right-stick direction, the last non-neutral reading in the ticks before).
##   godot --headless --path <tree> --script res://qa/godot/launch_trace.gd -- <file.json> [look-ahead ticks, default 24]
## LAUNCH lines: tick, sender -> sent, plan, speed, ux uy, side (the sent body's side of the sender: + is the sender's +x), displacement after N ticks (dx, dy), slot 0's last stick reading. Read-only.

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = args[0]
	var look: int = int(args[1]) if args.size() > 1 else 24
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
	var pending: Array = []   # launches waiting for their look-ahead
	var lastPlan: String = ""
	var lastPlanT: int = -1000
	var lastStick: String = "none"
	var lastStickT: int = -1000
	var rows: Array = []
	for t in range(int(rp.ticks)):
		while ti < rp.toggles.size() and int(rp.toggles[ti][0]) == t:
			SimCore.toggleAI(S, int(rp.toggles[ti][1]))
			ti += 1
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		var itx = cur[0]
		if itx != null:
			var bits: Array = []
			if absf(itx.mx) > 0.2 or absf(itx.my) > 0.2:
				bits.append("left %.1f,%.1f" % [itx.mx, itx.my])
			if int(itx.rsDir) != 0:
				bits.append("rsDir %d lvl %d" % [int(itx.rsDir), int(itx.rsLevel)])
			if itx.light or itx.heavy or itx.sig:
				bits.append("face " + ("X" if itx.light else ("Y" if itx.heavy else "B")))
			if not bits.is_empty():
				lastStick = ", ".join(bits)
				lastStickT = t
		SimCore.step(S, cur)
		for e in S.out.fx:
			if e.type == "launch_plan":
				lastPlan = str(e.chosen)
				lastPlanT = t
			elif e.type == "launch":
				var sent = S.fighters[int(e.actor)]
				var by = S.fighters[int(e.target)] if int(e.target) >= 0 else null
				pending.append({"t": t, "sent": int(e.actor), "by": int(e.target), "amount": float(e.amount), "ux": float(e.ux), "uy": float(e.uy), "plan": lastPlan if t - lastPlanT < 120 else "", "x0": sent.x, "y0": sent.y, "side": (SimWrap.sdx(by.x, sent.x) if by != null else 0.0), "face": (by.face if by != null else 0.0), "stick": lastStick if t - lastStickT < 40 else "none (+%d)" % (t - lastStickT), "tier": int(e.tier)})
		var keep: Array = []
		for pl in pending:
			if t - int(pl.t) >= look:
				var sent2 = S.fighters[int(pl.sent)]
				var dx: float = SimWrap.sdx(float(pl.x0), sent2.x)
				var dy: float = sent2.y - float(pl.y0)
				print("LAUNCH t=%d (%.1fs) %d->%d plan=%s tier %d speed %.0f | set ux %.2f uy %.2f | sent body is %s of the sender (sender faces %s) | moved dx %.0f dy %.0f in %d ticks | slot0: %s" % [
					int(pl.t), float(pl.t) / 60.0, int(pl.by), int(pl.sent), str(pl.plan), int(pl.tier), float(pl.amount), float(pl.ux), float(pl.uy),
					("right (+x)" if float(pl.side) > 0.0 else "left (-x)"), ("+x" if float(pl.face) > 0.0 else "-x"), dx, dy, look, str(pl.stick)])
			else:
				keep.append(pl)
		pending = keep
		S.out.fx.clear()
		S.out.feed.clear()
	quit()
