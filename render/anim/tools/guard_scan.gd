extends SceneTree
## The contact-key pass (docs/animation/guard-pass.md): on the contact key of every strike, the hand (or hands, in a kick) that is not striking stays near the
## stance guard. Measured in the chest's own frame, so a torso turned into a blow carries its guard with it: the distance from the free hand to the nearer of
## the guard's two hands (`stance.aggressive`).
##   godot --headless --path . -s res://render/anim/tools/guard_scan.gd -- [--goal-hand=20] [--goal-foot=30] [--list=12] [--strict] [--fit=out.json]
## --strict exits 1 when any piece is over its goal. --fit writes, for each piece over its goal, the free-hand target that lands at 0.7 of the goal (the rows of
## data/anim/guard_pass.json, which wave_gen.mjs applies when a wave is generated).

const KEEP := 0.7   # a fitted hand lands at this fraction of the goal, so a pose has room


static func _frame(p: AnimPose) -> Dictionary:
	var gq: Array[Quaternion] = []
	var gp := PackedVector3Array()
	gq.resize(AnimRig.N)
	gp.resize(AnimRig.N)
	AnimPose.fk(p.q, p.hips, gq, gp)
	var ix: Dictionary = AnimRig.index
	return {"b": Basis(gq[int(ix["spine_2"])]), "o": gp[int(ix["spine_2"])], "hand_r": gp[int(ix["hand_r"])], "hand_l": gp[int(ix["hand_l"])]}


static func _local(fr: Dictionary, key: String) -> Vector3:
	return (fr.b as Basis).inverse() * ((fr[key] as Vector3) - (fr.o as Vector3))


## Every (contact key, free side) of the loaded strikes: {id, side, limb, err, goal, fit} (fit: the model-space target that brings the hand to KEEP of the goal, or empty).
## A strike with a second limb (a two-handed blow) has no free hand and is left out.
static func rows(goal_hand: float = 20.0, goal_foot: float = 30.0, fit: bool = false) -> Array:
	AnimData.load_every_wave()
	var gfr: Dictionary = _frame(AnimData.pose("stance.aggressive"))
	var gl := {"r": _local(gfr, "hand_r"), "l": _local(gfr, "hand_l")}
	var res: Array = []
	var seen := {}
	for id in AnimData.keysets:
		var ks: Dictionary = AnimData.keysets[id]
		var limb: String = String(ks.get("limb", ""))
		if String(ks.get("limb2", "")) != "":
			continue
		var contact: String = ""
		for k in ks.get("keys", []):
			if String(k.get("role", "")) == "contact":
				contact = String(k.pose)
		if contact == "" or not AnimData.raw.has(contact) or seen.has(contact):
			continue
		seen[contact] = true
		var sides: Array = []
		var goal: float = goal_hand
		if limb.begins_with("hand_"):
			sides = ["l" if limb.ends_with("r") else "r"]
		elif limb.begins_with("foot_"):
			sides = ["r", "l"]
			goal = goal_foot
		var sk: Dictionary = (AnimData.raw[contact] as Dictionary).duplicate(true)
		var fr: Dictionary = _frame(AnimPose.bake(contact, sk))
		for sd in sides:
			var cur: Vector3 = _local(fr, "hand_" + sd)
			var od: String = "l" if sd == "r" else "r"
			var d_same: float = (cur - gl[sd]).length()
			var d_other: float = (cur - gl[od]).length()
			var err: float = minf(d_same, d_other)
			var row := {"id": contact, "side": sd, "limb": limb, "err": err, "goal": goal, "fit": {}}
			if fit and err > goal:
				var want: String = sd if d_same <= d_other else od
				var t: float = clampf(1.0 - goal * KEEP / err, 0.0, 1.0)
				var w: Vector3 = (fr.b as Basis) * cur.lerp(gl[want], t) + (fr.o as Vector3)
				var sk2: Dictionary = sk.duplicate(true)
				sk2["hand_" + sd] = [snappedf(w.x, 0.1), snappedf(w.y, 0.1), snappedf(w.z, 0.1)]
				var fr2: Dictionary = _frame(AnimPose.bake(contact + "#fit", sk2))
				var c2: Vector3 = _local(fr2, "hand_" + sd)
				row["fit"] = {"target": sk2["hand_" + sd], "now": minf((c2 - gl[sd]).length(), (c2 - gl[od]).length())}
			res.append(row)
	return res


func _initialize() -> void:
	var goal_hand: float = 20.0
	var goal_foot: float = 30.0
	var strict: bool = false
	var list_n: int = 12
	var fit_out: String = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--goal-hand="):
			goal_hand = float(a.substr(12))
		elif a.begins_with("--goal-foot="):
			goal_foot = float(a.substr(12))
		elif a.begins_with("--list="):
			list_n = int(a.substr(7))
		elif a.begins_with("--fit="):
			fit_out = a.substr(6)
		elif a == "--strict":
			strict = true
	var rs: Array = rows(goal_hand, goal_foot, fit_out != "")
	rs.sort_custom(func(a, b): return float(a.err) > float(b.err))
	var over: int = 0
	var bins := {"<=10": 0, "10-20": 0, "20-30": 0, ">30": 0}
	var plan := {}
	for r in rs:
		if float(r.err) > float(r.goal):
			over += 1
		var e: float = float(r.err)
		bins["<=10" if e <= 10.0 else ("10-20" if e <= 20.0 else ("20-30" if e <= 30.0 else ">30"))] += 1
		if not (r.fit as Dictionary).is_empty():
			var row: Dictionary = plan.get(r.id, {})
			row["hand_" + String(r.side)] = r.fit.target
			row["was"] = snappedf(float(r.err), 0.1)
			row["now"] = snappedf(float(r.fit.now), 0.1)
			plan[r.id] = row
	print("guard scan: %d (key, free hand) rows, %d over their goal (hand %.0f, foot %.0f); distance from the guard, units: %s" % [rs.size(), over, goal_hand, goal_foot, str(bins)])
	for i in range(mini(list_n, rs.size())):
		var r = rs[i]
		print("  %5.1f (goal %2.0f)  %s  free hand %s, striking with %s" % [r.err, r.goal, r.id, r.side, r.limb])
	if fit_out != "":
		var f := FileAccess.open(fit_out, FileAccess.WRITE)
		f.store_string(JSON.stringify(plan, " "))
		f.close()
		print("guard scan: %d pieces fitted into %s" % [plan.size(), fit_out])
	if strict and over > 0:
		print("guard scan FAILED (%d)" % over)
		quit(1)
		return
	quit()
