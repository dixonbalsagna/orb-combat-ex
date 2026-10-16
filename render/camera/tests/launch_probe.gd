extends SceneTree
## After a launch: where is the launched fighter on the screen, and is his return seen? (Orb, 2026-10-16: "the split screen didn't
## really catch up with them ... I had no idea what they were doing until they rushed back at me at full speed and got some cheap
## hits".) AI against AI through the real scene (render/main.tscn, the host's own step, the compositor attached), headless, the
## `ai` scenario's writes (forms readied at 300 and 1500, a tier at 900, a stage at 1200). For every launch event it follows the
## victim until the next blow that lands between the pair (or `--span` seconds) and reads the displayed picture each tick:
##   off      ticks the victim is not inside the picture (a pane, on its side of the divider, or the one view)
##   longest  the longest run of those
##   last1s   ticks of the final second before the next blow that he is off the picture ("his return unseen")
##   size     his apparent height in pixels when the blow lands
##   gap      the distance between the pair when the blow lands, in body heights
## The one the player controls is slot 0; victims of slot 1 are the ones Orb meant.
##   godot --headless --path . --script res://render/camera/tests/launch_probe.gd -- --seed=1 --ticks=3600 [--hold] [--bundle] [--reduced]

const DT: float = 1.0 / 60.0
const FORM_TICKS: Array = [300, 1500]

var main: Node
var seed_v: int = 1
var ticks: int = 3600
var hold: bool = false
var bundle: bool = false
var reduced: bool = false
var span_s: float = 8.0
var extra: Array = []   # switch names for later builds, e.g. --sw=name
var verbose: bool = false
var human0: bool = false
var nobundle: bool = false
var ordinary: bool = false
var follow: String = ""
var trace0: int = -1


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed_v = int(a.substr(7))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--span="):
			span_s = float(a.substr(7))
		elif a == "--hold":
			hold = true
		elif a == "--bundle":
			bundle = true
		elif a == "--reduced":
			reduced = true
		elif a == "--verbose":
			verbose = true
		elif a == "--human0":
			human0 = true
		elif a == "--nobundle":
			nobundle = true
		elif a == "--ordinary":
			ordinary = true
		elif a.begins_with("--follow="):
			follow = a.substr(9)
		elif a.begins_with("--trace="):
			trace0 = int(a.substr(8))
		elif a.begins_with("--sw="):
			extra.append(a.substr(5))
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	vpn.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _on_picture(fr: SplitFrame, f, vw: float, vh: float) -> Dictionary:
	var best: Dictionary = {"on": false, "px": 0.0}
	for pi in range(2):
		if not fr.shows(pi):
			continue
		var sp: Vector2 = fr.screen_pos(pi, f.x, f.y + CamParams.CHEST, float(f.z))
		var inside: bool = sp.x >= 0.0 and sp.x <= vw and sp.y >= 0.0 and sp.y <= vh
		if inside and fr.feather <= 0.001 and fr.sep >= 0.5:
			var side: float = (sp - fr.c).dot(fr.n)
			inside = side <= 0.0 if pi == 0 else side > 0.0
		if inside:
			var px: float = fr.apparent_height(pi, f.x, f.y, float(f.z))
			if not bool(best["on"]) or px > float(best["px"]):
				best = {"on": true, "px": px, "pane": pi}
	return best


func _run() -> void:
	await process_frame
	var sv := SplitView.new()
	main.split_view = sv
	main.add_child(sv)
	main._sync_split_options()
	sv.attach(main)
	if hold:
		sv.set_launch_hold(true)
	if bundle:
		sv.set_flash_bundle(true, false)
	for nm in extra:
		var parts: PackedStringArray = nm.split(":")
		if sv.has_method("set_" + parts[0]):
			sv.call("set_" + parts[0], true if parts.size() < 2 else bool(int(parts[1])))
		else:
			push_error("no switch " + nm)
	main.host.vfx.auto_quality = false
	main.host.vfx.destruction_enabled = true
	main.start_match(seed_v, {"p1": true, "p2": true}, null)
	if human0:
		main.split_rig.test_human_slot = 0
	if nobundle:
		main.split_rig.flash_bundle = false
	if ordinary:
		main.ui_hud.opts["reduce_flashing"] = false
	if follow != "":
		main.ui_hud.opts["camera_launch_follow"] = follow   # applied each frame by main._sync_split_options
	main.started = true
	var host: SimHost = main.host
	host.vfx.force_reduced = reduced
	host.release_all()
	var rig: SplitRig = main.split_rig
	var vw: float = rig.vw
	var vh: float = rig.vh
	var pend_launch: Array = []   # victim slots launched this tick
	var pend_hit: Array = []      # [attacker, victim] landed this tick
	var cb := func(evs: Array, _lines: Array):
		for e in evs:
			if e.type == "launch":
				pend_launch.append(int(e.actor))
			elif e.type == "damage" and float(e.amount) > 0.0 and int(e.attacker) >= 0 and int(e.victim) >= 0 and int(e.attacker) != int(e.victim):
				pend_hit.append([int(e.attacker), int(e.victim)])
	host.drained.connect(cb)
	var open_: Array = []   # {v, t0, off, run, longest, trail (array of bools)}
	var done: Array = []
	var guard: int = 0
	while host.ticks < ticks and guard < ticks * 4 and host.S.game.ko == null:
		_drive(host.ticks, host.S)
		var before: int = host.ticks
		main.frame(DT)
		guard += 1
		if host.ticks == before:
			continue
		var S: SimState = host.S
		var fr: SplitFrame = rig.current()
		for v in pend_launch:
			if verbose:
				print("LM t ", host.ticks, " victim ", v, " follow ", rig.launch_follow, " mode ", rig._launch_mode(S, int(v)), " human ", rig.test_human_slot, " sep ", snappedf(rig.sep, 0.01), " chase ", rig.chase_slot, " lv ", rig._launch_victim, " solo ", rig.solo_kind)
			var busy: bool = false
			for o in open_:
				if int(o.v) == int(v):
					busy = true
			if not busy:
				open_.append({"v": int(v), "t0": host.ticks, "off": 0, "run": 0, "longest": 0, "trail": [], "mode": str(fr.mode)})
		pend_launch.clear()
		if trace0 >= 0 and host.ticks >= trace0 and host.ticks < trace0 + 110 and host.ticks % 4 == 0:
			var rv: Dictionary = _on_picture(fr, S.fighters[1], vw, vh)
			var ra2: Dictionary = _on_picture(fr, S.fighters[0], vw, vh)
			print("TR t ", host.ticks, " mode ", fr.mode, " sep ", snappedf(fr.sep, 0.01), " e ", snappedf(fr.e, 0.01), " chase ", rig.chase_slot, " split_wanted ", rig.split_wanted, " st ", S.fighters[0].state, "/", S.fighters[1].state, " gap ", snappedf(absf(SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)), 1.0), " v_on ", rv["on"], " a_on ", ra2["on"], " cam0 ", snappedf(fr.cam_x[0], 1.0), " z ", snappedf(fr.cam_z[0], 0.001), " cam1 ", snappedf(fr.cam_x[1], 1.0), " z ", snappedf(fr.cam_z[1], 0.001), " | mz ", snappedf(rig._mz, 0.001), " mt ", snappedf(rig._merged_target(S).z, 0.001), " zo ", snappedf(rig._zo[0], 0.001), "/", snappedf(rig._zo[1], 0.001), " tgt ", snappedf(rig._own_zoom_target(S, 0), 0.001), "/", snappedf(rig._own_zoom_target(S, 1), 0.001), " wide ", snappedf(rig._wide_t, 0.01), " vsm_m ", snappedf(rig._vsm_m, 1.0), " gov ", rig._gov_bind_m, " mzl ", rig.merge_zoom_limit)
		for o in open_:
			var f = S.fighters[int(o.v)]
			var r: Dictionary = _on_picture(fr, f, vw, vh)
			o.trail.append(not bool(r["on"]))
			var flight: bool = f.state == "launched"
			if flight and not shot_skip(rig):
				var att = S.fighters[1 - int(o.v)]
				var ra: Dictionary = _on_picture(fr, att, vw, vh)
				o["a_n"] = int(o.get("a_n", 0)) + 1
				if not bool(ra["on"]):
					o["a_off"] = int(o.get("a_off", 0)) + 1
			var shot_tf: bool = rig.solo_kind == "transform" or rig.solo_kind == "ko" or rig.solo_kind == "finisher"
			if shot_tf:
				o["tf"] = int(o.get("tf", 0)) + 1
			else:
				var key_off: String = "f_off" if flight else "r_off"
				var key_sm: String = "f_small" if flight else "r_small"
				var key_n: String = "f_n" if flight else "r_n"
				o[key_n] = int(o.get(key_n, 0)) + 1
				if not bool(r["on"]):
					o[key_off] = int(o.get(key_off, 0)) + 1
				elif float(r["px"]) < 32.0:
					o[key_sm] = int(o.get(key_sm, 0)) + 1
			if not bool(r["on"]):
				o.off = int(o.off) + 1
				o.run = int(o.run) + 1
				o.longest = maxi(int(o.longest), int(o.run))
			else:
				o.run = 0
			o["px"] = float(r["px"])
		var finished: Array = []
		for o in open_:
			var landed: bool = false
			for h in pend_hit:
				if int(h[1]) != int(o.v) and host.ticks - int(o.t0) > 20 and S.fighters[int(o.v)].state != "launched":
					landed = true   # the victim hit the other one
				elif int(h[0]) != int(o.v) and int(h[1]) == int(o.v) and host.ticks - int(o.t0) > 90 and S.fighters[int(o.v)].state != "launched":
					landed = true   # the other one hit him again after the flight
			var timeout: bool = float(host.ticks - int(o.t0)) * DT > span_s
			if landed or timeout:
				var tr: Array = o.trail
				var last1: int = 0
				for i in range(maxi(0, tr.size() - 60), tr.size()):
					if bool(tr[i]):
						last1 += 1
				var A = S.fighters[0]
				var B = S.fighters[1]
				done.append({"v": int(o.v), "t0": int(o.t0), "len": host.ticks - int(o.t0), "off": int(o.off), "longest": int(o.longest), "last1s": last1,
					"size": snappedf(float(o.get("px", 0.0)), 0.1), "gap_bh": snappedf(absf(SimWrap.sdx(A.x, B.x)) / CamParams.BODY_H, 0.1), "end": "hit" if landed else "span", "mode0": o.mode,
					"flight": int(o.get("f_n", 0)), "f_off": int(o.get("f_off", 0)), "f_small": int(o.get("f_small", 0)), "ret": int(o.get("r_n", 0)), "r_off": int(o.get("r_off", 0)), "r_small": int(o.get("r_small", 0)), "tf": int(o.get("tf", 0)), "a_n": int(o.get("a_n", 0)), "a_off": int(o.get("a_off", 0))})
				finished.append(o)
		for o in finished:
			open_.erase(o)
		pend_hit.clear()
	var sums: Dictionary = {"flight": 0, "f_off": 0, "f_small": 0, "ret": 0, "r_off": 0, "r_small": 0, "tf": 0, "a_n": 0, "a_off": 0}
	var bad_returns: int = 0
	var n: int = 0
	var off_all: int = 0
	var longest: int = 0
	var unseen: int = 0
	var seen_small: int = 0
	for d in done:
		if verbose:
			print("L ", JSON.stringify(d))
		n += 1
		for k in sums.keys():
			sums[k] = int(sums[k]) + int(d[k])
		if int(d.r_off) + int(d.r_small) > 12:
			bad_returns += 1
		off_all += int(d.off)
		longest = maxi(longest, int(d.longest))
		if int(d.last1s) > 6:
			unseen += 1
		if float(d.size) < 32.0:
			seen_small += 1
	print("RESULT seed=", seed_v, " hold=", hold, " bundle=", bundle, " reduced=", reduced, " launches=", n, " off_ticks=", off_all, " longest_off=", longest,
		" returns_unseen=", unseen, " blow_lands_on_victim_under_32px_or_off=", seen_small, " sums=", JSON.stringify(sums), " returns_dot_or_off_over_12=", bad_returns)
	quit(0)


func _drive(t: int, S: SimState) -> void:
	if FORM_TICKS.has(t):
		for f in S.fighters:
			f.act.formReady = true
	if t == 900:
		S.fighters[0].tier = 3.0
	if t == 1200:
		S.fighters[1].stage[1] = 2


func shot_skip(rig: SplitRig) -> bool:
	return rig.solo_kind == "transform" or rig.solo_kind == "ko" or rig.solo_kind == "finisher"
