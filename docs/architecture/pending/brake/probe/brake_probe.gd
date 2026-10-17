extends SceneTree
# Scratch (Simulation): the air brake in live play, with {"brake": true}. (A) one scripted send, told tick by tick: the
# window, the start, the speed falling, the ki, the end and control back. (B) matches where slot 1 is a player holding the
# brake on every tick (stanceMask 8) and slot 0 is the AI: how many sends, brakes, ends by reason, ticks braked, and each
# match the same twice. Usage: godot --headless --path <export> --script res://zbrake/brake_probe.gd -- <matches> <ticks>


func _scripted() -> void:
	var M := SimCore.createSim()
	SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"brake": true})
	var A = M.fighters[0]
	var D = M.fighters[1]
	D.y = WorldTerrain.groundY(M, D.x) + 400.0
	DirLaunch.doLaunch(M, A, D, {"ux": 0.6, "uy": 0.8}, 2400.0, false)
	var v0: float = SimBrake.speed(D)
	var held := SimIntent.new()
	held.stanceMask = SimBrake.BIT
	var ki0: float = D.ki
	var line: Array = []
	for t in range(1, 60):
		SimCore.step(M, [null, held])
		var tags: Array = []
		for e in M.out.fx:
			if e.type == "air_brake":
				tags.append("%s %s %.0f" % [e.text, e.kind, e.amount])
			elif e.type == "journey_end":
				tags.append("journey_end " + str(e.kind))
		if t == 1:
			print("A: send of own speed %.0f (power %.2f): window %d ticks; rate %.0f a second a second; control back under %.0f" % [v0, minf(1.0, v0 / SimBrake.fullSpeed), D.brk.at, SimBrake.rate, v0 / SimBrake.controlDiv])
		if not tags.is_empty() or (D.brk.on and t % 3 == 0):
			line.append("t%d %s v %.0f ki %.1f %s" % [t, D.state, SimBrake.speed(D) if D.state == "launched" else SimDetMath.hypot(D.vx, D.vy), D.ki, str(tags)])
		M.out.fx.clear()
		M.out.feed.clear()
		if D.state != "launched" and not D.brk.on and t > D.brk.at:
			break
	for l in line:
		print("   " + l)
	print("A: ki paid %.2f" % (ki0 - D.ki))
	SimCore.dispose(M)


func _match(seed: int, ticks: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": true, "p2": false}, {"brake": true})
	var held := SimIntent.new()
	held.stanceMask = SimBrake.BIT
	var r := {"sends": 0, "starts": 0, "ends": {}, "braked": 0, "je": 0}
	for t in range(ticks):
		SimCore.step(S, [null, held])
		for e in S.out.fx:
			if e.type == "launch" and int(e.actor) == 1:
				r.sends += 1
			elif e.type == "air_brake" and int(e.actor) == 1:
				if e.text == "start":
					r.starts += 1
				else:
					r.ends[e.kind] = int(r.ends.get(e.kind, 0)) + 1
			elif e.type == "journey_end" and e.kind == "brake":
				r.je += 1
		if S.fighters[1].brk.on:
			r.braked += 1
		S.out.fx.clear()
		S.out.feed.clear()
		if S.game.ko != null and S.game.koT > 2.5:
			break
	r["hash"] = SimHash.stateHash(S).gameplay
	SimCore.dispose(S)
	return r


func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 4
	var ticks: int = int(a[1]) if a.size() > 1 else 7200
	_scripted()
	var same: int = 0
	for k in range(n):
		var x: Dictionary = _match(400 + k, ticks)
		var y: Dictionary = _match(400 + k, ticks)
		same += 1 if x.hash == y.hash else 0
		print("B seed %d: sends to the braker %d, brakes %d, ends %s, journey_end brake %d, ticks braked %d (%.1f a brake); twice: %s" % [400 + k, x.sends, x.starts, str(x.ends), x.je, x.braked, float(x.braked) / maxf(1.0, float(x.starts)), "same" if x.hash == y.hash else "DIFFERENT"])
	print("B: %d of %d the same twice" % [same, n])
	quit()
