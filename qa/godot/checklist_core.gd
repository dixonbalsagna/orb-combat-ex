extends RefCounted
## The Alpha match checklist (X-13, sprint A1, A-COMBAT-08): the ten things the criterion says a normal match of 6 to 8 minutes shows at least once, read from the match's event feed and the intents fed to it. Shared by checklist.gd (replays of saved play files)
## and orbs_player.gd (scripted matches). It only reads: call begin(S) at the start of a match, feed(S, t, intents) after each SimCore.step (before S.out.fx is cleared), result() at the end.
## The ten items and the test of each:
##   lap          a fighter's travel round the globe, summed with its sign, reaches the world's width (SimConst.W).
##   stances      each stance used: of Orb's five stances (none, LB guard, RB energy, RT power, LT manoeuvre) the layer bits slot 0's pad held (intent stanceMask & 15). Only a human slot has them; a computer's stances are not in the intent.
##   beam_off     a beam aimed and dodged by moving off its line: a beam_outcome of DODGE, ESCAPE or DEFLECT where the target had moved 150 units or more in height or depth since the beam's window opened (a tap dodge that left him where he stood does not count). Any such movement counts, so a target that was already in flight and moving is read as moving off the line: this test cannot tell a sidestep from incidental motion.
##   signatures   both signatures on Orb's inputs: each fighter threw a signature beam started by the right stick or by RT + B (a beam_stage cue just before the charge, or RT held at it). A computer's own beam is not on Orb's inputs and is listed as "computer".
##   launch       a `launch` event.
##   well         the gravity well's pull: an event or cue whose kind holds "well" or "gravity". The build has none until the well is built (GW1); then it reads as "no such event in this build".
##   crater       a `crater` event.
##   building     a building damaged: `building_hit`, `building_stage` or `building_fall`.
##   bystanders   bystanders scattering: an `evacuate` event, or a `crowd_state` event.
##   transform    a transformation: a `transform` event (a form taken).
## result() gives, for each item, seen, the first tick it was seen and a short detail.

var W: float = 9600.0
var items: Dictionary = {}
var _unw: Array = [0.0, 0.0]
var _prev: Array = [0.0, 0.0]
var _mask_seen: Array = [0, 0]
var _human: Array = [false, false]
var _stage_t: Array = [-100, -100]
var _win: Dictionary = {}   # shooter -> [tick, target index, target x, y, z]
var _sig: Array = [{}, {}]
var _t_last: int = 0


func begin(S) -> void:
	W = float(SimConst.W)
	items = {}
	for k in ["lap", "stances", "beam_off", "signatures", "launch", "well", "crater", "building", "bystanders", "transform"]:
		items[k] = {"seen": false, "tick": -1, "detail": ""}
	_unw = [0.0, 0.0]
	_prev = [S.fighters[0].x, S.fighters[1].x]
	_mask_seen = [0, 0]
	_human = [false, false]
	_stage_t = [-100, -100]
	_win = {}
	_sig = [{}, {}]


func _see(k: String, t: int, detail: String = "") -> void:
	if not bool(items[k].seen):
		items[k].seen = true
		items[k].tick = t
		items[k].detail = detail


func feed(S, t: int, intents: Array) -> void:
	_t_last = t
	for i in range(2):
		var f = S.fighters[i]
		_unw[i] += SimWrap.sdx(_prev[i], f.x)
		_prev[i] = f.x
		if absf(_unw[i]) >= W:
			_see("lap", t, "fighter %d travelled %.0f units round (the world is %.0f)" % [i, absf(_unw[i]), W])
		if i < intents.size() and intents[i] != null:
			_human[i] = true
			var m: int = int(intents[i].stanceMask) & 15
			_mask_seen[i] |= (16 if m == 0 else m)   # each layer bit as held (1 LB, 2 RB, 4 RT, 8 LT), and bit 16 for no layer held
	for e in S.out.fx:
		var ty: String = str(e.type)
		match ty:
			"launch":
				_see("launch", t)
			"crater":
				_see("crater", t)
			"building_hit", "building_stage", "building_fall":
				_see("building", t, ty)
			"evacuate", "crowd_state":
				_see("bystanders", t, ty)
			"transform":
				_see("transform", t)
			"beam_outcome":
				var a: int = int(e.actor)
				var kd: String = str(e.kind)
				if _win.has(a) and kd in ["DODGE", "ESCAPE", "DEFLECT"]:
					var w: Array = _win[a]
					var tg = S.fighters[int(w[1])]
					var moved: float = maxf(absf(tg.y - float(w[3])), absf(float(tg.z) - float(w[4])))
					if moved >= 150.0:
						_see("beam_off", t, "%s after moving %.0f off the line" % [kd, moved])
					elif not bool(items.beam_off.seen):
						items.beam_off.detail = "dodged by a tap, no move off the line (most we saw: %s, moved %.0f)" % [kd, moved]
		if ty == "cue":
			var k: String = str(e.kind)
			var a2: int = int(e.actor)
			if a2 >= 0 and a2 <= 1:
				if k == "beam_stage":
					_stage_t[a2] = t
				elif k == "beam_window" and str(e.text) == "start":
					var tgi: int = int(e.target) if int(e.target) >= 0 else 1 - a2
					var tg2 = S.fighters[tgi]
					_win[a2] = [t, tgi, tg2.x, tg2.y, float(tg2.z)]
				elif k == "beam_charge" and str(e.text) == "start":
					var src: String = "other"
					if S.fighters[a2].ai != null:
						src = "computer"
					elif t - int(_stage_t[a2]) <= 5:
						src = "stick"
					elif (int(S.fighters[a2].input.stanceMask) & 4) != 0:
						src = "rtb"
					_sig[a2][src] = int(_sig[a2].get(src, 0)) + 1
					if int(_sig[0].get("stick", 0)) + int(_sig[0].get("rtb", 0)) > 0 and int(_sig[1].get("stick", 0)) + int(_sig[1].get("rtb", 0)) > 0:
						_see("signatures", t, "both fighters threw one")
			var kl: String = str(e.kind).to_lower()
			if kl.contains("well") or kl.contains("gravity"):
				_see("well", t, str(e.kind))
		var tl: String = ty.to_lower()
		if ty != "cue" and (tl.contains("well") or tl.contains("gravity")):
			_see("well", t, ty)


func result() -> Dictionary:
	var out: Dictionary = items.duplicate(true)
	# stances: of none, LB (1), RB (2), RT (4), LT (8) which the human slots used
	var used: Array = []
	var names := {16: "none", 1: "LB", 2: "RB", 4: "RT", 8: "LT"}
	for i in range(2):
		if not bool(_human[i]):
			continue
		var got: Array = []
		for b in [16, 1, 2, 4, 8]:
			if (int(_mask_seen[i]) & b) != 0:
				got.append(names[b])
		used.append("slot %d: %s" % [i, ", ".join(got)])
		if got.size() >= 5:
			out.stances.seen = true
			out.stances.tick = _t_last
	out.stances.detail = "; ".join(used) if not used.is_empty() else "no human slot: a computer's stances are not in the intent"
	var s0: int = int(_sig[0].get("stick", 0)) + int(_sig[0].get("rtb", 0))
	var s1: int = int(_sig[1].get("stick", 0)) + int(_sig[1].get("rtb", 0))
	out.signatures.seen = s0 > 0 and s1 > 0
	out.signatures.detail = "fighter 0 %s, fighter 1 %s" % [JSON.stringify(_sig[0]), JSON.stringify(_sig[1])]
	if str(out.well.detail) == "" and not bool(out.well.seen):
		out.well.detail = "no such event in this build"
	return out
