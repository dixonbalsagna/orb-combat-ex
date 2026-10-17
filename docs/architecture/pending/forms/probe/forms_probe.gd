extends SceneTree
# Scratch (Simulation): forms on, in live matches. (A) AI against AI with {"forms": true}, each match twice: the same
# hashes both times, and what the Protagonist's steps did (the AI takes a ready step at once: its holds are Encounter's).
# (B) the slingshot by hand: slot 0 holds (no input) while the rival's AI fights him, until his power reaches 100 or the
# clock 5,400 ticks, then holds Transform once: every banked step taken in one release, with its coil.
# Usage: godot --headless --path <export with forms.py applied> --script res://zforms/forms_probe.gd -- <matches> <ticks>


func _one(seed: int, ticks: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"forms": true})
	var steps: Array = []
	var rel: Array = []
	var holds: int = 0
	for t in range(ticks):
		SimCore.step(S)
		for e in S.out.fx:
			if e.type == "form_step" and int(e.actor) == 0:
				steps.append([int(e.k), int(e.tier), S.tick])
			elif e.type == "form_release":
				rel.append([int(e.actor), int(e.n), snappedf(float(e.amount), 0.01)])
			elif e.type == "form_hold":
				holds += 1
		S.out.fx.clear()
		S.out.feed.clear()
		if S.game.ko != null and S.game.koT > 2.5:
			break
	var out := {"hash": SimHash.stateHash(S).gameplay, "steps": steps, "rel": rel, "holds": holds, "end": S.tick, "p": S.fighters[0].form.step, "tier": S.fighters[0].tier, "rtier": S.fighters[1].tier}
	SimCore.dispose(S)
	return out


func _sling(seed: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": true}, {"forms": true})
	var p = S.fighters[0]
	var o = S.fighters[1]
	var info := {}
	var asking: bool = false
	for t in range(20000):
		var i := SimIntent.new()
		var d: float = SimWrap.sdx(p.x, o.x)
		i.mx = 1.0 if d > 0.0 else -1.0   # he closes and trades blows: a light every 12 ticks
		i.light = (S.tick % 12) == 0
		if not asking and p.act.formReady and (p.power >= 65.0 or S.tick >= 14400):
			asking = true
			info = {"ready": p.form.ready, "coil": snappedf(p.form.coil, 0.01), "power": snappedf(p.power, 0.01), "tick": S.tick, "rtier": o.tier, "step0": p.form.step}
		if asking:
			i.light = false
			i.mx = 0.0
			i.transform = true   # held until the director takes it (between exchanges)
		SimCore.step(S, [i, null])
		S.out.fx.clear()
		S.out.feed.clear()
		if asking and not p.act.formReady and p.act.breakIn < 0:
			info["taken"] = S.tick
			info["step"] = p.form.step
			info["tier"] = p.tier
			info["armour"] = p.form.armour
			info["lasting"] = snappedf(p.form.lasting, 0.0001)
			info["surgeT"] = p.form.surgeT
			break
		if S.game.ko != null:
			info["ko"] = S.tick
			break
	SimCore.dispose(S)
	return info


func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 4
	var ticks: int = int(a[1]) if a.size() > 1 else 7200
	var same: int = 0
	for k in range(n):
		var x: Dictionary = _one(100 + k, ticks)
		var y: Dictionary = _one(100 + k, ticks)
		same += 1 if x.hash == y.hash else 0
		print("A seed %d: %s ticks, Protagonist at step %d (tier %d), rival tier %d; his steps [step, tier, tick] %s; releases [slot, n, coil] %s; holds told %d; twice: %s" % [100 + k, x.end, x.p, int(x.tier), int(x.rtier), str(x.steps), str(x.rel), x.holds, "same" if x.hash == y.hash else "DIFFERENT"])
	print("A: %d of %d matches the same both times" % [same, n])
	for k in range(4):
		print("B seed %d: %s" % [200 + k, str(_sling(200 + k))])
	quit()
