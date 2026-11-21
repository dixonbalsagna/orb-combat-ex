extends SceneTree
## QA's scripted player on Orb's scheme, both slots (sprint A1, A-QA-09): two pads on the real input hub play whole seeded matches against each other, each one as Orb plays: the right thumb flicks a strike (three ticks out, one every 30 to 48 ticks),
## LB is HELD from the foe's wind-up until contact (his windup end cue, a blow taken, or 90 ticks), the left stick walks at the foe, and the right stick beam is thrown at a stated pace.
##   godot --headless --path <tree copy with qa/godot/qa_planet.gd> --script res://qa/godot/orbs_player.gd -- <matches> <baseSeed> [--arm=default|swap|default-flip|swap-flip] [--beamevery=420] [--beamhold=50] [--capsec=900] [--wall=300] [--budget=3600]
## THE BEAM, at a stated pace: every --beamevery ticks (default 420, 7 s; a jitter of up to a fifth either way from the seed) a pad holds RB and leans the right stick toward the foe for --beamhold ticks (default 50: stage 3 comes at about 46), lets the stick go to
## fire, and RB a few ticks after. No other pace than that one; --beamevery=0 turns the beam off (the strikes and the guard alone).
## The arm is QA's own (records.gd): `swap` puts each fighter in the other's slot, so a win rate by FIGHTER is read from default and swap together. The setup is QaPlanet's (QA_PLANET) and `intro` false, power model as the setup says.
## One line, ORBS <json>: wins by slot, draws, timeouts, beams fired by slot (the cue beam_fire), flicks, hits landed by slot, the names in each slot, the win list by match with the fighters' names, the median length and the data hash. Read-only with respect to sim/.
const QaPlanet = preload("res://qa/godot/qa_planet.gd")
const Chk = preload("res://qa/godot/checklist_core.gd")

var hub: SimInputHub
var held: Array = [{}, {}]


func _init() -> void:
	var pos: Array = []
	var arm: String = "default"
	var every: int = 420
	var hold: int = 50
	var capsec: float = 900.0
	var wall: float = 300.0
	var budget: float = 3600.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--arm="):
			arm = a.substr(6)
		elif a.begins_with("--beamevery="):
			every = int(a.substr(12))
		elif a.begins_with("--beamhold="):
			hold = int(a.substr(11))
		elif a.begins_with("--capsec="):
			capsec = float(a.substr(9))
		elif a.begins_with("--wall="):
			wall = float(a.substr(7))
		elif a.begins_with("--budget="):
			budget = float(a.substr(9))
		else:
			pos.append(a)
	var n: int = int(pos[0]) if pos.size() > 0 else 10
	var base: int = int(pos[1]) if pos.size() > 1 else 1
	SimInputData.load_and_apply()
	var wins: Array = [0, 0]
	var beams: Array = [0, 0]
	var flicks: Array = [0, 0]
	var hits: Array = [0, 0]
	var chk_seen := {}   # X-13: for each of the checklist's ten items, in how many matches it was seen and the ticks it was first seen
	var other_log: Array = []   # the first few beams that were neither a stick beam nor RT + B, with the cues of that fighter just before (QA reads them)
	var src: Array = [{}, {}]   # X-17: what started each beam of each slot: stick (a beam_stage cue just before), rtb (RT held), other (anything else)
	var draws: int = 0
	var timeouts: int = 0
	var done: int = 0
	var stopped: bool = false
	var lens: Array = []
	var names: Array = ["", ""]
	var by_match: Array = []
	var t_all: int = Time.get_ticks_msec()
	for m in range(n):
		if float(Time.get_ticks_msec() - t_all) / 1000.0 > budget:
			stopped = true
			break
		var seed_: int = base + m
		var S := _make(seed_, arm)
		if QaPlanet.fellBack(S, seed_):
			quit(3)
			return
		names = [str(S.fighters[0].name), str(S.fighters[1].name)]
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_
		var chk = Chk.new()
		chk.begin(S)
		var st: Array = []
		for i in range(2):
			st.append({"next": 20 + 7 * i, "rsTo": -1, "aim": Vector2.ZERO, "lbTo": -1, "foeOpen": false, "foeT": -100, "bAt": (every + rng.randi_range(-every / 5, every / 5)) if every > 0 else -1, "bPhase": 0, "bUntil": -1})
		var t0: int = Time.get_ticks_msec()
		var result: int = -2   # -2 timeout, -1 draw, 0 or 1 the winner
		var koSeen: int = -1
		var cap: int = int(capsec * 60.0)
		var dend = load("res://sim/director/ending.gd") if ResourceLoader.exists("res://sim/director/ending.gd") else null
		for t in range(cap):
			for i in range(2):
				_drive(i, S, t, st[i], rng, every, hold)
			_step(S, t, st, beams, flicks, hits, src, other_log, chk)
			if S.game.ko != null and koSeen < 0:
				koSeen = t
			if koSeen >= 0 and S.game.koT > 3.0:
				result = 1 if S.game.ko == S.fighters[0] else 0
				break
			if dend != null and bool(dend.noContest(S)):
				result = -1
				break
			if (Time.get_ticks_msec() - t0) / 1000.0 > wall:
				break
		lens.append(float(S.tick) / 60.0)
		var cr: Dictionary = chk.result()
		for ck in cr:
			var cs: Dictionary = chk_seen.get(ck, {"seen": 0, "ticks": []})
			if bool(cr[ck].seen):
				cs.seen = int(cs.seen) + 1
				cs.ticks.append(int(cr[ck].tick))
			chk_seen[ck] = cs
		if result >= 0:
			wins[result] += 1
		elif result == -1:
			draws += 1
		else:
			timeouts += 1
		by_match.append([seed_, result, names[0], names[1]])
		done += 1
		for i in range(2):
			for k in held[i].keys():
				hub.pad_button(i, k, false)
		SimCore.dispose(S)
	lens.sort()
	var med: float = lens[lens.size() / 2] if lens.size() > 0 else 0.0
	var out := {"arm": arm, "n": n, "done": done, "budgetStopped": stopped, "winsBySlot": wins, "draws": draws, "timeouts": timeouts, "beamsBySlot": beams, "beamSources": src, "checklist": chk_seen, "otherBeams": other_log, "flicksBySlot": flicks, "hitsBySlot": hits, "namesSlots": names, "beamEvery": every, "beamHold": hold,
		"medianSec": snappedf(med, 0.1), "dataHash": str(SimReplay.dataHash({})), "matches": by_match}
	print("ORBS " + JSON.stringify(out))
	quit()


func _make(seed_: int, arm: String) -> SimState:
	hub = SimInputHub.new()
	held = [{}, {}]
	var su: Dictionary = QaPlanet.setup(seed_, hub.setup())
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {"p1": false, "p2": false}, su)
	SimGolden.applyArm(arm, S.fighters)
	hub.set_pad_has_right_stick(0, true)
	hub.set_pad_has_right_stick(1, true)
	hub.pad_button(0, "west", true)   # one press each, in slot order, so pad 0 drives slot 0 and pad 1 slot 1
	hub.pad_button(0, "west", false)
	hub.pad_button(1, "west", true)
	hub.pad_button(1, "west", false)
	return S


func _btn(i: int, name: String, down: bool) -> void:
	if down == held[i].has(name):
		return
	if down:
		held[i][name] = true
	else:
		held[i].erase(name)
	hub.pad_button(i, name, down)


func _drive(i: int, S: SimState, t: int, st: Dictionary, rng: RandomNumberGenerator, every: int, hold: int) -> void:
	var me = S.fighters[i]
	var foe = S.fighters[1 - i]
	var dx: float = SimWrap.sdx(me.x, foe.x)
	var dy: float = foe.y - me.y
	hub.pad_stick(i, signf(dx) if absf(dx) > 110.0 else 0.0, signf(dy) if absf(dy) > 40.0 else 0.0)
	var side: float = 1.0 if dx >= 0.0 else -1.0
	# the beam, at its stated pace: RB down, the right stick toward him for `hold` ticks, the stick let go to fire, RB up 6 ticks later
	if every > 0:
		match int(st.bPhase):
			0:
				if t >= int(st.bAt):
					_btn(i, "rb", true)
					st.bPhase = 1
					st.bUntil = t + 6   # RB first, then the stick
			1:
				if t >= int(st.bUntil):
					hub.pad_stick_right(i, side, 0.0)
					st.bPhase = 2
					st.bUntil = t + hold
			2:
				hub.pad_stick_right(i, side, 0.0)
				if t >= int(st.bUntil):
					hub.pad_stick_right(i, 0.0, 0.0)
					st.bPhase = 3
					st.bUntil = t + 6
			3:
				if t >= int(st.bUntil):
					_btn(i, "rb", false)
					st.bPhase = 0
					st.bAt = t + every + rng.randi_range(-every / 5, every / 5)
	var beaming: bool = int(st.bPhase) != 0
	if not beaming:
		if t >= int(st.next):
			var d: int = rng.randi_range(1, 4)
			match d:
				1:
					st.aim = Vector2(0.0, 1.0)
				2:
					st.aim = Vector2(0.0, -1.0)
				3:
					st.aim = Vector2(side, 0.0)
				_:
					st.aim = Vector2(-side, 0.0)
			st.rsTo = t + 3
			st.next = t + rng.randi_range(30, 48)
		if t < int(st.rsTo):
			hub.pad_stick_right(i, st.aim.x, st.aim.y)
		elif t == int(st.rsTo):
			hub.pad_stick_right(i, 0.0, 0.0)
		# LB is HELD from the foe's wind-up until contact, not tapped
		var open: bool = bool(st.foeOpen) and t - int(st.foeT) <= 90
		var guard: bool = open or (not DirBrawl.winding(S, foe).is_empty())
		if guard and int(st.lbTo) < 0:
			_btn(i, "lb", true)
			st.lbTo = t
		elif not guard and int(st.lbTo) >= 0:
			_btn(i, "lb", false)
			st.lbTo = -1
	elif int(st.lbTo) >= 0:
		_btn(i, "lb", false)
		st.lbTo = -1


func _step(S: SimState, t: int, st: Array, beams: Array, flicks: Array, hits: Array, src: Array, other_log: Array, chk) -> void:
	hub.set_humans(true, true)
	var hb: Object = hub
	for i in range(2):
		hb.call("set_struggle", i, SimDir.inStruggle(S, S.fighters[i]))
	var its: Array = [hub.intent(0), hub.intent(1)]
	var pausing: bool = S.pause.left > 0
	if SimCore.step(S, its):
		hub.consumed()
	elif pausing:
		if S.pause.left > 0:
			hub.drop_edges()
		else:
			hub.resume()
	chk.feed(S, t, its)
	for e in S.out.fx:
		if e.type == "cue":
			var who: int = int(e.actor)
			if who < 0 or who > 1:
				continue
			var k: String = str(e.kind)
			var rl: Array = st[who].get("recent", [])
			rl.append("%d:%s:%s" % [t, k, str(e.text)])
			if rl.size() > 14:
				rl.pop_front()
			st[who]["recent"] = rl
			if k == "windup" and str(e.text) == "start":
				st[1 - who].foeT = t
				st[1 - who].foeOpen = true
			elif k == "windup" and str(e.text) == "end":
				st[1 - who].foeOpen = false
			elif k == "beam_stage":
				st[who]["stageT"] = t
			elif k == "beam_charge" and str(e.text) == "start":
				var how: String = "stick" if t - int(st[who].get("stageT", -100)) <= 5 else ("rtb" if (int(S.fighters[who].input.stanceMask) & 4) != 0 else "other")
				src[who][how] = int(src[who].get(how, 0)) + 1
				if how == "other" and other_log.size() < 12:
					other_log.append({"t": t, "slot": who, "recent": st[who].get("recent", []).duplicate(), "rb": held[who].has("rb"), "phase": int(st[who].bPhase)})
			elif k == "beam_fire":
				beams[who] += 1
			elif k == "stick_start":
				flicks[who] += 1
		elif e.type == "damage":
			var at: int = int(e.attacker)
			var vi: int = int(e.victim)
			if at >= 0 and at <= 1 and vi >= 0 and vi <= 1 and at != vi:
				hits[at] += 1
				st[vi].foeOpen = false   # contact: the guard goes down
	hub.on_events(S.out.fx)
	S.out.fx.clear()
	S.out.feed.clear()
