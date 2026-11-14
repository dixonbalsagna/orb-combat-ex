class_name SimHorde
extends RefCounted
## The horde, the core's side (docs/ep/proposals/horde-trial-design.md sections 6.1 to 6.3; Game Design's rulings docs/design/horde-trial.md):
## five fixed slots, the seats (0 and 1) then the places (2 to 4). A seat is a player's; a place is a weak fighter's, and refills when its body falls.
## Nothing in a horde match starts an exchange; the director's side (sim/director/horde.gd) runs the pack and the run. An away body (`f.out`) is
## parked straight up, not stepped, reads no input and takes no hit.
##
## The switch is data/fight/horde.json "enabled" (off), which SimCore.newMatch copies into S.hordeOn unless the setup has its own "horde". Off, nothing
## here runs: no horde state exists or is hashed, no event is sent, and the file is not in a replay's data hash. No draw from S.rng anywhere here.
## This file names no director class (sim/core/tools/load_split.gd).

const FILE: String = "res://data/fight/horde.json"
const HASHED_BODY: Array = ["kind", "phase", "t", "worth", "at", "w", "buf", "ready", "ln", "due", "dg", "dgOk", "was", "taken", "downs"]
const HASHED_RUN: Array = ["wave", "up", "rest", "t", "over", "sent", "felled"]
const KINDS: Array = ["", "fodder", "bruiser", "speedster"]   # a body's kind: 0 a seat, then the pack's three
const BH_UNITS: float = 75.0   # a body height in units (the director's own constant; the core keeps the height in units, as it may not name a director class)

static var _d = null
static var _hash: String = ""
static var _errors: Array = []
static var on_: bool = false
static var seats: int = 2
static var places: int = 3
static var wholeFight: bool = false
static var parkBh: float = 400.0
static var staggerTicks: int = 20


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	var h := SimHash.Hasher.new()
	var j = FighterData._load(FILE, "fight/horde.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary):
		_errors.append("fight/horde.json: missing, or not an object")
		_d = {}
		_hash = h.hex()
		return
	_d = j
	h.text("fight/horde.json")
	FighterData._canon(h, j)
	_hash = h.hex()
	on_ = j.get("enabled") == true
	seats = int(j.seats)
	places = int(j.places)
	wholeFight = j.hold.wholeFight == true
	parkBh = float(j.respawn.parkBh)
	staggerTicks = int(j.respawn.staggerTicks)
	if seats != 2 or places != 3:
		_errors.append("fight/horde.json: the trial plays two seats and three places (five slots, SimRoster.MAX_BODIES)")


static func enabled() -> bool:
	_ensure()
	return on_


static func dataHash() -> String:
	_ensure()
	return _hash


static func errors() -> Array:
	_ensure()
	return _errors


static func data() -> Dictionary:
	_ensure()
	return _d


## Tests only: read the file again on the next call.
static func reload() -> void:
	_d = null


## A pack kind's block (1 fodder, 2 bruiser, 3 speedster).
static func packCfg(kind: int) -> Dictionary:
	_ensure()
	return _d.pack[KINDS[kind]]


## A horde match's five slots from the setup's one or two fighters: the seats, then the places (SimCore._mFighters).
static func slots(setup: Dictionary) -> Array:
	_ensure()
	var s: Array = setup.get("slots", FighterData.order().slice(0, 2)).slice(0, seats)
	for k in range(places):
		s.append(String(packCfg(1).fighter))   # the fodder's fighter: a place's first body
	return s


## Each body's part for a new match (SimCore._mSetupsC, after the floor's start, which would set a parked body down).
static func setup(S: SimState, _setup: Dictionary) -> void:
	_ensure()
	if S.hordeOn and S.fighters.size() != seats + places:
		if not FighterData.quiet:
			push_error("SimHorde.setup: a horde match needs %d slots, this one has %d; the horde is off" % [seats + places, S.fighters.size()])
		S.hordeOn = false
	S.horde = SimState.HordeRun.new() if S.hordeOn else null
	for k in range(S.fighters.size()):
		var f = S.fighters[k]
		f.hd = SimState.HordeBody.new() if S.hordeOn else null
		if f.hd == null:
			continue
		f.hd.kind = 0 if k < seats else 1
		if k >= seats or f.ai != null:   # every place, and a seat with nobody on it, starts away, parked
			f.out = true
			park(f)
		else:
			f.hd.phase = 2
			f.hd.was = 1
	if not S.hordeOn:
		return
	S.horde.mix = PackedInt32Array([0, 0, 0])
	S.horde.lane.resize(seats * places)   # every lane free from tick 0
	S.horde.lane.fill(0)
	S.horde.mark.resize(S.fighters.size())
	for k in range(S.fighters.size()):
		S.horde.mark[k] = seats if k < seats else 0   # a seat marks the first place; a place marks the first seat
	S.horde.rest = staggerTicks   # the first wave starts after a beat


## An away body, straight up by respawn.parkBh, still: clear of the fight, of beams and of thrown bodies.
static func park(f) -> void:
	f.y = parkBh * BH_UNITS
	f.vx = 0.0
	f.vy = 0.0
	f.z = 0.0
	f.rush = null


## The side a body is on: 0 a seat, 1 a place.
static func side(S: SimState, k: int) -> int:
	return 0 if S.fighters[k].hd.kind == 0 else 1


## Slot k made fresh, in place: every field as a new match would give it (SimRoster.createFighter, then each set-up's one-body form), at x, y.
## The caller sets the body's part in the run (its kind, phase, toughness) and its mark.
static func fresh(S: SimState, k: int, id: String, x: float, y: float) -> void:
	var f = S.fighters[k]
	var hd = f.hd
	var v2: bool = f.act.v2 if k < seats else false   # a seat keeps the setup's v2 and assists; a place's are a new match's (none)
	var assist: int = f.act.assist if k < seats else 0
	var n = SimRoster.createFighter(FighterData.def(id), x, f.keys, f.ai != null)
	for p in n.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			f.set(p.name, n.get(p.name))   # (as SimStage._copy walks a record, stage.gd:106-120)
	f.y = y
	f.hd = hd
	_bodySetups(S, f, v2, assist)


## One body's share of a new match's set-ups (SimCore._mFighters' stance, then SimAct, SimBrake, SimKick, SimForms, SimFlight, SimMood's style),
## touching no other body. A set-up added to newMatch later needs its line here: horde_check's reading 3 fails without it.
static func _bodySetups(S: SimState, f, v2: bool, assist: int) -> void:
	f.stance = 0.0
	var a := SimState.ActState.new()
	a.v2 = v2
	a.assist = assist
	f.act = a
	f.brk = SimState.BrakeState.new() if S.brakeOn else null
	if f.brk != null:
		f.brk.n = f.launchN
	f.kik = SimState.KickState.new() if S.kickOn else null
	f.form = SimState.FormState.new() if S.formsOn else null
	f.fd = SimForms.def(f.id) if S.formsOn else null
	f.flt = SimState.FlightState.new() if S.flightOn else null
	if f.flt != null:
		f.flt.n = f.launchN
	f.style = SimMood.newStyle()


## A body's part in the run back to a new body's, in place (the same object).
static func clearBody(h) -> void:
	h.phase = 0
	h.t = 0
	h.worth = 0.0
	h.at = 0
	h.w = 0
	h.buf = 0
	h.ready = 0
	h.ln = -1
