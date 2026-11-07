extends SceneTree
## Stick-only against buttons-only, in wins (EP's order of 2026-11-01, read 1): one scripted pad on the real input hub, whole matches against the AI at one level.
## The pad walks at the rival and, every 8 to 24 ticks, makes one press of its arm: stick = a right-stick flick in one of the four screen directions; buttons = X (60%), Y (25%), B (15%); pad = a mix of both
## (X 45%, Y 17%, B 6%, flick 20%, RB + X 9%), the cadence and mix of Combat's own read (docs/combat/pending/stick-directions/stick_bands.gd), which this borrows. A win is the AI being the one knocked out.
## Bots for Game Design's rows of docs/design/stick-lands.md (After Combat's read): react = a flick only as the foe's Y or B winds up; idle = that, or no light of his in the last 20 ticks; lb = LB held, a flick on a foe who is not
## guarding and 40 ticks after the last flick; x = X every 8 ticks; afk = no input at all (the idle player of the match ending); holdx, holdy, holdb = that button pressed at tick 60 and never released (a stuck button: the web gamepad path can drop a release), nothing else touched; stuck = the right stick held up from tick 60 to the end and nothing else touched (a stale or drifting stick); padidle = the pad mix for 2,400 ticks, then every control let go for the rest of the match, counting the blows and flicks the idle pad still makes after 180 ticks (a stuck-input check: the playtest of 2026-11-06 reports a fighter that kept attacking with the controller let go); meteor = the meteor route: X mash and the transform chord (LT + RT held 40 ticks) whenever a form is ready, and once both fighters are at tier 4 and close, the stick held up for 56 ticks (level 3), let go, then B held 36 ticks inside the stun (the ignition, launch.json arc.bankFull); driver = RB + B held 90 ticks (level 3) and let go, standing off at range while it charges. Counts: flicks, stick_hit cues (a stun when n is over 0), and the trade breaks (closes) by each side.
##   godot --headless --path . --script res://qa/godot/stickplay.gd -- <matches> <baseSeed> --arm=stick|buttons|pad|x|react|idle|lb|driver|afk|meteor|padidle|stuck|holdx|holdy|holdb --level=easy|medium|hard [--capsec=900] [--wall=300] [--budget=3600]
## The pad takes slot 0 in every match (the hub's pad 0), so a spawn-side effect is in all arms alike. Read-only with respect to sim/. Prints one JSON line.
const QaPlanet = preload("res://qa/godot/qa_planet.gd")

var hub: SimInputHub
var held: Dictionary = {}


func _init() -> void:
	var pos: Array = []
	var arm: String = "stick"
	var level: String = "medium"
	var capsec: float = 900.0
	var wall: float = 300.0
	var budget: float = 3600.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--arm="):
			arm = a.substr(6)
		elif a.begins_with("--level="):
			level = a.substr(8)
		elif a.begins_with("--capsec="):
			capsec = float(a.substr(9))
		elif a.begins_with("--wall="):
			wall = float(a.substr(7))
		elif a.begins_with("--budget="):
			budget = float(a.substr(9))
		else:
			pos.append(a)
	var n: int = int(pos[0]) if pos.size() > 0 else 20
	var base: int = int(pos[1]) if pos.size() > 1 else 1
	SimInputData.load_and_apply()
	var dai = load("res://sim/director/ai.gd")
	var dend = load("res://sim/director/ending.gd") if ResourceLoader.exists("res://sim/director/ending.gd") else null   # the match ending's park: absent on a build before it
	dai.set("level", level)
	var won := 0
	var lost := 0
	var draws := 0
	var timeouts := 0
	var capped := 0
	var lens: Array = []
	var dealt := 0.0
	var taken := 0.0
	var thrown := 0
	var cnt := {"flicks": 0, "refused": 0, "hits": 0, "clean": 0, "closeAI": 0, "closeMe": 0, "secs": 0.0}
	var t_all: int = Time.get_ticks_msec()
	var done := 0
	var stopped := false
	for m in range(n):
		if float(Time.get_ticks_msec() - t_all) / 1000.0 > budget:
			stopped = true
			break
		var seed: int = base + m
		var S := _make(seed)
		if QaPlanet.fellBack(S, seed):
			quit(3)
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var next: int = 20
		var lastFlick: int = -1000
		var lastLight: int = -1000
		var lbTo: int = -1
		var drvTo: int = -1
		var mtState: int = 0
		var mtAt: int = 0
		var mtLast: int = -1000
		var mtTf: int = -1
		var rsTo: int = -1
		var aim := Vector2.ZERO
		var off: Dictionary = {2: ["west"]}
		_btn("west", true)
		var t0: int = Time.get_ticks_msec()
		var cap: int = int(capsec * 60.0)
		var result: String = "timeout"
		var koSeen: int = -1
		for t in range(cap):
			if arm == "meteor":
				var me = S.fighters[0]
				var foe0 = S.fighters[1]
				if mtTf >= 0:
					if t >= mtTf:
						hub.pad_trigger(0, "lt", 0.0)
						hub.pad_trigger(0, "rt", 0.0)
						mtTf = -1
				elif mtState == 0 and me.act.formReady:
					hub.pad_trigger(0, "lt", 1.0)
					hub.pad_trigger(0, "rt", 1.0)
					mtTf = t + 40
				elif mtState == 0 and me.tier >= 4.0 and foe0.tier >= 4.0 and absf(SimWrap.sdx(me.x, foe0.x)) < 400.0 and t - mtLast > 150 and me.state == "free" and not DirStick._cant(S, me):
					mtState = 4   # a quiet spell first: a blow of his own still winding up would leave the charge pending too long (stick_refused late)
					mtAt = t + 24
				if mtState == 4:
					if t >= mtAt and not DirStick._cant(S, me):
						mtState = 1
						mtAt = t + 56
						cnt["meteorTries"] = int(cnt.get("meteorTries", 0)) + 1
					elif t >= mtAt + 90:
						mtState = 0
						mtLast = t
				if mtState == 1:
					hub.pad_stick_right(0, 0.0, 1.0)
					hub.pad_stick(0, 0.0, 0.0)
					if t >= mtAt:
						hub.pad_stick_right(0, 0.0, 0.0)
						mtState = 2
						mtAt = t + 3
				elif mtState == 2:
					if t >= mtAt:
						_btn("east", true)
						mtState = 3
						mtAt = t + 36
				elif mtState == 3:
					if t >= mtAt:
						_btn("east", false)
						mtState = 0
						mtLast = t
			var idleNow: bool = arm == "padidle" and t >= 2400
			if idleNow and t == 2400:
				for hb in held.keys():
					_btn(hb, false)
				hub.pad_stick(0, 0.0, 0.0)
				hub.pad_stick_right(0, 0.0, 0.0)
				hub.pad_trigger(0, "lt", 0.0)
				hub.pad_trigger(0, "rt", 0.0)
				off.clear()
				rsTo = -1
				cnt["idleFrom"] = 2400 + 180
			if t == 60 and arm.begins_with("hold"):
				_btn({"holdx": "west", "holdy": "north", "holdb": "east"}[arm], true)
			if arm == "stuck" and t >= 60:
				hub.pad_stick_right(0, 0.0, 1.0)
			if drvTo < 0 and arm != "afk" and arm != "stuck" and not arm.begins_with("hold") and not idleNow and not (arm == "meteor" and mtState >= 1 and mtState != 4):
				_walk(S)
			else:
				hub.pad_stick(0, 0.0, 0.0)
			if t >= next and not idleNow:
				var r: float = rng.randf()
				var press: String = ""
				var gapMax: int = 24
				var gapMin: int = 8
				var foe = S.fighters[1]
				var winding: bool = not DirBrawl.winding(S, foe).is_empty()
				match arm:
					"stick":
						press = "s"
					"buttons":
						press = "x" if r < 0.6 else ("y" if r < 0.85 else "b")
					"driver":
						press = "d" if (S.fighters[0].ki >= 30.0 and S.fighters[0].state == "free" and S.dirS.ex == null) else "x"   # the driver when he can pay for level 3 (24 ki and 4 a second held), X to build ki between
						gapMin = 40 if press == "d" else 8
						gapMax = gapMin
					"meteor":
						press = "x" if (mtState == 0 and mtTf < 0) else ""
						gapMin = 8
						gapMax = 8
					"afk", "stuck", "holdx", "holdy", "holdb":
						press = ""
						gapMin = 600
						gapMax = 600
					"x":
						press = "x"
						gapMin = 8
						gapMax = 8
					"react":
						press = "s" if (winding and t - lastFlick > 20) else ""
						gapMin = 1
						gapMax = 1
					"idle":
						press = "s" if ((winding or t - lastLight > 20) and t - lastFlick > 20) else ""
						gapMin = 1
						gapMax = 1
					"lb":
						press = "s" if (foe.act.guardSince < 0 and t - lastFlick > 40) else ""
						gapMin = 1
						gapMax = 1
					_:
						press = "x" if r < 0.45 else ("y" if r < 0.62 else ("b" if r < 0.68 else ("s" if r < 0.88 else "ex")))
				var names: Array = []
				match press:
					"x":
						names = ["west"]
					"y":
						names = ["north"]
					"b":
						names = ["east"]
					"ex":
						names = ["rb", "west"]
					"d":
						_btn("rb", true)
						_btn("east", true)
						drvTo = t + 90
					"s":
						aim = _aim(S, rng.randi_range(1, 4))
						rsTo = t + 3
						thrown += 1
						lastFlick = t
						if arm == "lb":
							_btn("lb", true)
							lbTo = t + 10
					_:
						pass
				for nm in names:
					_btn(nm, true)
				if not names.is_empty():
					off[t + 2] = names
				next = t + (rng.randi_range(gapMin, gapMax) if press != "" or gapMax > 1 else 1)
			if drvTo >= 0 and t >= drvTo:
				_btn("east", false)   # B first, RB held a few ticks more: "let go to fire" reads B's release with the family still held
				if t >= drvTo + 4:
					_btn("rb", false)
					drvTo = -1
			if lbTo >= 0 and t >= lbTo:
				_btn("lb", false)
				lbTo = -1
			if off.has(t):
				for nm in off[t]:
					_btn(nm, false)
				off.erase(t)
			if t < rsTo:
				hub.pad_stick_right(0, aim.x, aim.y)
			elif t == rsTo:
				hub.pad_stick_right(0, 0.0, 0.0)
			var h0: float = S.fighters[1].hp
			var h1: float = S.fighters[0].hp
			var over: bool = S.game.ko != null
			lastLight = _step(S, cnt, t, lastLight)
			if not over:
				dealt += maxf(0.0, h0 - S.fighters[1].hp)
				taken += maxf(0.0, h1 - S.fighters[0].hp)
			if S.game.ko != null and koSeen < 0:
				koSeen = t
			if koSeen >= 0 and S.game.koT > 3.0:
				result = "won" if S.game.ko == S.fighters[1] else "lost"
				break
			if dend != null and bool(dend.noContest(S)):
				result = "draw"
				break
			if (Time.get_ticks_msec() - t0) / 1000.0 > wall:
				result = "capped"
				break
		lens.append(float(S.tick) / 60.0)
		cnt.secs += float(S.tick) / 60.0
		_btn("lb", false)
		match result:
			"won":
				won += 1
			"lost":
				lost += 1
			"draw":
				draws += 1
			"capped":
				capped += 1
			_:
				timeouts += 1
		done += 1
		SimCore.dispose(S)
	lens.sort()
	var med: float = lens[lens.size() / 2] if lens.size() > 0 else 0.0
	print("STICKPLAY " + JSON.stringify({"arm": arm, "level": level, "n": n, "done": done, "won": won, "lost": lost, "draws": draws, "timeouts": timeouts, "wallCapped": capped, "budgetStopped": stopped, "medianSec": snappedf(med, 0.1), "dealt": snappedf(dealt, 1.0), "taken": snappedf(taken, 1.0), "flicksThrown": thrown, "cues": cnt, "seconds": snappedf(float(Time.get_ticks_msec() - t_all) / 1000.0, 1.0)}))
	quit()


func _make(seed_: int) -> SimState:
	hub = SimInputHub.new()
	held = {}
	var su: Dictionary = QaPlanet.setup(seed_, hub.setup())
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {"p1": false, "p2": true}, su)
	hub.set_pad_has_right_stick(0, true)
	return S


func _btn(name: String, down: bool) -> void:
	if down == held.has(name):
		return
	if down:
		held[name] = true
	else:
		held.erase(name)
	hub.pad_button(0, name, down)


func _walk(S: SimState) -> void:
	var dx: float = SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)
	var dy: float = S.fighters[1].y - S.fighters[0].y
	hub.pad_stick(0, signf(dx) if absf(dx) > 110.0 else 0.0, signf(dy) if absf(dy) > 40.0 else 0.0)


func _aim(S: SimState, dir: int) -> Vector2:
	var side: float = 1.0 if SimWrap.sdx(S.fighters[0].x, S.fighters[1].x) >= 0.0 else -1.0
	match dir:
		1:
			return Vector2(0.0, 1.0)
		2:
			return Vector2(0.0, -1.0)
		3:
			return Vector2(side, 0.0)
	return Vector2(-side, 0.0)


## One tick in the host's order (render/core/sim_host.gd tick), as Combat's read does.
func _step(S: SimState, cnt: Dictionary, t: int, lastLight: int) -> int:
	hub.set_humans(S.fighters[0].ai == null, S.fighters[1].ai == null)
	hub.set_struggle(0, SimDir.inStruggle(S, S.fighters[0]))
	var it: SimIntent = hub.intent(0)
	var pausing: bool = S.pause.left > 0
	if SimCore.step(S, [it, null]):
		hub.consumed()
	elif pausing:
		if S.pause.left > 0:
			hub.drop_edges()
		else:
			hub.resume()
	for e in S.out.fx:
		if e.type != "cue":
			continue
		var who: int = int(e.actor)
		match str(e.kind):
			"stick_start":
				if who == 0:
					cnt.flicks += 1
					if cnt.has("idleFrom") and t >= int(cnt.idleFrom):
						cnt["idleFlicks"] = int(cnt.get("idleFlicks", 0)) + 1
			"stick_refused":
				if who == 0:
					cnt.refused += 1
					cnt["refused:" + str(e.text) + "/" + str(e.get("source"))] = int(cnt.get("refused:" + str(e.text) + "/" + str(e.get("source")), 0)) + 1
			"stick_hit":
				if who == 0:
					cnt.hits += 1
					if int(e.n) > 0:
						cnt.clean += 1
			"trade_break":
				if who == 1:
					cnt.closeAI += 1
				elif who == 0:
					cnt.closeMe += 1
			"blow":
				if who == 1 and str(e.text) == "light":
					lastLight = t
				elif who == 0:
					cnt["blow:" + str(e.text)] = int(cnt.get("blow:" + str(e.text), 0)) + 1
					if cnt.has("idleFrom") and t >= int(cnt.idleFrom):
						cnt["idleBlows"] = int(cnt.get("idleBlows", 0)) + 1
						cnt["idleBlow:" + str(e.text)] = int(cnt.get("idleBlow:" + str(e.text), 0)) + 1
			"driver_fire", "driver_drop", "driver_refused", "charge_full", "arc_send", "meteor", "meteor_launch", "arc", "chase", "no_contest", "stick_armour", "armour":
				if who == 0:
					cnt[str(e.kind) + ":" + str(e.text)] = int(cnt.get(str(e.kind) + ":" + str(e.text), 0)) + 1
	hub.on_events(S.out.fx)
	S.out.fx.clear()
	S.out.feed.clear()
	return lastLight
