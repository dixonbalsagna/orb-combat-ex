extends SceneTree
## The computer answers a visible hold during the hold (Game Design's rulings, docs/design/gauntlet-plan.md, 2026-11-21; DirBrawl._aiVsHold;
## ai.json levels.<level>.brawl.holdAnswer; interrupts.json grapple.throw.holdBreak). A player in a brawl with the computer, at Medium,
## holds B: a fist's heavy, winding and then charging. Rows:
##   - drawn, in reach: after its reaction time (never sooner) it grabs; the clinch starts one ahead, and the charge never lands
##   - the hold-break's throw: worth holdBreak.worthMul times a throw's worth (against the same staging with the rule absent), and no
##     noRegrab: he can be grabbed again at once; without the rule, noRegrab starts
##   - drawn, out of reach but close enough: it closes in on its stick and grabs before the charge's first flash
##   - drawn, too far to close in time: it waits, slips the release (no energy), the charge meets nothing, and it punishes
##   - drawn, no catch to be had (a lockout): the same slip and punish; with the dodge's cooldown running and no ki it still slips (the slip,
##     not the dodge-cancel); the third slip of one direction inside 3 s keeps its movement and loses its frames, and that charge lands
##   - Easy's window (420): two earlier holds 200 and 360 ticks back count 3 at Easy and 2 at Medium (300)
##   - in every drawn hold: it never guards and never gives ground
##   - repetition at Medium (holdAnswer {windowTicks 300, byCount [0, 0.4, 0.9]}, Game Design, 2026-11-22): a lone hold isn't answered (nor at
##     Easy, {300, [0, 0.3, 0.75]}); a
##     third hold in the window is answered (keyed, deterministic); holds older than the window don't count; the record counts real holds
##   - a tap isn't a visible hold: B let go before the reaction time is never noted, grabbed or dodged
##   - one draw a hold, keyed by its start: of 2,000 holds, each level's share (each count's, for a repetition level) within 3 points
##   - the exploit is closed: a charge-only pad (QA's charge pad, played by this script) doesn't win every Medium match on QA's planet
##     settings (it won 40 of 40 before the answer; X-06's A1 exit, gauntlet-plan.md section 10)
##   - negative control: holdAnswer 0, with the old answers (the catch share and giving ground) at 0: nothing answers, the charge reaches
##     its release at full
##   - the idle training dummy (Game Design, 2026-11-23; ai.json idleDummy): on the data as it ships, the reference fighter never
##     answers a hold: with the answer at 1.0 it doesn't note, grab, close in or slip, and the charge reaches its release at full; nor a
##     third hold in Medium's window; nor does it slip a release it can't reach; against another computer (Tools' AI pairings) the
##     reference fighter plays as the fighters do: the skip is the dummy against a player only
##   - nor does the idle dummy perfect-block a full charge (idleDummy.skips perfectVsHeavy): of 100 stagings at Medium, none of the charges
##     released at full, and every one lands unguarded; while a computer still does at its level's number (perfectVsHeavy, over its charges
##     released at full): the reference fighter as standard AI and RIVAL at Medium, RIVAL at Easy
## The computer in every other staging is the reference fighter as the dummy set to "standard AI": the staging empties
## idleDummy.roles for its run (opts.dummy keeps the data's).
##   godot --headless --path . --script res://sim/director/tools/hold_answer_check.gd
## Ends on the verdict line.

var fails: int = 0
const PAD_SEEDS: int = 6   # the charge-only pad's Medium matches: QA's seeds 1 to 6


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
	print(("ok    " if c else "FAIL  ") + what)


## One staging: the player presses B in reach of the computer and holds it `hold` ticks, then waits. opts: answer (the level's holdAnswer),
## gap (body heights past striking distance to put the computer at, two ticks into the hold; -1 leaves it), lock (a catch lockout on the
## computer), quiet (the old answers at 0), pummel (the level's grapple pummel share), noRule (grapple.throw.holdBreak absent), data (the
## level's holdAnswer as the data has it), byCount (a repetition holdAnswer, window 300, with these chances), warm (ticks before the press),
## ring (the player's earlier visible holds, so many live ticks before this one), cool (the computer's dodge cooldown running and no ki),
## slips (the computer's earlier slips of a release, so many ticks before the press, straight away), repeat ([holds, gap, length]: in place of one hold,
## so many holds of `length` ticks, each pressed once he is free (no stun, his line idle) at least `gap` ticks after the last), ticks
## (the staging's length, 260), dummy (the data's idleDummy as it ships: the idle dummy; else the roles are emptied for the run), seed (the
## match's, 11), cpu (the computer's fighter, REFERENCE).
func _run(hold: int, opts: Dictionary) -> Dictionary:
	SimInputData.load_and_apply()   # the pad's switches as main ships them (bNoBeam: B is the heavy)
	var sk = DirAI.skill().get("idleDummy", null)
	var keepRoles = sk.get("roles", null) if sk is Dictionary else null
	if sk is Dictionary and not bool(opts.get("dummy", false)):
		sk["roles"] = []   # the dummy set to standard AI
	var bl: Dictionary = DirAI.lv().get("brawl", {})
	var gr: Dictionary = bl.get("grapple", {})
	var tc: Dictionary = DirInterrupt.data().grapple.throw
	var keep: Dictionary = {"holdAnswer": bl.get("holdAnswer", null), "giveGround": bl.get("giveGround", null), "catch": gr.get("catch", null), "pummel": gr.get("pummel", null), "holdBreak": tc.get("holdBreak", null)}
	if opts.has("byCount"):
		bl["holdAnswer"] = {"windowTicks": 300, "byCount": opts.byCount}
	elif not bool(opts.get("data", false)):
		bl["holdAnswer"] = float(opts.get("answer", 1.0))
	if bool(opts.get("quiet", false)):
		bl["giveGround"] = 0.0
		gr["catch"] = 0.0
	if opts.has("pummel"):
		gr["pummel"] = float(opts.pummel)
	if bool(opts.get("noRule", false)):
		tc.erase("holdBreak")
	var S := SimCore.createSim()
	SimCore.newMatch(S, int(opts.get("seed", 11)), {"p1": false, "p2": true}, {"intro": false, "v2": [true, true], "slots": ["PROTAGONIST", String(opts.get("cpu", "REFERENCE"))]})
	var P = S.fighters[0]
	var C = S.fighters[1]
	var brain = C.ai
	C.ai = null
	for f in S.fighters:
		f.hp = 100000.0
		f.ki = 100.0
	C.x = SimWrap.wrap(P.x + 58.0)
	C.y = P.y
	for _t in range(int(opts.get("warm", 5))):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
	S.out.fx.clear()
	S.out.feed.clear()
	C.ai = brain
	var ring: Array = opts.get("ring", [])
	for k in range(ring.size()):
		DirBrawl._hvS(P, k, DirBrawl._now(S) + 1 - int(ring[k]) + 1)   # his earlier visible holds, newest first (live tick plus 1)
	var sl: Array = opts.get("slips", [])
	for k in range(sl.size()):
		DirBrawl._hvS(C, DirBrawl.HV_N + k, (S.tick - int(sl[k]) + 1) * 8 + 1)   # its earlier slips, newest first
	var rep: Array = opts.get("repeat", [])
	var pressAt: int = -1
	var pressN: int = 0
	var react: int = int(DirAI.skill().get("reactTicks", 14))
	var r := {"oh": 0, "catchLive": -1, "clinch": false, "lead": 0, "release": -1, "relCharge": -1.0, "landed": false, "miss": "", "punish": false,
		"closed": -1, "gapReact": -1.0, "guarded": false, "gave": false, "dodge": -1, "kiPaid": 0.0, "thrown": "", "throwDmg": 0.0, "noGrabAfter": 0, "react": react, "counts": {}, "count": 0, "noted": false, "draw": -1.0, "slipText": "", "perfect": 0}
	for t in range(int(opts.get("ticks", 260))):
		if bool(opts.get("cool", false)) and t == 1:
			C.act.dodgeCool = 100000
			C.ki = 0.0
		if bool(opts.get("lock", false)) and t == 1:
			DirGrapple._s(C, DirGrapple.LOCK, S.tick + 100000)
		if float(opts.get("gap", -1.0)) >= 0.0 and t == 2:
			var side: float = 1.0 if SimWrap.sdx(P.x, C.x) >= 0.0 else -1.0
			C.x = SimWrap.wrap(P.x + side * (float(DirData.contact().offset) + float(opts.gap) * DirInterrupt.BH))
		var i := SimIntent.new()
		if rep.is_empty():
			i.sig = t == 0
			i.sigHeld = t < hold
		elif pressN < int(rep[0]) and (pressAt < 0 or t >= pressAt + int(rep[1])) and P.stunTicks <= 0 and DirBrawl._g(P, DirBrawl.LINE) == 0:
			pressAt = t
			pressN += 1
			i.sig = true
			i.sigHeld = true
		elif pressAt >= 0 and t < pressAt + int(rep[2]):
			i.sigHeld = true
		var kiWas: float = C.ki
		SimCore.step(S, [i, null])
		if r.oh == 0 and DirBrawl._g(P, DirBrawl.HOLD_AT) > 0:
			r.oh = DirBrawl._g(P, DirBrawl.HOLD_AT)
			r.draw = SimRng.keyed(int(S.game.seed), "brawl.holdAnswer", int(r.oh) * 2 + 1)
		var cur: int = DirBrawl._g(P, DirBrawl.HOLD_AT)
		if cur > 0 and DirBrawl._hvG(P, 0) == cur + 1 and not r.counts.has(cur):
			var haq = bl.get("holdAnswer", 0.0)
			r.counts[cur] = DirBrawl.holdsInWindow(P, cur, int(haq.get("windowTicks", 300)) if haq is Dictionary else 300)   # the level's own window
			if cur == int(r.oh):
				r.count = int(r.counts[cur])
				r.noted = true
		var since: int = DirBrawl._now(S) - int(r.oh)
		var holding: bool = int(r.oh) > 0 and r.release < 0 and not bool(r.clinch) and since >= react
		if holding:
			if int(r.gapReact) < 0 and since == react:
				r.gapReact = maxf(0.0, DirBands.dist(P, C) - float(DirData.contact().offset)) / DirInterrupt.BH
			if C.input != null and C.input.guard:
				r.guarded = true
			if DirBrawl._g(C, DirBrawl.AI_GIVE) == 1:
				r.gave = true
			if r.closed < 0 and DirBrawl._g(C, DirBrawl.AI_GIVE) == 2:
				r.closed = since
		var throwTick: bool = false
		for e in S.out.fx:
			if e.type == "cue" and String(e.kind) == "grapple_end" and int(e.actor) == 1 and r.thrown == "":
				throwTick = true
		if throwTick:
			for e in S.out.fx:
				if e.type == "damage" and int(e.attacker) == 1 and int(e.victim) == 0:
					r.throwDmg = float(e.amount)   # the throw's own blow: it lands on the tick of its grapple_end cue, before it
					break
		for e in S.out.fx:
			if e.type != "cue":
				if e.type == "damage" and int(e.attacker) == 0 and int(e.victim) == 1 and String(e.kind) != "guard" and r.release >= 0:
					r.landed = true
				elif e.type == "damage" and int(e.attacker) == 1 and int(e.victim) == 0:
					if r.miss != "":
						r.punish = true
				continue
			var k: String = String(e.kind)
			if k == "grapple_catch" and String(e.text) == "tell" and int(e.actor) == 1 and r.catchLive < 0:
				r.catchLive = since
			elif k == "grapple_clinch" and String(e.text) == "start":
				r.clinch = true
				r.lead = int(e.k) if int(e.actor) == 1 else -int(e.k)
			elif k == "blow" and String(e.text) == "release" and int(e.actor) == 0 and r.release < 0:
				r.release = since
				r.relCharge = float(e.x)
			elif k == "miss" and int(e.actor) == 0 and r.miss == "":
				r.miss = String(e.text)
			elif k == "perfect_block" and int(e.actor) == 1:
				r.perfect = int(r.perfect) + 1
			elif k == "hold_dodge" and int(e.actor) == 1 and r.dodge < 0:
				r.dodge = since
				r.kiPaid = kiWas - C.ki
				r.slipText = String(e.text)
			elif k == "grapple_end" and int(e.actor) == 1 and r.thrown == "":
				r.thrown = String(e.text)
				r.noGrabAfter = DirGrapple._g(P, DirGrapple.NOGRAB) - S.tick
		S.out.fx.clear()
		S.out.feed.clear()
	SimCore.dispose(S)
	for k in ["holdAnswer", "giveGround"]:
		if keep[k] == null:
			bl.erase(k)
		else:
			bl[k] = keep[k]
	for k in ["catch", "pummel"]:
		if keep[k] != null:
			gr[k] = keep[k]
	if keep.holdBreak != null:
		tc["holdBreak"] = keep.holdBreak
	if keepRoles != null:
		sk["roles"] = keepRoles
	return r


## A charge-only pad against the computer at Medium: QA's charge pad (qa/godot/orbs_player.gd --mode=charge), played by this script through
## intents: its stick walks at the computer (past 110 units across, 40 up or down), it holds B 50 ticks, lets go and waits 40 to 60 (a
## generator seeded by the match). QA's planet settings (QA_PLANET gen=3;planets=7;touches=3;cols=4800;power=1;travel=1.5;level=medium),
## to a KO, a no-contest or the 900-second cap. Returns [the winner's slot, -1 a no-contest, -2 the cap; the ticks played].
func _padMatch(seed: int) -> Array:
	SimInputData.load_and_apply()
	var su := {"v2": [true, true], "assists": [[], []], "planet": 7, "touch": 3, "arena": {"cols": 4800}, "planetGen": 3, "intro": false, "power": true, "travel": 1.5, "aiLevel": "medium"}
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": true}, su)
	var P = S.fighters[0]
	var C = S.fighters[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var next: int = 20
	var until: int = -1
	var result: int = -2
	var koAt: int = -1
	for t in range(54000):
		var i := SimIntent.new()
		var dx: float = SimWrap.sdx(P.x, C.x)
		var dy: float = C.y - P.y
		i.mx = signf(dx) if absf(dx) > 110.0 else 0.0
		i.my = signf(dy) if absf(dy) > 40.0 else 0.0
		if until >= 0:
			if t >= until:
				until = -1
				next = t + rng.randi_range(40, 60)
			else:
				i.sigHeld = true
		elif t >= next:
			i.sig = true
			i.sigHeld = true
			until = t + 50
		SimCore.step(S, [i, null])
		S.out.fx.clear()
		S.out.feed.clear()
		if S.game.ko != null and koAt < 0:
			koAt = t
		if koAt >= 0 and S.game.koT > 3.0:
			result = 1 if S.game.ko == P else 0
			break
		if DirEnding.noContest(S):
			result = -1
			break
	var n: int = S.tick
	SimCore.dispose(S)
	return [result, n]


## n stagings of a charge held 60 ticks, one a seed (1 to n), counted over the charges released at full (a computer's own strike can cut
## one short): [those the computer perfect-blocked, those released at full, those that landed unguarded].
func _pbRate(n: int, opts: Dictionary) -> Array:
	var blocks: int = 0
	var full: int = 0
	var landed: int = 0
	for sd in range(1, n + 1):
		var o2: Dictionary = opts.duplicate()
		o2["seed"] = sd
		var r: Dictionary = _run(60, o2)
		if float(r.relCharge) < 1.0:
			continue
		full += 1
		if int(r.perfect) > 0:
			blocks += 1
		if bool(r.landed):
			landed += 1
	return [blocks, full, landed]


func _line(what: String, r: Dictionary) -> void:
	print("      %s: hold from live tick %d (gap %.2f bh at +%d); closes in from +%d; catch at +%d, clinch %s (lead %d); release at +%d (charge %.2f); dodge at +%d (ki %.0f); miss %s, punished %s, landed %s; guarded %s, gave ground %s; thrown %s (damage %.1f, noRegrab left %d)" % [what, int(r.oh), float(r.gapReact), int(r.react), int(r.closed), int(r.catchLive), str(r.clinch), int(r.lead), int(r.release), float(r.relCharge), int(r.dodge), float(r.kiPaid), r.miss if r.miss != "" else "none", str(r.punish), str(r.landed), str(r.guarded), str(r.gave), r.thrown if r.thrown != "" else "no", float(r.throwDmg), int(r.noGrabAfter)])


func _init() -> void:
	DirAI.level = "medium"
	var first: int = int(DirInterrupt.data().brawl.heavy.charge.fromTicks)
	var dc: Dictionary = DirInterrupt.data().dodgeCancel
	var a: Dictionary = _run(60, {})
	_line("drawn, in reach", a)
	ok(int(a.catchLive) >= int(a.react), "drawn, in reach: it grabs after its reaction time, never sooner (+%d against %d)" % [int(a.catchLive), int(a.react)])
	ok(bool(a.clinch) and int(a.lead) > 0 and not bool(a.landed) and int(a.release) < 0, "... the clinch starts one ahead (a grab beats the armour) and the charge never lands")
	var hb: Dictionary = _run(60, {"pummel": 1.0})
	var pl: Dictionary = _run(60, {"pummel": 1.0, "noRule": true})
	_line("the hold-break's throw", hb)
	_line("the same, holdBreak absent", pl)
	var mul: float = float(DirInterrupt.data().grapple.throw.get("holdBreak", {}).get("worthMul", 1.0))
	var ratio: float = float(hb.throwDmg) / float(pl.throwDmg) if float(pl.throwDmg) > 0.0 else 0.0
	ok(hb.thrown != "" and pl.thrown != "" and absf(ratio - mul) <= 0.02 * mul, "the hold-break's throw is worth %.2f times the throw (%.1f against %.1f; holdBreak.worthMul %.2f)" % [ratio, float(hb.throwDmg), float(pl.throwDmg), mul])
	ok(int(hb.noGrabAfter) <= 0 and int(pl.noGrabAfter) > 0, "... and leaves no noRegrab (%d ticks left; without the rule, %d)" % [int(hb.noGrabAfter), int(pl.noGrabAfter)])
	var c: Dictionary = _run(60, {"gap": 1.2})
	_line("drawn, 1.2 bh out", c)
	ok(int(c.closed) >= int(c.react) and int(c.catchLive) >= 0 and int(c.catchLive) <= first and bool(c.clinch) and not bool(c.landed), "drawn, out of reach but close enough: it closes in (+%d) and grabs before the first flash (+%d, the flash at +%d)" % [int(c.closed), int(c.catchLive), first])
	var d: Dictionary = _run(50, {"gap": 2.3})
	_line("drawn, 2.3 bh out", d)
	ok(int(d.closed) < 0 and int(d.catchLive) < 0 and int(d.dodge) >= 0 and int(d.dodge) <= int(d.release) + 12 and d.slipText == "slip" and absf(float(d.kiPaid)) < 0.5, "drawn, too far to close in time: it doesn't close in or grab; it slips the release (+%d, the release at +%d) at no energy (%.1f)" % [int(d.dodge), int(d.release), float(d.kiPaid)])
	ok(d.miss == "dodged" and not bool(d.landed) and bool(d.punish), "... the charge meets nothing (the miss cue says %s) and the computer punishes him while he is open" % (d.miss if d.miss != "" else "nothing"))
	var e: Dictionary = _run(50, {"lock": true})
	_line("drawn, a lockout", e)
	ok(int(e.catchLive) < 0 and int(e.dodge) >= 0 and e.miss == "dodged" and not bool(e.landed) and bool(e.punish), "drawn, no catch to be had (a lockout): the same slip, miss and punish")
	var cool: Dictionary = _run(50, {"lock": true, "cool": true})
	_line("drawn, a lockout, the dodge's cooldown running and no ki", cool)
	ok(int(cool.dodge) >= 0 and cool.slipText == "slip" and cool.miss == "dodged" and not bool(cool.landed), "... with the dodge's cooldown running and no ki it still slips, and the charge meets nothing: the slip, never refused by the dodge-cancel's cooldown")
	var slip3: Dictionary = _run(50, {"lock": true, "warm": 200, "slips": [20, 60]})
	_line("drawn, a lockout, two slips of the same way just before", slip3)
	ok(int(slip3.dodge) >= 0 and slip3.slipText == "slip_no_frames" and slip3.miss != "dodged", "... the third slip of one direction inside 3 s keeps its movement and loses its frames: the charge isn't made to miss (the slip's rule, R34)")
	ok(not bool(a.guarded) and not bool(a.gave) and not bool(c.guarded) and not bool(c.gave) and not bool(d.guarded) and not bool(d.gave) and not bool(e.guarded) and not bool(e.gave), "in every drawn hold it never guards and never gives ground")
	var lone: Dictionary = _run(60, {"data": true, "quiet": true})
	_line("Medium's data, a lone hold", lone)
	ok(int(lone.count) == 1 and int(lone.catchLive) < 0 and int(lone.dodge) < 0 and int(lone.closed) < 0 and float(lone.relCharge) >= 1.0, "repetition at Medium: a lone hold isn't answered (its count %d, byCount's first entry), and the charge reaches its release at full" % int(lone.count))
	DirAI.level = "easy"
	var loneE: Dictionary = _run(60, {"data": true, "quiet": true})
	DirAI.level = "medium"
	_line("Easy's data, a lone hold", loneE)
	ok(int(loneE.count) == 1 and int(loneE.catchLive) < 0 and int(loneE.dodge) < 0 and int(loneE.closed) < 0 and float(loneE.relCharge) >= 1.0, "... a lone hold isn't answered at Easy either (its count %d, byCount's first entry)" % int(loneE.count))
	var third: Dictionary = _run(60, {"data": true, "warm": 400, "ring": [100, 220]})
	_line("Medium's data, a third hold in the window", third)
	ok(int(third.count) == 3 and (int(third.catchLive) >= 0 or int(third.dodge) >= 0), "... a third hold in the window (two before it, 100 and 220 ticks earlier) is answered: its count %d, chance 0.9, its keyed draw %.3f" % [int(third.count), float(third.draw)])
	var older: Dictionary = _run(60, {"data": true, "quiet": true, "warm": 400, "ring": [320, 380]})
	DirAI.level = "easy"
	var winE: Dictionary = _run(60, {"data": true, "quiet": true, "warm": 500, "ring": [200, 360]})
	DirAI.level = "medium"
	var winM: Dictionary = _run(60, {"data": true, "quiet": true, "warm": 500, "ring": [200, 360]})
	ok(int(winE.count) == 3 and int(winM.count) == 2, "Easy's window (420): two earlier holds 200 and 360 ticks back count %d at Easy, and %d at Medium (300)" % [int(winE.count), int(winM.count)])
	ok(int(older.count) == 1 and int(older.catchLive) < 0 and int(older.dodge) < 0, "... holds older than the window don't count: two 320 and 380 ticks earlier leave a count of %d, unanswered" % int(older.count))
	var org: Dictionary = _run(0, {"byCount": [0, 0, 0], "quiet": true, "repeat": [3, 60, 24], "ticks": 420})
	var cs: Array = org.counts.values()
	ok(cs == [1, 2, 3], "... the record counts real holds: three visible holds, each 60 ticks or more after the last, count %s (their starts %s)" % [str(cs), str(org.counts.keys())])
	var tap: Dictionary = _run(3, {"answer": 1.0, "quiet": true})
	_line("a tap", tap)
	ok(not bool(tap.noted) and int(tap.dodge) < 0 and int(tap.catchLive) < 0 and tap.miss != "dodged", "a tap isn't a visible hold: B let go at 3 ticks is never noted, grabbed or dodged (the answer at 1.0)")
	var seed: int = 11
	var shares: Array = []
	var good: bool = true
	for lvl in ["easy", "medium", "hard"]:
		var ha = DirAI.skill().levels[lvl].get("brawl", {}).get("holdAnswer", 0.0)
		var wants: Array = ha.byCount if ha is Dictionary else [float(ha)]
		var got: Array = []
		for want in wants:
			var n: int = 0
			for oh in range(1, 2001):
				if SimRng.keyed(seed, "brawl.holdAnswer", oh * 2 + 1) < float(want):
					n += 1
			got.append("%.3f (data %.2f)" % [float(n) / 2000.0, float(want)])
			good = good and absf(float(n) / 2000.0 - float(want)) <= 0.03
		good = good and (ha is Dictionary or float(ha) > 0.0)
		shares.append("%s %s" % [lvl, ", ".join(got) if wants.size() == 1 else "by count [" + ", ".join(got) + "]"])
	ok(good, "one draw a hold, keyed by its start: of 2,000 holds, %s" % ", ".join(shares))
	var pads: Array = []
	var padWins: int = 0
	var cpuWins: int = 0
	for sd in range(1, PAD_SEEDS + 1):
		var m: Array = _padMatch(sd)
		pads.append("%d: %s in %d ticks" % [sd, "the pad" if int(m[0]) == 0 else ("the computer" if int(m[0]) == 1 else ("no contest" if int(m[0]) == -1 else "the cap")), int(m[1])])
		if int(m[0]) == 0:
			padWins += 1
		elif int(m[0]) == 1:
			cpuWins += 1
	print("      the charge-only pad at Medium (holdAnswer %s), seeds 1 to %d: %s" % [JSON.stringify(DirAI.skill().levels.medium.brawl.get("holdAnswer", 0.0)), PAD_SEEDS, "; ".join(pads)])
	ok(cpuWins >= 1 and padWins < PAD_SEEDS, "the exploit is closed: the charge-only pad doesn't win every Medium match (the pad %d, the computer %d, of %d)" % [padWins, cpuWins, PAD_SEEDS])
	var z: Dictionary = _run(60, {"answer": 0.0, "quiet": true})
	_line("negative control", z)
	ok(int(z.catchLive) < 0 and int(z.dodge) < 0 and int(z.closed) < 0 and float(z.relCharge) >= 1.0, "negative control: holdAnswer 0 and the old answers at 0: nothing answers the hold, and the charge reaches its release at full")
	var skr = DirAI.skill().get("idleDummy", {})
	var roles: Array = skr.get("roles", []) if skr is Dictionary else []
	var dm: Dictionary = _run(60, {"answer": 1.0, "quiet": true, "dummy": true})
	_line("the idle dummy, the answer at 1.0", dm)
	ok(roles.has("reference") and int(dm.oh) > 0 and not bool(dm.noted) and int(dm.catchLive) < 0 and int(dm.dodge) < 0 and int(dm.closed) < 0 and float(dm.relCharge) >= 1.0, "the idle training dummy never answers a hold (ai.json idleDummy.roles %s): with the answer at 1.0 it doesn't note, grab, close in or slip, and the charge reaches its release at full (%.2f)" % [str(roles), float(dm.relCharge)])
	var dm3: Dictionary = _run(60, {"data": true, "quiet": true, "warm": 400, "ring": [100, 220], "dummy": true})
	_line("the idle dummy, Medium's data, a third hold in the window", dm3)
	ok(not bool(dm3.noted) and int(dm3.count) == 0 and int(dm3.catchLive) < 0 and int(dm3.dodge) < 0 and int(dm3.closed) < 0 and float(dm3.relCharge) >= 1.0, "... nor a third hold in Medium's window (the standard AI answers it at 0.9, the row above): never counted, the charge at full (%.2f)" % float(dm3.relCharge))
	var dmS: Dictionary = _run(50, {"answer": 1.0, "quiet": true, "gap": 2.3, "dummy": true})
	_line("the idle dummy, 2.3 bh out, the answer at 1.0", dmS)
	ok(int(dmS.release) >= 0 and int(dmS.dodge) < 0 and dmS.miss != "dodged", "... nor does it slip a release it can't reach (2.3 bh out): the charge isn't made to miss (the miss cue says %s)" % (dmS.miss if dmS.miss != "" else "nothing"))
	var Sv := SimCore.createSim()
	SimCore.newMatch(Sv, 11, {"p1": true, "p2": true}, {"intro": false, "v2": [true, true], "slots": ["PROTAGONIST", "REFERENCE"]})
	var vsCpu: bool = DirBrawl.idleDummy(Sv.fighters[1], Sv.fighters[0], "holdAnswer") or DirBrawl.idleDummy(Sv.fighters[1], Sv.fighters[0], "perfectVsHeavy")
	var brainP = Sv.fighters[0].ai
	Sv.fighters[0].ai = null
	var vsPlayer: bool = DirBrawl.idleDummy(Sv.fighters[1], Sv.fighters[0], "holdAnswer") and DirBrawl.idleDummy(Sv.fighters[1], Sv.fighters[0], "perfectVsHeavy")
	Sv.fighters[0].ai = brainP
	SimCore.dispose(Sv)
	ok(brainP != null and not vsCpu and vsPlayer, "... the skip is the dummy against a player only: against another computer (Tools' AI pairings) the reference fighter answers as the fighters do (skips against a computer %s, against a player %s)" % [str(vsCpu), str(vsPlayer)])
	var pbN: int = 100
	var pbD: Array = _pbRate(pbN, {"answer": 0.0, "quiet": true, "dummy": true})
	var pbS: Array = _pbRate(pbN, {"answer": 0.0, "quiet": true})
	var pbR: Array = _pbRate(pbN, {"answer": 0.0, "quiet": true, "cpu": "RIVAL"})
	DirAI.level = "easy"
	var pbE: Array = _pbRate(pbN, {"answer": 0.0, "quiet": true, "cpu": "RIVAL"})
	var pvhE: float = float(DirAI.lv().get("brawl", {}).get("perfectVsHeavy", 0.0))
	DirAI.level = "medium"
	var pvh: float = float(DirAI.lv().get("brawl", {}).get("perfectVsHeavy", 0.0))
	print("      %d stagings of B held 60 ticks (holdAnswer 0, the old answers 0; seeds 1 to %d), perfect blocks of the charges released at full: the idle dummy %d of %d (%d landed unguarded); the reference fighter as standard AI %d of %d (%d landed); RIVAL %d of %d (%d landed) at Medium (perfectVsHeavy %.2f); RIVAL %d of %d (%d landed) at Easy (%.2f)" % [pbN, pbN, pbD[0], pbD[1], pbD[2], pbS[0], pbS[1], pbS[2], pbR[0], pbR[1], pbR[2], pvh, pbE[0], pbE[1], pbE[2], pvhE])
	ok(roles.has("reference") and int(pbD[1]) >= pbN / 2 and int(pbD[0]) == 0 and int(pbD[2]) == int(pbD[1]), "the idle training dummy never perfect-blocks a full charge (idleDummy.skips perfectVsHeavy): 0 of %d at Medium, and every one landed unguarded (%d)" % [int(pbD[1]), int(pbD[2])])
	ok(pvh > 0.0 and int(pbS[1]) >= pbN / 2 and int(pbR[1]) >= pbN / 2 and absf(float(pbS[0]) / float(pbS[1]) - pvh) <= 0.1 and absf(float(pbR[0]) / float(pbR[1]) - pvh) <= 0.1, "... while a computer still perfect-blocks it at its level's number (Medium perfectVsHeavy %.2f): the reference fighter as standard AI %d of %d, RIVAL %d of %d" % [pvh, int(pbS[0]), int(pbS[1]), int(pbR[0]), int(pbR[1])])
	ok(pvhE > 0.0 and int(pbE[1]) >= pbN / 2 and absf(float(pbE[0]) / float(pbE[1]) - pvhE) <= 0.06, "... and at Easy's (%.2f): RIVAL %d of %d" % [pvhE, int(pbE[0]), int(pbE[1])])
	DirAI.level = ""
	print("HOLD ANSWER: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
