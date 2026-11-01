class_name SimStage
extends RefCounted
## A match of more than one fight on one line (docs/architecture/fight-swap.md): setup {"fights": 2} with four slots.
## Each fight is a plain 1v1 to everything that reads S: its pair, its director, its clock, its holds. Only one fight is
## in S's fields at a time: SimCore._stepFights steps them in turn, in slot order, and between ticks S holds fight 0, so
## what reads S between ticks reads the first fight. The planet, its stored damage, the buildings and the water are S's
## own, so all of them are shared. In any other match S.stage is null and nothing here runs.

const WHOLE: int = -1   # Stage.cur while S.fighters is everyone: the swing's tick, once a tick


## Fight i's fields into S, and whoever was there back to its record. The record of the fight in S holds the blanks, so
## no array is in two places, as a snapshot needs. Spelled out because it runs twice a fight, every tick.
static func enter(S: SimState, i: int) -> void:
	var st = S.stage
	if i == st.cur:
		return
	_swap(S, st.fights[st.cur])
	_swap(S, st.fights[i])
	st.cur = i


static func _swap(S: SimState, r) -> void:
	var a = S.fighters; S.fighters = r.fighters; r.fighters = a
	var d = S.dirS; S.dirS = r.dirS; r.dirS = d
	var t: float = S.T; S.T = r.T; r.T = t
	t = S.dt; S.dt = r.dt; r.dt = t
	var q = S.rng; S.rng = r.rng; r.rng = q
	var g = S.game; S.game = r.game; r.game = g
	var w = S.world; S.world = r.world; r.world = w
	a = S.beams; S.beams = r.beams; r.beams = a
	a = S.shots; S.shots = r.shots; r.shots = a
	var n: int = S.shotSeq; S.shotSeq = r.shotSeq; r.shotSeq = n
	var m = S.mood; S.mood = r.mood; r.mood = m
	var p = S.pause; S.pause = r.pause; r.pause = p
	var h = S.hs; S.hs = r.hs; r.hs = h
	var c = S.cata; S.cata = r.cata; r.cata = c
	var e = S.epoch; S.epoch = r.epoch; r.epoch = e
	var ph: PackedFloat32Array = S.popHist; S.popHist = r.popHist; r.popHist = ph
	a = S.waterWin; S.waterWin = r.waterWin; r.waterWin = a
	t = S.waterTick; S.waterTick = r.waterTick; r.waterTick = t
	a = S.aftermathJobs; S.aftermathJobs = r.aftermathJobs; r.aftermathJobs = a
	var o = S.out; S.out = r.out; r.out = o


## The setup's number of fights: 1 in every match but one that asks for 2 and has the bodies for it (slots can be left
## out: the roster's first two, twice).
static func fightsOf(setup: Dictionary) -> int:
	return 2 if int(setup.get("fights", 1)) == 2 else 1


static func slotsFor() -> Array:
	var o: Array = FighterData.order()
	return [o[0], o[1], o[0], o[1]]


## At the start: the second pair half a ring from the first, as it stands, before the setups put them on the ground.
static func place(S: SimState) -> void:
	for k in range(2):
		var f = S.fighters[k + 2]
		f.x = SimWrap.wrap(S.fighters[k].x + SimConst.W * 0.5)
		f.face = S.fighters[k].face


## At the end of newMatch, the bodies all set up: the pairs apart into fights. Fight 1 starts as fight 0 has, by copying
## its fresh state, with its own stream and seed. Nothing here holds a fighter yet (a test below says so).
static func open(S: SimState, seed: int) -> void:
	var st := SimState.Stage.new()
	var all: Array = S.fighters
	S.fighters = all.slice(0, 2)
	st.fights.append(SimState.Fight.new())
	var key: int = (seed + 0x9E3779B1) & 0xFFFFFFFF
	var r := SimState.Fight.new()
	r.fighters = all.slice(2, 4)
	r.dirS = _copy(S.dirS)
	r.rng = SimRng.new(key)
	r.game = _copy(S.game)
	r.game.seed = float(key)
	r.world = _copy(S.world)
	r.mood = _copy(S.mood)
	r.pause = _copy(S.pause)
	r.hs = _copy(S.hs) if S.hs != null else null
	r.cata = _copy(S.cata) if S.cata != null else null
	r.popHist = S.popHist.duplicate()
	st.fights.append(r)
	S.stage = st


## A fresh record's copy: its scalars and its containers. A state that holds an object at match start isn't fresh.
static func _copy(o):
	var c = o.get_script().new()
	for p in o.get_property_list():
		if not (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var v = o.get(p.name)
		match typeof(v):
			TYPE_OBJECT:
				if v != null:
					push_error("SimStage: %s holds an object at match start" % p.name)
			TYPE_ARRAY, TYPE_DICTIONARY, TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
				c.set(p.name, v.duplicate(true) if typeof(v) == TYPE_ARRAY or typeof(v) == TYPE_DICTIONARY else v.duplicate())
			_:
				c.set(p.name, v)
	return c


## What SimCore.dispose does for S's own fight, for the others.
static func dispose(S: SimState) -> void:
	for r in S.stage.fights:
		for f in r.fighters:
			f.launchBy = null
			f.rush = null
		if r.game != null:
			r.game.ko = null
			r.game.clash = null
		if r.dirS != null:
			r.dirS.ex = null
		r.beams.clear()


static func inputsOf(inputs, i: int):
	return inputs.slice(i * 2, i * 2 + 2) if inputs != null else null


## Every fighter in the match, fight by fight.
static func bodies(S: SimState) -> Array:
	var st = S.stage
	if st.cur == WHOLE:
		return S.fighters
	var out: Array = []
	for i in range(st.fights.size()):
		out.append_array(S.fighters if i == st.cur else st.fights[i].fighters)
	return out


## The line's one tick. It belongs to nobody's clock, so it runs while any fight does; with everyone held it waits, as
## it does for one fight's hold. S.fighters is everyone for its length: what the swing answers to, keeps on the floor and
## poses. An event it sends goes to fight 0.
static func swingTick(S: SimState) -> void:
	var st = S.stage
	var live: bool = false
	for i in range(st.fights.size()):
		var d = S.dirS if i == st.cur else st.fights[i].dirS
		var p = S.pause if i == st.cur else st.fights[i].pause
		if d.stop <= 0.0 and p.left <= 0:
			live = true
	if not live or S.frame == null:
		return
	var pair: Array = S.fighters
	S.fighters = bodies(S)
	st.cur = WHOLE
	SimSwing.tick(S)
	S.fighters = pair
	st.cur = 0


## The middle of everyone, on the ring.
static func middle(S: SimState) -> float:
	var all: Array = bodies(S)
	var sum: float = 0.0
	for f in all:
		sum += SimWrap.sdx(all[0].x, f.x)
	return SimWrap.wrap(all[0].x + sum / float(all.size()))


## Game Design's "all four on one line" with the pairs apart: nothing to turn it for. Together is everyone within
## swing.json's apartReach of the middle.
static func together(S: SimState) -> bool:
	var px: float = middle(S)
	var reach: float = float(SimSwing.data().apartReach)
	for f in bodies(S):
		if absf(SimWrap.sdx(px, f.x)) > reach:
			return false
	return true


## A swing's reasons to rest beyond the plain 1v1's: the pairs apart, or a beam in another fight.
static func halts(S: SimState) -> bool:
	if S.stage == null:
		return false
	if not together(S):
		return true
	for r in S.stage.fights:
		if r.beams.size() > 0:
			return true
	return false


## The closest two bodies of different fights: what "apart" is measured by in a check.
static func gap(S: SimState) -> float:
	var st = S.stage
	var near: float = 1.0e18
	for f in st.fights[1 - st.cur].fighters:
		for g in S.fighters:
			near = minf(near, absf(SimWrap.sdx(f.x, g.x)))
	return near


## The fight a body is in, -1 for none.
static func fightOf(S: SimState, f) -> int:
	var st = S.stage
	for i in range(st.fights.size()):
		if (S.fighters if i == st.cur else st.fights[i].fighters).has(f):
			return i
	return -1


## A body's times are his fight's clock. Moving to another fight, every one of them moves with it, so what he had left
## stays what he has left.
const STAMPS: Array = ["hurtT", "breathT", "ambushUntil", "lockBackT", "sigReadyT", "lastAtkT", "exT", "embedCool"]


static func rebase(f, from: float, to: float) -> void:
	var d: float = to - from
	for k in STAMPS:
		f.set(k, f.get(k) + d)
	if f.beamCharge != null:
		f.beamCharge += d
	if f.rush != null:
		f.rush.end += d


## Two bodies of different fights change places in them, each taking the other's slot, so a fight stays a pair and its
## director needs nothing new. Between ticks only. Refused (false) while either fight has something that names a slot or
## a fighter: an exchange, a clash, a beam, a shot, a pause, a KO, a launch. A real tag needs Encounter's side.
static func trade(S: SimState, a, b) -> bool:
	var st = S.stage
	if st == null or st.cur != 0:
		return false
	var ia: int = fightOf(S, a)
	var ib: int = fightOf(S, b)
	if ia < 0 or ib < 0 or ia == ib:
		return false
	if a.launchBy != null or b.launchBy != null:
		return false
	for i in [ia, ib]:
		enter(S, i)
		var busy: bool = S.dirS.ex != null or S.game.clash != null or S.game.ko != null or S.beams.size() > 0 or S.shots.size() > 0 or S.pause.left > 0
		enter(S, 0)
		if busy:
			return false
	enter(S, ia)
	var ka: int = S.fighters.find(a)
	var ta: float = S.T
	S.fighters[ka] = b
	enter(S, ib)
	var kb: int = S.fighters.find(b)
	var tb: float = S.T
	S.fighters[kb] = a
	enter(S, 0)
	rebase(a, ta, tb)
	rebase(b, tb, ta)
	return true


## The hash's values, fight by fight: fight 0's walk (the world with it), then each other's.
static func collect(S: SimState) -> Array:
	var v: Array = SimHash.collect(S, "gameplay")
	for i in range(1, S.stage.fights.size()):
		enter(S, i)
		v.append_array(SimHash.collect(S, "gameplay"))
	enter(S, 0)
	return v
