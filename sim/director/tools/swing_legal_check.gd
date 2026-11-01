extends SceneTree
## Legal's conditions on the swing (RL-213 to RL-216; encounter.md section 2's table): what it may read, what it may arrive at,
## what it may say. QA's batch (the band, the one-way rule) is QA's; this is the part that needs no batch.
##   godot --headless --path . --script res://sim/director/tools/swing_legal_check.gd
## Plays on field worlds. Ends on the verdict line. A scratch copy with a term reading popAlive in _direction must fail it: that's
## the negative control.

const FILES := ["res://sim/director/swing.gd"]
const BARRED := ["crowd", "popAlive", "popNear", "popHist", "pop_mult", "toll", "casualt"]
const NOT_IN_DIRECTION := ["mood", "menace"]
const WORDS := ["people", "person", "civilian", "crowd", "casualt", "victim", "dead", "death", "kill", "school", "hospital", "church", "temple", "mosque", "chapel"]
const PLANETS := [7, 3, 11, 25]

var failed: int = 0


func _init() -> void:
	DirSwing.setForce(1)
	_lint()
	for p in PLANETS:
		_blind(p)
		_oneMatch(p)
	_excluded()
	DirSwing.setForce(-1)
	print("SWING LEGAL: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		print("FAIL  " + what)
		failed += 1


func _ok(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## The source: no file names a barred field; the direction function names neither mood nor menace; and the nudge's reads no
## fighter's stat at all. Comments count, so that no reader has to judge one.
func _lint() -> void:
	for path in FILES:
		var text: String = FileAccess.get_file_as_string(path)
		for w in BARRED:
			_ok(not text.contains(w), "%s doesn't name %s" % [path.get_file(), w])
	var src: String = FileAccess.get_file_as_string(FILES[0])
	var dir: String = _func(src, "static func _direction(")
	_ok(dir != "", "the direction function is there")
	for w in NOT_IN_DIRECTION:
		_ok(not dir.contains(w), "the direction function doesn't name %s" % w)
	var nu: String = _func(src, "static func nudgeList(")
	_ok(nu != "", "the nudge's scorer is there")
	for w in ["care", "anguish", "menace", "mood"]:
		_ok(not nu.contains(w), "the nudge's scorer doesn't name %s" % w)
	var tm: String = _func(src, "static func _tension(")
	for w in ["anguish", "menace", "mood"]:
		_ok(tm.contains(w), "timing's scalar %s is the one listed by name" % w)


func _func(src: String, head: String) -> String:
	var a: int = src.find(head)
	if a < 0:
		return ""
	var b: int = src.find("\nstatic func ", a + head.length())
	var body: String = src.substr(a, (b if b > 0 else src.length()) - a)
	var i: int = body.rfind("\n## ")   # the next function's own comment isn't this one's
	return body.substr(0, i) if i > 0 else body


## Blind to people: each ask scored twice from one state, the people zeroed in one and doubled in the other. Not a bit moves.
func _blind(planet: int) -> void:
	var S = _match(planet, 1800)
	var fs = S.fighters
	var askers := [fs[0], fs[1]]
	for a in askers:
		var o = SimRoster.opp(S, a)
		var pv: float = float(a.x)
		for k in range(4):
			var side: int = 1 if k % 2 == 0 else -1
			var reach: float = 3000.0 + 3000.0 * float(k)
			var one: Array = _sig(S, a, o, pv, side, reach, 0.0)
			var two: Array = _sig(S, a, o, pv, side, reach, 2.0)
			_expect(one == two, "planet %d: an ask's scores moved with the people (%s side %d)" % [planet, a.name, side])
	var villain = fs[0] if float(fs[0].care) < 0.0 else fs[1]
	var o2 = SimRoster.opp(S, villain)
	var m0 = villain.menace
	villain.menace = 0.0
	var a1: Array = _dirOnly(S, villain, o2, 1)
	villain.menace = 100.0
	var a2: Array = _dirOnly(S, villain, o2, 1)
	villain.menace = m0
	_expect(a1 == a2, "planet %d: direction moved with his menace" % planet)
	var m1 = S.mood.v
	S.mood.v = 0
	var b1: Array = _dirOnly(S, villain, o2, 1)
	S.mood.v = 3000
	var b2: Array = _dirOnly(S, villain, o2, 1)
	S.mood.v = m1
	_expect(b1 == b2, "planet %d: direction moved with the mood" % planet)
	_nudgeSame(S, planet)
	SimCore.dispose(S)


## The nudge's scorer is the same for every fighter: flip care and every toll-fed stat, and it doesn't move (RL-216).
func _nudgeSame(S, planet: int) -> void:
	var f = S.fighters[0]
	var x: float = float(f.x)
	var a: Array = _nudgeSig(S, x)
	var keep := [f.care, f.anguish, f.menace]
	f.care = -float(f.care)
	f.anguish = 90.0
	f.menace = 90.0
	var b: Array = _nudgeSig(S, x)
	f.care = keep[0]
	f.anguish = keep[1]
	f.menace = keep[2]
	_expect(a == b, "planet %d: the nudge's pick moved with a fighter's stats" % planet)
	var keep2: Array = _people(S, 0.0)
	var c: Array = _nudgeSig(S, x)
	_people(S, -1.0, keep2)
	_expect(a == c, "planet %d: the nudge's pick moved with the people" % planet)


func _nudgeSig(S, x: float) -> Array:
	var out: Array = []
	for h in [1, -1]:
		for e in DirSwing.nudgeList(S, x, h):
			out.append([int(e.id), float(e.turn), float(e.s)])
	return out


func _dirOnly(S, a, o, side: int) -> Array:
	var out: Array = []
	for e in DirSwing.scored(S, "launch", a, o, float(a.x), side, 180.0, 9000.0, 180.0):
		out.append([float(e.turn), int(e.id), float(e.dir)])
	return out


func _sig(S, a, o, pv: float, side: int, reach: float, mul: float) -> Array:
	var keep: Array = _people(S, mul)
	var out: Array = []
	for e in DirSwing.scored(S, "launch", a, o, pv, side, 180.0, reach, 180.0):
		out.append([float(e.turn), int(e.id), String(e.kind), float(e.s)])
	_people(S, -1.0, keep)
	return out


## Sets everything that counts people to mul times itself (mul < 0: back to `back`). Returns what was there.
func _people(S, mul: float, back: Array = []) -> Array:
	if mul < 0.0:
		for i in range(S.buildings.size()):
			S.buildings[i].popAlive = back[0][i]
		S.popHist = back[1]
		S.world.casualties = back[2]
		return []
	var keep := [[], S.popHist.duplicate(), S.world.casualties]
	for b in S.buildings:
		(keep[0] as Array).append(b.popAlive)
		b.popAlive = float(b.popAlive) * mul
	var h = S.popHist.duplicate()
	for i in range(h.size()):
		h[i] = float(h[i]) * mul
	S.popHist = h
	S.world.casualties = float(S.world.casualties) * mul
	return keep


## Every ask of a match with the switch on: words, picks.
func _oneMatch(planet: int) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, planet, {}, _setup(planet))
	var asks: int = 0
	while S.tick < 18000 and S.game.ko == null:
		SimCore.step(S)
		for l in S.out.feed:
			if String(l.tag).begins_with("SWING "):
				asks += 1
				_words(String(l.tag) + " " + String(l.sub), planet)
		for e in S.out.fx:
			if e.type == "cue" and (e.kind == "swing_place" or e.kind == "swing_nudge"):
				_words(str(e.text) + " " + str(e.source), planet)
		S.out.fx.clear()
		S.out.feed.clear()
	_ok(asks > 0, "planet %d: %d asks read for their words and picks" % [planet, asks])
	SimCore.dispose(S)


func _words(t: String, planet: int) -> void:
	var low: String = t.to_lower()
	for w in WORDS:
		_expect(not low.contains(w), "planet %d: the words name %s: %s" % [planet, w, t])


## Excluded places (RL-214): a landmark marked noTarget is never a candidate. The chapel where it stands on a world, and WorldBrunt's own list.
func _excluded() -> void:
	var seen: int = 0
	var cands: int = 0
	for planet in PLANETS:
		var S = _match(planet, 60)
		var near: Dictionary = {}
		for i in range(S.buildings.size()):
			var b = S.buildings[i]
			if WorldSettle.noTarget(b.landmark):
				seen += 1
				near[i] = true
		var o = S.fighters[1]
		var keep: float = o.x
		for i in near:
			o.x = SimWrap.wrap(float(S.buildings[i].x) + 400.0)
			for bi in WorldBrunt.candidates(S, o):
				cands += 1
				_expect(not WorldSettle.noTarget(S.buildings[bi].landmark), "planet %d: WorldBrunt offers a noTarget landmark" % planet)
		o.x = keep
		SimCore.dispose(S)
	_ok(true, "excluded kinds: %d stood on these worlds, %d candidates beside them read" % [seen, cands])
	var marked: bool = false
	var lms: Array = WorldSettle.data().get("landmarks", [])
	for k in range(lms.size()):
		if String(lms[k].get("key", "")) == "hill_chapel":
			marked = WorldSettle.noTarget(k + 1)
	_expect(marked, "hill_chapel isn't marked noTarget")
	_expect(not DirSwing.places(_probeS(), DirSwing._planet(_probeS()), DirSwing._frame(_probeS(), 0.0), 1.0e9).is_empty(), "the place list is empty")
	if _s != null:
		SimCore.dispose(_s)


var _s = null


func _probeS():
	if _s == null:
		_s = _match(7, 1)
	return _s


func _setup(planet: int) -> Dictionary:
	return {"planet": planet, "touch": 1, "planetGen": 3, "intro": false}


func _match(planet: int, ticks: int):
	var S := SimCore.createSim()
	SimCore.newMatch(S, planet, {}, _setup(planet))
	_expect(S.frame != null, "planet %d: no field world, so this reads nothing" % planet)
	for _k in range(ticks):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
	return S
