extends SceneTree
## Probe: Performance's mid-match press (its latency bench: the scene, a throwaway KeyE that claims player one at 1.5 s,
## then ONE press at about 9.5 s) through the real hub (the solo keyboard), the host's v2 setup, an idle dummy at d units.
## Per case: the cooldown and the band at the press; the first tick (0 = the press tick) of a sim START as Controls' T1
## counts it (an exchange, his rush, a rush event, state, velocity or position); of his BODY changing (state, velocity or
## position: what a picture shows); of a press_ack; and every event of the first 8 ticks.
## -- (no args)


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var out := []
	for dist in [80.0, 150.0, 250.0]:
		for k in [["KeyJ", "light"], ["KeyK", "heavy"]]:
			out.append(_case(String(k[0]), String(k[1]), dist))
	print(JSON.stringify(out))
	quit()


func _case(code: String, what: String, dist: float) -> Dictionary:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	var quiet := SimIntent.new()
	var t := 0
	while t < 570:
		if t == 90:
			hub.key("KeyE", true)
		elif t == 94:
			hub.key("KeyE", false)
		if t == 560:
			b.x = SimWrap.wrap(a.x + dist)
			b.y = WorldTerrain.groundY(S, b.x)
			a.y = WorldTerrain.groundY(S, a.x)
			a.vx = 0.0
			a.vy = 0.0
			b.vx = 0.0
			b.vy = 0.0
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
		S.out.feed.clear()
		t += 1
	var r := {"what": what, "d": dist, "T": snappedf(S.T, 0.01), "cool": snappedf(S.dirS.cool, 0.01), "exN": S.dirS.exN, "band": DirBands.band(a, b), "state0": a.state,
		"start": -1, "body": -1, "ack": -1, "lungeWind": -1, "ev": []}
	var x0: float = a.x
	var y0: float = a.y
	for k in range(14):
		if k == 0:
			hub.key(code, true)
		elif k == 3:
			hub.key(code, false)
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		var body: bool = a.state != "free" or absf(a.vx) > 0.0 or absf(a.vy) > 0.0 or absf(SimWrap.sdx(x0, a.x)) > 0.0 or absf(a.y - y0) > 0.0
		var started: bool = S.dirS.ex != null or a.rush != null or body
		var evs := []
		for e in S.out.fx:
			var nm: String = String(e.kind) if String(e.type) == "cue" else String(e.type)
			if String(e.type) != "tick":
				evs.append(nm + ("/" + String(e.text) if String(e.type) == "cue" and String(e.text) != "" else ""))
			if nm == "rush":
				started = true
			elif nm == "press_ack" and int(e.actor) == 0 and int(r.ack) < 0:
				r.ack = k
			if nm.begins_with("lunge_") and int(r.lungeWind) < 0:
				r.lungeWind = int(e.amount)
		if started and int(r.start) < 0:
			r.start = k
		if body and int(r.body) < 0:
			r.body = k
		if k < 8 and evs.size() > 0:
			r.ev.append(str(k) + ": " + ", ".join(evs))
		S.out.fx.clear()
		S.out.feed.clear()
	SimCore.dispose(S)
	return r
