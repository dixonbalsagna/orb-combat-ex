extends SceneTree
## The stick's full send (stick.json fullSend, off; docs/director/pending/stick-slam/; Game Design, slam-and-pace.md section 1):
##   godot --headless --path . --script res://sim/director/tools/full_send_check.gd
## - on: a down strike held to his top stage that lands on a foe in the air sends him down: the slam (cue stick_full_send slamDown), the
##   brawl ends, he's launched and falls
## - on: down at the top on a foe on the ground: the down send from where he stands (cue bury)
## - on: up at the top sends him up (skyward); toward at the top sends him across
## - on: a hold short of the top, and a quick flick, never send; a quick down flick on a foe in the air gives UI's hint cue (slam_hint)
## - off: as before, no send
## The top stage is read at the release (level 3 with the plain hold's stages off). A real brawl is played to (seed 1, the computer on both
## sides), then the blow is landed by hand. Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	DirStick.setForce(1)
	DirBeamMove.setStrikeForce(0)
	var sc: Dictionary = DirStick.cfg()
	var on0: bool = bool(sc.fullSend.enabled)
	sc.fullSend.enabled = true
	var slam: Dictionary = _case(DirStick.DOWN, 8.0, 3, true)
	var ground: Dictionary = _case(DirStick.DOWN, 0.0, 3, true)
	var up: Dictionary = _case(DirStick.UP, 0.0, 3, true)
	var across: Dictionary = _case(DirStick.TOWARD, 0.0, 3, true)
	var short: Dictionary = _case(DirStick.DOWN, 8.0, 2, false)
	var quick: Dictionary = _case(DirStick.DOWN, 8.0, 0, false)
	sc.fullSend.enabled = false
	var off: Dictionary = _case(DirStick.DOWN, 8.0, 3, true)
	sc.fullSend.enabled = on0
	var top3: bool = DirStick._atTop(null, 3) and not DirStick._atTop(null, 2)
	DirBeamMove.setStrikeForce(-1)
	DirStick.setForce(-1)
	for r in [slam, ground, up, across, short, quick, off]:
		print("      %s: cue %s, brawl ended %s, launched %s, rose %.0f, moved %.0f" % [r.name, str(r.cue), str(r.ended), str(r.launched), r.rose, r.moved])
	_expect(slam.found and slam.cue == "stick_full_send/slamDown" and slam.ended and slam.launched and slam.rose < -50.0, "on: down at the top on a foe in the air is the slam: he's sent down (%.0f)" % slam.rose)
	_expect(ground.found and ground.cue == "stick_full_send/bury" and ground.ended, "on: down at the top on a foe on the ground: the down send from where he stands (bury)")
	_expect(up.found and up.cue == "stick_full_send/skyward" and up.ended and up.rose > 50.0, "on: up at the top sends him up (%.0f)" % up.rose)
	_expect(across.found and across.cue == "stick_full_send/across" and across.ended and across.moved > 100.0, "on: toward at the top sends him across (%.0f)" % across.moved)
	_expect(short.found and short.cue == "" and not short.ended, "on: a hold short of the top never sends")
	_expect(quick.found and quick.cue == "slam_hint/" and not quick.ended, "on: a quick down flick on a foe in the air doesn't send, and gives UI's hint cue")
	_expect(off.found and off.cue == "" and not off.ended, "off: as before, no send")
	_expect(top3, "the top, with the plain hold's stages off, is level 3")
	print("FULL SEND: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _case(dir: int, bh: float, lvl: int, top: bool) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": true, "p2": true}, {})
	var ex = null
	var found := false
	while S.tick < 20000 and not found:
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		ex = S.dirS.ex
		found = ex != null and DirBrawl.isBrawl(ex) and ex.branch == "" and ex.A.state == "locked" and ex.D.state == "locked" and ex.A.stunTicks == 0 and ex.D.stunTicks == 0
	var out := {"name": "%s at %s bh, level %d%s" % [DirStick.NAMES[dir], str(bh), lvl, ", top" if top else ""], "found": found, "cue": "", "ended": false, "launched": false, "rose": 0.0, "moved": 0.0}
	if not found:
		SimCore.dispose(S)
		return out
	var f = ex.A
	var o = ex.D
	o.y = WorldTerrain.groundY(S, o.x, o.z) + bh * DirInterrupt.BH
	f.y = o.y
	f.ki = 100.0
	var y0: float = o.y
	var x0: float = o.x
	DirStick.landed(S, ex, f, o, {"stick": dir, "stickL": lvl, "top": top})
	for e in S.out.fx:
		if String(e.type) == "cue" and (String(e.kind) == "stick_full_send" or String(e.kind) == "slam_hint"):
			out.cue = String(e.kind) + "/" + String(e.source)
	out.ended = S.dirS.ex != ex
	out.launched = o.state == "launched"
	for _k in range(20):
		SimCore.step(S)
	out.rose = o.y - y0
	out.moved = absf(SimWrap.sdx(x0, o.x))
	SimCore.dispose(S)
	return out
