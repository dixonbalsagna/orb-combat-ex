extends SceneTree
## One versus many, the camera's read (docs/camera/one-v-many.md): a match of 3 to 5 bodies through the real scene (render/main.tscn, the
## host's own step, the compositor attached), the AI on every body, headless. The one is slot 0, the Empress slot 1, the others her guards
## (Simulation's stage 1, Encounter's stages 2 and 3 on the tree). Per tick it reads the displayed picture and counts what the
## brief asked for: ticks the one, his partner (the sim's: DirZip.END + 2 on the one) or the Empress is off the picture, ticks a
## guard is, the travel a tick (the shared bound is 0.045 of the width), cuts, and the smallest size a principal is drawn at.
##   godot --headless --path . --script res://render/camera/tests/many_probe.gd -- --bodies=4 --seed=1 --ticks=3600 [--many] [--phone]
## --phone draws it at 812 x 375 (a phone in landscape). Prints one RESULT line.

const DT: float = 1.0 / 60.0

var main: Node
var bodies: int = 4
var seed_v: int = 1
var ticks: int = 3600
var many: bool = false
var phone: bool = false
var from_t: int = -1
var to_t: int = -1


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bodies="):
			bodies = int(a.substr(9))
		elif a.begins_with("--seed="):
			seed_v = int(a.substr(7))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a == "--many":
			many = true
		elif a == "--phone":
			phone = true
		elif a.begins_with("--from="):
			from_t = int(a.substr(7))
		elif a.begins_with("--to="):
			to_t = int(a.substr(5))
	var vpn := SubViewport.new()
	vpn.size = Vector2i(812, 375) if phone else Vector2i(1280, 720)
	vpn.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var sv := SplitView.new()
	main.split_view = sv
	main.add_child(sv)
	main._sync_split_options()
	sv.attach(main)
	if many:
		sv.set_many_framing(true)
	main.host.vfx.auto_quality = false
	main.host.vfx.destruction_enabled = true
	var slots: Array = ["PROTAGONIST"]
	var names: Array = ["ONE"]
	var ai: Dictionary = {}
	for k in range(bodies):
		ai["p" + str(k + 1)] = true
		if k > 0:
			slots.append("RIVAL")
			names.append("G" + str(k))
	main.start_match(seed_v, ai, {"slots": slots, "names": names})
	main.started = true
	var host: SimHost = main.host
	host.release_all()
	var rig: SplitRig = main.split_rig
	var pend: Array = []
	var cb := func(evs: Array, _lines: Array):
		for e in evs:
			if e.type == "cue" and str(e.kind) == "interject" and str(e.text) == "landed":
				pend.append(int(e.actor))
	host.drained.connect(cb)
	var vw: float = rig.vw
	var vh: float = rig.vh
	var prev: Vector3 = Vector3.ZERO
	var prev_ok: bool = false
	var n: int = 0
	var out_one: int = 0
	var out_part: int = 0
	var out_emp: int = 0
	var out_guard: int = 0
	var guard_ticks: int = 0
	var worst: float = 0.0
	var worst_at: int = 0
	var worst_mode: String = ""
	var prev_tr: float = 0.0
	var over: int = 0
	var cuts: int = 0
	var min_px: float = 1.0e9
	var split_ticks: int = 0
	var shot_ticks: int = 0
	var marks_max: int = 0
	var zmin: float = 1.0e9
	var zmax: float = 0.0
	var zstep: float = 0.0
	var prev_z: float = -1.0
	var inter_total: int = 0
	var inter_off: int = 0
	var under24: int = 0
	var guard: int = 0
	var ring_base: int = DirZip.END
	while host.ticks < ticks and guard < ticks * 4 and host.S.game.ko == null:
		var before: int = host.ticks
		main.frame(DT)
		guard += 1
		if host.ticks == before:
			continue
		var S: SimState = host.S
		var fr: SplitFrame = rig.current()
		var merged: bool = fr.sep < 0.5
		var pc: int = 0
		var cam: Vector3 = Vector3(fr.cam_x[pc], fr.cam_y[pc], fr.cam_z[pc])
		var tr: float = 0.0
		if prev_ok and fr.cut:
			cuts += 1
		elif prev_ok:
			var dx: float = SimWrap.sdx(prev.x, cam.x)
			var dy: float = cam.y - prev.y
			tr = sqrt(dx * dx + dy * dy) * cam.z / vw + 0.5 * absf(log(cam.z / maxf(prev.z, 0.0001)))
		prev = cam
		prev_ok = true
		if host.ticks < 60:
			continue
		var shot: bool = rig.solo_kind != "" or rig.solo_w > 0.01   # a launch shot or a cut-in shows one body by design
		n += 1
		if rig.solo_kind != "" or rig.solo_w > 0.01:
			shot_ticks += 1
		if tr > worst:
			worst = tr
			worst_at = host.ticks
			worst_mode = str(fr.mode) + " sep " + str(snappedf(fr.sep, 0.01)) + " mx " + str(snappedf(rig._mx, 1.0)) + " mz " + str(snappedf(rig._mz, 0.001)) + " part " + str(rig._many_partner) + " prev_ok " + str(snappedf(prev_tr, 0.0001))
		prev_tr = tr
		if host.ticks >= from_t and host.ticks <= to_t:
			var xs: String = ""
			for k in range(S.fighters.size()):
				xs += " " + str(snappedf(SimWrap.sdx(S.fighters[0].x, S.fighters[k].x), 1.0))
			print("P t ", host.ticks, " ", fr.mode, " sep ", snappedf(fr.sep, 0.01), " tr ", snappedf(tr, 0.0001), " cam ", snappedf(cam.x, 1.0), " ", snappedf(cam.z, 0.001), " mx ", snappedf(rig._mx, 1.0), " mz ", snappedf(rig._mz, 0.001), " part ", rig._many_partner, " in ", rig._many_w, " rel x", xs, " dbg ", rig._many_dbg, " marks ", fr.many_off, " solo ", rig.solo_kind)
		if tr > 0.045:
			over += 1
		if not split_pane_free(fr):
			split_ticks += 1
		zmin = minf(zmin, cam.z)
		zmax = maxf(zmax, cam.z)
		if prev_z > 0.0:
			zstep = maxf(zstep, absf(log(cam.z / prev_z)))
		prev_z = cam.z
		marks_max = maxi(marks_max, fr.many_off.size())
		var one = S.fighters[0]
		var pslot: int = 1
		var dir: Array = one.act.dirI
		if dir.size() > ring_base + 2 and int(dir[ring_base + 2]) > 0:
			pslot = int(dir[ring_base + 2]) - 1
		var small_now: bool = false
		for k in range(S.fighters.size()):
			var f = S.fighters[k]
			var pane: int = 0
			var on: bool = false
			for pi in range(2):
				if not fr.shows(pi):
					continue
				var sp: Vector2 = fr.screen_pos(pi, f.x, f.y + CamParams.CHEST, float(f.z))
				var inside: bool = sp.x >= 0.0 and sp.x <= vw and sp.y >= 0.0 and sp.y <= vh
				if inside and fr.feather <= 0.001 and fr.sep >= 0.5:
					var side: float = (sp - fr.c).dot(fr.n)
					inside = side <= 0.0 if pi == 0 else side > 0.0
				if inside:
					on = true
					pane = pi
					break
			if on and not shot:
				var hpx: float = fr.apparent_height(pane, f.x, f.y, float(f.z))
				if hpx < 24.0:
					small_now = true
			if pend.has(k):
				inter_total += 1
				if not on:
					inter_off += 1
			if k == 0 or k == 1 or k == pslot:
				var px: float = fr.apparent_height(pane, f.x, f.y, float(f.z))
				min_px = minf(min_px, px)
			if shot:
				continue
			if k == 0 and not on:
				out_one += 1
			if k == pslot and not on:
				out_part += 1
			if k == 1 and k != pslot and not on:
				out_emp += 1
			if k >= 2 and k != pslot:
				guard_ticks += 1
				if not on:
					out_guard += 1
		if small_now:
			under24 += 1
		pend.clear()
	var emp_note: String = "tags %d" % (int(host.S.fighters[0].act.dirI[ring_base + 8]) if host.S.fighters[0].act.dirI.size() > ring_base + 8 else 0)
	print("RESULT bodies=", bodies, " many=", many, " phone=", phone, " seed=", seed_v, " ticks=", n, " split_ticks=", split_ticks, " shot_ticks=", shot_ticks,
		" one_out=", out_one, " partner_out=", out_part, " empress_out=", out_emp, " guard_out_share=", snappedf(float(out_guard) / maxf(1.0, float(guard_ticks)), 0.001),
		" worst_travel=", snappedf(worst, 0.0001), " over_0.045=", over, " cuts=", cuts, " min_principal_px=", snappedf(min_px, 0.1),
		" zoom=", snappedf(zmin, 0.001), "..", snappedf(zmax, 0.001), " max_zoom_step=", snappedf(zstep, 0.0001), " marks_max=", marks_max, " under24=", under24, " inter=", inter_off, "/", inter_total, " ", emp_note,
		" ko=", host.S.game.ko != null, " worst_at=", worst_at, " [", worst_mode, "]")
	quit(0)


func split_pane_free(fr: SplitFrame) -> bool:
	return fr.sep < 0.5
