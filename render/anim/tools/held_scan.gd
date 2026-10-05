extends SceneTree
## Held-pose lint (Legal's held rules h01 to h03, docs/legal/movegen-banned.json `held`; RL-081): every pose a fighter holds for 12 ticks or more is checked against the numbers pose_lint's Legal rules
## use. NOT a gate (anim_check does not run it): it lists which poses fail, for Legal and the EP to see first. Beside joint_scan.
##   h01  any pose held 12 ticks or more keeps its hands out of the hip zone (x 14 or less, height 24 to 44), hands at least a shoulder width (20) apart if both are low (under --low, default 60),
##        and no hand above 80
##   h02  no held crossed forearms (the hands cross the midline: one on each side of it past it), no held arms-wide invitation (both hands out wide: |z| of --wide, default 32, or more)
##   h03  a tell is its own stance: never a crouch (the crouched family, or the hips 8 or lower) with both hands closed fists at the sides (the scream is not a pose: Audio's and VFX's)
## What counts as held (the sources, listed on each row): a phase of a sequence or an entry of 12 ticks or more (its own ticks, or its share of the sequence's length); a pair_live role's pose
## held `ticks` of 12 or more, and the charge and full poses of a charged shot (held until the release); a gesture's pose held 12 ticks or more; and every pose whose name says it is held
## (`.hold.`, `ready_`, the stances): their duration is the sim's or the match's, so they count. The rival's On the Chin lift and the take-it stance are rule h02's own exception (his alone).
##   godot --headless --path . -s res://render/anim/tools/held_scan.gd -- [--md=docs/animation/held-lint.md] [--json=out.json] [--low=60] [--wide=32] [--list]
const DT := 1.0 / 60.0
const SHOULDER := 20.0
var low: float = 60.0
var wide: float = 32.0
var md_out: String = ""
var json_out: String = ""
var list_all: bool = false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--md="):
			md_out = a.substr(5)
		elif a.begins_with("--json="):
			json_out = a.substr(7)
		elif a.begins_with("--low="):
			low = float(a.substr(6))
		elif a.begins_with("--wide="):
			wide = float(a.substr(7))
		elif a == "--list":
			list_all = true
	AnimData.load_waves = true
	_run.call_deferred()


func _held(held: Dictionary, pose: String, ticks: float, source: String) -> void:
	if pose == "" or not AnimData.raw.has(pose):
		return
	var e: Dictionary = held.get(pose, {"sources": [], "ticks": 0.0})
	e.ticks = maxf(float(e.ticks), ticks)
	if not (e.sources as Array).has(source):
		(e.sources as Array).append(source)
	held[pose] = e


func _run() -> void:
	AnimRig.setup()
	AnimData.load_all()
	AnimData.ensure_fighter("KAI")
	AnimData.ensure_fighter("VORR")
	var held: Dictionary = {}
	# 1. sequences and entries: a phase of 12 ticks or more
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
	# 2. pair_live: a role's pose held 12 ticks or more; a charged shot's charge and full poses (held to the release)
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
	# 3. poses whose name says they are held, and the stances
	for id in AnimData.raw:
		var s: String = String(id)
		if s.contains(".hold.") or s.contains(".ready_") or s.begins_with("stance."):
			_held(held, s, 999.0, "named held (duration by the event or the match)")
	# the rules
	var fails: Array = []
	var ids: Array = held.keys()
	ids.sort()
	for pid in ids:
		var d: Dictionary = AnimData.raw[pid]
		var hr = d.get("hand_r")
		var hl = d.get("hand_l")
		var hs: Dictionary = d.get("hands", {})
		var why: Array = []
		for hv in [["r", hr], ["l", hl]]:
			var t = hv[1]
			if t == null:
				continue
			if float(t[0]) <= 14.0 and float(t[1]) >= 24.0 and float(t[1]) <= 44.0:
				why.append("h01 the %s hand is in the hip zone (%.0f, %.0f)" % [hv[0], float(t[0]), float(t[1])])
			if float(t[1]) > 80.0:
				why.append("h01 the %s hand is above 80 (%.0f)" % [hv[0], float(t[1])])
		if hr != null and hl != null:
			var dist: float = Vector3(float(hr[0]) - float(hl[0]), float(hr[1]) - float(hl[1]), float(hr[2]) - float(hl[2])).length()
			if float(hr[1]) < low and float(hl[1]) < low and dist < SHOULDER:
				why.append("h01 both hands low and %.1f apart (%.2f shoulder widths)" % [dist, dist / SHOULDER])
			if float(hr[2]) < -2.0 and float(hl[2]) > 2.0:
				why.append("h02 the forearms cross the midline (right z %.0f, left z %.0f)" % [float(hr[2]), float(hl[2])])
			if absf(float(hr[2])) >= wide and absf(float(hl[2])) >= wide and float(hr[2]) * float(hl[2]) < 0.0:
				why.append("h02 both arms wide (z %.0f and %.0f)" % [float(hr[2]), float(hl[2])])
			var crouch: bool = String(d.get("family", "")) == "crouched" or (d.get("hips") != null and float(d.hips[1]) <= -8.0)
			if crouch and String(hs.get("r", "")) == "fist" and String(hs.get("l", "")) == "fist" and float(hr[0]) <= 24.0 and float(hl[0]) <= 24.0:
				why.append("h03 a crouch with both fists at the sides")
		if not why.is_empty():
			fails.append({"pose": pid, "why": why, "sources": held[pid].sources, "ticks": held[pid].ticks})
	print("held-pose lint (h01 to h03): %d poses held 12 ticks or more, %d fail" % [ids.size(), fails.size()])
	for f in fails:
		print("  %-34s %s   [%s]" % [f.pose, "; ".join(f.why), "; ".join((f.sources as Array).slice(0, 2))])
	if list_all:
		for pid in ids:
			print("  held: %s  %s" % [pid, held[pid].sources])
	if json_out != "":
		var jf := FileAccess.open(json_out, FileAccess.WRITE)
		jf.store_string(JSON.stringify({"tool": "held_scan", "held": ids.size(), "fails": fails, "low": low, "wide": wide}))
		jf.close()
	if md_out != "":
		var lines: PackedStringArray = ["# Held-pose lint: Legal's h01 to h03", "", "Generated by `render/anim/tools/held_scan.gd`. **Not a gate**: it lists the poses held 12 ticks or more that fail the held rules (`docs/legal/movegen-banned.json` `held`; RL-081), for Legal and the EP to see first. %d poses are held; **%d fail**." % [ids.size(), fails.size()], "",
			"Numbers: shoulder width 20; hip zone x 14 or less at height 24 to 44; no hand above 80; both hands low means both under %.0f high; arms wide means both hands %.0f or more out to opposite sides; a crouch is the crouched family or hips 8 down. h02's arms-wide exception (On the Chin's take-it stance) is the rival's alone." % [low, wide], "",
			"| Pose | Held (ticks) | What fails | Where it is held |", "| :--- | ---: | :--- | :--- |"]
		for f in fails:
			lines.append("| `%s` | %s | %s | %s |" % [f.pose, ("to the event" if float(f.ticks) >= 999.0 else "%.0f" % float(f.ticks)), "; ".join(f.why), "; ".join((f.sources as Array).slice(0, 3))])
		var mf := FileAccess.open(md_out, FileAccess.WRITE)
		mf.store_string("\n".join(lines) + "\n")
		mf.close()
	quit(0)
