extends SceneTree
func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	SimInputData.load_and_apply()
	var rp = JSON.parse_string(FileAccess.open(args[0], FileAccess.READ).get_as_text())
	rp = rp.replay
	var upto: int = int(args[1])
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
	for t in range(upto + 1):
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		if t < upto:
			SimCore.step(S, cur)
	var f = S.fighters[0]
	var o = S.fighters[1]
	var toward: float = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(f.x, o.x)), f.face)
	print("PROBE t=%d sender x %.0f face %.0f, sent body x %.0f (toward the punch = %+.0f)" % [upto, f.x, f.face, o.x, toward])
	print("PROBE landing score going WITH the punch %+.0f: %.1f ; AGAINST it %+.0f: %.1f" % [toward, DirArc.landingScore(S, o, 0, toward), -toward, DirArc.landingScore(S, o, 0, -toward)])
	quit()
