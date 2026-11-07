extends SceneTree
## Does slot 0's recorded intent match what the sim's own AI would choose from the same state? (a black box file played on the tree it was built from)
##   godot --headless --path <tree> --script res://qa/godot/ai_compare.gd -- <file.json> <from> <to> [<from2> <to2> ...]
## For each tick in a range: snapshot the state, make slot 0 the sim's AI (SimCore.toggleAI), step once with no intent for it, read the intent the AI chose (the fighter's input), restore the snapshot, and step for real with the recorded intent.
## Prints per range: ticks compared, the share where the buttons agree, the share where the left stick agrees within 0.2 on both axes, and the share where both agree. Read-only (the real timeline is never changed).

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = args[0]
	var ranges: Array = []
	var control: bool = args.has("--control")
	var i0: int = 1
	while i0 + 1 < args.size() and args[i0] != "--control":
		ranges.append([int(args[i0]), int(args[i0 + 1])])
		i0 += 2
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
	var res := {}
	for r in ranges:
		res[str(r)] = {"n": 0, "btn": 0, "mv": 0, "both": 0, "recBtn": 0, "aiBtn": 0, "recIdle": 0}
	var BTN := ["light", "heavy", "sig", "dodge", "guard", "lightHeld", "heavyHeld", "sigHeld", "rsStart", "rsHeld"]
	for t in range(int(rp.ticks)):
		while ti < rp.toggles.size() and int(rp.toggles[ti][0]) == t:
			SimCore.toggleAI(S, int(rp.toggles[ti][1]))
			ti += 1
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		var inr = null
		for r in ranges:
			if t >= r[0] and t <= r[1]:
				inr = r
		if control and inr != null and t == int(inr[0]):
			SimCore.toggleAI(S, 0)
		if control and inr != null and S.fighters[0].ai != null:
			var snapc: NetSnapshot = NetSnapshot.take(S)
			var aiC: Array = cur.duplicate()
			aiC[0] = null
			SimCore.step(S, aiC)
			var x = S.fighters[0].input
			var xs: Array = [x.mx, x.my]
			var xb: Array = []
			for k in BTN:
				xb.append(bool(x.get(k)))
			NetSnapshot.restore(S, snapc)
			SimCore.step(S, aiC)
			var y = S.fighters[0].input
			var okb: bool = true
			for j in range(BTN.size()):
				if bool(y.get(BTN[j])) != xb[j]:
					okb = false
			var okm: bool = absf(y.mx - xs[0]) <= 0.2 and absf(y.my - xs[1]) <= 0.2
			var rc: Dictionary = res[str(inr)]
			rc.n += 1
			rc.btn += 1 if okb else 0
			rc.mv += 1 if okm else 0
			rc.both += 1 if (okb and okm) else 0
			S.out.fx.clear()
			S.out.feed.clear()
			continue
		if inr != null and cur[0] != null and S.fighters[0].ai == null and not control:
			var snap: NetSnapshot = NetSnapshot.take(S)
			var rec = cur[0]
			SimCore.toggleAI(S, 0)
			var aiCur: Array = cur.duplicate()
			aiCur[0] = null
			SimCore.step(S, aiCur)
			var ai = S.fighters[0].input
			var bm: bool = true
			var recB: int = 0
			var aiB: int = 0
			for k in BTN:
				var a = bool(rec.get(k))
				var b = bool(ai.get(k))
				if a:
					recB += 1
				if b:
					aiB += 1
				if a != b:
					bm = false
			var mm: bool = absf(rec.mx - ai.mx) <= 0.2 and absf(rec.my - ai.my) <= 0.2
			var rr: Dictionary = res[str(inr)]
			rr.n += 1
			rr.btn += 1 if bm else 0
			rr.mv += 1 if mm else 0
			rr.both += 1 if (bm and mm) else 0
			rr.recBtn += 1 if recB > 0 else 0
			rr.aiBtn += 1 if aiB > 0 else 0
			NetSnapshot.restore(S, snap)
		SimCore.step(S, cur)
		S.out.fx.clear()
		S.out.feed.clear()
	for k in res.keys():
		var r: Dictionary = res[k]
		var n: float = maxf(1.0, float(r.n))
		print("AICOMPARE range %s ticks %d buttons agree %.0f%%, stick agrees %.0f%%, both %.0f%%; ticks with a button down: recorded %.0f%%, AI %.0f%%" % [k, r.n, 100.0 * r.btn / n, 100.0 * r.mv / n, 100.0 * r.both / n, 100.0 * r.recBtn / n, 100.0 * r.aiBtn / n])
	quit()
