extends SceneTree
func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	SimInputData.load_and_apply()
	var rp = JSON.parse_string(FileAccess.open(args[0], FileAccess.READ).get_as_text())
	rp = rp.replay
	var tl: int = int(args[1])
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
	var o = S.fighters[1]
	var pred: Dictionary = {}
	var hits: Array = []
	var maxd: float = 0.0
	var x0: float = 0.0
	var y0: float = 0.0
	for t in range(tl + 900):
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		SimCore.step(S, cur)
		if t == tl:
			x0 = o.x
			y0 = o.y
		if t == tl + 1:
			pred = DirArc.landing(o)
			print("ARC t=%d launched: from x %.0f y %.0f; the curve says it lands at x %.0f (side %+.0f, %d ticks)" % [tl, x0, y0, float(pred.x), float(pred.side), int(pred.ticks)])
		if not pred.is_empty() and t == tl + 1 + int(pred.ticks):
			print("ARC t=%d end of the curve: body at x %.0f y %.0f (predicted x %.0f, miss %.0f; ground there %.0f)" % [t, o.x, o.y, float(pred.x), SimWrap.sdx(float(pred.x), o.x), float(pred.y)])
		if t > tl and t % 30 == 0 and t <= tl + 240:
			print("ARC   +%d ticks: dx %.0f dy %.0f (state %s)" % [t - tl, SimWrap.sdx(x0, o.x), o.y - y0, str(o.state)])
		for e in S.out.fx:
			if t >= tl and e.type == "crater" and str(e.cause) == "impact" and int(e.owner) == 1 and hits.size() < 2:
				hits.append(t)
				print("ARC t=%d impact crater at x %.0f (from the send: dx %.0f); predicted x %.0f, miss %.0f" % [t, float(e.x), SimWrap.sdx(x0, float(e.x)), float(pred.get("x", 0.0)), SimWrap.sdx(float(pred.get("x", 0.0)), float(e.x))])
		S.out.fx.clear()
		S.out.feed.clear()
		if hits.size() >= 1 and t > hits[0] + 5:
			break
	quit()
