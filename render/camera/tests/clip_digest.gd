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
var trace_from: int = -1
var trace_to: int = -1
var _prev_cam: Array = []


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
	var guard: int = 0
	while host.ticks < total and guard < total * 4:
		_drive(sc, host.ticks, host.S)
		var before: int = host.ticks
		main.frame(DT)
		guard += 1
		if host.ticks != before:
			var fr: SplitFrame = main.split_rig.current()
			var h: int = hash([snappedf(fr.cam_x[0], 0.01), snappedf(fr.cam_y[0], 0.01), snappedf(fr.cam_z[0], 0.00001), snappedf(fr.cam_x[1], 0.01), snappedf(fr.cam_y[1], 0.01), snappedf(fr.cam_z[1], 0.00001), snappedf(fr.sep, 0.0001), snappedf(fr.e, 0.0001), fr.mode, fr.cut, fr.active, fr.panel.get("kind", ""), snappedf(float(fr.panel.get("open", 0.0)), 0.001)])
			out.store_line("%s\t%s\t%d\t%d" % [label, mode, host.ticks, h])
			if host.ticks >= trace_from and host.ticks <= trace_to:
				var rg: SplitRig = main.split_rig
				var tr: float = 0.0
				if not _prev_cam.is_empty():
					tr = sqrt(pow(SimWrap.sdx(float(_prev_cam[0]), fr.cam_x[0]), 2.0) + pow(fr.cam_y[0] - float(_prev_cam[1]), 2.0)) * fr.cam_z[0] / rg.vw + 0.5 * absf(log(fr.cam_z[0] / float(_prev_cam[2])))
				_prev_cam = [fr.cam_x[0], fr.cam_y[0], fr.cam_z[0]]
				print("TR %s %s t %d mode %s sep %.2f e %.2f solo %s/%d cut %s fade %.2f pn %s/%.2f cam %.0f,%.0f z %.3f travel %.4f st %s/%s" % [label, mode, host.ticks, fr.mode, fr.sep, fr.e, rg.solo_kind, rg.solo_slot, fr.cut, fr.fade, fr.panel.get("kind", "-"), float(fr.panel.get("open", 0.0)), fr.cam_x[0], fr.cam_y[0], fr.cam_z[0], tr, host.S.fighters[0].state, host.S.fighters[1].state])
	_release_all()
