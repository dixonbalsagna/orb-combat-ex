extends SceneTree
## A launch sent in a hit-stop still gets its peak shot (docs/camera/launch-director.md): the shot waits out the stop, then fires, once.
##   godot --headless --path . --script res://render/camera/tests/peak_retry_check.gd

func _initialize() -> void:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 12345, {"p1": false, "p2": false}, {"planet": 7, "touch": 1, "planetGen": 3, "intro": false})
	S.dt = SplitRig.DT
	for f in S.fighters:
		f.tier = 4.0
	var rig := SplitRig.new()
	rig.swing_view = true
	rig.peak_launch = true
	rig.launch_director = true
	rig.reset(S, 1280.0, 720.0)
	for t in range(5):
		rig.step(S, 1280.0, 720.0, [])
	var o = S.fighters[1]
	o.state = "launched"
	o.launchT = 1.0
	o.vx = 6000.0
	o.vy = 11000.0
	S.dirS.stop = 0.1
	var during: int = 0
	for t in range(6):
		rig.step(S, 1280.0, 720.0, [])
		during = rig.peak_shots
	S.dirS.stop = 0.0
	for t in range(3):
		rig.step(S, 1280.0, 720.0, [])
	var ok: bool = during == 0 and rig.peak_shots == 1
	if not ok:
		print("FAIL shots in the stop %d, after it %d" % [during, rig.peak_shots])
	print("peak_retry_check: %s" % ("1 check passed" if ok else "1 of 1 checks FAILED"))
	quit(0 if ok else 1)
