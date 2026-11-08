class_name DirEnding
extends RefCounted
## How a match always ends (docs/design/spec-wounds.md 1b-end). A KO only comes from a finisher, and hit points end nothing.
## - A player with no input for idleSec: the wear he takes is idleWearMul times. After pushSec, on the brink he's opened, so his rival's next
##   decisive win is the finisher, unless the rival's idle too. Any input ends it at once. An AI is never idle.
## - The time cap (finishers.json timeCapAt): both go on the brink, Rallies stop, and every decisive win is a finisher (DirExchange.decisive).
## - lastAt: the fighter with less wear gets his finisher, with no contest; level wear with anyone playing breaks by seed. Nobody's played
##   since the cap, and wear level: a no-contest, and a cue.
## - 2v2 with hits across (docs/design/two-v-two.md, "The last event in a 2v2"): lastAt is decided by team, not fight by fight. The team
##   with more fighters standing wins, then the one with less wear across its standing fighters, then by seed with anyone playing. Every
##   standing fighter of the other team gets his finisher from the standing opponent in his fight, at once, with no contest (one alone in
##   his fight, from the one Simulation's rejoin brings him). Nobody's played (every fighter a player, none with input since the cap) and
##   the teams level: a no-contest.
## Off, no slot is sized and nothing changes.

const E_IDLE: int = 0   # live ticks with no input from him
const E_ADD: int = 1    # the wear the cap put on him: it doesn't count at lastAt
const E_DONE: int = 2   # on the first fighter: 1 the last event has fired, 2 it was a no-contest. 2v2, on every body: 2 the no-contest,
                        # 3 + the winning team, decided; on a losing fighter, 5 + the team once his finisher's started
const E_N: int = 3

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("ending", {})


static func on() -> bool:
	return bool(cfg().get("enabled", false)) if _force < 0 else _force == 1


static func _b() -> int:
	return DirArc._b() + DirArc.A_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + E_N:
		f.act.dirI.resize(_b() + E_N)
	f.act.dirI[_b() + k] = v


## Anything he's doing: either stick, a button held or pressed.
static func _input(f) -> bool:
	var i = f.input
	return i.mx != 0.0 or i.my != 0.0 or i.light or i.heavy or i.sig or i.lightHeld or i.heavyHeld or i.sigHeld or i.guard or i.dodge or i.sprint or i.power or i.dash or i.charge or i.rsHeld or i.rsStart or i.stanceMask != 0


static func idle(f) -> bool:
	return on() and f.ai == null and _g(f, E_IDLE) >= int(float(cfg().idleSec) * DirData.TICKS_PER_SEC)


## Long enough that the finisher's pushed on him.
static func pushed(f) -> bool:
	return on() and f.ai == null and _g(f, E_IDLE) >= int(float(cfg().pushSec) * DirData.TICKS_PER_SEC)


## SimWounds.addWear's factor.
static func wearMul(f) -> float:
	return float(cfg().idleWearMul) if idle(f) else 1.0


## A share of how well he's doing, for a read that used to be his hit points, which are gone a minute in.
static func standing(f) -> float:
	return SimWounds.vitality(f) if on() else float(f.hp) / maxf(1.0, float(f.maxhp))


static func noContest(S: SimState) -> bool:
	return on() and _g(S.fighters[0], E_DONE) == 2


static func _worn(f) -> int:
	var n: int = 0
	for r in range(f.wear.size()):
		n += int(f.wear[r])
	return n - _g(f, E_ADD)


static func _toBrink(S: SimState, f) -> void:
	if f.brink:
		return
	var add: int = maxi(0, int(f.wd.stageAt[2]) - int(f.wear[SimWounds.CORE]))
	f.wear[SimWounds.CORE] += add
	_s(f, E_ADD, _g(f, E_ADD) + add)
	SimWounds.updateStages(S, f)


## Once a live tick, after the time cap's own check.
static func tick(S: SimState) -> void:
	if not on() or S.game.ko != null:
		return
	var pair: Array = [S.fighters[0], S.fighters[1]]
	for k in [0, 1]:
		var f = pair[k]
		if f.ai != null:
			continue
		if _input(f):
			if _g(f, E_IDLE) != 0:
				_s(f, E_IDLE, 0)
			continue
		_s(f, E_IDLE, _g(f, E_IDLE) + 1)
	for k in [0, 1]:
		var f = pair[k]
		var o = pair[1 - k]
		if pushed(f) and f.brink and not f.brinkOpen and not idle(o):
			DirExchange._openBrink(S, o, f)
	if not S.game.timeCap:
		return
	for f in pair:
		_toBrink(S, f)
	var done: int = _g(pair[0], E_DONE)
	if _now(S) >= _lastAt(S) and (done == 0 or (done >= 3 and SimCross.on(S))):
		_last(S, pair)


## 2v2 with hits across: the last event and the cap on the stage's clock, at cross.json's lastAt and timeCapAt (Simulation's
## SimCross), so both fights reach them on one tick; otherwise the fight's own clock and a 1v1's numbers.
static func _now(S: SimState) -> float:
	return S.stage.clock if SimCross.on(S) else S.T


static func _lastAt(S: SimState) -> float:
	return SimCross.lastAt() if SimCross.on(S) else float(cfg().lastAt)


static func _capAt(S: SimState) -> float:
	return SimCross.timeCap() if SimCross.on(S) else DirData.timeCapAt()



## 2v2 with hits across: the last event by team (two-v-two.md, 2026-11-07). The first fight to reach lastAt decides for the stage and marks
## every body (E_DONE 3 + the team), so the decision goes with them through a trade or a rejoin; then each fight, on its own tick, plays
## its finisher: the winning team's standing fighter in it finishes the losing team's, who is marked 5 + the team once it's started. Two
## fights play theirs at once; Camera frames two KOs. A losing fighter with no opponent standing in his fight (his fight's won, by him) waits
## for Simulation's rejoin (SimStage.rejoin), which puts the two standing of different teams in one fight: his nearest opponent finishes him there.
static func _lastTeam(S: SimState, pair: Array) -> void:
	var T: int = -1
	for f in SimStage.bodies(S):
		var v: int = _g(f, E_DONE)
		if v == 2:
			return   # the stage's no-contest
		if v >= 3:
			T = (v - 3) % 2
	if T < 0:
		var stand: Array = [0, 0]
		var worn: Array = [0, 0]
		var players: bool = true
		var need: int = int((_lastAt(S) - _capAt(S)) * DirData.TICKS_PER_SEC)
		var quiet: bool = true
		for f in SimStage.bodies(S):
			if f.ai != null:
				players = false
			elif _g(f, E_IDLE) < need:
				quiet = false
			if f.out:
				continue
			var t: int = SimCross.team(f)
			stand[t] += 1
			worn[t] += _worn(f)
		if stand[0] == stand[1] and worn[0] == worn[1] and players and quiet:
			_markAll(S, 2)
			SimFx.cue(S, null, "no_contest", "", "")
			SimEvents.feed(S, "NO CONTEST", "nobody's touched anything: straight to the rematch")
			return
		if stand[0] != stand[1]:
			T = 0 if stand[0] > stand[1] else 1
		elif worn[0] != worn[1]:
			T = 0 if worn[0] < worn[1] else 1
		else:
			T = 0 if SimRng.keyed(int(S.game.seed), "ending.team", 0) < 0.5 else 1
		_markAll(S, 3 + T)
		var why: String = "more standing" if stand[0] != stand[1] else ("the less wear" if worn[0] != worn[1] else "the edge")
		SimEvents.feed(S, "THE PLANET GIVES WAY", "team %d has %s, and the finishers" % [T + 1, why])
	var W = null
	var L = null
	for f in pair:
		if f.out:
			continue
		if SimCross.team(f) == T:
			W = f
		else:
			L = f
	if W == null or L == null:
		return   # nobody of the losing team stands in this fight, or he waits for the rejoin to bring him his opponent
	if _g(L, E_DONE) >= 5:
		return   # his finisher's started
	_s(L, E_DONE, 5 + T)
	var ex = DirBrawl.exOf(S)
	if ex != null and DirExchange.finisherPlanned(ex):
		return   # one's already on its way, and at the cap it can't be survived
	if ex == null:
		ex = DirExchange.startZip(S, W, L, "heavy")
	DirExchange.startFinisher(S, ex, W, L)


## Every body carries the stage's decision (E_DONE), in every fight.
static func _markAll(S: SimState, v: int) -> void:
	for f in SimStage.bodies(S):
		_s(f, E_DONE, v)


## Nobody's played for the time since the cap: two players with no input.
static func _nobody(S: SimState, pair: Array) -> bool:
	var need: int = int((_lastAt(S) - _capAt(S)) * DirData.TICKS_PER_SEC)
	return pair[0].ai == null and pair[1].ai == null and _g(pair[0], E_IDLE) >= need and _g(pair[1], E_IDLE) >= need


static func _last(S: SimState, pair: Array) -> void:
	if SimCross.on(S):
		_lastTeam(S, pair)
		return
	var a: int = _worn(pair[0])
	var b: int = _worn(pair[1])
	if a == b and _nobody(S, pair):
		_s(pair[0], E_DONE, 2)
		SimFx.cue(S, null, "no_contest", "", "")
		SimEvents.feed(S, "NO CONTEST", "nobody's touched anything: straight to the rematch")
		return
	_s(pair[0], E_DONE, 1)
	var first: bool = a < b if a != b else SimRng.keyed(int(S.game.seed), "ending.level", 0) < 0.5
	var W = pair[0] if first else pair[1]
	var L = pair[1] if first else pair[0]
	SimEvents.feed(S, "THE PLANET GIVES WAY", W.name + " has the less wear, and the finisher")
	var ex = S.dirS.ex
	if ex != null and DirExchange.finisherPlanned(ex):
		return   # one's already on its way, and at the cap it can't be survived
	if ex == null:
		ex = DirExchange.startZip(S, W, L, "heavy")
	DirExchange.startFinisher(S, ex, W, L)
