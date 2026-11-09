extends SceneTree
## One energy model, Simulation's part (sim/core/power.gd): godot --headless --path . --script res://sim/core/tools/power_check.gd
## The numbers against docs/design/power-scale.md's table; no send past what he has, and none by a base or tier 2 fighter glows; flat-out and close flight; a match's switch keeps to its match;
## Combat's shares; two runs one hash and a rollback across launches; the page's travel. --negative-control lets a send past what he has, and leaves a setup's "travel" unread, and each must be seen.

var fails: int = 0
const FIELD: Dictionary = {"intro": false, "planet": 7, "touch": 3, "planetGen": 3, "power": true}


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func near(a: float, b: float, by: float) -> bool:
	return absf(a - b) <= by


func _new(su: Dictionary, ai: bool = false, seed: int = 77) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": ai, "p2": ai}, su)
	return S


func _numbers() -> void:
	var S := _new(FIELD)
	var f = S.fighters[0]
	for row in [[1.0, 0.0, 0.0, 4.9, 2000.0, 5000.0], [1.0, 100.0, 0.2, 8.2, 2570.0, 5910.0], [2.0, 35.0, 0.3367, 11.5, 3050.0, 6620.0], [3.0, 65.0, 0.6633, 26.0, 4590.0, 8695.0], [4.0, 100.0, 1.0, 60.5, 7000.0, 11525.0]]:
		f.tier = row[0]
		f.power = row[1]
		ok(near(SimPower.level(f), row[2], 0.001), "level at tier %d, %d%%: %.4f" % [int(row[0]), int(row[1]), SimPower.level(f)])
		ok(near(SimPower.energy(f), row[3], 0.5), "energy: %.2f against %.1f" % [SimPower.energy(f), row[3]])
		ok(near(SimPower.speed(f, 1.0), row[4], 25.0), "full send: %.0f against %.0f" % [SimPower.speed(f, 1.0), row[4]])
		var far: float = SimPower.flatSpeed(S, f, 430.0 * f.spd * SimForms.speedMul(S, f) * 2.4, 1.0)
		ok(near(far, row[5] * f.spd, 25.0), "flat out: %.0f against %.0f" % [far, row[5] * f.spd])
	f.tier = 1.0
	f.power = 0.0
	ok(near(WorldSlide.launchTravel(1.0, 0.0), 2.0, 1.0e-6) and WorldSlide.launchTravel(0.0, 1.0) == 1.0, "along the line, twice; straight up, once")
	for row in [["fullB", 2000.0], ["launcher", 1414.0], ["tap", 707.0], ["firstFlash", 1414.0], ["unlisted", 1000.0], ["templates.heavy_clash", 1414.0], ["templates.guard_break", 1414.0], ["templates.dodge", 1000.0], ["templates.charge_interrupt.heavy", 1414.0], ["knock", 707.0], ["beam.signature", 2000.0], ["beam.guarded", 1000.0], ["finisher.fixed", 1414.0], ["breakLaunch", 2000.0]]:
		ok(near(SimPower.speed(f, SimPower.share(row[0])), row[1], 2.0), "%s at base: %.0f" % [row[0], SimPower.speed(f, SimPower.share(row[0]))])
	ok(SimPower.templateShare("charge_interrupt", "light", 900.0) == 0.25 and SimPower.templateShare("charge_interrupt", "heavy", 1500.0) == 0.5, "a template's light and heavy rows")
	ok(SimPower.templateShare("guard_break", "heavy", 700.0) == 0.125, "a small pop")
	ok(SimPower.shareBetween("brawl.launchAnywhere", 0.0) == 0.25 and SimPower.shareBetween("brawl.launchAnywhere", 1.0) == 0.5, "launch anywhere, by its power")
	ok(near(SimPower.sendForce(S, f, 1600.0, "launcher"), 1414.2, 1.0) and SimPower.fit(S, 1000.0, 0.6, 0.8) * SimPower.fm(S, 3.0) == 1000.0, "no force multiplier past the share")
	ok(near(SimPower.fit(S, 1000.0, 1.0, 0.32), 952.4, 1.0), "nor a direction that isn't a unit")
	SimCore.dispose(S)
	var O := _new({"intro": false, "planet": 7, "touch": 3, "planetGen": 3, "power": false})   # off by its setup, whatever the data says
	SimPower.bindStep(O)   # the factor along the line is bound as a match steps: this one, before it's read
	ok(not O.powerOn and near(WorldSlide.launchTravel(1.0, 0.0), 6.0, 1.0e-6), "off: x6 as ever")
	ok(SimForms.launchMul(O, O.fighters[0]) == 1.0 + O.fighters[0].ld.launch * (O.fighters[0].tier - 1.0), "off: the ladder's launch")
	ok(SimPower.sendForce(O, O.fighters[0], 1600.0, "launcher") == 1600.0 and SimPower.fit(O, 1600.0, 1.0, 0.32) * SimPower.fm(O, 2.0) * 1.5 == 4800.0, "off: the authored force and its multipliers")
	SimCore.dispose(O)


## Flight held flat out, by tier: the measure, against the table. Close to the rival, what it was with the switch off.
func _flight() -> void:
	var off: Dictionary = FIELD.duplicate()
	off["power"] = false
	for tier in [1, 2, 3, 4]:
		var got: Array = []
		for su in [FIELD, off]:
			var s2: Dictionary = su.duplicate()
			if tier > 1:
				s2["startTier"] = tier
			var S := _new(s2)
			var f = S.fighters[0]
			var o = S.fighters[1]
			var i := SimIntent.new()
			i.mx = 1.0
			i.sprint = true
			i.dash = true
			f.x = SimWrap.wrap(o.x + 14000.0)
			f.y = 6000.0
			o.y = 6000.0
			var far: float = 0.0
			for t in range(90):
				SimCore.step(S, [i, null])
				S.out.fx.clear()
				S.out.feed.clear()
				far = maxf(far, sqrt(f.vx * f.vx + f.vy * f.vy))
			var close: float = 0.0
			f.vx = 0.0
			for t in range(40):
				f.x = SimWrap.wrap(o.x + 300.0)
				SimCore.step(S, [i, null])
				S.out.fx.clear()
				S.out.feed.clear()
				close = maxf(close, sqrt(f.vx * f.vx + f.vy * f.vy))
			got.append([far, close, SimPower.level(f), f.spd])
			SimCore.dispose(S)
		var want: float = 5000.0 * SimDetMath.pow(2.305, got[0][2]) * got[0][3]
		print("flight tier %d: flat out %.0f (off %.0f), close %.0f (off %.0f)" % [tier, got[0][0], got[1][0], got[0][1], got[1][1]])
		ok(near(got[0][0], want, want * 0.02), "tier %d: flat out %.0f against %.0f" % [tier, got[0][0], want])
		ok(got[0][1] == got[1][1], "tier %d: the close dash doesn't change (%.1f, %.1f)" % [tier, got[0][1], got[1][1]])
	var a: Dictionary = FIELD.duplicate()
	a["flatOut"] = 3500.0
	var S2 := _new(a)
	ok(S2.powerFlat == 3500.0, "the page's base")
	var h1: String = str(SimHash.stateHash(S2).gameplay)
	SimCore.dispose(S2)
	a["flatOut"] = 90000.0
	var S3 := _new(a)
	ok(S3.powerFlat == 7000.0, "held to the data's range (%.0f)" % S3.powerFlat)
	ok(str(SimHash.stateHash(S3).gameplay) != h1, "the base is in the hash")
	SimCore.dispose(S3)


## The page's slider for a send's speed (Orb's ?travel=, x1.25 to x2): a setup's "travel" is the factor along the line, held to the data's range and hashed. A send's rise is the same,
## its sideways speed goes by the factor. A match with no word takes the data's; with the model off the word does nothing and it's x6 as ever.
func _travel() -> void:
	var a: Dictionary = FIELD.duplicate()
	var S0 := _new(a)
	SimPower.bindStep(S0)
	ok(S0.powerTravel == SimPower.launchTravel and near(WorldSlide.launchTravel(1.0, 0.0), SimPower.launchTravel, 1.0e-6), "no word: the data's x%.2f" % S0.powerTravel)
	var h0: String = str(SimHash.stateHash(S0).gameplay)
	_send(S0)
	var d0 = S0.fighters[1]
	var sent0: Array = [d0.vx, d0.vy, d0.launchT]
	SimCore.dispose(S0)
	a["travel"] = 1.25
	var S1 := _new(a)
	SimPower.bindStep(S1)
	ok(S1.powerTravel == 1.25 and near(WorldSlide.launchTravel(1.0, 0.0), 1.25, 1.0e-6) and WorldSlide.launchTravel(0.0, 1.0) == 1.0, "the page's x1.25 along the line (%.2f); straight up, once" % S1.powerTravel)
	ok(str(SimHash.stateHash(S1).gameplay) != h0, "the factor is in the hash")
	_send(S1)
	var d1 = S1.fighters[1]
	var s: float = 1.0 / (1.0 + 0.32 + 1.0e-9)
	ok(d1.vy == sent0[1] and near(d1.launchT, 1.0 + 0.25 * s, 1.0e-9) and near(d1.vx / sent0[0], d1.launchT / sent0[2], 1.0e-9), "a send: the same rise (%.1f), sideways by the factor (%.1f against %.1f)" % [d1.vy, d1.vx, sent0[0]])
	SimCore.dispose(S1)
	for row in [[0.5, SimPower.travelMin], [9.0, SimPower.travelMax]]:
		a["travel"] = row[0]
		var S2 := _new(a)
		ok(S2.powerTravel == row[1], "x%.2f held to the data's range: x%.2f" % [row[0], S2.powerTravel])
		SimCore.dispose(S2)
	a["travel"] = 1.25
	a["power"] = false
	var O := _new(a)
	SimPower.bindStep(O)
	ok(not O.powerOn and near(WorldSlide.launchTravel(1.0, 0.0), 6.0, 1.0e-6), "off: the word does nothing, x6 as ever")
	SimCore.dispose(O)
	var D := _new({"intro": false, "planet": 7, "touch": 3, "planetGen": 3})
	ok(D.powerOn == SimPower.enabled(), "a match with no key of its own takes the data's switch")
	SimCore.dispose(D)


## LT held, fast at any range (Game Design's overnight-2026-11-08.md (c); power.json's dash, here by the setup's "dash"): its top
## speed is the level's flat out whatever the gap; it rises to it from rest at least 1,000 a second on its first tick and is
## at the top by tick 12; Game Design's close times from 1,000, 3,000 and 6,000 at base, and 6,000 at the top, to 1.5 bh, with
## the other standing still. Off it's the dash as it was, and nothing in the hash moves.
func _dashAt(su: Dictionary, gap: float, tier: float, power_: float) -> SimState:
	var s2: Dictionary = su.duplicate()
	if tier > 1.0:
		s2["startTier"] = int(tier)
	var S := _new(s2)
	var f = S.fighters[0]
	var o = S.fighters[1]
	f.power = power_
	f.x = SimWrap.wrap(o.x - gap)
	f.y = 6000.0
	o.y = 6000.0
	f.vx = 0.0
	f.vy = 0.0
	return S


## Ticks from the press until he's within 1.5 bh of the other, who stands still; and his speed on ticks 1 to 12.
func _dashRun(S: SimState, cap: int) -> Array:
	var f = S.fighters[0]
	var o = S.fighters[1]
	var ox: float = o.x
	var i := SimIntent.new()
	i.mx = 1.0
	i.sprint = true
	i.dash = true
	var speeds: Array = []
	for t in range(cap):
		o.x = ox
		o.y = 6000.0
		o.vx = 0.0
		o.vy = 0.0
		SimCore.step(S, [i, null])
		S.out.fx.clear()
		S.out.feed.clear()
		if speeds.size() < 12:
			speeds.append(absf(f.vx))
		if absf(SimWrap.sdx(f.x, ox)) <= 1.5 * SimDepth.BH:
			return [t + 1, speeds]
	return [-1, speeds]


func _dash() -> void:
	var on: Dictionary = FIELD.duplicate()
	on["dash"] = true
	var off: Dictionary = FIELD.duplicate()
	off["dash"] = false
	# the top speed, by the gap
	var tops: Array = []
	for gap in [300.0, 1500.0, 6000.0, 14000.0]:
		var S := _dashAt(on, gap, 1.0, 0.0)
		tops.append(SimFighter.flightSpeed(S, S.fighters[0], true))
		SimCore.dispose(S)
	var S0 := _dashAt(off, 300.0, 1.0, 0.0)
	var closeOff: float = SimFighter.flightSpeed(S0, S0.fighters[0], true)
	SimCore.dispose(S0)
	ok(near(tops[0], 5000.0, 25.0) and tops[0] == tops[1] and tops[1] == tops[2] and tops[2] == tops[3], "the dash at 300, 1,500, 6,000 and 14,000 apart: %.0f, %.0f, %.0f, %.0f, his level's flat out" % tops)
	ok(closeOff < 1500.0, "off: the close dash as it was at 300 apart (%.0f)" % closeOff)
	var SM := _dashAt(on, 300.0, 4.0, 100.0)
	var fm = SM.fighters[0]
	var topMax: float = SimFighter.flightSpeed(SM, fm, true)
	var wantMax: float = 5000.0 * SimDetMath.pow(2.305, SimPower.level(fm)) * fm.spd
	SimCore.dispose(SM)
	ok(near(topMax, wantMax, wantMax * 0.01) and topMax > 11000.0, "at the top, at 300 apart: %.0f (his level's flat out %.0f)" % [topMax, wantMax])
	# the response is the kick's (instant and climb, kick.json; the builds play with it on): the first tick, up close
	var onK: Dictionary = on.duplicate()
	onK["kick"] = true
	var offK: Dictionary = off.duplicate()
	offK["kick"] = true
	var SR := _dashAt(onK, 1000.0, 1.0, 0.0)
	var rr: Array = _dashRun(SR, 12)
	SimCore.dispose(SR)
	var S2 := _dashAt(offK, 1000.0, 1.0, 0.0)
	var r2: Array = _dashRun(S2, 12)
	SimCore.dispose(S2)
	ok(rr[1].size() > 0 and rr[1][0] >= 1000.0, "with the kick, 1,000 apart: %.0f on the first tick (off: %.0f)" % [rr[1][0] if rr[1].size() > 0 else -1.0, r2[1][0] if r2[1].size() > 0 else -1.0])
	# Game Design's close times, the other standing still: asserted with the kick on, as the builds play; printed with it off
	for row in [[1000.0, 1.0, 0.0, 0.4], [3000.0, 1.0, 0.0, 0.8], [6000.0, 1.0, 0.0, 1.4], [6000.0, 4.0, 100.0, 0.75]]:
		var got: Array = []
		for su in [onK, offK, on, off]:
			var SC := _dashAt(su, row[0], row[1], row[2])
			got.append(_dashRun(SC, 600)[0])
			SimCore.dispose(SC)
		var sec: float = float(got[0]) / 60.0
		print("dash close from %.0f at tier %d, in ticks: %d with the dash and the kick (%.2f s, target %.2f s); %d the kick alone; %d the dash alone; %d neither" % [row[0], int(row[1]), got[0], sec, row[3], got[1], got[2], got[3]])
		ok(got[0] > 0 and sec <= row[3], "close from %.0f at tier %d in %.2f s with the kick (at most %.2f)" % [row[0], int(row[1]), sec, row[3]])
	# off moves nothing, and on is in the hash
	var A := _new(off)
	var B := _new(FIELD)
	ok(str(SimHash.stateHash(A).gameplay) == str(SimHash.stateHash(B).gameplay), "off by its setup, the same hash as with no word")
	var C := _new(on)
	ok(str(SimHash.stateHash(C).gameplay) != str(SimHash.stateHash(B).gameplay), "the dash is in the hash")
	SimCore.dispose(A)
	SimCore.dispose(B)
	SimCore.dispose(C)
	var D := _new({"intro": false, "planet": 7, "touch": 3, "planetGen": 3, "power": false, "dash": true})
	ok(not D.dashOn, "with the model off the word does nothing")
	SimCore.dispose(D)


## Each real route to a send, and the share it ends up with: through DirBrawl._send, the rally's turn, a chain link's own beat and a launch beat with the earned gate's multiplier. Reading a
## share from the table says nothing about who asks for which.
func _routes() -> void:
	var one := func(why: String, mul: float, extra: Dictionary, pow_: int, want: float) -> void:
		var S := _new(FIELD)
		var f = S.fighters[0]
		var o = S.fighters[1]
		f.y = 3000.0
		o.y = 3000.0
		var ex := SimState.Exchange.new()
		ex.A = f
		ex.D = o
		ex.tpl = DirBrawl.TPL
		ex.kind = "heavy"
		S.dirS.ex = ex
		DirBrawl._size(f)
		DirBrawl._size(o)
		DirBrawl._ls(f, DirBrawl.LA_POW, pow_)
		SimPower.lastShare = -1.0
		DirBrawl._send(S, ex, f, o, 0, why, mul, extra)
		ok(near(SimPower.lastShare, want, 0.001), "%s, power %d: share %.3f against %.3f" % [why, pow_, SimPower.lastShare, want])
		print("route: %s, power %d: share %.3f" % [why, pow_, SimPower.lastShare])
		S.dirS.ex = null
		SimCore.dispose(S)
	var flight: float = float(DirBrawl.cfg().launcher.flightMul)
	one.call("a heavy charged to full", 1.0, {}, 0, 1.0)
	one.call("the launcher", flight, {}, 0, 0.5)
	one.call("the launcher", flight, {}, 1000, 0.5)
	one.call("the launcher", flight, {}, 500, 0.375)
	one.call("the sell's send", flight, {"sold": true, "decisive": true}, 1000, 0.5)
	one.call("the turn", 1.0, {}, 0, 0.5)
	# a launch beat, by its template and from a chain link's own plan, whatever template it runs on
	for row in [["heavy_clash", "heavy", 1800.0, 0.5], ["guard_break", "heavy", 1700.0, 0.5], ["dodge", "light", 1400.0, 0.25], ["trade_blows", "light", 1000.0, 0.25], ["clean_hit_heavy", "heavy", 1500.0, 0.5]]:
		_beat(row[0], row[1], {"force": row[2], "forced": true, "why": "a route"}, row[2], row[3], "template")
	for tpl in ["pressure", "clean_hit", "heavy_clash", "dodge"]:
		var S := _new(FIELD)
		var ex := SimState.Exchange.new()
		ex.A = S.fighters[0]
		ex.D = S.fighters[1]
		ex.tpl = tpl
		ex.kind = "light"
		S.dirS.ex = ex
		DirData.planChain(ex, S.powerOn)
		var n: int = 0
		for b in ex.beats:
			if b.op == "launch":
				n += 1
				ok(String(b.args.get("share", "")) == "chainLink", "%s: a chain link's launch beat says chainLink" % tpl)
				var a2: Dictionary = b.args.duplicate()
				a2["forced"] = true   # past the earned gate, which is its own question
				a2["why"] = "a route"
				_beat(tpl, "light", a2, float(a2.force), 0.5, "chain link")
		ok(n > 0, "%s: a chain link has a launch beat (%d)" % [tpl, n])
		S.dirS.ex = null
		SimCore.dispose(S)
	# a style's small pop, with the earned gate's multiplier on the way
	_beat("clean_hit", "light", {"force": 700.0, "forced": true, "why": "a route"}, 700.0, 0.125, "small pop")
	var O := _new({"intro": false, "planet": 7, "touch": 3, "planetGen": 3, "power": false})   # off by its setup, whatever the data says
	var ex2 := SimState.Exchange.new()
	ex2.A = O.fighters[0]
	ex2.D = O.fighters[1]
	ex2.tpl = "pressure"
	DirData.planChain(ex2, O.powerOn)
	for b in ex2.beats:
		ok(b.op != "launch" or not b.args.has("share"), "off: a chain's beat is what it was")
	SimCore.dispose(O)


func _beat(tpl: String, kind: String, args: Dictionary, force: float, want: float, what: String) -> void:
	var S := _new(FIELD)
	var f = S.fighters[0]
	var o = S.fighters[1]
	f.y = 3000.0
	o.y = 3000.0
	var ex := SimState.Exchange.new()
	ex.A = f
	ex.D = o
	ex.tpl = tpl
	ex.kind = kind
	S.dirS.ex = ex
	SimPower.lastShare = -1.0
	DirMelee.launchBeat(S, ex, f, o, force, false, args)
	ok(near(SimPower.lastShare, want, 0.001), "%s %s: share %.3f against %.3f" % [what, tpl, SimPower.lastShare, want])
	print("route: %s %s: share %.3f, speed %.0f" % [what, tpl, SimPower.lastShare, sqrt(o.vx / maxf(o.launchT, 0.001) * o.vx / maxf(o.launchT, 0.001) + o.vy * o.vy)])
	S.dirS.ex = null
	SimCore.dispose(S)


## Sends aimed at a building: planned by WorldBrunt.aim, flown by doLaunch, counted against the hit. An aim that flies a different flight misses.
func _aimed() -> void:
	for tier in [1, 4]:
		var su: Dictionary = FIELD.duplicate()
		if tier > 1:
			su["startTier"] = tier
		var S := _new(su)
		var a = S.fighters[0]
		var d = S.fighters[1]
		var V: float = SimPower.speed(a, 1.0)
		var aimed: int = 0
		var hits: int = 0
		var i: int = 0
		while i < 200 and aimed < 24:
			# a real fight's place on the line: whatever WorldBrunt.candidates offers a body there
			d.x = SimWrap.wrap(a.x + float(i) * 773.0)
			i += 1
			d.y = WorldTerrain.groundY(S, d.x) + 200.0
			d.z = 0.0
			d.state = "free"
			d.vx = 0.0
			d.vy = 0.0
			a.x = SimWrap.wrap(d.x - 150.0)
			a.y = d.y
			a.face = 1.0
			var cands: Array = WorldBrunt.candidates(S, d)
			if cands.is_empty():
				continue
			var b = S.buildings[cands[0]]
			var plan = WorldBrunt.aim(S, a, d, b, V, 1.0)
			if plan == null:
				continue
			aimed += 1
			DirLaunch.doLaunch(S, a, d, plan, V)
			var hit: bool = false
			var n: int = 0
			while d.state == "launched" and n < 300:
				SimCore.step(S)
				for e in S.out.fx:
					if e.type == "building_hit":
						hit = true
				S.out.fx.clear()
				S.out.feed.clear()
				n += 1
			if hit:
				hits += 1
			d.state = "free"
			d.launchBy = null
			d.hp = d.maxhp
			a.hp = a.maxhp
			S.game.ko = null
			S.dirS.ex = null
			S.dirS.stop = 0.0
		print("aimed tier %d: %d sends at a building, %d hit it" % [tier, aimed, hits])
		ok(aimed >= 8, "tier %d: there were sends to aim (%d)" % [tier, aimed])
		ok(hits * 10 >= aimed * 8, "tier %d: an aimed send flies its plan (%d of %d hit)" % [tier, hits, aimed])
		SimCore.dispose(S)


## A repeat launch: speed by fresh, as Game Design rules, on the plan and on the send. x0.9 a mark of that kind, x0.97 a mark of any, never under 0.7, for 60 s of fight, with the switch on.
func _fresh() -> void:
	var S := _new(FIELD)
	var f = S.fighters[0]
	var o = S.fighters[1]
	DirBrawl._size(f)
	DirBrawl._size(o)
	var across: Dictionary = {"name": "SMASH ACROSS", "ux": 1.0, "uy": 0.0}
	ok(DirBrawl.planFresh(S, o, across) == 1.0, "a first launch is whole")
	DirBrawl.markKind(S, o, 1)
	ok(near(DirBrawl.planFresh(S, o, across), 0.9 * 0.97, 1.0e-9), "one of that kind: %.4f" % DirBrawl.planFresh(S, o, across))
	ok(near(DirBrawl.planFresh(S, o, {"name": "UPPERCUT", "ux": 0.0, "uy": 1.0}), 0.97, 1.0e-9), "one of another kind: %.4f" % DirBrawl.planFresh(S, o, {"name": "UPPERCUT", "ux": 0.0, "uy": 1.0}))
	o.y = 3000.0
	var V: float = SimPower.speed(f, 1.0)
	DirLaunch.doLaunch(S, f, o, across, V)
	ok(near(absf(o.vx) / o.launchT, V * 0.9 * 0.97, 1.0), "the send flies it: %.0f against %.0f" % [absf(o.vx) / o.launchT, V * 0.9 * 0.97])
	o.state = "free"
	o.launchBy = null
	DirBrawl.markKind(S, o, 1)
	DirBrawl.markKind(S, o, 1)
	DirBrawl.markKind(S, o, 1)
	ok(near(DirBrawl.planFresh(S, o, across), 0.7, 1.0e-9), "never under 0.7: %.4f" % DirBrawl.planFresh(S, o, across))
	DirLaunch.doLaunch(S, f, o, {"name": "KNOCK BACK", "ux": 1.0, "uy": 0.0, "dist": 500.0}, 900.0)
	ok(near(absf(o.vx) / o.launchT, 900.0, 1.0e-6), "a knock's length is its own: %.1f" % (absf(o.vx) / o.launchT))
	o.state = "free"
	o.launchBy = null
	S.T += 61.0
	S.tick += 3660
	var late: float = DirBrawl.planFresh(S, o, across)
	print("fresh: after 60 s of fight, %.3f" % late)
	ok(late == 1.0, "after the window, whole again (%.3f)" % late)
	SimCore.dispose(S)
	var O := _new({"intro": false, "planet": 7, "touch": 3, "planetGen": 3, "power": false})   # off by its setup, whatever the data says
	DirBrawl.markKind(O, O.fighters[1], 1)
	ok(DirBrawl.planFresh(O, O.fighters[1], across) == 1.0 and DirBrawl.freshMarks(O, O.fighters[1], 1) == 0, "off: nothing")
	SimCore.dispose(O)


## The meteor is an authored curve, not a send by energy (Combat's table: "an authored curve, so it's only the crater's number"): DirArc.send sets his velocity from the curve's own shape. So its
## speed is the same with the switch on or off, and it isn't held to a share. This says what it is, so nobody reads it as a send past the cap.
func _meteor() -> void:
	var got: Array = []
	for su in [FIELD, {"intro": false, "planet": 7, "touch": 3, "planetGen": 3}]:
		var S := _new(su)
		var f = S.fighters[0]
		var o = S.fighters[1]
		f.tier = 4.0
		f.power = 100.0
		o.y = WorldTerrain.groundY(S, o.x) + 100.0
		var ex := SimState.Exchange.new()
		ex.A = f
		ex.D = o
		ex.tpl = DirBrawl.TPL
		S.dirS.ex = ex
		DirBrawl._size(f)
		DirBrawl._size(o)
		DirBrawl.markKind(S, o, 0)   # a repeat doesn't shorten a curve
		DirArc.send(S, f, o, 0, 1.0)
		S.dirS.ex = null
		var top: float = sqrt(o.vx * o.vx + o.vy * o.vy)
		var first: float = top
		var topX: float = absf(o.vx)
		var n: int = 0
		var x0: float = o.x
		var yTop: float = o.y
		while o.state == "launched" and n < 900:
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
			top = maxf(top, sqrt(o.vx * o.vx + o.vy * o.vy))
			topX = maxf(topX, absf(o.vx))
			yTop = maxf(yTop, o.y)
			n += 1
		got.append(top)
		print("meteor, %s: first tick %.0f, fastest %.0f, along the line %.0f; %.1f s, %.0f along, top %.0f up" % ["on" if S.powerOn else "off", first, top, topX, float(n) / 60.0, absf(SimWrap.sdx(x0, o.x)), yTop])
		SimCore.dispose(S)
	ok(got[0] == got[1], "the meteor's curve doesn't read the energy model (%.0f, %.0f)" % [got[0], got[1]])


## AI fights at each tier: every launched body against what he could spend.
func _sends(blind: bool = false) -> Array:
	SimPower.blind = 3.0 if blind else 1.0
	var worst: Array = [0.0, 0.0, 0.0, 0.0]
	var over: int = 0
	var glow: int = 0
	var seen: int = 0
	var farTop: Array = [0.0, 0.0, 0.0, 0.0]
	var shares: Dictionary = {}
	var trips: Array = [[], [], [], []]
	for tier in [1, 2, 3, 4]:
		for seed in [77, 5, 12345]:
			var su: Dictionary = FIELD.duplicate()
			if tier > 1:
				su["startTier"] = tier
			var S := _new(su, true, seed)
			var was: Array = ["", ""]
			var from: Array = [0.0, 0.0]
			for t in range(1800):
				SimCore.step(S)
				S.out.fx.clear()
				S.out.feed.clear()
				for k in range(2):
					var f = S.fighters[k]
					var o = S.fighters[1 - k]
					if f.state == "launched" and was[k] != "launched" and f.launchBy != null:
						var v: float = sqrt(f.vx / f.launchT * f.vx / f.launchT + f.vy * f.vy)
						seen += 1
						var sk: String = "%.3f" % SimPower.lastShare
						shares[sk] = int(shares.get(sk, 0)) + 1
						from[k] = f.x
						var by = f.launchBy
						worst[tier - 1] = maxf(worst[tier - 1], v)
						farTop[tier - 1] = maxf(farTop[tier - 1], absf(f.vx))
						if v > SimPower.speedUnit * sqrt(SimPower.energy(by)) * 1.02:
							over += 1
							print("  past it: tier %d power %.0f, %.0f against %.0f, %s, launchT %.2f" % [int(by.tier), by.power, v, SimPower.speedUnit * sqrt(SimPower.energy(by)), S.dirS.lastLaunch, f.launchT])
						if by.tier <= 2.0 and v >= 4500.0:
							glow += 1
					if f.state != "launched" and was[k] == "launched":
						trips[tier - 1].append(absf(SimWrap.sdx(from[k], f.x)))
					was[k] = f.state
				if S.game.ko != null:
					break
			SimCore.dispose(S)
	SimPower.blind = 1.0
	for q in range(4):
		var a: Array = trips[q]
		a.sort()
		print("trips tier %d: %d, median %.0f, longest %.0f" % [q + 1, a.size(), a[a.size() / 2] if a.size() > 0 else 0.0, a[a.size() - 1] if a.size() > 0 else 0.0])
	print("shares asked for last before a launch: %s" % str(shares))
	print("sends: %d launches; fastest at tiers 1 to 4: %.0f, %.0f, %.0f, %.0f; along the line %.0f, %.0f, %.0f, %.0f; %d past the cap, %d that glow at tier 2 or under" % [seen, worst[0], worst[1], worst[2], worst[3], farTop[0], farTop[1], farTop[2], farTop[3], over, glow])
	return [seen, over, glow]


## Two matches in turn, one on, one off: each is what it would be alone, as the factor is a static bound each step.
func _interleave() -> void:
	var off: Dictionary = FIELD.duplicate()
	off["power"] = false
	var run := func(su: Dictionary) -> String:
		var A := _new(su, true)
		for t in range(1500):
			SimCore.step(A)
			A.out.fx.clear()
			A.out.feed.clear()
		var h: String = str(SimHash.stateHash(A).gameplay)
		SimCore.dispose(A)
		return h
	var ha: String = run.call(FIELD)
	var hb: String = run.call(off)
	ok(ha != hb, "the switch changes the match")
	ok(ha == run.call(FIELD), "two runs one hash")
	var A := _new(FIELD, true)
	var B := _new(off, true)
	for t in range(1500):
		SimCore.step(A)
		A.out.fx.clear()
		A.out.feed.clear()
		SimCore.step(B)
		B.out.fx.clear()
		B.out.feed.clear()
	ok(str(SimHash.stateHash(A).gameplay) == ha, "on, stepped in turn with an off match")
	ok(str(SimHash.stateHash(B).gameplay) == hb, "off, stepped in turn with an on match")
	SimCore.dispose(A)
	SimCore.dispose(B)
	# a rollback across launches
	var S := _new(FIELD, true)
	var snap: NetSnapshot = null
	var hs: Array = []
	var launches: int = 0
	for t in range(1500):
		if t == 100:
			snap = NetSnapshot.take(S)
		if t == 800:
			_send(S)
		SimCore.step(S)
		for e in S.out.fx:
			if t >= 100 and e.type == "launch":
				launches += 1
		S.out.fx.clear()
		S.out.feed.clear()
		if t >= 100:
			hs.append("%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)])
	NetSnapshot.restore(S, snap)
	var bad: int = 0
	for t in range(hs.size()):
		if t == 700:
			_send(S)
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		if "%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)] != hs[t]:
			bad += 1
	print("rollback: %d ticks, %d launches, %d differ" % [hs.size(), launches, bad])
	ok(bad == 0 and launches > 0, "a rollback across launches (%d differ, %d launches)" % [bad, launches])
	SimCore.dispose(S)


## A launch at a set tick, as a test's way to have one in the window: the AI's are rare on a whole ring.
func _send(S: SimState) -> void:
	DirLaunch.doLaunch(S, S.fighters[0], S.fighters[1], {"name": "SMASH ACROSS", "ux": 1.0, "uy": 0.32}, SimPower.speed(S.fighters[0], 1.0))


func _init() -> void:
	WorldClimate.useGen(3)
	var neg: bool = false
	for a in OS.get_cmdline_user_args():
		if a == "--negative-control":
			neg = true
	if neg:
		var r: Array = _sends(true)
		ok(r[1] > 0, "a send past its cap is seen (%d)" % r[1])
		var f0: int = fails
		SimPower.blindTravel = true
		_travel()
		SimPower.blindTravel = false
		var seen: int = fails - f0
		fails = f0
		ok(seen > 0, "a setup's travel left unread is seen (%d)" % seen)
		var f1: int = fails
		SimPower.blindDash = true
		_dash()
		SimPower.blindDash = false
		var seenD: int = fails - f1
		fails = f1
		ok(seenD > 0, "the dash switch left unread is seen (%d)" % seenD)
		print("POWER negative control: %d check(s) failed" % fails)
		quit(1 if fails > 0 else 0)
		return
	_numbers()
	_routes()
	_aimed()
	_fresh()
	_meteor()
	_flight()
	_travel()
	_dash()
	var r2: Array = _sends()
	ok(r2[0] > 0, "there were launches")
	ok(r2[1] == 0, "no send past what he has (%d)" % r2[1])
	ok(r2[2] == 0, "the hard test: no send by a base or tier 2 fighter glows (%d)" % r2[2])
	_interleave()
	print("POWER: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
