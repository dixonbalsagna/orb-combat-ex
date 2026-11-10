extends SceneTree
## Slot 0's attack queue and the exchange, tick by tick over a window of a black box file: probe_queue.gd -- <file> <from> <to>
func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	SimInputData.load_and_apply()
	var rp = JSON.parse_string(FileAccess.open(args[0], FileAccess.READ).get_as_text())
	rp = rp.replay
	var t0: int = int(args[1])
	var t1: int = int(args[2])
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
	var last: String = ""
	for t in range(t1 + 1):
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		SimCore.step(S, cur)
		if t >= t0:
			var a = S.fighters[0]
			var qs: Array = []
			for qe in a.act.queue:
				qs.append("[w%d m%d e%d t%d]" % [int(qe[0]), int(qe[1]), int(qe[2]), int(qe[3])])
			var ex = DirBrawl.exOf(S)
			var itx = cur[0]
			var line := "queue %s ex=%s/%s state=%s mask=%d sig=%s sigHeld=%s power=%s powerPress=%s" % [" ".join(qs), (str(ex.kind) + ":" + str(ex.tpl)) if ex != null else "none", str(ex.branch) if ex != null else "", a.state, int(itx.stanceMask), str(itx.sig), str(itx.sigHeld), str(itx.power), str(itx.powerPress)]
			if line != last:
				print("Q t=%d %s" % [t, line])
				last = line
		S.out.fx.clear()
		S.out.feed.clear()
	quit()
