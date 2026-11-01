extends SceneTree
## The stick's strike against the rulings (docs/design/right-hand-attacks-rulings.md section 2), by scripted second words on an
## idle dummy: the quick strike, the charge, the guard, bareness, one stun a string, the third repeat, the cancel, the lunge.
##   godot --headless --path . --script res://sim/director/tools/stick_check.gd
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	DirStick.setForce(1)
	_quick()
	_charged()
	_guarded()
	_bare()
	_oneStun()
	_repeat()
	_cancel()
	_lunge()
	_releasedEarly()
	_noStray()
	_pools()
	_downed()
	_lateReturn()
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
	_flick(S, SimStrikeRead.RIGHT)
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
	_step(S, _word(true, false, true, SimStrikeRead.RIGHT, 0))
	var early: bool = false
	for k in range(52):
		_step(S, _word(false, false, true, SimStrikeRead.RIGHT, 0 if k < 10 else (1 if k < 28 else 2)))
		early = early or _hits > 0
	_expect(not early, "a stick still out holds the blow back")
	_step(S, _word(false, true, false, SimStrikeRead.RIGHT, 3))
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
	_step(S, _word(true, false, true, SimStrikeRead.RIGHT, 0), g)
	_step(S, _word(false, true, false, SimStrikeRead.RIGHT, 0), g)
	for _k in range(16):
		_step(S, null, g)
	_expect(_hits == 0, "a guard blocks it, with no stun (%d)" % _hits)
	SimCore.dispose(S)


func _bare() -> void:
	var S := _pair()
	_hits = 0
	_step(S, _word(true, false, true, SimStrikeRead.RIGHT, 0))
	_step(S, _word(false, false, true, SimStrikeRead.RIGHT, 0), _light())
	for _k in range(30):
		_step(S, _word(false, false, true, SimStrikeRead.RIGHT, 0))
	_expect(_hits == 0, "a light ends its wind-up (%d)" % _hits)
	_expect(DirStick._g(S.fighters[0], DirStick.ST_ON) == 0, "and the charge is lost")
	SimCore.dispose(S)


func _oneStun() -> void:
	var S := _pair()
	_hits = 0
	_stun = -1
	_flick(S, SimStrikeRead.RIGHT)
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
		_flick(S, SimStrikeRead.RIGHT)
		for _k in range(14):
			_step(S)
		stuns.append(_stun)
	_expect(_hits == 3 and stuns[0] == 20 and stuns[1] == 20 and stuns[2] == 0, "the third of one direction inside 3 s hits and doesn't stun (%s)" % str(stuns))
	SimCore.dispose(S)


func _cancel() -> void:
	var S := _pair()
	_hits = 0
	_step(S, _word(true, false, true, SimStrikeRead.RIGHT, 0))
	for _k in range(4):
		_step(S, _word(false, false, true, SimStrikeRead.RIGHT, 0))
	_step(S, _word(false, false, false, SimStrikeRead.RIGHT, 0, true))
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
	_flick(S, SimStrikeRead.RIGHT)
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
	_step(S, _word(true, false, true, SimStrikeRead.RIGHT, 0))
	_step(S, _word(false, true, false, SimStrikeRead.RIGHT, 2))
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
	_step(S, _word(true, false, true, SimStrikeRead.RIGHT, 0))
	for k in range(11):
		SimCore.step(S, [_word(false, false, true, SimStrikeRead.RIGHT, 0), SimIntent.new()])
		for e in S.out.fx:
			if e.type == "cue" and e.kind == "stick_charge":
				cues += 1
			if e.type == "cue" and e.kind == "stick_hit":
				_hits += 1
				_stun = int(e.n)
		S.out.fx.clear()
		S.out.feed.clear()
	_step(S, _word(false, true, false, SimStrikeRead.RIGHT, 0))
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
		for dir in [SimStrikeRead.UP, SimStrikeRead.DOWN, SimStrikeRead.LEFT, SimStrikeRead.RIGHT]:
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
	_step(S, _word(true, false, true, SimStrikeRead.RIGHT, 0))
	var early: bool = false
	for _k in range(9):
		_step(S, _word(false, false, true, SimStrikeRead.RIGHT, 0))
		early = early or _hits > 0
	_expect(not early, "out past the wind-up, the blow waits")
	_step(S, _word(false, true, false, SimStrikeRead.RIGHT, 0))
	_step(S)
	_step(S)
	_expect(_hits == 1, "back before the dwell: it lands just after (%d)" % _hits)
	_expect(_stun == 20, "as a quick strike (%d)" % _stun)
	SimCore.dispose(S)
