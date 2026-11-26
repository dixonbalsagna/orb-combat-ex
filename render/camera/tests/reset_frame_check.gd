extends SceneTree
## A following match's first frame is placed on its own sim frame, not the last match's (Rendering's find, 2026-11-26: the tile ground
## popped for one frame on Play again, at every planet size). SplitRig.reset, which main._mb_end calls at every match build, re-reads the
## sim's frame (_pl) as cut() does. One rig, as the game keeps one: a match played on until its frame has moved, then a new match.
##   godot --headless --path . --script res://render/camera/tests/reset_frame_check.gd
## Ends with `reset_frame_check: N checks passed` or a line per failure. Skips with a line if the build has no sim frame.

const VW: float = 1280.0
const VH: float = 720.0

var fails: int = 0
var checks: int = 0


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL ", what)


func _match(seed: int) -> SimState:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": true, "p2": true}, {"intro": false})
	S.dt = SplitRig.DT
	return S


func _tick(S: SimState, rig: SplitRig) -> void:
	SimCore.step(S)
	var ev: Array = S.out.fx.duplicate()
	S.out.fx.clear()
	S.out.feed.clear()
	rig.step(S, VW, VH, ev)


func _same(a: PackedFloat64Array, b: PackedFloat64Array) -> bool:
	if a.size() != b.size():
		return false
	for k in range(a.size()):
		if absf(a[k] - b[k]) > 1e-9:
			return false
	return true


func _initialize() -> void:
	var S1: SimState = _match(3)
	if CamPlaces.frame_of(S1).is_empty():
		print("reset_frame_check: skipped (no sim frame in this build)")
		quit(0)
		return
	var rig := SplitRig.new()
	rig.swing_view = true
	rig.reset(S1, VW, VH)
	_ok(_same(rig.current().place, CamPlaces.frame_of(S1)), "the first match's first frame is on its own frame")
	# play on until the frame has moved well away from where the next match starts
	var S2: SimState = _match(17)
	var f2: PackedFloat64Array = CamPlaces.frame_of(S2)
	var t: int = 0
	while t < 3600 and _same(CamPlaces.frame_of(S1), f2):
		_tick(S1, rig)
		t += 1
	for _k in range(600):
		_tick(S1, rig)
	var f1_end: PackedFloat64Array = CamPlaces.frame_of(S1)
	_ok(not _same(f1_end, f2), "staging: the last match's frame differs from the next match's (else the row proves nothing)")
	_ok(_same(rig._pl, f1_end), "staging: the rig holds the last match's frame before the reset")
	# Play again: the same rig, a new match
	rig.reset(S2, VW, VH)
	var fr: SplitFrame = rig.current()
	_ok(_same(fr.place, f2), "Play again: the new match's first frame is placed on its own frame (it was the last match's)")
	_ok(not _same(fr.place, f1_end), "Play again: the first frame does not use the last match's frame")
	_tick(S2, rig)
	_ok(_same(rig.current().place, CamPlaces.turned(CamPlaces.frame_of(S2), rig.swing_shown)), "Play again: the next tick follows the new frame")
	_ok(absf(rig.swing_shown) < 1e-6, "Play again: no swing carried over from the last match (%.4f)" % rig.swing_shown)
	# with the swing view off, the frame stays empty
	var rig_off := SplitRig.new()
	rig_off.swing_view = false
	rig_off.reset(S2, VW, VH)
	_ok(rig_off.current().place.is_empty(), "the swing view off: no frame")
	SimCore.dispose(S1)
	SimCore.dispose(S2)
	if fails == 0:
		print("reset_frame_check: %d checks passed" % checks)
	else:
		print("reset_frame_check: %d of %d checks FAILED" % [fails, checks])
	quit(1 if fails > 0 else 0)
