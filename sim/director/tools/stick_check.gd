extends SceneTree
## The stick's strike against the rulings (docs/design/right-hand-attacks-rulings.md section 2), by scripted second words on an
## idle dummy: the quick strike, the charge, the guard, bareness, one stun a string, the third repeat, the cancel, the lunge.
##   godot --headless --path . --script res://sim/director/tools/stick_check.gd
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	DirStick.setForce(1)
	DirStick.setArmourForce(0)
	_quick()
	_charged()
	_guarded()
	var ls: bool = DirStick.lightStops()
	DirStick.cfg()["lightStops"] = true
	_bare()
	DirStick.cfg()["lightStops"] = ls
	_oneStun()
	_repeat()
	_cancel()
	_lunge()
	_releasedEarly()
	_noStray()
	_pools()
	_downed()
	_lateReturn()
	_levelThreeHolds()
	_directions()
	_refused()
	_stops()
	_lightsLand()
	_levelThreeAll()
	DirStick.setArmourForce(1)
	_armour()
	DirStick.setArmourForce(-1)
	DirStick.setForce(-1)
	print("STICK: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## Two idle fighters in reach, in a brawl opened by a light.
func _pair() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.ki = 100.0
		f.hp = 100000.0 if "hp" in f else 0.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 58.0)
	S.fighters[1].y = S.fighters[0].y
	for _k in range(5):
		_step(S)
	_step(S, _light())
	for _k in range(30):
		_step(S)
	return S


func _light() -> SimIntent:
	var a := SimIntent.new()
	a.light = true
	return a


## One tick; a is the first fighter's intent, b the second's.
func _step(S: SimState, a: SimIntent = null, b: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), b if b != null else SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue" and e.kind == "stick_hit":
			_hits += 1
			_stun = int(e.n)
	S.out.fx.clear()
	S.out.feed.clear()
	if S.dirS.ex != null:
		for bt in S.dirS.ex.beats:
			if not bt.done and bt.op == "strike" and bt.args != null and bt.args.has("stick") and bt.args.has("piece"):
				_piece = String(bt.args.piece)


var _piece: String = ""
var _hits: int = 0
var _stun: int = -1


func _word(start: bool, release: bool, held: bool, dir: int, lvl: int, cancel: bool = false) -> SimIntent:
	var i := SimIntent.new()
	i.rsStart = start
	i.rsRelease = release
	i.rsHeld = held
	i.rsDir = dir
	i.rsLevel = lvl
	i.rsCancel = cancel
	return i


## A flick: request, back at rest 4 ticks later.
func _flick(S: SimState, dir: int) -> void:
	_step(S, _word(true, false, true, dir, 0))
	for _k in range(3):
		_step(S, _word(false, false, true, dir, 0))
	_step(S, _word(false, true, false, dir, 0))


func _quick() -> void:
	var S := _pair()
	_hits = 0
	_stun = -1
	var d = S.fighters[1]
	var hp0: float = d.hp
	_flick(S, SimStrikeRead.LEFT)
	var at: int = -1
	for k in range(14):
		_step(S)
		if _hits > 0 and at < 0:
			at = k + 5
	_expect(_hits == 1, "a flick lands one quick strike (%d)" % _hits)
	_expect(at == 7 or at == 8, "it lands 7 live ticks from the request (%d)" % at)
	_expect(_stun == 20, "its stun is 20 (%d)" % _stun)
	_expect(d.hp < hp0, "it does damage")
	_expect(d.state == "locked", "it never sends him (%s)" % d.state)
	SimCore.dispose(S)


func _charged() -> void:
	var S := _pair()
	_hits = 0
	_stun = -1
	var d = S.fighters[1]
	_step(S, _word(true, false, true, SimStrikeRead.LEFT, 0))
	var early: bool = false
	for k in range(52):
		_step(S, _word(false, false, true, SimStrikeRead.LEFT, 0 if k < 10 else (1 if k < 28 else 2)))
		early = early or _hits > 0
	_expect(not early, "a stick still out holds the blow back")
	_step(S, _word(false, true, false, SimStrikeRead.LEFT, 3))
	for _k in range(4):
		_step(S)
	_expect(_hits == 1, "the release lands it (%d)" % _hits)
	_expect(_stun == 40, "level 3's stun is 40 (%d)" % _stun)
	_expect(d.state == "locked", "level 3 stays in reach (%s)" % d.state)
	_expect(DirBrawl._g(S.fighters[0], DirBrawl.LC_UNTIL) > 0, "level 3 opens the send")
	SimCore.dispose(S)


func _guarded() -> void:
	var S := _pair()
	_hits = 0
	var g := SimIntent.new()
	g.guard = true
	g.stance = 1
	for _k in range(20):
		_step(S, null, g)
	_step(S, _word(true, false, true, SimStrikeRead.LEFT, 0), g)
	_step(S, _word(false, true, false, SimStrikeRead.LEFT, 0), g)
	for _k in range(16):
		_step(S, null, g)
	_expect(_hits == 0, "a guard blocks it, with no stun (%d)" % _hits)
	SimCore.dispose(S)


## Past the flick a hold has B's armour (power-scale.md section 2): a light takes 30% and it goes on, a medium stops it only before level 2,
## a heavy always, and the beam's hold is armoured too.
func _armour() -> void:
	var light := SimIntent.new()
	light.light = true
	var medium := SimIntent.new()
	medium.heavy = true
	var heavy := SimIntent.new()
	heavy.sig = true
	for row in [["light", light, 16, true], ["medium", medium, 2, false], ["medium", medium, 30, true], ["heavy", heavy, 14, false]]:
		var S := _pair()
		var A = S.fighters[0]
		_step(S, _word(true, false, true, SimStrikeRead.LEFT, 0))
		var hp: float = A.hp
		var lost: int = -1
		for k in range(60):
			_step(S, _word(false, false, true, SimStrikeRead.LEFT, 0), row[1] if k == int(row[2]) else null)
			if lost < 0 and DirStick._g(A, DirStick.ST_ON) != 2 and k > 8:
				lost = k
		print("      a %s pressed %d ticks into the hold: %s, he took %.1f" % [row[0], row[2], ("the charge was lost at %d" % lost) if lost >= 0 else "the charge goes on", hp - A.hp])
		_expect((lost < 0) == bool(row[3]), "a %s pressed %d ticks in: the charge %s" % [row[0], row[2], "goes on" if bool(row[3]) else "is lost"])
		if String(row[0]) == "light":
			_expect(hp - A.hp > 0.0 and hp - A.hp <= float(DirBrawl.cfg().light.damage) * 0.31, "... at 30%% of its damage (%.1f of %.1f)" % [hp - A.hp, float(DirBrawl.cfg().light.damage)])
		SimCore.dispose(S)
	# The beam's hold.
	var S2 := _pair()
	var A2 = S2.fighters[0]
	var w: SimIntent = _word(true, false, true, SimStrikeRead.LEFT, 0)
	w.rsMask = DirStick.RB
	w.stanceMask = DirStick.RB
	_step(S2, w)
	var hp2: float = A2.hp
	for k in range(40):
		var h: SimIntent = _word(false, false, true, SimStrikeRead.LEFT, 0)
		h.rsMask = DirStick.RB
		h.stanceMask = DirStick.RB
		_step(S2, h, light if k == 16 else null)
	print("      a light on a beam's hold: he took %.1f, stun %d, holding %s" % [hp2 - A2.hp, A2.stunTicks, str(DirStick._g(A2, DirStick.ST_ON) == 3)])
	_expect(DirStick._g(A2, DirStick.ST_ON) == 3 and hp2 - A2.hp <= float(DirBrawl.cfg().light.damage) * 0.31, "a light on a beam's hold: it goes on, at 30%")
	var rel: SimIntent = _word(false, true, false, SimStrikeRead.LEFT, 2)
	rel.rsMask = DirStick.RB
	rel.stanceMask = DirStick.RB
	_step(S2, rel)
	for _k in range(60):
		_step(S2)
	print("      let go in the brawl: exchange %s, beams %d, charge showing %s" % [S2.dirS.ex.kind if S2.dirS.ex != null else "none", S2.beams.size(), str(A2.beamCharge != null)])
	SimCore.dispose(S2)
	# A dodge makes it miss, and he's open.
	var S3 := _pair()
	var A3 = S3.fighters[0]
	S3.fighters[1].act.v2 = true
	_step(S3, _word(true, false, true, SimStrikeRead.LEFT, 0))
	for _k in range(18):
		_step(S3, _word(false, false, true, SimStrikeRead.LEFT, 0))
	var dg := SimIntent.new()
	dg.dodge = true
	dg.mx = 1.0   # the stick away: in a brawl a dodge leaves only so
	_hits = 0
	_step(S3, _word(false, false, true, SimStrikeRead.LEFT, 0), dg)
	for _k in range(3):
		_step(S3, _word(false, false, true, SimStrikeRead.LEFT, 0))
	var open: int = DirBrawl._g(A3, DirBrawl.OPEN_UNTIL) - DirBrawl._now(S3)
	print("      dodged: %d hits, charge %d, open %d more ticks, exchange %s" % [_hits, DirStick._g(A3, DirStick.ST_ON), open, str(S3.dirS.ex != null)])
	_expect(_hits == 0 and DirStick._g(A3, DirStick.ST_ON) == 0, "a dodge makes it miss")
	_expect(open >= int(DirStick.cfg().armour.missOpenTicks) - 6, "... and he's open for 0.33 s (%d)" % open)
	SimCore.dispose(S3)


func _bare() -> void:
	var S := _pair()
	_hits = 0
	_step(S, _word(true, false, true, SimStrikeRead.LEFT, 0))
	_step(S, _word(false, false, true, SimStrikeRead.LEFT, 0), _light())
	for _k in range(30):
		_step(S, _word(false, false, true, SimStrikeRead.LEFT, 0))
	_expect(_hits == 0, "a light ends its wind-up (%d)" % _hits)
	_expect(DirStick._g(S.fighters[0], DirStick.ST_ON) == 0, "and the charge is lost")
	SimCore.dispose(S)


func _oneStun() -> void:
	var S := _pair()
	_hits = 0
	_stun = -1
	_flick(S, SimStrikeRead.LEFT)
	for _k in range(14):
		_step(S)
	var first: int = _stun
	_flick(S, SimStrikeRead.UP)
	for _k in range(14):
		_step(S)
	_expect(first == 20 and _stun == 0 and _hits == 2, "one stun a string: the second still hits and stuns nothing (%d, %d, %d)" % [first, _stun, _hits])
	SimCore.dispose(S)


func _repeat() -> void:
	var S := _pair()
	_hits = 0
	var stuns: Array = []
	for _r in range(3):
		DirStick._s(S.fighters[1], DirStick.ST_STUN, 0)   # (one stun a string aside, each is read alone)
		_flick(S, SimStrikeRead.UP)
		for _k in range(14):
			_step(S)
		stuns.append(_stun)
	_expect(_hits == 3 and stuns[0] > 0 and stuns[1] > 0 and stuns[2] == 0, "the third of one direction inside 3 s hits and doesn't stun (%s)" % str(stuns))
	SimCore.dispose(S)


func _cancel() -> void:
	var S := _pair()
	_hits = 0
	_step(S, _word(true, false, true, SimStrikeRead.LEFT, 0))
	for _k in range(4):
		_step(S, _word(false, false, true, SimStrikeRead.LEFT, 0))
	_step(S, _word(false, false, false, SimStrikeRead.LEFT, 0, true))
	for _k in range(20):
		_step(S)
	_expect(_hits == 0, "a cancel throws nothing (%d)" % _hits)
	SimCore.dispose(S)


## Out of reach a request closes the gap at the lunge's price, and the blow it arrives with is the stick's.
func _lunge() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.ki = 100.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 900.0)
	S.fighters[1].y = S.fighters[0].y
	for _k in range(5):
		_step(S)
	_hits = 0
	_flick(S, SimStrikeRead.LEFT)
	for _k in range(120):
		_step(S)
		if _hits > 0:
			break
	_expect(_hits == 1, "from out of reach it closes, and lands as the stick's (%d)" % _hits)
	SimCore.dispose(S)


## A charge let go while its request is still closing the gap keeps its level: the edge is one tick, and the blow comes later.
func _releasedEarly() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.ki = 100.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 900.0)
	S.fighters[1].y = S.fighters[0].y
	for _k in range(5):
		_step(S)
	_hits = 0
	_stun = -1
	_step(S, _word(true, false, true, SimStrikeRead.LEFT, 0))
	_step(S, _word(false, true, false, SimStrikeRead.LEFT, 2))
	for _k in range(120):
		_step(S)
		if _hits > 0:
			break
	_expect(_hits == 1 and _stun == 32, "released before its blow, level 2 lands at level 2's stun (%d, %d)" % [_hits, _stun])
	SimCore.dispose(S)


## A stick out for 10 or 11 ticks and then let go is a quick strike with no charge cue, a tick or two late because he held it.
func _noStray() -> void:
	var S := _pair()
	_hits = 0
	_stun = -1
	var cues: int = 0
	_step(S, _word(true, false, true, SimStrikeRead.LEFT, 0))
	for k in range(11):
		SimCore.step(S, [_word(false, false, true, SimStrikeRead.LEFT, 0), SimIntent.new()])
		for e in S.out.fx:
			if e.type == "cue" and e.kind == "stick_charge":
				cues += 1
			if e.type == "cue" and e.kind == "stick_hit":
				_hits += 1
				_stun = int(e.n)
		S.out.fx.clear()
		S.out.feed.clear()
	_step(S, _word(false, true, false, SimStrikeRead.LEFT, 0))
	for _k in range(6):
		_step(S)
	_expect(cues == 0, "no charge cue before dwell (%d)" % cues)
	_expect(_hits == 1 and _stun == 20, "it lands as a quick (%d, %d)" % [_hits, _stun])
	SimCore.dispose(S)


## Combat's pools share out: a guard or travel list draws each piece, even one a medium's pool also has, and never repeats
## his last. Up has 3 of each for the Protagonist: 16 expected of 48, 9 is well under chance. A quick's one piece is its list's,
## and a charge's draw leaves the quick it replaced off his last two.
func _pools() -> void:
	for mask in [DirStick.LB, DirStick.LT]:
		var tally: Dictionary = {}
		var repeats: int = 0
		for sd in range(1, 4):
			var S := _pair()
			S.game.seed = sd
			var last: String = ""
			for _n in range(16):
				_piece = ""
				S.fighters[0].ki = 100.0
				S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 58.0)
				S.fighters[1].y = S.fighters[0].y
				var w := _word(true, false, true, SimStrikeRead.UP, 0)
				w.rsMask = mask
				_step(S, w)
				for _k in range(3):
					_step(S, _word(false, false, true, SimStrikeRead.UP, 0))
				_step(S, _word(false, true, false, SimStrikeRead.UP, 0))
				for _k in range(45):
					_step(S)
				tally[_piece] = int(tally.get(_piece, 0)) + 1
				repeats += 1 if _piece == last else 0
				last = _piece
			SimCore.dispose(S)
		var low: int = 48
		for k in tally:
			low = mini(low, int(tally[k]))
		var name: String = "guard" if mask == DirStick.LB else "travel"
		_expect(tally.size() == 3 and low >= 9, "a %s list shares out: %s" % [name, JSON.stringify(tally)])
		_expect(repeats == 0, "a %s piece never repeats his last (%d)" % [name, repeats])
	var S2 := _pair()
	_piece = ""
	_step(S2, _word(true, false, true, SimStrikeRead.UP, 0))
	for k in range(52):
		_step(S2, _word(false, false, true, SimStrikeRead.UP, 0 if k < 10 else (1 if k < 28 else 2)))
	var p1: int = S2.fighters[0].act.dirI[DirAlchemy.PIECE_2]
	_step(S2, _word(false, true, false, SimStrikeRead.UP, 3))
	_step(S2)
	var head: int = _piece.hash() & 0x7fffffff
	_expect(S2.fighters[0].act.dirI[DirAlchemy.PIECE_1] == head and S2.fighters[0].act.dirI[DirAlchemy.PIECE_2] == p1, "a charge's draw takes the quick's place in his last two (%s)" % _piece)
	SimCore.dispose(S2)


## RL-218 condition 3: the stick's pieces, the head-target ones among them, are thrown only in a brawl and land only on a foe
## locked in it. On a downed foe, every direction and level, in a brawl and out of one, none is thrown and no strike lands.
func _downed() -> void:
	var landed: int = 0
	var thrown: Dictionary = {}
	for inBrawl in [true, false]:
		for dir in [SimStrikeRead.UP, SimStrikeRead.DOWN, SimStrikeRead.LEFT, SimStrikeRead.LEFT]:
			for lvl in [0, 3]:
				var S: SimState
				if inBrawl:
					S = _pair()
				else:
					S = SimCore.createSim()
					SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"intro": false})
					for f in S.fighters:
						f.ai = null
						f.ki = 100.0
					S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 58.0)
					S.fighters[1].y = S.fighters[0].y
				var d = S.fighters[1]
				_hits = 0
				_piece = ""
				var script: Array = [_word(true, false, true, dir, 0)]
				for k in range(3 if lvl == 0 else 52):
					script.append(_word(false, false, true, dir, 0 if k < 10 else (1 if k < 28 else 2)))
				script.append(_word(false, true, false, dir, lvl))
				for _k in range(45):
					script.append(SimIntent.new())
				for w in script:
					d.state = "down"
					_step(S, w)
				landed += _hits
				if _piece != "":
					thrown[_piece] = int(thrown.get(_piece, 0)) + 1
				SimCore.dispose(S)
	_expect(thrown.is_empty(), "no stick piece is thrown at a downed foe: %s" % JSON.stringify(thrown))
	_expect(landed == 0, "no stick strike lands on one (%d)" % landed)


## The later of the wind-up's end and the stick's return: out past the wind-up and back before the dwell, a quick strike a tick after
## its return; still out at the dwell, a charge, with its cue only then.
func _lateReturn() -> void:
	var S := _pair()
	_hits = 0
	_stun = -1
	_step(S, _word(true, false, true, SimStrikeRead.LEFT, 0))
	var early: bool = false
	for _k in range(9):
		_step(S, _word(false, false, true, SimStrikeRead.LEFT, 0))
		early = early or _hits > 0
	_expect(not early, "out past the wind-up, the blow waits")
	_step(S, _word(false, true, false, SimStrikeRead.LEFT, 0))
	_step(S)
	_step(S)
	_expect(_hits == 1, "back before the dwell: it lands just after (%d)" % _hits)
	_expect(_stun == 20, "as a quick strike (%d)" % _stun)
	SimCore.dispose(S)


## Game Design's ruling: at both tier 4 the upward level 3 stays in reach and the brawl holds, and a B from it can land inside the stun.
func _levelThreeHolds() -> void:
	for dir in [SimStrikeRead.UP, SimStrikeRead.DOWN]:
		var S := _pair()
		S.fighters[0].tier = 4.0
		S.fighters[1].tier = 4.0
		_hits = 0
		var a = S.fighters[0]
		var d = S.fighters[1]
		_step(S, _word(true, false, true, dir, 0))
		for k in range(52):
			_step(S, _word(false, false, true, dir, 0 if k < 10 else (1 if k < 28 else 2)))
		_step(S, _word(false, true, false, dir, 3))
		var waited: int = 0
		while _hits == 0 and waited < 12:
			_step(S)
			waited += 1
		var held: int = 0
		var far: float = 0.0
		for _k in range(40):
			if S.dirS.ex != null and DirBrawl.isBrawl(S.dirS.ex):
				held += 1
			far = maxf(far, SimDetMath.hypot(SimWrap.sdx(a.x, d.x), a.y - d.y))
			_step(S)
		print("      direction %d: in the brawl for %d of the stun's 40 ticks, furthest apart %.0f" % [dir, held, far])
		_expect(held == 40, "direction %d, level 3: the brawl holds through the stun (%d of 40)" % [dir, held])
		_expect(far < 400.0, "direction %d, level 3: in reach (%.0f)" % [dir, far])
		SimCore.dispose(S)
	_ignition()


## The ignition route (rule-of-cool-map.md row 5): both at tier 4, level 3 upward, then B held to the flash as soon as his line is free. It lands inside the stun, and it's the meteor.
func _ignition() -> void:
	DirArc.setForce(1)
	var saved: int = int(DirArc.cfg().minForms)
	DirArc.cfg()["minForms"] = 0
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false, "startTier": 4})
	for f in S.fighters:
		f.ai = null
		f.hp = 100000.0
		f.ki = 100.0
	var a = S.fighters[0]
	var d = S.fighters[1]
	d.x = SimWrap.wrap(a.x + 58.0)
	d.y = a.y
	for _k in range(5):
		_step(S)
	_step(S, _light())
	for _k in range(30):
		_step(S)
	_hits = 0
	_step(S, _word(true, false, true, SimStrikeRead.UP, 0))
	for k in range(52):
		_step(S, _word(false, false, true, SimStrikeRead.UP, 0 if k < 10 else (1 if k < 28 else 2)))
	_step(S, _word(false, true, false, SimStrikeRead.UP, 3))
	var waited: int = 0
	while _hits == 0 and waited < 12:
		_step(S)
		waited += 1
	var free: int = int(DirStick.cfg().chargeRecover)
	for _k in range(free):
		_step(S)
	var hd := SimIntent.new()
	hd.sig = true
	hd.sigHeld = true
	_step(S, hd)
	var t: int = free + 1
	while DirBrawl._g(a, DirBrawl.CHG) != 2 and t < 60:
		var h := SimIntent.new()
		h.sigHeld = true
		_step(S, h)
		t += 1
	var flash: int = t
	var stunAtLand: int = -1
	while DirArc._g(d, DirArc.A_ROW) == 0 and t < 60:
		stunAtLand = d.stunTicks
		_step(S)
		t += 1
	print("      flash at %d after the strike; he's sent at %d, %d of the stun left" % [flash, t, stunAtLand])
	_expect(t < int(DirStick.cfg().levels[3].stun), "the ignition route lands inside the 40-tick stun (%d)" % t)
	_expect(DirArc._g(d, DirArc.A_ROW) != 0, "and it sends him up the curve")
	_expect(String(d.state) == "launched", "he's launched (%s)" % d.state)
	DirArc.cfg()["minForms"] = saved
	DirArc.setForce(-1)
	SimCore.dispose(S)


## Same worth, four results: where he is 16 ticks after a quick strike.
func _directions() -> void:
	var worth: Array = []
	var ends: Dictionary = {}
	for dir in [SimStrikeRead.UP, SimStrikeRead.DOWN, SimStrikeRead.RIGHT, SimStrikeRead.LEFT]:
		var S := _pair()
		var a = S.fighters[0]
		var d = S.fighters[1]
		var hp: float = d.hp
		var y0: float = d.y
		var side0: float = signf(SimWrap.sdx(a.x, d.x))
		var gap0: float = absf(SimWrap.sdx(a.x, d.x))
		_hits = 0
		_flick(S, dir)
		var k: int = 0
		while _hits == 0 and k < 14:
			_step(S)
			k += 1
		worth.append(hp - d.hp)
		for _k in range(16):
			_step(S)
		ends[dir] = [d.y - y0, signf(SimWrap.sdx(a.x, d.x)), absf(SimWrap.sdx(a.x, d.x)), gap0, side0, S.dirS.ex != null and DirBrawl.isBrawl(S.dirS.ex), d.stunTicks]
		print("      direction %d: %.0f up, %.0f apart on side %.0f (was %.0f on %.0f), in the brawl %s, stun left %d" % [dir, ends[dir][0], ends[dir][2], ends[dir][1], gap0, side0, str(ends[dir][5]), d.stunTicks])
		SimCore.dispose(S)
	_expect(absf(float(worth[0]) - float(worth[1])) < 0.01 and absf(float(worth[0]) - float(worth[2])) < 0.01 and absf(float(worth[0]) - float(worth[3])) < 0.01, "same worth (%s)" % str(worth))
	_expect(float(ends[SimStrikeRead.UP][0]) > 60.0, "up floats him")
	_expect(float(ends[SimStrikeRead.DOWN][0]) < 1.0 and int(ends[SimStrikeRead.DOWN][6]) > 0, "down holds him on the floor")
	# the right of the screen is toward him here
	_expect(float(ends[SimStrikeRead.RIGHT][2]) > float(ends[SimStrikeRead.RIGHT][3]) + 60.0, "toward drives him back")
	_expect(float(ends[SimStrikeRead.LEFT][1]) != float(ends[SimStrikeRead.LEFT][4]), "away turns him past")
	for dir in ends:
		_expect(bool(ends[dir][5]), "direction %d: the brawl holds" % int(dir))


## A press that can't become a blow says so at once, and nothing fires later.
func _refused() -> void:
	var S := _pair()
	var f = S.fighters[0]
	f.state = "launched"
	f.vy = 400.0
	var cues: int = 0
	var at: int = -1
	for t in range(20):
		f.state = "launched"
		f.vy = 400.0
		SimCore.step(S, [_word(true, false, true, SimStrikeRead.UP, 0) if t == 0 else SimIntent.new(), SimIntent.new()])
		for e in S.out.fx:
			if e.type == "cue" and e.kind == "stick_refused" and e.actor == 0.0:
				cues += 1
				at = t
		S.out.fx.clear()
		S.out.feed.clear()
	_expect(cues == 1, "sent and staying sent: one refusal (%d)" % cues)
	_expect(at == int(DirStick.cfg().bufferTicks), "as the wait runs out (%d)" % at)
	_expect(DirStick._g(f, DirStick.ST_PEND) == 0, "and nothing waits")
	SimCore.dispose(S)
	# free inside the wait: it's taken
	var S2 := _pair()
	var f2 = S2.fighters[0]
	f2.stunTicks = 8
	_hits = 0
	_step(S2, _word(true, false, true, SimStrikeRead.RIGHT, 0))
	_step(S2, _word(false, false, true, SimStrikeRead.RIGHT, 0))
	_step(S2, _word(false, true, false, SimStrikeRead.RIGHT, 0))
	var fired: bool = false
	for _k in range(40):
		_step(S2)
		fired = fired or _hits > 0
	_expect(fired, "free inside the wait: the press goes, and lands")
	SimCore.dispose(S2)


## A charged strike holds more than a quick one.
func _stops() -> void:
	_expect(DirBrawl.weightOf({"stick": 1, "stickL": 0}) == "medium", "a quick strike: a medium's hit-stop")
	_expect(DirBrawl.weightOf({"stick": 1, "stickL": 2}) == "heavy", "level 2: a heavy's")
	_expect(DirBrawl.weightOf({"stick": 1, "stickL": 3}) == "launch", "level 3, which opens the send: a launch's")


## docs/design/stick-lands.md, with lightStops false: a light on a quick flick takes the stun and not the blow; a Y still ends it; a charged
## flick is still bare; LB holds the guard through the wind-up.
func _lightsLand() -> void:
	var cfg: Dictionary = DirStick.cfg()
	var was: bool = bool(cfg.lightStops)
	for row in [[true, "the light stops it"], [false, "the light takes the stun"]]:
		cfg["lightStops"] = bool(row[0])
		var S := _pair()
		var d = S.fighters[1]
		_hits = 0
		_stun = -1
		var hp: float = S.fighters[0].hp
		_step(S, _word(true, false, true, SimStrikeRead.RIGHT, 0))
		_step(S, _word(false, false, true, SimStrikeRead.RIGHT, 0), _light2())
		_step(S, _word(false, false, true, SimStrikeRead.RIGHT, 0))
		_step(S, _word(false, true, false, SimStrikeRead.RIGHT, 0))
		for _k in range(20):
			_step(S)
		print("      lightStops %s: stick hits %d, stun %d, he took %.1f" % [str(row[0]), _hits, _stun, hp - S.fighters[0].hp])
		if bool(row[0]):
			_expect(_hits == 0, "true: " + String(row[1]))
		else:
			_expect(_hits == 1 and _stun == 0, "false: " + String(row[1]) + " (%d, stun %d)" % [_hits, _stun])
			_expect(hp - S.fighters[0].hp > 0.0, "false: he took the light")
			_expect(DirBrawl._g(d, DirBrawl.REEL_AT) > 0, "false: and the one it landed on reels")
		SimCore.dispose(S)
	cfg["lightStops"] = false
	# a Y still ends it
	var S2 := _pair()
	_hits = 0
	var y := SimIntent.new()
	y.heavy = true
	_step(S2, null, y)
	_step(S2, _word(true, false, true, SimStrikeRead.RIGHT, 0))
	_step(S2, _word(false, false, true, SimStrikeRead.RIGHT, 0))
	_step(S2, _word(false, true, false, SimStrikeRead.RIGHT, 0))
	for _k in range(24):
		_step(S2)
	print("      a Y landing on the flick: stick hits %d" % _hits)
	_expect(_hits == 0, "a Y still ends it (%d)" % _hits)
	SimCore.dispose(S2)
	# LB: the guard holds through the wind-up, and the stun's the guard's
	var S3 := _pair()
	var a3 = S3.fighters[0]
	_hits = 0
	_stun = -1
	var hp3: float = a3.hp
	var w: SimIntent = _word(true, false, true, SimStrikeRead.RIGHT, 0)
	w.rsMask = DirStick.LB
	w.guard = true
	w.stance = 1
	w.stanceMask = DirStick.LB
	_step(S3, w)
	var w2: SimIntent = _word(false, false, true, SimStrikeRead.RIGHT, 0)
	w2.guard = true
	w2.stance = 1
	w2.stanceMask = DirStick.LB
	_step(S3, w2, _light2())
	_step(S3, w2)
	var w3: SimIntent = _word(false, true, false, SimStrikeRead.RIGHT, 0)
	w3.guard = true
	w3.stance = 1
	w3.stanceMask = DirStick.LB
	_step(S3, w3)
	var g4 := SimIntent.new()
	g4.guard = true
	g4.stance = 1
	g4.stanceMask = DirStick.LB
	for _k in range(16):
		_step(S3, g4)
	print("      LB + flick through a light: stick hits %d, stun %d, he took %.1f" % [_hits, _stun, hp3 - a3.hp])
	_expect(_hits == 1 and _stun == int(cfg.guardStun), "LB + flick lands through a light, at the guard's stun (%d, stun %d)" % [_hits, _stun])
	SimCore.dispose(S3)
	cfg["lightStops"] = was


func _light2() -> SimIntent:
	var a := SimIntent.new()
	a.light = true
	return a


## Level 3's carry holds the brawl, in all four directions (docs/design/stick-lands.md).
func _levelThreeAll() -> void:
	for dir in [SimStrikeRead.UP, SimStrikeRead.DOWN, SimStrikeRead.LEFT, SimStrikeRead.RIGHT]:
		var S := _pair()
		_hits = 0
		_step(S, _word(true, false, true, dir, 0))
		for k in range(52):
			_step(S, _word(false, false, true, dir, 0 if k < 10 else (1 if k < 28 else 2)))
		_step(S, _word(false, true, false, dir, 3))
		var k2: int = 0
		while _hits == 0 and k2 < 12:
			_step(S)
			k2 += 1
		var held: int = 0
		for _k in range(30):
			_step(S)
			if S.dirS.ex != null and DirBrawl.isBrawl(S.dirS.ex):
				held += 1
		_expect(held == 30, "direction %d, level 3: the brawl holds (%d of 30)" % [dir, held])
		SimCore.dispose(S)

