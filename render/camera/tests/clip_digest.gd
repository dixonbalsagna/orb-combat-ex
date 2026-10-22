extends "res://tools/flash/flash_worst.gd"
## Camera's digest of a flash clip: plays tools/flash's scenes through the real scene exactly as flash_worst.gd does (it extends that
## script for the scenes' own drive code) and writes, for each tick, a hash of the camera's frame (both panes' camera, the divider,
## the mode, the panel). Two runs with one switch changed (the merge lookahead, a panel rule) are compared with
## render/camera/tests/clip_digest_diff.py: a clip whose digests are equal is the same picture tick for tick, so a frame
## comparison of it would show no change; a clip that differs says from which tick.
##   godot --headless --path . --script res://render/camera/tests/clip_digest.gd -- --clips=ai:1,ai:4,collapse,mashcity --mlook=0 --out=PATH [--modes=normal,reduced] [--panel-flash-off=signature+clash]
## --clips: scenario[:seed[:SLOT,SLOT]] entries joined by commas, with the pairing joined by + (ai:8:PROTAGONIST+REFERENCE).
## The lines are `clip<TAB>mode<TAB>tick<TAB>hash`. Nothing here writes into the sim; the camera reads it.

var clips: Array = ["ai:1", "ai:4", "ai:5", "ai:38", "ai:106", "collapse", "mashcity", "signaturecity", "rushcity"]
var mlook: int = -1
var modes: Array = ["normal", "reduced"]
var digest_path: String = "digest.txt"
var panel_flash_off: String = "-"   # "-" the rig's default; "" none; or kind names joined by +
var ticks_cap: int = 0
var ev_types: Array = []   # --events=a,b: print each event of these types with its tick
var trace_from: int = -1
var trace_to: int = -1
var _prev_cam: Array = []
var budget_on: bool = false
var tmax: float = -1.0
var _off_ticks: int = 0
var _cut_ticks: int = 0
var _mode_changes: int = 0
var _nc_spans: Array = []   # the cam_intent plans' do-not-cut spans [from, to] (Encounter's feed, when it is on)
var _nc_plans: int = 0
var _nc_changes: int = 0
var _nc_cuts: int = 0
var _fade_ticks: int = 0
var _panels: int = 0
var _prev_mode: String = ""
var _prev_panel: String = ""
# smoothness in the one view: zoom reversals over 2% (a pump), the picture's largest change of velocity in a tick, and the room ahead of a pair moving together
var _zl: Array = []
var _jerk: float = 0.0
var _vprev: float = 0.0
var _xprev: float = 0.0
var _room_n: int = 0
var _room_sum: float = 0.0
var _small: Dictionary = {}
var _l_ticks: int = 0
var _l_in: int = 0
var _heights_l: Array = []   # the launched body's drawn height, px at 720p
var _heights: Array = []   # each fighter's drawn height in the pane that shows him, px, every tick


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--clips="):
			clips = Array(a.substr(8).split(","))
		elif a.begins_with("--mlook="):
			mlook = int(a.substr(8))
		elif a.begins_with("--modes="):
			modes = Array(a.substr(8).split(","))
		elif a.begins_with("--out="):
			digest_path = a.substr(6)
		elif a.begins_with("--panel-flash-off="):
			panel_flash_off = a.substr(18)
		elif a == "--budget":
			budget_on = true
		elif a.begins_with("--tmax="):
			tmax = float(a.substr(7))
		elif a.begins_with("--events="):
			ev_types = Array(a.substr(9).split(","))
		elif a.begins_with("--trace="):
			var tp: PackedStringArray = a.substr(8).split("-")
			trace_from = int(tp[0])
			trace_to = int(tp[1])
		elif a.begins_with("--ticks="):
			ticks_cap = int(a.substr(8))
	super._initialize()


func _run() -> void:
	await process_frame
	var sv := SplitView.new()
	main.split_view = sv
	main.add_child(sv)
	main._sync_split_options()
	sv.attach(main)
	if budget_on:
		sv.set_travel_budget(true)
	if tmax > 0.0:
		main.split_rig.set("travel_max", tmax)
	if mlook >= 0:
		sv.set_merge_lookahead(mlook == 1)
	if panel_flash_off != "-":
		sv.set_panel_flash_off([] if panel_flash_off == "" else Array(panel_flash_off.split("+")))
	main.host.vfx.auto_quality = false
	main.host.vfx.destruction_enabled = true
	var out := FileAccess.open(digest_path, FileAccess.WRITE)
	var ticks_of: Dictionary = {}
	for sd in defs["scenarios"]:
		ticks_of[str(sd["id"])] = int(sd["ticks"])
	for c in clips:
		var parts: PackedStringArray = String(c).split(":")
		var sc: String = parts[0]
		var seed: int = int(parts[1]) if parts.size() > 1 else 12345
		var slots: Array = Array(parts[2].split("+")) if parts.size() > 2 else []
		for m in modes:
			var reduced: bool = m == "reduced"
			var total: int = ticks_cap if ticks_cap > 0 else int(ticks_of.get(sc, 3600))
			_digest_play(out, String(c), String(m), sc, seed, reduced, total, slots)
	out.close()
	quit(0)


func _digest_play(out: FileAccess, label: String, mode: String, sc: String, seed: int, reduced: bool, total: int, slots: Array) -> void:
	var ai: Array = AI_SLOTS[sc]
	var ai_set: Dictionary = {"p1": ai[0], "p2": ai[1]}
	for i in range(2, slots.size()):
		ai_set["p%d" % (i + 1)] = sc == "ring"
	main.start_match(seed, ai_set, null if slots.is_empty() else {"slots": slots})
	var host: SimHost = main.host
	host.vfx.force_reduced = reduced
	main.ui_hud.opts["reduce_flashing"] = reduced
	_release_all()
	_claim_pads(ai)
	var cb := func(evs: Array, _lines: Array):
		for e in evs:
			if ev_types.has(String(e.type)):
				print("EV %s t %d %s %s actor %s kind %s amount %s n %s" % [label, host.ticks, e.type, str(e.get("text")), str(e.get("actor")), str(e.get("kind")), str(e.get("amount")), str(e.get("n"))])
	if not ev_types.is_empty():
		host.drained.connect(cb)
	var cb_nc := func(evs: Array, _lines: Array):
		for e in evs:
			if String(e.type) == "cue" and String(e.get("kind")) == "cam_intent" and String(e.get("text")) == "plan" and e.has_meta("plan"):
				_nc_plans += 1
				for sp in e.get_meta("plan").get("noCut", []):
					_nc_spans.append([int(sp[0]), int(sp[1])])
	host.drained.connect(cb_nc)
	var guard: int = 0
	while host.ticks < total and guard < total * 4:
		_drive(sc, host.ticks, host.S)
		var before: int = host.ticks
		main.frame(DT)
		guard += 1
		if host.ticks != before:
			var fr: SplitFrame = main.split_rig.current()
			var h: int = hash([snappedf(fr.cam_x[0], 0.01), snappedf(fr.cam_y[0], 0.01), snappedf(fr.cam_z[0], 0.00001), snappedf(fr.cam_x[1], 0.01), snappedf(fr.cam_y[1], 0.01), snappedf(fr.cam_z[1], 0.00001), snappedf(fr.sep, 0.0001), snappedf(fr.e, 0.0001), fr.mode, fr.cut, fr.active, fr.panel.get("kind", ""), snappedf(float(fr.panel.get("open", 0.0)), 0.001)])
			# the stats a budget run is judged by: ticks a fighter is outside the picture that shows him, and cut frames
			if fr.cut:
				_cut_ticks += 1
			if _prev_mode != "" and fr.mode != _prev_mode:
				_mode_changes += 1
				if _in_nocut(host.S.tick):
					_nc_changes += 1
			if fr.cut and _in_nocut(host.S.tick):
				_nc_cuts += 1
			_prev_mode = fr.mode
			if fr.fade > 0.0:
				_fade_ticks += 1
			var pk: String = str(fr.panel.get("kind", ""))
			if pk != "" and _prev_panel == "":
				_panels += 1
			_prev_panel = pk
			for fi in range(2):
				var pi: int = fi if fr.shows(fi) else 0
				var fs = host.S.fighters[fi]
				var sp: Vector2 = fr.screen_pos(pi, fs.x, fs.y + CamParams.CHEST, float(fs.z))
				var hh: float = fr.apparent_height(pi, fs.x, fs.y, float(fs.z)) * 720.0 / maxf(main.split_rig.vh, 1.0)
				_heights.append(hh)
				if fs.state == "launched":
					_heights_l.append(hh)
					_l_ticks += 1
					if sp.x >= 0.0 and sp.x <= main.split_rig.vw and sp.y >= 0.0 and sp.y <= main.split_rig.vh:
						_l_in += 1
				if hh < 40.0:
					var why: String = ("deep " if absf(float(fs.z)) > 60.0 else "") + fr.mode + ("/" + main.split_rig.solo_kind if main.split_rig.solo_kind != "" else "") + ("/launched" if fs.state == "launched" else "") + " z%.2f" % snappedf(fr.cam_z[pi] * 75.0 / main.split_rig.vh / 0.01, 1.0) if false else ("deep " if absf(float(fs.z)) > 60.0 else "plane ") + fr.mode + ("/" + main.split_rig.solo_kind if main.split_rig.solo_kind != "" else "") + ("/launched" if fs.state == "launched" else "")
					_small[why] = int(_small.get(why, 0)) + 1
				if sp.x < 0.0 or sp.x > main.split_rig.vw or sp.y < 0.0 or sp.y > main.split_rig.vh:
					_off_ticks += 1
			if fr.mode == "merged" and not fr.cut:
				_zl.append(log(fr.cam_z[0]))
				var vx: float = SimWrap.sdx(_xprev, fr.cam_x[0]) * fr.cam_z[0] / main.split_rig.vw if _xprev != 0.0 else 0.0
				if absf(vx) < 0.2:
					_jerk = maxf(_jerk, absf(vx - _vprev))
				_vprev = vx
				_xprev = fr.cam_x[0]
				var fa = host.S.fighters[0]
				var fb = host.S.fighters[1]
				var vm: float = (fa.vx + fb.vx) * 0.5
				if absf(vm) > 600.0 and signf(fa.vx) == signf(fb.vx):
					var pa: Vector2 = fr.screen_pos(0, fa.x, fa.y + CamParams.CHEST, float(fa.z))
					var pb: Vector2 = fr.screen_pos(0, fb.x, fb.y + CamParams.CHEST, float(fb.z))
					var lead_px: float = maxf(pa.x, pb.x) if vm > 0.0 else minf(pa.x, pb.x)
					var room: float = (main.split_rig.vw - lead_px) if vm > 0.0 else lead_px
					_room_sum += room / main.split_rig.vw
					_room_n += 1
			else:
				_xprev = 0.0
				_vprev = 0.0
			out.store_line("%s\t%s\t%d\t%d" % [label, mode, host.ticks, h])
			if host.ticks >= trace_from and host.ticks <= trace_to:
				var rg: SplitRig = main.split_rig
				var tr: float = 0.0
				if not _prev_cam.is_empty():
					tr = sqrt(pow(SimWrap.sdx(float(_prev_cam[0]), fr.cam_x[0]), 2.0) + pow(fr.cam_y[0] - float(_prev_cam[1]), 2.0)) * fr.cam_z[0] / rg.vw + 0.5 * absf(log(fr.cam_z[0] / float(_prev_cam[2])))
				var tr1: float = 0.0
				if _prev_cam.size() > 3:
					tr1 = sqrt(pow(SimWrap.sdx(float(_prev_cam[3]), fr.cam_x[1]), 2.0) + pow(fr.cam_y[1] - float(_prev_cam[4]), 2.0)) * fr.cam_z[1] / rg.vw + 0.5 * absf(log(fr.cam_z[1] / float(_prev_cam[5])))
				_prev_cam = [fr.cam_x[0], fr.cam_y[0], fr.cam_z[0], fr.cam_x[1], fr.cam_y[1], fr.cam_z[1]]
				print("TR %s %s t %d mode %s sep %.2f e %.2f solo %s/%d cut %s fade %.2f pn %s/%.2f cam %.0f,%.0f z %.3f travel %.4f/%.4f act %s st %s/%s clash %s" % [label, mode, host.ticks, fr.mode, fr.sep, fr.e, rg.solo_kind, rg.solo_slot, fr.cut, fr.fade, fr.panel.get("kind", "-"), float(fr.panel.get("open", 0.0)), fr.cam_x[0], fr.cam_y[0], fr.cam_z[0], tr, tr1, str(fr.active), host.S.fighters[0].state, host.S.fighters[1].state, str(host.S.game.clash != null)])
	_heights.sort()
	var hn: int = _heights.size()
	if hn > 0:
		print("SIZE %s %s drawn height at 720p: p10 %.0f px, median %.0f px, share under 40 px %.1f%%" % [label, mode, float(_heights[int(hn * 0.1)]), float(_heights[hn / 2]), 100.0 * float(_heights.filter(func(h): return h < 40.0).size()) / float(hn)])
	print("SMALL %s %s %s" % [label, mode, str(_small)])
	_small = {}
	_heights_l.sort()
	if _heights_l.size() > 0:
		print("LAUNCHED %s %s the launched body: p10 %.0f px, median %.0f px over %d ticks, in frame %.1f%%" % [label, mode, float(_heights_l[int(_heights_l.size() * 0.1)]), float(_heights_l[_heights_l.size() / 2]), _heights_l.size(), 100.0 * float(_l_in) / maxf(float(_l_ticks), 1.0)])
	_l_ticks = 0
	_l_in = 0
	_heights_l = []
	_heights = []
	print("SMOOTH %s %s zoom pumps %d, largest velocity change %.4f of the width a tick, room ahead of a pair moving together %.3f of the width over %d ticks" % [label, mode, _count_pumps(_zl), _jerk, (_room_sum / maxf(float(_room_n), 1.0)), _room_n])
	_zl = []
	_jerk = 0.0
	_room_n = 0
	_room_sum = 0.0
	print("DIRECTOR %s %s anticipations %s, brink ticks %s" % [label, mode, str(main.split_rig.get("ant_starts")), str(main.split_rig.get("brink_ticks"))])
	print("STATS %s %s cuts %d fighter-ticks outside the picture %d of %d layout changes %d dip ticks %d strips %d blow pushes %s" % [label, mode, _cut_ticks, _off_ticks, total * 2, _mode_changes, _fade_ticks, _panels, str(main.split_rig.get("blows"))])
	var nct: Dictionary = {}
	for sp in _nc_spans:
		for t in range(int(sp[0]), int(sp[1]) + 1):
			nct[t] = true
	print("INTENTFEED %s %s plans %d, do-not-cut spans %d over %d ticks, layout changes inside %d, cut ticks inside %d, holds %s" % [label, mode, _nc_plans, _nc_spans.size(), nct.size(), _nc_changes, _nc_cuts, str(main.split_rig.get("nocut_holds"))])
	host.drained.disconnect(cb_nc)
	_nc_spans = []
	_nc_plans = 0
	_nc_changes = 0
	_nc_cuts = 0
	_off_ticks = 0
	_cut_ticks = 0
	_mode_changes = 0
	_fade_ticks = 0
	_panels = 0
	_prev_mode = ""
	_prev_panel = ""
	if not ev_types.is_empty():
		host.drained.disconnect(cb)
	_release_all()


## Zoom pumps: turning points of ln z 0.02 or more from the last turning point.
static func _count_pumps(zl: Array) -> int:
	if zl.size() < 3:
		return 0
	var n: int = 0
	var ext: float = float(zl[0])
	var dir: int = 0
	for k in range(1, zl.size()):
		var z: float = float(zl[k])
		if dir >= 0 and z > ext:
			ext = z
			dir = 1
		elif dir <= 0 and z < ext:
			ext = z
			dir = -1
		elif dir == 1 and ext - z >= 0.02:
			n += 1
			dir = -1
			ext = z
		elif dir == -1 and z - ext >= 0.02:
			n += 1
			dir = 1
			ext = z
	return n


func _in_nocut(t: int) -> bool:
	for sp in _nc_spans:
		if t >= int(sp[0]) and t <= int(sp[1]):
			return true
	return false
