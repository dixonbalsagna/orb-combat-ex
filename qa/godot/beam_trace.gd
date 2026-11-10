extends SceneTree
## Replays a black box file (the page's orb-first-play json) on the tree the page was built from and lists every beam event of the match with the two fighters' places and slot 0's intent at that tick.
##   godot --headless --path <tree> --script res://qa/godot/beam_trace.gd -- <file.json> [from tick] [to tick]
## BEAM lines: tick, kind, text, actor, both fighters (x offset in wrapped distance from slot 0, height, depth z, state, tier), slot 0's intent as the sim read it (buttons, rs state, triggers' stance mask) and the ticks since slot 0's last
## signature press, held B or right-stick start. BEAMOUT lines: beam_outcome events. PRESSES: slot 0's signature, B-held and right-stick starts with the tick. Read-only: nothing is written.

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = args[0]
	var nums: Array = []
	var flip: int = -1   # --flip=<tick>: on a tree with Controls' bNoBeam park, the switch is off until this tick and then on, so the same match runs to it and the rule closes only what follows (EP 2026-11-08)
	for ai in range(1, args.size()):
		if args[ai].begins_with("--flip="):
			flip = int(args[ai].substr(7))
		else:
			nums.append(int(args[ai]))
	var t0: int = int(nums[0]) if nums.size() > 0 else 0
	var t1: int = int(nums[1]) if nums.size() > 1 else 1000000
	SimInputData.load_and_apply()
	if flip >= 0:
		SimInputData.timing["switches"]["bNoBeam"] = false
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
	var lastSig: int = -100000
	var lastSigHeld: int = -100000
	var lastRs: int = -100000
	var presses: Array = []
	var hist: Array = []   # per tick, slot 0: the non-neutral buttons as text, for the 24 ticks before a beam start
	var kinds := {}
	for t in range(int(rp.ticks)):
		while ti < rp.toggles.size() and int(rp.toggles[ti][0]) == t:
			SimCore.toggleAI(S, int(rp.toggles[ti][1]))
			ti += 1
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			cur[int(rp.inputs[ii][1])] = packed[ii]
			ii += 1
		if flip >= 0 and t == flip:
			SimInputData.timing["switches"]["bNoBeam"] = true
			print("FLIP t=%d bNoBeam on" % t)
		var mBefore: int = int(S.fighters[0].act.mode)
		SimCore.step(S, cur)
		var itx = cur[0]
		var hflags: Array = []
		if itx != null:
			for hk in ["light", "heavy", "sig", "sigHeld", "dodge", "guard", "guardPress", "power", "powerPress", "powerTap", "context", "transform", "sprint", "rsStart", "rsHeld", "rsRelease"]:
				if itx.get(hk):
					hflags.append(hk)
			if int(itx.stanceMask) != 0:
				hflags.append("mask%d" % int(itx.stanceMask))
			if int(itx.special) != 0 or int(itx.upgrade) != 0:
				hflags.append("special%d/upgrade%d" % [int(itx.special), int(itx.upgrade)])
		hist.append("%d:%s" % [t, "+".join(hflags) if not hflags.is_empty() else "-"])
		if hist.size() > 30:
			hist.pop_front()
		if itx != null:
			if itx.sig:
				lastSig = t
				presses.append("%d:sig" % t)
			if itx.sigHeld:
				lastSigHeld = t
			if itx.rsStart:
				lastRs = t
				presses.append("%d:rsStart(dir %d lvl %d)" % [t, int(itx.rsDir), int(itx.rsLevel)])
		if t >= t0 and t <= t1:
			var a = S.fighters[0]
			var b = S.fighters[1]
			for e in S.out.fx:
				var isBeam: bool = false
				var kind: String = ""
				var text: String = ""
				if e.type == "cue":
					kind = str(e.kind)
					text = str(e.text)
					isBeam = kind.begins_with("beam") or kind in ["arc_send", "driver_fire", "driver_hold"]
				elif e.type == "beam_outcome":
					kind = "beam_outcome"
					text = str(e.get("kind"))
					isBeam = true
				if not isBeam:
					continue
				kinds[kind + ":" + text] = int(kinds.get(kind + ":" + text, 0)) + 1
				var ins: Array = []
				if itx != null:
					for k in ["light", "heavy", "sig", "dodge", "guard", "sigHeld", "rsStart", "rsHeld", "rsRelease", "transform", "power", "sprint"]:
						if itx.get(k):
							ins.append(k)
					ins.append("mask %d" % int(itx.stanceMask))
					ins.append("intent.mode %d, fighter act.mode %d (before the tick %d)" % [int(itx.mode), int(a.act.mode), mBefore])   # -1 auto, 0 physical, 1 energy: was a B beam thrown from the energy layer (EP, 2026-11-08)
				if kind == "beam_charge" and text == "start" and int(e.get("actor")) == 0:
					var qs: Array = []
					for qe in a.act.queue:
						qs.append("[w%d m%d e%d t%d]" % [int(qe[0]), int(qe[1]), int(qe[2]), int(qe[3])])
					print("BEAMPRE t=%d queue now %s ; last 24 ticks of slot 0: %s" % [t, " ".join(qs) if not qs.is_empty() else "empty", " ".join(hist.slice(maxi(0, hist.size() - 24)))])
				if kind == "beam_charge" and text == "start":
					var exs = DirBrawl.exOf(S)   # what exchange the beam is: kind, template, branch, and the pair's gap in body heights (the close band is 3)
					print("BEAMEX t=%d exchange kind=%s tpl=%s branch=%s A=%d gap %.2f bh stick-beam move on %s" % [t, str(exs.kind) if exs != null else "none", str(exs.tpl) if exs != null else "", str(exs.branch) if exs != null else "", S.fighters.find(exs.A) if exs != null else -1, DirBands.dist(a, b) / DirInterrupt.BH, str(DirBeamMove.on())])
				print("BEAM t=%d %s:%s actor=%d | s0y=%.0f z=%.0f %s tier %d | s1 dx=%.0f y=%.0f z=%.0f %s tier %d | in=[%s] since sig %d held %d rs %d" % [
					t, kind, text, int(e.get("actor")), a.y, a.z, str(a.state), int(a.tier), SimWrap.sdx(a.x, b.x), b.y, b.z, str(b.state), int(b.tier),
					", ".join(ins), t - lastSig, t - lastSigHeld, t - lastRs])
		S.out.fx.clear()
		S.out.feed.clear()
	print("PRESSES " + str(presses.size()) + " " + ", ".join(presses.slice(0, 120)))
	print("SUMMARY beam events " + JSON.stringify(kinds))
	quit()
