class_name AnimHeldLint
extends RefCounted
## Held-pose lint (Legal's held rules h01 to h03 as scoped by RL-087: docs/legal/movegen-banned.json `held` and `heldScope`): every pose a fighter holds for 12 ticks or more is checked against the
## scope's tests. Beside joint_scan: `tools/held_scan.gd` is the command line (`--strict` exits 1 on any failure) and anim_check's `_test_held` is the gate.
##   pair test (every held pose, every class)   fails only if both hands are within 10 of each other and both in the hip zone (x 14 or less, height 24 to 44), or both wrists are forward and within 7
##                                              (wrists_together). Exempt: a named gesture where one hand holds or brushes the other (the cuff, the dusting, a tap), the body upright
##   emitter test (classes charge, tell, signature, energy, hold)   fails if the hand that emits or strikes next (the one reaching farther forward) is an open or clawed hand in the hip zone with
##                                              its wrist at x 8 or less, or if any hand is above 82. A closed fist at the hip and a relaxed free hand pass
##   h02 arms wide (the same classes, and any held pose that is not a gesture with bent elbows)   fails if both elbows are within 25 degrees of straight and both hands are 32 or more out to opposite
##                                              sides; outside the rival's On the Chin. A shrug (elbows bent 40 or more) is not arms wide
##   h03   a crouch (the crouched family, or hips 8 down) with both hands closed fists at the sides, in a tell or a signature
## A pose's class: a `_legal.class`-style mark where a pose has one (none do yet: it would need a schema key), else the family of the sequence or pose by name (CLASS_RULES below, from the scope's
## `classes`: rest, gesture, charge, tell, signature, energy, hold); an unmarked pose is rest. What counts as held: a sequence or entry phase of 12 ticks or more; a pair_live role's pose held that
## long, the charge and full poses of a charged shot, a gesture's pose; and every pose named `.hold.`, `ready_`, a stance or a stance cue (their length is the sim's).
## The scope's thresholds are Legal's, written in its file as prose (RL-087); they are constants here, named for the rule they come from. The file is read for the scope's presence and its class list.
##   godot --headless --path . -s res://render/anim/tools/held_scan.gd -- [--md=docs/animation/held-lint.md] [--json=out.json] [--strict] [--list]
const DT := 1.0 / 60.0
const SHOULDER := 20.0
const PAIR_APART := 10.0          # pair test: both hands within this of each other, both in the hip zone
const PAIR_WRISTS := 7.0          # pair test: both wrists forward and within this (wrists_together)
const HIP_X := 14.0               # the hip zone: x this or less, height 24 to 44
const EMIT_WRIST_X := 8.0         # emitter test: an open hand in the hip zone with its wrist at x this or less
const HAND_TOP := 82.0            # emitter test: any hand above this (80 and a tolerance of 2)
const ARM_STRAIGHT := 25.0        # h02: elbows within this many degrees of straight
const ARM_WIDE := 32.0            # h02: both hands this far out to opposite sides
const SHRUG_BEND := 40.0          # h02: a bend this much or more is a shrug, not arms wide
## the scope's classes by the family of the pose or sequence (prefix of its id); the first match wins. Poses that match none are rest.
const CLASS_RULES := [
	["rs.hold.sig_tell", "tell"], ["ps.hold.sig_tell", "tell"], ["rs.tell.", "tell"], ["ps.tell.", "tell"],
	["rs.hold.sig_end", "tell"], ["ps.hold.sig_end", "tell"], ["rs.end.", "tell"], ["ps.end.", "tell"],
	["stance.", "tell"], ["cue.", "tell"],
	["ag.hold.charge", "charge"], ["pn.hold.brace", "charge"], ["charge.hold", "charge"], ["beam.charge", "charge"],
	["ag.taunt", "gesture"], ["pg.taunt", "gesture"], ["rw.taunt", "gesture"], ["rw.drop_the_act", "gesture"], ["pi.", "gesture"], ["ri.", "gesture"], ["in.cuff", "gesture"], ["emote.", "gesture"],
	["ls.ready_", "rest"], ["ls.", "rest"], ["rv.", "energy"], ["pn.", "energy"], ["pg.", "energy"], ["en.", "energy"], ["rw.", "energy"], ["pf.", "energy"], ["beam.", "energy"], ["pe.", "energy"],
	["zp.hold", "hold"],
]
## a named gesture where one hand holds or brushes the other hand or wrist: exempt from the pair test (the cuff, the dusting, the close taunt's tap)
const BRUSH := ["in.cuff.", "rw.taunt_dust_plate.", "rw.taunt_close.", "pg.taunt_close"]

static func _held(held: Dictionary, pose: String, ticks: float, source: String) -> void:
	if pose == "" or not AnimData.raw.has(pose):
		return
	var e: Dictionary = held.get(pose, {"sources": [], "ticks": 0.0})
	e.ticks = maxf(float(e.ticks), ticks)
	if not (e.sources as Array).has(source):
		(e.sources as Array).append(source)
	held[pose] = e


static func _class_of(pid: String) -> String:
	for r in CLASS_RULES:
		if pid.begins_with(String(r[0])):
			return String(r[1])
	return "rest"


static func _bend(p: AnimPose, bone: String) -> float:
	var v: Vector3 = p.q[AnimRig.index[bone]] * Vector3(0, -1, 0)
	return rad_to_deg(atan2(v.x, -v.y))


static func _in_hip(t) -> bool:
	return t != null and float(t[0]) <= HIP_X and float(t[1]) >= 24.0 and float(t[1]) <= 44.0


## The scan: {ok (the scope was found), held (the count), classes, fails: [{pose, class, why, sources, ticks}], numbers: [text]}. Needs the data loaded (load_all with waves, or load_every_wave).
static func scan() -> Dictionary:
	AnimData.load_every_wave()
	AnimData.ensure_fighter("KAI")
	AnimData.ensure_fighter("VORR")
	var ban = JSON.parse_string(FileAccess.get_file_as_string("res://docs/legal/movegen-banned.json"))
	var scope: Dictionary = ban.get("heldScope", {}) if ban is Dictionary else {}
	var scope_ok: bool = scope.has("classes") and scope.has("pairTest") and scope.has("emitterTest") and scope.has("armsWideTest")
	var held: Dictionary = {}
	for id in AnimData.entries:
		var en = AnimData.entries[id]
		var ph: Array = en.phases
		var fixed: float = 0.0
		var sumw: float = 0.0
		for p in ph:
			if p.has("ticks"):
				fixed += float(p.ticks)
			else:
				sumw += float(p.get("w", 1.0))
		var flex: float = maxf(float(en.get("dur", fixed)) - fixed, 1.0)
		for p in ph:
			var tk: float = float(p.ticks) if p.has("ticks") else flex * float(p.get("w", 1.0)) / maxf(sumw, 0.001)
			if tk >= 12.0:
				_held(held, String(p.pose), tk, "%s (%.0f ticks)" % [id, tk])
	for fk in AnimData.pair.get("roles", {}):
		var role: Dictionary = AnimData.pair.roles[fk]
		for rk in role:
			var v = role[rk]
			if v is Dictionary:
				if v.has("pose") and float(v.get("ticks", 0)) >= 12.0:
					_held(held, String(v.pose), float(v.ticks), "%s.%s (%.0f ticks)" % [fk, rk, float(v.ticks)])
				if rk == "charged":
					for k2 in ["charge", "full"]:
						_held(held, String(v.get(k2, "")), 999.0, "%s.charged.%s (held to the release)" % [fk, k2])
					var rel = v.get("release")
					if rel is Dictionary and float(rel.get("ticks", 0)) >= 12.0:
						_held(held, String(rel.pose), float(rel.ticks), "%s.charged.release (%.0f ticks)" % [fk, float(rel.ticks)])
				if rk == "gestures":
					for ik in v:
						var g: Dictionary = v[ik]
						if not AnimData.entries.has(String(g.seq)) and float(g.get("hold", 0.0)) * 60.0 >= 12.0:
							_held(held, String(g.seq), float(g.hold) * 60.0, "%s gesture %s (%.0f ticks)" % [fk, ik, float(g.hold) * 60.0])
	for id in AnimData.raw:
		var s: String = String(id)
		if s.contains(".hold.") or s.contains(".ready_") or s.begins_with("stance."):
			_held(held, s, 999.0, "named held (duration by the event or the match)")
	var fails: Array = []
	var ids: Array = held.keys()
	ids.sort()
	var classes: Dictionary = {}
	for pid in ids:
		var d: Dictionary = AnimData.raw[pid]
		var cls: String = _class_of(pid)
		classes[cls] = int(classes.get(cls, 0)) + 1
		var hr = d.get("hand_r")
		var hl = d.get("hand_l")
		var hs: Dictionary = d.get("hands", {})
		var why: Array = []
		var brush: bool = false
		for b in BRUSH:
			brush = brush or pid.begins_with(b)
		if hr != null and hl != null:
			var dist: float = Vector3(float(hr[0]) - float(hl[0]), float(hr[1]) - float(hl[1]), float(hr[2]) - float(hl[2])).length()
			if not brush:
				if dist <= PAIR_APART and _in_hip(hr) and _in_hip(hl):
					why.append("pair: both hands in the hip zone and %.1f apart" % dist)
				if dist <= PAIR_WRISTS and float(hr[0]) >= 16.0 and float(hl[0]) >= 16.0:
					why.append("pair: both wrists forward and %.1f apart" % dist)
		if cls in ["charge", "tell", "signature", "energy", "hold"]:
			var emit = hr
			var emit_side: String = "r"
			if hr != null and hl != null and float(hl[0]) > float(hr[0]):
				emit = hl
				emit_side = "l"
			if emit != null:
				var st: String = String(hs.get(emit_side, "open"))
				if (st == "open" or st == "claw") and _in_hip(emit) and float(emit[0]) <= EMIT_WRIST_X:
					why.append("emitter: the %s hand (%s) is in the hip zone with its wrist at x %.0f" % [emit_side, st, float(emit[0])])
			for hv in [["r", hr], ["l", hl]]:
				if hv[1] != null and float(hv[1][1]) > HAND_TOP:
					why.append("emitter: the %s hand is above %.0f (%.0f)" % [hv[0], HAND_TOP, float(hv[1][1])])
		if hr != null and hl != null and not pid.begins_with("rv.on_the_chin"):
			var p: AnimPose = AnimData.pose(pid)
			var br: float = _bend(p, "forearm_r")
			var bl: float = _bend(p, "forearm_l")
			var wide: bool = absf(float(hr[2])) >= ARM_WIDE and absf(float(hl[2])) >= ARM_WIDE and float(hr[2]) * float(hl[2]) < 0.0
			if wide and br <= ARM_STRAIGHT and bl <= ARM_STRAIGHT:
				why.append("h02: both arms near straight (elbows %.0f and %.0f degrees) and %.0f and %.0f out" % [br, bl, float(hr[2]), float(hl[2])])
		if hr != null and hl != null and (cls == "tell" or cls == "signature"):
			var crouch: bool = String(d.get("family", "")) == "crouched" or (d.get("hips") != null and float(d.hips[1]) <= -8.0)
			if crouch and String(hs.get("r", "")) == "fist" and String(hs.get("l", "")) == "fist" and float(hr[0]) <= 24.0 and float(hl[0]) <= 24.0:
				why.append("h03: a crouch with both fists at the sides")
		if not why.is_empty():
			fails.append({"pose": pid, "class": cls, "why": why, "sources": held[pid].sources, "ticks": held[pid].ticks})
	# the numbers Legal asked for
	var nums: Array = []
	if AnimData.raw.has("rv.hold.fin_held"):
		var a = AnimData.raw["rv.hold.fin_held"]
		nums.append("rv.hold.fin_held: the hands are %.1f apart (right %s, left %s; the zone test needs over 10)" % [Vector3(float(a.hand_r[0]) - float(a.hand_l[0]), float(a.hand_r[1]) - float(a.hand_l[1]), float(a.hand_r[2]) - float(a.hand_l[2])).length(), a.hand_r, a.hand_l])
	if AnimData.raw.has("ag.taunt.shrug"):
		var sp: AnimPose = AnimData.pose("ag.taunt.shrug")
		var sa = AnimData.raw["ag.taunt.shrug"]
		nums.append("ag.taunt.shrug: the elbows are bent %.0f (right) and %.0f (left) degrees; the hands are %.0f and %.0f out (%d ticks held)" % [_bend(sp, "forearm_r"), _bend(sp, "forearm_l"), float(sa.hand_r[2]), float(sa.hand_l[2]), int(held.get("ag.taunt.shrug", {}).get("ticks", 0))])
	if AnimData.entries.has("ls.ready_e"):
		var le = AnimData.entries["ls.ready_e"]
		var fixed2: float = 0.0
		var sumw2: float = 0.0
		for p in le.phases:
			if p.has("ticks"):
				fixed2 += float(p.ticks)
			else:
				sumw2 += float(p.get("w", 1.0))
		var rise_ticks: float = 0.0
		for p in le.phases:
			if String(p.pose) == "ls.ready_e.rise":
				rise_ticks = float(p.ticks) if p.has("ticks") else maxf(float(le.get("dur", fixed2)) - fixed2, 1.0) * float(p.get("w", 1.0)) / maxf(sumw2, 0.001)
		var rp: AnimPose = AnimData.pose("ls.ready_e.rise")
		var ra = AnimData.raw["ls.ready_e.rise"]
		nums.append("ls.ready_e.rise: the rise phase lasts %.0f ticks of a %d-tick steadying (12 or fewer passes wide); the hands are %.0f and %.0f out (under 28 is arms forward), the elbows bent %.0f and %.0f degrees" % [rise_ticks, int(le.get("dur", 0)), float(ra.hand_r[2]), float(ra.hand_l[2]), _bend(rp, "forearm_r"), _bend(rp, "forearm_l")])
	if AnimData.raw.has("rv.chin_beam.beam_out"):
		var bo = AnimData.raw["rv.chin_beam.beam_out"]
		nums.append("rv.chin_beam.beam_out: the hands are %.1f apart (right %s, left %s; Legal wants 16 or more)" % [Vector3(float(bo.hand_r[0]) - float(bo.hand_l[0]), float(bo.hand_r[1]) - float(bo.hand_l[1]), float(bo.hand_r[2]) - float(bo.hand_l[2])).length(), bo.hand_r, bo.hand_l])
	return {"ok": scope_ok, "held": ids.size(), "classes": classes, "fails": fails, "numbers": nums, "ids": ids, "held_map": held}
