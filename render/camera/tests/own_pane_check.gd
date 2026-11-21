extends "res://tools/flash/flash_worst.gd"
## The player always sees himself, in the real scene: plays tools/flash's scenes through the main scene (as clip_digest does) in both
## modes, Reduce flashing on (the default view) and off, and fails when a fighter is out of the pane that's his for more than
## launch_shots_check's limit (15 ticks). Fully open, his pane is his slot, as launch_shots_check reads it; from the split's first tick and in the
## one view before it, he must be in some drawn picture (launch_shots_check counts nothing until the split is fully open). Its rows are
## staged sends; these are the scenes' real launches. Exempt, as there: a slam, the peak launch, and a fighter who isn't a running solo shot's subject.
##   godot --headless --path . --script res://render/camera/tests/own_pane_check.gd -- [--clips=clash,signature,launchai] [--modes=normal,reduced] [--measure]
## Ends with `own_pane_check: N checks passed` or a line per failure.

const OFF_LIMIT: int = 15
## Losses the camera already has on the GW1a camera (a-camera-01 + cd04), both modes, pinned as ceilings that may only come down (a fix is
## owed for each, docs/camera/pending/own-pane/README.md): the beam lock's one view on player one with player two off screen (clash), and
## player two at the divider's edge after a beam or blow sends him (signature, launchai). Anything else holds the 15-tick limit.
## With GW1a's whole data (the 9 November target), the signature scene adds two: the one view loses player one for 26 ticks after his beam
## sends player two (ticks 125 to 150), and player two for 48 after a send (860 to 907). The clash and launchai losses read 0 there.
const KNOWN: Dictionary = {"clash/1": 52, "signature/0": 26, "signature/1": 48, "launchai/1": 35}
var clips: Array = ["clash", "signature", "launchai"]
var modes: Array = ["normal", "reduced"]
var measure: bool = false
var fails: int = 0
var checks: int = 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--clips="):
			clips = Array(a.substr(8).split(","))
		elif a.begins_with("--modes="):
			modes = Array(a.substr(8).split(","))
		elif a == "--measure":
			measure = true
	super._initialize()


func _run() -> void:
	await process_frame
	var sv := SplitView.new()
	main.split_view = sv
	main.add_child(sv)
	main._sync_split_options()
	sv.attach(main)
	main.host.vfx.auto_quality = false
	main.host.vfx.destruction_enabled = true
	var ticks_of: Dictionary = {}
	for sd in defs["scenarios"]:
		ticks_of[str(sd["id"])] = int(sd["ticks"])
	for c in clips:
		var parts: PackedStringArray = String(c).split(":")
		var sc: String = parts[0]
		var seed: int = int(parts[1]) if parts.size() > 1 else 12345
		for m in modes:
			_one(String(c), sc, seed, String(m) == "reduced", int(ticks_of.get(sc, 1500)))
	if measure:
		print("own_pane_check: measured")
	elif fails == 0:
		print("own_pane_check: %d checks passed" % checks)
	else:
		print("own_pane_check: %d of %d checks FAILED" % [fails, checks])
	quit(1 if fails > 0 and not measure else 0)


## Whether fighter i is out of the pane that's his this frame. Once the split is fully open, his pane is his own slot and he must be on its
## side of the divider (launch_shots_check's rule). Before that, in the one view and through the split's opening, he must be in some
## drawn picture: the gap the old rule left, where a fighter could go unseen while the split opened.
static func off_his_pane(fr: SplitFrame, rig: SplitRig, f, i: int) -> bool:
	if rig._slam_slot >= 0 or rig._pk_phase != "" or not (rig.solo_kind == "" or rig.solo_slot == i):
		return false
	if fr.sep >= 0.999 and fr.shows(i):
		return not _in_pane(fr, rig, f, i, 1.0)
	for p in range(2):
		if (p == 0 or fr.shows(p)) and _in_pane(fr, rig, f, p, 0.5):
			return false
	return true


## Whether the fighter's chest is in pane p's picture, where that pane is drawn at least `share` of the pixel.
static func _in_pane(fr: SplitFrame, rig: SplitRig, f, p: int, share: float) -> bool:
	var sp: Vector2 = fr.screen_pos(p, f.x, f.y + CamParams.CHEST, float(f.z))
	if sp.x < 0.0 or sp.x > rig.vw or sp.y < 0.0 or sp.y > rig.vh:
		return false
	if not fr.shows(1):
		return p == 0
	var w1: float = fr.weight1(sp)
	return (w1 if p == 1 else 1.0 - w1) >= share


func _one(label: String, sc: String, seed: int, reduced: bool, total: int) -> void:
	var ai: Array = AI_SLOTS[sc]
	main.start_match(seed, {"p1": ai[0], "p2": ai[1]}, null)
	var host: SimHost = main.host
	host.vfx.force_reduced = reduced
	main.ui_hud.opts["reduce_flashing"] = reduced
	_release_all()
	_claim_pads(ai)
	var run: Array = [0, 0]
	var worst: Array = [0, 0]
	var worst_at: Array = ["", ""]
	var guard: int = 0
	while host.ticks < total and guard < total * 4:
		_drive(sc, host.ticks, host.S)
		var before: int = host.ticks
		main.frame(DT)
		guard += 1
		if host.ticks == before:
			continue
		var fr: SplitFrame = main.split_rig.current()
		for i in range(2):
			if off_his_pane(fr, main.split_rig, host.S.fighters[i], i):
				run[i] += 1
				if run[i] > int(worst[i]):
					worst[i] = run[i]
					worst_at[i] = "ticks %d to %d, %s, sep %.2f, %s" % [host.ticks - run[i] + 1, host.ticks, fr.mode, fr.sep, str(host.S.fighters[i].state)]
			else:
				run[i] = 0
	_release_all()
	var mode: String = "reduced" if reduced else "normal"
	for i in range(2):
		var cap: int = int(KNOWN.get("%s/%d" % [label, i], OFF_LIMIT))
		print("  %s %s, fighter %d: out of his pane at most %d ticks (limit %d%s) %s" % [label, mode, i, worst[i], cap, ", a known loss" if cap > OFF_LIMIT else "", worst_at[i]])
		checks += 1
		if int(worst[i]) > cap and not measure:
			fails += 1
			print("FAIL own_pane_check: %s %s, fighter %d out of his pane for %d ticks (%s)" % [label, mode, i, worst[i], worst_at[i]])
